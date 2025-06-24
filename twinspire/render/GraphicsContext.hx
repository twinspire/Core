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
    **/
    public function beginGroup(?index:Int = -1) {
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
            if (index > -1 && index < _groups[_currentGroup].length - 1) {
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
                results.push(new Dim(d.x + c.offset.x * scale, d.y + c.offset.y * scale, d.width, d.height, d.order));
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
                if (item < _groups.length - 1) {
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
                results.push(new Dim(d.x - cDim.x + c.offset.x * scale, d.y - cDim.y + c.offset.y * scale, d.width, d.height, d.order)); 
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
                    return [ new Dim(_dimClientPositions[item].x, _dimClientPositions[item].y, dimensions[item].width, dimensions[item].height, dimensions[item].order) ];
                }
            }
            case Group(item): {
                if (item < _groups.length - 1) {
                    var results = new Array<Dim>();
                    for (child in _groups[item]) {
                        results.push(new Dim(_dimClientPositions[child].x, _dimClientPositions[child].y, dimensions[child].width, dimensions[child].height, dimensions[child].order));
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
    * Add a static dimension with the given render type. Static dimensions are not considered to be
    * affected by user input or physics simulations.
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
    public function addStatic(dim:Dim, renderType:Id, ?linkTo:Int = -1):DimIndex {
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

        if (_currentGroup > -1) {
            return Group(_currentGroup);
        }
        else {
            return Direct(index);
        }
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
    public function addUI(dim:Dim, renderType:Id, ?linkTo:Int = -1):DimIndex {
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

        if (_currentGroup > -1) {
            return Group(_currentGroup);
        }
        else {
            return Direct(index);
        }
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
    public function addSprite(dim:Dim, renderType:Id, ?linkTo:Int = -1):DimIndex {
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

        if (_currentGroup > -1) {
            return Group(_currentGroup);
        }
        else {
            return Direct(index);
        }
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