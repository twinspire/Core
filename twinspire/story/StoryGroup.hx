package twinspire.story;

/**
 * Represents a story group containing multiple story branches
 */
class StoryGroup
{
    /**
     * Unique identifier for this group
     */
    public var id:String;
    
    /**
     * Display name of the group
     */
    public var name:String;
    
    /**
     * The chapter this group belongs to
     */
    public var parentChapter:StoryChapter;
    
    /**
     * Story branches within this group
     */
    public var storyBranches:Array<StoryBranch>;
    
    /**
     * Whether this group has been started
     */
    public var isStarted:Bool;
    
    /**
     * Whether this group has been completed
     */
    public var isCompleted:Bool;
    
    /**
     * Group-specific conditions for availability
     */
    public var conditions:Array<String>;
    
    public function new(id:String, name:String)
    {
        this.id = id;
        this.name = name;
        this.storyBranches = [];
        this.isStarted = false;
        this.isCompleted = false;
        this.conditions = [];
    }
    
    /**
     * Add a story branch to this group
     */
    public function addStoryBranch(branch:StoryBranch):Void
    {
        storyBranches.push(branch);
        branch.parentGroup = this;
    }
    
    /**
     * Add a condition for this group's availability
     */
    public function addCondition(condition:String):Void
    {
        conditions.push(condition);
    }
    
    /**
     * Check if this group's conditions are met
     */
    public function checkConditions():Bool
    {
        // This will be implemented in Stage 2 when we have expression evaluation
        // For now, assume conditions are met if no conditions are specified
        return conditions.length == 0;
    }
    
    /**
     * Check if this group can be started
     */
    public function canStart():Bool
    {
        return !isStarted && checkConditions();
    }
    
    /**
     * Start this group
     */
    public function start():Void
    {
        if (!canStart()) {
            throw 'Cannot start story group "$name": conditions not met';
        }
        isStarted = true;
    }
    
    public function toString():String
    {
        return 'StoryGroup($id: $name, branches: ${storyBranches.length})';
    }
}