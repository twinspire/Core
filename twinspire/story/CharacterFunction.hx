package twinspire.story;

/**
 * Represents a function that belongs to a specific character or set of characters.
 * Character functions can modify character states and execute story logic.
 */
class CharacterFunction
{
    /**
     * The name of the function
     */
    public var name:String;
    
    /**
     * Characters this function is restricted to (null means any character can use it)
     */
    public var restrictedToCharacters:Array<String>;
    
    /**
     * Parameters this function accepts with their default values
     */
    public var parameters:Map<String, Dynamic>;
    
    /**
     * The actual function implementation
     */
    public var implementation:Character -> Array<Dynamic> -> Dynamic;
    
    /**
     * Whether this function modifies character state
     */
    public var modifiesState:Bool;
    
    /**
     * Conversations this function is attached to (if any)
     */
    public var attachedConversations:Array<String>;
    
    public function new(name:String, implementation:Character -> Array<Dynamic> -> Dynamic)
    {
        this.name = name;
        this.implementation = implementation;
        this.restrictedToCharacters = null;
        this.parameters = new Map<String, Dynamic>();
        this.modifiesState = false;
        this.attachedConversations = [];
    }
    
    /**
     * Set character restrictions for this function
     */
    public function restrictToCharacters(characters:Array<String>):CharacterFunction
    {
        this.restrictedToCharacters = characters;
        return this;
    }
    
    /**
     * Add a parameter with optional default value
     */
    public function addParameter(paramName:String, ?defaultValue:Dynamic):CharacterFunction
    {
        this.parameters.set(paramName, defaultValue);
        return this;
    }
    
    /**
     * Mark this function as one that modifies character state
     */
    public function setModifiesState(modifies:Bool = true):CharacterFunction
    {
        this.modifiesState = modifies;
        return this;
    }
    
    /**
     * Attach this function to specific conversations
     */
    public function attachToConversations(conversations:Array<String>):CharacterFunction
    {
        this.attachedConversations = conversations;
        return this;
    }
    
    /**
     * Check if this function can be executed by the given character
     */
    public function canExecute(character:Character):Bool
    {
        if (restrictedToCharacters == null) {
            return true;
        }
        
        return restrictedToCharacters.indexOf(character.name) != -1;
    }
    
    /**
     * Execute the function on the given character with the provided arguments
     */
    public function execute(character:Character, args:Array<Dynamic>):Dynamic
    {
        if (!canExecute(character)) {
            throw 'Character "${character.name}" cannot execute function "$name"';
        }
        
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
        
        return implementation(character, finalArgs);
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
        return 'CharacterFunction($name, restricted: $restrictedToCharacters)';
    }
}