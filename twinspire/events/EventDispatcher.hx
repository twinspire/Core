package twinspire.events;

import kha.math.FastVector2;
import twinspire.events.args.CharEventArgs;
import twinspire.events.args.DropFilesEventArgs;
import twinspire.events.args.KeyEventArgs;
import twinspire.events.args.MouseEventArgs;
import twinspire.events.args.MouseScrollEventArgs;
import twinspire.render.UpdateContext;
import twinspire.render.ActivityType;
import twinspire.DimIndex;
using twinspire.extensions.ArrayExtensions;

typedef EventHandler = {
    var target:Int;
    var type:ActivityType;
}

/**
* Organise event handling.
**/
class EventDispatcher {
    
    private var handlers:Array<EventHandler>;
    private var callbacks:Array<(EventArgs) -> Void>;

    public function new() {
        handlers = [];
        callbacks = [];
    }

    public function addEventListener(target:Int, type:ActivityType, listener:(EventArgs) -> Void) {
        handlers.push({ target: target, type: type });
        callbacks.push(listener);
    }

    public function dispatch(utx:UpdateContext) {
        var index = utx.getMouseIndex();
        var activated = utx.getActivatedIndex();

        // universal handlers
        var indices = handlers.whereIndices((h) -> h.target == index);
        for (i in indices) {
            var data = utx.getActivity(index, handlers[i].type);
            switch (handlers[i].type) {
                case ACTIVITY_DRAGGING: {
                    callbacks[i](new EventArgs());
                }
                case ACTIVITY_DRAG_END: {
                    callbacks[i](new EventArgs());
                }
                case ACTIVITY_DRAG_START: {
                    callbacks[i](new EventArgs());
                }
                case ACTIVITY_MOUSE_CLICKED: {
                    var mouseEvent = new MouseEventArgs();
                    mouseEvent.button = cast (data[0], Buttons);
                    mouseEvent.clientPosition = cast (data[1], FastVector2);
                    mouseEvent.relativePosition = cast (data[2], FastVector2);
                    callbacks[i](mouseEvent);
                }
                case ACTIVITY_MOUSE_SCROLL: {
                    var scrollEvent = new MouseScrollEventArgs();
                    scrollEvent.delta = cast (data[0], Int);
                    callbacks[i](scrollEvent);
                }
                case ACTIVITY_MOUSE_DOWN: {
                    var mouseEvent = new MouseEventArgs();
                    mouseEvent.button = cast (data[0], Buttons);
                    mouseEvent.clientPosition = cast (data[1], FastVector2);
                    mouseEvent.relativePosition = cast (data[2], FastVector2);
                    callbacks[i](mouseEvent);
                }
                case ACTIVITY_MOUSE_OVER: {
                    var mouseEvent = new MouseEventArgs();
                    mouseEvent.clientPosition = cast (data[0], FastVector2);
                    mouseEvent.relativePosition = cast (data[1], FastVector2);
                    callbacks[i](mouseEvent);
                }
                case ACTIVITY_DROP_FILES: {
                    
                }
                default: {

                }
            }
        }

        // handlers for activated dimensions
        var activeIndices = handlers.whereIndices((h) -> h.target == activated);
        for (active in activeIndices) {
            var data = utx.getActivity(active, handlers[active].type);
            switch (handlers[active].type) {
                case ACTIVITY_KEY_DOWN: {
                    var keyEvent = new KeyEventArgs();
                    for (key in data) {
                        keyEvent.keys.push(cast (key, Int));
                    }
                    callbacks[i](keyEvent);
                }
                case ACTIVITY_KEY_UP: {
                    var keyEvent = new KeyEventArgs();
                    for (key in data) {
                        keyEvent.keys.push(cast (key, Int));
                    }
                    callbacks[i](keyEvent);
                }
                case ACTIVITY_KEY_ENTER: {
                    var charEvent = new CharEventArgs();
                    charEvent.char = cast(data[0], String);
                    callbacks[i](charEvent);
                }
                default: {

                }
            }
        }
    }

}