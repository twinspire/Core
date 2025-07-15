package twinspire;

import twinspire.DimSize;
import twinspire.geom.Box;
import twinspire.geom.Dim;
import twinspire.geom.DimCellSize;
import twinspire.geom.DimCellSize.DimCellSizing;
import twinspire.Application;

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
    CreateEmpty(then:Array<DimCommand>);
    CreateOnInit(dim:Dim, init:DimInitCommand);
    CentreScreenY(width:Float, height:Float, offsetY:Float, inside:Array<DimInitCommand>);
    CentreScreenX(width:Float, height:Float, offsetX:Float, inside:Array<DimInitCommand>);
    CentreScreenFromSize(width:Float, height:Float, inside:Array<DimInitCommand>);
    CreateDimAlignScreen(width:Float, height:Float, align:DimAlignment, offset:FastVector2, inside:Array<DimInitCommand>);
    CreateFromOffset(offset:FastVector2, inside:Array<DimInitCommand>);
    CreateGridEquals(columns:Int, rows:Int, items:Array<DimInitCommand>);
    CreateGridFloats(columns:Array<Float>, rows:Array<Float>, items:Array<DimInitCommand>);
    CreateGrid(columns:Array<DimCellSize>, rows:Array<DimCellSize>, items:Array<DimInitCommand>);
    CreateFixedFlow(itemSize:DimSize, dir:Direction, items:Array<DimInitCommand>);
    CreateVariableFlow(dir:Direction, items:Array<DimInitCommand>);
    CreateFlowComplex(flow:DimFlow, items:Array<DimInitCommand>);
}

enum DimCommand {
    ScreenAlign(align:DimAlignment, offset:FastVector2);
    Align(align:DimAlignment, offset:FastVector2);
    MeasureText(text:String, font:Font, fontSize:Int);
    AddSpacingAround(space:Float);
    AddSpacing(space:Float, dir:Float);
    Scale(scale:Float);
    ScaleX(scale:Float);
    ScaleY(scale:Float);
    Shrink(value:Float);
    ShrinkW(value:Float);
    ShrinkH(value:Float);
    Grow(value:Float);
    GrowW(value:Float);
    GrowH(value:Float);
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
    * Construct a series of dimensions from a `DimMap`, represented by a `Map<String, DimObject>`. All
    * positions and sizes are automatically calculated and an object of `Map<String, DimObjectResult>` is returned
    * with the resulting `DimIndex` values.
    **/
    public static function construct(items:DimMap, startPos:FastVector2, order:Int = -1) {
        var results:Map<String, DimObjectResult> = [];
        for (k => v in items) {
            var data = calculate(v, startPos, order);
            for (childK => childV in data) {
                var childName = '/${childK}';
                if (childK == "parent") {
                    childName = "";
                }

                var name = '${k}${childK}';
                results[name] = childV;
            }
        }
        return results;
    }

