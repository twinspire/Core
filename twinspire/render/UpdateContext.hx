package twinspire.render;

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
import twinspire.Dimensions.*;
import twinspire.Dimensions.VerticalAlign;
import twinspire.Dimensions.HorizontalAlign;

@:allow(Application)
class UpdateContext {

    private var _gctx:GraphicsContext;
    private var _events:Array<GameEvent>;

    // UI stuff
    private var _tempUI:Array<Int>;
    private var _mouseFocusIndexUI:Int;
    private var _mouseIsDown:Int;
    private var _mouseIsScrolling:Int;
    private var _mouseScrollValue:Int;
    private var _mouseIsReleased:Int;
    private var _keysUp:Array<Int>;
    private var _keysDown:Array<Int>;
    private var _activatedIndex:Int;

    private var _deltaTime:Float;

    public var deltaTime(get, default):Float;
    function get_deltaTime() return _deltaTime;

    public function new(gctx:GraphicsContext) {
        _gctx = gctx;
        _events = [];
        _menus = [];

        _mouseFocusIndexUI = -1;
        _activatedIndex = -1;
    }

    /**
    * Begin update context and start performing event simulations.
    **/
    public function begin() {
        _tempUI = [];
        _mouseFocusIndexUI = -1;

        var mousePos = GlobalEvents.getMousePosition();
        var currentOrder = -1;

        for (i in 0..._gctx.dimensions.length) {
            var query = _gctx.queries[i];
            if (GlobalEvents.isMouseOverDim(_gctx.dimensions[i]) && _gctx.dimensions[i].order > currentOrder
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
            if (query.type == QUERY_SPRITE)
                continue;

            isMouseOver = index;

            if (GlobalEvents.isMouseButtonReleased(BUTTON_LEFT)) {
                _mouseIsReleased = index;
                _activatedIndex = index;
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
        }

        _keysUp = GlobalEvents.isAnyKeyUp();
        _keysDown = GlobalEvents.isAnyKeyDown();

        if (_mouseFocusIndexUI > -1 && _activatedIndex == _mouseFocusIndexUI) {

        }
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
            var activity = new Activity();
            activity.type = ACTIVITY_MOUSE_OVER;
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a mouse
    * down event.
    * @param index The index of the dimension to check.
    **/
    public function isMouseDown(index:Int) {
        if (index < 0 || index > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _mouseIsDown == index && _gctx.queries[index].type != QUERY_STATIC;
        if (result) {
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
            var activity = new Activity();
            activity.type = ACTIVITY_KEY_DOWN;
            activity.data.push(_keysDown);
            _gctx.activities[index] = activity;
        }

        return result;
    }

    /**
    * 
    **/
    public function isKeyEnter(index:Int) {

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
                submitGameEvent(GameEvent.SetDimPosition, [ dimAlign(menuItemDim, _gctx.dimensions[menu.cursorIndex], VALIGN_CENTRE, HALIGN_LEFT) ]);
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