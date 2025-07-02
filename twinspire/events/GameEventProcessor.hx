package twinspire.events;

import kha.Scheduler;
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
    * Process all the events in the current stack and determine their values. Returns an array
    * of callbacks that are used to execute the render state or logic (if any) associated with
    * the events.
    *
    * Each callback function returns a `Bool` value representing if the event was handled internally
    * by Twinspire. If not handled internally, the `false` value can be used to perform your own logic.
    **/
    public function processEvents():Array<() -> Bool> {
        var callbacks = new Array<() -> Bool>();

        for (e in sequentialEvents) {
            var cb = function(event:GameEvent) {
                return function() {
                    if (event.id == GameEvent.ExitApp) {
                        Application.instance.exit();
                        return true;
                    }
                    return false;
                };
            };

            callbacks.push(cb(e));
        }

        for (t in timelineEvents) {
            if (t.nodes.length == 0) {
                continue;
            }

            var node = t.nodes[0];
            if (!t.background) {
                if (t.animIndex == -1) {
                    t.animIndex = Animate.animateCreateTick();
                }

                if (Animate.animateTick(t.animIndex, node.duration)) {
                    node.finished = true;
                    if (node.next) {
                        t.nodes.shift();
                    }
                    else {
                        t.nodes.splice(0, t.nodes.length);
                    }
                }

                if (!node.finished) {
                    callbacks.push(function(event:GameEvent) {
                        return function() {
                            if (node.e.id == GameEvent.ExitApp) {
                                Application.instance.exit();
                                return true;
                            }
                            return false;
                        };
                    });
                }
            }
        }

        return callbacks;
    }

}