    static function calculate(item:DimObject, pos:FastVector2, order:Int = 0):Map<String, DimObjectResult> {
        var results:Map<String, DimObjectResult> = [];

        var padding = item.padding ?? new Box(0);
        var margin = item.margin ?? new Box(0);

        var size = item.size ?? { width: 0, height: 0 };

        var textSize:Dim = null;
        if (item.text != null && item.font != null && item.fontSize != null) {
            textSize = getTextDim(item.font, item.fontSize, item.text);
        }

        var growToTextSize = item.growToTextSize ?? false;
        if (growToTextSize && textSize != null) {
            size.width = textSize.width + padding.left + padding.right;
            size.height = textSize.height + padding.top + padding.bottom;
        }
        else {
            if (item.width != null) {
                size.width = item.width + padding.left + padding.right;
            }

            if (item.height != null) {
                size.height = item.height + padding.top + padding.bottom;
            }
        }

        var parentDim = new Dim(pos.x, pos.y, size.width, size.height, order + 1);

        if (item.items != null) {
            var childSizes = new Map<String, Dim>();
            for (k => i in item.items) {
                var calculated = calculate(i, pos, order);
                for (innerK => innerV in calculated) {
                    var childName = "/" + innerK;
                    if (innerK == "parent") {
                        childName = "";
                    }

                    var name = '${k}${childName}';
                    results[name] = innerV;
                    childSizes[k] = innerV.dim;
                }
            }

            var autoSize = item.autoSize ?? false;

            if (autoSize) {
                // finally, calculate the likely size of the container, including padding
                for (k => child in childSizes) {
                    var relX = child.x - pos.x;
                    var relY = child.y - pos.y;

                    parentDim.width = Math.max(relX + child.width, parentDim.width);
                    parentDim.height = Math.max(relX + child.height, parentDim.height);
                }

                parentDim.width += padding.left + padding.right;
                parentDim.height += padding.top + padding.bottom;
            }

            // one for loop to check for children aligned to the parent
            // because we need to work out parent alignment first
            for (k => child in childSizes) {
                var alignTo = item.items[k].alignTo ?? "";
                // check intermediate children with alignment to parent
                if (alignTo == "") {
                    var alignment = item.items[k].align ?? None;
                    var offset = item.items[k].alignOffset ?? new FastVector2();
                    switch (alignment) {
                        case DimAlign(valign, halign): {
                            if (autoSize) {
                                parentDim.width += child.width;
                                parentDim.height += child.height;
                            }
                            else {
                                var child = new Dim(childSizes[k].x, childSizes[k].y, childSizes[k].width, childSizes[k].height, childSizes[k].order);
                                dimAlignOffset(parentDim, child, halign, valign, offset.x, offset.y);
                                childSizes[k] = child;
                            }
                        }
                        default: {
                            // children without alignment
                            var x = item.items[k].x ?? 0;
                            var y = item.items[k].y ?? 0;

                            childSizes[k].x = x + pos.x;
                            childSizes[k].y = y + pos.y;
                        }
                    }
                }
            }

            // one loop to check if there are children aligned to other
            // children that have already been aligned to the parent.
            for (k => child in childSizes) {
                var alignTo = item.items[k].alignTo ?? "";
                // check children aligning to other children
                if (alignTo != "" && alignTo != "screen") {
                    var alignment = item.items[k].align ?? None;
                    var offset = item.items[k].alignOffset ?? new FastVector2();
                    var alignToDim = childSizes[alignTo];
                    switch (alignment) {
                        case DimAlign(valign, halign): {
                            dimAlignOffset(alignToDim, child, halign, valign, offset.x, offset.y);
                        }
                        default: {

                        }
                    }
                }
            }
        }

        results["parent"] = {
            type: item.id,
            dim: parentDim,
            originalObject: item
        };

        return results;
    }

