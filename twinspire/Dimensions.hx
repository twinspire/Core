package twinspire;

import twinspire.DimIndex;
import haxe.ds.ArraySort;

import twinspire.DimIndex.DimIndexUtils;
import haxe.io.Path;
import twinspire.events.EventArgs;
import twinspire.events.DimBindingOptions;
import twinspire.render.GraphicsContext;
import twinspire.render.ComplexResult;
import twinspire.Id;
import twinspire.geom.Box;
import twinspire.geom.Dim;
import twinspire.geom.DimCellSize;
import twinspire.geom.DimCellSize.DimCellSizing;
import twinspire.scenes.Scene;
import twinspire.scenes.SceneObject;
import twinspire.Application;
using twinspire.extensions.ArrayExtensions;
using kha.StringExtensions;

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

enum abstract Direction(Int) to Int {
    var Up;
    var Down;
    var Left;
    var Right;
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

typedef DimResult = {
    var ?index:DimIndex;
    var ?dim:Dim;
}

enum FlowAlign {
    /**
    * Top for horizontal, Left for vertical
    **/
    Start;
    /**
    * Center for horizontal, Middle for vertical
    **/
    Center;
    /**
    * Bottom for horizontal, Right for vertical
    **/
    End;
}

// Flow justification options
enum FlowJustify {
    /**
    * Pack items at start
    **/
    Start;
    /**
    * Pack items at end
    **/
    End;
    /**
    * Center items
    **/
    Center;
    /**
    * Equal space between items
    **/
    SpaceBetween;
    /**
    * Equal space around items
    **/
    SpaceAround;
    /**
    * Equal space between and around
    **/
    SpaceEvenly;
}

// Wrap direction for multi-line flows
enum FlowWrap {
    /**
    * No wrapping
    **/
    None;
    /**
    * Wrap down for horizontal, right for vertical
    **/
    Forward;
    /**
    * Wrap up for horizontal, left for vertical
    **/
    Reverse;
}

// Flow configuration
typedef FlowConfig = {
    var justify:FlowJustify;
    var align:FlowAlign;
    var wrap:FlowWrap;
    /**
    * Space between wrapped lines
    **/
    var lineSpacing:Float;
}

class Dimensions {

    private static var _order:Int = 0;
    private static var _visibility:Bool = true;
    private static var _editMode:Bool;

