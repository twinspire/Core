package twinspire.story;

/**
 * Manages conversation flow, character participation, and integration with the story engine.
 */
class ConversationManager
{
    /**
     * Stack of conversation history for navigation
     */
    private static var conversationHistory:Array<String> = [];
    
    /**
     * Current conversation being processed
     */
    private static var currentConversation:Conversation = null;
    
    /**
     * Characters currently participating across all conversations
     */
    private static var globalActiveCharacters:Map<String, Character> = new Map<String, Character>();
    
    /**
     * Conversation flow rules and conditions
     */
    private static var conversationRules:Array<ConversationRule> = [];
    
    /**
     * Initialize the conversation manager
     */
    public static function initialize():Void
    {
        conversationHistory = [];
        currentConversation = null;
        globalActiveCharacters.clear();
        conversationRules = [];
    }
    
    /**
     * Start a conversation by name
     */
    public static function startConversation(conversationName:String):Bool
    {
        var conversation = StoryManager.findConversation(conversationName);
        if (conversation == null) {
            trace('Conversation "$conversationName" not found');
            return false;
        }
        
        // Check if conversation is available
        conversation.updateAvailability();
        if (!conversation.isAvailable) {
            trace('Conversation "$conversationName" is not available');
            return false;
        }
        
        // End current conversation if active
        if (currentConversation != null) {
            endConversation();
        }
        
        // Start new conversation
        currentConversation = conversation;
        conversationHistory.push(conversationName);
        
        StoryManager.setCurrentConversation(conversationName);
        
        // Apply conversation rules
        applyConversationRules(conversation);
        
        trace('Started conversation: $conversationName');
        return true;
    }
    
    /**
     * End the current conversation
     */
    public static function endConversation():Void
    {
        if (currentConversation == null) {
            return;
        }
        
        var conversationName = currentConversation.commandBlock.title;
        
        // Complete the conversation
        currentConversation.complete();
        
        // Trigger exit events
        StoryManager.getEventManager().triggerExitEvents();
        
        currentConversation = null;
        StoryManager.setCurrentConversation("");
        
        trace('Ended conversation: $conversationName');
    }
    
    /**
     * Switch to a different conversation
     */
    public static function switchToConversation(conversationName:String):Bool
    {
        if (currentConversation != null && currentConversation.commandBlock.title == conversationName) {
            return true; // Already in this conversation
        }
        
        var previousName = currentConversation != null ? currentConversation.commandBlock.title : "";
        
        if (startConversation(conversationName)) {
            // Trigger conversation change events
            StoryManager.getEventManager().triggerConversationChangeEvents(previousName, conversationName);
            return true;
        }
        
        return false;
    }
    
    /**
     * Add a character to the current conversation
     */
    public static function addCharacterToConversation(character:Character):Void
    {
        if (currentConversation == null) {
            trace('Cannot add character: no active conversation');
            return;
        }
        
        currentConversation.addCharacter(character);
        globalActiveCharacters.set(character.name, character);
        
        // Process function queue in case this character enables queued functions
        StoryManager.processFunctionQueue();
    }
    
    /**
     * Remove a character from the current conversation
     */
    public static function removeCharacterFromConversation(character:Character):Void
    {
        if (currentConversation == null) {
            return;
        }
        
        currentConversation.removeCharacter(character);
        globalActiveCharacters.remove(character.name);
    }
    
    /**
     * Process a dialogue line with optional character
     */
    public static function processDialogue(dialogue:String, ?characterName:String):Void
    {
        if (currentConversation == null) {
            trace('Cannot process dialogue: no active conversation');
            return;
        }
        
        var character:Character = null;
        if (characterName != null) {
            character = StoryManager.getCharacter(characterName);
            if (character != null) {
                addCharacterToConversation(character);
            }
        }
        
        // Let StoryManager handle the dialogue processing
        StoryManager.processDialogue(dialogue, characterName);
    }
    
    /**
     * Process a choice selection
     */
    public static function processChoice(choiceIndex:Int, choiceData:Dynamic):Void
    {
        if (currentConversation == null) {
            trace('Cannot process choice: no active conversation');
            return;
        }
        
        // Trigger choice events
        currentConversation.eventHandlers.triggerChoice(choiceIndex, choiceData);
        StoryManager.getEventManager().triggerChoiceEvents(choiceIndex, choiceData);
    }
    
    /**
     * Get the current active conversation
     */
    public static function getCurrentConversation():Conversation
    {
        return currentConversation;
    }
    
    /**
     * Get all characters currently active in any conversation
     */
    public static function getGlobalActiveCharacters():Array<Character>
    {
        return [for (char in globalActiveCharacters) char];
    }
    
