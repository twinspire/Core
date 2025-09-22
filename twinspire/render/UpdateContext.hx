package twinspire.render;

import js.lib.webassembly.Table;
import twinspire.DimIndex.DimIndexUtils;
import twinspire.events.EventArgs;
import twinspire.events.GameEventProcessingType;
import twinspire.events.GameEventProcessor;
import twinspire.events.GameEventTimeline;
import twinspire.events.GameEventTimeNode;
import twinspire.events.GameEvent;
import twinspire.events.Buttons;
import twinspire.events.EventDispatcher;
import twinspire.render.GraphicsContext;
import twinspire.render.RenderQuery;
import twinspire.render.QueryType;
import twinspire.render.MouseScrollValue;
import twinspire.render.ActivityType;
import twinspire.text.TextRenderer;
import twinspire.geom.Dim;
import twinspire.Application;
import twinspire.GlobalEvents;
import twinspire.Dimensions.VerticalAlign;
import twinspire.Dimensions.HorizontalAlign;
import twinspire.Dimensions.*;
import twinspire.HotKey;
using twinspire.extensions.ArrayExtensions;
using twinspire.utils.ArrayUtils;

import kha.input.KeyCode;
import kha.math.FastVector2;
import kha.System;

typedef KeyRepeatInfo = {
    var initialDelay:Float;
    var repeatRate:Float;
    var timeHeld:Float;
    var isRepeating:Bool;
    var lastRepeatTime:Float;
}

@:allow(Application)
class UpdateContext {

    private var _gctx:GraphicsContext;
    private var _events:Array<GameEvent>;
    private var _eventProcessor:GameEventProcessor;
    private var _eventDispatcher:EventDispatcher;
    private var _hotkeys:Array<HotKey>;
    private var _hotkeyAssociations:Map<DimIndex, Array<String>>;

    // UI stuff
    private var _tempUI:Array<Int>;
    private var _retainedMouseDown:Array<Int>;

    private var _mouseFocusIndexUI:Int;
    private var _mouseIsOver:Int;
    private var _mouseIsDown:Int;
    private var _mouseIsScrolling:Int;
    private var _mouseScrollValue:Int;
    private var _mouseIsReleased:Int;
    private var _mouseButtons:Buttons;
    private var _keysUp:Array<Int>;
    private var _keysDown:Array<Int>;
    private var _charString:String;
    private var _activatedIndex:Int;

    // button pressing down
    // floating points since some buttons allow pressure
    private var _gamepadDown:Array<Float>;
    private var _gamepadUp:Array<Float>;
    // axes, array of arrays for multiple joy sticks on a single gamepad,
    // and 2 indices (first for x-axis, second for y-axis)
    private var _gamepadAxis:Array<Array<Float>>;

    // where each touch index is a finger
    private var _touchStart:Array<FastVector2>;
    // added to only when touch is released
    private var _touchEnd:Array<FastVector2>;
    private var _touchIndicesReleased:Array<Int>;
    private var _touchPoints:Array<FastVector2>;
    // defines the speed from the last frame given the last frame positions
    private var _touchVelocity:Array<FastVector2>;
    // determines the force between the start position and end position, using
    // velocity to determine continued motion for a limited period.
    private var _touchForce:Array<FastVector2>;

    private var _penStart:FastVector2;
    // array of floats for when the pen is moved/released,
    // values can be retrieved by the user or used to determine force/velocity
    // in a certain direction
    private var _penPressure:Array<Float>;
    private var _penEnd:FastVector2;
    private var _penIsErasing:Bool;

    private var _keyRepeatStates:Map<KeyCode, KeyRepeatInfo>;
    private var _defaultInitialDelay:Float = 0.5;  // 500ms initial delay
    private var _defaultRepeatRate:Float = 0.05;

    private var _lastMousePosition:FastVector2;
    private var _mouseDownFirstPos:FastVector2;
    private var _mouseDragTolerance:Float = 1.5;

    private var _drag:DragObject;
    private var _isDragStart:Int;
    private var _isDragEnd:Int;
    private var _containerDragIndex:Int;

    private static var _deltaTime:Float;

    private var _toggles:Map<DimIndex, Bool>;

    // animations
    private var _moveToAnimations:Array<MoveToAnimation>;


    public static var deltaTime(get, default):Float;
    static function get_deltaTime() return _deltaTime;

    /**
    * Get the frame count per second.
    **/
    public static function getFrameCount() {
        #if js
        return 1 / Application.getCorrectedDeltaTime();
        #else
        return 1 / _deltaTime;
        #end
    }