    static function addDimToGraphicsContext(dim:Dim, addLogic:AddLogic, ?parent:DimIndex) {
        var gtx = Application.instance.graphicsCtx;
        var result:DimIndex = null;
        switch (addLogic) {
            case Empty(linked): {
                result = gtx.addEmpty(dim, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1));
            }
            case Ui(id, linked): {
                result = gtx.addUI(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1));
            }
            case Static(id, linked): {
                result = gtx.addStatic(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1));
            }
            case Sprite(id, linked): {
                result = gtx.addSprite(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1));
            }
        }
        return result;
    }

    static function getDimensionIndicesFromGroup(group:Array<Dim>, addLogic:AddLogic, parent:DimIndex):Array<DimIndex> {
        var gtx = Application.instance.graphicsCtx;
        var resultIndices = new Array<DimIndex>();

        for (i in 0...group.length) {
            var dim = group[i];
            switch (addLogic) {
                case Ui(id, linked):
                    resultIndices.push(gtx.addUI(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1)));
                case Static(id, linked):
                    resultIndices.push(gtx.addStatic(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1)));
                case Sprite(id, linked):
                    resultIndices.push(gtx.addSprite(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1)));
                case Empty(linked):
                    resultIndices.push(gtx.addEmpty(dim, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1)));
            }
        }

        return resultIndices;
    }

    private static var _currentDimBuilder:IDimBuilder = null;
    
    /**
    * Set the current DimBuilder context for dimension operations.
    * This allows Dimensions API to reference updated dimensions during template building.
    **/
    public static function setBuilderContext(builder:IDimBuilder) {
        _currentDimBuilder = builder;
    }
    
    /**
    * Clear the current DimBuilder context.
    **/
    public static function clearBuilderContext() {
        _currentDimBuilder = null;
    }

    private static function getCurrentDimAtIndex(index:DimIndex):Dim {
        if (_currentDimBuilder != null && _currentDimBuilder.updating && index != null) {
            // Check builder's results for updated dimension
            var result = _currentDimBuilder.getCurrentDimAtIndex(index);
            if (result != null) {
                return result; // Return the updated dimension
            }
        }
        
        // Fall back to GraphicsContext
        if (index != null) {
            var gtx = Application.instance.graphicsCtx;
            return gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(index));
        }
        
        return null;
    }

    /**
    * Begins editing dimensions. This avoids creating a `DimIndex` and invoking the underlying `GraphicsContext`
    * `add` functions. Called by `useDimension` if using this for managing dimensions.
    *
    * All functions that return a `DimResult` will only return a `Dim` and no `index` value.
    **/
    public static function beginEdit() {
        _editMode = true;
    }

    /**
    * Ends editing.
    **/
    public static function endEdit() {
        _editMode = false;
    }

    /**
    * Advances the `order` of a `Dim` when creating dimensions.
    **/
    public static function advanceOrder() {
        _order += 1;
    }

    /**
    * Reduces the `order` of a `Dim` when creating dimensions.
    **/
    public static function reduceOrder() {
        _order -= 1;
    }

    /**
    * Mark a dimension beginning invisible when creating dimensions.
    **/
    public static function beginInvisible() {
        _visibility = false;
    }

    /**
    * Mark a dimension as visible when creating dimensions.
    **/
    public static function endInvisible() {
        _visibility = true;
    }

    /**
    * Create a dimension from a manually created `Dim`.
    *
    * @param dim The dimensions to create from.
    * @param addLogic The type of dimension to add to `GraphicsContext`.
    *
    * @return Returns a `DimResult` with a `dim`, and `index` value if available.
    **/
    public static function createFromDim(dim:Dim, addLogic:AddLogic):DimResult {
        var result = dim.clone();
        if (result.order < _order) {
            result.order = _order;
        }
        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
	 * Create a dimension block from the given width and height, centering in the middle of the screen.
	 * @param width The width of the object to centre.
	 * @param height The height of the object to centre.
     * @param addLogic The type of dimension to add to `GraphicsContext`.
     *
     * @return Returns a `DimResult` with a `dim`, and `index` value if available.
	 */
	public static function centreScreenFromSize(width:Float, height:Float, addLogic:AddLogic):DimResult {
        var x = (System.windowWidth() - width) / 2;
        var y = (System.windowHeight() - height) / 2;
        var result = new Dim(x, y, width, height, _order);
        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
     * Create a dimension block from the given width and given offset on the Y-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetY The offset from the top of the screen.
     * @param addLogic The type of dimension to add to `GraphicsContext`.
     *
     * @return Returns a `DimResult` with a `dim`, and `index` value if available.
     */
    public static function centreScreenY(width:Float, height:Float, offsetY:Float, addLogic:AddLogic):DimResult {
        var x = (System.windowWidth() - width) / 2;
        var result = new Dim(x, offsetY, width, height, _order);
        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
     * Create a dimension block from the given width and given offset on the X-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetX The offset from the left of the screen.
     * @param addLogic The type of dimension to add to `GraphicsContext`.
     *
     * @return Returns a `DimResult` with a `dim`, and `index` value if available.
     */
    public static function centreScreenX(width:Float, height:Float, offsetX:Float, addLogic:AddLogic):DimResult {
        var y = (System.windowHeight() - height) / 2;
        var result = new Dim(offsetX, y, width, height, _order);
        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
        }

        return {
            index: resultIndex,
            dim: result
        };
    }

    /**
     * Create a dimension block aligned to the screen, with the given width and height, and the given vertical and horizontal alignment.
     * @param width The width of the dimension.
     * @param height The height of the dimension.
     * @param valign The vertical alignment to use.
     * @param halign The horizontal alignment to use.
     * @param offsetX The offset from the left of the screen.
     * @param offsetY The offset from the top of the screen.
     * @param addLogic The type of dimension to add to `GraphicsContext`.
     *
     * @return Returns a `DimResult` with a `dim`, and `index` value if available.
     */
    public static function createDimAlignScreen(width:Float, height:Float, valign:VerticalAlign, halign:HorizontalAlign, offsetX:Float, offsetY:Float, addLogic:AddLogic):DimResult {
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

        var result = new Dim(x, y, width, height, _order);
        result.visible = _visibility;
        var resultIndex:DimIndex = null;

        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
    * Create a new dimension offset from an existing dimension.
    *
    * @param from The dim to reference.
    * @param offset The offset value from the given dimension.
    * @param addLogic The type of dimension to add to `GraphicsContext`.
    *
    * @return Returns a `DimResult` with a `dim`, and `index` value if available.
    **/
    public static function createFromOffset(fromIndex:DimIndex, offset:FastVector2, addLogic:AddLogic):DimResult {
        var gtx = Application.instance.graphicsCtx;
        var from = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(fromIndex));

        var result = new Dim(from.x + offset.x, from.y + offset.y, from.width, from.height, _order);
        result.visible = _visibility;
        var resultIndex:DimIndex = null;

        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
     * Align the given dimension along the x-axis of the current game client.
     * @param aIndex The dimension reference.
     * @param halign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static function screenAlignX(aIndex:DimIndex, halign:Int, offset:FastVector2) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        if (halign == HALIGN_LEFT)
        {
            a.x = offset.x;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            a.x = ((System.windowWidth() - a.width) / 2) + offset.x;
        }
        else if (halign == HALIGN_RIGHT)
        {
            a.x = System.windowWidth() - a.width - offset.x;
        }
    }

    /**
     * Align the given dimension along the y-axis of the current game client.
     * @param aIndex The dimension reference.
     * @param valign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static function screenAlignY(aIndex:DimIndex, valign:Int, offset:FastVector2) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        if (valign == VALIGN_TOP)
        {
            a.y = offset.y;
        }
        else if (valign == VALIGN_CENTRE)
        {
            a.y = ((System.windowHeight() - a.height) / 2) + offset.y;
        }
        else if (valign == VALIGN_BOTTOM)
        {
            a.y = System.windowHeight() - a.height + offset.y;
        }
    }

    /**
     * Create a series of dimensions representing a grid, with each column and row of 
     * equal width and height proportionate to the number of given columns and rows to the container.
     * @param containerIndex The container dimension reference to create the grid from.
     * @param columns The number of equally sized columns.
     * @param rows The number of equally sized rows.
     * @param addLogic The type of dimension to add to `GraphicsContext`.
     *
     * @return Returns an array of `DimResult` with a `dim`, and `index` value if available.
     */
    public static function dimGridEquals(containerIndex:DimIndex, columns:Int, rows:Int, ?addLogic:AddLogic):Array<DimResult> {
        var gtx = Application.instance.graphicsCtx;
        var container = getCurrentDimAtIndex(containerIndex);

        var cellWidth = container.width / columns;
        var cellHeight = container.height / rows;
        var results = [];

        for (r in 0...rows) {
            for (c in 0...columns) {
                var cell = new Dim(c * cellWidth + container.x, r * cellHeight + container.y, cellWidth, cellHeight, _order);
                cell.visible = _visibility;
                results.push(cell);
            }
        }

        var resultIndices:Array<DimIndex> = [];

        if (!_editMode) {
            resultIndices = getDimensionIndicesFromGroup(results, addLogic ?? Empty(), containerIndex);
        }

        var dimResults:Array<DimResult> = [];
        for (i in 0...results.length) {
            var index:DimIndex = null;
            if (i < resultIndices.length) {
                index = resultIndices[i];
            }

            dimResults.push({
                dim: results[i],
                index: index
            });
        }

        return dimResults;
    }

    /**
     * Create a series of dimensions representing a grid, containing specific ratios for each set of columns and rows based on the size of the given container.
     * @param container The container dimension to create the grid from.
     * @param columns An array representing the ratios for the columns in the grid.
     * @param rows An array representing the ratios for the rows in the grid.
     * @param addLogic The type of dimension to add to `GraphicsContext`.
     *
     * @return Returns an array of `DimResult` with a `dim`, and `index` value if available.
     */
    public static function dimGridFloats(containerIndex:DimIndex, columns:Array<Float>, rows:Array<Float>, ?addLogic:AddLogic):Array<DimResult> {
        var gtx = Application.instance.graphicsCtx;
        var container = getCurrentDimAtIndex(containerIndex);

        var results = [];
        var startY = 0.0;
        for (r in 0...rows.length)
        {
            var cellHeight = container.height * rows[r];
            var startX = 0.0;
            for (c in 0...columns.length)
            {
                var cellWidth = container.width * columns[c];
                var cell = new Dim(startX + container.x, startY + container.y, cellWidth, cellHeight, _order);
                cell.visible = _visibility;
                results.push(cell);
                startX += cellWidth;
            }

            startY += cellHeight;
        }

        var resultIndices:Array<DimIndex> = [];

        if (!_editMode) {
            resultIndices = getDimensionIndicesFromGroup(results, addLogic ?? Empty(), containerIndex);
        }

        var dimResults:Array<DimResult> = [];
        for (i in 0...results.length) {
            var index:DimIndex = null;
            if (i < resultIndices.length) {
                index = resultIndices[i];
            }

            dimResults.push({
                dim: results[i],
                index: index
            });
        }

        return dimResults;
    }

    /**
     * Create a series of dimensions representing a grid, using the specific given columns and rows with varying size methods.
     * Any cell sizes with the method `DIM_SIZING_PIXELS` are calculated first, and the remaining width or height of the
     * column or row is then used to determine any sizes with the method `DIM_SIZING_PERCENT`. Any pixel sizes that
     * are greater than the width or height of the given container will supersede any provided percentage sizes.
     * @param container The container dimension to create the grid from.
     * @param columns An array of column sizes.
     * @param rows An array of row sizes.
     * @param addLogic The type of dimension to add to `GraphicsContext`.
     *
     * @return Returns an array of `DimResult` with a `dim`, and `index` value if available.
     */
    public static function dimGrid(containerIndex:DimIndex, columns:Array<DimCellSize>, rows:Array<DimCellSize>, ?addLogic:AddLogic):Array<DimResult> {
        var gtx = Application.instance.graphicsCtx;
        var container = getCurrentDimAtIndex(containerIndex);

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

                var cell = new Dim(x, y, width, height, _order);
                cell.visible = _visibility;
                results.push(cell);
            }
        }

        
        var resultIndices:Array<DimIndex> = [];

        if (!_editMode) {
            resultIndices = getDimensionIndicesFromGroup(results, addLogic ?? Empty(), containerIndex);
        }

        var dimResults:Array<DimResult> = [];
        for (i in 0...results.length) {
            var index:DimIndex = null;
            if (i < resultIndices.length) {
                index = resultIndices[i];
            }

            dimResults.push({
                dim: results[i],
                index: index
            });
        }

        return dimResults;
    }

    /**
    * Create multiple `DimCellSize` with the given `count` as convenience.
    **/
    public static function dimMultiCellSize(cellSize:DimCellSize, count:Int):Array<DimCellSize> {
        var results = [];
        for (i in 0...count)
            results.push({ value: cellSize.value, sizing: cellSize.sizing });
        return results;
    }

    static var containerColumnOrRow:Dim;
    static var containerDirection:Direction;
    static var containerCellSize:Dim;
    static var containerCell:Int;
    static var containerMethod:Int;
    static var containerOffset:FastVector2;

    static var flowContainerIndex:DimIndex;
    static var flowResults:Array<Dim>;
    static var flowAddLogic:AddLogic;

    /**
     * Create a flow container, within which each time the function `getNewDim` is called,
     * a new dimension is created based on the given `size` and `direction`.
     *
     * This function flows continuously in one direction.
     *
     * Call `endFlow` to obtain an array of all dimensions created in this flow.
     *
     * @param container The container reference to use.
     * @param size The dim of each cell.
     * @param direction Specify the direction flow should go in.
     * @param addLogic The type of dimension to add to `GraphicsContext`.
     */
    public static function dimFixedFlow(containerIndex:DimIndex, size:Dim, direction:Direction, ?addLogic:AddLogic) {
        var gtx = Application.instance.graphicsCtx;
        var container = getCurrentDimAtIndex(containerIndex);

        flowContainerIndex = containerIndex;
        containerColumnOrRow = container;
        containerCellSize = size;
        containerDirection = direction;
        containerMethod = FLOW_FIXED;
        containerCell = 0;
        containerOffset = new FastVector2();
        flowAddLogic = addLogic != null ? addLogic : Empty();
        flowResults = [];

        if (direction == Direction.Up) {
            containerOffset = new FastVector2(0, containerColumnOrRow.getHeight() + containerColumnOrRow.getY());
        }
        else if (direction == Direction.Left) {
            containerOffset = new FastVector2(containerColumnOrRow.getWidth() + containerColumnOrRow.getX(), 0);
        }
    }

    private static var flowConfig:FlowConfig = null;
    private static var flowLines:Array<Array<{dim:Dim, index:DimIndex}>> = [];
    private static var flowCurrentLine:Array<{dim:Dim, index:DimIndex}> = [];
    private static var flowCurrentLineSize:Float = 0;
    private static var flowPendingDims:Array<{dim:Dim, index:DimIndex}> = [];

    /**
     * Create a flow container within which each time the function `getNewDim` is called,
     * a new dimension is created based on the given `direction`. The size of each item
     * must be specified using `dimVariableSetNextDim` prior to calling subsequent `getNewDim`.
     *
     * This function flows continuously in one direction.
     *
     * Call `endFlow` to obtain an array of all dimensions created in this flow.
     * 
     * @param container The container reference to use.
     * @param direction The specified direction dimensions should flow in.
     * @param addLogic The type of dimension to add to `GraphicsContext`.
     */
    public static function dimVariableFlow(containerIndex:DimIndex, direction:Direction, ?addLogic:AddLogic) {
        var gtx = Application.instance.graphicsCtx;
        var container = getCurrentDimAtIndex(containerIndex);

        flowContainerIndex = containerIndex;
        containerColumnOrRow = container;
        containerDirection = direction;
        containerOffset = new FastVector2();
        if (direction == Direction.Up) {
            containerOffset = new FastVector2(0, containerColumnOrRow.getHeight() + containerColumnOrRow.getY());
        }
        else if (direction == Direction.Left) {
            containerOffset = new FastVector2(containerColumnOrRow.getWidth() + containerColumnOrRow.getX(), 0);
        }

        containerMethod = FLOW_VARIABLE;
        containerCellSize = new Dim(0, 0, 0, 0);
        containerCell = 0;
        flowAddLogic = addLogic != null ? addLogic : Empty();
        flowResults = [];
    }

    /**
    * Set next dimension for variable flow with wrap support
    **/
    public static function dimVariableSetNextDim(dim:Dim) {
        if (containerMethod != FLOW_VARIABLE) {
            containerCellSize = dim.clone();
            return;
        }
        
        if (flowConfig == null) {
            // Fallback to original behavior
            containerCellSize = dim.clone();
            return;
        }
        
        var isHorizontal = (containerDirection == Direction.Left || containerDirection == Direction.Right);
        var itemSize = isHorizontal ? dim.width : dim.height;
        
        // Check if we need to wrap
        var needsWrap = false;
        if (flowConfig.wrap != None) {
            var availableSize = isHorizontal ? containerColumnOrRow.width : containerColumnOrRow.height;
            
            if (flowCurrentLineSize + itemSize > availableSize && flowCurrentLine.length > 0) {
                needsWrap = true;
            }
        }
        
        if (needsWrap) {
            // Finish current line
            flowLines.push(flowCurrentLine);
            flowCurrentLine = [];
            flowCurrentLineSize = 0;
        }
        
        containerCellSize = dim.clone();
    }

    /**
    * Get a new dimension from flow functionality.
    **/
    public static function getNewDim(padding:Float = 0):Dim {
        if (containerColumnOrRow != null && containerCellSize != null) {
            var x = containerColumnOrRow.getX();
            var y = containerColumnOrRow.getY();
            var width = containerColumnOrRow.getWidth();
            var height = containerColumnOrRow.getHeight();
            if (containerDirection == Direction.Up)
            {
                containerOffset.y -= containerCellSize.height + padding;
                y = containerOffset.y + y;
                height = containerCellSize.height;
            }
            else if (containerDirection == Direction.Down)
            {
                containerOffset.y += containerCellSize.height;
                y = containerOffset.y;

                height = containerCellSize.height;
            }
            else if (containerDirection == Direction.Left)
            {
                containerOffset.x -= containerCellSize.width + padding;
                x = containerOffset.x + x;

                width = containerCellSize.width;
            }
            else if (containerDirection == Direction.Right)
            {
                containerOffset.x += containerCellSize.width;
                x = containerOffset.x;
                width = containerCellSize.width;
            }

            var result = new Dim(x, y, width, height, _order);
            result.visible = _visibility;
            flowResults.push(result);
            return result;
        }

        return null;
    }

    /**
    * Ends the current flow of dimensions, returning an array of dimension indices that were created during the flow.
    * This function should be called after all dimensions have been created using `getNewDim`.
    * @return An array of `DimResult` representing the dimensions created during the flow.
    **/
    public static function endFlow():Array<DimResult> {
        var resultIndices:Array<DimIndex> = [];

        if (!_editMode) {
            resultIndices = getDimensionIndicesFromGroup(flowResults, flowAddLogic, flowContainerIndex);
        }

        var dimResults:Array<DimResult> = [];
        for (i in 0...flowResults.length) {
            var index:DimIndex = null;
            if (i < resultIndices.length) {
                index = resultIndices[i];
            }

            dimResults.push({
                dim: flowResults[i],
                index: index
            });
        }

        flowResults = [];

        return dimResults;
    }

    /**
    * Begin variable flow with enhanced options
    **/
    public static function dimVariableFlowEx(containerIndex:DimIndex, direction:Direction, config:FlowConfig, ?addLogic:AddLogic) {
        var gtx = Application.instance.graphicsCtx;
        var container = getCurrentDimAtIndex(containerIndex);

        flowContainerIndex = containerIndex;
        containerColumnOrRow = container;
        containerDirection = direction;
        containerOffset = new FastVector2();
        
        if (direction == Direction.Up) {
            containerOffset = new FastVector2(0, containerColumnOrRow.getHeight() + containerColumnOrRow.getY());
        }
        else if (direction == Direction.Left) {
            containerOffset = new FastVector2(containerColumnOrRow.getWidth() + containerColumnOrRow.getX(), 0);
        }

        containerMethod = FLOW_VARIABLE;
        containerCellSize = new Dim(0, 0, 0, 0);
        flowAddLogic = addLogic != null ? addLogic : Empty();
        flowResults = [];
        
        // Initialize flow configuration
        flowConfig = config;
        flowLines = [];
        flowCurrentLine = [];
        flowCurrentLineSize = 0;
        flowPendingDims = [];
    }

    /**
    * Get new dimension - just creates and stores, NO positioning yet
    **/
    public static function getNewDimEx():DimResult {
        if (containerColumnOrRow == null || containerCellSize == null) {
            return {dim: null, index: null};
        }
        
        // Create dimension with placeholder position (will be calculated in endFlowEx)
        var result = new Dim(0, 0, containerCellSize.width, containerCellSize.height, _order);
        result.visible = _visibility;
        
        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, flowAddLogic ?? Empty(), flowContainerIndex);
        }
        
        var dimResult = {dim: result, index: resultIndex};
        
        // Store for line calculation
        flowCurrentLine.push(dimResult);
        
        var isHorizontal = (containerDirection == Direction.Left || containerDirection == Direction.Right);
        flowCurrentLineSize += isHorizontal ? result.width : result.height;
        
        // Add to pending dims for final calculation
        flowPendingDims.push(dimResult);
        
        return dimResult;
    }

    /**
    * End flow and apply final positions with justification/alignment
    **/
    public static function endFlowEx():Array<DimResult> {
        if (flowConfig == null) {
            return endFlow(); // Fallback to original
        }
        
        var gtx = Application.instance.graphicsCtx;
        
        // Add final line
        if (flowCurrentLine.length > 0) {
            flowLines.push(flowCurrentLine);
        }
        
        // Now calculate ALL positions with justification and alignment
        var isHorizontal = (containerDirection == Direction.Left || containerDirection == Direction.Right);
        var containerSize = isHorizontal ? containerColumnOrRow.width : containerColumnOrRow.height;
        
        var lineOffset = 0.0; // Track cross-axis offset for wrapped lines
        
        for (lineIdx in 0...flowLines.length) {
            var line = flowLines[lineIdx];
            
            // Calculate total size and max cross size for this line
            var totalItemSize = 0.0;
            var maxCrossSize = 0.0;
            
            for (item in line) {
                totalItemSize += isHorizontal ? item.dim.width : item.dim.height;
                var crossSize = isHorizontal ? item.dim.height : item.dim.width;
                if (crossSize > maxCrossSize) maxCrossSize = crossSize;
            }
            
            // Calculate spacing based on justify mode
            var spacing = 0.0;
            var startOffset = 0.0;
            
            switch (flowConfig.justify) {
                case Start:
                    spacing = 0;
                    startOffset = 0;
                case End:
                    spacing = 0;
                    startOffset = containerSize - totalItemSize;
                case Center:
                    spacing = 0;
                    startOffset = (containerSize - totalItemSize) / 2;
                case SpaceBetween:
                    if (line.length > 1) {
                        spacing = (containerSize - totalItemSize) / (line.length - 1);
                    }
                    startOffset = 0;
                case SpaceAround:
                    spacing = (containerSize - totalItemSize) / line.length;
                    startOffset = spacing / 2;
                case SpaceEvenly:
                    spacing = (containerSize - totalItemSize) / (line.length + 1);
                    startOffset = spacing;
            }
            
            // Apply positions to each item in the line
            var currentMainPos = startOffset;
            
            for (item in line) {
                var dim = item.dim;
                var itemMainSize = isHorizontal ? dim.width : dim.height;
                var itemCrossSize = isHorizontal ? dim.height : dim.width;
                
                // Calculate cross-axis position based on alignment
                var crossAxisPos = 0.0;
                switch (flowConfig.align) {
                    case Start:
                        crossAxisPos = 0;
                    case Center:
                        crossAxisPos = (maxCrossSize - itemCrossSize) / 2;
                    case End:
                        crossAxisPos = maxCrossSize - itemCrossSize;
                }
                
                // Set final positions based on direction
                if (containerDirection == Direction.Right) {
                    dim.x = containerColumnOrRow.x + currentMainPos;
                    dim.y = containerColumnOrRow.y + lineOffset + crossAxisPos;
                }
                else if (containerDirection == Direction.Left) {
                    dim.x = containerColumnOrRow.x + containerSize - currentMainPos - itemMainSize;
                    dim.y = containerColumnOrRow.y + lineOffset + crossAxisPos;
                }
                else if (containerDirection == Direction.Down) {
                    dim.x = containerColumnOrRow.x + lineOffset + crossAxisPos;
                    dim.y = containerColumnOrRow.y + currentMainPos;
                }
                else if (containerDirection == Direction.Up) {
                    dim.x = containerColumnOrRow.x + lineOffset + crossAxisPos;
                    dim.y = containerColumnOrRow.y + containerSize - currentMainPos - itemMainSize;
                }
                
                // Update dimension in GraphicsContext if we have an index
                if (item.index != null) {
                    gtx.setOrReinitDim(item.index, dim);
                }
                
                currentMainPos += itemMainSize + spacing;
            }
            
            // Update line offset for next line (wrap)
            if (flowConfig.wrap == Forward) {
                lineOffset += maxCrossSize + flowConfig.lineSpacing;
            } else if (flowConfig.wrap == Reverse) {
                lineOffset -= maxCrossSize + flowConfig.lineSpacing;
            }
        }
        
        // Return the results
        var dimResults = flowPendingDims.copy();
        
        // Reset flow state
        flowResults = [];
        flowConfig = null;
        flowLines = [];
        flowCurrentLine = [];
        flowPendingDims = [];
        flowCurrentLineSize = 0;
        
        return dimResults;
    }

    /**
     * Create a new dimension from an existing dimension, offsetting by the value of x as a margin from the given dimension.
     * If `offsetX` is less than `0`, then the new dimension will appear on the left of the new dimension, rather than the right.
     * If `offsetX` is equal to `0`, the new dimension will be to the right with no margin.
     * @param a The current dimension to use.
     * @param offsetX The value to offset the new dimension.
     * @param addLogic The type of dimension to add to `GraphicsContext`.
     *
     * @return Returns a `DimResult` with a `dim`, and `index` value if available.
     */ 
    public static function dimOffsetXClone(aIndex:DimIndex, offsetX:Float, ?addLogic:AddLogic):DimResult {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        var result:Dim = null;

        if (offsetX >= 0)
            result = new Dim(a.x + a.width + offsetX, a.y, a.width, a.height, _order);
        else if (offsetX < 0)
            result = new Dim(a.x - a.width - offsetX, a.y, a.width, a.height, _order);

        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic ?? Empty());
        }
        
        return {
            dim: result,
            index: resultIndex
        };
    }

    public static function dimOffsetX(aIndex:DimIndex, offsetX:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        a.x += offsetX;
    }

    /**
     * Create a new dimension from an existing dimension, offsetting by the value of y as a margin from the given dimension.
     * If `offsetY` is less than `0`, then the new dimension will appear above the new dimension, rather than below.
     * If `offsetY` is equal to `0`, the new dimension will be below with no margin.
     * @param a The current dimension to use.
     * @param offsetY The value to offset the new dimension.
     * @param addLogic The type of dimension to add to `GraphicsContext`.
     *
     * @return Returns a `DimResult` with a `dim`, and `index` value if available.
     */
    public static function dimOffsetYClone(aIndex:DimIndex, offsetY:Float, ?addLogic:AddLogic):DimResult {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        var result:Dim = null;

        if (offsetY >= 0)
            result = new Dim(a.x, a.y + a.height + offsetY, a.width, a.height, _order);
        else if (offsetY < 0)
            result = new Dim(a.x, a.y - a.height - offsetY, a.width, a.height, _order);

        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic ?? Empty());
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    public static function dimOffsetY(aIndex:DimIndex, offsetY:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        a.y += offsetY;
    }

    /**
     * Aligns dimension `bIndex` to `aIndex`, with the given alignment options. If both alignment values are set to CENTRE/MIDDLE, `b` will effectively be centred to `a`.
     * @param aIndex The first dimension reference.
     * @param bIndex The second dimension reference.
     * @param valign The vertical alignment `b` should be to `a`.
     * @param halign The horizontal alignment `b` should be to `a`.
     */
    public static function dimAlign(aIndex:DimIndex, bIndex:DimIndex, valign:Int, halign:Int) {
        dimVAlign(aIndex, bIndex, valign);
        dimHAlign(aIndex, bIndex, halign);
    }

    /**
     * Aligns dimension `bIndex` to `aIndex` on the Y-axis using the given vertical alignment.
     * @param aIndex The first dimension reference.
     * @param bIndex The second dimension reference.
     * @param valign The vertical alignment `b` should be to `a`.
     */
    public static function dimVAlign(aIndex:DimIndex, bIndex:DimIndex, valign:Int) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);
        var b = getCurrentDimAtIndex(bIndex);

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
     * Aligns dimension `bIndex` to `aIndex` on the X-axis using the given horizontal alignment.
     * @param aIndex The first dimension reference.
     * @param bIndex The second dimension reference.
     * @param valign The horizontal alignment `b` should be to `a`.
     */
    public static function dimHAlign(aIndex:DimIndex, bIndex:DimIndex, halign:Int) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);
        var b = getCurrentDimAtIndex(bIndex);

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

    /**
    * Align dimension `b` to `a` using the given alignment and offset values. This will align from the outer edge of `a`, rather than
    * align to the inside of `a`.
    *
    * @param a The first dimension reference.
    * @param b The second dimension reference.
    * @param halign The horizontal alignment.
    * @param valign The vertical alignment.
    * @param hoffset The horizontal offset.
    * @param voffset The vertical offset.
    **/
    public static function dimAlignOffset(a:DimIndex, b:DimIndex, halign:Int, valign:Int, hoffset:Float = 0.0, voffset:Float = 0.0) {
        dimVAlignOffset(a, b, valign, voffset);
        dimHAlignOffset(a, b, halign, hoffset);
    }

    /**
    * Align dimension `b` to `a` using the given alignment and offset values. This will align from the outer edge of `a`, rather than
    * align to the inside of `a`.
    *
    * @param aIndex The first dimension reference.
    * @param bIndex The second dimension reference.
    * @param valign The vertical alignment.
    * @param offset The vertical offset.
    **/
    public static function dimVAlignOffset(aIndex:DimIndex, bIndex:DimIndex, valign:Int, offset:Float = 0.0) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);
        var b = getCurrentDimAtIndex(bIndex);

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

    /**
    * Align dimension `b` to `a` using the given alignment and offset values. This will align from the outer edge of `a`, rather than
    * align to the inside of `a`.
    *
    * @param a The first dimension reference.
    * @param b The second dimension reference.
    * @param halign The horizontal alignment.
    * @param offset The horizontal offset.
    **/
    public static function dimHAlignOffset(aIndex:DimIndex, bIndex:DimIndex, halign:Int, offset:Float = 0.0) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);
        var b = getCurrentDimAtIndex(bIndex);

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
    public static function dimScale(aIndex:DimIndex, scaleX:Float, scaleY:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

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
    public static function dimScaleX(aIndex:DimIndex, scaleX:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

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
    public static function dimScaleY(aIndex:DimIndex, scaleY:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        var ratioHeight = a.height * scaleY;
        var ratioY = a.y + ((a.height - ratioHeight) / 2);
        a.y = ratioY;
        a.height = ratioHeight;
    }

    /**
    * Shrink the given dimension by an `amount` in pixels.
    **/
    public static function dimShrink(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        a.width = a.width - amount;
        a.height = a.height - amount;
    }

    /**
    * Shrink the width of a given dimension by an `amount` in pixels.
    **/
    public static function dimShrinkW(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        a.width = a.width - amount;
    }

    /**
    * Shrink the height of a given dimension by an `amount` in pixels.
    **/
    public static function dimShrinkH(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        a.height = a.height - amount;
    }

    /**
    * Grow the given dimension by an `amount` in pixels.
    **/
    public static function dimGrow(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        a.width = a.width + amount;
        a.height = a.height + amount;
    }

    /**
    * Grow the width of a given dimension by an `amount` in pixels.
    **/
    public static function dimGrowW(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        a.width = a.width + amount;
    }

    /**
    * Grow the height of a given dimension by an `amount` in pixels.
    **/
    public static function dimGrowH(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = getCurrentDimAtIndex(aIndex);

        a.height = a.height + amount;
    }

    /**
     * Measure the width and height of the given text with font and fontSize.
     *
     * @param font The instance of a font to measure against.
     * @param fontSize The size of the font.
     * @param text The text to measure.
     * 
     * @return Returns a `DimResult` with a `dim`, and `index` value if available.
     */
    public static function getTextDim(font:Font, fontSize:Int, text:String, ?addLogic:AddLogic):DimResult {
        var result = new Dim(0, 0, font.width(fontSize, text), font.height(fontSize), _order);
        result.visible = _visibility;
        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic ?? Empty());
        }

		return {
            dim: result,
            index: resultIndex
        };
	}

}