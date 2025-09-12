package twinspire.story;

/**
 * Template for initializing character states in events
 */
class EventTemplate
{
    /**
     * Initial member list for this event
     */
    public var initialMembers:Array<String>;
    
    /**
     * Current members of this event
     */
    public var currentMembers:Array<String>;
    
    /**
     * Template for initializing character member states
     */
    public var memberState:Dynamic;
    
    /**
     * Global state for this event (shared across all characters)
     */
    public var globalState:Dynamic;
    
    /**
     * Initial global state (for reset purposes)
     */
    public var initialGlobalState:Dynamic;
    
    /**
     * Current conversation for this event
     */
    public var currentConversation:String;
    
    public function new(memberState:Dynamic, globalState:Dynamic, ?initialMembers:Array<String>)
    {
        this.initialMembers = initialMembers != null ? initialMembers : [];
        this.currentMembers = [];
        this.memberState = memberState;
        this.globalState = globalState;
        this.currentConversation = "";
        
        // Store copy of initial global state for resets
        this.initialGlobalState = {};
        var fields = Reflect.fields(globalState);
        for (field in fields) {
            Reflect.setField(this.initialGlobalState, field, Reflect.field(globalState, field));
        }
    }
    
    public function toString():String
    {
        return 'EventTemplate(members: ${currentMembers.length}, conversation: $currentConversation)';
    }
}