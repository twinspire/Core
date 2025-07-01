package twinspire.render;

import kha.System;
import js.lib.webassembly.Global;
import kha.math.FastVector2;
import twinspire.Application;
import twinspire.events.GameEventProcessor;
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
    private var _eventProcessor:GameEventProcessor;

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

    private var _lastMousePosition:FastVector2;
    private var _mouseDownFirstPos:FastVector2;
    private var _mouseDragTolerance:Float = 3.0;

    private var _drag:DragObject;
    private var _isDragStart:Int;
    private var _isDragEnd:Int;
    private var _containerDragIndex:Int;

    private var _deltaTime:Float;

    // animations
    private var _moveToAnimations:Array<MoveToAnimation>;


    public var deltaTime(get, default):Float;
    function get_deltaTime() return _deltaTime;

    public function new(gctx:GraphicsContext) {
        _gctx = gctx;
        _events = [];
        _eventProcessor = new GameEventProcessor();
        _retainedMouseDown = [];
        _moveToAnimations = [];

        _mouseFocusIndexUI = -1;
        _activatedIndex = -1;
        _charString = "";
        _containerDragIndex = -1;

        _drag = new DragObject();
        _drag.dragIndex = -1;
        _drag.childIndex = -1;
        _drag.scrollIndex = -1;
        _lastMousePosition = FastVector2.fromVector2(GlobalEvents.getMousePosition());
        _mouseDownFirstPos = new FastVector2(-1, -1);

        _isDragStart = -1;
        _isDragEnd = -1;
    }

    /**
    * Gets a copy of a dimension at the given index.
    **/
    public function getDimensionsAt(index:DimIndex) {
        switch (index) {
            case Direct(item): {
                if (item < 0 || item > _gctx.dimensions.length - 1) {
                    return [ null ];
                }

                return [ _gctx.dimensions[item].clone() ];
            }
            case Group(item): {
                var results = [];
                for (grp in _gctx.getDimIndicesAtGroupIndex(item)) {
                    if (grp > _gctx.dimensions.length - 1) {
                        break;
                    }

                    results.push(_gctx.dimensions[grp].clone());
                }

                return results;
            }
        }
    }

    public function getTextInputState(index:Int) {
        return _gctx.textInputs[index];
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

        if (_mouseDownFirstPos.x == -1 && GlobalEvents.isAnyMouseButtonDown()) {
            _mouseDownFirstPos = FastVector2.fromVector2(GlobalEvents.getMousePosition());
        }
        else if (GlobalEvents.isNoMouseButtonDown()) {
            _mouseDownFirstPos = new FastVector2(-1, -1);
        }

        var mousePos = GlobalEvents.getMousePosition();
        var currentOrder = -1;

        if (_drag.dragIndex == -1) {
            var remainActive = false;
            if (_mouseDownFirstPos.x > -1 && _mouseDownFirstPos.y > -1) {
                remainActive = true;
            }

            for (i in 0..._gctx.dimensions.length) {
                var query = _gctx.queries[i];
                var actualDim = _gctx.getClientDimensionsAtIndex(Direct(i))[0];

                var active = GlobalEvents.isMouseOverDim(actualDim);

                if (remainActive) {
                    active = GlobalEvents.isMouseOverDim(actualDim, _mouseDownFirstPos);
                }

                if (active && actualDim.order > currentOrder
                    && query.type != QUERY_STATIC) {
                    _tempUI.push(i);
                    currentOrder = actualDim.order;
                }
            }
        }
        else {
            _tempUI.push(_drag.dragIndex);
        }

        _mouseIsDown = -1;
        _mouseIsReleased = -1;
        _mouseIsScrolling = -1;
        
        determineInitialMouseEvents();
        
        if (!handleKeyEvents()) {
            return;
        }

        handleMouseEvents();
    }

    private function determineInitialMouseEvents() {
        if (_tempUI.length == 0 && GlobalEvents.isAnyMouseButtonDown()) {
            _activatedIndex = -1;
        }

        var i = _tempUI.length - 1;
        var hasTextInput = false;
        while (i > -1) {
            var index = _tempUI[i--];
            if (_gctx.queries[index].acceptsTextInput && _drag.dragIndex == -1) {
                hasTextInput = true;
                break;
            }
        }

        if (!hasTextInput && GlobalEvents.isAnyMouseButtonReleased()) {
            _activatedIndex = -1;
        }
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

            var containers = _gctx.containers.whereIndices((c) -> c.enableScrollWithClick != BUTTON_NONE);
            
            for (c in containers) {
                var container = _gctx.containers[c];
                var containerDim = _gctx.dimensions[container.dimIndex];
                
                if (GlobalEvents.isMouseOverDim(containerDim) && 
                    GlobalEvents.isMouseButtonDown(container.enableScrollWithClick)) {
                    _drag.scrollIndex = container.dimIndex;
                    break; // Only one container can be scrolled at a time
                }
            }

            if (GlobalEvents.isAnyMouseButtonReleased()) {
                if (query.acceptsTextInput) {
                    _activatedIndex = isMouseOver;
                }

                if (_drag.dragIndex > -1) {
                    _isDragEnd = _drag.dragIndex;
                    _mouseIsReleased = _drag.dragIndex;
                }
                else {
                    _mouseIsReleased = isMouseOver;
                }
                
                _drag.dragIndex = -1;
                _drag.childIndex = -1;
                _drag.scrollIndex = -1;
                _drag.firstMousePosition = new FastVector2(-1, -1);
            }

            if (GlobalEvents.isAnyMouseButtonDown()) {
                if (_drag.childIndex > -1 && _drag.scrollIndex == -1) {
                    _mouseIsDown = _drag.childIndex;
                }
                else {
                    _mouseIsDown = index;
                }
            }

            if (GlobalEvents.getMouseDelta() != 0) {
                mouseScrollDelta = GlobalEvents.getMouseDelta();

                var containerIndex = _gctx.containers.findIndex((a) -> a.dimIndex == isMouseOver);
                if (containerIndex > -1) {
                    var container = _gctx.containers[containerIndex];
                    var dim = _gctx.dimensions[container.dimIndex];
                    if (_keysDown.contains(cast KeyCode.Shift)) {
                        // TODO: We are doing things in pixels for now as we do not have a way
                        // to measure buffer or screen space.

                        if (mouseScrollDelta < 0 && container.offset.x < 0) {
                            container.offset.x += container.increment;
                        }
                        else if (mouseScrollDelta > 0 && container.offset.x > -(container.content.x - dim.width)) {
                            container.offset.x -= container.increment;
                        }
                    }
                    else {
                        if (mouseScrollDelta < 0 && container.offset.y < 0) {
                            container.offset.y += container.increment;
                        }
                        else if (mouseScrollDelta > 0 && container.offset.y > -(container.content.y - dim.height)) {
                            container.offset.y -= container.increment;
                        }
                    }
                }

                _mouseIsScrolling = index;
            }

            if (_drag.scrollIndex == -1) {
                break;
            }
        }

        _mouseFocusIndexUI = isMouseOver;

        var mousePos = GlobalEvents.getMousePosition();
        var diff = new FastVector2(mousePos.x - _lastMousePosition.x, mousePos.y - _lastMousePosition.y);

        if (_mouseIsDown > -1) {
            var theChild = _mouseIsDown;
            var dragStarted = false;
            if (_drag.dragIndex == -1 && _drag.scrollIndex != -1) {
                dragStarted = true;
            }
            
            var parentIndex = _gctx.dimensionLinks[_mouseIsDown];
            if (parentIndex > -1 && _drag.scrollIndex == -1) {
                // if the parent is draggable and we mouse down and move,
                // drag the parent and prevent mouse release on the focused index.

                if (_gctx.queries[parentIndex].allowDragging && _gctx.queries[theChild].dragOptions.allowParentDrag) {
                    _drag.dragIndex = parentIndex;
                    _drag.childIndex = theChild;
                }
                else if (_gctx.queries[theChild].allowDragging) {
                    _drag.dragIndex = _mouseIsDown;
                }
            }
            else if (_drag.scrollIndex == -1) {
                if (_gctx.queries[_mouseIsDown].allowDragging) {
                    _drag.dragIndex = _mouseIsDown;
                }
            }

            if (_drag.dragIndex > -1) {
                if (dragStarted && _isDragStart == -1) {
                    _isDragStart = _drag.dragIndex;
                }

                var query = _gctx.queries[theChild];

                if (theChild != _drag.dragIndex) {
                    _gctx.dimensions[_drag.dragIndex].x += diff.x;
                    _gctx.dimensions[_drag.dragIndex].y += diff.y;

                    var childIndices = _gctx.dimensionLinks.whereIndices((dl) -> dl == parentIndex);
                    for (child in childIndices) {
                        _gctx.dimensions[child].x += diff.x;
                        _gctx.dimensions[child].y += diff.y;

                        _gctx.markDimChange(Direct(child));
                    }

                    _gctx.markDimChange(Direct(_drag.dragIndex));
                }
                else if (query.dragOptions.constrained && parentIndex > -1) {
                    // our child is constrained, but the parent is not draggable
                    // constrain child movement to parent dimensions.
                    switch (query.dragOptions.orientation) {
                        case ORIENTATION_HORIZONTAL: {
                            _gctx.dimensions[theChild].x += diff.x;

                            if (_gctx.dimensions[theChild].x < _gctx.dimensions[parentIndex].x) {
                                _gctx.dimensions[theChild].x = _gctx.dimensions[parentIndex].x;
                            }
                            else if (_gctx.dimensions[theChild].x + _gctx.dimensions[theChild].width >
                                _gctx.dimensions[parentIndex].x + _gctx.dimensions[parentIndex].width) {
                                _gctx.dimensions[theChild].x = (_gctx.dimensions[parentIndex].x + _gctx.dimensions[parentIndex].width) - _gctx.dimensions[theChild].width;
                            }
                        }
                        case ORIENTATION_VERTICAL: {
                            _gctx.dimensions[theChild].y += diff.y;

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
            }
            else if (_drag.scrollIndex > -1) {
                // Find the container index for the current scroll
                var containerIndex = -1;
                
                for (i in 0..._gctx.containers.length) {
                    if (_gctx.containers[i].dimIndex == _drag.scrollIndex) {
                        containerIndex = i;
                        break;
                    }
                }
                
                // Only scroll if the correct button is still being held down
                if (containerIndex > -1) {
                    _gctx.containers[containerIndex].offset.x += diff.x;
                    _gctx.containers[containerIndex].offset.y += diff.y;
                }
                else {
                    _drag.scrollIndex = -1;
                }
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
    *
    * If the index is a reference to a group and `allGroup` is true, if any index is
    * `true`, all indices are considered to have the mouse over them.
    *
    * @param index The index of the dimension to check.
    * @param allGroup (Optional) Specify that all indices in a group receive this event if one returns `true`.
    **/
    public function isMouseOver(index:DimIndex, ?allGroup:Bool = false) {
        var actualIndex = -1;
        var partOfGroup = false;
        switch (index) {
            case Direct(item): {
                actualIndex = item;
            }
            case Group(item): {
                partOfGroup = true;
                for (dim in _gctx.getDimIndicesAtGroupIndex(item)) {
                    if (dim == _mouseFocusIndexUI) {
                        actualIndex = dim;
                        break;
                    }
                }
            }
        }

        if (actualIndex < 0 || actualIndex > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _mouseFocusIndexUI == actualIndex && _gctx.queries[actualIndex].type != QUERY_STATIC;
        if (result) {
            var parentIndex = _gctx.dimensionLinks[actualIndex];
            if (parentIndex > -1 && !partOfGroup) {
                var activity = new Activity();
                activity.type = ACTIVITY_MOUSE_OVER;
                _gctx.activities[parentIndex].push(activity);
            }

            switch (index) {
                case Group(item): {
                    if (!allGroup) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_OVER;
                        _gctx.activities[actualIndex].push(activity);
                        return result;
                    }

                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_OVER;
                        _gctx.activities[child].push(activity);    
                    }
                }
                default: {
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_OVER;
                    _gctx.activities[actualIndex].push(activity);
                }
            }
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
    public function isMouseDown(index:DimIndex, ?allGroup:Bool = false) {
        var actualIndex = -1;
        var partOfGroup = false;
        switch (index) {
            case Direct(item): {
                actualIndex = item;
            }
            case Group(item): {
                partOfGroup = true;
                for (dim in _gctx.getDimIndicesAtGroupIndex(item)) {
                    if (dim == _mouseIsDown) {
                        actualIndex = dim;
                        break;
                    }
                }
            }
        }

        if (actualIndex < 0 || actualIndex > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _mouseIsDown == actualIndex && _gctx.queries[actualIndex].type != QUERY_STATIC;
        if (_retainedMouseDown.indexOf(actualIndex) > -1) {
            result = true;
        }

        if (result) {
            var parentIndex = _gctx.dimensionLinks[actualIndex];
            if (parentIndex > -1 && !partOfGroup) {
                var activity = new Activity();
                activity.type = ACTIVITY_MOUSE_DOWN;
                _gctx.activities[parentIndex].push(activity);
            }

            switch (index) {
                case Group(item): {
                    if (!allGroup) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_DOWN;
                        _gctx.activities[actualIndex].push(activity);
                        return result;
                    }

                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_DOWN;
                        _gctx.activities[child].push(activity);    
                    }
                }
                default: {
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_DOWN;
                    _gctx.activities[actualIndex].push(activity);
                }
            }
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a mouse
    * released event.
    *
    * @param index The index of the dimension to check.
    **/
    public function isMouseReleased(index:DimIndex, ?allGroup:Bool = false) {
        var actualIndex = -1;
        var partOfGroup = false;
        switch (index) {
            case Direct(item): {
                actualIndex = item;
            }
            case Group(item): {
                partOfGroup = true;
                for (dim in _gctx.getDimIndicesAtGroupIndex(item)) {
                    if (dim == _mouseIsReleased) {
                        actualIndex = dim;
                        break;
                    }
                }
            }
        }
        
        if (actualIndex < 0 || actualIndex > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _mouseIsReleased == actualIndex && _gctx.queries[actualIndex].type != QUERY_STATIC;
        if (result) {
            var parentIndex = _gctx.dimensionLinks[actualIndex];
            if (parentIndex > -1 && !partOfGroup) {
                var activity = new Activity();
                activity.type = ACTIVITY_MOUSE_CLICKED;
                _gctx.activities[parentIndex].push(activity);
            }

            switch (index) {
                case Group(item): {
                    if (!allGroup) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_CLICKED;
                        _gctx.activities[actualIndex].push(activity);
                        return result;
                    }

                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_CLICKED;
                        _gctx.activities[child].push(activity);    
                    }
                }
                default: {
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_CLICKED;
                    _gctx.activities[actualIndex].push(activity);
                }
            }
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
    public function isMouseScrolling(index:DimIndex, ?allGroup:Bool = false) {
        var actualIndex = -1;
        var partOfGroup = false;
        switch (index) {
            case Direct(item): {
                actualIndex = item;
            }
            case Group(item): {
                partOfGroup = true;
                for (dim in _gctx.getDimIndicesAtGroupIndex(item)) {
                    if (dim == _mouseIsScrolling) {
                        actualIndex = dim;
                        break;
                    }
                }
            }
        }
        
        if (actualIndex < 0 || actualIndex > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _mouseIsScrolling == actualIndex && _gctx.queries[actualIndex].type != QUERY_STATIC;
        if (result) {
            var parentIndex = _gctx.dimensionLinks[actualIndex];
            if (parentIndex > -1) {
                var activity = new Activity();
                activity.type = ACTIVITY_MOUSE_SCROLL;
                activity.data.push(_mouseScrollValue);
                _gctx.activities[parentIndex].push(activity);
            }

            switch (index) {
                case Group(item): {
                    if (!allGroup) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_SCROLL;
                        activity.data.push(_mouseScrollValue);
                        _gctx.activities[actualIndex].push(activity);
                        return result;
                    }

                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_SCROLL;
                        activity.data.push(_mouseScrollValue);
                        _gctx.activities[child].push(activity);    
                    }
                }
                default: {
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_SCROLL;
                    activity.data.push(_mouseScrollValue);
                    _gctx.activities[actualIndex].push(activity);
                }
            }
        }


        return result;
    }

    /**
    * Checks that a key up event is received and provide it to the given index.
    * Unlike positional events, like mouse or touch, keyboard events typically give an index the listened events, rather than
    * checking if an index has received an event.
    *
    * @param index The index of the dimension to check.
    * @param activatedOnly A boolean value specifying that only the activated dimension index should receive this event, if one is activated.
    * If there is no activated item, this function returns `false` and no activity is submitted.
    * @return Returns a boolean value to determine the key up event. Get the key code data from `activities` in `GraphicsContext`.
    **/
    public function isKeyUp(?index:DimIndex, ?activatedOnly:Bool = false) {
        var result = _keysUp.length > 0;

        if (result) {
            if (activatedOnly && _activatedIndex > -1) {
                var activity = new Activity();
                activity.type = ACTIVITY_KEY_UP;
                activity.data.push(_keysUp);
                _gctx.activities[_activatedIndex].push(activity);
                return result;
            }
            else if (activatedOnly) {
                return false;
            }

            switch (index) {
                case Direct(item): {
                    var activity = new Activity();
                    activity.type = ACTIVITY_KEY_UP;
                    activity.data.push(_keysUp);
                    _gctx.activities[item].push(activity);
                }
                case Group(item): {
                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_KEY_UP;
                        activity.data.push(_keysUp);
                        _gctx.activities[child].push(activity);
                    }
                }
            }
        }

        return result;
    }

    /**
    * Checks that a key is down and provide it to the given index.  
    * Unlike positional events, like mouse or touch, keyboard events typically give an index the listened events, rather than
    * checking if an index has received an event.
    *
    * @param index The index of the dimension to check.
    * @param activatedOnly A boolean value specifying that only the activated dimension index should receive this event, if one is activated.
    * If there is no activated item, this function returns `false` and no activity is submitted.
    * @return Returns a boolean value to determine the key down event. Get the key code data from `activities` in `GraphicsContext`.
    **/
    public function isKeyDown(?index:DimIndex, ?activatedOnly:Bool = false) {
        var result = _keysDown.length > 0;

        if (result) {
            if (activatedOnly && _activatedIndex > -1) {
                var activity = new Activity();
                activity.type = ACTIVITY_KEY_DOWN;
                activity.data.push(_keysDown);
                _gctx.activities[_activatedIndex].push(activity);
                return result;
            }
            else if (activatedOnly) {
                return false;
            }

            switch (index) {
                case Direct(item): {
                    var activity = new Activity();
                    activity.type = ACTIVITY_KEY_DOWN;
                    activity.data.push(_keysDown);
                    _gctx.activities[item].push(activity);
                }
                case Group(item): {
                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_KEY_DOWN;
                        activity.data.push(_keysDown);
                        _gctx.activities[child].push(activity);
                    }
                }
            }
        }

        return result;
    }

    /**
    * Checks that a key enter event is received and provide it to the given index.
    * Unlike positional events, like mouse or touch, keyboard events typically give an index the listened events, rather than
    * checking if an index has received an event.
    *
    * @param index The index of the dimension to check.
    * @param activatedOnly A boolean value specifying that only the activated dimension index should receive this event, if one is activated.
    * If there is no activated item, this function returns `false` and no activity is submitted.
    * @return Returns a boolean value to determine the key enter event. Get the key string data from `activities` in `GraphicsContext`.
    **/
    public function isKeyEnter(?index:DimIndex, ?activatedOnly:Bool = false) {
        var result = _charString.length > 0;

        if (result) {
            if (activatedOnly && _activatedIndex > -1) {
                var activity = new Activity();
                activity.type = ACTIVITY_KEY_ENTER;
                activity.data.push(_charString);
                _gctx.activities[_activatedIndex].push(activity);
                return result;
            }
            else if (activatedOnly) {
                return false;
            }

            switch (index) {
                case Direct(item): {
                    var activity = new Activity();
                    activity.type = ACTIVITY_KEY_ENTER;
                    activity.data.push(_charString);
                    _gctx.activities[item].push(activity);
                }
                case Group(item): {
                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_KEY_ENTER;
                        activity.data.push(_charString);
                        _gctx.activities[child].push(activity);
                    }
                }
            }
        }

        return result;
    }

    /**
    * Checks that the following dimension at the given index is receiving a drag start
    * event.
    *
    * @param index The index of the dimension to check.
    * @param allGroup 
    * @return Returns a boolean value to determine the drag start event.
    **/
    public function isDragStart(?index:DimIndex, ?allGroup:Bool = false) {
        var actualIndex = -1;
        var partOfGroup = false;
        switch (index) {
            case Direct(item): {
                actualIndex = item;
            }
            case Group(item): {
                partOfGroup = true;
                for (dim in _gctx.getDimIndicesAtGroupIndex(item)) {
                    if (dim == _isDragStart) {
                        actualIndex = dim;
                        break;
                    }
                }
            }
        }

        var result = _isDragStart == actualIndex && (_activatedIndex == -1 || _activatedIndex == actualIndex);

        if (result) {
            switch (index) {
                case Group(item): {
                    if (!allGroup) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_DRAG_START;
                        _gctx.activities[actualIndex].push(activity);
                        return result;
                    }

                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_DRAG_START;
                        _gctx.activities[child].push(activity);    
                    }
                }
                default: {
                    var activity = new Activity();
                    activity.type = ACTIVITY_DRAG_START;
                    _gctx.activities[actualIndex].push(activity);
                }
            }
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
    public function isDragging(?index:DimIndex, ?allGroup:Bool = false) {
        var actualIndex = -1;
        var partOfGroup = false;
        switch (index) {
            case Direct(item): {
                actualIndex = item;
            }
            case Group(item): {
                partOfGroup = true;
                for (dim in _gctx.getDimIndicesAtGroupIndex(item)) {
                    if (dim == _drag.dragIndex) {
                        actualIndex = dim;
                        break;
                    }
                }
            }
        }

        if (actualIndex < 0 || actualIndex > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _drag.dragIndex == actualIndex && (_activatedIndex == -1 || _activatedIndex == actualIndex);

        if (result) {
            switch (index) {
                case Group(item): {
                    if (!allGroup) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_DRAGGING;
                        _gctx.activities[actualIndex].push(activity);
                        return result;
                    }

                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_DRAGGING;
                        _gctx.activities[child].push(activity);    
                    }
                }
                default: {
                    var activity = new Activity();
                    activity.type = ACTIVITY_DRAGGING;
                    _gctx.activities[actualIndex].push(activity);
                }
            }
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
    public function isDragEnd(?index:DimIndex, ?allGroup:Bool = false) {
        var actualIndex = -1;
        var partOfGroup = false;
        switch (index) {
            case Direct(item): {
                actualIndex = item;
            }
            case Group(item): {
                partOfGroup = true;
                for (dim in _gctx.getDimIndicesAtGroupIndex(item)) {
                    if (dim == _isDragEnd) {
                        actualIndex = dim;
                        break;
                    }
                }
            }
        }

        if (actualIndex < 0 || actualIndex > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _isDragEnd == actualIndex && (_activatedIndex == -1 || _activatedIndex == actualIndex);

        if (result) {
            switch (index) {
                case Group(item): {
                    if (!allGroup) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_DRAG_END;
                        _gctx.activities[actualIndex].push(activity);
                        return result;
                    }

                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_DRAG_END;
                        _gctx.activities[child].push(activity);    
                    }
                }
                default: {
                    var activity = new Activity();
                    activity.type = ACTIVITY_DRAG_END;
                    _gctx.activities[actualIndex].push(activity);
                }
            }
        }

        return result;
    }

    /**
    * Gets the activity data for a given activity type at the specified dimension index.
    * Returns `null` if no activity is found for that type or an event was never received.
    *
    * @param index The dimension index.
    * @param type The activity type to check.
    *
    * @return The array of data for a specific activity type, if any exist. `null` otherwise.
    **/
    public function getActivity(index:Int, type:ActivityType):Array<Dynamic> {
        if (_gctx.activities[index] == null) {
            return null;
        }

        if (_gctx.activities[index].length == 0) {
            return null;
        }

        for (a in _gctx.activities[index]) {
            if (a.type == type) {
                return a.data;
            }
        }

        return null;
    }

    /**
    * Checks if the given activity data for and activity type and dimension index matches
    * to the activity data stored for the event. This function uses `getActivity` internally.
    *
    * @param index The index of the dimension.
    * @param type The type of activity.
    * @param data An array of data to match.
    *
    * @return Returns `true` if the data matches, `false` otherwise. Returns `false` if there is no data.
    **/
    public function hasActivityData(index:Int, type:ActivityType, data:...Dynamic) {
        var array = getActivity(index, type);
        if (array == null) {
            return false;
        }

        var result = true;

        for (i in 0...data.length) {
            var matched = false;
            for (j in 0...array.length) {
                if (array[j] == data[i]) {
                    matched = true;
                    break;
                }
            }
            if (!matched) {
                result = false;
                break;
            }
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
        _charString = "";

        // do container checks here.
        for (i in 0..._gctx.containers.length) {
            var container = _gctx.containers[i];
            // calculate content
            var maxWidth = 0.0;
            var maxHeight = 0.0;
            var containerDim = _gctx.dimensions[container.dimIndex];
            // give a gap of a third of the container
            // to allow a more natural view of the contents
            var gap = containerDim.width * 0.3; 

            for (child in container.childIndices) {
                switch (child) {
                    case Direct(childItem): {
                        var dim = _gctx.dimensions[childItem];
                        maxWidth = Math.max(dim.x + dim.width + gap, maxWidth);
                        maxHeight = Math.max(dim.y + dim.height + gap, maxHeight);
                    }
                    case Group(childGroup): {
                        for (grpDim in _gctx.getDimIndicesAtGroupIndex(childGroup)) {
                            var dim = _gctx.dimensions[grpDim];
                            maxWidth = Math.max(dim.x + dim.width + gap, maxWidth);
                            maxHeight = Math.max(dim.y + dim.height + gap, maxHeight);
                        }
                    }
                }
            }

            container.content = new FastVector2(maxWidth, maxHeight);
        }

        for (i in 0..._gctx.containers.length) {
            var container = _gctx.containers[i];
            // infinite scroll or manual intervention, so don't clamp anything
            if (container.infiniteScroll || container.manual) {
                continue;
            }

            var dim = _gctx.dimensions[container.dimIndex];

            if (container.offset.x > 0) {
                container.offset.x = 0;
            }

            if (container.offset.x < -(container.content.x - dim.width) && container.content.x > dim.width) {
                container.offset.x = -(container.content.x - dim.width);
            }

            if (container.offset.y > 0) {
                container.offset.y = 0;
            }

            if (container.offset.y < -(container.content.y - dim.height) && container.content.y > dim.height) {
                container.offset.y = -(container.content.y - dim.height);
            }
        }

        _lastMousePosition = FastVector2.fromVector2(GlobalEvents.getMousePosition());
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