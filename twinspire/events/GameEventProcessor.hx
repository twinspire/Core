package twinspire.events;

using twinspire.extensions.ArrayExtensions;

class GameEventProcessor {
    
    /**
    * A list of sequential events. This is designed to be used for very basic events
    * to run on a single frame. Use sparingly.
    **/
    public var sequentialEvents:Array<GameEvent>;
    /**
    * A list of timeline events. These events are designed to run across more than one frame.
    **/
    public var timelineEvents:Array<GameEventTimeline>;

    public function new() {
        sequentialEvents = [];
        timelineEvents = [];
    }

    /**
    * Checks if this processor has events.
    **/
    public function hasEvents() {
        return sequentialEvents.length > 0 && timelineEvents.each((t) -> t.nodes.length > 0);
    }

    /**
    * 
    **/
    public function processEvents():Array<(GameEvent) -> Void> {

    }

}