package twinspire;

import twinspire.events.EventArgs;
import twinspire.events.DimBindingOptions;
import twinspire.render.GraphicsContext;
import twinspire.render.ComplexResult;
import twinspire.DimObjectResult;
import twinspire.DimObjectResult.DimObjectOptions;
import twinspire.Id;
import twinspire.DimSize;
import twinspire.geom.Box;
import twinspire.geom.Dim;
import twinspire.geom.DimCellSize;
import twinspire.geom.DimCellSize.DimCellSizing;
import twinspire.scenes.Scene;
import twinspire.scenes.SceneObject;
import twinspire.Application;
using twinspire.extensions.ArrayExtensions;

import kha.graphics2.Graphics;
import kha.math.FastVector2;
import kha.System;
import kha.Font;

#if assertion
import Assertion.*;
#end

enum abstract HorizontalAlign(Int) from Int to Int {
	var HALIGN_NONE				=	0;
	var HALIGN_LEFT				=	1;
	var HALIGN_MIDDLE			=	2;
	var HALIGN_RIGHT			=	3;
}

enum abstract VerticalAlign(Int) from Int to Int {
	var VALIGN_NONE				=	0;
	var VALIGN_TOP				=	1;
	var VALIGN_CENTRE			=	2;
	var VALIGN_BOTTOM			=	3;
}

enum abstract Direction(Int) {
    var Up;
    var Down;
    var Left;
    var Right;
}

enum abstract DimBehaviourFlags(Int) from Int to Int {
    /**
     * A dimension behaviour which specifies no events are to be handled by the simulation engine.
     */
    var DIM_NO_EVENTS           =   0;
    /**
     * A dimension behaviour specifying mouse movements in and out of the dimension affects the render results.
     */
    var DIM_MOUSE_EVENTS        =   0x01;
    /**
     * A dimension behaviour specifying that the mouse wheel affects the position of dimensions contained in this dimension.
     */
    var DIM_SCROLL_EVENTS       =   0x02;
}

typedef DimIndexResult = {
    var dimIndex:Int;
    var groupIndex:Int;
}

enum abstract ContainerMethods(Int) from Int to Int {
    var FLOW_FIXED      =   0;
    var FLOW_VARIABLE   =   1;
}

enum DimAlignment {
    None;
    DimVAlign(valign:VerticalAlign);
    DimHAlign(halign:HorizontalAlign);
    DimAlign(valign:VerticalAlign, halign:HorizontalAlign);
}

enum FlowSpacing {
    SpaceBetween;
    SpaceAround;
    SpaceEqual(space:Float);
}

enum DimFlow {
    FlowNone;
    FlowVertical(?maxWidth:Float, ?span:Bool, ?inverse:Bool, ?spacing:FlowSpacing);
    FlowHorizontal(?maxHeight:Float, ?span:Bool, ?inverse:Bool, ?spacing:FlowSpacing);
    FlowGrid(columns:Int, rows:Int, width:Float, height:Float);
}

