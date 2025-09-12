package twinspire.story;

/**
 * Represents a story chapter containing story groups and chapter-scoped variables
 */
class StoryChapter
{
    /**
     * Unique identifier for this chapter
     */
    public var id:String;
    
    /**
     * Display name of the chapter
     */
    public var name:String;
    
    /**
     * Story groups within this chapter
     */
    public var storyGroups:Array<StoryGroup>;
    
    /**
     * Chapter-scoped variables that are accessible to all elements in this chapter
     */
    public var chapterVariables:Map<String, Dynamic>;
    
    /**
     * Whether this chapter has been started
     */
    public var isStarted:Bool;
    
    /**
     * Whether this chapter has been completed
     */
    public var isCompleted:Bool;
    
    public function new(id:String, name:String)
    {
        this.id = id;
        this.name = name;
        this.storyGroups = [];
        this.chapterVariables = new Map<String, Dynamic>();
        this.isStarted = false;
        this.isCompleted = false;
    }
    
    /**
     * Add a story group to this chapter
     */
    public function addStoryGroup(group:StoryGroup):Void
    {
        storyGroups.push(group);
        group.parentChapter = this;
    }
    
    /**
     * Get a chapter variable value
     */
    public function getVariable(name:String):Dynamic
    {
        return chapterVariables.get(name);
    }
    
    /**
     * Set a chapter variable value
     */
    public function setVariable(name:String, value:Dynamic):Void
    {
        chapterVariables.set(name, value);
    }
    
    /**
     * Check if all required conditions are met to start this chapter
     */
    public function canStart():Bool
    {
        // Override in specific implementations or add condition checking logic
        return !isStarted;
    }
    
    /**
     * Start this chapter
     */
    public function start():Void
    {
        if (!canStart()) {
            throw 'Cannot start chapter "$name": conditions not met';
        }
        isStarted = true;
    }
    
    /**
     * Check if this chapter can be completed
     */
    public function canComplete():Bool
    {
        if (!isStarted || isCompleted) {
            return false;
        }
        
        // Check if all story groups are completed (if required)
        for (group in storyGroups) {
            if (!group.isCompleted) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Complete this chapter
     */
    public function complete():Void
    {
        if (!canComplete()) {
            throw 'Cannot complete chapter "$name": conditions not met';
        }
        isCompleted = true;
    }
    
    public function toString():String
    {
        return 'StoryChapter($id: $name, groups: ${storyGroups.length})';
    }
}