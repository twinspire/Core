package twinspire.render;

import kha.System;
import js.lib.webassembly.Global;
import kha.math.FastVector2;
import twinspire.Application;
import twinspire.events.GameEvent;
import twinspire.events.Buttons;
import twinspire.GlobalEvents;
import twinspire.render.GraphicsContext;
import twinspire.render.RenderQuery;
import twinspire.render.QueryType;
import twinspire.render.MouseScrollValue;
import twinspire.render.ActivityType;
import twinspire.geom.Dim;
import twinspire.Dimensions.VerticalAlign;
import twinspire.Dimensions.HorizontalAlign;
import twinspire.Dimensions.*;
using twinspire.extensions.ArrayExtensions;
using twinspire.utils.ArrayUtils;

import kha.input.KeyCode;

@:allow(Application)
class UpdateContext {

    private var _gctx:GraphicsContext;
    private var _events:Array<GameEvent>;

    // UI stuff
    private var _tempUI:Array<Int>;
    private var _retainedMouseDown:Array<Int>;

    private var _mouseFocusIndexUI:Int;
    private var _mouseIsDown:Int;
    private var _mouseIsScrolling:Int;
    private var _mouseScrollValue:Int;
    private var _mouseIsReleased:Int;
    private var _keysUp:Array<Int>;
    private var _keysDown:Array<Int>;
    private var _charString:String;
    private var _activatedIndex:Int;

    private var _mouseDownPosFirst:FastVector2;
    private var _mouseDragTolerance:Float = 3.0;

    private var _drag:DragObject;
    private var _isDragStart:Int;
    private var _isDragEnd:Int;

    private var _deltaTime:Float;

    // animations
    private var _moveToAnimations:Array<MoveToAnimation>;


    public var deltaTime(get, default):Float;
    function get_deltaTime() return _deltaTime;

    public function new(gctx:GraphicsContext) {
        _gctx = gctx;
        _events = [];
        _retainedMouseDown = [];
        _moveToAnimations = [];

        _mouseFocusIndexUI = -1;
        _activatedIndex = -1;
        _charString = "";

        _drag = new DragObject();
        _drag.dragIndex = -1;
        _mouseDownPosFirst = new FastVector2(-1, -1);

        _isDragStart = -1;
        _isDragEnd = -1;
    }

    /**
    * Gets a copy of a dimension at the given index.
    **/
    public function getDimensionAt(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            throw "Index of out range.";
        }

