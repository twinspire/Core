package twinspire.render;

import twinspire.geom.Dim;
import twinspire.render.UpdateContext;
import twinspire.render.QueryType;
import twinspire.render.RenderQuery;
import twinspire.text.InputRenderer;
import twinspire.text.TextInputState;
import twinspire.text.TextInputMethod;
import twinspire.Application;

import kha.graphics2.Graphics;
import kha.math.FastVector2;

typedef ContainerResult = {
    var dimIndex:Int;
    var containerIndex:Int;
}

typedef TextInputResult = {
    > ContainerResult,
    var textInputIndex:Int;
}

@:allow(Application)
@:allow(UpdateContext)
class GraphicsContext {

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
    function get_g2() return _g2;

    public function new() {
        _dimTemp = [];
        _dimTempLinkTo = [];
        _dimForceChangeIndices = [];
        _containerTemp = [];
        containers = [];
        dimensions = [];
        dimensionLinks = [];
        queries = [];
        activities = [];
        textInputs = [];
        _ended = false;
        _currentMenu = -1;
        _containerOffsetsChanged = false;
        _dimClientPositions = [];
        _containerLastOffsets = [];
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
    * Get the dimension at the given index. Any offsets assigned to the dimension is resolved
    * before returned. This function is best used for rendering.
    *
    * @param index The index of the dimension
    * @return Returns either a reference to a given dimension, or a copy of a dimension if linked to a container.
    **/
    public function getDimensionAtIndex(index:Int) {
        var containerIndex = -1;
        for (i in 0...containers.length) {
            var c = containers[i];
            if (c.childIndices.contains(index)) {
                containerIndex = i;
                break;
            }
        }

        if (containerIndex == -1) {
            return dimensions[index];
        }
        else {
            var c = containers[containerIndex];
            var d = dimensions[index];
            return new Dim(d.x + c.offset.x, d.y + c.offset.y, d.width, d.height, d.order);
        }
    }

    /**
    * Like `getDimensionAtIndex`, except the returning dimension is relative to the container it resides.
    * If the dimension does not belong to a container, it returns the exact dimension as is.
    *
    * @param index The index of the dimension.
    **/
    public function getDimensionRelativeAtIndex(index:Int) {
        var containerIndex = -1;
        for (i in 0...containers.length) {
            var c = containers[i];
            if (c.childIndices.contains(index)) {
                containerIndex = i;
                break;
            }
        }

        if (containerIndex == -1) {
            return dimensions[index];
        }
        else {
            var c = containers[containerIndex];
            var d = dimensions[index];
            var cDim = dimensions[c.dimIndex];
            return new Dim(d.x - cDim.x + c.offset.x, d.y - cDim.y + c.offset.y, d.width, d.height, d.order);
        }
    }

    /**
    * Gets a dimension at its respective client coordinates after resolving container offsets.
    * Takes into account any multiples of containers.
    *
    * @param index The index of the dimension.
    **/
    public function getClientDimensionAtIndex(index:Int) {
        return new Dim(_dimClientPositions[index].x, _dimClientPositions[index].y, dimensions[index].width, dimensions[index].height, dimensions[index].order);
    }

    /**
    * Force a dimension's position to change at a given index.
    *
    * @param index The index of the dimension.
    **/
    public function markDimChange(index:Int) {
        if (!_dimForceChangeIndices.contains(index)) {
            _dimForceChangeIndices.push(index);
        }
    }

    /**
    * Add a static dimension with the given render type. Static dimensions are not considered to be
    * affected by user input or physics simulations.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    * @param linkTo An optional index specifying that this dimension should be linked to another index.
    *
    * @return An index value of the position of this dimension as it would be in permanent storage.
    **/
    public function addStatic(dim:Dim, renderType:Id, ?linkTo:Int = -1):Int {
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

        return index;
    }

    /**
    * Add a UI dimension with the given render type. UI dimensions are considered to be
    * affected by user input but not physics simulations.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    * @param linkTo An optional index specifying that this dimension should be linked to another index.
    *
    * @return An index value of the position of this dimension as it would be in permanent storage.
    **/
    public function addUI(dim:Dim, renderType:Id, ?linkTo:Int = -1) {
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

        return index;
    }

    /**
    * Add a Sprite dimension with the given render type. Sprite dimensions are considered to be
    * affected physics simulations but not user input.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    * @param linkTo An optional index specifying that this dimension should be linked to another index.
    *
    * @return An index value of the position of this dimension as it would be in permanent storage.
    **/
    public function addSprite(dim:Dim, renderType:Id, ?linkTo:Int = -1) {
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

        return index;
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
        container.dimIndex = addUI(dim, renderType, linkTo);
        container.offset = new FastVector2(0, 0);
        container.content = new FastVector2(0, 0);

        _containerTemp.push(container);
        var result = _containerTemp.length - 1;
        if (noVirtualSceneChange) {
            result += containers.length;
        }

        return {
            dimIndex: container.dimIndex,
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
        container.dimIndex = addUI(dim, InputRenderer.RenderId, linkTo);
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
            dimIndex: container.dimIndex,
            textInputIndex: textInputs.length
        };

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
                    dimIndicesChanged.push(di);
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
                var dim = dimensions[index];
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
                        if (c.childIndices.contains(childIndex)) {
                            offset.x += c.offset.x;
                            offset.y += c.offset.y;
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