    /**
	 * Create a dimension block from the given width and height, centering in the middle of the screen.
	 * @param width The width of the object to centre.
	 * @param height The height of the object to centre.
	 */
	public static function centreScreenFromSize(width:Float, height:Float)
    {
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
    public static function centreScreenY(width:Float, height:Float, offsetY:Float)
    {
        var x = (System.windowWidth() - width) / 2;
        return new Dim(x, offsetY, width, height);
    }

    /**
     * Create a dimension block from the given width and given offset on the X-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetX The offset from the left of the screen.
     */
    public static function centreScreenX(width:Float, height:Float, offsetX:Float)
    {
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
    public static function createDimAlignScreen(width:Float, height:Float, valign:VerticalAlign, halign:HorizontalAlign, offsetX:Float, offsetY:Float)
    {
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
    public static function centreBufferY(width:Float, height:Float, offsetY:Float)
    {
        var x = (Application.getBufferSize().x - width) / 2;
        return new Dim(x, offsetY, width, height);
    }

    /**
     * Align the given dimension along the x-axis of the current game client.
     * @param a The dimension.
     * @param halign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static inline function screenAlignX(a:Dim, halign:Int, offset:FastVector2)
    {
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
    public static inline function screenAlignY(a:Dim, valign:Int, offset:FastVector2)
    {
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
    public static inline function bufferAlignX(a:Dim, halign:Int, offset:FastVector2)
    {
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
    public static inline function bufferAlignY(a:Dim, valign:Int, offset:FastVector2)
    {
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
    public static function dimGridEquals(container:Dim, columns:Int, rows:Int):Array<Dim>
    {
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
    public static function dimGridFloats(container:Dim, columns:Array<Float>, rows:Array<Float>):Array<Dim>
    {
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
    public static function dimGrid(container:Dim, columns:Array<DimCellSize>, rows:Array<DimCellSize>):Array<Dim>
    {
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

    public static function dimMultiCellSize(cellSize:DimCellSize, count:Int):Array<DimCellSize>
    {
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
    public static function dimFixedFlow(container:Dim, size:Dim, direction:Int)
    {
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
    public static function dimVariableFlow(container:Dim, direction:Int)
    {
        containerColumnOrRow = container;
        containerDirection = direction;
        containerMethod = FLOW_VARIABLE;
        containerCellSize = new Dim(0, 0, 0, 0);
        containerCell = 0;
    }

    public static function dimVariableSetNextDim(dim:Dim)
    {
        if (containerMethod == FLOW_VARIABLE)
            containerCellSize = dim.clone();
    }

    public static function getNewDim(padding:Float = 0)
    {
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
    public static function centreBufferX(width:Float, height:Float, offsetX:Float)
    {
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
    public static function dimOffsetX(a:Dim, offsetX:Float)
    {
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
    public static function dimOffsetY(a:Dim, offsetY:Float)
    {
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
    public static inline function dimAlign(a:Dim, b:Dim, valign:Int, halign:Int)
    {
        dimVAlign(a, b, valign);
        dimHAlign(a, b, halign);
    }

    /**
     * Aligns dimension `b` to `a` on the Y-axis using the given vertical alignment.
     * @param a The first dimension.
     * @param b The second dimension.
     * @param valign The vertical alignment `b` should be to `a`.
     */
    public static inline function dimVAlign(a:Dim, b:Dim, valign:Int)
    {
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
    public static inline function dimHAlign(a:Dim, b:Dim, halign:Int)
    {
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

    public static inline function dimAlignOffset(a:Dim, b:Dim, halign:Int, valign:Int, hoffset:Float = 0.0, voffset:Float = 0.0)
    {
        dimVAlignOffset(a, b, valign, voffset);
        dimHAlignOffset(a, b, halign, hoffset);
    }

    public static inline function dimVAlignOffset(a:Dim, b:Dim, valign:Int, offset:Float = 0.0)
    {
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

    public static inline function dimHAlignOffset(a:Dim, b:Dim, halign:Int, offset:Float = 0.0)
    {
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
    public static function dimScale(a:Dim, scaleX:Float, scaleY:Float)
    {
        var ratioWidth = a.width * scaleX;
        var ratioX = a.x + ((a.width - ratioWidth) / 2);
        var ratioHeight = a.height * scaleY;
        var ratioY = a.y + ((a.height - ratioHeight) / 2);
        return new Dim(ratioX, ratioY, ratioWidth, ratioHeight);
    }

    /**
     * Scale a given dimension along the X-Axis and return a new dimension with the results.
     * @param a The dimension to scale.
     * @param scaleX How much to scale, as a percentage (0-1), along the X-Axis.
     */
    public static function dimScaleX(a:Dim, scaleX:Float)
    {
        var ratioWidth = a.width * scaleX;
        var ratioX = a.x + ((a.width - ratioWidth) / 2);
        return new Dim(ratioX, a.y, ratioWidth, a.height);
    }

    /**
     * Scale a given dimension along the Y-Axis and return a new dimension with the results.
     * @param a The dimension to scale.
     * @param scaleY How much to scale, as a percentage (0-1), along the Y-Axis.
     */
    public static function dimScaleY(a:Dim, scaleY:Float)
    {
        var ratioHeight = a.height * scaleY;
        var ratioY = a.y + ((a.height - ratioHeight) / 2);
        return new Dim(a.x, ratioY, a.width, ratioHeight);
    }

    /**
    * Shrink the given dimension by an `amount` in pixels.
    **/
    public static function dimShrink(a:Dim, amount:Float) {
        return new Dim(a.x + amount / 2, a.y + amount / 2, a.width - amount, a.height - amount);
    }

    /**
    * Shrink the width of a given dimension by an `amount` in pixels.
    **/
    public static function dimShrinkW(a:Dim, amount:Float) {
        return new Dim(a.x + amount / 2, a.y, a.width - amount, a.height);
    }

    /**
    * Shrink the height of a given dimension by an `amount` in pixels.
    **/
    public static function dimShrinkH(a:Dim, amount:Float) {
        return new Dim(a.x, a.y + amount / 2, a.width, a.height - amount);
    }

    /**
    * Grow the given dimension by an `amount` in pixels.
    **/
    public static function dimGrow(a:Dim, amount:Float) {
        return new Dim(a.x - amount / 2, a.y - amount / 2, a.width + amount, a.height + amount);
    }

    /**
    * Grow the width of a given dimension by an `amount` in pixels.
    **/
    public static function dimGrowW(a:Dim, amount:Float) {
        return new Dim(a.x - amount / 2, a.y, a.width + amount, a.height);
    }

    /**
    * Grow the height of a given dimension by an `amount` in pixels.
    **/
    public static function dimGrowH(a:Dim, amount:Float) {
        return new Dim(a.x, a.y - amount / 2, a.width, a.height + amount);
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