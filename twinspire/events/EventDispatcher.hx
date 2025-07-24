package twinspire.events;

import kha.math.Vector2;
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

    public function removeEventListener(target:Int, type:ActivityType) {
        var index = handlers.findIndex((h) -> h.target == target && h.type == type);
        if (index == -1) {
            return;
        }

        handlers.splice(index, 1);
        callbacks.splice(index, 1);
    }

    public function dispatch(utx:UpdateContext) {
        var index = utx.getMouseIndex();
        var activated = utx.getActivatedIndex();

        if (index == -1 && activated == -1) {
            return;
        }

        // universal handlers
        var indices = handlers.whereIndices((h) -> h.target == index);
        for (i in indices) {
            switch (handlers[i].type) {
                case ACTIVITY_DRAGGING: {
                    if (utx.isDragging(Direct(i))) {
                        callbacks[i](new EventArgs());
                    }
                }
                case ACTIVITY_DRAG_END: {
                    callbacks[i](new EventArgs());
                }
                case ACTIVITY_DRAG_START: {
                    callbacks[i](new EventArgs());
                }
                case ACTIVITY_MOUSE_CLICKED: {
                    if (utx.isMouseReleased(Direct(handlers[i].target))) {
                        var data = utx.getActivity(index, handlers[i].type);

                        var mouseEvent = new MouseEventArgs();
                        mouseEvent.button = cast (data[0], Buttons);
                        mouseEvent.clientPosition = cast (data[1], Vector2);
                        mouseEvent.relativePosition = cast (data[2], FastVector2);
                        callbacks[i](mouseEvent);
                    }
                }
                case ACTIVITY_MOUSE_SCROLL: {
                    if (utx.isMouseScrolling(Direct(handlers[i].target))) {
                        var data = utx.getActivity(index, handlers[i].type);

                        var scrollEvent = new MouseScrollEventArgs();
                        scrollEvent.delta = cast (data[0], Int);
                        callbacks[i](scrollEvent);
                    }
                }
                case ACTIVITY_MOUSE_DOWN: {
                    if (utx.isMouseDown(Direct(handlers[i].target))) {
                        var data = utx.getActivity(index, handlers[i].type);

                        var mouseEvent = new MouseEventArgs();
                        mouseEvent.button = cast (data[0], Buttons);
                        mouseEvent.clientPosition = cast (data[1], Vector2);
                        mouseEvent.relativePosition = cast (data[2], FastVector2);
                        callbacks[i](mouseEvent);
                    }
                }
                case ACTIVITY_MOUSE_OVER: {
                    if (utx.isMouseOver(Direct(handlers[i].target))) {
                        var data = utx.getActivity(index, handlers[i].type);

                        var mouseEvent = new MouseEventArgs();
                        mouseEvent.clientPosition = cast (data[0], Vector2);
                        mouseEvent.relativePosition = cast (data[1], FastVector2);
                        callbacks[i](mouseEvent);
                    }
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

            switch (handlers[active].type) {
                case ACTIVITY_KEY_DOWN: {
                    if (utx.isKeyDown(Direct(handlers[active].target))) {
                        var data = utx.getActivity(handlers[active].target, handlers[active].type);

                        var keyEvent = new KeyEventArgs();
                        for (key in data) {
                            keyEvent.keys.push(cast (key, Int));
                        }
                        callbacks[active](keyEvent);
                    }
                }
                case ACTIVITY_KEY_UP: {
                    if (utx.isKeyUp(Direct(handlers[active].target))) {
                        var data = utx.getActivity(handlers[active].target, handlers[active].type);

                        var keyEvent = new KeyEventArgs();
                        for (key in data) {
                            keyEvent.keys.push(cast (key, Int));
                        }
                        callbacks[active](keyEvent);
                    }
                }
                case ACTIVITY_KEY_ENTER: {
                    if (utx.isKeyEnter(Direct(handlers[active].target))) {
                        var data = utx.getActivity(handlers[active].target, handlers[active].type);

                        var charEvent = new CharEventArgs();
                        charEvent.char = cast(data[0], String);
                        callbacks[active](charEvent);
                    }
                }
                default: {

                }
            }
        }
    }

}