package twinspire.render;

import kha.System;
import twinspire.maps.Tile;
import twinspire.maps.TileMap;
import twinspire.maps.TileMapLayer;
import kha.math.FastMatrix3;
import kha.math.Matrix3;
import twinspire.DimIndex;
import twinspire.geom.Dim;
import twinspire.render.particles.Engine;
import twinspire.render.vector.VectorSpace;
import twinspire.render.UpdateContext;
import twinspire.render.QueryType;
import twinspire.render.RenderQuery;
import twinspire.text.InputRenderer;
import twinspire.text.TextInputState;
import twinspire.text.TextInputMethod;
import twinspire.Application;
import twinspire.Dimensions;
using twinspire.extensions.ArrayExtensions;
using twinspire.extensions.Graphics2;

import kha.graphics2.Graphics;
import kha.math.FastVector2;
import kha.math.Vector2;
import kha.Image;
import kha.Color;
import kha.Font;
import kha.Video;

typedef TextInputResult = {
    > ContainerResult,
    var textInputIndex:Int;
}

typedef DimensionRecord = {
    var dim:Dim;
}

typedef DimensionCallback = (DimIndex) -> Void;

typedef ContainerResult = {
    var index:DimIndex;
    var ?space:VectorSpace;
    var containerIndex:Int;
}

typedef ContainerContext = {
    var container:ContainerResult;
    var childrenThisFrame:Array<DimIndex>;
}

@:allow(Application)
@:allow(UpdateContext)
class GraphicsContext {

    private var _inRenderContext:Bool;
    private var _dimTemp:Array<Dim>;
    private var _dimTempLinkTo:Array<Int>;
    private var _dimForceChangeIndices:Array<Int>;
    private var _containerTemp:Array<Container>;
    private var _ended:Bool;
    private var _menus:Array<Menu>;
    private var _currentMenu:Int;
    private var _activeMenu:Int;

    private var _containerOffsetsChanged:Bool;
    private var _containerLastOffsets:Array<FastVector2>;

    private var _vectorSpaces:Array<VectorSpace>;
    private var _activeContainers:Array<ContainerResult>;
    private var _containerStack:Array<ContainerResult>; // For nested containers

    private var _buffers:Array<Image>;
    private var _bufferDimensionIndices:Array<Array<Int>>;
    private var _currentBuffer:Int;

    private var _groups:Array<Array<Int>>;
    private var _currentGroup:Int;
    private var _currentGroupRenderType:Id;

    private var _activeDimensions:Array<Bool>;

    private var _dormantDimIndices:Array<Int>;
    private var _dormantGroups:Array<Int>;

    private var _cameras:Array<Camera>;

    private var _dimRecordsTemp:Array<DimensionRecord>;
    private var _dimRecords:Array<DimensionRecord>;

    private var _animations:Map<DimIndex, AnimationState>;

    private var _dimensionCallbacks:Map<Int, DimensionCallback>;
    private var _callbackOrder:Array<Int>;

    /**
    * A collection of dimensions within this context. Do not write directly.
    **/
    public var dimensions:Array<Dim>;
    /**
    * A collection of dimension links within this context. Do not write directly.
    **/
    public var dimensionLinks:Array<Int>;
    /**
    * A collection of containers referring to the grouping of dimensions within this context. Do not write directly.
    **/
    public var containers:Array<Container>;
    /**
    * A collection of render queries. Do not write directly.
    **/
    public var queries:Array<RenderQuery>;
    /**
    * A collection of activities. Do not write directly.
    **/
    public var activities:Array<Array<Activity>>;
    /**
    * A collection of text input states. Do not write directly.
    **/
    public var textInputs:Array<TextInputState>;
    /**
    * Defines how the `end()` call works with permanent storage. See `end()` for more info.
    **/
    public var noVirtualSceneChange:Bool;
    /**
    * Supply an Id for defining what should be rendered when a menu is activated and a cursor
    * should indicate the position in the menu. If `null`, nothing will be rendered.
    **/
    public var menuCursorRenderId:Null<Id>;
    /**
    * This is an optional tracking module that allows tracking the render, update and logical
    * states of objects referred to by a `DimIndex`. It is important to set `useTracker` to `true`
    * before using and operating on this variable. Ensure this is set at initialisation,
    * before the application starts.
    **/
    public var tracker:Map<DimIndex, TrackingObject>;
    /**
    * Specifies that the `GraphicsContext` tracker is used to automatically add references
    * to newly created dimensions.
    **/
    public var useTracker:Bool;

    private var _g2:Graphics;

    public function new() {
        _dimTemp = [];
        _dimTempLinkTo = [];
        _dimForceChangeIndices = [];
        _activeDimensions = [];
        _containerTemp = [];
        _dormantDimIndices = [];
        _dormantGroups = [];
        _dimRecordsTemp = [];
        _dimRecords = [];
        _cameras = [];
        _ended = false;
        _currentMenu = -1;
        _containerOffsetsChanged = false;
        _containerLastOffsets = [];
        _vectorSpaces = [];
        _activeContainers = [];
        _containerStack = [];
        _buffers = [];
        _bufferDimensionIndices = [];
        _currentBuffer = -1;
        _groups = [];
        _currentGroup = -1;
        _currentGroupRenderType = null;
        _animations = [];
        _dimensionCallbacks = [];
        _callbackOrder = [];

        containers = [];
        dimensions = [];
        dimensionLinks = [];
        queries = [];
        activities = [];
        textInputs = [];

        transforms = [];
    }

    /**
    * Internal method to get the appropriate graphics context (buffer or main).
    **/
    private function getGraphics():Graphics {
        if (_currentBuffer > -1 && _currentBuffer < _buffers.length) {
            return _buffers[_currentBuffer].g2;
        }
        else {
            return _g2;
        }
    }

    /**
    * Get current graphics context for advanced operations.
    * Use sparingly - prefer the wrapper methods.
    **/
    public function getCurrentGraphics():Graphics {
        return getGraphics();
    }


    /**
    * Gets one or more queries that is referred to by the given `DimIndex`.
    *
    * @param index The `DimIndex` reference.
    **/
    public function getQueries(index:DimIndex) {
        switch (index) {
            case Direct(item): {
                return [ queries[item] ];
            }
            case Group(item): {
                return _groups[item].map((grp) -> queries[grp]);
            }
        }
    }

    /**
    * Gets one or more activities that is referred to by the given `DimIndex`.
    *
    * @param index The `DimIndex` reference.
    **/
    public function getActivities(index:DimIndex) {
        switch (index) {
            case Direct(item): {
                return [ activities[item] ];
            }
            case Group(item): {
                return _groups[item].map((grp) -> activities[grp]);
            }
        }
    }

    /**
    * Register a callback for recalculating a dimension on resize.
    * Callbacks are executed in the order they were registered.
    */
    public function useDimension(index:DimIndex, callback:DimensionCallback):Void {
        var directIndex = switch (index) {
            case Direct(i, _): i;
            case Group(i, _): i; // For groups, use the group index
        };
        
        _dimensionCallbacks.set(directIndex, callback);
        
        // Maintain order for dependency management
        if (!_callbackOrder.contains(directIndex)) {
            _callbackOrder.push(directIndex);
        }
    }

    /**
    * Remove a dimension callback.
    */
    public function removeDimensionCallback(index:DimIndex):Void {
        var directIndex = switch (index) {
            case Direct(i, _): i;
            case Group(i, _): i;
        };
        
        _dimensionCallbacks.remove(directIndex);
        _callbackOrder.remove(directIndex);
    }

    /**
    * Recalculate all dimensions using user-defined callbacks.
    */
    public function recalculateDimensions():Void {
        Dimensions.beginEdit();
        
        // Execute callbacks in registration order
        for (index in _callbackOrder) {
            var callback = _dimensionCallbacks.get(index);
            if (callback != null) {
                var dimIndex = Direct(index);
                try {
                    callback(dimIndex);
                } catch (e:Dynamic) {
                    trace('Error in dimension callback for index $index: $e');
                }
            }
        }
        
        Dimensions.endEdit();
    }
    
    /**
    * Clear all dimension callbacks. Useful for scene changes.
    */
    public function clearDimensionCallbacks():Void {
        _dimensionCallbacks.clear();
        _callbackOrder = [];
    }

    /**
    * Advance the order of a dimension or group of dimensions by a specified amount.
    *
    * @param index The `DimIndex` to advance.
    * @param amount The amount to advance the order by.
    **/
    public function advanceOrderOf(index:DimIndex, amount:Int) {
        switch (index) {
            case Direct(i): {
                if (i < _dimRecords.length) {
                    _dimRecords[i].dim.order += amount;
                }
                else {
                    _dimRecordsTemp[i].dim.order += amount;
                }
            }
            case Group(g): {
                if (g < _groups.length) {
                    for (item in _groups[g]) {
                        if (item < _dimRecords.length) {
                            _dimRecords[item].dim.order += amount;
                        }
                        else {
                            _dimRecordsTemp[item].dim.order += amount;
                        }
                    }
                }
            }
        }
    }

    /**
    * Advance the order of a collection of dimensions or groups by a specified amount.
    *
    * @param indices An array of `DimIndex` to advance.
    * @param amount The amount to advance the order by.
    **/
    public function advanceOrderOfCollection(indices:Array<DimIndex>, amount:Int) {
        for (index in indices) {
            advanceOrderOf(index, amount);
        }
    }

    /**
    * Make a dimension or group of dimensions invisible.
    *
    * @param index The `DimIndex` to make invisible.
    **/
    public function makeInvisible(index:DimIndex) {
        switch (index) {
            case Direct(i): {
                if (i < _dimRecords.length) {
                    _dimRecords[i].dim.visible = false;
                }
                else {
                    _dimRecordsTemp[i].dim.visible = false;
                }
            }
            case Group(g): {
                if (g < _groups.length) {
                    for (item in _groups[g]) {
                        if (item < _dimRecords.length) {
                            _dimRecords[item].dim.visible = false;
                        }
                        else {
                            _dimRecordsTemp[item].dim.visible = false;
                        }
                    }
                }
            }
        }
    }
    
