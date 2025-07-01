package twinspire.events;

class GameEventTimeNode {
    
    /**
    * The original game event.
    **/
    public var e:GameEvent;
    /**
    * The duration of this event.
    **/
    public var duration:Float;
    /**
    * Determines if the next node in this timeline should execute.
    **/
    public var next:Bool;
    /**
    * Get a value determining if this time node has been completed.
    **/
    public var finished:Bool;

    public function new(e:GameEvent) {
        this.e = e;
    }

}