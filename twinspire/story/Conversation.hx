package twinspire.story;

/**
 * Extensions to the existing conversation system to support story engine features.
 * This class maintains compatibility with existing CommandBlock while adding
 * story-specific functionality.
 */
class Conversation
{

    /**
     * The underlying CommandBlock for compatibility
     */
    public var commandBlock:CommandBlock;
    
    /**
     * Characters currently participating in this conversation
     */
    public var activeCharacters:Array<Character>;
    
    /**
     * All characters that have participated in this conversation
     */
    public var allCharacters:Array<Character>;
    
    /**
     * Functions attached to this conversation
     */
    public var attachedFunctions:Array<StoryFunction>;
    
    /**
     * Event handlers for this conversation
     */
    public var eventHandlers:ConversationEvents;
    
    /**
     * Story branch this conversation belongs to (if any)
     */
    public var storyBranch:StoryBranch;
    
    /**
     * Whether this conversation has been completed
     */
    public var isCompleted:Bool;
    
    /**
     * Whether this conversation is currently available
     */
    public var isAvailable:Bool;
    
    /**
     * Conditions for this conversation's availability
     */
    public var conditions:Array<String>;

    /**
    * Get the title of the underlying command block.
    **/
    public var title(get, never):String;
    function get_title() {
        return commandBlock.title;
    }
    
    public function new(commandBlock:CommandBlock)
    {
        this.commandBlock = commandBlock;
        this.activeCharacters = [];
        this.allCharacters = [];
        this.attachedFunctions = [];
        this.eventHandlers = new ConversationEvents();
        this.storyBranch = null;
        this.isCompleted = false;
        this.isAvailable = true;
        this.conditions = [];
    }
    
    /**
     * Add a character to this conversation
     */
    public function addCharacter(character:Character):Void
    {
        if (activeCharacters.indexOf(character) == -1) {
            activeCharacters.push(character);
            character.enterConversation(commandBlock.title);
        }
        
        if (allCharacters.indexOf(character) == -1) {
            allCharacters.push(character);
        }
    }
    
    /**
     * Remove a character from this conversation
     */
    public function removeCharacter(character:Character):Void
    {
        activeCharacters.remove(character);
        character.exitConversation();
    }
    
    /**
     * Get character by name
     */
    public function getCharacter(name:String):Character
    {
        for (char in allCharacters) {
            if (char.name == name) {
                return char;
            }
        }
        return null;
    }
    
    /**
     * Attach a function to this conversation
     */
    public function attachFunction(func:StoryFunction):Void
    {
        if (attachedFunctions.indexOf(func) == -1) {
            attachedFunctions.push(func);
        }
    }
    
    /**
     * Trigger a specific function with given characters and arguments
     */
    public function triggerFunction(functionName:String, ?characters:Array<String>, ?args:Array<Dynamic>):Dynamic
    {
        for (func in attachedFunctions) {
            if (func.name == functionName) {
                var targetCharacters = [];
                
                if (characters != null) {
                    // Use specified characters
                    for (charName in characters) {
                        var char = getCharacter(charName);
                        if (char != null) {
                            targetCharacters.push(char);
                        }
                    }
                } else {
                    // Use currently active characters
                    targetCharacters = activeCharacters.copy();
                }
                
                return func.execute(targetCharacters, args != null ? args : []);
            }
        }
        
        throw 'Function "$functionName" not found in conversation "${commandBlock.title}"';
    }
    
    /**
     * Process dialogue and trigger any relevant functions
     */
    public function processDialogue(dialogue:String, ?character:Character):Void
    {
        // Add character if provided and not already active
        if (character != null) {
            addCharacter(character);
        }
        
        // Trigger onDialogue event
        eventHandlers.triggerDialogue(dialogue, character);
        
        // Execute any functions that should run on dialogue
        for (func in attachedFunctions) {
            if (func.eventName == "onDialogue" && func.canExecute(activeCharacters)) {
                func.execute(activeCharacters, [dialogue, character]);
            }
        }
    }
    
    /**
     * Check if this conversation's conditions are met
     */
    public function checkConditions():Bool
    {
        // This will be implemented in Stage 2 when we have expression evaluation
        return conditions.length == 0;
    }
    
    /**
     * Update availability status
     */
    public function updateAvailability():Void
    {
        isAvailable = checkConditions() && !isCompleted;
    }
    
    /**
     * Complete this conversation
     */
    public function complete():Void
    {
        isCompleted = true;
        
        // Remove all characters from this conversation
        for (char in activeCharacters.copy()) {
            removeCharacter(char);
        }
        
        // Trigger onExit event
        eventHandlers.triggerExit();
    }
    
    public function toString():String
    {
        return 'Conversation(${this.title}, active: ${activeCharacters.length}, functions: ${attachedFunctions.length})';
    }
}