    /**
    * Make a dimension or group of dimensions visible.
    *
    * @param index The `DimIndex` to make visible.
    **/
    public function makeVisible(index:DimIndex) {
        switch (index) {
            case Direct(i): {
                if (i < _dimRecords.length) {
                    _dimRecords[i].dim.visible = true;
                }
                else {
                    _dimRecordsTemp[i].dim.visible = true;
                }
            }
            case Group(g): {
                if (g < _groups.length) {
                    for (item in _groups[g]) {
                        if (item < _dimRecords.length) {
                            _dimRecords[item].dim.visible = true;
                        }
                        else {
                            _dimRecordsTemp[item].dim.visible = true;
                        }
                    }
                }
            }
        }
    }

    /**
    * Make a collection of dimensions or groups invisible.
    *
    * @param indices An array of `DimIndex` to make invisible.
    **/
    public function makeInvisibleCollection(indices:Array<DimIndex>) {
        for (index in indices) {
            makeInvisible(index);
        }
    }

    /**
    * Make a collection of dimensions or groups visible.
    *
    * @param indices An array of `DimIndex` to make visible.
    **/
    public function makeVisibleCollection(indices:Array<DimIndex>) {
        for (index in indices) {
            makeVisible(index);
        }
    }

    /**
    * Move a dimension or group of dimensions towards a target position at a specified speed.
    *
    * @param index The `DimIndex` to move.
    * @param target The target position to move towards.
    * @param speed The speed at which to move towards the target position, typically a value between 0 and 1.
    **/
    public function moveDimIndexTowards(index:DimIndex, target:FastVector2, speed:Float) {
        switch (index) {
            case Direct(i): {
                if (i < _dimRecords.length) {
                    var dim = _dimRecords[i].dim;
                    dim.x += (target.x - dim.x) * speed;
                    dim.y += (target.y - dim.y) * speed;
                }
                else {
                    var dim = _dimRecordsTemp[i].dim;
                    dim.x += (target.x - dim.x) * speed;
                    dim.y += (target.y - dim.y) * speed;
                }
            }
            case Group(g): {
                if (g < _groups.length) {
                    for (item in _groups[g]) {
                        if (item < _dimRecords.length) {
                            var dim = _dimRecords[item].dim;
                            dim.x += (target.x - dim.x) * speed;
                            dim.y += (target.y - dim.y) * speed;
                        }
                        else {
                            var dim = _dimRecordsTemp[item].dim;
                            dim.x += (target.x - dim.x) * speed;
                            dim.y += (target.y - dim.y) * speed;
                        }
                    }
                }
            }
        }
    }

    /**
    * Move a collection of dimensions or groups towards a target position at a specified speed.
    *
    * @param indices An array of `DimIndex` to move.
    * @param target The target position to move towards.
    * @param speed The speed at which to move towards the target position, typically a value between 0 and 1.
    **/
    public function moveDimIndexTowardsCollection(indices:Array<DimIndex>, target:FastVector2, speed:Float) {
        for (index in indices) {
            moveDimIndexTowards(index, target, speed);
        }
    }

    /**
    * Move a dimension or group of dimensions towards a target position at a specified speed and radius.
    *
    * @param index The `DimIndex` to move.
    * @param target The target position to move towards.
    * @param speed The speed at which to move towards the target position, typically a value between 0 and 1.
    * @param radius The radius to apply to the movement, affecting how far the dimension moves towards the target.
    **/
    public function moveDimIndexTowardsArch(index:DimIndex, target:FastVector2, speed:Float, radius:Float) {
        switch (index) {
            case Direct(i): {
                if (i < _dimRecords.length) {
                    var dim = _dimRecords[i].dim;
                    var angle = Math.atan2(target.y - dim.y, target.x - dim.x);
                    dim.x += Math.cos(angle) * speed * radius;
                    dim.y += Math.sin(angle) * speed * radius;
                }
                else {
                    var dim = _dimRecordsTemp[i].dim;
                    var angle = Math.atan2(target.y - dim.y, target.x - dim.x);
                    dim.x += Math.cos(angle) * speed * radius;
                    dim.y += Math.sin(angle) * speed * radius;
                }
            }
            case Group(g): {
                if (g < _groups.length) {
                    for (item in _groups[g]) {
                        if (item < _dimRecords.length) {
                            var dim = _dimRecords[item].dim;
                            var angle = Math.atan2(target.y - dim.y, target.x - dim.x);
                            dim.x += Math.cos(angle) * speed * radius;
                            dim.y += Math.sin(angle) * speed * radius;
                        }
                        else {
                            var dim = _dimRecordsTemp[item].dim;
                            var angle = Math.atan2(target.y - dim.y, target.x - dim.x);
                            dim.x += Math.cos(angle) * speed * radius;
                            dim.y += Math.sin(angle) * speed * radius;
                        }
                    }
                }
            }
        }
    }

    /**
    * Move a collection of dimensions or groups towards a target position at a specified speed and radius.
    *
    * @param indices An array of `DimIndex` to move.
    * @param target The target position to move towards.
    * @param speed The speed at which to move towards the target position, typically a value between 0 and 1.
    * @param radius The radius to apply to the movement, affecting how far the dimensions move towards the target.
    **/
    public function moveDimIndexTowardsArchCollection(indices:Array<DimIndex>, target:FastVector2, speed:Float, radius:Float) {
        for (index in indices) {
            moveDimIndexTowardsArch(index, target, speed, radius);
        }
    }

    /**
    * Move a dimension or group of dimensions towards a target position using a bezier curve with a control point.
    *
    * @param index The `DimIndex` to move.
    * @param target The target position to move towards.
    * @param speed The speed at which to move towards the target position, typically a value between 0 and 1.
    * @param controlPoint The control point for the bezier curve, affecting the curvature of the movement.
    **/
    public function moveDimIndexTowardsBezier(index:DimIndex, target:FastVector2, speed:Float, controlPoint:FastVector2) {
        switch (index) {
            case Direct(i): {
                if (i < _dimRecords.length) {
                    var dim = _dimRecords[i].dim;
                    var t = speed; // Assuming speed is a value between 0 and 1
                    dim.x = (1 - t) * (1 - t) * dim.x + 2 * (1 - t) * t * controlPoint.x + t * t * target.x;
                    dim.y = (1 - t) * (1 - t) * dim.y + 2 * (1 - t) * t * controlPoint.y + t * t * target.y;
                }
                else {
                    var dim = _dimRecordsTemp[i].dim;
                    var t = speed; // Assuming speed is a value between 0 and 1
                    dim.x = (1 - t) * (1 - t) * dim.x + 2 * (1 - t) * t * controlPoint.x + t * t * target.x;
                    dim.y = (1 - t) * (1 - t) * dim.y + 2 * (1 - t) * t * controlPoint.y + t * t * target.y;
                }
            }
            case Group(g): {
                if (g < _groups.length) {
                    for (item in _groups[g]) {
                        if (item < _dimRecords.length) {
                            var dim = _dimRecords[item].dim;
                            var t = speed; // Assuming speed is a value between 0 and 1
                            dim.x = (1 - t) * (1 - t) * dim.x + 2 * (1 - t) * t * controlPoint.x + t * t * target.x;
                            dim.y = (1 - t) * (1 - t) * dim.y + 2 * (1 - t) * t * controlPoint.y + t * t * target.y;
                        }
                        else {
                            var dim = _dimRecordsTemp[item].dim;
                            var t = speed; // Assuming speed is a value between 0 and 1
                            dim.x = (1 - t) * (1 - t) * dim.x + 2 * (1 - t) * t * controlPoint.x + t * t * target.x;
                            dim.y = (1 - t) * (1 - t) * dim.y + 2 * (1 - t) * t * controlPoint.y + t * t * target.y;
                        }
                    }
                }
            }
        }
    }

    /**
    * Move a collection of dimensions or groups towards a target position using a bezier curve with a control point.
    *
    * @param indices An array of `DimIndex` to move.
    * @param target The target position to move towards.
    * @param speed The speed at which to move towards the target position, typically a value between 0 and 1.
    * @param controlPoint The control point for the bezier curve, affecting the curvature of the movement.
    **/
    public function moveDimIndexTowardsBezierCollection(indices:Array<DimIndex>, target:FastVector2, speed:Float, controlPoint:FastVector2) {
        for (index in indices) {
            moveDimIndexTowardsBezier(index, target, speed, controlPoint);
        }
    }

    /**
    * Specify a new manually adjusted dimension for the given index.
    **/
    public function overrideDimension(index:DimIndex, dim:Dim) {
        switch (index) {
            case Direct(i): {
                if (i < _dimRecords.length) {
                    _dimRecords[i].dim.width = dim.width;
                    _dimRecords[i].dim.height = dim.height;
                    _dimRecords[i].dim.x = dim.x;
                    _dimRecords[i].dim.y = dim.y;
                }
                else {
                    _dimRecordsTemp[i].dim.width = dim.width;
                    _dimRecordsTemp[i].dim.height = dim.height;
                    _dimRecordsTemp[i].dim.x = dim.x;
                    _dimRecordsTemp[i].dim.y = dim.y;
                }
            }
            case Group(g): {
                if (g < _groups.length) {
                    for (item in _groups[g]) {
                        if (item < _dimRecords.length) {
                            _dimRecords[item].dim.width = dim.width;
                            _dimRecords[item].dim.height = dim.height;
                            _dimRecords[item].dim.x = dim.x;
                            _dimRecords[item].dim.y = dim.y;
                        }
                        else {
                            _dimRecordsTemp[item].dim.width = dim.width;
                            _dimRecordsTemp[item].dim.height = dim.height;
                            _dimRecordsTemp[item].dim.x = dim.x;
                            _dimRecordsTemp[item].dim.y = dim.y;
                        }
                    }
                }
            }
        }
    }

    /**
    * Create a continuous animation for the given index. Transforms are applied prior to rendering
    * and updated each frame automatically.
    *
    * Use this for static or UI render types. For complex animations or sprite-related animations, use Game Events.
    *
    * @param index The index of the animation.
    * @param speed The speed of the animation based on frame rate.
    * @param anim The animation object representing how the animation should transform. Only `transform` and `rotation` applies for continuous animations.
    **/
    public function createAnimationContinuous(index:DimIndex, speed:Float, anim:AnimObject) {
        if (_animations.exists(index)) {
            _animations[index] = null;
        }

        var state = new AnimationState();
        state.current = {};
        state.to = anim;
        state.time = Frames(speed);

        _animations[index] = state;
    }

