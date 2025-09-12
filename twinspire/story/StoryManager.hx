package twinspire.story;

/**
 * Global manager for story engine functionality.
 * Manages characters, conversations, story functions, and events.
 */
class StoryManager
{
    /**
     * All registered characters in the story
     */
    private static var characters:Map<String, Character> = new Map<String, Character>();
    
    /**
     * All conversations in the story
     */
    private static var conversations:Map<String, Conversation> = new Map<String, Conversation>();
    
    /**
     * All registered story functions
     */
    private static var storyFunctions:Map<String, StoryFunction> = new Map<String, StoryFunction>();
    
    /**
     * All story chapters
     */
    private static var chapters:Map<String, StoryChapter> = new Map<String, StoryChapter>();
    
    /**
     * Global event registry
     */
    private static var events:StoryEventManager = new StoryEventManager();
    
    /**
     * Current active conversation
     */
    private static var currentConversation:String = "";
    
    /**
     * Function execution queue for character-aware functions
     */
    private static var functionQueue:Array<QueuedFunction> = [];
    
    /**
     * Initialize the story manager
     */
    public static function initialize():Void
    {
        characters.clear();
        conversations.clear();
        storyFunctions.clear();
        chapters.clear();
        events = new StoryEventManager();
        currentConversation = "";
        functionQueue = [];
    }
    
    /**
     * Register a character with the story manager
     */
    public static function registerCharacter(character:Character):Void
    {
        characters.set(character.name, character);
        
        // Initialize character for all registered events
        events.initializeCharacterForAllEvents(character);
    }
    
    /**
     * Get a character by name
     */
    public static function getCharacter(name:String):Character
    {
        return characters.get(name);
    }
    
    /**
     * Get all registered characters
     */
    public static function getAllCharacters():Array<Character>
    {
        return [for (char in characters) char];
    }
    
    /**
     * Register a conversation from a CommandBlock
     */
    public static function registerConversation(commandBlock:CommandBlock):Conversation
    {
        var conversation = new Conversation(commandBlock);
        conversations.set(commandBlock.title, conversation);
        return conversation;
    }
    
    /**
     * Find a conversation by name
     */
    public static function findConversation(name:String):Conversation
    {
        return conversations.get(name);
    }
    
    /**
     * Get all conversations
     */
    public static function getAllConversations():Array<Conversation>
    {
        return [for (conv in conversations) conv];
    }
    
    /**
     * Register a story function
     */
    public static function registerStoryFunction(func:StoryFunction):Void
    {
        storyFunctions.set(func.name, func);
    }
    
    /**
     * Get a story function by name
     */
    public static function getStoryFunction(name:String):StoryFunction
    {
        return storyFunctions.get(name);
    }
    
    /**
     * Execute a story function with given characters and arguments
     */
    public static function executeStoryFunction(functionName:String, characters:Array<String>, ?args:Array<Dynamic>):Dynamic
    {
        var func = getStoryFunction(functionName);
        if (func == null) {
            throw 'Story function "$functionName" not found';
        }
        
        var targetCharacters = [];
        for (charName in characters) {
            var char = getCharacter(charName);
            if (char != null) {
                targetCharacters.push(char);
            } else {
                throw 'Character "$charName" not found';
            }
        }
        
        return func.execute(targetCharacters, args != null ? args : []);
    }
    
    /**
     * Queue a function for execution when required characters become available
     */
    public static function queueFunction(functionName:String, requiredCharacters:Array<String>, ?args:Array<Dynamic>):Void
    {
        var queuedFunc = new QueuedFunction(functionName, requiredCharacters, args != null ? args : []);
        functionQueue.push(queuedFunc);
    }
    
