package twinspire.render;

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

    private var _deltaTime:Float;

    public var deltaTime(get, default):Float;
    function get_deltaTime() return _deltaTime;

    public function new(gctx:GraphicsContext) {
        _gctx = gctx;
        _events = [];
        _retainedMouseDown = [];

        _mouseFocusIndexUI = -1;
        _activatedIndex = -1;
        _charString = "";

        _drag = new DragObject();
        _drag.dragIndex = -1;
        _mouseDownPosFirst = new FastVector2(-1, -1);
    }

    /**
    * Begin update context and start performing event simulations.
    **/
    public function begin() {
        _tempUI = [];
        _mouseFocusIndexUI = -1;

        var mousePos = GlobalEvents.getMousePosition();
        var currentOrder = -1;

        var remainActive = false;
        if (_mouseDownPosFirst.x > -1 && _mouseDownPosFirst.y > -1) {
            remainActive = true;
        }

        for (i in 0..._gctx.dimensions.length) {
            var query = _gctx.queries[i];
            var active = GlobalEvents.isMouseOverDim(_gctx.dimensions[i]);
            if (remainActive && _drag.dragIndex == -1) { // ensure nothing is dragging
                active = GlobalEvents.isMouseOverDim(_gctx.dimensions[i], _mouseDownPosFirst);
            }

            if (active && _gctx.dimensions[i].order > currentOrder
                && query.type != QUERY_STATIC) {
                _tempUI.push(i);
                currentOrder = _gctx.dimensions[i].order;
            }
        }

        _mouseIsDown = -1;
        _mouseIsReleased = -1;
        _mouseIsScrolling = -1;

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
                break;
            }

            if (GlobalEvents.isMouseButtonDown(BUTTON_LEFT)) {
                _mouseIsDown = index;
                break;
            }

            if (GlobalEvents.getMouseDelta() != 0) {
                mouseScrollDelta = GlobalEvents.getMouseDelta();
                _mouseIsScrolling = index;
                break;
            }
        }

        _mouseFocusIndexUI = isMouseOver;

        if (_mouseFocusIndexUI == -1 && GlobalEvents.isMouseButtonReleased(BUTTON_LEFT)) {
            _activatedIndex = -1;
            _mouseDownPosFirst = new FastVector2(-1, -1);
            _drag.dragIndex = -1;
            _drag.firstMousePosition = new FastVector2(-1, -1);
        }

        if (_mouseFocusIndexUI > -1) {
            if (_mouseIsDown > -1 && _mouseDownPosFirst.x == -1) {
                _mouseDownPosFirst = FastVector2.fromVector2(GlobalEvents.getMousePosition());
            }

            var parentIndex = _gctx.dimensionLinks[_mouseFocusIndexUI];
            if (parentIndex > -1) {
                // if the parent is draggable and we mouse down and move,
                // drag the parent and prevent mouse release on the focused index.

                if (_gctx.queries[parentIndex].allowDragging) {
                    if (_mouseIsDown > -1) {
                        var mousePos = GlobalEvents.getMousePosition();
                        if ((mousePos.x < _mouseDownPosFirst.x - _mouseDragTolerance || mousePos.x > _mouseDownPosFirst.x + _mouseDragTolerance)
                            && (mousePos.y < _mouseDownPosFirst.y - _mouseDragTolerance || mousePos.y > _mouseDownPosFirst.y + _mouseDragTolerance)) {
                            _drag.firstMousePosition = new FastVector2(_mouseDownPosFirst.x, _mouseDownPosFirst.y);
                            _drag.dragIndex = parentIndex;

                            // mouse down query moves to parent once dragging is within the drag tolerance
                            _mouseIsDown = parentIndex;
                        }
                    }
                }
            }
            else {
                if (_mouseIsDown > -1 && _gctx.queries[_mouseIsDown].allowDragging) {
                    var mousePos = GlobalEvents.getMousePosition();
                    if ((mousePos.x < _mouseDownPosFirst.x - _mouseDragTolerance || mousePos.x > _mouseDownPosFirst.x + _mouseDragTolerance)
                        && (mousePos.y < _mouseDownPosFirst.y - _mouseDragTolerance || mousePos.y > _mouseDownPosFirst.y + _mouseDragTolerance)) {
                        _drag.firstMousePosition = new FastVector2(_mouseDownPosFirst.x, _mouseDownPosFirst.y);
                        _drag.dragIndex = _mouseIsDown;
                    }
                }
            }
        }

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

                _keysDown = [];
                _keysUp = [];
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
    * Detects if the dimension at the given index is possibly being dragged by the user.
    * If the dimension has a parent who also accepts dragging, the parent is dragged before the child.
    * To disable this behaviour, ensure `allowDragging` in the parent's index is `false`, i.e. `gtx.queries[index].allowDragging = false`.
    **/
    public function isDragging(index:Int) {
        return _drag.dragIndex == index;
    }

    /**
    * Gets the offset of the drag between the initial drag point and the current mouse position.
    **/
    public function getDragOffset():FastVector2 {
        var offset = new FastVector2(_drag.firstMousePosition.x - GlobalEvents.getMousePosition().x, 
            _drag.firstMousePosition.y - GlobalEvents.getMousePosition().y);
        return offset;
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
    * Determines if an exit event was submitted.
    **/
    public function isExitEvent():Bool {
        for (e in _events) {
            if (e.id == GameEvent.ExitApp) {
                return true;
            }
        }

        return false;
    }

}