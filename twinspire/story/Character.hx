package twinspire.story;

using StringTools;

/**
 * Represents a character in the story engine with event-scoped state management.
 * Characters maintain both global states and event-specific states that can be
 * modified by story functions and tracked across conversations.
 */
class Character
{
    /**
     * The unique name/identifier of the character
     */
    public var name:String;
    
    /**
     * Global character state that persists across all events and conversations.
     * This contains base character attributes like relationships, personality traits, etc.
     */
    public var globalState:Dynamic;
    
    /**
     * Event-scoped states for this character. Each event can have its own state
     * that is separate from global state and other events.
     */
    public var eventStates:Map<String, Dynamic>;
    
    /**
     * Character functions that are specific to this character.
     * These are called using the character.functionName() syntax.
     */
    public var characterFunctions:Map<String, CharacterFunction>;
    
    /**
     * Tracks which conversations this character has participated in
     */
    public var conversationHistory:Array<String>;
    
    /**
     * Tracks the current conversation this character is in (if any)
     */
    public var currentConversation:String;
    
    public function new(name:String, ?initialState:Dynamic)
    {
        this.name = name;
        this.globalState = initialState != null ? initialState : {};
        this.eventStates = new Map<String, Dynamic>();
        this.characterFunctions = new Map<String, CharacterFunction>();
        this.conversationHistory = [];
        this.currentConversation = "";
    }
    
    /**
     * Get a state value from global state
     */
    public function getGlobalState(key:String):Dynamic
    {
        if (!Reflect.hasField(globalState, key)) {
            return null;
        }
        return Reflect.field(globalState, key);
    }
    
    /**
     * Set a state value in global state
     */
    public function setGlobalState(key:String, value:Dynamic):Void
    {
        Reflect.setField(globalState, key, value);
    }
    
    /**
     * Get a state value from a specific event's state
     */
    public function getEventState(eventName:String, key:String):Dynamic
    {
        if (!eventStates.exists(eventName)) {
            return null;
        }
        
        var eventState = eventStates.get(eventName);
        if (!Reflect.hasField(eventState, key)) {
            return null;
        }
        
        return Reflect.field(eventState, key);
    }
    
    /**
     * Set a state value in a specific event's state
     */
    public function setEventState(eventName:String, key:String, value:Dynamic):Void
    {
        if (!eventStates.exists(eventName)) {
            eventStates.set(eventName, {});
        }
        
        var eventState = eventStates.get(eventName);
        Reflect.setField(eventState, key, value);
    }
    
    /**
     * Initialize event state for this character from event template
     */
    public function initializeEventState(eventName:String, memberStateTemplate:Dynamic):Void
    {
        if (!eventStates.exists(eventName)) {
            // Create a copy of the template for this character
            var newState = {};
            var fields = Reflect.fields(memberStateTemplate);
            for (field in fields) {
                Reflect.setField(newState, field, Reflect.field(memberStateTemplate, field));
            }
            eventStates.set(eventName, newState);
        }
    }
    
    /**
     * Add this character to a conversation
     */
    public function enterConversation(conversationName:String):Void
    {
        currentConversation = conversationName;
        if (conversationHistory.indexOf(conversationName) == -1) {
            conversationHistory.push(conversationName);
        }
    }
    
    /**
     * Remove this character from current conversation
     */
    public function exitConversation():Void
    {
        currentConversation = "";
    }
    
    /**
     * Register a character-specific function
     */
    public function registerFunction(functionName:String, func:CharacterFunction):Void
    {
        characterFunctions.set(functionName, func);
    }
    
    /**
     * Execute a character-specific function if it exists
     */
    public function executeFunction(functionName:String, ?args:Array<Dynamic>):Dynamic
    {
        if (!characterFunctions.exists(functionName)) {
            throw 'Character function "$functionName" not found for character "$name"';
        }
        
        var func = characterFunctions.get(functionName);
        return func.execute(this, args != null ? args : []);
    }
    
    /**
     * Check if this character has a specific function
     */
    public function hasFunction(functionName:String):Bool
    {
        return characterFunctions.exists(functionName);
    }
    
    /**
     * Get string representation for debugging
     */
    public function toString():String
    {
        return 'Character($name, currentConversation: $currentConversation)';
    }
}