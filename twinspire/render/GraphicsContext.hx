package twinspire.render;

import twinspire.DimIndex;
import twinspire.geom.Dim;
import twinspire.render.UpdateContext;
import twinspire.render.QueryType;
import twinspire.render.RenderQuery;
import twinspire.text.InputRenderer;
import twinspire.text.TextInputState;
import twinspire.text.TextInputMethod;
import twinspire.Application;
using twinspire.extensions.ArrayExtensions;

import kha.graphics2.Graphics;
import kha.math.FastVector2;
import kha.Image;

typedef ContainerResult = {
    var dimIndex:DimIndex;
    var containerIndex:Int;
}

typedef TextInputResult = {
    > ContainerResult,
    var textInputIndex:Int;
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
    private var _dimClientPositions:Array<FastVector2>;

    private var _buffers:Array<Image>;
    private var _bufferDimensionIndices:Array<Array<Int>>;
    private var _currentBuffer:Int;

    private var _groups:Array<Array<Int>>;
    private var _currentGroup:Int;
    private var _currentGroupRenderType:Id;

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
    public var g2(get, default):Graphics;
    function get_g2() {
        if (_currentBuffer > -1 && _currentBuffer < _buffers.length) {
            return _buffers[_currentBuffer].g2;
        }
        else {
            return _g2;
        }
    }

    public function new() {
        _dimTemp = [];
        _dimTempLinkTo = [];
        _dimForceChangeIndices = [];
        _containerTemp = [];
        _ended = false;
        _currentMenu = -1;
        _containerOffsetsChanged = false;
        _dimClientPositions = [];
        _containerLastOffsets = [];
        _buffers = [];
        _bufferDimensionIndices = [];
        _currentBuffer = -1;
        _groups = [];
        _currentGroup = -1;
        _currentGroupRenderType = null;

        containers = [];
        dimensions = [];
        dimensionLinks = [];
        queries = [];
        activities = [];
        textInputs = [];
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
    * Returns the dimension in temporary storage in the current frame at the index
    * it would be at once added into permanent storage.
    *
    * @param index The position of the dimension when it is added into permanent storage.
    **/
    public function getTemporaryDimAtNewIndex(index:Int) {
        var resolvedIndex = index - (dimensions.length - 1);
        return _dimTemp[resolvedIndex];
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
                        dimensions[index].scale = container.bufferZoomFactor;
                    }
                    case Group(index): {
                        for (item in _groups[index]) {
                            dimensions[item].scale = container.bufferZoomFactor;
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
                return;
            }
        }
        
        _currentGroup = _groups.push([]) - 1;
        _currentGroupRenderType = renderType;
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
    * Gets a value to determine if the given index is valid (i.e., the dimension reference exists in the stack).
    *
    * @param index The dimension index to check.
    **/
    public function isDimIndexValid(index:DimIndex) {
        switch (index) {
            case Direct(item): {
                return item > -1 && item < dimensions.length;
            }
            case Group(group): {
                for (item in _groups[group]) {
                    if (item < 0 || item > dimensions.length - 1) {
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
                results.push(dimensions[actual]);
            }
            else {
                var c = containers[containerIndex];
                var scale = (c.bufferIndex == -1 ? 1.0 : c.bufferZoomFactor);
                var d = dimensions[actual];
                var value = new Dim(d.x + c.offset.x * scale, d.y + c.offset.y * scale, d.width, d.height, d.order);
                value.visible = dimensions[actual].visible;
                value.scale = dimensions[actual].scale;
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
                results.push(dimensions[actual]);
            }
            else {
                var c = containers[containerIndex];
                var scale = (c.bufferIndex == -1 ? 1.0 : c.bufferZoomFactor);
                var d = dimensions[actual].get();
                var cDim = dimensions[c.dimIndex];
                var value = new Dim(d.x - cDim.x + c.offset.x * scale, d.y - cDim.y + c.offset.y * scale, d.width, d.height, d.order);
                value.visible = dimensions[actual].visible;
                value.scale = dimensions[actual].scale;
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
    public function getClientDimensionsAtIndex(index:DimIndex) {
        switch (index) {
            case Direct(item): {
                if (item < dimensions.length) {
                    var value = new Dim(_dimClientPositions[item].x, _dimClientPositions[item].y, dimensions[item].width, dimensions[item].height, dimensions[item].order);
                    value.visible = dimensions[item].visible;
                    value.scale = dimensions[item].scale;
                    return [ value ];
                }
            }
            case Group(item): {
                if (item < _groups.length) {
                    var results = new Array<Dim>();
                    for (child in _groups[item]) {
                        var value = new Dim(_dimClientPositions[child].x, _dimClientPositions[child].y, dimensions[child].width, dimensions[child].height, dimensions[child].order);
                        value.visible = dimensions[child].visible;
                        value.scale = dimensions[child].scale;
                        results.push(value);
                    }
                    return results;
                }
            }
        }

        return [];
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
    * Collate a given set of indices into a single group, returning the new group index as a
    * `DimIndex`. Any existing groups found within the set of indices are extracted and moved into
    * the new group. If the old group is emptied as a result of this, the group is deleted.
    *
    * Any previous reference to other groups that you hold should be refreshed using the `refreshGroups`
    * function.
    *
    * @param indices The indices to collate.
    **/
    public function addNextGroupReference(indices:Array<Int>) {
        // TODO   
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
            copiedContainer.bufferReceivesEvents = ref.bufferReceivesEvents;
            copiedContainer.bufferZoomFactor = ref.bufferZoomFactor;
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
                var childDim = dimensions[childIndex];
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
                    var newIndex = dimensions.length + _dimTemp.length - 1;
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
                var dim = dimensions[item];
                var clonedQuery = queries[item].clone();
                var offset = _dimTemp.push(dim.clone());

                var newIndex = dimensions.length + offset - 1;
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

    private function setupTrackingObject(index:DimIndex, renderType:Id, data:Dynamic) {
        if (useTracker &&
            AutoTrackInfo.updateTracks.exists(renderType) &&
            AutoTrackInfo.renderTracks.exists(renderType) &&
            AutoTrackInfo.endTracks.exists(renderType) &&
            AutoTrackInfo.initTracks.exists(renderType)) {
            var type = _currentGroupRenderType ?? renderType;
            var object = AutoTrackInfo.initTracks[type](this, data);
            if (Reflect.isObject(data)) {
                for (f in Reflect.fields(data)) {
                    object.data[f] = Reflect.field(data, f);
                }
            }

            object.update = AutoTrackInfo.updateTracks[type];
            object.render = AutoTrackInfo.renderTracks[type];
            object.end = AutoTrackInfo.endTracks[type];
            tracker[index] = object;
        }
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
        
        _dimTemp.push(dim);
        _dimTempLinkTo.push(linkTo);
        _dimClientPositions.push(new FastVector2(dim.x, dim.y));
        var index = _dimTemp.length - 1;
        if (noVirtualSceneChange) {
            index += dimensions.length;
        }

        var query = new RenderQuery();
        query.type = QUERY_STATIC;
        query.renderType = renderType;
        queries.push(query);

        activities.push([]);

        addDimensionIndexToBuffer(index);
        addDimensionIndexToGroup(index);

        var result = _currentGroup > -1 ? DimIndex.Group(_currentGroup) : DimIndex.Direct(index);
        if (_currentGroup == -1) {
            setupTrackingObject(result, renderType, data ?? {});
        }
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

        _dimTemp.push(dim);
        _dimTempLinkTo.push(linkTo);
        _dimClientPositions.push(new FastVector2(dim.x, dim.y));
        var index = _dimTemp.length - 1;
        if (noVirtualSceneChange) {
            index += dimensions.length;
        }

        var query = new RenderQuery();
        query.type = QUERY_UI;
        query.renderType = renderType;
        queries.push(query);

        activities.push([]);

        if (_currentMenu > -1) {
            _menus[_currentMenu].indices.push(index);
        }

        addDimensionIndexToBuffer(index);
        addDimensionIndexToGroup(index);

        var result = _currentGroup > -1 ? DimIndex.Group(_currentGroup) : DimIndex.Direct(index);
        if (_currentGroup == -1) {
            setupTrackingObject(result, renderType, data ?? {});
        }
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

        _dimTemp.push(dim);
        _dimTempLinkTo.push(linkTo);
        _dimClientPositions.push(new FastVector2(dim.x, dim.y));
        var index = _dimTemp.length - 1;
        if (noVirtualSceneChange) {
            index += dimensions.length;
        }

        var query = new RenderQuery();
        query.type = QUERY_SPRITE;
        query.renderType = renderType;
        queries.push(query);

        activities.push([]);

        addDimensionIndexToBuffer(index);
        addDimensionIndexToGroup(index);

        var result = _currentGroup > -1 ? DimIndex.Group(_currentGroup) : DimIndex.Direct(index);
        if (_currentGroup == -1) {
            setupTrackingObject(result, renderType, data ?? {});
        }
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
            dimIndex: resultIndex,
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
            dimIndex: resultIndex,
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
    public function setContainerScroll(containerIndex:Int, scroll:FastVector2, ?infinite:Bool = false) {
        var container = containers[containerIndex];
        container.infiniteScroll = infinite;
        if (container.infiniteScroll) {
            if (scroll.x != 0 && scroll.y != 0) {
                container.offset = new FastVector2(scroll.x, scroll.y);
            }
        }
    }

    /**
    * Begin the `GraphicsContext`.
    **/
    public function begin() {
        _ended = false;
    }
    
    /**
    * Begin a menu starting from the last dimension added to temporary storage.
    * The menu automatically receives focus unless specified otherwise.
    *
    * @param id The unique id identifying this menu.
    * @param autoFocus If `false`, does not automatically focus.
    **/
    public function beginMenu(id:Id, autoFocus:Bool = true) {
        var menu = new Menu();
        menu.menuId = id;
        menu.indices.push(_dimTemp.length - 1);
        _menus.push(menu);
        _currentMenu = _menus.length - 1;

        if (autoFocus) {
            _activeMenu = _currentMenu;
        }
    }

    /**
    * Stop adding dimensions to the current menu.
    **/
    public function endMenu() {
        if (menuCursorRenderId != null) {
            var index = addStatic(new Dim(0, 0, 0, 0), menuCursorRenderId);
            _menus[_currentMenu].dimIndex = index;
        }

        _currentMenu = -1;
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
            if (_dimTemp.length > 0) {
                dimensions = _dimTemp.copy();
                dimensionLinks = _dimTempLinkTo.copy();
            }

            if (_containerTemp.length > 0) {
                containers = _containerTemp.copy();
            }
        }
        else {
            for (i in 0..._dimTemp.length) {
                dimensions.push(_dimTemp[i]);
                dimensionLinks.push(_dimTempLinkTo[i]);
            }

            for (i in 0..._containerTemp.length) {
                containers.push(_containerTemp[i]);
            }
        }

        _dimTemp = [];
        _dimTempLinkTo = [];
        _containerTemp = [];

        for (i in 0...activities.length) {
            activities[i] = [];
        }
        
        var containersChanged = new Array<Int>();
        
        // add any additional containers added in current frame
        if (_containerLastOffsets.length != containers.length) {
            var remainder = containers.length - _containerLastOffsets.length;
            // ensure remainder is positive
            if (remainder > 0) {
                for (i in 0...remainder) {
                    _containerLastOffsets.push(new FastVector2());
                    // force a check on all additional containers
                    containersChanged.push(i + containers.length);
                }
            }
        }

        // determine which containers were last changed
        for (i in 0..._containerLastOffsets.length) {
            var current = containers[i].offset;
            var last = _containerLastOffsets[i];

            if (current.x != last.x || current.y != last.y) {
                containersChanged.push(i);
            }
        }

        // recalculate client dimensions for all dimensions affected
        // by a container change
        var dimIndicesChanged = new Array<Int>();

        if (containersChanged.length > -1) {
            for (ci in 0...containersChanged.length) {
                var container = containers[ci];
                for (di in container.childIndices) {
                    switch (di) {
                        case Direct(index): {
                            dimIndicesChanged.push(index);
                        }
                        case Group(index): {
                            dimIndicesChanged.concat(_groups[index]);
                        }
                    }
                }
            }
        }

        for (index in _dimForceChangeIndices) {
            if (!dimIndicesChanged.contains(index)) {
                dimIndicesChanged.push(index);
            }
        }

        if (dimIndicesChanged.length > 0) {
            for (index in dimIndicesChanged) {
                // iterate each dimension
                var dim = dimensions[index].get();
                var childIndex = index;
                
                var containerIndex = -1;
                // contain an offset resolving to client coordinates
                var offset = new FastVector2(0, 0);
                var found = 0;
                
                // loop all containers and check a child index is not found
                // i.e., reached the root-level.
                while (found != -1) {
                    var innerFound = -1;
                    for (i in 0...containers.length) {
                        var c = containers[i];
                        // determine if the offset should change based on whether the container is buffered
                        var scale = (c.bufferIndex == -1 ? 1 : c.bufferZoomFactor);
                        if (c.childIndices.findIndex((di) -> switch (di) {
                            case Direct(index): index == childIndex;
                            case Group(index): _groups[index].contains(childIndex);
                        }) != -1) {
                            offset.x += c.offset.x * scale;
                            offset.y += c.offset.y * scale;
                            innerFound = i;
                            childIndex = c.dimIndex;
                            break;
                        }
                    }

                    found = innerFound;
                }

                _dimClientPositions[index] = new FastVector2(dim.x + offset.x, dim.y + offset.y);
            }
        }

        _ended = true;
    }

}