        return _gctx.dimensions[index].clone();
    }

    /**
    * Begin update context and start performing event simulations.
    **/
    public function begin() {
        // simulate animations first, then check user input
        var finished = [];
        for (i in 0..._moveToAnimations.length) {
            var moveTo = _moveToAnimations[i];
            if (Animate.animateTick(moveTo.animIndex, moveTo.duration)) {
                finished.push(i);
            }

            var ratio = Animate.animateGetRatio(moveTo.animIndex);
            var startX = moveTo.start.x;
            var endX = moveTo.end.x;
            if (moveTo.end.x < moveTo.start.x) {
                startX = moveTo.end.x;
                endX = moveTo.start.x;
            }

            var startY = moveTo.start.y;
            var endY = moveTo.end.y;
            if (moveTo.end.y < moveTo.start.y) {
                startY = moveTo.end.y;
                endY = moveTo.start.y;
            }

            var startW = moveTo.start.width;
            var endW = moveTo.end.width;
            if (moveTo.end.width < moveTo.start.width) {
                startW = moveTo.end.width;
                endW = moveTo.start.width;
            }

            var startH = moveTo.start.height;
            var endH = moveTo.end.height;
            if (moveTo.end.height < moveTo.start.height) {
                startH = moveTo.end.height;
                endH = moveTo.start.height;
            }

            var x = ((endX - startX) * ratio) + startX;
            var y = ((endY - startY) * ratio) + startY;
            var width = ((endW - startW) * ratio) + startW;
            var height = ((endH - startH) * ratio) + startH;

            _gctx.dimensions[moveTo.contextIndex].x = x;
            _gctx.dimensions[moveTo.contextIndex].y = y;
            _gctx.dimensions[moveTo.contextIndex].width = width;
            _gctx.dimensions[moveTo.contextIndex].height = height;
        }

        _moveToAnimations.clearFromTemp(finished);

        // check user input
        _tempUI = [];
        _mouseFocusIndexUI = -1;

        var mousePos = GlobalEvents.getMousePosition();
        var currentOrder = -1;

        if (_drag.dragIndex == -1) {
            var remainActive = false;
            if (_mouseDownPosFirst.x > -1 && _mouseDownPosFirst.y > -1) {
                remainActive = true;
            }

            for (i in 0..._gctx.dimensions.length) {
                var query = _gctx.queries[i];
                var active = GlobalEvents.isMouseOverDim(_gctx.dimensions[i]);
                if (remainActive) {
                    active = GlobalEvents.isMouseOverDim(_gctx.dimensions[i], _mouseDownPosFirst);
                }

                if (active && _gctx.dimensions[i].order > currentOrder
                    && query.type != QUERY_STATIC) {
                    _tempUI.push(i);
                    currentOrder = _gctx.dimensions[i].order;
                }
            }
        }
        else {
            _tempUI.push(_drag.dragIndex);
        }

        _mouseIsDown = -1;
        _mouseIsReleased = -1;
        _mouseIsScrolling = -1;
        
        if (!handleKeyEvents()) {
            return;
        }

        handleMouseEvents();
    }

    private function handleKeyEvents() {
        var acceptNewEvents = true;
        var isFocusTextBased = false;
        if (_activatedIndex > -1) {
            isFocusTextBased = _gctx.queries[_activatedIndex].acceptsTextInput;
        }

        _keysUp = GlobalEvents.isAnyKeyUp();
        _keysDown = GlobalEvents.isAnyKeyDown();
        var keyMods = GlobalEvents.getCurrentKeyModifiers();

        if (_keysUp.length > 0) {
            var first = cast (_keysUp.shift(), KeyCode);
            if (first == KeyCode.Tab) {
                var increment = 1;
                if (keyMods.filter((c) -> c == KeyCode.Shift).length == 1 && keyMods.length == 1) {
                    increment = -1;
                }

                var index = _activatedIndex;
                while (true) {
                    index += increment;
                    var query = _gctx.queries[index];
                    if (query.type == QUERY_UI && (query.acceptsTextInput || query.acceptsKeyInput)) {
                        break;
                    }

                    if (index == _activatedIndex) {
                        break; // prevent infinite looping
                    }
                }

                _activatedIndex = index;
            }
        }

        if (_activatedIndex > -1) {
            if (isFocusTextBased) {
                for (c in GlobalEvents.getKeyCharCode()) {
                    _charString += String.fromCharCode(c);
                }
                
                acceptNewEvents = false;
            }
        }

        return acceptNewEvents;
    }

    private function handleMouseEvents() {
        var isMouseOver = -1;
        var mouseScrollDelta = 0;

        var i = _tempUI.length - 1;
        while (i > -1) {
            var index = _tempUI[i--];
            var dim:Dim = _gctx.dimensions[index];
            var query:RenderQuery = _gctx.queries[index];
            // we only allow UI to receive mouse events.
            if (query.type != QUERY_UI)
                continue;

            isMouseOver = index;

            if (GlobalEvents.isMouseButtonReleased(BUTTON_LEFT)) {
                // check that the mouse is actually within the active component
                // when the mouse button is released.
                if (GlobalEvents.isMouseOverDim(dim)) {
                    _mouseIsReleased = index;
                    _activatedIndex = index;
                }
                
                _mouseDownPosFirst = new FastVector2(-1, -1);
            }

            if (GlobalEvents.isMouseButtonDown(BUTTON_LEFT)) {
                _mouseIsDown = index;
            }

            if (GlobalEvents.getMouseDelta() != 0) {
                mouseScrollDelta = GlobalEvents.getMouseDelta();

                var containerIndex = _gctx.containers.findIndex((a) -> a.dimIndex == isMouseOver);
                if (containerIndex > -1) {
                    var container = _gctx.containers[containerIndex];
                    var dim = _gctx.dimensions[container.dimIndex];
                    if (_keysDown[KeyCode.Shift]) {
                        // TODO: We are doing things in pixels for now as we do not have a way
                        // to measure buffer or screen space.

                        if (mouseScrollDelta < 0 && container.offset.x > 0) {
                            container.offset.x -= container.increment;
                        }
                        else if (mouseScrollDelta > 0 && container.offset.x < container.content.x - dim.width) {
                            container.offset.x += container.increment;
                        }
                    }
                    else {
                        if (mouseScrollDelta < 0 && container.offset.y > 0) {
                            container.offset.y -= container.increment;
                        }
                        else if (mouseScrollDelta > 0 && container.offset.y < container.content.y - dim.height) {
                            container.offset.y += container.increment;
                        }
                    }
                }

                _mouseIsScrolling = index;
            }

            break;
        }

        _mouseFocusIndexUI = isMouseOver;

        if (_mouseIsDown == -1 && GlobalEvents.isMouseButtonReleased(BUTTON_LEFT)) {
            _activatedIndex = -1;
            _mouseDownPosFirst = new FastVector2(-1, -1);
            if (_drag.dragIndex > -1) {
                _isDragEnd = _drag.dragIndex;
            }

            _drag.dragIndex = -1;
            _drag.firstMousePosition = new FastVector2(-1, -1);
        }

        if (_mouseIsDown > -1) {
            if (_mouseDownPosFirst.x == -1) {
                _mouseDownPosFirst = FastVector2.fromVector2(GlobalEvents.getMousePosition());
            }

            var parentIndex = _gctx.dimensionLinks[_mouseFocusIndexUI];
            var theChild = _mouseIsDown;
            var dragStarted = false;
            if (_drag.dragIndex == -1) {
                dragStarted = true;
            }

            if (parentIndex > -1) {
                // if the parent is draggable and we mouse down and move,
                // drag the parent and prevent mouse release on the focused index.

                if (_gctx.queries[parentIndex].allowDragging && _gctx.queries[parentIndex].dragOptions.allowParentDrag) {
                    _drag.dragIndex = parentIndex;
                    _mouseIsDown = parentIndex; // move mouse down event to parent when dragging
                }
                else if (_gctx.queries[_mouseIsDown].allowDragging) {
                    _drag.dragIndex = _mouseIsDown;
                }
            }
            else {
                if (_gctx.queries[_mouseIsDown].allowDragging) {
                    _drag.dragIndex = _mouseIsDown;
                }
            }

            if (_drag.dragIndex > -1) {
                if (dragStarted && _isDragStart == -1) {
                    _isDragStart = _drag.dragIndex;
                }

                var query = _gctx.queries[theChild];
                var mousePos = GlobalEvents.getMousePosition();
                var offset = new FastVector2(mousePos.x - _mouseDownPosFirst.x, mousePos.y - _mouseDownPosFirst.y);

                if (theChild != _drag.dragIndex) { // ignore drag options 
                    _gctx.dimensions[_drag.dragIndex].x += offset.x;
                    _gctx.dimensions[_drag.dragIndex].y += offset.y;
                }
                else if (query.dragOptions.constrained && parentIndex > -1) {
                    // our child is constrained, but the parent is not draggable
                    // constrain child movement to parent dimensions.
                    switch (query.dragOptions.orientation) {
                        case ORIENTATION_HORIZONTAL: {
                            _gctx.dimensions[theChild].x += offset.x;

                            if (_gctx.dimensions[theChild].x < _gctx.dimensions[parentIndex].x) {
                                _gctx.dimensions[theChild].x = _gctx.dimensions[parentIndex].x;
                            }
                            else if (_gctx.dimensions[theChild].x + _gctx.dimensions[theChild].width >
                                _gctx.dimensions[parentIndex].x + _gctx.dimensions[parentIndex].width) {
                                _gctx.dimensions[theChild].x = (_gctx.dimensions[parentIndex].x + _gctx.dimensions[parentIndex].width) - _gctx.dimensions[theChild].width;
                            }
                        }
                        case ORIENTATION_VERTICAL: {
                            _gctx.dimensions[theChild].y += offset.y;

                            if (_gctx.dimensions[theChild].y < _gctx.dimensions[parentIndex].y) {
                                _gctx.dimensions[theChild].y = _gctx.dimensions[parentIndex].y;
                            }
                            else if (_gctx.dimensions[theChild].y + _gctx.dimensions[theChild].height >
                                _gctx.dimensions[parentIndex].y + _gctx.dimensions[parentIndex].height) {
                                _gctx.dimensions[theChild].y = (_gctx.dimensions[parentIndex].y + _gctx.dimensions[parentIndex].height) - _gctx.dimensions[theChild].height;
                            }
                        }
                    }
                }

                _mouseDownPosFirst = new FastVector2(mousePos.x, mousePos.y);
            }
        }
    }

    /**
    * Gets the activated index, normally from a user clicking a UI dimension or
    * pressing the tab key between UI elements.
    **/
    public function getActivatedIndex() {
        return _activatedIndex;
    }

    /**
    * Get the currently focused index.
    **/
    public function getFocusedIndex() {
        return _mouseFocusIndexUI;
    }
    
    /**
    * Checks that the following dimension at the given index is receiving a mouse
    * over event.
    * @param index The index of the dimension to check.
    **/
    public function isMouseOver(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _mouseFocusIndexUI == index && _gctx.queries[index].type != QUERY_STATIC;
        if (result) {
            var parentIndex = _gctx.dimensionLinks[index];
            if (parentIndex > -1) {
                if (_mouseFocusIndexUI == index && _gctx.queries[parentIndex].type != QUERY_STATIC) {
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_OVER;
                    _gctx.activities[parentIndex] = activity;
                }
            }

            var activity = new Activity();
            activity.type = ACTIVITY_MOUSE_OVER;
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a mouse
    * down event. If a mouse down effect is forcibly preserved with the `retainMouseDownEffect`
    * function, this function will always return `true`.
    *
    * @param index The index of the dimension to check.
    **/
    public function isMouseDown(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _mouseIsDown == index && _gctx.queries[index].type != QUERY_STATIC;
        if (_retainedMouseDown.indexOf(index) > -1) {
            result = true;
        }

        if (result) {
            var parentIndex = _gctx.dimensionLinks[index];
            if (parentIndex > -1) {
                if (_mouseIsDown == index && _gctx.queries[parentIndex].type != QUERY_STATIC) {
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_DOWN;
                    _gctx.activities[parentIndex] = activity;
                }
            }

            var activity = new Activity();
            activity.type = ACTIVITY_MOUSE_DOWN;
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a mouse
    * released event.
    *
    * @param index The index of the dimension to check.
    **/
    public function isMouseReleased(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _mouseIsReleased == index && _gctx.queries[index].type != QUERY_STATIC;
        if (result) {
            var parentIndex = _gctx.dimensionLinks[index];
            if (parentIndex > -1) {
                if (_mouseIsReleased == index && _gctx.queries[parentIndex].type != QUERY_STATIC) {
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_CLICKED;
                    _gctx.activities[parentIndex] = activity;
                }
            }

            var activity = new Activity();
            activity.type = ACTIVITY_MOUSE_CLICKED;
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a mouse
    * scroll event.
    *
    * @param index The index of the dimension to check.
    * @return Returns a boolean value to determine its scroll state. Get the scroll state data from `activities` in `GraphicsContext`.
    **/
    public function isMouseScrolling(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _mouseIsScrolling == index && _gctx.queries[index].type != QUERY_STATIC;
        if (result) {
            var parentIndex = _gctx.dimensionLinks[index];
            if (parentIndex > -1) {
                if (_mouseIsScrolling == index && _gctx.queries[parentIndex].type != QUERY_STATIC) {
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_SCROLL;
                    activity.data.push(_mouseScrollValue);
                    _gctx.activities[parentIndex] = activity;
                }
            }

            var activity = new Activity();
            activity.type = ACTIVITY_MOUSE_SCROLL;
            activity.data.push(_mouseScrollValue);
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a key up
    * event.
    *
    * @param index The index of the dimension to check.
    * @return Returns a boolean value to determine the key up event. Get the key code data from `activities` in `GraphicsContext`.
    **/
    public function isKeyUp(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _keysUp.length > 0 && _gctx.queries[index].type != QUERY_STATIC && (_activatedIndex == -1 || _activatedIndex == index);

        if (result) {
            var parentIndex = _gctx.dimensionLinks[index];
            if (parentIndex > -1) {
                if (_gctx.queries[parentIndex].type != QUERY_STATIC) {
                    var activity = new Activity();
                    activity.type = ACTIVITY_KEY_UP;
                    activity.data.push(_keysUp);
                    _gctx.activities[parentIndex] = activity;
                }
            }

            var activity = new Activity();
            activity.type = ACTIVITY_KEY_UP;
            activity.data.push(_keysUp);
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a key down
    * event.
    *
    * @param index The index of the dimension to check.
    * @return Returns a boolean value to determine the key down event. Get the key code data from `activities` in `GraphicsContext`.
    **/
    public function isKeyDown(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _keysDown.length > 0 && _gctx.queries[index].type != QUERY_STATIC && (_activatedIndex == -1 || _activatedIndex == index);

        if (result) {
            var parentIndex = _gctx.dimensionLinks[index];
            if (parentIndex > -1) {
                if (_gctx.queries[parentIndex].type != QUERY_STATIC) {
                    var activity = new Activity();
                    activity.type = ACTIVITY_KEY_DOWN;
                    activity.data.push(_keysDown);
                    _gctx.activities[parentIndex] = activity;
                }
            }

            var activity = new Activity();
            activity.type = ACTIVITY_KEY_DOWN;
            activity.data.push(_keysDown);
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a key enter
    * event.
    *
    * @param index The index of the dimension to check.
    * @return Returns a boolean value to determine the key enter event. Get the key string data from `activities` in `GraphicsContext`.
    **/
    public function isKeyEnter(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _charString.length > 0 && _gctx.queries[index].type != QUERY_STATIC && (_activatedIndex == -1 || _activatedIndex == index);

        if (result) {
            var parentIndex = _gctx.dimensionLinks[index];
            if (parentIndex > -1) {
                if (_gctx.queries[parentIndex].type != QUERY_STATIC) {
                    var activity = new Activity();
                    activity.type = ACTIVITY_KEY_ENTER;
                    activity.data.push(_charString);
                    _gctx.activities[parentIndex] = activity;
                }
            }

            var activity = new Activity();
            activity.type = ACTIVITY_KEY_ENTER;
            activity.data.push(_charString);
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a drag start
    * event.
    *
    * @param index The index of the dimension to check.
    * @return Returns a boolean value to determine the drag start event.
    **/
    public function isDragStart(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _isDragStart == index && _gctx.queries[index].type != QUERY_STATIC && (_activatedIndex == -1 || _activatedIndex == index);

        if (result) {
            var activity = new Activity();
            activity.type = ACTIVITY_DRAG_START;
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a drag
    * event.
    *
    * @param index The index of the dimension to check.
    * @return Returns a boolean value to determine the drag event.
    **/
    public function isDragging(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _drag.dragIndex == index && _gctx.queries[index].type != QUERY_STATIC && (_activatedIndex == -1 || _activatedIndex == index);

        if (result) {
            var activity = new Activity();
            activity.type = ACTIVITY_DRAGGING;
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a drag end
    * event.
    *
    * @param index The index of the dimension to check.
    * @return Returns a boolean value to determine the drag end event.
    **/
    public function isDragEnd(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _isDragEnd == index && _gctx.queries[index].type != QUERY_STATIC && (_activatedIndex == -1 || _activatedIndex == index);

        if (result) {
            var activity = new Activity();
            activity.type = ACTIVITY_DRAG_END;
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * Retains a mouse-down effect for the given index, allowing for preserving a visual state
    * between frames.
    **/
    public function retainMouseDownEffect(index:Int) {
        if (_retainedMouseDown.filter((i) -> i == index).length == 0) {
            _retainedMouseDown.push(index);
        }
    }

    /**
    * Clears a previously permanent mouse-down effect for the given index, if it exists.
    **/
    public function clearMouseDownEffect(index:Int) {
        var indexInArray = _retainedMouseDown.indexOf(index);
        if (indexInArray > -1) {
            _retainedMouseDown.splice(indexInArray, 1);
        }
    }

    /**
    * Attempt to navigate a menu with the given id. Set `upOrDown` or `1` for up, or `-1` for down.
    * This function does not cater for values greater than 1.
    *
    * @param menuId The unique ID of the menu to affect.
    * @param upOrDown A value determining where the new cursor should appear.
    **/
    public function navigateMenu(menuId:Id, upOrDown:Int = 0) {
        @:privateAccess(GraphicsContext) {
            var menuFound = -1;
            for (i in 0..._gctx._menus.length) {
                var m = _gctx._menus[i];
                if (m.menuId == menuId) {
                    menuFound = i;
                    break;
                }
            }

            if (menuFound == -1) {
                return;
            }

            _gctx._activeMenu = menuFound;
            var menu = _gctx._menus[_gctx._currentMenu];
            if (menu.cursorIndex + upOrDown > menu.indices.length - 1) {
                menu.cursorIndex = 0;
            }
            
            if (menu.cursorIndex + upOrDown < 0) {
                menu.cursorIndex = menu.indices.length - 1;
            }

            if (_gctx.menuCursorRenderId != null) {
                var menuItemDim = _gctx.dimensions[menu.indices[menu.cursorIndex]];
                var temp = _gctx.dimensions[menu.cursorIndex].clone();
                dimAlign(menuItemDim, temp, VALIGN_CENTRE, HALIGN_LEFT);
                submitGameEvent(GameEvent.SetDimPosition, [ temp ]);
            }
        }
    }

    /**
    * End event context and complete the final simulations.
    **/
    public function end() {
        _mouseIsReleased = -1;
        _mouseIsScrolling = -1;
        _keysDown = [];
        _keysUp = [];
        _isDragStart = -1;
        _isDragEnd = -1;

        // do container checks here.
        for (i in 0..._gctx.containers.length) {
            var container = _gctx.containers[i];
            var dim = _gctx.dimensions[container.dimIndex];

            if (container.offset.x < 0) {
                container.offset.x = 0;
            }

            if (container.offset.x > container.content.x - dim.width) {
                container.offset.x = container.content.x - dim.width;
            }

            if (container.offset.y < 0) {
                container.offset.y = 0;
            }

            if (container.offset.y > container.content.y - dim.height) {
                container.offset.y = container.content.y - dim.height;
            }
        }
    }

    /**
    * Submit an event of a given type.
    **/
    public function submitGameEvent(id:Id, ?data:Array<Dynamic> = null) {
        var gevent = new GameEvent();
        gevent.id = id;
        gevent.data = data;
        _events.push(gevent);
    }


    /**
    * Allow for checking game events, iterating over each and filtering on the ones
    * cared about, automating the ones that are used by Twinspire.
    *
    * This function is typically used at the end of the loop.
    *
    * @param callback The callback function to execute for any custom game events.
    * @param exitCallback The callback function to execute when an exit event is triggered.
    **/
    public function onEvent(callback:(GameEvent) -> Void, exitCallback:Void -> Void) {
        if (callback == null)
            return;

        for (i in 0..._events.length) {
            var e = _events.pop();
            if (e.id == GameEvent.ExitApp) {
                if (exitCallback != null) {
                    exitCallback();
                }
            }

            if (cast(e.id, Int) > GameEvent.maximum) {
                callback(e);
            }
            else {
                if (e.id == GameEvent.SetDimPosition) {
                    if (e.data.length != 2) {
                        // TODO: Log error
                        continue;
                    }

                    var firstArgIndex = Std.isOfType(e.data[0], Int);
                    if (!firstArgIndex) {
                        // TODO: Log error
                        continue;
                    }

                    var secondArgDim = Std.isOfType(e.data[1], Dim);
                    if (!secondArgDim) {
                        // TODO: Log error
                        continue;
                    }

                    var index = cast(e.data[0], Int);
                    var dim = cast(e.data[1], Dim);
                    trace(index);
                    _gctx.dimensions[index] = dim.clone();
                }
                else if (e.id == GameEvent.MoveDim) {
                    if (e.data.length != 4) {
                        // TODO: Log error
                        continue;
                    }

                    var firstArgDim = Std.isOfType(e.data[0], Dim);
                    if (!firstArgDim) {
                        // TODO: Log error
                        continue;
                    }

                    var secondArgDim = Std.isOfType(e.data[1], Dim);
                    if (!secondArgDim) {
                        // TODO: Log error
                        continue;
                    }

                    var thirdArgSeconds = Std.isOfType(e.data[2], Float);
                    if (!thirdArgSeconds) {
                        // TODO: Log error
                        continue;
                    }

                    var fourthArgContextIndex = Std.isOfType(e.data[3], Int);
                    if (!fourthArgContextIndex) {
                        // TODO: Log error
                        continue;
                    }

                    var moveTo = new MoveToAnimation();
                    moveTo.start = cast (e.data[0], Dim);
                    moveTo.end = cast (e.data[1], Dim);
                    moveTo.duration = cast (e.data[2], Float);
                    moveTo.animIndex = Animate.animateCreateTick();
                    moveTo.contextIndex = cast (e.data[3], Int);

                    _moveToAnimations.push(moveTo);
                }
            }
        }
    }

    


}