    /**
    * Create a tween animation going from one state to another for the given index.
    *
    * Use this for static or UI render types. For complex animations or sprite-related animations, use Game Events.
    *
    * @param index The index of the animation.
    * @param duration The time (in seconds) for this animation to complete.
    * @param from The state from.
    * @param to The completion state.
    **/
    public function createAnimationTween(index:DimIndex, duration:Float, from:AnimObject, to:AnimObject) {
        if (_animations.exists(index)) {
            _animations[index] = null;
        }

        var state = new AnimationState();
        state.current = from;
        state.from = from;
        state.to = to;
        state.time = Seconds(duration);
        state.index = Animate.animateCreateTick();

        _animations[index] = state;
    }

    /**
    * Specifies the camera to use for observing dimensions.
    **/
    public function beginCamera(camera:Camera) {

    }

    /**
    * Stop using the current camera. This function determines what indices are observable
    * while the camera is idle, and filtering on dimensions close enough to the camera's
    * observation of the dimension stack. Note that camera observation only applies to
    * queries of type `STATIC` and `SPRITE`. `UI` type dimensions are ignored.
    *
    * To obtain the list of observed dimensions, use `getCameraObserved`.
    **/
    public function endCamera() {

    }

    /**
    * Retrieve an array of all currently observed DimIndices. If a `DimIndex` completely
    * overlaps the referenced dimension of another, the final `DimIndex` is the one rendered
    * first.
    **/
    public function getCameraObserved():Array<DimIndex> {
        return [];
    }

    /**
    * Returns the dimension in temporary storage in the current frame at the index
    * it would be once added into permanent storage.
    *
    * @param index The position of the dimension when it is added into permanent storage.
    **/
    public function getTemporaryDimAtNewIndex(index:Int):Dim {
        var resolvedIndex = index - _dimRecords.length;
        return _dimRecordsTemp[resolvedIndex].dim;
    }

    /**
    * Returns the current or temporary dimension.
    *
    * @param index The position of the dimension.
    **/
    public function getTempOrCurrentDimAtIndex(index:Int):Dim {
        if (index > _dimRecords.length - 1) {
            return getTemporaryDimAtNewIndex(index);
        }
        else {
            return _dimRecords[index].dim;
        }
    }

    /**
    * Create a buffer to the given width and height.
    *
    * @return Returns a buffer index.
    **/
    public function createBuffer(width:Int, height:Int) {
        _bufferDimensionIndices.push([]);
        return _buffers.push(Image.createRenderTarget(width, height)) - 1;
    }

    /**
    * Begin using a buffer to render to. Anything rendered to this buffer is not
    * considered rendered until `endBuffer` is called.
    *
    * If you create dimensions within this buffer, use `getDimensionAtIndex` or
    * `getDimensionRelativeAtIndex` to get the logical or relative position of a dimension
    * within the buffer.
    *
    * Every time you refer to a dimension within this buffer, always call this function
    * prior to any rendering or events taking place.
    *
    * @param index The index of the buffer.
    **/
    public function beginBuffer(index:Int) {
        _currentBuffer = index;
    }

    /**
    * End the current buffer and return it.
    **/
    public function endBuffer():Image {
        if (_inRenderContext) {
            var bufferContainerIndex = containers.findIndex((c) -> c.bufferIndex == _currentBuffer);
            var container = containers[bufferContainerIndex];
            
            for (child in container.childIndices) {
                switch (child) {
                    case Direct(index): {
                        _dimRecords[index].dim.scale = container.zoom;
                    }
                    case Group(index): {
                        for (item in _groups[index]) {
                            _dimRecords[item].dim.scale = container.zoom;
                        }
                    }
                }
            }
        }

        if (_currentBuffer > -1 && _currentBuffer < _buffers.length) {
            var temp = _currentBuffer;
            _currentBuffer = -1;
            return _buffers[temp];
        }

        return null;
    }

    private function addDimensionIndexToBuffer(index:Int) {
        if (_currentBuffer > -1) {
            var arr = _bufferDimensionIndices[_currentBuffer].filter((i) -> i == index);
            if (arr.length == 0) {
                _bufferDimensionIndices[_currentBuffer].push(index);
            }
        }
    }

    /**
    * Begin a new group of dimensions. This function is a convenience for manipulating groups of
    * dimensions at once. To refer to an existing group, specify the index.
    *
    * @param index (Optional) Specify the group index you wish to use. 
    * @param renderType (Optional) Specify if this group should be referenced to a specific render type.
    **/
    public function beginGroup(?index:Int = -1, ?renderType:Id = null) {
        if (_currentGroup > -1) {
            throw "You cannot create a group within a group. End the current group before starting a new one.";
        }

        if (index > -1) {
            if (index < _groups.length) {
                _currentGroup = index;
            }
            else {
                // log error
            }

            return;
        }

        var temp = _groups.length;
        if (_dormantGroups.length > 0) {
            temp = _dormantGroups.shift();
        }
        else {
            _groups.push([]);
        }

        _currentGroup = temp;
        _currentGroupRenderType = renderType;
    }

    /**
    * Add a `DimIndex` or integer value that is an index itself
    * to the currently active group. Only provide a single argument.
    *
    * If providing an integer value, the value must be within the range
    * of the currently active dimension stack.
    **/
    public function addToGroup(?indexRef:DimIndex, ?indexInt:Int) {
        if (_currentGroup > -1)  {
            if (indexRef != null) {
                var i = switch (indexRef) {
                    case Direct(index): index;
                    default: -1;
                };

                if (i > -1) {
                    _groups[_currentGroup].push(i);
                }
            }
            else if (indexInt != null) {
                if (indexInt < 0 || indexInt > _dimRecords.length) {
                    return;
                }

                _groups[_currentGroup].push(indexInt);
            }
        }
    }

    /**
    * Set the link of a direct index to a specific parent index.
    *
    * @param child The direct index to assign to a parent index.
    * @param parent The parent index to assign the child index to. 
    **/
    public function setupDirectLink(child:DimIndex, parent:DimIndex) {
        switch ([ child, parent ]) {
            case [ Direct(cindex), Direct(pindex) ]: {
                if (cindex > dimensionLinks.length - 1) {
                    _dimTempLinkTo[cindex] = pindex;
                }
                else {
                    dimensionLinks[cindex] = pindex;
                }
            }
            default: {

            }
        }
    }

    /**
    * Set the links of a group to a specific parent index.
    *
    * @param group The group index to assign to a parent index.
    * @param parent The parent index to assign the group indices to. 
    **/
    public function setupGroupLinksToIndex(group:DimIndex, parent:DimIndex) {
        switch (group) {
            case Direct(_): {
                throw "Invalid index reference.";
            }
            case Group(index, _): {
                var children = _groups[index];
                for (child in children) {
                    if (child > dimensionLinks.length - 1) {
                        _dimTempLinkTo[child] = switch(parent) {
                            case Direct(i): i;
                            default: -1;
                        };
                    }
                    else {
                        dimensionLinks[child] = switch(parent) {
                            case Direct(i): i;
                            default: -1;
                        };
                    }
                }
            }
        }
    }

    /**
    * Gets the indices from a `DimIndex`. If you use links to a `Group` index,
    * both the links and the wrapping dimension indices are included, and the
    * wrapping index is likely to always be at zero (depending on your specific
    * order of operations).
    **/
    public function getIndicesFromDimIndex(index:DimIndex) {
        switch (index) {
            case Direct(item): {
                return [ item ];
            }
            case Group(group): {
                return _groups[group];
            }
        }
    }

    /**
    * Gets the last input index in the current group.
    *
    * @return Returns `-1` if no last input index can be found. 
    **/
    public function getLastDimIndexFromGroup() {
        return getLastDimIndexAtGroup(_currentGroup);
    }

    /**
    * Gets the last input index in the given group.
    *
    * @return Returns `-1` if no last input index can be found. 
    **/
    public function getLastDimIndexAtGroup(groupIndex:Int) {
        if (groupIndex > -1 && groupIndex < _groups.length) {
            return _groups[groupIndex][_groups[groupIndex].length - 1];
        }

        return -1;
    }

    /**
    * Gets the dim index from a given index in the current group.
    *
    * @return Returns `-1` if no dim index can be found. 
    **/
    public function getDimIndexFromGroup(index:Int) {
        if (_currentGroup > -1 && _currentGroup < _groups.length) {
            if (index > -1 && index < _groups[_currentGroup].length) {
                return _groups[_currentGroup][index];
            }
        }

        return -1;
    }

    /**
    * Gets the dim indices from the current group.
    *
    * @return Returns an array.
    **/
    public function getDimIndicesFromGroup() {
        return getDimIndicesAtGroupIndex(_currentGroup);
    }

    /**
    * Gets the dim indices from the given group index.
    *
    * @param groupIndex The index of the group.
    * @return Returns an array.
    **/
    public function getDimIndicesAtGroupIndex(groupIndex:Int) {
        if (groupIndex > -1 && groupIndex < _groups.length) {
            return _groups[groupIndex];
        }

        return [];
    }

    /**
    * Gets the `DimIndex` of an integer value reference to the dimension stack,
    * returning `Group` if the index is found in a group, otherwise `Direct`.
    *
    * @param value The dimension index to search for.
    **/
    public function getDimIndexFromInt(value:Int) {
        for (i in 0..._groups.length) {
            for (index in _groups[i]) {
                if (index == value) {
                    return Group(i);
                }
            }
        }

        return Direct(value);
    }

    /**
    * End the current group and return the index of the group.
    **/
    public function endGroup() {
        var temp = _currentGroup;
        _currentGroup = -1;
        return temp;
    }

    private function addDimensionIndexToGroup(index:Int) {
        if (_currentGroup > -1) {
            _groups[_currentGroup].push(index);
        }
    }

    /**
    * Either activate or deactivate a series of dimensions. This function prevents
    * `UpdateContext` from using these dimensions for input simulations.
    *
    * @param indices A collection of indices.
    * @param active Enable or disable.
    **/
    public function activateDimensions(indices:Array<DimIndex>, active:Bool) {
        for (index in indices) {
            switch (index) {
                case Direct(item): {
                    _activeDimensions[item] = active;
                }
                case Group(group): {
                    for (g in _groups[group]) {
                        _activeDimensions[g] = active;
                    }
                }
            }
        }
    }

    /**
    * Gets a value to determine if the given index is valid (i.e., the dimension reference exists in the stack).
    *
    * @param index The dimension index to check.
    **/
    public function isDimIndexValid(index:DimIndex) {
        switch (index) {
            case Direct(item): {
                return item > -1 && item < _dimRecords.length && !_dormantDimIndices.contains(item);
            }
            case Group(group): {
                for (item in _groups[group]) {
                    if (item < 0 || item > _dimRecords.length - 1 || _dormantDimIndices.contains(item)) {
                        return false;
                    }
                }
                return true;
            }
        }
    }

