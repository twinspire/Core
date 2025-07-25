package twinspire.events;

import twinspire.events.EventArgs;
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
    var type:Int;
}

typedef CustomEventIndex = {
    var type:Int;
    var name:String;
}

typedef CustomEventTrigger = {
    var target:Int;
    var type:Int;
    var args:EventArgs;
};

/**
* Organise event handling.
**/
class EventDispatcher {
    
    private var handlers:Array<EventHandler>;
    private var callbacks:Array<(EventArgs) -> Void>;

    private var customEvents:Array<CustomEventIndex>;
    private var triggered:Array<CustomEventTrigger>;

    public function new() {
        handlers = [];
        callbacks = [];
        customEvents = [];
        triggered = [];
    }

    public function addCustomEvent(name:String) {
        var found = customEvents.findIndex((ce) -> ce.name == name);
        if (found > -1) {
            return null;
        }

        var type = ACTIVITY_MAX;
        if (customEvents.length > 0) {
            type = customEvents[customEvents.length - 1].type + 1;
        }

        var ce:CustomEventIndex = {
            name: name,
            type: type
        };

        customEvents.push(ce);
        return customEvents[customEvents.length - 1];
    }

    public function triggerEvent(target:Int, name:String, args:EventArgs) {
        triggered.push({
            target: target,
            type: customEvents.findIndex((ce) -> ce.name == name),
            args: args
        });
    }

    public function addEventListener(target:Int, type:Int, listener:(EventArgs) -> Void) {
        handlers.push({ target: target, type: type });
        callbacks.push(listener);
    }

    public function removeEventListener(target:Int, type:Int) {
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
            var e:EventArgs;

            switch (handlers[i].type) {
                case ACTIVITY_DRAGGING: {
                    if (utx.isDragging(Direct(i))) {
                        e = new EventArgs();
                        callbacks[i](e);
                    }
                }
                case ACTIVITY_DRAG_END: {
                    if (utx.isDragEnd(Direct(i))) {
                        e = new EventArgs();
                        callbacks[i](e);
                    }
                }
                case ACTIVITY_DRAG_START: {
                    if (utx.isDragStart(Direct(i))) {
                        e = new EventArgs();
                        callbacks[i](e);
                    }
                }
                case ACTIVITY_MOUSE_CLICKED: {
                    if (utx.isMouseReleased(Direct(handlers[i].target))) {
                        var data = utx.getActivity(index, handlers[i].type);

                        var mouseEvent = new MouseEventArgs();
                        mouseEvent.button = cast (data[0], Buttons);
                        mouseEvent.clientPosition = cast (data[1], Vector2);
                        mouseEvent.relativePosition = cast (data[2], FastVector2);
                        e = mouseEvent;
                        callbacks[i](e);
                    }
                }
                case ACTIVITY_MOUSE_SCROLL: {
                    if (utx.isMouseScrolling(Direct(handlers[i].target))) {
                        var data = utx.getActivity(index, handlers[i].type);

                        var scrollEvent = new MouseScrollEventArgs();
                        scrollEvent.delta = cast (data[0], Int);
                        e = scrollEvent;
                        callbacks[i](e);
                    }
                }
                case ACTIVITY_MOUSE_DOWN: {
                    if (utx.isMouseDown(Direct(handlers[i].target))) {
                        var data = utx.getActivity(index, handlers[i].type);

                        var mouseEvent = new MouseEventArgs();
                        mouseEvent.button = cast (data[0], Buttons);
                        mouseEvent.clientPosition = cast (data[1], Vector2);
                        mouseEvent.relativePosition = cast (data[2], FastVector2);
                        e = mouseEvent;
                        callbacks[i](e);
                    }
                }
                case ACTIVITY_MOUSE_OVER: {
                    if (utx.isMouseOver(Direct(handlers[i].target))) {
                        var data = utx.getActivity(index, handlers[i].type);

                        var mouseEvent = new MouseEventArgs();
                        mouseEvent.clientPosition = cast (data[0], Vector2);
                        mouseEvent.relativePosition = cast (data[1], FastVector2);
                        e = mouseEvent;
                        callbacks[i](e);
                    }
                }
                case ACTIVITY_DROP_FILES: {
                    
                }
                default: {

                }
            }

            if (e != null) {
                if (e.triggerCustom != null) {
                    triggerEvent(handlers[active].target, e.triggerCustom, e);
                }
            }
        }

        // handlers for activated dimensions
        var activeIndices = handlers.whereIndices((h) -> h.target == activated);
        for (active in activeIndices) {
            var e:EventArgs;

            switch (handlers[active].type) {
                case ACTIVITY_KEY_DOWN: {
                    if (utx.isKeyDown(Direct(handlers[active].target))) {
                        var data = utx.getActivity(handlers[active].target, handlers[active].type);

                        var keyEvent = new KeyEventArgs();
                        for (key in data) {
                            keyEvent.keys.push(cast (key, Int));
                        }
                        e = keyEvent;
                        callbacks[active](e);
                    }
                }
                case ACTIVITY_KEY_UP: {
                    if (utx.isKeyUp(Direct(handlers[active].target))) {
                        var data = utx.getActivity(handlers[active].target, handlers[active].type);

                        var keyEvent = new KeyEventArgs();
                        for (key in data) {
                            keyEvent.keys.push(cast (key, Int));
                        }
                        e = keyEvent;
                        callbacks[active](e);
                    }
                }
                case ACTIVITY_KEY_ENTER: {
                    if (utx.isKeyEnter(Direct(handlers[active].target))) {
                        var data = utx.getActivity(handlers[active].target, handlers[active].type);

                        var charEvent = new CharEventArgs();
                        charEvent.char = cast(data[0], String);
                        e = charEvent;
                        callbacks[active](e);
                    }
                }
                default: {

                }
            }

            if (e != null) {
                if (e.triggerCustom != null) {
                    triggerEvent(handlers[active].target, e.triggerCustom, e);
                }
            }
        }

        for (t in triggered) {
            var indices = handlers.whereIndices((h) -> h.target == t.target && h.type == t.type);
            for (i in indices) {
                callbacks[i](t.args);
            }
        }

        triggered = [];
    }

}