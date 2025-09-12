package twinspire.story;

/**
 * Event check types that determine when events should be triggered
 */
enum abstract EventCheckType(Int) from Int to Int
{
    var EVENT_DIALOGUE = 1;
    var EVENT_CONVERSATION_CHANGE = 2;
    var EVENT_CHOICE = 3;
    var EVENT_EXIT = 4;
    var EVENT_CUSTOM = 5;
}

/**
 * Manages the story event system including event registration, triggering, and function execution.
 */
class StoryEventManager
{
    /**
     * Registered events mapped by event name
     */
    private var registeredEvents:Map<String, StoryEvent> = new Map<String, StoryEvent>();
    
    /**
     * Functions registered to respond to specific events
     */
    private var eventFunctions:Map<String, Array<StoryFunction>> = new Map<String, Array<StoryFunction>>();
    
    /**
     * Custom event triggers mapped by trigger function name
     */
    private var customTriggers:Map<String, StoryFunction> = new Map<String, StoryFunction>();

    public function new() {
        
    }
    
    /**
     * Register a new story event
     */
    public function registerEvent(eventName:String, eventData:Dynamic, triggerFunctionName:String, checkType:EventCheckType):Void
    {
        var storyEvent = new StoryEvent(eventName, eventData, triggerFunctionName, checkType);
        registeredEvents.set(eventName, storyEvent);
        
        // Register event template with character state manager
        var memberState = eventData.memberState != null ? eventData.memberState : {};
        var globalState = eventData.state != null ? eventData.state : {};
        var initialMembers = eventData.members != null ? eventData.members : [];
        
        var template = new EventTemplate(memberState, globalState, initialMembers);
        CharacterStateManager.registerEventTemplate(eventName, template);
        
        // Initialize event function list
        if (!eventFunctions.exists(eventName)) {
            eventFunctions.set(eventName, []);
        }
    }
    
    /**
     * Register a function to respond to a specific event
     */
    public function registerEventFunction(eventName:String, func:StoryFunction):Void
    {
        if (!eventFunctions.exists(eventName)) {
            eventFunctions.set(eventName, []);
        }
        
        var functions = eventFunctions.get(eventName);
        if (functions.indexOf(func) == -1) {
            functions.push(func);
            func.registerForEvent(eventName);
        }
    }
    
    /**
     * Register a custom trigger function
     */
    public function registerCustomTrigger(functionName:String, func:StoryFunction):Void
    {
        customTriggers.set(functionName, func);
    }
    
    /**
     * Initialize a character for all registered events
     */
    public function initializeCharacterForAllEvents(character:Character):Void
    {
        for (eventName in registeredEvents.keys()) {
            CharacterStateManager.initializeCharacterForEvent(character, eventName);
        }
    }
    
    /**
     * Trigger dialogue events
     */
    public function triggerDialogueEvents(dialogue:String, ?character:Character):Void
    {
        for (eventName in registeredEvents.keys()) {
            var storyEvent = registeredEvents.get(eventName);
            if (storyEvent.checkType == EVENT_DIALOGUE) {
                triggerEvent(eventName, [dialogue, character]);
            }
        }
    }
    
    /**
     * Trigger conversation change events
     */
    public function triggerConversationChangeEvents(previous:String, next:String):Void
    {
        for (eventName in registeredEvents.keys()) {
            var storyEvent = registeredEvents.get(eventName);
            if (storyEvent.checkType == EVENT_CONVERSATION_CHANGE) {
                CharacterStateManager.setEventConversation(eventName, next);
                triggerEvent(eventName, [previous, next]);
            }
        }
    }
    
    /**
     * Trigger choice events
     */
    public function triggerChoiceEvents(choice:Int, data:Dynamic):Void
    {
        for (eventName in registeredEvents.keys()) {
            var storyEvent = registeredEvents.get(eventName);
            if (storyEvent.checkType == EVENT_CHOICE) {
                triggerEvent(eventName, [choice, data]);
            }
        }
    }
    
    /**
     * Trigger exit events
     */
    public function triggerExitEvents():Void
    {
        for (eventName in registeredEvents.keys()) {
            var storyEvent = registeredEvents.get(eventName);
            if (storyEvent.checkType == EVENT_EXIT) {
                triggerEvent(eventName, []);
            }
        }
    }
    
    /**
     * Trigger a custom event by calling its trigger function
     */
    public function triggerCustomEvent(triggerFunctionName:String, ?args:Array<Dynamic>):Bool
    {
        var triggerFunc = customTriggers.get(triggerFunctionName);
        if (triggerFunc == null) {
            return false;
        }
        
        // Execute trigger function - it should return true to trigger the event
        var result = triggerFunc.execute([], args != null ? args : []);
        
        if (result == true) {
            // Find and trigger the associated event
            for (eventName in registeredEvents.keys()) {
                var storyEvent = registeredEvents.get(eventName);
                if (storyEvent.triggerFunctionName == triggerFunctionName) {
                    triggerEvent(eventName, args != null ? args : []);
                    return true;
                }
            }
        }
        
        return false;
    }
    
