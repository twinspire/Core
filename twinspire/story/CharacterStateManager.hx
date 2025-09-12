package twinspire.story;

/**
 * Manages character states across different events.
 * Handles initialization of character states for events and provides
 * utilities for state manipulation and querying.
 */
class CharacterStateManager
{
    /**
     * Event templates for initializing character states
     */
    private static var eventTemplates:Map<String, EventTemplate> = new Map<String, EventTemplate>();
    
    /**
     * Characters that have been initialized for each event
     */
    private static var initializedCharacters:Map<String, Array<String>> = new Map<String, Array<String>>();
    
    /**
     * Register an event template for character state initialization
     */
    public static function registerEventTemplate(eventName:String, template:EventTemplate):Void
    {
        eventTemplates.set(eventName, template);
        initializedCharacters.set(eventName, []);
    }
    
    /**
     * Initialize a character for a specific event using the event template
     */
    public static function initializeCharacterForEvent(character:Character, eventName:String):Void
    {
        var template = eventTemplates.get(eventName);
        if (template == null) {
            throw 'Event template "$eventName" not found';
        }
        
        var initializedList = initializedCharacters.get(eventName);
        if (initializedList.indexOf(character.name) != -1) {
            // Character already initialized for this event
            return;
        }
        
        // Initialize character's event state from template
        character.initializeEventState(eventName, template.memberState);
        
        // Add character to event's member list if specified in template
        if (template.initialMembers != null && template.initialMembers.indexOf(character.name) != -1) {
            addCharacterToEvent(character, eventName);
        }
        
        // Mark character as initialized for this event
        initializedList.push(character.name);
    }
    
    /**
     * Add a character to an event's member list
     */
    public static function addCharacterToEvent(character:Character, eventName:String):Void
    {
        var template = eventTemplates.get(eventName);
        if (template == null) {
            throw 'Event template "$eventName" not found';
        }
        
        if (template.currentMembers.indexOf(character.name) == -1) {
            template.currentMembers.push(character.name);
        }
        
        // Ensure character is initialized for this event
        initializeCharacterForEvent(character, eventName);
    }
    
    /**
     * Remove a character from an event's member list
     */
    public static function removeCharacterFromEvent(character:Character, eventName:String):Void
    {
        var template = eventTemplates.get(eventName);
        if (template == null) {
            throw 'Event template "$eventName" not found';
        }
        
        template.currentMembers.remove(character.name);
    }
    
    /**
     * Get all characters that are members of a specific event
     */
    public static function getEventMembers(eventName:String):Array<Character>
    {
        var template = eventTemplates.get(eventName);
        if (template == null) {
            return [];
        }
        
        var members = [];
        for (memberName in template.currentMembers) {
            var character = StoryManager.getCharacter(memberName);
            if (character != null) {
                members.push(character);
            }
        }
        
        return members;
    }
    
    /**
     * Check if a character is a member of a specific event
     */
    public static function isCharacterInEvent(character:Character, eventName:String):Bool
    {
        var template = eventTemplates.get(eventName);
        if (template == null) {
            return false;
        }
        
        return template.currentMembers.indexOf(character.name) != -1;
    }
    
    /**
     * Get the event state for a specific event
     */
    public static function getEventState(eventName:String):Dynamic
    {
        var template = eventTemplates.get(eventName);
        if (template == null) {
            return null;
        }
        
        return template.globalState;
    }
    
    /**
     * Set a value in the global state of an event
     */
    public static function setEventState(eventName:String, key:String, value:Dynamic):Void
    {
        var template = eventTemplates.get(eventName);
        if (template == null) {
            throw 'Event template "$eventName" not found';
        }
        
        Reflect.setField(template.globalState, key, value);
    }
    
    /**
     * Get a value from the global state of an event
     */
    public static function getEventStateValue(eventName:String, key:String):Dynamic
    {
        var template = eventTemplates.get(eventName);
        if (template == null) {
            return null;
        }
        
        return Reflect.field(template.globalState, key);
    }
    
    /**
     * Set the current conversation for an event
     */
    public static function setEventConversation(eventName:String, conversationName:String):Void
    {
        var template = eventTemplates.get(eventName);
        if (template != null) {
            template.currentConversation = conversationName;
        }
    }
    
    /**
     * Get the current conversation for an event
     */
    public static function getEventConversation(eventName:String):String
    {
        var template = eventTemplates.get(eventName);
        if (template == null) {
            return "";
        }
        
        return template.currentConversation;
    }
    
    /**
     * Initialize all registered characters for all events
     */
    public static function initializeAllCharactersForAllEvents():Void
    {
        var allCharacters = StoryManager.getAllCharacters();
        
        for (eventName in eventTemplates.keys()) {
            for (character in allCharacters) {
                initializeCharacterForEvent(character, eventName);
            }
        }
    }
    
    /**
     * Reset all event states and character memberships
     */
    public static function resetAllEvents():Void
    {
        for (eventName in eventTemplates.keys()) {
            var template = eventTemplates.get(eventName);
            if (template != null) {
                template.currentMembers = [];
                template.currentConversation = "";
                
                // Reset global state to initial values
                var initialState = {};
                var fields = Reflect.fields(template.initialGlobalState);
                for (field in fields) {
                    Reflect.setField(initialState, field, Reflect.field(template.initialGlobalState, field));
                }
                template.globalState = initialState;
            }
            
            initializedCharacters.set(eventName, []);
        }
        
        // Re-initialize all characters
        initializeAllCharactersForAllEvents();
    }
    
    /**
     * Get debug information about all events and character states
     */
    public static function getDebugInfo():Dynamic
    {
        var eventInfo = {};
        
        var count = 0;
        for (eventName in eventTemplates.keys()) {
            var template = eventTemplates.get(eventName);
            var initialized = initializedCharacters.get(eventName);
            
            Reflect.setField(eventInfo, eventName, {
                currentMembers: template.currentMembers,
                initializedCharacters: initialized,
                currentConversation: template.currentConversation,
                globalState: template.globalState
            });
            count++;
        }
        
        return {
            events: eventInfo,
            totalEvents: count
        };
    }
    
    /**
     * Validate character states and report any issues
     */
    public static function validateCharacterStates():Array<String>
    {
        var issues = [];
        
        for (eventName in eventTemplates.keys()) {
            var template = eventTemplates.get(eventName);
            
            // Check if all current members are valid characters
            for (memberName in template.currentMembers) {
                var character = StoryManager.getCharacter(memberName);
                if (character == null) {
                    issues.push('Event "$eventName" has invalid member "$memberName"');
                } else {
                    // Check if character has event state initialized
                    if (!character.eventStates.exists(eventName)) {
                        issues.push('Character "$memberName" is member of event "$eventName" but has no event state');
                    }
                }
            }
        }
        
        return issues;
    }
}