    /**
     * Get characters active in the current conversation
     */
    public static function getCurrentConversationCharacters():Array<Character>
    {
        if (currentConversation == null) {
            return [];
        }
        
        return currentConversation.activeCharacters;
    }
    
    /**
     * Add a conversation rule
     */
    public static function addConversationRule(rule:ConversationRule):Void
    {
        conversationRules.push(rule);
    }
    
    /**
     * Apply conversation rules to a conversation
     */
    private static function applyConversationRules(conversation:Conversation):Void
    {
        for (rule in conversationRules) {
            if (rule.appliesToConversation(conversation.commandBlock.title)) {
                rule.apply(conversation);
            }
        }
    }
    
    /**
     * Get conversation history
     */
    public static function getConversationHistory():Array<String>
    {
        return conversationHistory.copy();
    }
    
    /**
     * Go back to the previous conversation
     */
    public static function goToPreviousConversation():Bool
    {
        if (conversationHistory.length < 2) {
            return false;
        }
        
        // Remove current conversation from history
        conversationHistory.pop();
        
        // Get previous conversation
        var previousName = conversationHistory[conversationHistory.length - 1];
        
        // Don't add to history again since we're going back
        conversationHistory.pop();
        
        return startConversation(previousName);
    }
    
    /**
     * Check if a conversation can be started based on current state
     */
    public static function canStartConversation(conversationName:String):Bool
    {
        var conversation = StoryManager.findConversation(conversationName);
        if (conversation == null) {
            return false;
        }
        
        conversation.updateAvailability();
        return conversation.isAvailable && !conversation.isCompleted;
    }
    
    /**
     * Get all available conversations
     */
    public static function getAvailableConversations():Array<String>
    {
        var available = [];
        var allConversations = StoryManager.getAllConversations();
        
        for (conversation in allConversations) {
            if (canStartConversation(conversation.commandBlock.title)) {
                available.push(conversation.commandBlock.title);
            }
        }
        
        return available;
    }
    
    /**
     * Get debug information about conversation state
     */
    public static function getDebugInfo():Dynamic
    {
        var currentName = currentConversation != null ? currentConversation.commandBlock.title : null;
        var currentCharacters = getCurrentConversationCharacters().map(c -> c.name);
        var globalCharacters = getGlobalActiveCharacters().map(c -> c.name);
        
        return {
            currentConversation: currentName,
            conversationHistory: conversationHistory,
            currentCharacters: currentCharacters,
            globalActiveCharacters: globalCharacters,
            availableConversations: getAvailableConversations(),
            conversationRules: conversationRules.length
        };
    }
    
    /**
     * Validate conversation flow and report issues
     */
    public static function validateConversationFlow():Array<String>
    {
        var issues = [];
        
        // Check for conversations referencing missing characters
        var allConversations = StoryManager.getAllConversations();
        for (conversation in allConversations) {
            for (character in conversation.allCharacters) {
                if (StoryManager.getCharacter(character.name) == null) {
                    issues.push('Conversation "${conversation.title}" references missing character "${character.name}"');
                }
            }
            
            // Check for attached functions that don't exist
            for (func in conversation.attachedFunctions) {
                if (StoryManager.getStoryFunction(func.name) == null) {
                    issues.push('Conversation "${conversation.title}" has attached function "${func.name}" that is not registered');
                }
            }
        }
        
        return issues;
    }
}

/**
 * Represents a rule that can be applied to conversations
 */
class ConversationRule
{
    /**
     * Name of this rule
     */
    public var name:String;
    
    /**
     * Pattern to match conversation names (null means applies to all)
     */
    public var conversationPattern:String;
    
    /**
     * Function to execute when rule is applied
     */
    public var ruleFunction:Conversation -> Void;
    
    public function new(name:String, ruleFunction:Conversation -> Void, ?conversationPattern:String)
    {
        this.name = name;
        this.ruleFunction = ruleFunction;
        this.conversationPattern = conversationPattern;
    }
    
    /**
     * Check if this rule applies to a conversation
     */
    public function appliesToConversation(conversationName:String):Bool
    {
        if (conversationPattern == null) {
            return true;
        }
        
        // Simple pattern matching - can be enhanced with regex if needed
        return conversationName.indexOf(conversationPattern) != -1;
    }
    
    /**
     * Apply this rule to a conversation
     */
    public function apply(conversation:Conversation):Void
    {
        try {
            ruleFunction(conversation);
        } catch (e:Dynamic) {
            trace('Error applying conversation rule "$name": $e');
        }
    }
    
    public function toString():String
    {
        return 'ConversationRule($name, pattern: $conversationPattern)';
    }
}