    public function new(gctx:GraphicsContext) {
        _gctx = gctx;
        _events = [];
        _keyRepeatStates = new Map<KeyCode, KeyRepeatInfo>();
        _eventProcessor = new GameEventProcessor();
        _eventDispatcher = new EventDispatcher();
        _retainedMouseDown = [];
        _moveToAnimations = [];
        _toggles = [];
        _hotkeys = [];
        _hotkeyAssociations = [];

        _mouseFocusIndexUI = -1;
        _mouseIsOver = -1;
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
    * Add a hotkey to this context.
    **/
    public function addHotkey(key:HotKey) {
        _hotkeys.push(key);
    }

    /**
    * Allows a dimension to respond to a hot key being triggered.
    *
    * @param index The dimension to associate a hot key to.
    * @param name The name of the hot key to add to the given index.
    **/
    public function associateKey(index:DimIndex, name:String) {
        if (_hotkeyAssociations.exists(index)) {
            var found = _hotkeyAssociations[index].findIndex((hk) -> hk == name);
            if (found != -1) {
                _hotkeyAssociations.get(index).push(name);
            }
        }
        else {
            _hotkeyAssociations[index] = [name];
        }
    }

    /**
    * Removes a hot key from a given dimension index.
    **/
    public function removeAssociatedKey(index:DimIndex, name:String) {
        if (!_hotkeyAssociations.exists(index)) {
            return;
        }

        var found = _hotkeyAssociations[index].findIndex((hk) -> hk == name);
        if (found > -1) {
            _hotkeyAssociations.get(index).splice(found, 1);
        }
    }

    /**
    * Removes an entire index from the hot key associations.
    **/
    public function removeAssociation(index:DimIndex) {
        if (!_hotkeyAssociations.exists(index)) {
            return;
        }

        _hotkeyAssociations.remove(index);
    }

    /**
    * A high-level function for adding a callback or listener to an event triggered at a given target index.
    * This is typically used for user interface elements and not recommended for frame-to-frame event scenarios.
    * Consider the `GameEvent` system for real-time events.
    * 
    * @param target The target dimension index. The first item of a `Group` index is used if the target is a `Group`.
    * @param type The activity type to listen for.
    * @param listener The callback function to execute when the target receives the activity type.
    **/
    public function addEventListener(target:DimIndex, type:ActivityType, listener:(EventArgs) -> Void) {
        var actualIndex = -1;
        switch (target) {
            case Direct(index): {
                actualIndex = index;
            }
            case Group(index): {
                @:privateAccess(GraphicsContext) {
                    actualIndex = _gctx._groups[index][0];
                }
            }
        }

        if (actualIndex > -1) {
            _eventDispatcher.addEventListener(actualIndex, type, listener);
        }
    }

    public function removeEventListener(target:DimIndex, type:ActivityType) {
        var actualIndex = -1;
        switch (target) {
            case Direct(index): {
                actualIndex = index;
            }
            case Group(index): {
                @:privateAccess(GraphicsContext) {
                    actualIndex = _gctx._groups[index][0];
                }
            }
        }

        if (actualIndex > -1) {
            _eventDispatcher.removeEventListener(actualIndex, type);
        }
    }

    public function addCustomEvent(name:String) {
        return _eventDispatcher.addCustomEvent(name);
    }

    public function triggerEvent(target:Int, name:String, args:EventArgs) {
        _eventDispatcher.triggerEvent(target, name, args);
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

    /**
    * Gets a reference to a dimension at the given index.
    **/
    public function getDimensionsRefAt(index:DimIndex) {
        switch (index) {
            case Direct(item): {
                if (item < 0 || item > _gctx.dimensions.length - 1) {
                    return [ null ];
                }

                return [ _gctx.dimensions[item] ];
            }
            case Group(item): {
                var results = [];
                for (grp in _gctx.getDimIndicesAtGroupIndex(item)) {
                    if (grp > _gctx.dimensions.length - 1) {
                        break;
                    }

                    results.push(_gctx.dimensions[grp]);
                }

                return results;
            }
        }
    }

    public function getTextInputState(index:Int) {
        return _gctx.textInputs[index];
    }

    /**
    * New main processing method with proper event ordering.
    **/
    private function processInputEvents() {
        // Phase 1: Update global state and animations
        _updateGlobalInputState();
        _processAnimations();
        
        // Phase 2: Build interaction candidates
        _buildInteractionCandidates();
        
        // Phase 3: Handle high-priority interactions
        if (_processDragOperations()) return;  // If dragging, skip most other processing
        if (_processModalInteractions()) return;  // If modal active, skip lower priority
        
        // Phase 4: Handle container scrolling (before focus changes)
        _processContainerScrolling();
        
        // Phase 5: Process focus management
        _processFocusChanges();
        
        // Phase 6: Process input for focused elements
        _processFocusedElementInput();
        
        // Phase 7: Process general UI interactions
        _processGeneralUIInteractions();
        
        // Phase 8: Update final state
        _updateFinalState();
    }

    /**
    * Begin update context and start performing event simulations.
    **/
    public function begin() {
        processInputEvents();

        if (_activatedIndex > -1) {
            var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
            if (renderer != null) {
                renderer.update(this);
            }
        }
    }

    //
    // begin new process
    //

    /**
    * Phase 1: Update global input state and animations
    **/
    private function _updateGlobalInputState() {
        // Capture current mouse position
        var mousePos = GlobalEvents.getMousePosition();
        
        // Track mouse down state
        if (_mouseDownFirstPos.x == -1 && GlobalEvents.isAnyMouseButtonDown()) {
            _mouseDownFirstPos = FastVector2.fromVector2(mousePos);
        } else if (GlobalEvents.isNoMouseButtonDown()) {
            _mouseDownFirstPos = new FastVector2(-1, -1);
        }
        
        // Reset per-frame state
        _mouseIsOver = -1;
        _mouseIsDown = -1;
        _mouseIsReleased = -1;
        _mouseIsScrolling = -1;
        _isDragStart = -1;
        _isDragEnd = -1;
        _charString = "";
        
        // Capture keyboard state
        _keysUp = GlobalEvents.isAnyKeyUp();
        _keysDown = GlobalEvents.isAnyKeyDown();
    }
    
    /**
    * Process animations (existing logic)
    **/
    private function _processAnimations() {
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
    }
    
    /**
    * Phase 2: Build list of UI elements that could receive interactions
    **/
    private function _buildInteractionCandidates() {
        _tempUI = [];
        _mouseFocusIndexUI = -1;
        
        var mousePos = GlobalEvents.getMousePosition();
        var currentOrder = -1;
        
        // If dragging, only the drag target is a candidate
        if (_drag.dragIndex != -1) {
            _tempUI.push(_drag.dragIndex);
            return;
        }
        
        // Build list of elements under cursor, sorted by render order
        var remainActive = _mouseDownFirstPos.x > -1 && _mouseDownFirstPos.y > -1;
        
        for (i in 0..._gctx.dimensions.length) {
            @:privateAccess(GraphicsContext) {
                if (!_gctx._activeDimensions[i]) continue;
            }
            
            var query = _gctx.queries[i];
            if (query == null || query.type == QUERY_STATIC) continue;
            
            var actualDim = _gctx.getClientDimensionsAtIndex(Direct(i))[0];
            if (actualDim == null) continue;
            
            var mouseOver = remainActive ? 
                GlobalEvents.isMouseOverDim(actualDim, _mouseDownFirstPos) :
                GlobalEvents.isMouseOverDim(actualDim);
            
            if (mouseOver && actualDim.order > currentOrder) {
                _tempUI.push(i);
                currentOrder = actualDim.order;
            }
        }
    }
    
    /**
    * Phase 3: Handle drag operations (highest priority)
    **/
    private function _processDragOperations():Bool {
        if (!_attemptDragStart()) {
            return false;
        }
        
        // Continue existing drag
        _continueDragOperation();
        
        // Check for drag end
        if (GlobalEvents.isAnyMouseButtonReleased()) {
            _endDragOperation();
            return false;
        }
        
        return true; // Dragging blocks other interactions
    }
    
    /**
    * Phase 3b: Handle modal interactions (high priority)
    **/
    private function _processModalInteractions():Bool {
        // If you have modals/popups, they would be handled here
        // For now, return false to continue processing
        return false;
    }
    
    /**
    * Phase 4: Process container scrolling
    **/
    private function _processContainerScrolling() {
        var containers = _gctx.getActiveContainers();
        var activeContainerIndex = _findActiveContainer(containers);
        
        if (activeContainerIndex >= 0) {
            _handleContainerScrolling(activeContainerIndex);
        }
    }
    
    /**
    * Phase 5: Handle focus changes from mouse clicks and tab navigation
    **/
    private function _processFocusChanges() {
        // Handle tab navigation first (global)
        _processTabNavigation();
        
        // Handle mouse-based focus changes
        _processMouseFocusChanges();
    }
    
    /**
    * Process tab navigation
    **/
    private function _processTabNavigation() {
        if (_keysUp.length == 0) return;
        
        var keyMods = GlobalEvents.getCurrentKeyModifiers();
        var tabIndex = _keysUp.indexOf(KeyCode.Tab);
        if (tabIndex == -1) return;
        
        // Remove tab from keys to prevent other processing
        _keysUp.splice(tabIndex, 1);
        
        var increment = 1;
        if (keyMods.contains(KeyCode.Shift)) {
            increment = -1;
        }
        
        _navigateToNextFocusableElement(increment);
    }
    
    /**
    * Navigate to next focusable element
    **/
    private function _navigateToNextFocusableElement(direction:Int) {
        var startIndex = _activatedIndex;
        var currentIndex = startIndex;
        var foundNext = false;
        
        // Search for next focusable element
        var attempts = 0;
        var maxAttempts = _gctx.queries.length;
        
        while (attempts < maxAttempts) {
            currentIndex += direction;
            
            // Wrap around
            if (currentIndex >= _gctx.queries.length) {
                currentIndex = 0;
            } else if (currentIndex < 0) {
                currentIndex = _gctx.queries.length - 1;
            }
            
            var query = _gctx.queries[currentIndex];
            if (query != null && query.type == QUERY_UI && 
                (query.acceptsTextInput || query.acceptsKeyInput)) {
                _activatedIndex = currentIndex;
                foundNext = true;
                break;
            }
            
            if (currentIndex == startIndex) break;
            attempts++;
        }
    }
    
    /**
    * Handle focus changes from mouse clicks
    **/
    private function _processMouseFocusChanges() {
        // Commit focus change immediately on mouse down
        if (GlobalEvents.isAnyMouseButtonDown()) {
            _commitFocusChangeImmediate();
        }
    }
    
    private function _commitFocusChangeImmediate() {
        // Don't change focus if actively selecting text
        if (_activatedIndex > -1 && _gctx.queries[_activatedIndex].acceptsTextInput) {
            var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
            if (renderer != null && renderer.isSelecting()) {
                return; // Preserve current focus during text selection
            }
        }
        
        if (_tempUI.length == 0) {
            // Clicked outside all UI - clear focus
            _activatedIndex = -1;
        } else {
            var lastActivatedIndex = _activatedIndex;
            // Find topmost focusable element and set focus immediately
            var topMostFocusable = -1;
            var i = _tempUI.length - 1;
            while (i > -1) {
                var index = _tempUI[i];
                var query = _gctx.queries[index];
                if (query != null && (query.acceptsTextInput || query.acceptsKeyInput)) {
                    topMostFocusable = index;
                    break;
                }
                i--;
            }
            
            if (topMostFocusable >= 0) {
                _activatedIndex = topMostFocusable;
            }
            else {
                var renderer = _gctx.getTextRendererByDimIndex(Direct(lastActivatedIndex));
                if (renderer != null) {
                    renderer.loseFocus();
                }
            }
        }
    }
    
    /**
    * Phase 6: Process input for the currently focused element
    **/
    private function _processFocusedElementInput() {
        if (_activatedIndex == -1) return;
        
        var query = _gctx.queries[_activatedIndex];
        if (query == null) return;
        
        if (query.acceptsTextInput) {
            _processTextInputKeys();
            _processTextInputMouse();
        } else if (query.acceptsKeyInput) {
            _processKeyInputElement();
        }
    }
    
    /**
    * Process keyboard input for text elements
    **/
    private function _processTextInputKeys() {
        var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
        if (renderer == null) return;
        
        // Process character input (no repeat needed for character codes)
        for (c in GlobalEvents.getKeyCharCode()) {
            _charString += String.fromCharCode(c);
            renderer.insertAt(String.fromCharCode(c), renderer.getCursorPosition());
        }
        
        // Process special keys with proper repeat timing
        var consumedKeys = [];

        for (keyCode in _keysDown) {
            var key = cast(keyCode, KeyCode);
            var handled = false;
            
            switch (key) {
                case KeyCode.Backspace:
                    _handleKeyWithRepeat(key, () -> {
                        renderer.delete();
                    });
                    handled = true;
                    
                case KeyCode.Delete:
                    _handleKeyWithRepeat(key, () -> {
                        var cursorPos = renderer.getCursorPosition();
                        renderer.delete(cursorPos, 1);
                    });
                    handled = true;
                    
                case KeyCode.Left:
                    _handleKeyWithRepeat(key, () -> {
                        renderer.enableCursorAnimation(false);
                        if (GlobalEvents.isKeyDown(KeyCode.Shift)) {
                            renderer.extendSelectionLeft();
                        } else {
                            renderer.moveCursor(-1);
                        }
                    });
                    handled = true;
                    
                case KeyCode.Right:
                    _handleKeyWithRepeat(key, () -> {
                        renderer.enableCursorAnimation(false);
                        if (GlobalEvents.isKeyDown(KeyCode.Shift)) {
                            renderer.extendSelectionRight();
                        } else {
                            renderer.moveCursor(1);
                        }
                    });
                    handled = true;
                    
                case KeyCode.Up:
                    if (renderer.isMultiLine()) {
                        _handleKeyWithRepeat(key, () -> {
                            renderer.enableCursorAnimation(false);
                            if (GlobalEvents.isKeyDown(KeyCode.Shift)) {
                                renderer.extendSelectionUp();
                            } else {
                                renderer.moveCursorUp();
                            }
                        });
                        handled = true;
                    }
                    
                case KeyCode.Down:
                    if (renderer.isMultiLine()) {
                        _handleKeyWithRepeat(key, () -> {
                            renderer.enableCursorAnimation(false);
                            if (GlobalEvents.isKeyDown(KeyCode.Shift)) {
                                renderer.extendSelectionDown();
                            } else {
                                renderer.moveCursorDown();
                            }
                        });
                        handled = true;
                    }
                    
                case KeyCode.Home:
                    _handleKeyWithRepeat(key, () -> {
                        if (GlobalEvents.isKeyDown(KeyCode.Shift)) {
                            renderer.extendSelectionToLineStart();
                        } else {
                            renderer.moveCursorToLineStart();
                        }
                    });
                    handled = true;
                    
                case KeyCode.End:
                    _handleKeyWithRepeat(key, () -> {
                        if (GlobalEvents.isKeyDown(KeyCode.Shift)) {
                            renderer.extendSelectionToLineEnd();
                        } else {
                            renderer.moveCursorToLineEnd();
                        }
                    });
                    handled = true;
                    
                case KeyCode.Return:
                    // Return typically doesn't repeat, just single action
                    if (renderer.isMultiLine()) {
                        renderer.insertAt("\n", renderer.getCursorPosition());
                        handled = true;
                    }
                default:
            }
            
            if (handled) {
                consumedKeys.push(keyCode);
            }
        }
        
        // Clean up key repeat states for keys that are no longer pressed
        _cleanupKeyRepeatStates();
        
        // Remove consumed keys from global list
        for (key in consumedKeys) {
            var index = _keysDown.indexOf(key);
            if (index != -1) {
                _keysDown.splice(index, 1);
            }
        }

        if (consumedKeys.length == 0) {
            renderer.enableCursorAnimation(true);
        }
    }

    /**
    * Handle key with proper repeat timing.
    **/
    private function _handleKeyWithRepeat(key:KeyCode, action:() -> Void) {
        if (GlobalEvents.isKeyDown(key)) {
            if (!_keyRepeatStates.exists(key)) {
                // First press - execute immediately
                action();
                
                // Set up repeat state
                var repeat:KeyRepeatInfo = {
                    timeHeld: 0.0,
                    isRepeating: false,
                    initialDelay: _defaultInitialDelay,
                    repeatRate: _defaultRepeatRate,
                    lastRepeatTime: 0.0
                };
                
                _keyRepeatStates.set(key, repeat);
            } else {
                // Key being held - handle repeat timing
                var repeatInfo = _keyRepeatStates.get(key);
                repeatInfo.timeHeld += deltaTime;
                
                if (!repeatInfo.isRepeating) {
                    // Check if we've passed the initial delay
                    if (repeatInfo.timeHeld >= repeatInfo.initialDelay) {
                        repeatInfo.isRepeating = true;
                        repeatInfo.lastRepeatTime = 0.0;
                        action(); // First repeat
                    }
                } else {
                    // In repeat mode - check repeat rate
                    repeatInfo.lastRepeatTime += deltaTime;
                    if (repeatInfo.lastRepeatTime >= repeatInfo.repeatRate) {
                        repeatInfo.lastRepeatTime = 0.0;
                        action(); // Repeated action
                    }
                }
            }
        }
    }
    
    /**
    * Clean up key repeat states for keys that are no longer pressed.
    **/
    private function _cleanupKeyRepeatStates() {
        var keysToRemove:Array<KeyCode> = [];
        
        for (key in _keyRepeatStates.keys()) {
            if (!GlobalEvents.isKeyDown(key)) {
                keysToRemove.push(key);
            }
        }
        
        for (key in keysToRemove) {
            _keyRepeatStates.remove(key);
        }
    }
    
    /**
    * Set custom repeat timing for specific keys or globally.
    **/
    public function setKeyRepeatTiming(initialDelay:Float, repeatRate:Float) {
        _defaultInitialDelay = initialDelay;
        _defaultRepeatRate = repeatRate;
    }
    
    /**
    * Get current key repeat state (for debugging).
    **/
    public function getKeyRepeatState(key:KeyCode):KeyRepeatInfo {
        return _keyRepeatStates.get(key);
    }
    
    /**
    * Check if a key is primarily used for text input
    **/
    private function _isTextInputKey(key:KeyCode):Bool {
        return switch (key) {
            case KeyCode.Backspace | KeyCode.Delete | KeyCode.Left | KeyCode.Right | 
                 KeyCode.Up | KeyCode.Down | KeyCode.Home | KeyCode.End | KeyCode.Return: true;
            default: false;
        };
    }
    
    /**
    * Process mouse input for text elements (selection, cursor positioning)
    **/
    private function _processTextInputMouse() {
        var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
        if (renderer == null) return;
        
        if (GlobalEvents.isAnyMouseButtonReleased()) {
            renderer.endSelection();
        }
        
        // Always process if we have an active selection, regardless of mouse position
        if (renderer.isSelecting()) {
            var mousePos = GlobalEvents.getMousePosition();
            var charPos = renderer.getCharacterPositionFromMouse(mousePos.x, mousePos.y);
            renderer.updateSelection(charPos);
            return;
        }
        
        // Only check bounds for starting new interactions
        if (_tempUI.indexOf(_activatedIndex) == -1) return;

        // Handle mouse down to start selection
        if (GlobalEvents.isAnyMouseButtonDown()) {
            var mousePos = GlobalEvents.getMousePosition();
            var charPos = renderer.getCharacterPositionFromMouse(mousePos.x, mousePos.y);
            renderer.setCursorPosition(charPos);
            renderer.startSelection(charPos);
        }
    }
    
    /**
    * Process input for non-text elements that accept key input
    **/
    private function _processKeyInputElement() {
        
    }
    
    /**
    * Phase 7: Process general UI interactions (for non-focused elements)
    **/
    private function _processGeneralUIInteractions() {
        _processMouseInteractions();
        _processGlobalKeyboardShortcuts();
    }
    
    /**
    * Process mouse interactions for all UI elements
    **/
    private function _processMouseInteractions() {
        if (_tempUI.length == 0) return;
        
        var topMostIndex = _tempUI[_tempUI.length - 1];
        var query = _gctx.queries[topMostIndex];

        _mouseIsOver = topMostIndex;
        
        // Mouse down events
        if (GlobalEvents.isAnyMouseButtonDown()) {
            _mouseIsDown = topMostIndex;
            _mouseButtons = GlobalEvents.getCurrentMouseButton();
        }
        
        // Mouse release events
        if (GlobalEvents.isAnyMouseButtonReleased()) {
            _mouseIsReleased = topMostIndex;
        }
        
        // Mouse scroll events
        var scrollDelta = GlobalEvents.getMouseDelta();
        if (scrollDelta != 0) {
            _mouseIsScrolling = topMostIndex;
            _mouseScrollValue = scrollDelta;
        }
    }
    
    /**
    * Process global keyboard shortcuts (Ctrl+C, Ctrl+V, F-keys, etc.)
    **/
    private function _processGlobalKeyboardShortcuts() {
        var keyMods = GlobalEvents.getCurrentKeyModifiers();
        var ctrlPressed = keyMods.contains(KeyCode.Control);
        
        for (keyCode in _keysDown) {
            var key = cast(keyCode, KeyCode);
            var handled = false;
            
            if (ctrlPressed) {
                switch (key) {
                    case KeyCode.C:
                        // Copy operation - could be handled by focused text input or globally
                        _processCopyCommand();
                        handled = true;
                        
                    case KeyCode.V:
                        // Paste operation
                        _processPasteCommand();
                        handled = true;
                        
                    case KeyCode.X:
                        // Cut operation
                        _processCutCommand();
                        handled = true;
                        
                    case KeyCode.Z:
                        // Undo operation
                        _processUndoCommand();
                        handled = true;
                        
                    case KeyCode.Y:
                        // Redo operation
                        _processRedoCommand();
                        handled = true;
                    default:
                }
            }
            
            // F-keys and other global shortcuts
            switch (key) {
                case KeyCode.Escape:
                    // Clear selection, close modals, etc.
                    _processEscapeCommand();
                    handled = true;
                    
                case KeyCode.F1:
                    // Help
                    handled = true;
                    
                default:
                // Add other global shortcuts as needed
            }
            
            if (handled) {
                var index = _keysDown.indexOf(keyCode);
                if (index != -1) {
                    _keysDown.splice(index, 1);
                }
            }
        }
    }
    
    /**
    * Phase 8: Update final state and cleanup
    **/
    private function _updateFinalState() {
        // Any final state updates or cleanup
        // This is where you might update hover states, tooltips, etc.
    }
    
    // Helper methods for the new system
    
    private function _attemptDragStart() {
        if (!GlobalEvents.isAnyMouseButtonDown()) { 
            _drag.dragIndex = -1;
            _drag.childIndex = -1;
            _drag.firstMousePosition = new FastVector2(-1, -1);
            _drag.scrollIndex = -1;
            return false;
        }
        
        var mousePos = GlobalEvents.getMousePosition();
        var dragDistance = _mouseDownFirstPos.sub(FastVector2.fromVector2(mousePos));
        var topMostIndex = -1;
        if (_tempUI.length > 0) {
            topMostIndex = _tempUI[_tempUI.length - 1];
        }

        if (topMostIndex == -1) {
            return false;
        }

        var query = _gctx.queries[topMostIndex];
        
        if (query.allowDragging && ((dragDistance.x < -7.5 || dragDistance.x > 7.5) || (dragDistance.y < -7.5 || dragDistance.y > 7.5))) {
            _drag.dragIndex = topMostIndex;
            _drag.firstMousePosition = _mouseDownFirstPos;
            _isDragStart = topMostIndex;
            return true;
        }

        return false;
    }
    
    private function _continueDragOperation() {
        if (_drag.dragIndex == -1) return;
        
        var mousePos = GlobalEvents.getMousePosition();
        var mouseDelta = new FastVector2(
            mousePos.x - _lastMousePosition.x,
            mousePos.y - _lastMousePosition.y
        );

        _gctx.dimensions[_drag.dragIndex].x += mouseDelta.x;
        _gctx.dimensions[_drag.dragIndex].y += mouseDelta.y;
        _gctx.markDimChange(Direct(_drag.dragIndex));

        var children = _gctx.getLinksFromIndex(Direct(_drag.dragIndex));
        for (childIndex in children) {
            _gctx.dimensions[childIndex].x += mouseDelta.x;
            _gctx.dimensions[childIndex].y += mouseDelta.y;
            _gctx.markDimChange(Direct(childIndex));
        }
    }
    
    private function _endDragOperation() {
        if (_drag.dragIndex == -1) return;
        
        _isDragEnd = _drag.dragIndex;
        _drag.dragIndex = -1;
        _drag.childIndex = -1;
        _drag.scrollIndex = -1;
        _drag.firstMousePosition = new FastVector2(-1, -1);
    }
    
    private function _findActiveContainer(containers:Array<Dynamic>):Int {
        var possibleActiveContainers = [];
        var lastContainerIndex = -1;
        
        for (i in 0...containers.length) {
            var context = containers[i];
            var containerIndex = _tempUI.indexOf(DimIndexUtils.getDirectIndex(context.index));
            if (containerIndex > lastContainerIndex && containerIndex > -1) {
                possibleActiveContainers.push(i);
            }
        }
        
        return possibleActiveContainers.length > 0 ? 
            possibleActiveContainers[possibleActiveContainers.length - 1] : -1;
    }
    
    private function _handleContainerScrolling(containerIndex:Int):Bool {
        // Check if focused text input should handle mouse wheel events first
        if (_activatedIndex > -1 && _gctx.queries[_activatedIndex].acceptsTextInput) {
            var textInputDimIndex = _activatedIndex;
            
            // If mouse is over text input AND there's actual wheel scrolling
            if (_tempUI.indexOf(textInputDimIndex) != -1 && GlobalEvents.getMouseDelta() != 0) {
                var renderer = _gctx.getTextRendererByDimIndex(Direct(textInputDimIndex));
                if (renderer != null && _handleTextRendererScrolling(renderer)) {
                    return true; // Text input consumed the scroll event
                }
            }
        }
        
        // Handle normal container scrolling
        return _scrollContainerAtIndex(containerIndex);
    }
    
    /**
    * Handle scrolling for text renderers with Shift key support.
    **/
    private function _handleTextRendererScrolling(renderer:TextRenderer):Bool {
        var scrollDelta = GlobalEvents.getMouseDelta();
        if (scrollDelta == 0) return false;
        
        var keyMods = GlobalEvents.getCurrentKeyModifiers();
        var shiftPressed = keyMods.contains(KeyCode.Shift);
        
        if (shiftPressed) {
            // Shift + wheel = horizontal scrolling
            if (renderer.canScrollHorizontally()) {
                renderer.scrollHorizontally(scrollDelta);
                return true;
            }
        } else {
            // Normal wheel = vertical scrolling (multi-line) or horizontal (single-line overflow)
            if (renderer.isMultiLine() && renderer.canScrollVertically()) {
                renderer.scrollVertically(scrollDelta);
                return true;
            } else if (!renderer.isMultiLine() && renderer.canScrollHorizontally()) {
                // Single-line with overflow scrolls horizontally by default
                renderer.scrollHorizontally(scrollDelta);
                return true;
            }
        }
        
        return false; // Couldn't handle scrolling
    }
    
    /**
    * Enhanced container scrolling with Shift key support.
    **/
    private function _scrollContainerAtIndex(containerIndex:Int):Bool {
        if (containerIndex == -1) return false;
        
        var scrollDelta = GlobalEvents.getMouseDelta();
        if (scrollDelta == 0) return false;
        
        @:privateAccess(GraphicsContext) {
            var i = _gctx.findContainerForDimension(containerIndex);
            if (i < 0 || i >= _gctx._activeContainers.length) {
                return false;
            }
            
            var context = _gctx._activeContainers[i];
            var space = context.space;
            if (!space.scrollable) return false;
            
            var keyMods = GlobalEvents.getCurrentKeyModifiers();
            var shiftPressed = keyMods.contains(KeyCode.Shift);
            
            var scrollAmount = scrollDelta * 20; // Adjust scroll sensitivity
            
            if (shiftPressed) {
                // Shift + wheel = horizontal scrolling
                if (space.canScrollHorizontally()) {
                    space.scrollBy(scrollAmount, 0);
                    return true;
                }
            } else {
                // Normal wheel = vertical scrolling
                if (space.canScrollVertically()) {
                    space.scrollBy(0, scrollAmount);
                    return true;
                }
            }
            
            // Handle click-and-drag scrolling (mouse button down)
            if (GlobalEvents.isMouseButtonDown(space.scrollButtons)) {
                var mousePos = GlobalEvents.getMousePosition();
                var mouseDelta = new FastVector2(
                    mousePos.x - _lastMousePosition.x,
                    mousePos.y - _lastMousePosition.y
                );
                
                // Drag scrolling works in both directions simultaneously
                space.scrollByImmediate(-mouseDelta.x, -mouseDelta.y);
                return true;
            }
        }
        
        return false;
    }
    
    // Global shortcut command implementations
    private function _processCopyCommand() {
        if (_activatedIndex > -1 && _gctx.queries[_activatedIndex].acceptsTextInput) {
            var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
            if (renderer != null) {
                renderer.copySelection();
            }
        }
    }
    
    private function _processPasteCommand() {
        if (_activatedIndex > -1 && _gctx.queries[_activatedIndex].acceptsTextInput) {
            var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
            if (renderer != null) {
                renderer.pasteFromClipboard();
            }
        }
    }
    
    private function _processCutCommand() {
        if (_activatedIndex > -1 && _gctx.queries[_activatedIndex].acceptsTextInput) {
            var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
            if (renderer != null) {
                renderer.cutSelection();
            }
        }
    }
    
    private function _processUndoCommand() {
        if (_activatedIndex > -1 && _gctx.queries[_activatedIndex].acceptsTextInput) {
            var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
            if (renderer != null) {
                renderer.undo();
            }
        }
    }
    
    private function _processRedoCommand() {
        if (_activatedIndex > -1 && _gctx.queries[_activatedIndex].acceptsTextInput) {
            var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
            if (renderer != null) {
                renderer.redo();
            }
        }
    }
    
    private function _processEscapeCommand() {
        // Clear text selection if any
        if (_activatedIndex > -1 && _gctx.queries[_activatedIndex].acceptsTextInput) {
            var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
            if (renderer != null) {
                renderer.clearSelection();
            }
        }
        
        // Close modals, clear focus, etc.
        // ... additional escape handling
    }

    private function _validateActivatedIndex() {
        // Ensure the activated index is still valid
        if (_activatedIndex >= 0) {
            if (_activatedIndex >= _gctx.queries.length || 
                _gctx.queries[_activatedIndex] == null ||
                !(_gctx.queries[_activatedIndex].acceptsTextInput || _gctx.queries[_activatedIndex].acceptsKeyInput)) {
                _activatedIndex = -1;
            }
        }
    }

    //
    // end new process
    //

    private function determineInitialMouseEvents() {
        var i = _tempUI.length - 1;
        var hasTextInput = false;
        while (i > -1) {
            var index = _tempUI[i--];
            if (_gctx.queries[index].acceptsTextInput && _drag.dragIndex == -1) {
                hasTextInput = true;
                break;
            }
        }

        if (_tempUI.length == 0 && GlobalEvents.isAnyMouseButtonDown()) {
            // Check if we're in text selection mode
            if (_activatedIndex > -1 && _gctx.queries[_activatedIndex].acceptsTextInput) {
                var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
                if (renderer != null && renderer.isSelecting()) {
                    return; // Don't clear focus during text selection
                }
            }
            
            // Only clear focus if this is a deliberate click outside
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
                var renderer = _gctx.getTextRendererByDimIndex(Direct(_activatedIndex));
                
                for (c in GlobalEvents.getKeyCharCode()) {
                    _charString += String.fromCharCode(c);
                }
                
                acceptNewEvents = false;
            }
        }

        return acceptNewEvents;
    }

    private function handleContainerScrolling(index:Int) {
        if (index == -1) {
            return false;
        }

        var mousePos = GlobalEvents.getMousePosition();
        var isScrolling = false;
        
        @:privateAccess(GraphicsContext) {
            var i = _gctx.findContainerForDimension(index);
            if (i < 0 || i >= _gctx._activeContainers.length) {
                return false;
            }

            var context = _gctx._activeContainers[i];
            var space = context.space;
            if (!space.scrollable) return false;
            
            // Handle mouse wheel scrolling
            var scrollDelta = GlobalEvents.getMouseDelta();
            if (scrollDelta != 0) {
                var scrollAmount = scrollDelta * 20; // Adjust scroll sensitivity
                if (_keysDown.contains(KeyCode.Shift)) {
                    space.scrollBy(scrollAmount, 0);
                } else {
                    space.scrollBy(0, scrollAmount);
                }
                isScrolling = true;
            }
            
            // Handle click-and-drag scrolling
            if (GlobalEvents.isMouseButtonDown(space.scrollButtons)) {
                var mouseDelta = new FastVector2(
                    mousePos.x - _lastMousePosition.x,
                    mousePos.y - _lastMousePosition.y
                );
                // For drag scrolling, use immediate scrolling to feel responsive
                space.scrollByImmediate(-mouseDelta.x, -mouseDelta.y);
                isScrolling = true;
            }
        }

        return isScrolling;
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
                _mouseButtons = BUTTON_NONE;
            }

            if (GlobalEvents.isAnyMouseButtonDown()) {
                if (_drag.childIndex > -1 && _drag.scrollIndex == -1) {
                    _mouseIsDown = _drag.childIndex;
                }
                else {
                    _mouseIsDown = index;
                    _mouseButtons = GlobalEvents.getCurrentMouseButton();
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
    * Get the index the mouse is pointing at.
    **/
    public function getMouseIndex() {
        return _mouseFocusIndexUI;
    }
    
    /**
    * Determines if a dimension is enabled.
    **/
    public function isEnabled(index:DimIndex) {
        return _gctx.isEnabled(index);
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
                    if (dim == _mouseIsOver) {
                        actualIndex = dim;
                        break;
                    }
                }
            }
        }

        if (actualIndex < 0 || actualIndex > _gctx.dimensions.length - 1) {
            return false;
        }

        var result = _mouseIsOver == actualIndex && _gctx.queries[actualIndex].type != QUERY_STATIC;
        if (result) {
            var parentIndex = _gctx.dimensionLinks[actualIndex];
            if (parentIndex > -1 && !partOfGroup) {
                var activity = new Activity();
                activity.type = ACTIVITY_MOUSE_OVER;

                activity.data.push(GlobalEvents.getMousePosition());
                var parentDim = _gctx.getClientDimensionsAtIndex(Direct(parentIndex))[0];
                activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - parentDim.x, GlobalEvents.getMousePosition().y - parentDim.y));

                _gctx.activities[parentIndex].push(activity);
            }

