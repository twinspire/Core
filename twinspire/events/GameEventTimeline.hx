package twinspire.events;

import kha.Scheduler;
import kha.Scheduler.FrameTask;

class GameEventTimeline {
    
    private static var _id:Int = -1;
    private var _groupId:Int;

    /**
    * The ID of this timeline.
    **/
    public var id:Id;
    /**
    * The animation index to operate the timeline.
    **/
    public var animIndex:Int;
    /**
    * A collection of nodes for this timeline.
    **/
    public var nodes:Array<GameEventTimeNode>;
    /**
    * A collection of alternate nodes for this timeline.
    **/
    public var alternate:Array<GameEventTimeNode>;
    /**
    * Specifies the current active node.
    **/
    public var currentNode:Int;
    /**
    * Specifies how this timeline is processed.
    **/
    public var type:TimelineProcessType;
    /**
    * Specifies that this timeline should run in the background.
    * Default is `true`. When background is disabled, frame rate may drop
    * depending on how intense the task is.
    **/
    public var background:Bool;
    /**
    * A background callback that is used to monitor this timeline, checking
    * which node is currently being processed and also the underlying kha `FrameTask`
    * running the event's code.
    **/
    public var backgroundCallback:(FrameTask, GameEventTimeNode) -> Void;
    /**
    * The currently running task. Automatically assigned by Twinspire.
    **/
    public var currentTask:() -> Void;

    public function new() {
        _id += 1;
        _groupId = _id;
        nodes = [];
        currentNode = -1;
        type = InSequence;
        background = true;
        animIndex = -1;
    }

    /**
    * Add a node to the current timeline.
    **/
    public function addNode(node:GameEventTimeNode) {
        nodes.push(node);
        if (currentNode == -1) {
            currentNode = 0;
        }
    }

}