    /**
     * Process the function queue and execute any functions that can now run
     */
    public static function processFunctionQueue():Array<String>
    {
        var executedFunctions = [];
        var remainingQueue = [];
        
        for (queuedFunc in functionQueue) {
            var canExecute = true;
            var targetCharacters = [];
            
            for (charName in queuedFunc.requiredCharacters) {
                var char = getCharacter(charName);
                if (char != null && char.currentConversation == currentConversation) {
                    targetCharacters.push(char);
                } else {
                    canExecute = false;
                    break;
                }
            }
            
            if (canExecute) {
                try {
                    executeStoryFunction(queuedFunc.functionName, queuedFunc.requiredCharacters, queuedFunc.args);
                    executedFunctions.push(queuedFunc.functionName);
                } catch (e:Dynamic) {
                    // Function failed to execute, keep it in queue
                    remainingQueue.push(queuedFunc);
                }
            } else {
                // Not all characters available yet
                remainingQueue.push(queuedFunc);
            }
        }
        
        functionQueue = remainingQueue;
        return executedFunctions;
    }
    
    /**
     * Register a story chapter
     */
    public static function registerChapter(chapter:StoryChapter):Void
    {
        chapters.set(chapter.id, chapter);
    }
    
    /**
     * Get a story chapter by ID
     */
    public static function getChapter(id:String):StoryChapter
    {
        return chapters.get(id);
    }
    
    /**
     * Set the current active conversation
     */
    public static function setCurrentConversation(conversationName:String):Void
    {
        var previous = currentConversation;
        currentConversation = conversationName;
        
        // Trigger conversation change events
        var conversation = findConversation(conversationName);
        if (conversation != null) {
            conversation.eventHandlers.triggerConversationChange(previous, conversationName);
        }
        
        // Process function queue in case new characters are now available
        processFunctionQueue();
    }
    
    /**
     * Get the current conversation name
     */
    public static function getCurrentConversation():String
    {
        return currentConversation;
    }
    
    /**
     * Get the event manager
     */
    public static function getEventManager():StoryEventManager
    {
        return events;
    }
    
    /**
     * Process a dialogue line and trigger relevant events and functions
     */
    public static function processDialogue(dialogue:String, ?characterName:String):Void
    {
        var character:Character = null;
        if (characterName != null) {
            character = getCharacter(characterName);
        }
        
        var conversation = findConversation(currentConversation);
        if (conversation != null) {
            conversation.processDialogue(dialogue, character);
        }
        
        // Trigger global events
        events.triggerDialogueEvents(dialogue, character);
        
        // Process function queue
        processFunctionQueue();
    }
    
    /**
     * Validate the current story state and report any issues
     */
    public static function validateStoryState():Array<String>
    {
        var issues = [];
        
        // Check for functions with missing required characters
        for (func in storyFunctions) {
            for (requiredChar in func.requiredCharacters) {
                if (!characters.exists(requiredChar)) {
                    issues.push('Story function "${func.name}" requires character "$requiredChar" which is not registered');
                }
            }
        }
        
        // Check for conversations referencing missing characters
        for (conversation in conversations) {
            for (char in conversation.allCharacters) {
                if (!characters.exists(char.name)) {
                    issues.push('Conversation "${conversation.commandBlock.title}" references unregistered character "${char.name}"');
                }
            }
        }
        
        return issues;
    }
    
    /**
     * Get debug information about the current story state
     */
    public static function getDebugInfo():Dynamic
    {
        return {
            characters: [for (name in characters.keys()) name],
            conversations: [for (name in conversations.keys()) name],
            storyFunctions: [for (name in storyFunctions.keys()) name],
            chapters: [for (id in chapters.keys()) id],
            currentConversation: currentConversation,
            queuedFunctions: functionQueue.length,
            registeredEvents: events.getRegisteredEventNames()
        };
    }
}

/**
 * Represents a queued function waiting for required characters to become available
 */
class QueuedFunction
{
    public var functionName:String;
    public var requiredCharacters:Array<String>;
    public var args:Array<Dynamic>;
    
    public function new(functionName:String, requiredCharacters:Array<String>, args:Array<Dynamic>)
    {
        this.functionName = functionName;
        this.requiredCharacters = requiredCharacters;
        this.args = args;
    }
    
    public function toString():String
    {
        return 'QueuedFunction($functionName, required: $requiredCharacters)';
    }
}