    /**
    * Gets the links of a dimension as indices.
    *
    * @param index The index of the dimension.
    **/
    public function getLinksFromIndex(index:DimIndex):Array<Int> {
        switch (index) {
            case Direct(item): {
                return dimensionLinks.whereIndices((i) -> i == item);
            }
            case Group(item): {
                var results = [];
                for (child in _groups[item]) {
                    var indices = dimensionLinks.whereIndices((i) -> i == child);
                    for (i in indices) {
                        results.push(i);
                    }
                }

                return results;
            }
        }
    }

    /**
    * Get the dimension at the given index. Any offsets assigned to the dimension is resolved
    * before returned. This function is best used for rendering.
    *
    * @param index The index of the dimension
    * @return Returns either a reference to a given dimension, or a copy of a dimension if linked to a container.
    **/
    public function getDimensionsAtIndex(index:DimIndex) {
        var actualIndices = new Array<Int>();
        switch (index) {
            case Direct(item): {
                actualIndices.push(item);
            }
            case Group(item): {
                _groups[item].map((child) -> actualIndices.push(child));
            }
        }

        var results = [];
        for (actual in actualIndices) {
            var containerIndex = -1;
            for (i in 0...containers.length) {
                var c = containers[i];
                if (c.childIndices.contains(index)) {
                    containerIndex = i;
                    break;
                }
            }

            if (containerIndex == -1) {
                results.push(_dimRecords[actual].dim);
            }
            else {
                var c = containers[containerIndex];
                var scale = (c.bufferIndex == -1 ? 1.0 : c.zoom);
                var d = _dimRecords[actual].dim;
                var value = new Dim(d.x + c.offset.x * scale, d.y + c.offset.y * scale, d.width, d.height, d.order);
                value.visible = _dimRecords[actual].dim.visible;
                value.scale = _dimRecords[actual].dim.scale;
                results.push(value);
            }
        }

        return results;
    }

    /**
    * Like `getDimensionsAtIndex`, except the returning dimension is relative to the container it resides.
    * If the dimension does not belong to a container, it returns the exact dimension as is.
    *
    * @param index The index of the dimension as a `DimIndex`.
    **/
    public function getDimensionsRelativeAtIndex(index:DimIndex) {
        var actualIndices = new Array<Int>();

        switch (index) {
            case Direct(item): {
                actualIndices.push(item);
            }
            case Group(item): {
                if (item < _groups.length) {
                    for (child in _groups[item]) {
                        actualIndices.push(child);
                    }
                }
            }
        }

        var results = [];
        for (actual in actualIndices) {
            var containerIndex = -1;
            for (i in 0...containers.length) {
                var c = containers[i];
                if (c.childIndices.contains(index)) {
                    containerIndex = i;
                    break;
                }
            }

            if (containerIndex == -1) {
                results.push(_dimRecords[actual].dim);
            }
            else {
                var c = containers[containerIndex];
                var scale = (c.bufferIndex == -1 ? 1.0 : c.zoom);
                var d = _dimRecords[actual].dim.get();
                var cDim = _dimRecords[c.dimIndex].dim;
                var value = new Dim(d.x - cDim.x + c.offset.x * scale, d.y - cDim.y + c.offset.y * scale, d.width, d.height, d.order);
                value.visible = _dimRecords[actual].dim.visible;
                value.scale = _dimRecords[actual].dim.scale;
                results.push(value); 
            }
        }

        return results;
    }

    /**
    * Gets a dimension at its respective client coordinates after resolving container offsets.
    * Takes into account any multiples of containers.
    *
    * @param index The index as a `DimIndex` of the dimension or group.
    * @return The dimensions as an `Array<Dim>` or an empty array if a group or index is invalid.
    **/
    public function getClientDimensionsAtIndex(index:DimIndex):Array<Dim> {
        switch (index) {
            case Direct(item): {
                if (item < _dimRecords.length) {
                    var record = _dimRecords[item];
                    var baseDim = calculateClientDimension(record);
                    
                    // Apply container transformations
                    var containerDim = applyContainerTransformations(baseDim, item);
                    return [ containerDim ];
                }
            }
            case Group(item): {
                if (item < _groups.length) {
                    var results = new Array<Dim>();
                    for (child in _groups[item]) {
                        if (child < _dimRecords.length) {
                            var record = _dimRecords[child];
                            var baseDim = calculateClientDimension(record);
                            var containerDim = applyContainerTransformations(baseDim, child);
                            results.push(containerDim);
                        }
                    }
                    return results;
                }
            }
        }
        return [ null ];
    }

    /**
    * Calculate the actual screen position/size of a dimension.
    **/
    private function calculateClientDimension(record:DimensionRecord):Dim {
        var dim = record.dim;
        
        if (vectorSpace != null) {
            // Apply vector transformation
            var transformedPos = vectorSpace.transformPoint(dim.x, dim.y);
            var transformedWidth = vectorSpace.transformDistance(dim.width);
            var transformedHeight = vectorSpace.transformDistance(dim.height);
            
            var result = new Dim(transformedPos.x, transformedPos.y, transformedWidth, transformedHeight, dim.order);
            result.visible = dim.visible;
            result.scale = dim.scale;
            return result;
        } else {
            // No transformation needed
            var result = dim.clone();
            return result;
        }
    }

    /**
    * Force a dimension's position to change at a given index.
    *
    * @param index The index of the dimension.
    **/
    public function markDimChange(index:DimIndex) {
        switch (index) {
            case Direct(item): {
                if (!_dimForceChangeIndices.contains(item)) {
                    _dimForceChangeIndices.push(item);
                }
            }
            case Group(item): {
                if (item < _groups.length) {
                    for (child in _groups[item]) {
                        if (!_dimForceChangeIndices.contains(item)) {
                            _dimForceChangeIndices.push(item);
                        }
                    }
                }
            }
        }
    }

    /**
    * Compares two `DimIndex` instances.
    * This function returns `true` if any of the following conditions are met:
    *
    *   - `a` and `b` are `Direct` and have the exact same integer values.
    *   - `a` and `b` are `Group` and have the exact same integer values.
    *   - `a` is a `Group`, and `b` is `Direct`, and the integer value of `b` resides in `a`.
    * 
    * The comparison where `a` is `Direct` and `b` is a `Group` is an incompatible comparison, and returns `false`.
    **/
    public function compareIndex(a:DimIndex, b:DimIndex) {
        if (a == b) {
            return true;
        }
        else {
            switch [a, b] {
                case [ Direct(aResult), Direct(bResult) ]: {
                    return aResult == bResult;
                }
                case [ Direct(_), Group(_) ]: {
                    return false;
                }
                case [ Group(aResult), Direct(bResult) ]: {
                    var children = _groups[aResult];
                    return children.contains(bResult);
                }
                case [ Group(aResult), Group(bResult) ]: {
                    return aResult == bResult;
                }
            }
        }

        return false;
    }

    /**
    * Marks to remove an index from the dimension stack. Instead of physically removing the item,
    * the stack's respective indices are simply set to `null` and allowed to be replaced by other
    * indices when using any of the `add` functions.
    *
    * Any text inputs or containers that are related to any of the indices are physically removed.
    * If you use index referencing for text inputs or containers, it is recommended to refresh these
    * indices.
    *
    * @param index The index `Direct` or `Group` to remove.
    **/
    public function removeIndex(index:DimIndex) {
        var toRemove = new Array<Int>();
        var groupToRemove = -1;
        switch (index) {
            case Direct(i): {
                // ignore if already dormant
                if (_dormantDimIndices.contains(i)) {
                    return;
                }

                toRemove.push(i);
            }
            case Group(i): {
                if (_dormantGroups.contains(i)) {
                    return;
                }

                var children = _groups[i];
                for (child in children) {
                    if (!_dormantDimIndices.contains(child)) {
                        toRemove.push(child);
                    }
                }

                groupToRemove = i;
            }
        }


        // check inputs/containers
        var inputsRemove = new Array<Int>();
        for (i in 0...textInputs.length) {
            var input = textInputs[i];
            for (r in toRemove) {
                if (compareIndex(input.index.index, Direct(r))) {
                    inputsRemove.push(i);
                }
            }
        }

        var inputIndex = inputsRemove.length - 1;
        while (inputIndex > -1) {
            var index = inputsRemove[inputIndex];
            textInputs.splice(index, 1);

            inputIndex -= 1;
        }

        // var containersToRemove = containers.whereIndices((c) -> toRemove.contains(c.dimIndex));

        // for (i in 0...containers.length) {
        //     var container = containers[i];

        //     var found = container.childIndices.whereIndices((di) -> toRemove.contains(DimIndexUtils.getDirectIndex(di)));
        //     for (j in found.length...0) {
        //         container.childIndices.splice(found[j], 1);
        //     }
        // }

        // var containerIndex = containersToRemove.length - 1;
        // while (containerIndex > -1) {
        //     var index = containersToRemove[containerIndex];
        //     containers.splice(index, 1);

        //     containerIndex -= 1;
        // }

        for (g in _groups) {
            var gi = g.whereIndices((item) -> toRemove.contains(item));
            gi.sort((x, y) -> {
                if (x > y) return 1;
                else if (x < y) return -1;
                else return 0;
            });

            for (item in gi) {
                g.splice(item, 1);
            }
        }

        var removeIndex = toRemove.length - 1; 
        while (removeIndex > -1) {
            var index = toRemove[removeIndex];
            _dimRecords[index] = null;
            queries[index] = null;
            activities[index] = null;
            _activeDimensions[index] = false;

            var links = dimensionLinks.whereIndices((l) -> l == index);
            for (l in links) {
                dimensionLinks[l] = -1;
            }

            _dormantDimIndices.push(index);

            removeIndex -= 1;
        }

        if (groupToRemove > -1) {
            _groups[groupToRemove] = null;
            _dormantGroups.push(groupToRemove);
        }
    }

    /**
    * Remove a collection of indices. Uses the same behaviour as `removeIndex`.
    *
    * @param collection The collection of indices to remove from the stack.
    **/
    public function removeIndices(collection:Array<DimIndex>) {
        for (item in collection) {
            removeIndex(item);
        }
    }