            switch (index) {
                case Group(item): {
                    if (!allGroup) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_OVER;

                        activity.data.push(GlobalEvents.getMousePosition());
                        var currentDim = _gctx.getClientDimensionsAtIndex(Direct(actualIndex))[0];
                        activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, GlobalEvents.getMousePosition().y - currentDim.y));

                        _gctx.activities[actualIndex].push(activity);
                        return result;
                    }

                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_OVER;

                        activity.data.push(GlobalEvents.getMousePosition());
                        var currentDim = _gctx.getClientDimensionsAtIndex(Direct(child))[0];
                        activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, GlobalEvents.getMousePosition().y - currentDim.y));

                        _gctx.activities[child].push(activity);
                    }
                }
                default: {
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_OVER;

                    activity.data.push(GlobalEvents.getMousePosition());
                    var currentDim = _gctx.getClientDimensionsAtIndex(Direct(actualIndex))[0];
                    activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, GlobalEvents.getMousePosition().y - currentDim.y));

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

                activity.data.push(GlobalEvents.getCurrentMouseButton());
                activity.data.push(GlobalEvents.getMousePosition());
                var parentDim = _gctx.getClientDimensionsAtIndex(Direct(parentIndex))[0];
                activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - parentDim.x, GlobalEvents.getMousePosition().y - parentDim.y));

                _gctx.activities[parentIndex].push(activity);
            }

            switch (index) {
                case Group(item): {
                    if (!allGroup) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_DOWN;

                        activity.data.push(GlobalEvents.getCurrentMouseButton());
                        activity.data.push(GlobalEvents.getMousePosition());
                        var currentDim = _gctx.getClientDimensionsAtIndex(Direct(actualIndex))[0];
                        activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, GlobalEvents.getMousePosition().y - currentDim.y));

                        _gctx.activities[actualIndex].push(activity);
                        return result;
                    }

                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_DOWN;

                        activity.data.push(GlobalEvents.getCurrentMouseButton());
                        activity.data.push(GlobalEvents.getMousePosition());
                        var currentDim = _gctx.getClientDimensionsAtIndex(Direct(child))[0];
                        activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, GlobalEvents.getMousePosition().y - currentDim.y));

                        _gctx.activities[child].push(activity);    
                    }
                }
                default: {
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_DOWN;

                    activity.data.push(GlobalEvents.getMousePosition());
                    var currentDim = _gctx.getClientDimensionsAtIndex(Direct(actualIndex))[0];
                    activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, GlobalEvents.getMousePosition().y - currentDim.y));

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

                activity.data.push(GlobalEvents.getCurrentMouseButton());
                activity.data.push(GlobalEvents.getMousePosition());
                var parentDim = _gctx.getClientDimensionsAtIndex(Direct(parentIndex))[0];
                activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - parentDim.x, GlobalEvents.getMousePosition().y - parentDim.y));

                _gctx.activities[parentIndex].push(activity);
            }

            switch (index) {
                case Group(item): {
                    if (!allGroup) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_CLICKED;

                        activity.data.push(GlobalEvents.getCurrentMouseButton());
                        activity.data.push(GlobalEvents.getMousePosition());
                        var currentDim = _gctx.getClientDimensionsAtIndex(Direct(actualIndex))[0];
                        activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, GlobalEvents.getMousePosition().y - currentDim.y));

                        _gctx.activities[actualIndex].push(activity);
                        return result;
                    }

                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_CLICKED;

                        activity.data.push(GlobalEvents.getCurrentMouseButton());
                        activity.data.push(GlobalEvents.getMousePosition());
                        var currentDim = _gctx.getClientDimensionsAtIndex(Direct(child))[0];
                        activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, GlobalEvents.getMousePosition().y - currentDim.y));

                        _gctx.activities[child].push(activity);    
                    }
                }
                default: {
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_CLICKED;

                    activity.data.push(GlobalEvents.getCurrentMouseButton());
                    activity.data.push(GlobalEvents.getMousePosition());
                    var currentDim = _gctx.getClientDimensionsAtIndex(Direct(actualIndex))[0];
                    activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, GlobalEvents.getMousePosition().y - currentDim.y));

                    _gctx.activities[actualIndex].push(activity);
                }
            }
        }

        return result;
    }

    /**
    * Checks if the mouse has been released outside of the given dimension and all its linked dimensions.
    * This includes checking if the release occurred outside any child dimensions that are linked to the given dimension.
    * 
    * @param index The index of the dimension to check against.
    * @param allGroup (Optional) Specify that all indices in a group receive this event if one returns `true`.
    * @return Returns `true` if the mouse was released this frame and the release position is outside the dimension 
    *         and all its linked children. Returns `false` if no release occurred, or if the release was inside 
    *         the dimension or any of its linked children.
    **/
    public function isMouseReleasedOutside(index:DimIndex, ?allGroup:Bool = false):Bool {
        // No mouse release occurred this frame
        if (_mouseIsReleased == -1) {
            return false;
        }
        
        // Get all indices we need to check against
        var indicesToCheck:Array<Int> = [];
        var partOfGroup = false;
        
        switch (index) {
            case Direct(item): {
                indicesToCheck.push(item);
            }
            case Group(item): {
                partOfGroup = true;
                // For groups, check all dimensions in the group
                var groupIndices = _gctx.getDimIndicesAtGroupIndex(item);
                indicesToCheck = groupIndices.copy();
            }
        }
        
        if (indicesToCheck.length == 0) {
            return false;
        }
        
        // Store original indices for activity tracking
        var originalIndices = indicesToCheck.copy();
        
        // Add all linked children to the check list
        var linkedChildren = _gctx.dimensionLinks.whereIndices((dl) -> {
            // Find all dimensions that are linked to any of our indices to check
            for (idx in indicesToCheck) {
                if (dl == idx) {
                    return true;
                }
            }
            return false;
        });
        
        for (child in linkedChildren) {
            if (indicesToCheck.indexOf(child) == -1) {
                indicesToCheck.push(child);
            }
        }
        
        // Also check if any of our indices are children of another dimension
        for (idx in indicesToCheck.copy()) {
            var parentIndex = _gctx.dimensionLinks[idx];
            if (parentIndex > -1 && indicesToCheck.indexOf(parentIndex) == -1) {
                indicesToCheck.push(parentIndex);
            }
        }
        
        // Check if the mouse release was on any of our related dimensions
        // _mouseIsReleased contains the index that received the release event
        // If it matches any of our indices, the release was inside, not outside
        for (idx in indicesToCheck) {
            if (_mouseIsReleased == idx) {
                return false;
            }
        }
        
        // Mouse was released outside - add activities
        var result = true;
        
        if (result) {
            // Check if original index has a parent that should also receive the event
            var firstOriginal = originalIndices[0];
            var parentIndex = _gctx.dimensionLinks[firstOriginal];
            if (parentIndex > -1 && !partOfGroup) {
                var activity = new Activity();
                activity.type = ACTIVITY_MOUSE_CLICKED_OUT;
                
                activity.data.push(_mouseButtons);
                activity.data.push(GlobalEvents.getMousePosition());
                var parentDim = _gctx.getClientDimensionsAtIndex(Direct(parentIndex))[0];
                activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - parentDim.x, 
                                                GlobalEvents.getMousePosition().y - parentDim.y));
                
                _gctx.activities[parentIndex].push(activity);
            }
            
            switch (index) {
                case Group(item): {
                    if (!allGroup) {
                        // Only add activity to the first index in the group
                        var activity = new Activity();
                        activity.type = ACTIVITY_MOUSE_CLICKED_OUT;
                        
                        activity.data.push(_mouseButtons);
                        activity.data.push(GlobalEvents.getMousePosition());
                        var currentDim = _gctx.getClientDimensionsAtIndex(Direct(originalIndices[0]))[0];
                        activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, 
                                                        GlobalEvents.getMousePosition().y - currentDim.y));
                        
                        _gctx.activities[originalIndices[0]].push(activity);
                    }
                    else {
                        // Add activity to all indices in the group
                        for (child in originalIndices) {
                            var activity = new Activity();
                            activity.type = ACTIVITY_MOUSE_CLICKED_OUT;
                            
                            activity.data.push(_mouseButtons);
                            activity.data.push(GlobalEvents.getMousePosition());
                            var currentDim = _gctx.getClientDimensionsAtIndex(Direct(child))[0];
                            activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, 
                                                            GlobalEvents.getMousePosition().y - currentDim.y));
                            
                            _gctx.activities[child].push(activity);
                        }
                    }
                }
                default: {
                    // Direct index case
                    var activity = new Activity();
                    activity.type = ACTIVITY_MOUSE_CLICKED_OUT;
                    
                    activity.data.push(_mouseButtons);
                    activity.data.push(GlobalEvents.getMousePosition());
                    var currentDim = _gctx.getClientDimensionsAtIndex(Direct(originalIndices[0]))[0];
                    activity.data.push(new FastVector2(GlobalEvents.getMousePosition().x - currentDim.x, 
                                                    GlobalEvents.getMousePosition().y - currentDim.y));
                    
                    _gctx.activities[originalIndices[0]].push(activity);
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
                for (key in _keysUp) {
                    activity.data.push(key);
                }
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
                    for (key in _keysUp) {
                        activity.data.push(key);
                    }
                    _gctx.activities[item].push(activity);
                }
                case Group(item): {
                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_KEY_UP;
                        for (key in _keysUp) {
                            activity.data.push(key);
                        }
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
                for (key in _keysDown) {
                    activity.data.push(key);
                }
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
                    for (key in _keysDown) {
                        activity.data.push(key);
                    }
                    _gctx.activities[item].push(activity);
                }
                case Group(item): {
                    for (child in _gctx.getDimIndicesAtGroupIndex(item)) {
                        var activity = new Activity();
                        activity.type = ACTIVITY_KEY_DOWN;
                        for (key in _keysDown) {
                            activity.data.push(key);
                        }
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
    * Toggle visibility of the given `target` dimension reference based on whether the given
    * `on` dimension reference is receiving an event.
    *
    * @param on The dim reference to check.
    * @param target The target dim reference to toggle if `on` receives an event.
    * @param activity The activity type referring to the user input event to check.
    **/
    public function toggleVisibilityOn(on:DimIndex, target:DimIndex, activity:ActivityType) {
        var actualIndex = switch (on) {
            case Direct(index): index;
            case Group(index): @:privateAccess(GraphicsContext) { _gctx._groups[index][0]; };
        };

        var result = hasActivityData(actualIndex, activity);
        if (result) {
            if (!_toggles.exists(on)) {
                _toggles[on] = true;
            }
            else {
                _toggles[on] = !_toggles[on];
            }
        }

        switch (target) {
            case Direct(index): {
                _gctx.dimensions[index].visible = _toggles[on];
            }
            case Group(index): {
                var dims = _gctx.getDimIndicesAtGroupIndex(index);
                for (d in dims) {
                    _gctx.dimensions[d].visible = _toggles[on];
                }
            }
        }
    }

    /**
    * Toggle the visibility of a dimension reference.
    *
    * @param target The target dim reference to toggle.
    **/
    public function toggleVisibility(target:DimIndex) {
        switch (target) {
            case Direct(index): {
                _gctx.dimensions[index].visible = !_gctx.dimensions[index].visible;
            }
            case Group(index): {
                var dims = _gctx.getDimIndicesAtGroupIndex(index);
                for (d in dims) {
                    _gctx.dimensions[d].visible = !_gctx.dimensions[d].visible;
                }
            }
        }
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
    * @return Returns `true` if the data matches, `false` otherwise. Returns `true` if there is no data to match but the activity type exists.
    **/
    public function hasActivityData(index:Null<Int>, type:ActivityType, data:...Dynamic) {
        if (index == null) {
            return false;
        }

        if (!_gctx.isDimIndexValid(Direct(index))) {
            return false;
        }

        var array = getActivity(index, type);
        if (array == null) {
            return false;
        }

        if (array.length == 0 && data.length == 0) {
            return true;
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
                dimAlign(Direct(menu.indices[menu.cursorIndex]), Direct(menu.cursorIndex), VALIGN_CENTRE, HALIGN_LEFT);
                submitGameEventById(GameEvent.SetDimPosition, [ temp ]);
            }
        }
    }

    /**
    * End event context and complete the final simulations.
    **/
    public function end() {
        _eventDispatcher.dispatch(this);

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
    * Submit an event of a given type by ID, with optional data. When adding to a timeline,
    * no duration is given to the generated event node. For a more robust solution for timeline
    * events, use `submitGameEventToTimeline`.
    *
    * @param id The unique ID of the game event.
    * @param type The game event processing type.
    * @param data Any extra data to submit with the game event.
    * @param timelineId If adding to a timeline, this is the given timeline Id to add this game event to.
    **/
    public function submitGameEventById(id:Id, ?type:GameEventProcessingType, ?data:Array<Dynamic> = null, ?timelineId:Id) {
        if (type == null) {
            type = Sequential;
        }

        var event = new GameEvent();
        event.id = id;
        event.data = data;
        if (type == Sequential) {
            _eventProcessor.sequentialEvents.push(event);
        }
        else {
            var indices = _eventProcessor.timelineEvents.whereIndices((t) -> t.id == timelineId);
            if (indices.length > 0) {
                var node = new GameEventTimeNode(event);
                node.duration = Seconds(0.0);
                _eventProcessor.timelineEvents[indices[0]].addNode(node);
            }
        }
    }

    /**
    * Submit a game event to the given timeline ID. Specify an optional `duration` for the underlying event if this event is expected
    * to perform a frame-by-frame motion. For all other options, pass a callback to `optionsCallback`, which gives the newly created
    * `GameEventTimeNode` that you can use to modify its behaviour. Make sure to return the event back to the function to ensure
    * any changes are correctly stored.
    *
    * @param event The constructed game event. Can be a custom game event derived from `GameEvent`.
    * @param timelineId The ID of the timeline to pass the event to.
    * @param duration (Optional) The length of time (in seconds) that the event is expected to run for.
    * @param optionsCallback (Optional) A callback used to modify the created `GameEventTimeNode`.
    **/
    public function submitGameEventToTimeline(event:GameEvent, timelineId:Id, ?duration:Duration, ?optionsCallback:(GameEventTimeNode) -> GameEventTimeNode) {
        if (duration == null) {
            duration = Seconds(0.0);
        }

        var indices = _eventProcessor.timelineEvents.whereIndices((t) -> t.id == timelineId);
        if (indices.length == 0) {
            return;
        }

        var node = new GameEventTimeNode(event);
        node.duration = duration;
        if (optionsCallback != null) {
            node = optionsCallback(node);
        }

        _eventProcessor.timelineEvents[indices[0]].addNode(node);
    }

    /**
    * Add an event timeline to the underlying event processor. The event timeline must have a valid `id`.
    *
    * @param timeline The timeline to add.
    **/
    public function addEventTimeline(timeline:GameEventTimeline) {
        if (timeline.id == Id.None || timeline.id == cast -1) {
            return;
        }

        _eventProcessor.timelineEvents.push(timeline);
        _eventProcessor.lastEvents.push(null);
    }

    /**
    * Allow for checking game events, iterating over each and filtering on the ones
    * cared about, automating the ones that are used by Twinspire.
    *
    * This function is typically used at the end of the loop.
    *
    * @param callback The callback function to execute for any custom game events.
    **/
    public function onEvent(callback:(GameEvent) -> Void) {
        if (callback == null)
            return;

        if (!_eventProcessor.hasEvents()) {
            return;
        }

        var handled = _eventProcessor.processEvents();
        for (e in handled) {
            if (e.type == Sequential) {
                if (!e.callback()) {
                    callback(_eventProcessor.sequentialEvents[e.index]);
                }
            }
            else if (e.type == Timeline) {
                if (!e.callback()) {
                    callback(_eventProcessor.getLastEvent(e.index));
                }
            }
        }
    }
}