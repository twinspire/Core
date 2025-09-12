package twinspire.story;

/**
 * Represents a global story function that can be called from anywhere in the story.
 * Story functions can work with multiple characters and handle complex story logic.
 */
class StoryFunction
{
    /**
     * The name of the function
     */
    public var name:String;
    
    /**
     * Characters this function requires to be present for execution
     */
    public var requiredCharacters:Array<String>;
    
    /**
     * Parameters this function accepts with their default values
     */
    public var parameters:Map<String, Dynamic>;
    
    /**
     * The actual function implementation
     */
    public var implementation:Array<Character> -> Array<Dynamic> -> Dynamic;
    
    /**
     * Whether this function modifies character states
     */
    public var modifiesState:Bool;
    
    /**
     * Conversations this function is attached to (if any)
     */
    public var attachedConversations:Array<String>;
    
    /**
     * Event this function is registered to respond to (if any)
     */
    public var eventName:String;
    
    /**
     * Whether this function should be queued until all required characters are present
     */
    public var requiresAllCharacters:Bool;
    
    public function new(name:String, implementation:Array<Character> -> Array<Dynamic> -> Dynamic)
    {
        this.name = name;
        this.implementation = implementation;
        this.requiredCharacters = [];
        this.parameters = new Map<String, Dynamic>();
        this.modifiesState = false;
        this.attachedConversations = [];
        this.eventName = null;
        this.requiresAllCharacters = true;
    }
    
    /**
     * Set the characters required for this function to execute
     */
    public function setRequiredCharacters(characters:Array<String>):StoryFunction
    {
        this.requiredCharacters = characters;
        return this;
    }
    
    /**
     * Add a parameter with optional default value
     */
    public function addParameter(paramName:String, ?defaultValue:Dynamic):StoryFunction
    {
        this.parameters.set(paramName, defaultValue);
        return this;
    }
    
    /**
     * Mark this function as one that modifies character state
     */
    public function setModifiesState(modifies:Bool = true):StoryFunction
    {
        this.modifiesState = modifies;
        return this;
    }
    
    /**
     * Attach this function to specific conversations
     */
    public function attachToConversations(conversations:Array<String>):StoryFunction
    {
        this.attachedConversations = conversations;
        return this;
    }
    
    /**
     * Register this function to respond to an event
     */
    public function registerForEvent(eventName:String):StoryFunction
    {
        this.eventName = eventName;
        return this;
    }
    
    /**
     * Set whether all required characters must be present (default: true)
     */
    public function setRequiresAllCharacters(requires:Bool):StoryFunction
    {
        this.requiresAllCharacters = requires;
        return this;
    }
    
    /**
     * Check if this function can be executed with the given characters
     */
    public function canExecute(availableCharacters:Array<Character>):Bool
    {
        if (requiredCharacters.length == 0) {
            return true;
        }
        
        if (!requiresAllCharacters && availableCharacters.length > 0) {
            // If we don't require all characters, just need at least one match
            for (char in availableCharacters) {
                if (requiredCharacters.indexOf(char.name) != -1) {
                    return true;
                }
            }
            return false;
        }
        
        // Check if all required characters are available
        for (requiredChar in requiredCharacters) {
            var found = false;
            for (char in availableCharacters) {
                if (char.name == requiredChar) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Get the subset of characters that this function needs from available characters
     */
    public function getRequiredCharacters(availableCharacters:Array<Character>):Array<Character>
    {
        if (requiredCharacters.length == 0) {
            return availableCharacters;
        }
        
        var result = [];
        for (char in availableCharacters) {
            if (requiredCharacters.indexOf(char.name) != -1) {
                result.push(char);
            }
        }
        
        return result;
    }
    
    /**
     * Execute the function with the given characters and arguments
     */
    public function execute(characters:Array<Character>, args:Array<Dynamic>):Dynamic
    {
        if (!canExecute(characters)) {
            var availableNames = [for (char in characters) char.name];
            throw 'Cannot execute function "$name": required characters $requiredCharacters, available: $availableNames';
        }
        
        var targetCharacters = getRequiredCharacters(characters);
        
        // Fill in default parameter values if not provided
        var finalArgs = [];
        var paramNames = [for (key in parameters.keys()) key];
        
        for (i in 0...paramNames.length) {
            var paramName = paramNames[i];
            var defaultValue = parameters.get(paramName);
            
            if (i < args.length) {
                finalArgs.push(args[i]);
            } else if (defaultValue != null) {
                finalArgs.push(defaultValue);
            } else {
                finalArgs.push(null);
            }
        }
        
        return implementation(targetCharacters, finalArgs);
    }
    
    /**
     * Check if this function is attached to a specific conversation
     */
    public function isAttachedTo(conversationName:String):Bool
    {
        return attachedConversations.indexOf(conversationName) != -1;
    }
    
    public function toString():String
    {
        return 'StoryFunction($name, required: $requiredCharacters, event: $eventName)';
    }
}