    /**
    * Copy a dim index with the given `pos` offset from the original position of all
    * dimensions within this function. This function takes into account possible containers.
    *
    * The result of copying this function is not visible until the next frame.
    *
    * @param dimIndex The dimension index to copy. 
    * @param pos The position the new dimensions are set to.
    *
    * @return Return the references to the dimensions in temporary storage, prior to adding into the next frame. If further
    * action is needed on temporary dimensions, do so before calling `end`.
    **/
    public function copyDimIndexOffset(dimIndex:DimIndex, pos:FastVector2) {
        var dimRefs = new Array<Int>();
        switch (dimIndex) {
            case Direct(index): {
                dimRefs = createClonedDimensionsFromIndex(index);
            }
            case Group(index): {
                for (g in _groups[index]) {
                    var indices = createClonedDimensionsFromIndex(g);
                    dimRefs.concat(indices);
                }
            }
        }

        for (i in dimRefs) {
            _dimTemp[i].x += pos.x;
            _dimTemp[i].y += pos.y;
        }

        return dimRefs;
    }

    private function createClonedDimensionsFromIndex(index:Int) {
        var results = new Array<Int>();
        // check if the given index is associated to a container
        var containerResults = containers.whereIndices((c) -> c.dimIndex == index);
        if (containerResults.length > 0) {
            // if there is a container, copy the container, clone dimensions from indices inside
            var ref = containers[containerResults[0]];

            var copiedContainer = new Container();
            copiedContainer.dimIndex = ref.dimIndex;
            copiedContainer.bufferIndex = ref.bufferIndex;
            copiedContainer.vectorSpace = ref.vectorSpace;
            copiedContainer.useVectorSpace = ref.useVectorSpace;
            copiedContainer.translation = new FastVector2(ref.translation.x, ref.translation.y);
            copiedContainer.zoom = ref.zoom;
            copiedContainer.content = new FastVector2();
            copiedContainer.enableScrollWithClick = ref.enableScrollWithClick;
            copiedContainer.increment = ref.increment;
            copiedContainer.infiniteScroll = ref.infiniteScroll;
            copiedContainer.manual = ref.manual;
            copiedContainer.measurement = ref.measurement;
            copiedContainer.offset = new FastVector2();
            copiedContainer.smoothScrolling = ref.smoothScrolling;
            copiedContainer.softInfiniteLimit = ref.softInfiniteLimit;

            var newParentLink = -1;
            var first = true;
            for (child in ref.childIndices) {
                var childIndex = getIndicesFromDimIndex(child)[0];
                var childDim = _dimRecords[childIndex].dim;
                var childLink = dimensionLinks[childIndex];

                var link = -1;
                if (childLink > -1) {
                    link = newParentLink;
                }

                var length = copyDimIndex(child, link);
                var newIndices = [];

                if (child.getName() == "Group") {
                    beginGroup();
                }

                for (i in 0...length) {    
                    results.push(_dimTemp.length - 1);
                    var newIndex = _dimRecords.length + _dimTemp.length - 1;
                    newIndices.push(newIndex);
                    if (child.getName() == "Group") {
                        addDimensionIndexToGroup(newIndex);
                    }

                    if (first) {
                        newParentLink = newIndex;
                        first = false;
                    }
                }

                if (child.getName() == "Direct") {
                    copiedContainer.childIndices.push(Direct(newIndices[0]));
                }
                else {
                    copiedContainer.childIndices.push(Group(endGroup()));
                }
            }
            
            containers.push(copiedContainer);
        }
        else {
            // treat the index as a single dimension, copy only queries/activities
            copyDimIndex(Direct(index));
            results.push(_dimTemp.length - 1);
        }

        return results;
    }

    /**
    * Copies a `DimIndex`, either as a group or a specific index.
    * If copying a group of indices, `withLink` sets all the copied indices within the group to this index.
    *
    * The results of the copy do not move the dimension and are not seen until the next frame.
    * For a more robust copy function, use `copyDimIndexOffset`.
    * 
    * @param index The index to copy.
    *
    * @return Return the number of copied indices.
    **/
    public function copyDimIndex(index:DimIndex, ?withLink:Int = -1):Int {
        switch (index) {
            case Direct(item): {
                var dim = _dimRecords[item].dim;
                var clonedQuery = queries[item].clone();
                var offset = _dimTemp.push(dim.clone());

                var newIndex = _dimRecords.length + offset - 1;
                queries.push(clonedQuery);
                activities.push([]);

                addDimensionIndexToBuffer(newIndex);
                addDimensionIndexToBuffer(newIndex);

                _dimTempLinkTo.push(withLink);

                return 1;
            }
            case Group(item): {
                for (g in _groups[item]) {
                    copyDimIndex(Direct(g), withLink);
                }

                return _groups[item].length;
            }
        }
    }

    private function getNewIndex(index:Int) {
        if (_dormantDimIndices.length > 0) {
            return _dormantDimIndices[0];
        }
        
        return index;
    }

    /**
    * Create a container with the given bounds and render type. This function is used to create
    * a container that can hold dimensions and render them as a group.
    *
    * @param bounds The dimensions of the container.
    * @param renderType An optional render type ID to specify how the container should be rendered.
    **/
    public function createContainer(bounds:Dim, renderType:Id = null):ContainerResult {
        // Create the container dimension (setup phase)
        var containerIndex = addUI(bounds, renderType ?? Id.None);
        
        // Create associated VectorSpace
        var vectorSpace = new VectorSpace(bounds);
        
        var result:ContainerResult = {
            index: containerIndex,
            space: vectorSpace,
            containerIndex: _vectorSpaces.length
        };
        
        _vectorSpaces.push(vectorSpace);
        
        return result;
    }

    /**
    * Begin a new container with the given `ContainerResult`. This function is used to start rendering
    * dimensions within a container. The container must be created with `createContainer` first.
    **/
    public function beginContainer(container:ContainerResult) {
        if (_containerStack.findIndex((c) -> c.index == container.index) == -1) {
            _containerStack.push(container);
        }
        else {
            throw "Container with the same index already exists in the stack.";
        }
        
        // Begin vector space transformation
        beginVectorSpace(container.space);
        
        // Set up clipping
        scissor(container.index);
    }

    /**
    * End the current container and finalize its rendering. This function is used to stop rendering
    * dimensions within a container.
    **/
    public function endContainer() {
        if (_containerStack.length == 0) return;
        
        var container = _containerStack.pop();
        
        // Clean up rendering state
        disableScissor();
        endVectorSpace();
        
        // Store for cleanup in end()
        var foundContainerIndex = _activeContainers.findIndex((c) -> c.index == container.index);
        if (foundContainerIndex == -1) {
            _activeContainers.push(container);
        }
        else {
            _activeContainers[foundContainerIndex] = container;
        }

        updateContainerContentBounds(container);
    }

    /**
    * Get children that should be rendered in current container
    */
    public function getCurrentContainerChildren():Array<DimIndex> {
        return _containerStack.length > 0 ? 
            _containerStack[_containerStack.length - 1].space.children : [];
    }

    /**
    * Add an empty dimension to the context. This function is used to reserve a dimension index
    * for later use, such as when you want to add a dimension later in the frame.
    *
    * Dimensions added with this function cannot be added to groups or buffers.
    *
    * @param dim The dimension to add. This dimension is not rendered and is not considered
    * affected by user input or physics simulations.
    * @param linkTo An optional index specifying that this dimension should be linked to another index.
    * @return Returns the index of the dimension in the context.
    **/
    public function addEmpty(dim:Dim, linkTo:Int = -1) {
        if (_ended) {
            throw "Cannot add to context once the current frame has ended.";
        }

        // Store as a unified record in temporary storage
        var record:DimensionRecord = {
            dim: dim.clone()
        };
        
        _dimRecordsTemp.push(record);

        _dimTemp.push(dim);
        _dimTempLinkTo.push(linkTo);

        var index = getNewIndex(_dimTemp.length - 1);
        if (noVirtualSceneChange && _dormantDimIndices.length == 0) {
            index += _dimRecords.length;
        }

        queries[index] = null;
        activities[index] = null;
        _activeDimensions[index] = true;
        
        return DimIndex.Direct(index);
    }

    /**
    * Add a static dimension with the given render type. Static dimensions are not considered to be
    * affected by user input or physics simulations.
    *
    * When `beginGroup` is used, this function returns the group index and adds the dimension index to the group.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    * @param linkTo An optional index specifying that this dimension should be linked to another index.
    * @param data An optional data value specifying the data related to this dimension typically used for auto tracking.
    *
    * @return An index value of the position of this dimension as it would be in permanent storage,
    * or the current group index.
    **/
    public function addStatic(dim:Dim, renderType:Id, ?linkTo:Int = -1, ?data:Dynamic = null):DimIndex {
        if (_ended) {
            throw "Cannot add to context once the current frame has ended.";
        }

        // Store as a unified record in temporary storage
        var record:DimensionRecord = {
            dim: dim.clone()
        };
        
        _dimRecordsTemp.push(record);

        _dimTemp.push(dim);
        _dimTempLinkTo.push(linkTo);
        
        var index = getNewIndex(_dimTemp.length - 1);
        if (noVirtualSceneChange && _dormantDimIndices.length == 0) {
            index += _dimRecords.length;
        }

        var query = new RenderQuery();
        query.type = QUERY_STATIC;
        query.renderType = renderType;

        if (index < _dimTemp.length) {
            queries[index] = query;
            activities[index] = [];
            _activeDimensions[index] = true;
        }
        else {
            queries.push(query);
            activities.push([]);
            _activeDimensions.push(true);
        }

        addDimensionIndexToBuffer(index);
        addDimensionIndexToGroup(index);

        var result = _currentGroup > -1 ? DimIndex.Group(_currentGroup, renderType) : DimIndex.Direct(index, renderType);
        return result;
    }

