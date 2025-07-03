package twinspire.events;

class GameEventTimeNode {
    
    /**
    * The original game event.
    **/
    public var e:GameEvent;
    /**
    * The duration of this event.
    **/
    public var duration:Duration;
    /**
    * Determines if the next node in this timeline should execute.
    **/
    public var next:Bool;
    /**
    * Get or set a value determining if this time node has been completed.
    **/
    public var finished:Bool;
    /**
    * Set the options for this time node.
    **/
    public var options:GameEventOptions;

    public function new(e:GameEvent) {
        this.e = e;
        options = {
            continuous: false,
            userAction: false,
            actionRequired: false,
        };
    }

}