    /**
     * Trigger a specific event and execute all associated functions
     */
    public function triggerEvent(eventName:String, ?args:Array<Dynamic>):Void
    {
        var storyEvent = registeredEvents.get(eventName);
        if (storyEvent == null) {
            return;
        }
        
        // Get event members
        var eventMembers = CharacterStateManager.getEventMembers(eventName);
        
        // Execute trigger function if it exists and is custom
        if (storyEvent.checkType == EVENT_CUSTOM && storyEvent.triggerFunctionName != null) {
            var shouldTrigger = triggerCustomEvent(storyEvent.triggerFunctionName, args);
            if (!shouldTrigger) {
                return;
            }
        }
        
        // Execute all functions registered for this event
        var functions = eventFunctions.get(eventName);
        if (functions != null) {
            for (func in functions) {
                if (func.canExecute(eventMembers)) {
                    try {
                        func.execute(eventMembers, args != null ? args : []);
                    } catch (e:Dynamic) {
                        trace('Error executing event function "${func.name}" for event "$eventName": $e');
                    }
                }
            }
        }
    }
    
    /**
     * Add a character to an event's member list
     */
    public function addCharacterToEvent(character:Character, eventName:String):Void
    {
        CharacterStateManager.addCharacterToEvent(character, eventName);
    }
    
    /**
     * Remove a character from an event's member list
     */
    public function removeCharacterFromEvent(character:Character, eventName:String):Void
    {
        CharacterStateManager.removeCharacterFromEvent(character, eventName);
    }
    
    /**
     * Get all characters that are members of a specific event
     */
    public function getEventMembers(eventName:String):Array<Character>
    {
        return CharacterStateManager.getEventMembers(eventName);
    }
    
    /**
     * Check if an event is registered
     */
    public function isEventRegistered(eventName:String):Bool
    {
        return registeredEvents.exists(eventName);
    }
    
    /**
     * Get all registered event names
     */
    public function getRegisteredEventNames():Array<String>
    {
        return [for (name in registeredEvents.keys()) name];
    }
    
    /**
     * Get event information for debugging
     */
    public function getEventInfo(eventName:String):Dynamic
    {
        var storyEvent = registeredEvents.get(eventName);
        if (storyEvent == null) {
            return null;
        }
        
        var functions = eventFunctions.get(eventName);
        var functionNames = functions != null ? [for (func in functions) func.name] : [];
        
        return {
            name: eventName,
            triggerFunction: storyEvent.triggerFunctionName,
            checkType: storyEvent.checkType,
            members: CharacterStateManager.getEventMembers(eventName).map(c -> c.name),
            registeredFunctions: functionNames
        };
    }
    
    /**
     * Validate all registered events and report issues
     */
    public function validateEvents():Array<String>
    {
        var issues = [];
        
        for (eventName in registeredEvents.keys()) {
            var storyEvent = registeredEvents.get(eventName);
            
            // Check if trigger function exists (for custom events)
            if (storyEvent.checkType == EVENT_CUSTOM && storyEvent.triggerFunctionName != null) {
                if (!customTriggers.exists(storyEvent.triggerFunctionName)) {
                    issues.push('Event "$eventName" references missing trigger function "${storyEvent.triggerFunctionName}"');
                }
            }
            
            // Check if event functions are valid
            var functions = eventFunctions.get(eventName);
            if (functions != null) {
                for (func in functions) {
                    if (func.eventName != eventName) {
                        issues.push('Function "${func.name}" registered for event "$eventName" but has eventName "${func.eventName}"');
                    }
                }
            }
        }
        
        return issues;
    }
    
    /**
     * Get debug information about the event system
     */
    public function getDebugInfo():Dynamic
    {
        var eventInfo = {};
        
        var count = 0;
        for (eventName in registeredEvents.keys()) {
            count++;
            Reflect.setField(eventInfo, eventName, getEventInfo(eventName));
        }
        
        return {
            events: eventInfo,
            totalEvents: count,
            totalCustomTriggers: count
        };
    }
}

/**
 * Represents a story event with its configuration and trigger conditions
 */
class StoryEvent
{
    /**
     * Name of the event
     */
    public var name:String;
    
    /**
     * Initial event data (members, state, memberState)
     */
    public var eventData:Dynamic;
    
    /**
     * Name of the function that determines if this event should trigger
     */
    public var triggerFunctionName:String;
    
    /**
     * When this event should be checked/triggered
     */
    public var checkType:EventCheckType;
    
    public function new(name:String, eventData:Dynamic, triggerFunctionName:String, checkType:EventCheckType)
    {
        this.name = name;
        this.eventData = eventData;
        this.triggerFunctionName = triggerFunctionName;
        this.checkType = checkType;
    }
    
    public function toString():String
    {
        return 'StoryEvent($name, trigger: $triggerFunctionName, type: $checkType)';
    }
}