    /**
    * Add a UI dimension with the given render type. UI dimensions are considered to be
    * affected by user input but not physics simulations.
    *
    * When `beginGroup` is used, this function returns the group index and adds the dimension index to the group.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    * @param linkTo An optional index specifying that this dimension should be linked to another index.
    *
    * @return An index value of the position of this dimension as it would be in permanent storage,
    * or the current group index.
    **/
    public function addUI(dim:Dim, renderType:Id, ?linkTo:Int = -1, ?data:Dynamic = null):DimIndex {
        if (_ended) {
            throw "Cannot add to context once the current frame has ended.";
        }

        // Store as a unified record in temporary storage
        var record:DimensionRecord = {
            dim: dim.clone(),
        };
        
        _dimRecordsTemp.push(record);

        _dimTemp.push(dim);
        _dimTempLinkTo.push(linkTo);

        var index = getNewIndex(_dimTemp.length - 1);
        if (noVirtualSceneChange && _dormantDimIndices.length == 0) {
            index += _dimRecords.length;
        }

        var query = new RenderQuery();
        query.type = QUERY_UI;
        query.renderType = renderType;
        if (index < _dimTemp.length) {
            queries[index] = query;
            activities[index] = [];
            _activeDimensions[index] = true;
        }
        else {
            queries.push(query);
            activities.push([]);
            _activeDimensions.push(true);
        }

        if (_currentMenu > -1) {
            _menus[_currentMenu].indices.push(index);
        }

        addDimensionIndexToBuffer(index);
        addDimensionIndexToGroup(index);

        var result = _currentGroup > -1 ? DimIndex.Group(_currentGroup, renderType) : DimIndex.Direct(index, renderType);
        return result;
    }

    /**
    * Add a Sprite dimension with the given render type. Sprite dimensions are considered to be
    * affected physics simulations but not user input.
    *
    * When `beginGroup` is used, this function returns the group index and adds the dimension index to the group.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    * @param linkTo An optional index specifying that this dimension should be linked to another index.
    *
    * @return An index value of the position of this dimension as it would be in permanent storage,
    * or the current group index.
    **/
    public function addSprite(dim:Dim, renderType:Id, ?linkTo:Int = -1, ?data:Dynamic = null):DimIndex {
        if (_ended) {
            throw "Cannot add to context once the current frame has ended.";
        }

        // Store as a unified record in temporary storage
        var record:DimensionRecord = {
            dim: dim.clone(),
        };
        
        _dimRecordsTemp.push(record);

        _dimTemp.push(dim);
        _dimTempLinkTo.push(linkTo);

        var index = getNewIndex(_dimTemp.length - 1);
        if (noVirtualSceneChange && _dormantDimIndices.length == 0) {
            index += _dimRecords.length;
        }

        var query = new RenderQuery();
        query.type = QUERY_SPRITE;
        query.renderType = renderType;
        if (index < _dimTemp.length) {
            queries[index] = query;
            activities[index] = [];
            _activeDimensions[index] = true;
        }
        else {
            queries.push(query);
            activities.push([]);
            _activeDimensions.push(true);
        }

        addDimensionIndexToBuffer(index);
        addDimensionIndexToGroup(index);

        var result = _currentGroup > -1 ? DimIndex.Group(_currentGroup, renderType) : DimIndex.Direct(index, renderType);
        return result;
    }

    /**
    * Adds a container at the given dimension and then supplies the index of the container
    * as it would be in permanent storage. Containers are UI elements, but have special properties
    * that enables scroll and other like events to occur automatically.
    *
    * @param dim The dimension of this container.
    * @param renderType An integer used to determine what is rendered.
    * @param linkTo An optional index specifying that this dimension should be linked to another index.
    *
    * @return An index value of the position of this container as it would be in permanent storage.
    **/
    @:deprecated("Use `createContainer` instead.")
    public function addContainer(dim:Dim, renderType:Id, linkTo:Int = -1):ContainerResult {
        var container = new Container();
        var resultIndex = addUI(dim, renderType, linkTo);
        container.dimIndex = switch(resultIndex) {
            case Direct(index): index;
            case Group(index): _groups[index][_groups[index].length - 1];
        };
        container.offset = new FastVector2(0, 0);
        container.content = new FastVector2(0, 0);

        _containerTemp.push(container);
        var result = _containerTemp.length - 1;
        if (noVirtualSceneChange) {
            result += containers.length;
        }

        addDimensionIndexToBuffer(container.dimIndex);

        return {
            index: resultIndex,
            containerIndex: result
        };
    }

    /**
    * Add a container that is used as the basis for text input. An internal text input handler and text renderer
    * is implemented in the underlying `TextInputState`. To access, use the `textInputs` variable of this class
    * and use it to pass in your update and render contexts accordingly.
    *
    * You can control how the text input is rendered. There is `ImSingle`, `ImMultiline` and `Buffered`.
    *
    * @param dim The dimension to which this text input is rendered.
    * @param method The renderer method to use.
    * @param linkTo An optional index specifying that this dimension should be linked to another index.
    *
    * @return Returns three indices to represent the dim, container and input text states stored in this context.
    **/
    @:deprecated("API to be replaced with a more robust text input system in the future.")
    public function addTextInput(dim:Dim, method:TextInputMethod, linkTo:Int = -1):TextInputResult {
        var container = new Container();
        var resultIndex = addUI(dim, InputRenderer.RenderId, linkTo);
        container.dimIndex = switch (resultIndex) {
            case Direct(index): index;
            case Group(index): _groups[index][_groups[index].length - 1];
        };
        queries[container.dimIndex].acceptsTextInput = true;
        container.manual = true;
        container.offset = new FastVector2(0, 0);
        container.content = new FastVector2(0, 0);

        _containerTemp.push(container);
        var result = _containerTemp.length - 1;
        if (noVirtualSceneChange) {
            result += containers.length;
        }

        var inputResult:TextInputResult = {
            containerIndex: result,
            index: resultIndex,
            textInputIndex: textInputs.length
        };

        addDimensionIndexToBuffer(container.dimIndex);

        var inputState = new TextInputState();
        inputState.setup(inputResult, method);
        textInputs.push(inputState);

        return inputResult;
    }

    /**
    * Set the scroll position of a given container. Optionally set the scrolling of the container using
    * mouse behaviours to infinite. If you set the container to infinite and set scroll to (0, 0), the offset
    * stays in place and does not reset.
    *
    * @param containerIndex The index of the container, not the dimension.
    * @param scroll The scroll position to set this container to.
    * @param infinite (Optional) A value to specify if the container should scroll infinitely.
    **/
    @:deprecated("Favour `createContainer` and related vector space functions instead.")
    public function setContainerScroll(containerIndex:Int, scroll:FastVector2, ?infinite:Bool = false) {
        var container = containers[containerIndex];
        container.infiniteScroll = infinite;
        if (container.infiniteScroll) {
            if (scroll.x != 0 && scroll.y != 0) {
                container.offset = new FastVector2(scroll.x, scroll.y);
            }
        }
    }

    private function updateVectorSpaces() {
        for (vectorSpace in _vectorSpaces) {
            if (vectorSpace.scrollable) {
                vectorSpace.updateScrolling();
            }
        }
    }

    /**
    * Begin the `GraphicsContext`.
    **/
    public function begin() {
        _ended = false;

        updateVectorSpaces();
    }

    /**
    * Adds any temporary dimensions previously added in the current frame into permanent storage, refreshing
    * any activities that were also performed on this frame.
    *
    * NOTE: Temporary dimensions added are copied directly into dimensions, overriding any existing dimensions.
    * This happens to mimic scene changes without needing to perform a full re-initialisation. To disable this
    * behaviour, set `noVirtualSceneChange` field to `true`.
    **/
    public function end() {
        if (!noVirtualSceneChange) {
            if (_dimRecordsTemp.length > 0) {
                _dimRecords = _dimRecordsTemp.map((record) -> record);
                dimensions = _dimRecordsTemp.map((record) -> record.dim);
                dimensionLinks = _dimTempLinkTo.copy();
            }

            // if (_containerTemp.length > 0) {
            //     containers = _containerTemp.copy();
            // }
        }
        else {
            for (i in 0..._dimRecordsTemp.length) {
                var index = i;
                if (_dormantDimIndices.length > 0) {
                    index = _dormantDimIndices.shift();
                    if (index < _dimRecords.length) {
                        _dimRecords[index] = _dimRecordsTemp[i];
                        //dimensions[index] = _dimRecordsTemp[i].dim;
                        dimensionLinks[index] = _dimTempLinkTo[i];
                    }
                }
                else {
                    _dimRecords.push(_dimRecordsTemp[i]);
                    //dimensions.push(_dimRecordsTemp[i].dim);
                    dimensionLinks.push(_dimTempLinkTo[i]);
                }
            }

            // for (i in 0..._containerTemp.length) {
            //     containers.push(_containerTemp[i]);
            // }
        }

        _dimRecordsTemp = [];
        _dimTemp = [];
        _dimTempLinkTo = [];
        _containerTemp = [];

        for (i in 0...activities.length) {
            activities[i] = [];
        }

        _ended = true;
        _g2.end();
    }

    /**
    * Update container content bounds based on their children's actual positions.
    **/
    private function updateContainerContentBounds(context:ContainerResult) {
        if (context.space.children.length == 0) {
            context.space.updateContentBounds(new Dim(0, 0, 0, 0));
            return;
        }
        
        var minX = Math.POSITIVE_INFINITY;
        var minY = Math.POSITIVE_INFINITY;
        var maxX = Math.NEGATIVE_INFINITY;
        var maxY = Math.NEGATIVE_INFINITY;
        
        // Find the actual bounds of all content
        for (childIndex in context.space.children) {
            var dims = getClientDimensionsAtIndex(childIndex);
            for (dim in dims) {
                if (dim != null) {
                    minX = Math.min(minX, dim.x);
                    minY = Math.min(minY, dim.y);
                    maxX = Math.max(maxX, dim.x + dim.width);
                    maxY = Math.max(maxY, dim.y + dim.height);
                }
            }
        }
        
        // Handle case where no valid dimensions were found
        if (minX == Math.POSITIVE_INFINITY) {
            context.space.updateContentBounds(new Dim(0, 0, 0, 0));
            return;
        }
        
        // Create content bounds that include negative positions
        var contentBounds = new Dim(minX, minY, maxX - minX, maxY - minY);
        context.space.updateContentBounds(contentBounds);
    }

    /**
    * Apply container vector space transformations to a dimension.
    **/
    private function applyContainerTransformations(dim:Dim, dimIndex:Int):Dim {
        var containerIndex = findContainerForDimension(dimIndex);
        if (containerIndex == -1) {
            return dim;
        }
        
        var container = _vectorSpaces[containerIndex];
        var result = dim.clone();
        
        // Apply scrolling offset first
        var offsetX = container.translation.x;
        var offsetY = container.translation.y;
        
        result.x += offsetX;
        result.y += offsetY;

        var transformedPos = container.transformPoint(result.x, result.y);
        var transformedSize = container.transformPoint(result.width, result.height);
        
        result.x = transformedPos.x;
        result.y = transformedPos.y;
        result.width = transformedSize.x;
        result.height = transformedSize.y;
        
        return result;
    }

