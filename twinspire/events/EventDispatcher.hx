package twinspire.events;

import twinspire.events.args.KeyEventArgs;
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
                case ACTIVITY_KEY_DOWN: {
                    var keyEvent = new KeyEventArgs();
                    keyEvent.keys = cast (data[0], Array<Int>);
                    callbacks[i](keyEvent);
                }
                case ACTIVITY_KEY_UP: {
                    var keyEvent = new KeyEventArgs();
                    keyEvent.keys = cast (data[0], Array<Int>);
                    callbacks[i](keyEvent);
                }
                case ACTIVITY_MOUSE_CLICKED: {
                    
                }
            }
        }

    }

}