package twinspire.events;

enum GameEventProcessAction {
    /**
    * Specifies that the action jumps the event by a given ratio, relative to the duration given to the event.
    **/
    Jump(ratio:Float);
    /**
    * Immediately complete the event and optionally skip to the next.
    **/
    Complete(?skip:Bool);
    /**
    * Pause the event from running.
    **/
    Pause;
    /**
    * Specify a conditional that demands `true` to determine if the next event should execute.
    * If `wait` is `false`, the remaining events in the timeline are removed, otherwise wait until the condition is satisfied.
    **/
    ConditionalNext(cond:() -> Bool, ?wait:Bool);
}