    public function getActiveContainers():Array<ContainerResult> {
        return _activeContainers;
    }

    private function findContainerForDimension(dimIndex:Int):Int {
        for (i in 0..._activeContainers.length) {
            if (_activeContainers[i].containerIndex == dimIndex) {
                return i;
            }

            if (_activeContainers[i].space.hasChild(Direct(dimIndex))) {
                return i;
            }
        }

        // for (i in 0...containers.length) {
        //     var container = containers[i];
        //     for (childIndex in container.childIndices) {
        //         switch (childIndex) {
        //             case Direct(index): {
        //                 if (index == dimIndex) return i;
        //             }
        //             case Group(groupIndex): {
        //                 if (_groups[groupIndex].contains(dimIndex)) return i;
        //             }
        //         }
        //     }
        // }
        return -1;
    }


    /**
    * GRAPHICS / RENDERING FUNCTIONS
    **/

    //
    // Particle System
    //

    public function getParticleEngine():Engine {
        return Engine.instance;
    }

    public function drawParticles() {
        var engine = Engine.instance;
        if (vectorSpace != null) {
            for (emitter in engine.emitters) {
                emitter.position = vectorSpace.transformPoint(emitter.position.x, emitter.position.y);
            }
        }

        engine.update(UpdateContext.deltaTime);
        engine.render(this);
    }



    //
    // Animations
    //

    private var transforms:Array<FastMatrix3>;

    public function pushRotate3D(index:DimIndex, x:Float, y:Float, z:Float) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        // Calculate the center of the object (this is our anchor/pivot point)
        var centerX = dims[0].x + (dims[0].width / 2);
        var centerY = dims[0].y + (dims[0].height / 2);
        
        // The x, y, z parameters represent the rotation angles in 3D space
        // x = pitch (rotation around X-axis, up/down)
        // y = yaw (rotation around Y-axis, left/right) 
        // z = roll (rotation around Z-axis, clockwise/counter-clockwise)
        
        var pitch = x * Math.PI / 180; // Convert to radians
        var yaw = y * Math.PI / 180;
        var roll = z * Math.PI / 180;
        
        // Create 3D rotation matrices
        // Note: In 2D, we can only approximate 3D rotations
        
        // Roll (Z-axis rotation) - this is pure 2D rotation
        var cosRoll = Math.cos(roll);
        var sinRoll = Math.sin(roll);
        
        // Yaw (Y-axis rotation) - creates horizontal skewing and scaling
        var cosYaw = Math.cos(yaw);
        var sinYaw = Math.sin(yaw);
        
        // Pitch (X-axis rotation) - creates vertical skewing and scaling
        var cosPitch = Math.cos(pitch);
        var sinPitch = Math.sin(pitch);
        
        // Create the combined 3D transformation matrix
        // This approximates 3D rotation in 2D space
        var perspectiveMatrix = FastMatrix3.identity();
        
        // Apply rotations in order: Roll -> Pitch -> Yaw
        // Roll (pure 2D rotation)
        perspectiveMatrix._00 = cosRoll * cosYaw;
        perspectiveMatrix._01 = -sinRoll * cosPitch + cosRoll * sinYaw * sinPitch;
        perspectiveMatrix._10 = sinRoll * cosYaw;
        perspectiveMatrix._11 = cosRoll * cosPitch + sinRoll * sinYaw * sinPitch;
        
        // Add perspective foreshortening based on rotation angles
        // Objects rotated away from the viewer appear smaller
        var foreshortening = Math.abs(cosYaw * cosPitch);
        perspectiveMatrix._00 *= foreshortening;
        perspectiveMatrix._11 *= foreshortening;
        
        // Create translation to center, apply rotation, then translate back
        var finalTransform = FastMatrix3.translation(centerX, centerY)
            .multmat(perspectiveMatrix)
            .multmat(FastMatrix3.translation(-centerX, -centerY));

