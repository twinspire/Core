package twinspire.render;

import kha.math.FastVector2;
import twinspire.render.UpdateContext;
import twinspire.Application;
import kha.graphics2.Graphics;
import twinspire.render.QueryType;
import twinspire.render.RenderQuery;
import twinspire.geom.Dim;

typedef ContainerResult = {
    var dimIndex:Int;
    var containerIndex:Int;
}

@:allow(Application)
@:allow(UpdateContext)
class GraphicsContext {

    private var _dimTemp:Array<Dim>;
    private var _dimTempLinkTo:Array<Int>;
    private var _containerTemp:Array<Container>;
    private var _ended:Bool;
    private var _menus:Array<Menu>;
    private var _currentMenu:Int;
    private var _activeMenu:Int;

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
    public var activities:Array<Activity>;
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
        _containerTemp = [];
        containers = [];
        dimensions = [];
        dimensionLinks = [];
        queries = [];
        activities = [];
        _ended = false;
        _currentMenu = -1;
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
        var index = _dimTemp.length - 1;
        if (noVirtualSceneChange) {
            index += dimensions.length;
        }

        var query = new RenderQuery();
        query.type = QUERY_STATIC;
        query.renderType = renderType;
        queries.push(query);

        activities.push(null);

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
        var index = _dimTemp.length - 1;
        if (noVirtualSceneChange) {
            index += dimensions.length;
        }

        var query = new RenderQuery();
        query.type = QUERY_UI;
        query.renderType = renderType;
        queries.push(query);

        activities.push(null);

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

        var index = _dimTemp.length - 1;
        if (noVirtualSceneChange) {
            index += dimensions.length;
        }

        var query = new RenderQuery();
        query.type = QUERY_SPRITE;
        query.renderType = renderType;
        queries.push(query);

        activities.push(null);

        return index;
    }

    /**
    * Adds a container at the given dimension and then supplies the index of the container
    * as it would be in permanent storage. Containers are UI elements, but have special properties
    * that enables scroll and other like events to occur automatically.
    *
    * @param dim The dimension of this container.
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
        _currentMenu = -1;
        if (menuCursorRenderId != null) {
            var index = addStatic(new Dim(0, 0, 0, 0), menuCursorRenderId);
            _menus[_currentMenu].dimIndex = index;
        }
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
            activities[i] = null;
        }

        _ended = true;
    }

}