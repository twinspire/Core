package twinspire.events;

import twinspire.render.UpdateContext;
import kha.Scheduler;
using twinspire.extensions.ArrayExtensions;

typedef GameEventCallback = {
    var callback:() -> Bool;
    var type:GameEventProcessingType;
    var index:Int;
}

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
    /**
    * The last active event recently removed from timelines.
    **/
    public var lastEvents:Array<GameEvent>;

    public function new() {
        sequentialEvents = [];
        timelineEvents = [];
        lastEvents = [];
    }

    /**
    * Checks if this processor has events.
    **/
    public function hasEvents() {
        return sequentialEvents.length > 0 || timelineEvents.each((t) -> t.nodes.length > 0);
    }

    public function getLastEvent(timelineIndex:Int) {
        if (lastEvents[timelineIndex] != null) {
            return lastEvents[timelineIndex];
        }
        else {
            return timelineEvents[timelineIndex].nodes[0].e;
        }
    }

    /**
    * Process all the events in the current stack and determine their values. Returns an array
    * of callbacks that are used to execute the render state or logic (if any) associated with
    * the events.
    *
    * Each callback function returns a `Bool` value representing if the event was handled internally
    * by Twinspire. If not handled internally, the `false` value can be used to perform your own logic.
    **/
    public function processEvents():Array<GameEventCallback> {
        var callbacks = new Array<GameEventCallback>();

        for (i in 0...sequentialEvents.length) {
            var e = sequentialEvents[i];
            var cb = function(event:GameEvent) {
                return function() {
                    if (event.id == GameEvent.ExitApp) {
                        Application.instance.exit();
                        return true;
                    }
                    return false;
                };
            };

            callbacks.push({
                index: i,
                callback: cb(e),
                type: Sequential
            });
        }

        for (i in 0...timelineEvents.length) {
            var t = timelineEvents[i];
            if (t.nodes.length == 0) {
                continue;
            }

            if (t.type == Altogether) {
                var results = getCallbacksFromTimeline(t, t.nodes.whereIndices((_) -> true));
                for (r in results) {
                    callbacks.push(r);
                }
            }
            else {
                callbacks.push(getCallbacksFromTimeline(t, [ 0 ])[0]);
            }
        }

        return callbacks;
    }

    private function getCallbacksFromTimeline(t:GameEventTimeline, nodeIndices:Array<Int>) {
        var callbacks = new Array<GameEventCallback>();

        for (i in 0...nodeIndices.length) {
            var node = t.nodes[nodeIndices[i]];
            if (!t.background) {
                var duration = switch (node.duration) {
                    case Seconds(value): value;
                    case Frames(factor): factor * UpdateContext.getFrameCount();
                };

                if (t.animIndex == -1) {
                    t.animIndex = Animate.animateCreateTick();
                }

                if (Animate.animateTick(t.animIndex, duration) && !node.options.continuous) {
                    node.finished = true;
                    Animate.animateReset(t.animIndex);
                }

                var actionValidated = false;
                var actionIsRequired = false;
                if (node.options.actionRequired != null) {
                    actionIsRequired = node.options.actionRequired;
                }

                if (actionIsRequired && node.options.action.actionCallback != null) {
                    actionValidated = node.options.action.actionCallback();

                    if (actionValidated) {
                        switch (node.options.action.processAction) {
                            case Jump(ratio): {
                                Animate.animateResumeIndex(t.animIndex);
                                Animate.animateSetRatio(t.animIndex, ratio, duration);
                            }
                            case Pause: {
                                Animate.animatePauseIndex(t.animIndex);
                            }
                            case Complete(skip): {
                                node.finished = true;
                                Animate.animateSetRatio(t.animIndex, 1, duration);

                                if (skip != null) {
                                    node.next = skip;
                                }
                            }
                            case ConditionalNext(cond, wait): {
                                var _waiting = false;
                                if (wait != null) {
                                    _waiting = wait;
                                }

                                if (!_waiting) {
                                    node.next = cond();
                                    Animate.animateSetRatio(t.animIndex, 1, duration);
                                    node.finished = true;
                                }
                                else {
                                    if (!cond()) {
                                        continue;
                                    }
                                }
                            }
                        }
                    }
                }

                if (node.finished) {
                    if (node.next && ((actionIsRequired && actionValidated) || (!actionIsRequired))) {
                        lastEvents[i] = t.nodes.shift().e;
                    }
                    else {
                        lastEvents[i] = t.nodes[0].e;
                        t.nodes.splice(0, t.nodes.length);
                    }
                }

                var cb = function(event:GameEvent) {
                    return function() {
                        if (node.e.id == GameEvent.ExitApp) {
                            Application.instance.exit();
                            return true;
                        }
                        return false;
                    };
                };

                callbacks.push({
                    index: i,
                    callback: cb(node.e),
                    type: Timeline
                });
            }
        }
        return callbacks;
    }

}