        transforms.push(finalTransform);
    }

    private function pushAnimationState(index:DimIndex) {
        var g2 = getGraphics();

        var dim = getClientDimensionsAtIndex(index);
        if (dim[0] == null) {
            return;
        }
        
        if (!_animations.exists(index)) {
            var finalTransform = FastMatrix3.identity();

            while (transforms.length > 0) {
                finalTransform = finalTransform.multmat(transforms.pop());
            }

            g2.pushTransformation(finalTransform);

            return;
        }

        var state = _animations[index];
        switch (state.time) {
            case Seconds(value): {

            }
            case Frames(factor): {
                var deltaSpeed = UpdateContext.deltaTime * factor;
                if (state.to.rotation != null) {
                    if (state.current.rotation == null) {
                        state.current.rotation = 0.0;
                    }
                    state.current.rotation += state.to.rotation * deltaSpeed;
                }

                if (state.to.transform != null) {
                    if (state.current.transform == null) {
                        state.current.transform = FastMatrix3.identity();
                    }
                    // Apply incremental transform changes
                    var deltaTransform = state.to.transform.mult(deltaSpeed);
                    state.current.transform = state.current.transform.multmat(deltaTransform);
                }

                var finalTransform = FastMatrix3.identity();

                if (state.current.transform != null) {
                    finalTransform = finalTransform.multmat(state.current.transform);
                }

                if (state.current.rotation != null) {
                    if (state.to.rotationPivot == null) {
                        state.to.rotationPivot = new FastVector2(0.5, 0.5);
                    }

                    var pivotX = dim[0].x + dim[0].width * state.to.rotationPivot.x;
                    var pivotY = dim[0].y + dim[0].height * state.to.rotationPivot.y;
                    
                    var rotationTransform = FastMatrix3.translation(pivotX, pivotY)
                        .multmat(FastMatrix3.rotation(state.current.rotation))
                        .multmat(FastMatrix3.translation(-pivotX, -pivotY));
                    
                    finalTransform = finalTransform.multmat(rotationTransform);
                }

                while (transforms.length > 0) {
                    finalTransform = finalTransform.multmat(transforms.pop());
                }

                g2.pushTransformation(finalTransform);
            }
        }
    }

    public function popAnimationState() {
        var g2 = getGraphics();
        g2.popTransformation();
    }



    private var vectorSpace:VectorSpace;

    /**
    * Begin vector space rendering. All subsequent dimension operations will be transformed.
    **/
    public function beginVectorSpace(space:VectorSpace) {
        vectorSpace = space;
    }

    /**
    * End vector space rendering.
    **/
    public function endVectorSpace() {
        vectorSpace = null;
    }

    /**
    * Transform screen coordinates to vector space coordinates.
    * Use this for input handling when you need vector space coordinates.
    **/
    public function transformScreenToVector(screenPos:FastVector2):FastVector2 {
        if (vectorSpace == null) {
            return screenPos;
        }
        
        // Inverse transformation
        var translatedX = screenPos.x - vectorSpace.translation.x;
        var translatedY = screenPos.y - vectorSpace.translation.y;
        
        return new FastVector2(translatedX / vectorSpace.zoom, translatedY / vectorSpace.zoom);
    }

    /**
    * Transform vector space coordinates to screen coordinates.
    **/
    public function transformVectorToScreen(vectorPos:FastVector2):FastVector2 {
        if (vectorSpace == null) {
            return vectorPos;
        }
        
        return vectorSpace.transformPoint(vectorPos.x, vectorPos.y);
    }

    public function setColor(color:Color) {
        getGraphics().color = color;
    }

    public function setFont(font:Font) {
        getGraphics().font = font;
    }

    public function setFontSize(fontSize:Int) {
        getGraphics().fontSize = fontSize;
    }


    //
    // Tile Maps
    //

    private var _currentTileMap:TileMap;
    private var _tileMapActive:Bool;
    /**
    * An array of indices referring to rendered objects
    * within the map, collected from all `draw` calls
    * in this class.
    **/
    private var _tileMapIndices:Array<Int>;
    /**
    * A copy of `_tileMapIndices` when `endTileMap` is called.
    **/
    private var _tileMapLastIndices:Array<Int>;

    /**
    * Gets the last rendered objects within the tilemap as an array
    * of `DimIndex`, assuming they are of `SPRITE` render type.
    **/
    public function getTileMapRenderedObjects() {

    }


    /**
    * Render a tile map to a given dim index and optional callbacks.
    * For correct movement and positioning of the map, ensure the `index` value is assigned to a vector space, using `beginVectorSpace` / `endVectorSpace`.
    *
    * If supplying a `layerCallback`, each layer drawn is supplied to you before it is rendered. Return `true` from this function to finish rendering. Change
    * or adjust tiles as needed.
    * 
    * If the tile map is drawn with chunks, it is more efficient to use the `chunkCallback` parameter as this will automatically acquire a reference to all tiles
    * expected to be drawn. You can safely ignore `layerCallback` if layers do not need adjusting prior to rendering. You do not need to return a value with this callback.
    *
    * @param index The dim index for the position.
    * @param map The tile map to render.
    * @param layerCallback Optional callback for layer manipulation.
    * @param chunkCallback Optional callback for tile manipulation.
    **/
    public function beginTileMap(index:DimIndex, map:TileMap, ?layerCallback:(TileMapLayer) -> Bool, ?chunkCallback:(Array<Tile>) -> Void) {

    }

    /**
    * End the currently drawn tile map.
    **/
    public function endTileMap() {

    }



    //
    // Drawing Routines
    // 



    public function drawImage(index:DimIndex, img:Image) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        if (vectorSpace != null) {
            getGraphics().drawScaledImageDim(img, dims[0]);
        }
        else {
            getGraphics().drawImageDim(img, dims[0]);
        }

        popAnimationState();
    }

    public function drawSubImage(index:DimIndex, img:Image, source:Dim) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawSubImageDim(img, source, dims[0]);

        popAnimationState();
    }

    public function drawScaledImage(index:DimIndex, img:Image) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawScaledImageDim(img, dims[0]);

        popAnimationState();
    }

    public function drawScaledSubImage(index:DimIndex, img:Image, source:Dim) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawScaledSubImageDim(img, source, dims[0]);

        popAnimationState();
    }

    public function drawPatchedImage(index:DimIndex, img:Image, patch:Patch) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawPatchedImage(img, patch, dims[0]);

        popAnimationState();
    }

    public function drawImageRepeat(index:DimIndex, img:Image, source:Dim, axis:Int = 0) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawImageRepeat(img, source, dims[0], axis);

        popAnimationState();
    }

    public function drawRect(index:DimIndex, lineThickness:Float = 1.0) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawRectDim(dims[0], lineThickness);

        popAnimationState();
    }

    public function drawBorders(index:DimIndex, lineThickness:Float = 1.0, borders:Int = BORDER_ALL) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawBorders(dims[0], lineThickness, borders);

        popAnimationState();
    }

    public function fillRect(index:DimIndex) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().fillRectDim(dims[0]);

        popAnimationState();
    }

    static var frameCount:Int = 0;
    static var frameTimeAnimIndex:Int = -1;

    public function drawFrameRate() {
        if (frameTimeAnimIndex == -1) {
            frameTimeAnimIndex = Animate.animateCreateTick();
        }

        if (Animate.animateTickLoop(frameTimeAnimIndex, 0.5)) {
            frameCount = cast Math.round(UpdateContext.getFrameCount());
        }

        getGraphics().drawString("FPS: " + Std.string(frameCount), 10, 10);
    }

    public function drawString(index:DimIndex, text:String) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawStringDim(text, dims[0]);

        popAnimationState();
    }

    public function forceMultilineUpdate() {
        getGraphics().forceMultilineUpdate();
    }

    public function disableMultilineUpdate() {
        getGraphics().disableMultilineUpdate();
    }

    public function useCRLF(crlf:Bool) {
        getGraphics().useCRLF(crlf);
    }

    public function drawCharacters(index:DimIndex, characters:Array<Int>, start:Int, length:Int, autoWrap:Bool = false, clipping:Bool = false, breaks:Array<Int> = null) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return null;
        }

        pushAnimationState(index);

        var result = getGraphics().drawCharactersDim(characters, start, length, dims[0], autoWrap, clipping, breaks);

        popAnimationState();

        return result;
    }

    public function drawVideo(index:DimIndex, video:Video) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawVideoDim(video, dims[0]);

        popAnimationState();
    }

    public function drawCircle(index:DimIndex, strength:Float = 1.0) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        if (vectorSpace != null && vectorSpace?.zoom > 2) {
            var cx = dims[0].x + (dims[0].width / 2);
            var cy = dims[0].y + (dims[0].height / 2);
            var radius = dims[0].width / 2;

            getGraphics().drawTessellatedCircle(cx, cy, radius, strength, false);
        }
        else {
            getGraphics().drawCircleDim(dims[0], strength);
        }

        popAnimationState();
    }

    public function fillCircle(index:DimIndex) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        if (vectorSpace != null && vectorSpace?.zoom > 2) {
            var cx = dims[0].x + (dims[0].width / 2);
            var cy = dims[0].y + (dims[0].height / 2);
            var radius = dims[0].width / 2;

            getGraphics().drawTessellatedCircle(cx, cy, radius, 0, true);
        }
        else {
            getGraphics().fillCircleDim(dims[0]);
        }

        popAnimationState();
    }

    public function drawTriangle(index:DimIndex, direction:Int, strength:Float = 1.0) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawTriangleDim(dims[0], direction, strength);

        popAnimationState();
    }

    public function drawEquilateralTriangleRaw(centerX:Float, centerY:Float, radius:Float, rotation:Float = 0.0, strength:Float = 1.0) {
        getGraphics().drawEquilateralTriangle(centerX, centerY, radius, rotation, strength);
    }

    public function drawIsoscelesTriangleRaw(x:Float, y:Float, baseWidth:Float, height:Float, direction:Int = 0, strength:Float = 1.0) {
        getGraphics().drawIsoscelesTriangle(x, y, baseWidth, height, direction, strength);
    }

    public function drawPolygon(index:DimIndex, vertices:Array<Vector2>, strength:Float = 1) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawPolygon(dims[0].x, dims[0].y, vertices, strength);

        popAnimationState();
    }

    public function fillPolygon(index:DimIndex, vertices:Array<Vector2>) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().fillPolygon(dims[0].x, dims[0].y, vertices);

        popAnimationState();
    }

    public function fillTriangle(index:DimIndex, direction:Int) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().fillTriangleDim(dims[0], direction);

        popAnimationState();
    }

    public function drawRoundedRect(index:DimIndex, radius:Float, strength:Float = 1.0) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawRoundedRectDim(dims[0], radius, strength);

        popAnimationState();
    }

    public function fillRoundedRect(index:DimIndex, radius:Float, strength:Float = 1.0) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().fillRoundedRectDim(dims[0], radius, strength);

        popAnimationState();
    }

    public function drawRoundedRectCorners(index:DimIndex, topLeft:Float, topRight:Float, bottomRight:Float, bottomLeft:Float, strength:Float = 1.0) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().drawRoundedRectCornersDim(dims[0], topLeft, topRight, bottomRight, bottomLeft, strength);

        popAnimationState();
    }

    public function fillRoundedRectCorners(index:DimIndex, topLeft:Float, topRight:Float, bottomRight:Float, bottomLeft:Float) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(index);

        getGraphics().fillRoundedRectCornersDim(dims[0], topLeft, topRight, bottomRight, bottomLeft);

        popAnimationState();
    }

    public function drawCubicBezier(x:Array<Float>, y:Array<Float>, segments:Int = 20, strength:Float = 1.0) {
        getGraphics().drawCubicBezier(x, y, segments, strength);
    }

    public function drawCubicBezierPath(x:Array<Float>, y:Array<Float>, segments:Int = 20, strength:Float = 1.0) {
        getGraphics().drawCubicBezierPath(x, y, segments, strength);
    }

    public function scissor(index:DimIndex) {
        var dims = getClientDimensionsAtIndex(index);
        if (dims[0] == null) {
            return;
        }

        getGraphics().scissorDim(dims[0]);
    }

    public function disableScissor() {
        getGraphics().disableScissor();
    }

    public function drawSprite(dimindex:DimIndex, sprite:Sprite, index:Int) {
        var dims = getClientDimensionsAtIndex(dimindex);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(dimindex);
        
        getGraphics().drawSprite(sprite, index, dims[0]);

        popAnimationState();
    }

    public function drawSpritePatch(dimindex:DimIndex, sprite:Sprite, stateIndex:Int, patchIndex:Int) {
        var dims = getClientDimensionsAtIndex(dimindex);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(dimindex);
        
        getGraphics().drawSpritePatch(sprite, stateIndex, patchIndex, dims[0]);

        popAnimationState();
    }

    public function drawSpriteGroup(dimindex:DimIndex, sprite:Sprite, index:Int, group:String) {
        var dims = getClientDimensionsAtIndex(dimindex);
        if (dims[0] == null) {
            return;
        }

        pushAnimationState(dimindex);
        
        getGraphics().drawSpriteGroup(sprite, index, group, dims[0]);

        popAnimationState();
    }

    public function drawArc(cx:Float, cy:Float, radius:Float, sAngle:Float, eAngle:Float, strength:Float = 1, ccw:Bool = false,
			segments:Int = 0) {
        getGraphics().drawArc(cx, cy, radius, sAngle, eAngle, strength, ccw, segments);
    }

    public function fillArc(cx:Float, cy:Float, radius:Float, sAngle:Float, eAngle:Float, ccw:Bool = false, segments:Int = 0) {
        getGraphics().fillArc(cx, cy, radius, sAngle, eAngle, ccw, segments);
    }

    public function generateVerticalGradient(width:Int, height:Int, colors:Array<Color>, stops:Array<Float>, inverse:Bool) {
        return getGraphics().generateVerticalGradient(width, height, colors, stops, inverse);
    }

    public function generateHorizontalGradient(width:Int, height:Int, colors:Array<Color>, stops:Array<Float>, inverse:Bool) {
        return getGraphics().generateHorizontalGradient(width, height, colors, stops, inverse);
    }

    public function generateCircularGradient(width:Int, height:Int, colors:Array<Color>, stops:Array<Float>) {
        return getGraphics().generateCircularGradient(width, height, colors, stops);
    }

    public function generateConalGradient(width:Int, height:Int, colors:Array<Color>, stops:Array<Float>, clockwise:Bool) {
        return getGraphics().generateConalGradient(width, height, colors, stops, clockwise);
    }

    public function generatePolarGradient(width:Int, height:Int, colors:Array<Color>, stops:Array<Float>, scale:Float, offset:FastVector2, edge:PolarEdgeEffect) {
        return getGraphics().generatePolarGradient(width, height, colors, stops, scale, offset, edge);
    }



    /**
    * Apply vector transformation to a dimension.
    **/
    private function applyVectorTransform(dim:Dim):Dim {
        if (vectorSpace == null) {
            return dim;
        }
        
        var transformedPos = vectorSpace.transformPoint(dim.x, dim.y);
        var transformedWidth = vectorSpace.transformDistance(dim.width);
        var transformedHeight = vectorSpace.transformDistance(dim.height);
        
        var result = new Dim(transformedPos.x, transformedPos.y, transformedWidth, transformedHeight, dim.order);
        result.visible = dim.visible;
        result.scale = dim.scale;
        return result;
    }


    private function drawVectorRoundedRectCorners(x:Float, y:Float, width:Float, height:Float, 
                                                topLeft:Float, topRight:Float, bottomRight:Float, bottomLeft:Float, 
                                                strength:Float, filled:Bool) {
        var g2 = getGraphics();
        var maxRadius = Math.min(width, height) * 0.5;
        topLeft = Math.min(topLeft, maxRadius);
        topRight = Math.min(topRight, maxRadius);
        bottomRight = Math.min(bottomRight, maxRadius);
        bottomLeft = Math.min(bottomLeft, maxRadius);
        
        var cacheKey = vectorSpace.getCacheKey('roundedRectCorners_${x}_${y}_${width}_${height}_${topLeft}_${topRight}_${bottomRight}_${bottomLeft}_${filled}');
        var cachedPath = vectorSpace.getCachedPath(cacheKey);
        
        if (cachedPath == null) {
            cachedPath = @:privateAccess(Graphics2) Graphics2.generateRoundedRectPath(vectorSpace, x, y, width, height, topLeft, topRight, bottomRight, bottomLeft);
            vectorSpace.setCachedPath(cacheKey, cachedPath);
        }
        
        var scaledStrength = vectorSpace.transformDistance(strength);
        
        if (filled) {
            @:privateAccess(Graphics2) g2.drawFilledPath(cachedPath);
        } else {
            g2.drawTessellatedPath(cachedPath, scaledStrength, true);
        }
    }

}