enum DimInitCommand {
    CreateEmpty(then:Array<DimCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CreateOnInit(dim:Dim, init:DimInitCommand, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CentreScreenY(width:Float, height:Float, offsetY:Float, inside:Array<DimInitCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CentreScreenX(width:Float, height:Float, offsetX:Float, inside:Array<DimInitCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CentreScreenFromSize(width:Float, height:Float, inside:Array<DimInitCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CreateDimAlignScreen(width:Float, height:Float, align:DimAlignment, offset:FastVector2, inside:Array<DimInitCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CreateFromOffset(offset:FastVector2, inside:Array<DimInitCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CreateGridEquals(columns:Int, rows:Int, items:Array<DimInitCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CreateGridFloats(columns:Array<Float>, rows:Array<Float>, items:Array<DimInitCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CreateGrid(columns:Array<DimCellSize>, rows:Array<DimCellSize>, items:Array<DimInitCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CreateFixedFlow(itemSize:DimSize, dir:Direction, items:Array<DimInitCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CreateVariableFlow(dir:Direction, items:Array<DimInitCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    CreateFlowComplex(flow:DimFlow, items:Array<DimInitCommand>, ?ident:String, ?id:Id, ?bindings:DimBindingOptions);
    Reference(id:Id, ?bindings:DimBindingOptions);
}

enum DimCommand {
    ScreenAlign(align:DimAlignment, offset:FastVector2);
    Align(against:Int, align:DimAlignment, ?offset:FastVector2);
    MeasureText(text:String, font:Font, fontSize:Int);
    AddSpacingAround(space:Float);
    AddSpacing(space:Float, dir:Direction);
    Scale(scale:Float);
    ScaleX(scale:Float);
    ScaleY(scale:Float);
    Shrink(value:Float);
    ShrinkW(value:Float);
    ShrinkH(value:Float);
    Grow(value:Float);
    GrowW(value:Float);
    GrowH(value:Float);
    SpanParentWidth;
    SpanParentHeight;
}

typedef SceneMap = {
    var ?stack:Array<Array<DimObjectResult>>;
    var ?objects:Array<SceneObject>;
}

class Dimensions {

    static var dimTypes:Array<String>;
    static var dimTypesBehaviours:Array<Int>;

    static var activeGroups:Array<Int>;
    static var groups:Array<String>;
    static var groupDims:Array<Array<Dim>>;
    static var groupDimTypes:Array<Array<Int>>;
    static var groupDimNames:Array<Array<String>>;
    static var groupDimExtra:Array<Array<Dynamic>>;

    /**
     * Create a new dimensions group encapsulating all the dimensions that belong in this group.
     * @param id The name of the group.
     * @return Int
     */
    public static function createGroup(id:String):Int
    {
        if (groups == null)
        {
            groups = [];
        }

        if (groupDims == null)
        {
            groupDims = [];
        }
        groupDims.push([]);
        
        if (groupDimTypes == null)
        {
            groupDimTypes = [];
        }
        groupDimTypes.push([]);

        if (groupDimNames == null)
        {
            groupDimNames = [];
        }
        groupDimNames.push([]);

        if (groupDimExtra == null)
        {
            groupDimExtra = [];
        }
        groupDimExtra.push([]);

        return groups.push(id) - 1;
    }

    /**
     * Activate a group by a given name. If used, it is assumed that you will use `getActiveGroups()` to identify
     * what to render.
     * @param id The name of the group to activate.
     */
    public static function activateGroup(id:String)
    {
        for (i in 0...activeGroups.length)
        {
            if (activeGroups[i] == getDimGroupIndex(id))
            {
                return;
            }
        }

        activeGroups.push(getDimGroupIndex(id));
    }

    /**
     * Deactivate a group by name, preventing that group from being captured for rendering.
     * @param id The name of the group to deactivate.
     */
    public static function deactivateGroup(id:String)
    {
        var remove = -1;
        for (i in 0...activeGroups.length)
        {
            if (activeGroups[i] == getDimGroupIndex(id))
            {
                remove = i;
                break;
            }
        }

        if (remove > -1)
            activeGroups.splice(remove, 1);
    }

    /**
     * Order all dimensions of a given group by the specified order value.
     * @param id The name of the group.
     * @param order The new order value each dimension should have in this group.
     */
    public static function orderGroup(id:String, order:Int)
    {
        var index = getDimGroupIndex(id);
        if (index > -1)
        {
            var dims = groupDims[index];
            for (i in 0...dims.length)
            {
                dims[i].order = order;
            }
        }
    }

    

    /**
     * Get all currently active groups.
     * @return Array<Int>
     */
    public static function getActiveGroups():Array<Int>
    {
        return activeGroups;
    }

    /**
     * Get the index of a group of dimensions by a given name. Returns `-1` if nothing is found.
     * @param id The name of the group to find.
     * @return Int
     */
    public static function getDimGroupIndex(id:String):Int
    {
        for (i in 0...groups.length)
        {
            if (groups[i] == id)
                return i;
        }
        return -1;
    }

    /**
     * Create a new type with the given name and behaviour flags.
     * Behaviours will affect the resulting dimension statuses, whether it is active, dormant, hovered over
     * by the mouse, etc.
     * @param name The name for this type.
     * @param behaviourFlags The behaviour flags associated with this type.
     * @return Int
     */
    public static function createDimensionType(name:String, behaviourFlags:Int):Int
    {
        if (dimTypes == null)
        {
            dimTypes = [];
        }

        if (dimTypesBehaviours == null)
        {
            dimTypesBehaviours = [];
        }

        dimTypes.push(name);
        dimTypesBehaviours.push(behaviourFlags);
        return dimTypes.length - 1;
    }

    /**
     * Create a new dimension with zero values with the given type. Returns the index of the dimension
     * and the index of the currently active group.
     * @param dimType The type this dimension should use.
     * @return Int
     */
    public static function createDimensionIndex(name:String, dimType:Int, extraData:Dynamic = null):DimIndexResult
    {
        #if assertion
        assert(groupDims != null);
        #else
        if (groupDims == null)
            return null;
        #end

        var index = groupDims.length - 1;
        var dimensions = groupDims[index];
        var dimensionTypes = groupDimTypes[index];
        var dimensionNames = groupDimNames[index];

        dimensions.push(Dim.zero);
        dimensionTypes.push(dimType);
        dimensionNames.push(name);
        return {
            dimIndex: dimensions.length - 1,
            groupIndex: index
        };
    }

    /**
     * Get a dimension by a `DimIndexResult`.
     * @param indexResult A given dim index result.
     * @return Dim
     */
    public static function getDimension(indexResult:DimIndexResult):Dim
    {
        return groupDims[indexResult.groupIndex][indexResult.dimIndex];
    }

    /**
     * Get a dimension by the given group and dim name.
     * @param groupName The name of the group.
     * @param dimName The name of the dimension.
     * @return Dim
     */
    public static function getDimensionByName(groupName:String, dimName:String):Dim
    {
        var groupIndex = getDimGroupIndex(groupName);
        return getDimensionByGroupIndexAndName(groupIndex, dimName);
    }

    /**
     * Get a dimension by the given group index and dim name.
     * @param groupName The index of the group.
     * @param dimName The name of the dimension.
     * @return Dim
     */
    public static function getDimensionByGroupIndexAndName(groupIndex:Int, dimName:String):Dim
    {
        for (i in 0...groupDimNames[groupIndex].length)
        {
            if (groupDimNames[groupIndex][i] == dimName)
            {
                return groupDims[groupIndex][i];
            }
        }

        return null;
    }

    /**
     * Perform event-handling simulations on all active groups.
     * Requires use of the `GlobalEvents` class.
     */
    public static function simulateDimGroups()
    {

    }

    /**
    * command stack
    * - first index = the parent of a series of children, effectively the hierarchy
    * - second index = the children results
    **/
    static var dimCommandStack:Array<Array<DimObjectResult>>;
    /**
    * refers to the child index within a parent of the command stack, i.e.
    * [length - 1][currentParents[length - 1]] = parent of the current child
    **/ 
    static var currentParents:Array<Int>;

    /**
    * Reset the current hierarchy and clear all data.
    **/
    public static function resetConstruct() {
        dimCommandStack = [];
        currentParents = [];
    }

    /**
    * Create a hierarchy of dimensions from a single `DimInitCommand`, in which its children
    * represent a structured group of dimensions. This is particularly useful for creating
    * reusable components for complex interfaces.
    *
    * `construct` on its own just initialises a structure. To use the results of this function, `addComplex` 
    * of the `GraphicsContext` takes the constructed hierarchy and adds dimensions into the dimension stack.
    *
    * @param command The `DimInitCommand` representing the wrapping interface to contain all sub-dimensions
    * and interfaces.
    * @param level The level (or parent index) within the dimension hierarchy to begin adding dimensions to.
    * @param options (Optional) Add options specifying additional parameters for this command. 
    **/
    public static function construct(command:DimInitCommand, level:Int = 0, ?options:DimObjectOptions) {
        if (options == null) {
            options = {};
        }

        if (dimCommandStack == null) {
            dimCommandStack = [];
            currentParents = [];
        }

        switch (command) {
            case Reference(id, bindings): {
                if (mappedObjects.exists(id)) {
                    construct(mappedObjects[id], level);
                }
            }
            case CreateEmpty(then, ident, id, bindings): {
                var dim = new Dim(0, 0, 0, 0, level);
                if (level >= dimCommandStack.length - 1) {
                    currentParents.push(0);
                    dimCommandStack.push([ { originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: dim, autoSize: true, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings } ]);
                }
                else {
                    dimCommandStack[level].push({ originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: dim, autoSize: true, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings });
                    currentParents[level] = dimCommandStack[level].length - 1;
                }

                calculateDimFromCommands(then);
            }
            case CreateOnInit(dim, init, ident, id, bindings): {
                dim.order = level;
                currentParents.push(0);
                dimCommandStack.push([ { originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: dim, autoSize: false, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings } ]);

                construct(init, dimCommandStack.length - 1);
            }
            case CentreScreenY(width, height, offsetY, inside, ident, id, bindings): {
                var wrapper = centreScreenY(width, height, offsetY);
                wrapper.order = level;
                if (level >= dimCommandStack.length - 1) {
                    currentParents.push(0);
                    dimCommandStack.push([ { originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: wrapper, autoSize: false, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings } ]);
                }
                else {
                    dimCommandStack[level].push({ originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: wrapper, autoSize: false, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings });
                    currentParents[level] = dimCommandStack[level].length - 1;
                }
                
                for (o in inside) {
                    construct(o, level + 1);
                }
            }
            case CentreScreenX(width, height, offsetX, inside, ident, id, bindings): {
                var wrapper = centreScreenX(width, height, offsetX);
                wrapper.order = level;
                if (level >= dimCommandStack.length - 1) {
                    currentParents.push(0);
                    dimCommandStack.push([ { originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: wrapper, autoSize: false, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings } ]);
                }
                else {
                    dimCommandStack[level].push({ originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: wrapper, autoSize: false, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings });
                    currentParents[level] = dimCommandStack[level].length - 1;
                }
                
                for (o in inside) {
                    construct(o, level + 1);
                }
            }
            case CentreScreenFromSize(width, height, inside, ident, id, bindings): {
                var wrapper = centreScreenFromSize(width, height);
                wrapper.order = level;
                if (level >= dimCommandStack.length - 1) {
                    currentParents.push(0);
                    dimCommandStack.push([ { originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: wrapper, autoSize: false, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings } ]);
                }
                else {
                    dimCommandStack[level].push({ originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: wrapper, autoSize: false, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings });
                    currentParents[level] = dimCommandStack[level].length - 1;
                }
                
                for (o in inside) {
                    construct(o, level + 1);
                }
            }
            case CreateDimAlignScreen(width, height, align, offset, inside, ident, id, bindings): {
                var wrapper:Dim = null;
                switch (align) {
                    case None: {
                        return;
                    }
                    case DimVAlign(valign): {
                        wrapper = new Dim(0, 0, width, height);
                        screenAlignY(wrapper, valign, offset);
                    }
                    case DimHAlign(halign): {
                        wrapper = new Dim(0, 0, width, height);
                        screenAlignX(wrapper, halign, offset);
                    }
                    case DimAlign(valign, halign): {
                        wrapper = createDimAlignScreen(width, height, valign, halign, offset.x, offset.y);
                    }
                }

                wrapper.order = level;

                if (level >= dimCommandStack.length - 1) {
                    currentParents.push(0);
                    dimCommandStack.push([ { originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: wrapper, autoSize: false, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings } ]);
                }
                else {
                    dimCommandStack[level].push({ originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: wrapper, autoSize: false, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings });
                    currentParents[level] = dimCommandStack[level].length - 1;
                }
                
                for (o in inside) {
                    construct(o, level + 1);
                }
            }
            case CreateFromOffset(offset, inside, ident, id, bindings): {
                var lastItem = dimCommandStack[dimCommandStack.length - 1][currentParents[currentParents.length - 1]];

                var wrapper = createFromOffset(lastItem.dim, offset);
                wrapper.order = level;
                dimCommandStack[dimCommandStack.length - 1].push({ originalCommand: command, parentIndex: getParentIndex(), ident: ident ?? "", dim: wrapper, autoSize: false, clipped: options.forceClipping ?? false, id: id, requestedContainer: options.makeContainer ?? false, bindings: bindings });
                currentParents[dimCommandStack.length - 1] += 1;
                
                for (o in inside) {
                    construct(o, level + 1);
                }
            }
            case CreateGridEquals(columns, rows, items, ident, id, bindings): {

            }
            default: {

            }
        }
    }

    static var mappedScenes:Map<String, SceneMap>;
    public static var mappedObjects:Map<Id, DimInitCommand>;

    public static function setObjectDimInit(id:Id, init:DimInitCommand) {
        if (mappedObjects == null) {
            mappedObjects = [];
        }

        if (!mappedObjects.exists(id)) {
            mappedObjects[id] = init;
        }
    }

    public static function mapToScene(scene:Scene) {
        if (mappedScenes == null) {
            mappedScenes = [];
        }

        mappedScenes[scene.name] = {
            stack: dimCommandStack.copy()                
        };
    }

    public static function initScene(scene:Scene) {
        if (mappedObjects == null) {
            mappedObjects = [];
        }

        if (!mappedScenes.exists(scene.name)) {
            throw "initScene being used without using mapToScene first.";
        }

        var stack = mappedScenes[scene.name].stack;
        var objects = new Array<SceneObject>();
        for (i in 0...stack.length) {
            for (j in 0...stack[i].length) {
                var obj = new DimObject();
                obj.index = stack[i][j].resultIndex;
                obj.type = stack[i][j].id;
                obj.targetContainer = stack[i][j].dim;
                if (mappedObjects.exists(obj.type)) {
                    obj.initCommand = mappedObjects[obj.type];
                }
                else {
                    obj.initCommand = stack[i][j].originalCommand;
                }

                obj.dimObjectResult = stack[i][j];
                if (obj.dimObjectResult.bindings != null) {
                    var updateCtx = Application.instance.updateCtx;
                    if (obj.dimObjectResult.bindings.onBeginDrag != null) {
                        updateCtx.addEventListener(obj.index, ACTIVITY_DRAG_START, obj.dimObjectResult.bindings.onBeginDrag);
                    }

                    if (obj.dimObjectResult.bindings.onDragging != null) {
                        updateCtx.addEventListener(obj.index, ACTIVITY_DRAGGING, obj.dimObjectResult.bindings.onDragging);
                    }

                    if (obj.dimObjectResult.bindings.onEndDrag != null) {
                        updateCtx.addEventListener(obj.index, ACTIVITY_DRAG_END, obj.dimObjectResult.bindings.onEndDrag);
                    }

                    if (obj.dimObjectResult.bindings.onKeyDown != null) {
                        updateCtx.addEventListener(obj.index, ACTIVITY_KEY_DOWN, obj.dimObjectResult.bindings.onKeyDown);
                    }

                    if (obj.dimObjectResult.bindings.onKeyPress != null) {
                        updateCtx.addEventListener(obj.index, ACTIVITY_KEY_ENTER, obj.dimObjectResult.bindings.onKeyPress);
                    }

                    if (obj.dimObjectResult.bindings.onKeyUp != null) {
                        updateCtx.addEventListener(obj.index, ACTIVITY_KEY_UP, obj.dimObjectResult.bindings.onKeyUp);
                    }

                    if (obj.dimObjectResult.bindings.onMouseDown != null) {
                        updateCtx.addEventListener(obj.index, ACTIVITY_MOUSE_DOWN, obj.dimObjectResult.bindings.onMouseDown);
                    }

                    if (obj.dimObjectResult.bindings.onMouseOver != null) {
                        updateCtx.addEventListener(obj.index, ACTIVITY_MOUSE_OVER, obj.dimObjectResult.bindings.onMouseOver);
                    }

                    if (obj.dimObjectResult.bindings.onClick != null) {
                        if (obj.dimObjectResult.bindings.togglePath != null) {
                            var pathObject = findItemByName(obj.dimObjectResult.bindings.togglePath);
                            updateCtx.addEventListener(obj.index, ACTIVITY_MOUSE_CLICKED, function(e:EventArgs) {
                                updateCtx.toggleVisibility(pathObject.resultIndex);
                                obj.dimObjectResult.bindings.onClick(e);
                            });
                        }
                        else {
                            updateCtx.addEventListener(obj.index, ACTIVITY_MOUSE_CLICKED, obj.dimObjectResult.bindings.onClick);
                        }
                    }
                }

                objects.push(obj);
            }
        }

        mappedScenes[scene.name].objects = objects;
        scene.init(Application.instance.graphicsCtx, objects);
    }


    static var _lookupParent:Int;
    static var _lookupChild:Int;

    /**
    * Begin collecting dim object results by resetting the lookup position to zero.
    **/
    public static function begin() {
        _lookupParent = 0;
        _lookupChild = 0;
    }

    /**
    * Advance the position to the next dim object result.
    *
    * @return Returns `false` if there is no more to advance.
    **/
    public static function next() {
        if (dimCommandStack.length == 0) {
            return false;
        }

        if (dimCommandStack[_lookupParent].length > 0 && _lookupChild + 1 < dimCommandStack[_lookupParent].length) {
            _lookupChild += 1;
            return true;
        }
        else {
            if (_lookupParent + 1 >= dimCommandStack.length) {
                _lookupParent = 0;
                _lookupChild = 0;
                return false;
            }
            else {
                _lookupParent += 1;
                _lookupChild = 0;
                return true;
            }
        }

        return false;
    }

    /**
    * Gets the current lookup item.
    **/
    public static function getLookupItem() {
        return dimCommandStack[_lookupParent][_lookupChild];
    }

    /**
    * Finds an item by a given name. To lookup items in the hierarchy, use `/` to separate
    * each level within the hierarchy.
    *
    * @param name The name or path of an item to find in the constructed hierarchy.
    *
    * @return A `DimObjectResult` of the found item. `null` otherwise.
    **/
    public static function findItemByName(name:String) {
        var splitted = name.split("/");
        var indexFinds = new Array<Int>();
        var found = true;
        var currentParentIndex = -1;
        var currentParent:DimObjectResult = null;
        for (i in 0...splitted.length) {
            var name = splitted[i];
            var index = getChildIndexFromParent(name, i, currentParentIndex);
            if (index > -1) {
                currentParent = dimCommandStack[i][index];
                currentParentIndex = index;
            }

            if (currentParentIndex == -1) {
                found = false;
                break;
            }

            if (i == splitted.length - 1) {
                return currentParent;
            }
        }

        return null;
    }

    /**
    * Gets a collection of items where the given name contains children
    * within the dimension hierarchy.
    *
    * @param name The name or path of an item to find in the constructed hierarchy.
    *
    * @return An `Array<DimObjectResult>` or `null`.
    **/
    public static function findItemsByParentName(name:String) {
        var item = findItemByName(name);
        if (item != null) {
            return dimCommandStack[item.parentIndex];
        }

        return null;
    }

    /**
    * Find an item by name within a collection of items from the given `parentIndex`.
    *
    * @param parentIndex The parent index to search.
    * @param name The name or path to find.
    *
    * @return The `DimObjectResult` or `null`.
    **/
    public static function findInItemsByName(parentIndex:Int, name:String) {
        var item = dimCommandStack[parentIndex].find((fc) -> fc.ident == name);
        return item;
    }

    static function childExists(name:String, level:Int) {
        if (level < 0 || level > dimCommandStack.length - 1) {
            return false;
        }

        return dimCommandStack[level].findIndex((dc) -> dc.ident == name) > -1;
    }

    static function getChildIndexFromParent(name:String, level:Int, parent:Int) {
        var result = childExists(name, level);
        if (result) {
            return dimCommandStack[level].findIndex((dc) -> dc.parentIndex == parent);
        }

        return -1;
    }

    static function calculateDimFromCommands(commands:Array<DimCommand>, ?level:Int) {
        var lastItem = dimCommandStack[level ?? dimCommandStack.length - 1][currentParents[level ?? dimCommandStack.length - 1]];
        for (command in commands) {
            processDimCommand(lastItem.dim, command, level);
        }

        if (dimCommandStack.length - 1 > 0) {
            calculateParentDim(level ?? dimCommandStack.length - 1);
        }
    }

    static function processDimCommand(dim:Dim, command:DimCommand, ?level:Int) {
        var lastItem = dimCommandStack[level ?? dimCommandStack.length - 1][currentParents[level ?? dimCommandStack.length - 1]];

        switch (command) {
            case MeasureText(text, font, fontSize): {
                var textSize = getTextDim(font, fontSize, text);
                lastItem.textDim = textSize;

                dim.width += textSize.width;
                dim.height += textSize.height;
            }
            case AddSpacingAround(space): {
                if (lastItem.textDim != null) {
                    lastItem.textDim.x += space;
                    lastItem.textDim.y += space;
                    lastItem.textDim.width -= space;
                    lastItem.textDim.height -= space;
                }

                dim.x += space;
                dim.y += space;
                dim.width -= space;
                dim.height -= space;
            }
            case AddSpacing(space, dir): {
                switch (dir) {
                    case Down: {
                        if (lastItem.textDim != null) {
                            lastItem.textDim.height -= space;
                        }
                        
                        dim.height -= space;
                    }
                    case Left: {
                        if (lastItem.textDim != null) {
                            lastItem.textDim.x += space;
                        }

                        dim.x += space;
                    }
                    case Right: {
                        if (lastItem.textDim != null) {
                            lastItem.textDim.width -= space;
                        }

                        dim.width -= space;
                    }
                    case Up: {
                        if (lastItem.textDim != null) {
                            lastItem.textDim.y += space;
                        }

                        dim.y += space;
                    }
                }
            }
            case Scale(scale): {
                dimScale(dim, scale, scale);
                if (lastItem.textDim != null) {
                    dimScale(lastItem.textDim, scale, scale);
                }
            }
            case ScaleX(scale): {
                dimScaleX(dim, scale);
                if (lastItem.textDim != null) {
                    dimScaleX(lastItem.textDim, scale);
                }
            }
            case ScaleY(scale): {
                dimScaleY(dim, scale);
                if (lastItem.textDim != null) {
                    dimScaleY(lastItem.textDim, scale);
                }
            }
            case Shrink(value): {
                if (lastItem.textDim != null) {
                    lastItem.textDim.x = dim.x;
                    lastItem.textDim.y = dim.y;
                    lastItem.textDim.x -= dim.x + value / 2;   
                    lastItem.textDim.y -= dim.y + value / 2;
                }

                dimShrink(dim, value);
            }
            case ShrinkW(value): {
                if (lastItem.textDim != null) {
                    lastItem.textDim.x = dim.x;
                    lastItem.textDim.x -= dim.x + value / 2;   
                }

                dimShrinkW(dim, value);
            }
            case ShrinkH(value): {
                if (lastItem.textDim != null) {
                    lastItem.textDim.y = dim.y;
                    lastItem.textDim.y -= dim.y + value / 2;
                }

                dimShrinkH(dim, value);
            }
            case Grow(value): {
                if (lastItem.textDim != null) {
                    lastItem.textDim.x = dim.x;
                    lastItem.textDim.y = dim.y;
                    lastItem.textDim.x += dim.x + value / 2;   
                    lastItem.textDim.y += dim.y + value / 2;
                }

                dimGrow(dim, value);
            }
            case GrowW(value): {
                if (lastItem.textDim != null) {
                    lastItem.textDim.x = dim.x;
                    lastItem.textDim.x += dim.x + value / 2;   
                }

                dimGrowW(dim, value);
            }
            case GrowH(value): {
                if (lastItem.textDim != null) {
                    lastItem.textDim.y = dim.y;
                    lastItem.textDim.y += dim.y + value / 2;
                }

                dimGrowH(dim, value);
            }
            case Align(against, align, offset): {
                var dimItems = dimCommandStack[currentParents[currentParents.length - 1]];
                if (against > dimItems.length - 1) {
                    return;
                }

                var againstDim:Dim = getParentDim();
                var isOffset = offset != null;
                
                switch (align) {
                    case DimVAlign(valign): {
                        if (isOffset) {
                            dimVAlignOffset(againstDim, dim, valign, offset.y);
                            if (lastItem.textDim != null) {
                                dimVAlignOffset(againstDim, lastItem.textDim, valign, offset.y);
                            }
                        }
                        else {
                            dimVAlign(againstDim, dim, valign);
                            if (lastItem.textDim != null) {
                                dimVAlign(againstDim, lastItem.textDim, valign);
                            }
                        }
                    }
                    case DimHAlign(halign): {
                        if (isOffset) {
                            dimHAlignOffset(againstDim, dim, halign, offset.x);
                            if (lastItem.textDim != null) {
                                dimHAlignOffset(againstDim, lastItem.textDim, halign, offset.x);
                            }
                        }
                        else {
                            dimHAlign(againstDim, dim, halign);
                            if (lastItem.textDim != null) {
                                dimHAlign(againstDim, lastItem.textDim, halign);
                            }
                        }
                    }
                    case DimAlign(valign, halign): {
                        if (isOffset) {
                            dimAlignOffset(againstDim, dim, halign, valign, offset.x, offset.y);
                            if (lastItem.textDim != null) {
                                dimAlignOffset(againstDim, lastItem.textDim, halign, valign, offset.x, offset.y);
                            }
                        }
                        else {
                            dimAlign(againstDim, dim, valign, halign);
                            if (lastItem.textDim != null) {
                                dimAlign(againstDim, lastItem.textDim, valign, halign);
                            }
                        }
                    }
                    default: {

                    }
                }
            }
            case ScreenAlign(align, offset): {
                switch (align) {
                    case DimVAlign(valign): {
                        screenAlignY(dim, valign, offset);
                    }
                    case DimHAlign(halign): {
                        screenAlignX(dim, halign, offset);
                    }
                    case DimAlign(valign, halign): {
                        dim = createDimAlignScreen(dim.width, dim.height, valign, halign, offset.x, offset.y);
                    }
                    default: {

                    }
                }
            }
            case SpanParentWidth: {
                var parent = getParentDim();
                dim.x = parent?.x;
                dim.width = parent?.width;
            }
            case SpanParentHeight: {
                var parent = getParentDim();
                dim.y = parent.y;
                dim.height = parent.height;
            }
        }
    }

    static function calculateParentDim(level:Int) {
        if (level < 1 || level > dimCommandStack.length - 1) {
            return;
        }

        var parent = dimCommandStack[level - 1][currentParents[level - 1]];
        while (level > -1 && parent.autoSize) {
            for (item in dimCommandStack[level]) {
                parent.dim.width = Math.max(parent.dim.width, item.dim.x + item.dim.width);
                parent.dim.height = Math.max(parent.dim.height, item.dim.y + item.dim.height);
            }

            level -= 1;
            if (level < 1) {
                break;
            }

            parent = dimCommandStack[level - 1][currentParents[level - 1]];
        }
    }

    static function getParentDim() {
        var parent = getParent();
        return parent?.dim;
    }

    static function getParent() {
        if (currentParents.length > 1) {
            return dimCommandStack[dimCommandStack.length - 2][currentParents[currentParents.length - 2]];
        }
        else {
            return null;
        }
    }

    static function getParentIndex() {
        if (currentParents.length > 1) {
            return currentParents[currentParents.length - 2];
        }

        return -1;
    }

    

    /**
	 * Create a dimension block from the given width and height, centering in the middle of the screen.
	 * @param width The width of the object to centre.
	 * @param height The height of the object to centre.
	 */
	public static function centreScreenFromSize(width:Float, height:Float) {
        var x = (System.windowWidth() - width) / 2;
        var y = (System.windowHeight() - height) / 2;
        return new Dim(x, y, width, height);
    }

    /**
     * Create a dimension block from the given width and given offset on the Y-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetY The offset from the top of the screen.
     */
    public static function centreScreenY(width:Float, height:Float, offsetY:Float) {
        var x = (System.windowWidth() - width) / 2;
        return new Dim(x, offsetY, width, height);
    }

    /**
     * Create a dimension block from the given width and given offset on the X-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetX The offset from the left of the screen.
     */
    public static function centreScreenX(width:Float, height:Float, offsetX:Float) {
        var y = (System.windowHeight() - height) / 2;
        return new Dim(offsetX, y, width, height);
    }

    /**
     * 
     * @param width 
     * @param height 
     * @param offsetX 
     * @param offsetY 
     */
    public static function createDimAlignScreen(width:Float, height:Float, valign:VerticalAlign, halign:HorizontalAlign, offsetX:Float, offsetY:Float) {
        var x = 0.0;
        var y = 0.0;
        if (valign == VALIGN_TOP)
        {
            y += offsetY;
        }
        else if (valign == VALIGN_CENTRE)
        {
            y = (System.windowHeight() - height) / 2;
            y += offsetY;
        }
        else if (valign == VALIGN_BOTTOM)
        {
            y = System.windowHeight() - height;
            y -= offsetY;
        }

        if (halign == HALIGN_LEFT)
        {
            x = offsetX;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            x = (System.windowWidth() - width) / 2;
            x += offsetX;
        }
        else if (halign == HALIGN_RIGHT)
        {
            x = System.windowWidth() - width;
            x -= offsetX;
        }

        return new Dim(x, y, width, height);
    }

    /**
    * Create a new dimension offset from an existing dimension.
    *
    * @param from The dim to reference.
    * @param offset The offset value from the given dimension.
    **/
    public static function createFromOffset(from:Dim, offset:FastVector2) {
        return new Dim(from.x + offset.x, from.y + offset.y, from.width, from.height, from.order);
    }

    /**
     * Create a dimension block from the given width and given offset on the Y-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetY The offset from the top of the screen.
     */
    public static function centreBufferY(width:Float, height:Float, offsetY:Float) {
        var x = (Application.getBufferSize().x - width) / 2;
        return new Dim(x, offsetY, width, height);
    }

    /**
     * Align the given dimension along the x-axis of the current game client.
     * @param a The dimension.
     * @param halign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static inline function screenAlignX(a:Dim, halign:Int, offset:FastVector2) {
        if (halign == HALIGN_LEFT)
        {
            a.x = offset.x;
            a.y = offset.y;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            a = centreScreenY(a.width, a.height, offset.y);
            a.x = offset.x;
        }
        else if (halign == HALIGN_RIGHT)
        {
            a.x = System.windowWidth() - a.width - offset.x;
            a.y = offset.y;
        }
    }

    /**
     * Align the given dimension along the y-axis of the current game client.
     * @param a The dimension.
     * @param valign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static inline function screenAlignY(a:Dim, valign:Int, offset:FastVector2) {
        if (valign == VALIGN_TOP)
        {
            a.x = offset.x;
            a.y = offset.y;
        }
        else if (valign == VALIGN_CENTRE)
        {
            a = centreScreenX(a.width, a.height, offset.x);
        }
        else if (valign == VALIGN_BOTTOM)
        {
            a.y = System.windowHeight() - a.height - offset.y;
            a.x = System.windowHeight() - a.width - offset.x;
        }
    }

    /**
     * Align the given dimension along the x-axis of the current back buffer.
     * @param a The dimension.
     * @param halign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static inline function bufferAlignX(a:Dim, halign:Int, offset:FastVector2) {
        if (halign == HALIGN_LEFT)
        {
            a.x = offset.x;
            a.y = offset.y;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            a = centreBufferY(a.width, a.height, offset.y);
            a.x = offset.x;
        }
        else if (halign == HALIGN_RIGHT)
        {
            a.x = Application.getBufferSize().x - a.width - offset.x;
            a.y = offset.y;
        }
    }

    /**
     * Align the given dimension along the y-axis of the current back buffer.
     * @param a The dimension.
     * @param valign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static inline function bufferAlignY(a:Dim, valign:Int, offset:FastVector2) {
        if (valign == VALIGN_TOP)
        {
            a.x = offset.x;
            a.y = offset.y;
        }
        else if (valign == VALIGN_CENTRE)
        {
            a = centreBufferX(a.width, a.height, offset.x);
        }
        else if (valign == VALIGN_BOTTOM)
        {
            a.y = Application.getBufferSize().y - a.height - offset.y;
            a.x = Application.getBufferSize().y - a.width - offset.x;
        }
    }

    /**
     * Create a series of dimensions representing a grid, with each column and row of 
     * equal width and height proportionate to the number of given columns and rows to the container.
     * @param container The container dimension to create the grid from.
     * @param columns The number of equally sized columns.
     * @param rows The number of equally sized rows.
     */
    public static function dimGridEquals(container:Dim, columns:Int, rows:Int):Array<Dim> {
        var cellWidth = container.width / columns;
        var cellHeight = container.height / rows;
        var results = [];

        for (c in 0...columns)
        {
            for (r in 0...rows)
            {
                results.push(new Dim(c * cellWidth + container.x, r * cellHeight + container.y, cellWidth, cellHeight));
            }
        }

        return results;
    }

    /**
     * Create a series of dimensions representing a grid, containing specific ratios for each set of columns and rows based on the size of the given container.
     * @param container The container dimension to create the grid from.
     * @param columns An array representing the ratios for the columns in the grid.
     * @param rows An array representing the ratios for the rows in the grid.
     */
    public static function dimGridFloats(container:Dim, columns:Array<Float>, rows:Array<Float>):Array<Dim> {
        var results = [];
        var startY = 0.0;
        for (r in 0...rows.length)
        {
            var cellHeight = container.height * rows[r];
            var startX = 0.0;
            for (c in 0...columns.length)
            {
                var cellWidth = container.width * columns[c];
                results.push(new Dim(startX + container.x, startY + container.y, cellWidth, cellHeight));
                startX += cellWidth;
            }

            startY += cellHeight;
        }
        return results;
    }

    /**
     * Create a series of dimensions representing a grid, using the specific given columns and rows with varying size methods.
     * Any cell sizes with the method `DIM_SIZING_PIXELS` are calculated first, and the remaining width or height of the
     * column or row is then used to determine any sizes with the method `DIM_SIZING_PERCENT`. Any pixel sizes that
     * are greater than the width or height of the given container will supersede any provided percentage sizes.
     * @param container The container dimension to create the grid from.
     * @param columns An array of column sizes.
     * @param rows An array of row sizes.
     */
    public static function dimGrid(container:Dim, columns:Array<DimCellSize>, rows:Array<DimCellSize>):Array<Dim> {
        var totalPreciseWidth = 0.0;
        var totalPreciseHeight = 0.0;
        for (c in columns)
        {
            if (c.sizing == DIM_SIZING_PIXELS)
                totalPreciseWidth += c.value;
        }

        for (r in rows)
        {
            if (r.sizing == DIM_SIZING_PIXELS)
                totalPreciseHeight += r.value;
        }

        var remainingWidth = container.width - totalPreciseWidth;
        var remainingHeight = container.height - totalPreciseHeight;
        var contentWidth = totalPreciseWidth;
        var contentHeight = totalPreciseHeight;

        for (c in columns)
        {
            if (c.sizing == DIM_SIZING_PERCENT)
                contentWidth += (c.value * remainingWidth);
        }

        for (r in rows)
        {
            if (r.sizing == DIM_SIZING_PERCENT)
                contentHeight += (r.value * remainingHeight);
        }

        var contentX = ((container.width - contentWidth) / 2) + container.x;
        var contentY = ((container.height - contentHeight) / 2) + container.y;

        var results = [];

        var startY = contentY;
        for (r in rows)
        {
            var y = 0.0;
            var height = 0.0;

            if (r.sizing == DIM_SIZING_PERCENT)
            {
                height = (r.value * remainingHeight);
                y = startY;
                startY += height;
            }
            else if (r.sizing == DIM_SIZING_PIXELS)
            {
                y = startY;
                height = r.value;
                startY += height;
            }

            var startX = contentX;
            for (c in columns)
            {
                var x = 0.0;
                var width = 0.0;
                
                if (c.sizing == DIM_SIZING_PERCENT)
                {
                    width = (c.value * remainingWidth);
                    x = startX;
                    startX += width;
                }
                else if (c.sizing == DIM_SIZING_PIXELS)
                {
                    x = startX;
                    width = c.value;
                    startX += width;
                }

                results.push(new Dim(x, y, width, height));
            }
        }

        return results;
    }

    public static function dimMultiCellSize(cellSize:DimCellSize, count:Int):Array<DimCellSize> {
        var results = [];
        for (i in 0...count)
            results.push({ value: cellSize.value, sizing: cellSize.sizing });
        return results;
    }

    static var containerColumnOrRow:Dim;
    static var containerDirection:Int;
    static var containerCellSize:Dim;
    static var containerCell:Int;
    static var containerMethod:Int;

    /**
     * Create a dimension column, within which each time the function `getNewDim` is called,
     * a row is created within this column below the last row created.
     * @param container The container to use for creating new rows.
     * @param size The dim of each cell.
     * @param direction 1 for up, 2 for down, 3 for left, 4 for right
     */
    public static function dimFixedFlow(container:Dim, size:Dim, direction:Int) {
        containerColumnOrRow = container;
        containerCellSize = size;
        containerDirection = direction;
        containerMethod = FLOW_FIXED;
        containerCell = 0;
    }

    /**
     * 
     * @param container The container to use for creating new rows.
     * @param height The height of each row.
     * @param direction 1 for up, 2 for down, 3 for left, 4 for right
     */
    public static function dimVariableFlow(container:Dim, direction:Int) {
        containerColumnOrRow = container;
        containerDirection = direction;
        containerMethod = FLOW_VARIABLE;
        containerCellSize = new Dim(0, 0, 0, 0);
        containerCell = 0;
    }

    public static function dimVariableSetNextDim(dim:Dim) {
        if (containerMethod == FLOW_VARIABLE)
            containerCellSize = dim.clone();
    }

    public static function getNewDim(padding:Float = 0) {
        if (containerColumnOrRow != null && containerDirection > 0 && containerCellSize != null)
        {
            var x = containerColumnOrRow.getX();
            var y = containerColumnOrRow.getY();
            var width = containerColumnOrRow.getWidth();
            var height = containerColumnOrRow.getHeight();
            if (containerDirection == 1)
            {
                if (containerMethod == FLOW_FIXED)
                    y -= (containerCellSize.height * containerCell) - padding;
                else if (containerMethod == FLOW_VARIABLE)
                    y -= containerCellSize.height - padding;

                height = containerCellSize.height;
            }
            else if (containerDirection == 2)
            {
                if (containerMethod == FLOW_FIXED)
                    y += (containerCellSize.height * containerCell) + padding;
                else if (containerMethod == FLOW_VARIABLE)
                    y += containerCellSize.height + padding;

                height = containerCellSize.height;
            }
            else if (containerDirection == 3)
            {
                if (containerMethod == FLOW_FIXED)
                    x -= (containerCellSize.width * containerCell) - padding;
                else if (containerMethod == FLOW_VARIABLE)
                    x -= containerCellSize.width - padding;

                width = containerCellSize.width;
            }
            else if (containerDirection == 4)
            {
                if (containerMethod == FLOW_FIXED)
                    x += (containerCellSize.width * containerCell) + padding;
                else if (containerMethod == FLOW_VARIABLE)
                    x += containerCellSize.width + padding;

                width = containerCellSize.width;
            }

            containerCell += 1;
            return new Dim(x, y, width, height);
        }

        return null;
    }

    /**
     * Create a dimension block from the given width and given offset on the X-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetX The offset from the top of the screen.
     */
    public static function centreBufferX(width:Float, height:Float, offsetX:Float) {
        var y = (Application.getBufferSize().y - height) / 2;
        return new Dim(offsetX, y, width, height);
    }

    /**
     * Create a new dimension from an existing dimension, offsetting by the value of x as a margin from the given dimension.
     * If `offsetX` is less than `0`, then the new dimension will appear on the left of the new dimension, rather than the right.
     * If `offsetX` is equal to `0`, the new dimension will be to the right with no margin.
     * @param a The current dimension to use.
     * @param offsetX The value to offset the new dimension.
     */
    public static function dimOffsetX(a:Dim, offsetX:Float) {
        if (offsetX >= 0)
            return new Dim(a.x + a.width + offsetX, a.y, a.width, a.height);
        else if (offsetX < 0)
            return new Dim(a.x - a.width - offsetX, a.y, a.width, a.height);
        
        return null;
    }

    /**
     * Create a new dimension from an existing dimension, offsetting by the value of y as a margin from the given dimension.
     * If `offsetY` is less than `0`, then the new dimension will appear above the new dimension, rather than below.
     * If `offsetY` is equal to `0`, the new dimension will be below with no margin.
     * @param a The current dimension to use.
     * @param offsetY The value to offset the new dimension.
     */
    public static function dimOffsetY(a:Dim, offsetY:Float) {
        if (offsetY >= 0)
            return new Dim(a.x, a.y + a.height + offsetY, a.width, a.height);
        else if (offsetY < 0)
            return new Dim(a.x, a.y - a.height - offsetY, a.width, a.height);

        return null;
    }

    /**
     * Aligns dimension `b` to `a`, with the given alignment options. If both alignment values are set to CENTRE/MIDDLE, `b` will effectively be centred to `a`.
     * @param a The first dimension.
     * @param b The second dimension.
     * @param valign The vertical alignment `b` should be to `a`.
     * @param halign The horizontal alignment `b` should be to `a`.
     */
    public static inline function dimAlign(a:Dim, b:Dim, valign:Int, halign:Int) {
        dimVAlign(a, b, valign);
        dimHAlign(a, b, halign);
    }

    /**
     * Aligns dimension `b` to `a` on the Y-axis using the given vertical alignment.
     * @param a The first dimension.
     * @param b The second dimension.
     * @param valign The vertical alignment `b` should be to `a`.
     */
    public static inline function dimVAlign(a:Dim, b:Dim, valign:Int) {
        if (valign == VALIGN_TOP)
        {
            b.y = a.y;
        }
        else if (valign == VALIGN_BOTTOM)
        {
            b.y = a.y + a.height - b.height;
        }
        else if (valign == VALIGN_CENTRE)
        {
            b.y = a.y + ((a.height - b.height) / 2);
        }
    }

    /**
     * Aligns dimension `b` to `a` on the X-axis using the given horizontal alignment.
     * @param a The first dimension.
     * @param b The second dimension.
     * @param valign The horizontal alignment `b` should be to `a`.
     */
    public static inline function dimHAlign(a:Dim, b:Dim, halign:Int) {
        if (halign == HALIGN_LEFT)
        {
            b.x = a.x;
        }
        else if (halign == HALIGN_RIGHT)
        {
            b.x = a.x + a.width - b.width;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            b.x = a.x + ((a.width - b.width) / 2);
        }
    }

    public static inline function dimAlignOffset(a:Dim, b:Dim, halign:Int, valign:Int, hoffset:Float = 0.0, voffset:Float = 0.0) {
        dimVAlignOffset(a, b, valign, voffset);
        dimHAlignOffset(a, b, halign, hoffset);
    }

    public static inline function dimVAlignOffset(a:Dim, b:Dim, valign:Int, offset:Float = 0.0) {
        if (valign == VALIGN_TOP)
        {
            b.y = a.y - b.height - offset;
        }
        else if (valign == VALIGN_BOTTOM)
        {
            b.y = a.y + a.height + offset;
        }
        else if (valign == VALIGN_CENTRE)
        {
            b.y = a.y - ((b.height - a.height) / 2);
        }
    }

    public static inline function dimHAlignOffset(a:Dim, b:Dim, halign:Int, offset:Float = 0.0) {
        if (halign == HALIGN_LEFT)
        {
            b.x = a.x - b.width - offset;
        }
        else if (halign == HALIGN_RIGHT)
        {
            b.x = a.x + a.width + offset;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            b.x = a.x - ((b.width - a.width) / 2);
        }
    }

    /**
     * Scale a given dimension along the X-Axis and Y-Axis and return a new dimension with the results.
     * @param a The dimension to scale.
     * @param scaleX How much to scale, as a percentage (0-1), along the X-Axis.
     * @param scaleY How much to scale, as a percentage (0-1), along the Y-Axis.
     */
    public static inline function dimScale(a:Dim, scaleX:Float, scaleY:Float) {
        var ratioWidth = a.width * scaleX;
        var ratioX = a.x + ((a.width - ratioWidth) / 2);
        var ratioHeight = a.height * scaleY;
        var ratioY = a.y + ((a.height - ratioHeight) / 2);
        a.x = ratioX;
        a.y = ratioY;
        a.width = ratioWidth;
        a.height = ratioHeight;
    }

    /**
     * Scale a given dimension along the X-Axis and return a new dimension with the results.
     * @param a The dimension to scale.
     * @param scaleX How much to scale, as a percentage (0-1), along the X-Axis.
     */
    public static inline function dimScaleX(a:Dim, scaleX:Float) {
        var ratioWidth = a.width * scaleX;
        var ratioX = a.x + ((a.width - ratioWidth) / 2);
        a.x = ratioX;
        a.width = ratioWidth;
    }

    /**
     * Scale a given dimension along the Y-Axis and return a new dimension with the results.
     * @param a The dimension to scale.
     * @param scaleY How much to scale, as a percentage (0-1), along the Y-Axis.
     */
    public static inline function dimScaleY(a:Dim, scaleY:Float) {
        var ratioHeight = a.height * scaleY;
        var ratioY = a.y + ((a.height - ratioHeight) / 2);
        a.y = ratioY;
        a.height = ratioHeight;
    }

    /**
    * Shrink the given dimension by an `amount` in pixels.
    **/
    public static inline function dimShrink(a:Dim, amount:Float) {
        a.width = a.width - amount;
        a.height = a.height - amount;
    }

    /**
    * Shrink the width of a given dimension by an `amount` in pixels.
    **/
    public static inline function dimShrinkW(a:Dim, amount:Float) {
        a.width = a.width - amount;
    }

    /**
    * Shrink the height of a given dimension by an `amount` in pixels.
    **/
    public static inline function dimShrinkH(a:Dim, amount:Float) {
        a.height = a.height - amount;
    }

    /**
    * Grow the given dimension by an `amount` in pixels.
    **/
    public static inline function dimGrow(a:Dim, amount:Float) {
        a.width = a.width + amount;
        a.height = a.height + amount;
    }

    /**
    * Grow the width of a given dimension by an `amount` in pixels.
    **/
    public static inline function dimGrowW(a:Dim, amount:Float) {
        a.width = a.width + amount;
    }

    /**
    * Grow the height of a given dimension by an `amount` in pixels.
    **/
    public static inline function dimGrowH(a:Dim, amount:Float) {
        a.height = a.height + amount;
    }

    /**
     * Measure the width and height of the given text with font and fontSize parameters provided by
     * the given `g2` instance.
     * @param font The instance of a font to measure against.
     * @param fontSize The size of the font.
     * @param text The text to measure.
     */
    public static function getTextDim(font:Font, fontSize:Int, text:String)
	{
		return new Dim(0, 0, font.width(fontSize, text), font.height(fontSize));
	}

}