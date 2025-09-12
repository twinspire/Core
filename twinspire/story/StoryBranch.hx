package twinspire.story;

/**
 * Represents a story branch with conditions and conversation references
 */
class StoryBranch
{
    /**
     * Unique identifier for this branch
     */
    public var id:String;
    
    /**
     * Display name of the branch
     */
    public var name:String;
    
    /**
     * The group this branch belongs to
     */
    public var parentGroup:StoryGroup;
    
    /**
     * Conditions that must be met for this branch to be available
     */
    public var conditions:Array<String>;
    
    /**
     * Requirements that must be met for this branch to be available
     */
    public var requirements:Array<String>;
    
    /**
     * Conversation blocks that are part of this branch
     */
    public var conversationBlocks:Array<String>;
    
    /**
     * Conversation blocks that should be excluded when this branch is active
     */
    public var excludedBlocks:Array<String>;
    
    /**
     * Whether this branch has been started
     */
    public var isStarted:Bool;
    
    /**
     * Whether this branch has been completed
     */
    public var isCompleted:Bool;
    
    /**
     * Whether this branch is currently available
     */
    public var isAvailable:Bool;
    
    /**
     * Priority of this branch when multiple branches are available
     */
    public var priority:Int;
    
    public function new(id:String, name:String)
    {
        this.id = id;
        this.name = name;
        this.conditions = [];
        this.requirements = [];
        this.conversationBlocks = [];
        this.excludedBlocks = [];
        this.isStarted = false;
        this.isCompleted = false;
        this.isAvailable = false;
        this.priority = 0;
    }
    
    /**
     * Add a condition for this branch's availability
     */
    public function addCondition(condition:String):Void
    {
        conditions.push(condition);
    }
    
    /**
     * Add a requirement for this branch's availability
     */
    public function addRequirement(requirement:String):Void
    {
        requirements.push(requirement);
    }
    
    /**
     * Add a conversation block to this branch
     */
    public function addConversationBlock(blockName:String):Void
    {
        conversationBlocks.push(blockName);
    }
    
    /**
     * Add a conversation block to exclude when this branch is active
     */
    public function addExcludedBlock(blockName:String):Void
    {
        excludedBlocks.push(blockName);
    }
    
    /**
     * Check if all conditions and requirements are met
     */
    public function checkAvailability():Bool
    {
        // This will be implemented in Stage 2 when we have expression evaluation
        // For now, assume branch is available if no conditions/requirements are specified
        return conditions.length == 0 && requirements.length == 0;
    }
    
    /**
     * Update the availability status of this branch
     */
    public function updateAvailability():Void
    {
        isAvailable = checkAvailability();
    }
    
    /**
     * Check if this branch can be started
     */
    public function canStart():Bool
    {
        return !isStarted && isAvailable;
    }
    
    /**
     * Start this branch
     */
    public function start():Void
    {
        if (!canStart()) {
            throw 'Cannot start story branch "$name": not available or already started';
        }
        isStarted = true;
    }
    
    /**
     * Set the priority of this branch
     */
    public function setPriority(priority:Int):Void
    {
        this.priority = priority;
    }
    
    public function toString():String
    {
        return 'StoryBranch($id: $name, available: $isAvailable, priority: $priority)';
    }
}