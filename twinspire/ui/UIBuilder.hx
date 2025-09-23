package twinspire.ui;

import js.html.Text;
import twinspire.DimIndex.DimIndexUtils;
import twinspire.ui.widgets.Box.BoxOrientation;
import twinspire.ui.widgets.TabPage.TabPageStyle;
import twinspire.ui.widgets.*;
import twinspire.geom.Dim;
import kha.Font;
import kha.math.FastVector2;
import twinspire.scenes.SceneObject;
import twinspire.render.DragOptions;
import twinspire.geom.DimCellSize;
import twinspire.Dimensions.VerticalAlign;
import twinspire.Dimensions.HorizontalAlign;
import twinspire.Dimensions.DimResult;
import twinspire.Dimensions.Direction;
import twinspire.Dimensions.FlowJustify;
import twinspire.Dimensions.FlowAlign;
import twinspire.Dimensions.FlowWrap;
import twinspire.Dimensions.FlowConfig;
import twinspire.AddLogic;
using twinspire.extensions.ArrayExtensions;

typedef ContainerContext = {
    bounds: Dim,
    orientation: BoxOrientation,
    spacing: Float,
    padding: Float,
    offsetV: Float,  // Current vertical offset
    offsetH: Float,  // Current horizontal offset
    nextX: Float,    // For manual positioning in Stack
    nextY: Float,
    ?flowDirection: Direction,      // For flow boxes
    ?flowOptions: FlowBoxOptions,   // For flow boxes
    ?flowItems: Array<SceneObject>,  // Track items in flow
    ?boxRef: Box  // Direct reference to the Box object
}

typedef FlowBoxOptions = {
    var ?justify:FlowJustify;        // Default: Start
    var ?align:FlowAlign;            // Default: Start
    var ?wrap:FlowWrap;              // Default: None
    var ?lineSpacing:Float;          // Default: 0
    var ?itemSpacing:Float;          // Default: spacing parameter
}

typedef GridContext = {
    bounds: Dim,
    columns: Int,
    rows: Int,
    columnSizes: Array<Dynamic>, // Can be Float, DimCellSize, or Int depending on grid type
    rowSizes: Array<Dynamic>,
    currentCell: Int,
    gridType: GridType,
    spacing: Float,
    padding: Float,
    totalCells: Int,
    gridResults: Array<DimResult>
}

enum GridType {
    Equals;
    Floats;
    Cells;
}

class UIBuilder extends DimBuilder {
    
    // Track SceneObjects created by this builder
    private var sceneObjects:Array<SceneObject> = [];
    private var currentSceneObject:Int = 0;

    private var containerStack:Array<ContainerContext> = [];
    private var gridStack:Array<GridContext> = [];
    private var currentContainerName:String = null;
    private var currentTemplate:UITemplate = null;
    private var fillNext:Bool = false;
    private var stretchNext:Bool = false;

    private var font:Font;
    private var fontSize:Int;

    private var nextDraggable:Bool = false;
    private var nextDragOptions:DragOptions = null;

    private var nextId:Id;

    private var currentGrid(get, never):GridContext;
    function get_currentGrid():GridContext {
        return gridStack.length > 0 ? gridStack[gridStack.length - 1] : null;
    }

    private var currentContainer(get, never):ContainerContext;
    function get_currentContainer():ContainerContext {
        return containerStack.length > 0 ? containerStack[containerStack.length - 1] : null;
    }
    
    public function new(?existingResults:Array<DimResult>, ?isUpdate:Bool) {
        super(existingResults ?? [], isUpdate ?? false);
    }

    /**
    * Set the template reference for dynamic content management
    **/
    public function setTemplate(template:UITemplate, containerName:String):Void {
        currentTemplate = template;
        currentContainerName = containerName;
    }

    private function advanceSceneObject() {
        return currentSceneObject++;
    }

    /**
    * Create text - internal. Already adds a `DimResult`, no need to add again.
    **/
    private function createText(text:String, parent:DimIndex = null) {
        var result = Dimensions.getTextDim(font, fontSize, text, Ui(null, parent));
        add(result);
        return result;
    }

    private function getId(expect:Id) {
        if (nextId != null) {
            var temp = nextId;
            nextId = null;
            return temp;
        }
        return expect;
    }

    private function getDimension(index:DimIndex) {
        if (isUpdate) {
            switch (index) {
                case Group(idx): {
                    var wrapperIndex = Application.instance.graphicsCtx.getDimIndicesAtGroupIndex(idx)[0];
                    return results.find((res) -> DimIndexUtils.equals(res.index, Direct(wrapperIndex))).dim;
                }
                default: {
                    return results.find((res) -> DimIndexUtils.equals(res.index, index)).dim;
                }
            }
        }
        else {
            switch (index) {
                case Group(idx): {
                    var wrapperIndex = Application.instance.graphicsCtx.getDimIndicesAtGroupIndex(idx)[0];
                    return Application.instance.graphicsCtx.getTempOrCurrentDimAtIndex(wrapperIndex);
                }
                case Direct(idx): {
                    return Application.instance.graphicsCtx.getTempOrCurrentDimAtIndex(idx);
                }
            }
        }
    }

    /**
    * Begin this builder. Call before using.
    **/
    public function begin() {
        currentUpdatingIndex = 0;
        currentGroupIndex = -1;
        containerStack = [];
        Dimensions.setBuilderContext(this);
    }

    /**
    * End this builder.
    **/
    public function end() {
        Dimensions.clearBuilderContext();
    }

    /**
    * Set the font of the text to display in any object
    * from this call.
    **/
    public function setFont(font:Font) {
        this.font = font;
    }

    /**
    * Set the font size of the text to display in any object
    * from this call.
    **/
    public function setFontSize(size:Int) {
        this.fontSize = size;
    }

    /**
    * Set the ID of the next item to create.
    **/
    public function setNextId(id:Id) {
        this.nextId = id;
    }

    /**
    * Get the dim of the last item created.
    **/
    public function getLastItemDim() {
        if (sceneObjects.length == 0) {
            return null;
        }

        var lastObject = sceneObjects[sceneObjects.length - 1];
        var dim = getDimension(lastObject.index);
        return dim;
    }

    /**
    * Create a button.
    **/
    public function button(text:String, ?size:FastVector2):Button {
        var gtx = Application.instance.graphicsCtx;
        var id = getId(UITemplate.buttonId);

        var dim = new Dim(0, 0, size != null ? size.x : 0, size != null ? size.y : 0);
        var dimResult = Dimensions.createFromDim(dim, Ui());
        var isStretching = stretchNext;

        positionInContainer(dimResult.dim, dimResult.index);
        add(dimResult);

        var textDimResult = createText(text, dimResult.index);

        if (size == null) {
            if (containerStack.length > 0) {
                var box = containerStack[containerStack.length - 1];
                switch (box.orientation) {
                    case Flow(direction, options): {
                        if (!isStretching) {
                            Dimensions.dimGrowW(dimResult.index, textDimResult.dim.width + 6);
                            Dimensions.dimGrowH(dimResult.index, textDimResult.dim.height + 6);    
                        }
                        else {
                            if (direction == Left || direction == Right) {
                                Dimensions.dimGrowW(dimResult.index, textDimResult.dim.width + 6);
                            }
                            else if (direction == Up || direction == Down) {
                                Dimensions.dimGrowH(dimResult.index, textDimResult.dim.height + 6);
                            }
                        }
                    }
                    default: {
                        Dimensions.dimGrowW(dimResult.index, textDimResult.dim.width + 6);
                        Dimensions.dimGrowH(dimResult.index, textDimResult.dim.height + 6);
                    }
                }
            }

            dimResult.dim = getDimension(dimResult.index);
        }

        Dimensions.dimAlign(dimResult.index, textDimResult.index, VALIGN_CENTRE, HALIGN_MIDDLE);
        
        var dimIndex = advanceSceneObject();
        var button:Button;
        
        if (isUpdate && dimIndex < sceneObjects.length) {
            // Update existing SceneObject
            button = cast(sceneObjects[dimIndex], Button);
            button.lastChangedDim = dimResult.dim;
        } else {
            // Create new SceneObject
            button = new Button();
            button.type = id;
            button.text = text;
            button.font = font;
            button.fontSize = fontSize;
            button.wrapperIndex = dimResult.index;
            button.textIndex = textDimResult.index;
            button.targetContainer = dimResult.dim.clone();

            gtx.beginGroup();
            gtx.addToGroup(dimResult.index);
            gtx.addToGroup(textDimResult.index);
            button.index = Group(gtx.endGroup(), id);
            
            if (dimIndex < sceneObjects.length) {
                sceneObjects[dimIndex] = button;
            } else {
                sceneObjects.push(button);
            }
        }

        trackFlowElement(button);
        
        return button;
    }

    /**
    * Create a checkbox with text.
    **/
    public function checkbox(text:String, checked:Bool = false):Checkbox {
        var gtx = Application.instance.graphicsCtx;
        var id = getId(UITemplate.checkboxId);

        // Create the checkbox box dimension (20x20 square)
        var boxDim = new Dim(0, 0, 20, 20);
        var boxResult = Dimensions.createFromDim(boxDim, Ui());
        positionInContainer(boxResult.dim, boxResult.index);
        add(boxResult);

        // Create the tick dimension (inside the box, smaller)
        var tickDim = new Dim(0, 0, 12, 12);
        var tickResult = Dimensions.createFromDim(tickDim, Ui());
        add(tickResult);
        
        // Center the tick inside the box
        Dimensions.dimAlign(boxResult.index, tickResult.index, VALIGN_CENTRE, HALIGN_MIDDLE);

        // Create text dimension next to the box
        var textResult = createText(text);
        
        // Position text to the right of the box with some spacing
        Dimensions.dimAlignOffset(boxResult.index, textResult.index, HALIGN_RIGHT, VALIGN_CENTRE, 8, 0);

        var dimIndex = advanceSceneObject();
        var checkbox:Checkbox;

        if (isUpdate && dimIndex < sceneObjects.length) {
            // Update existing SceneObject
            checkbox = cast(sceneObjects[dimIndex], Checkbox);
            checkbox.lastChangedDim = boxResult.dim;
        } else {
            // Create new SceneObject
            checkbox = new Checkbox();
            checkbox.type = id;
            checkbox.text = text;
            checkbox.checked = checked;
            checkbox.font = font;
            checkbox.fontSize = fontSize;
            checkbox.boxIndex = boxResult.index;
            checkbox.tickIndex = tickResult.index;
            checkbox.textIndex = textResult.index;
            checkbox.targetContainer = boxResult.dim.clone();

            // Create group containing all three dimensions
            gtx.beginGroup();
            gtx.addToGroup(boxResult.index);
            gtx.addToGroup(tickResult.index);
            gtx.addToGroup(textResult.index);
            checkbox.index = Group(gtx.endGroup(), id);

            if (dimIndex < sceneObjects.length) {
                sceneObjects[dimIndex] = checkbox;
            } else {
                sceneObjects.push(checkbox);
            }
        }

        trackFlowElement(checkbox);

        return checkbox;
    }

    /**
    * Create a tab page.
    **/
    public function tabPage(text:String, ?showClose:Bool = false, ?style:TabPageStyle = RoundedCorners, ?size:FastVector2):TabPage {
        var gtx = Application.instance.graphicsCtx;
        var id = getId(UITemplate.tabPageId);

        var dim = new Dim(0, 0, size != null ? size.x : 0, size != null ? size.y : 0);
        var dimResult = Dimensions.createFromDim(dim, Ui());
        var isStretching = stretchNext;

        positionInContainer(dimResult.dim, dimResult.index);
        add(dimResult);

        var textDimResult = createText(text, dimResult.index);
        
        // Create close button if needed
        var closeButtonDimResult:DimResult = null;
        if (showClose) {
            var buttonSize = Math.min(textDimResult.dim.height, 16);
            var buttonDim = new Dim(0, 0, buttonSize, buttonSize);
            Dimensions.advanceOrder();
            closeButtonDimResult = Dimensions.createFromDim(buttonDim, Ui(dimResult.index));
            Dimensions.reduceOrder();
            add(closeButtonDimResult);
        }

        var padding = 12; // Horizontal padding
        var triangleOffset = switch (style) {
            case TriangularRight: {
                padding;
            }
            default: {
                0.0;
            }
        };

        // Auto-size tab if no size specified
        if (size == null) {
            var textWidth = textDimResult.dim.width;
            var textHeight = textDimResult.dim.height;
            var closeButtonWidth = showClose ? 20 : 0; // Space for close button + padding
            
            if (containerStack.length > 0) {
                var box = containerStack[containerStack.length - 1];
                switch (box.orientation) {
                    case Flow(direction, options): {
                        if (!isStretching) {
                            Dimensions.dimGrowW(dimResult.index, textWidth + closeButtonWidth + padding + triangleOffset);
                            Dimensions.dimGrowH(dimResult.index, textHeight + 8); // Vertical padding
                        }
                        else {
                            if (direction == Left || direction == Right) {
                                Dimensions.dimGrowW(dimResult.index, textWidth + closeButtonWidth + padding + triangleOffset);
                            }
                            else if (direction == Up || direction == Down) {
                                Dimensions.dimGrowH(dimResult.index, textHeight + 8);
                            }
                        }
                    }
                    default: {
                        Dimensions.dimGrowW(dimResult.index, textWidth + closeButtonWidth + padding + triangleOffset);
                        Dimensions.dimGrowH(dimResult.index, textHeight + 8);
                    }
                }
            } else {
                Dimensions.dimGrowW(dimResult.index, textWidth + closeButtonWidth + padding + triangleOffset);
                Dimensions.dimGrowH(dimResult.index, textHeight + 8);
            }

            dimResult.dim = getDimension(dimResult.index);
        }

        // Position text and close button within the tab
        Dimensions.dimAlign(dimResult.index, textDimResult.index, VALIGN_CENTRE, HALIGN_LEFT);
        Dimensions.dimOffsetX(textDimResult.index, padding / 2); // Offset text from left edge
        textDimResult.dim = getDimension(textDimResult.index);
        
        if (showClose && closeButtonDimResult != null) {
            Dimensions.dimAlign(dimResult.index, closeButtonDimResult.index, VALIGN_CENTRE, HALIGN_RIGHT);
            Dimensions.dimOffsetX(closeButtonDimResult.index, -((padding / 2) + triangleOffset)); // Offset from right edge
            closeButtonDimResult.dim = getDimension(closeButtonDimResult.index);
            
            // Adjust text positioning to not overlap with close button
            var availableWidth = dimResult.dim.width - closeButtonDimResult.dim.width - 18; // Extra padding
            if (textDimResult.dim.width > availableWidth) {
                // Could implement text truncation here if needed
            }
        }
        
        var dimIndex = advanceSceneObject();
        var tabPage:TabPage;
        
        if (isUpdate && dimIndex < sceneObjects.length) {
            // Update existing SceneObject
            tabPage = cast(sceneObjects[dimIndex], TabPage);
            tabPage.lastChangedDim = dimResult.dim;
        } else {
            // Create new SceneObject
            tabPage = new TabPage();
            tabPage.type = id;
            tabPage.text = text;
            tabPage.showClose = showClose;
            tabPage.style = style;
            tabPage.font = font;
            tabPage.fontSize = fontSize;
            tabPage.wrapperIndex = dimResult.index;
            tabPage.textIndex = textDimResult.index;
            tabPage.closeButtonIndex = closeButtonDimResult != null ? closeButtonDimResult.index : null;
            tabPage.targetContainer = dimResult.dim.clone();

            gtx.beginGroup();
            gtx.addToGroup(dimResult.index);
            gtx.addToGroup(textDimResult.index);
            if (closeButtonDimResult != null) {
                gtx.setupDirectLink(closeButtonDimResult.index, dimResult.index);
                gtx.addToGroup(closeButtonDimResult.index);
            }
            tabPage.index = Group(gtx.endGroup(), id);
            
            if (dimIndex < sceneObjects.length) {
                sceneObjects[dimIndex] = tabPage;
            } else {
                sceneObjects.push(tabPage);
            }
        }

        trackFlowElement(tabPage);
        
        return tabPage;
    }

    /**
    * Begin a new tab control.
    *
    * @param name Give a name for this tab control.
    * @param width The width of this tab control.
    * @param height The height of this tab control.
    * @param tabPageHeight (Optional) The height of the pages in the tab selection pane. If not supplied, the height is calculated based on the font.
    * @param extraControls (Optional) Whether or not to allow extra controls in the tab selection pane.
    * @param extraControlWidth (Optional) The width of the container used to contain any extra controls, flowing left from the right.
    **/
    public function beginTabControl(name:String, width:Float, height:Float, ?tabPageHeight:Float = 0.0, ?extraControls:Bool = false, ?extraControlWidth:Float = 0.0) {
        // perform initial calculations and cache some of the results
        
    }

    /**
    * Assign into the tab control the content callback of the next tab page element to create.
    **/
    public function assignTabPageContent(contentCallback:(IDimBuilder) -> Void) {

    }

    /**
    * End the current tab control, returning the final state.
    **/
    public function endTabControl():TabControl {

    }

    /**
    * Begin a vertical or horizontal box layout.
    **/
    public function beginBox(orientation:BoxOrientation, width:Float, height:Float, spacing:Float = 0, padding:Float = 0):Box {
        var gtx = Application.instance.graphicsCtx;
        var id = getId(UITemplate.boxId);
        
        var containerDim = new Dim(0, 0, width, height);
        var containerResult = Dimensions.createFromDim(containerDim, Ui(id));
        add(containerResult);
        
        // Position within parent container if exists
        if (currentContainer != null) {
            positionInContainer(containerResult.dim, containerResult.index);
        }
        
        var dimIndex = advanceSceneObject();
        var box:Box;
        
        if (isUpdate && dimIndex < sceneObjects.length) {
            box = cast(sceneObjects[dimIndex], Box);
            box.lastChangedDim = containerResult.dim;
        } else {
            var containerInfo = gtx.createContainer(containerResult.dim);
            var vectorSpace = containerInfo.space;

            box = new Box();
            box.type = UITemplate.boxId;
            box.orientation = orientation;
            box.spacing = spacing;
            box.padding = padding;
            box.vectorSpace = vectorSpace;
            box.index = containerResult.index;
            box.targetContainer = containerResult.dim.clone();
            box.ownerTemplate = currentTemplate;
            box.containerName = currentContainerName;
            
            if (dimIndex < sceneObjects.length) {
                sceneObjects[dimIndex] = box;
            } else {
                sceneObjects.push(box);
            }
        }
        
        containerDim = getDimension(containerResult.index);
        
        // Push context onto stack with Stack-specific initialization
        containerStack.push({
            bounds: containerDim,
            orientation: orientation,
            spacing: spacing,
            padding: padding,
            offsetV: padding,
            offsetH: padding,
            nextX: padding,  // Default to padding for Stack
            nextY: padding,
            boxRef: box  // Store direct reference
        });

        Dimensions.advanceOrder();
        
        return box;
    }

    public function beginVerticalBox(width:Float, height:Float, spacing:Float = 0, padding:Float = 0):Box {
        return beginBox(Vertical, width, height, spacing, padding);
    }

    public function beginHorizontalBox(width:Float, height:Float, spacing:Float = 0, padding:Float = 0):Box {
        return beginBox(Horizontal, width, height, spacing, padding);
    }

    /**
    * Begin a stack box - manual positioning container
    **/
    public function beginStackBox(width:Float, height:Float, padding:Float = 0):Box {
        return beginBox(Stack, width, height, 0, padding); // spacing=0 for Stack
    }

    /**
    * Begin a simple flow box - items flow in one direction with spacing
    * @param width Container width
    * @param height Container height
    * @param direction Flow direction
    * @param spacing Space between items
    * @param padding Internal padding
    **/
    public function beginFlowBox(width:Float, height:Float, direction:Direction, spacing:Float = 0, padding:Float = 0):Box {
        return beginFlowBoxEx(width, height, direction, spacing, padding, null);
    }

    /**
    * Begin a complex flow box with full flexbox-like control
    * @param width Container width
    * @param height Container height
    * @param direction Flow direction
    * @param spacing Default space between items (can be overridden by justify)
    * @param padding Internal padding
    * @param options Advanced flow options (justify, align, wrap, etc.)
    **/
    public function beginFlowBoxEx(width:Float, height:Float, direction:Direction, spacing:Float = 0, padding:Float = 0, ?options:FlowBoxOptions):Box {
        var gtx = Application.instance.graphicsCtx;
        var id = getId(UITemplate.boxId);
        
        // Create container dimension
        var containerDim = new Dim(0, 0, width, height);
        var containerResult = Dimensions.createFromDim(containerDim, Ui(id));
        add(containerResult);
        
        // Position within parent container if exists
        if (currentContainer != null) {
            positionInContainer(containerResult.dim, containerResult.index);
        }
        
        var dimIndex = advanceSceneObject();
        var box:Box;
        
        if (isUpdate && dimIndex < sceneObjects.length) {
            box = cast(sceneObjects[dimIndex], Box);
            box.lastChangedDim = containerResult.dim;
            box.orientation = Flow(direction, options);  // Store direction and options
            box.spacing = spacing;
            box.padding = padding;
        } else {
            var containerInfo = gtx.createContainer(containerResult.dim);
            var vectorSpace = containerInfo.space;

            box = new Box();
            box.type = UITemplate.boxId;
            box.orientation = Flow(direction, options);  // New orientation type
            box.spacing = spacing;
            box.padding = padding;
            box.vectorSpace = vectorSpace;
            box.index = containerResult.index;
            box.targetContainer = containerResult.dim.clone();
            box.ownerTemplate = currentTemplate;
            box.containerName = currentContainerName;
            
            if (dimIndex < sceneObjects.length) {
                sceneObjects[dimIndex] = box;
            } else {
                sceneObjects.push(box);
            }
        }
        
        containerDim = getDimension(containerResult.index);
        
        // Push context onto stack
        containerStack.push({
            bounds: containerDim,
            orientation: Flow(direction, options),
            spacing: spacing,
            padding: padding,
            offsetV: padding,
            offsetH: padding,
            nextX: padding,
            nextY: padding,
            flowDirection: direction,           // Store for flow calculations
            flowOptions: options,                // Store options
            flowItems: []                        // Track items added to this flow
        });

        Dimensions.advanceOrder();
        
        return box;
    }

    /**
    * Begin an equal-sized grid layout where all cells have the same dimensions
    * @param width Grid container width
    * @param height Grid container height  
    * @param columns Number of equally sized columns
    * @param rows Number of equally sized rows
    * @param spacing Space between grid cells (optional)
    * @param padding Internal padding around the grid (optional)
    **/
    public function beginGridEquals(width:Float, height:Float, columns:Int, rows:Int, spacing:Float = 0, padding:Float = 0):Box {
        var gtx = Application.instance.graphicsCtx;
        var id = getId(UITemplate.boxId);
        
        // Create container dimension
        var containerDim = new Dim(0, 0, width, height);
        var containerResult = Dimensions.createFromDim(containerDim, Ui(id));
        add(containerResult);
        
        // Position within parent container if exists
        if (currentContainer != null) {
            positionInContainer(containerResult.dim, containerResult.index);
        }
        
        var dimIndex = advanceSceneObject();
        var box:Box;
        
        if (isUpdate && dimIndex < sceneObjects.length) {
            box = cast(sceneObjects[dimIndex], Box);
            box.lastChangedDim = containerResult.dim;
        } else {
            var containerInfo = gtx.createContainer(containerResult.dim);
            var vectorSpace = containerInfo.space;

            box = new Box();
            box.type = UITemplate.boxId;
            box.orientation = Grid; // Need to add Grid to BoxOrientation enum
            box.spacing = spacing;
            box.padding = padding;
            box.vectorSpace = vectorSpace;
            box.index = containerResult.index;
            box.targetContainer = containerResult.dim.clone();
            box.ownerTemplate = currentTemplate;
            box.containerName = currentContainerName;
            
            if (dimIndex < sceneObjects.length) {
                sceneObjects[dimIndex] = box;
            } else {
                sceneObjects.push(box);
            }
        }
        
        containerDim = getDimension(containerResult.index);
        
        // Calculate grid dimensions using Dimensions.dimGridEquals
        var gridResults = Dimensions.dimGridEquals(containerResult.index, columns, rows);
        
        // Apply spacing if specified
        if (spacing > 0) {
            applyGridSpacing(gridResults, columns, rows, spacing);
        }
        
        // Push grid context onto stack
        gridStack.push({
            bounds: containerDim,
            columns: columns,
            rows: rows,
            columnSizes: [columns], // Store column count for equals grid
            rowSizes: [rows], // Store row count for equals grid
            currentCell: 0,
            gridType: Equals,
            spacing: spacing,
            padding: padding,
            totalCells: columns * rows,
            gridResults: gridResults
        });

        Dimensions.advanceOrder();
        
        return box;
    }

    /**
    * Begin a ratio-based grid layout using float percentages for column and row sizes
    * @param width Grid container width
    * @param height Grid container height
    * @param columns Array of float ratios for columns (must sum to 1.0)
    * @param rows Array of float ratios for rows (must sum to 1.0)
    * @param spacing Space between grid cells (optional)
    * @param padding Internal padding around the grid (optional)
    **/
    public function beginGridFloats(width:Float, height:Float, columns:Array<Float>, rows:Array<Float>, spacing:Float = 0, padding:Float = 0):Box {
        // Validate that ratios sum to approximately 1.0
        var columnSum = 0.0;
        var rowSum = 0.0;
        for (col in columns) columnSum += col;
        for (row in rows) rowSum += row;
        
        if (Math.abs(columnSum - 1.0) > 0.001 || Math.abs(rowSum - 1.0) > 0.001) {
            throw "Grid float ratios must sum to 1.0 (columns: " + columnSum + ", rows: " + rowSum + ")";
        }
        
        var gtx = Application.instance.graphicsCtx;
        var id = getId(UITemplate.boxId);
        
        // Create container dimension
        var containerDim = new Dim(0, 0, width, height);
        var containerResult = Dimensions.createFromDim(containerDim, Ui(id));
        add(containerResult);
        
        // Position within parent container if exists
        if (currentContainer != null) {
            positionInContainer(containerResult.dim, containerResult.index);
        }
        
        var dimIndex = advanceSceneObject();
        var box:Box;
        
        if (isUpdate && dimIndex < sceneObjects.length) {
            box = cast(sceneObjects[dimIndex], Box);
            box.lastChangedDim = containerResult.dim;
        } else {
            var containerInfo = gtx.createContainer(containerResult.dim);
            var vectorSpace = containerInfo.space;

            box = new Box();
            box.type = UITemplate.boxId;
            box.orientation = Grid;
            box.spacing = spacing;
            box.padding = padding;
            box.vectorSpace = vectorSpace;
            box.index = containerResult.index;
            box.targetContainer = containerResult.dim.clone();
            box.ownerTemplate = currentTemplate;
            box.containerName = currentContainerName;
            
            if (dimIndex < sceneObjects.length) {
                sceneObjects[dimIndex] = box;
            } else {
                sceneObjects.push(box);
            }
        }
        
        containerDim = getDimension(containerResult.index);
        
        // Calculate grid dimensions using Dimensions.dimGridFloats
        var gridResults = Dimensions.dimGridFloats(containerResult.index, columns, rows);
        
        // Apply spacing if specified
        if (spacing > 0) {
            applyGridSpacing(gridResults, columns.length, rows.length, spacing);
        }
        
        // Push grid context onto stack
        gridStack.push({
            bounds: containerDim,
            columns: columns.length,
            rows: rows.length,
            columnSizes: columns.copy(),
            rowSizes: rows.copy(),
            currentCell: 0,
            gridType: Floats,
            spacing: spacing,
            padding: padding,
            totalCells: columns.length * rows.length,
            gridResults: gridResults
        });

        Dimensions.advanceOrder();
        
        return box;
    }

    /**
    * Begin a cell-based grid layout using DimCellSize for precise control over column and row dimensions
    * @param width Grid container width
    * @param height Grid container height
    * @param columns Array of DimCellSize for columns (mix of pixels and percentages)
    * @param rows Array of DimCellSize for rows (mix of pixels and percentages)
    * @param spacing Space between grid cells (optional)
    * @param padding Internal padding around the grid (optional)
    **/
    public function beginGridCells(width:Float, height:Float, columns:Array<DimCellSize>, rows:Array<DimCellSize>, spacing:Float = 0, padding:Float = 0):Box {
        var gtx = Application.instance.graphicsCtx;
        var id = getId(UITemplate.boxId);
        
        // Create container dimension
        var containerDim = new Dim(0, 0, width, height);
        var containerResult = Dimensions.createFromDim(containerDim, Ui(id));
        add(containerResult);
        
        // Position within parent container if exists
        if (currentContainer != null) {
            positionInContainer(containerResult.dim, containerResult.index);
        }
        
        var dimIndex = advanceSceneObject();
        var box:Box;
        
        if (isUpdate && dimIndex < sceneObjects.length) {
            box = cast(sceneObjects[dimIndex], Box);
            box.lastChangedDim = containerResult.dim;
        } else {
            var containerInfo = gtx.createContainer(containerResult.dim);
            var vectorSpace = containerInfo.space;

            box = new Box();
            box.type = UITemplate.boxId;
            box.orientation = Grid;
            box.spacing = spacing;
            box.padding = padding;
            box.vectorSpace = vectorSpace;
            box.index = containerResult.index;
            box.targetContainer = containerResult.dim.clone();
            box.ownerTemplate = currentTemplate;
            box.containerName = currentContainerName;
            
            if (dimIndex < sceneObjects.length) {
                sceneObjects[dimIndex] = box;
            } else {
                sceneObjects.push(box);
            }
        }
        
        containerDim = getDimension(containerResult.index);
        
        // Calculate grid dimensions using Dimensions.dimGrid
        var gridResults = Dimensions.dimGrid(containerResult.index, columns, rows);
        
        // Apply spacing if specified
        if (spacing > 0) {
            applyGridSpacing(gridResults, columns.length, rows.length, spacing);
        }
        
        // Push grid context onto stack
        gridStack.push({
            bounds: containerDim,
            columns: columns.length,
            rows: rows.length,
            columnSizes: columns.copy(),
            rowSizes: rows.copy(),
            currentCell: 0,
            gridType: Cells,
            spacing: spacing,
            padding: padding,
            totalCells: columns.length * rows.length,
            gridResults: gridResults
        });

        Dimensions.advanceOrder();
        
        return box;
    }

    /**
    * End the current grid layout
    **/
    public function endGrid():Void {
        if (gridStack.length == 0) {
            throw "endGrid called without beginGrid*";
        }
        
        gridStack.pop();
        Dimensions.reduceOrder();
    }

    /**
    * Get the next available grid cell for element placement
    * @return DimResult for the next cell, or null if grid is full
    **/
    public function nextGridCell():DimResult {
        if (currentGrid == null) {
            throw "nextGridCell called outside of grid context";
        }
        
        if (currentGrid.currentCell >= currentGrid.totalCells) {
            return null; // Grid is full
        }
        
        var cellResult = currentGrid.gridResults[currentGrid.currentCell];
        currentGrid.currentCell++;
        
        return cellResult;
    }

    /**
    * Gets the current grid cell. Starts at zero.
    **/
    public function getCurrentGridCell():DimResult {
        if (currentGrid == null) {
            throw "nextGridCell called outside of grid context";
        }
        
        if (currentGrid.currentCell >= currentGrid.totalCells) {
            return null; // Grid is full
        }

        return currentGrid.gridResults[currentGrid.currentCell];
    }

    /**
    * Get a specific grid cell by row and column indices
    * @param column Column index (0-based)
    * @param row Row index (0-based)
    * @return DimResult for the specified cell, or null if out of bounds
    **/
    public function getGridCell(column:Int, row:Int):DimResult {
        if (currentGrid == null) {
            throw "getGridCell called outside of grid context";
        }
        
        if (column < 0 || column >= currentGrid.columns || row < 0 || row >= currentGrid.rows) {
            return null; // Out of bounds
        }
        
        var cellIndex = row * currentGrid.columns + column;
        return currentGrid.gridResults[cellIndex];
    }

    /**
    * Skip the next N grid cells (useful for spanning cells or leaving empty spaces)
    * @param count Number of cells to skip
    **/
    public function skipGridCells(count:Int):Void {
        if (currentGrid == null) {
            throw "skipGridCells called outside of grid context";
        }
        
        currentGrid.currentCell = cast Math.min(currentGrid.currentCell + count, currentGrid.totalCells);
    }

    /**
    * Position an element in the next available grid cell
    **/
    public function positionInGrid(elementDim:Dim, elementIndex:DimIndex):Bool {
        var cellResult = nextGridCell();
        if (cellResult == null) {
            return false; // Grid is full
        }
        
        // Position element within the cell
        elementDim.x = cellResult.dim.x;
        elementDim.y = cellResult.dim.y;
        
        // Apply fill/stretch if specified
        if (fillNext) {
            elementDim.width = cellResult.dim.width;
            elementDim.height = cellResult.dim.height;
            fillNext = false;
        } else if (stretchNext) {
            elementDim.width = cellResult.dim.width;
            elementDim.height = cellResult.dim.height;
            stretchNext = false;
        }
        
        return true;
    }

    /**
    * Position an element in a specific grid cell
    * @param column Column index (0-based)
    * @param row Row index (0-based)
    **/
    public function positionInGridCell(elementDim:Dim, elementIndex:DimIndex, column:Int, row:Int):Bool {
        var cellResult = getGridCell(column, row);
        if (cellResult == null) {
            return false; // Out of bounds
        }
        
        // Position element within the cell
        elementDim.x = cellResult.dim.x;
        elementDim.y = cellResult.dim.y;
        
        // Apply fill/stretch if specified
        if (fillNext) {
            elementDim.width = cellResult.dim.width;
            elementDim.height = cellResult.dim.height;
            fillNext = false;
        } else if (stretchNext) {
            elementDim.width = cellResult.dim.width;
            elementDim.height = cellResult.dim.height;
            stretchNext = false;
        }
        
        return true;
    }

    /**
    * Override positionInContainer to handle grid positioning
    **/
    private function positionInContainerGrid(elementDim:Dim, elementIndex:DimIndex):Void {
        if (currentGrid != null) {
            // We're in a grid context - use grid positioning
            if (!positionInGrid(elementDim, elementIndex)) {
                throw "Grid is full - cannot position more elements";
            }
        } else {
            // Fallback to regular container positioning (existing logic)
            positionInContainer(elementDim, elementIndex);
        }
    }

    /**
    * Apply spacing between grid cells by shrinking each cell and adjusting positions
    **/
    private function applyGridSpacing(gridResults:Array<DimResult>, columns:Int, rows:Int, spacing:Float):Void {
        if (spacing <= 0 || gridResults.length == 0) return;
        
        var halfSpacing = spacing / 2;
        
        for (i in 0...gridResults.length) {
            var cell = gridResults[i].dim;
            var row = Math.floor(i / columns);
            var col = i % columns;
            
            // Shrink cell dimensions to make room for spacing
            var horizontalSpacing = (col == 0 || col == columns - 1) ? halfSpacing : spacing;
            var verticalSpacing = (row == 0 || row == rows - 1) ? halfSpacing : spacing;
            
            cell.width -= horizontalSpacing;
            cell.height -= verticalSpacing;
            
            // Adjust position to center the smaller cell
            if (col > 0) cell.x += halfSpacing;
            if (row > 0) cell.y += halfSpacing;
        }
    }

    /**
    * Convenience helper to create multiple equal DimCellSize entries
    * @param cellSize The base cell size configuration
    * @param count Number of identical cells to create
    * @return Array of DimCellSize
    **/
    public static function createMultipleCells(cellSize:DimCellSize, count:Int):Array<DimCellSize> {
        return Dimensions.dimMultiCellSize(cellSize, count);
    }

    /**
    * Convenience helper to create percentage-based DimCellSize
    * @param percentage Value between 0.0 and 1.0
    * @return DimCellSize configured for percentage sizing
    **/
    public static function createPercentCell(percentage:Float):DimCellSize {
        return {
            value: percentage,
            sizing: DIM_SIZING_PERCENT
        };
    }

    /**
    * Convenience helper to create pixel-based DimCellSize  
    * @param pixels Fixed pixel size
    * @return DimCellSize configured for pixel sizing
    **/
    public static function createPixelCell(pixels:Float):DimCellSize {
        return {
            value: pixels,
            sizing: DIM_SIZING_PIXELS
        };
    }

    /**
    * Perform flow layout calculations and update positions
    **/
    private function performFlowLayout(ctx:ContainerContext, direction:Direction, options:FlowBoxOptions):Void {
        if (ctx.flowItems == null || ctx.flowItems.length == 0) return;
        
        var gtx = Application.instance.graphicsCtx;
        var isHorizontal = (direction == Direction.Left || direction == Direction.Right);
        var containerSize = isHorizontal ? ctx.bounds.width : ctx.bounds.height;
        
        // Setup flow configuration
        var config:FlowConfig = {
            justify: options != null && options.justify != null ? options.justify : Start,
            align: options != null && options.align != null ? options.align : Start,
            wrap: options != null && options.wrap != null ? options.wrap : None,
            lineSpacing: options != null && options.lineSpacing != null ? options.lineSpacing : 0
        };
        
        var itemSpacing = options != null && options.itemSpacing != null ? options.itemSpacing : ctx.spacing;
        
        // Organize items into lines based on wrap
        var lines:Array<Array<{item: SceneObject, size: Float, crossSize: Float}>> = [];
        var currentLine:Array<{item: SceneObject, size: Float, crossSize: Float}> = [];
        var currentLineSize:Float = 0;
        
        for (item in ctx.flowItems) {
            var itemDim = getDimension(item.index);
            var itemSize = isHorizontal ? itemDim.width : itemDim.height;
            var itemCrossSize = isHorizontal ? itemDim.height : itemDim.width;
            
            // Check for wrap
            if (config.wrap != None && currentLine.length > 0) {
                var availableSize = (isHorizontal ? ctx.bounds.width : ctx.bounds.height) - (ctx.padding * 2);
                
                if (currentLineSize + itemSize + (currentLine.length > 0 ? itemSpacing : 0) > availableSize && currentLine.length > 0) {
                    // Start new line
                    lines.push(currentLine);
                    currentLine = [];
                    currentLineSize = 0;
                }
            }
            
            currentLine.push({item: item, size: itemSize, crossSize: itemCrossSize});
            currentLineSize += itemSize;
            if (currentLine.length > 1) {
                currentLineSize += itemSpacing; // Add spacing between items
            }
        }
        
        // Add final line
        if (currentLine.length > 0) {
            lines.push(currentLine);
        }
        
        // Apply layout to each line
        var lineOffset:Float = 0;

        if (config.wrap == Reverse) {
            if (isHorizontal) {
                lineOffset = ctx.bounds.height; // Start at bottom for horizontal flows
            } else {
                lineOffset = ctx.bounds.width; // Start at right for vertical flows
            }
        }

        for (line in lines) {
            // Calculate total size and max cross size for line
            var totalItemSize:Float = 0;
            var maxCrossSize:Float = 0;
            
            for (item in line) {
                totalItemSize += item.size;
                if (item.crossSize > maxCrossSize) maxCrossSize = item.crossSize;
            }

            if (config.wrap == Forward) {
                lineOffset += config.lineSpacing; // Wrap down
            } else if (config.wrap == Reverse) {
                lineOffset -= config.lineSpacing; // Wrap up
            }
            
            // Calculate spacing based on justification
            var spacing:Float = 0;
            var startOffset:Float = 0;
            
            switch (config.justify) {
                case Start:
                    spacing = itemSpacing;
                    startOffset = ctx.padding;
                case End:
                    spacing = itemSpacing;
                    var totalWithSpacing = totalItemSize + (itemSpacing * Math.max(0, line.length - 1));
                    startOffset = containerSize - totalWithSpacing - ctx.padding;
                case Center:
                    spacing = itemSpacing;
                    var totalWithSpacing = totalItemSize + (itemSpacing * Math.max(0, line.length - 1));
                    startOffset = (containerSize - totalWithSpacing) / 2;
                case SpaceBetween:
                    if (line.length > 1) {
                        spacing = (containerSize - totalItemSize - (ctx.padding * 2)) / (line.length - 1);
                    } else {
                        spacing = 0;
                    }
                    startOffset = ctx.padding;
                case SpaceAround:
                    spacing = (containerSize - totalItemSize - (ctx.padding * 2)) / line.length;
                    startOffset = ctx.padding + (spacing / 2);
                case SpaceEvenly:
                    spacing = (containerSize - totalItemSize - (ctx.padding * 2)) / (line.length + 1);
                    startOffset = ctx.padding + spacing;
            }

            // Position items in the line
            var currentPos = startOffset;
            
            for (itemData in line) {
                var sceneObj = itemData.item;
                var itemDim = getDimension(sceneObj.index);
                
                // Calculate cross-axis position based on alignment
                var crossAxisPos:Float = 0;
                
                switch (config.align) {
                    case Start:
                        crossAxisPos += 0;
                    case Center:
                        crossAxisPos += (maxCrossSize - itemData.crossSize) / 2;
                    case End:
                        crossAxisPos += maxCrossSize - itemData.crossSize;
                }
                
                // Set position based on flow direction
                if (direction == Direction.Right) {
                    itemDim.x = ctx.bounds.x + currentPos;
                    itemDim.y = ctx.bounds.y + lineOffset + crossAxisPos + ctx.padding;
                }
                else if (direction == Direction.Left) {
                    if (config.wrap == Reverse) {
                        itemDim.y = ctx.bounds.y + lineOffset - maxCrossSize + crossAxisPos - ctx.padding;
                    } else {
                        itemDim.y = ctx.bounds.y + lineOffset + crossAxisPos + ctx.padding;
                    }
                    itemDim.x = ctx.bounds.x + containerSize - currentPos - itemData.size - ctx.padding;
                }
                else if (direction == Direction.Down) {
                    itemDim.x = ctx.bounds.x + lineOffset + crossAxisPos + ctx.padding;
                    itemDim.y = ctx.bounds.y + currentPos;
                }
                else if (direction == Direction.Up) {
                    if (config.wrap == Reverse) {
                        itemDim.x = ctx.bounds.x + lineOffset - maxCrossSize + crossAxisPos - ctx.padding;
                    } else {
                        itemDim.x = ctx.bounds.x + lineOffset + crossAxisPos + ctx.padding;
                    }
                    itemDim.y = ctx.bounds.y + containerSize - currentPos - itemData.size - ctx.padding;
                }

                var groupIndex = switch(sceneObj.index) {
                    case Group(idx): idx;
                    default: -1;
                }
                var children = gtx.getDimIndicesAtGroupIndex(groupIndex);
                var wrapperIndex = children[0];

                // Update the dimension
                gtx.setOrReinitDim(Direct(wrapperIndex), itemDim);
                
                // Update children positions (linked dimensions)
                for (i in 1...children.length) {
                    var childIndex = children[i];
                    var childDim = getDimension(Direct(childIndex));
                    
                    // Children are positioned relative to parent
                    // Adjust their absolute position based on parent's new position
                    childDim.x += (itemDim.x - sceneObj.targetContainer.x);
                    childDim.y += (itemDim.y - sceneObj.targetContainer.y);
                    
                    gtx.setOrReinitDim(Direct(childIndex), childDim);
                }
                
                currentPos += itemData.size + spacing;
            }
            
            // Update line offset for wrapping
            if (config.wrap == Forward) {
                lineOffset += maxCrossSize + config.lineSpacing;
            } else if (config.wrap == Reverse) {
                lineOffset -= maxCrossSize + config.lineSpacing;
            }
        }
    }

    public function endBox():Void {
        if (containerStack.length == 0) {
            throw "endBox called without beginBox";
        }
        
        // Perform flow layout if this is a flow box
        var ctx = containerStack[containerStack.length - 1];
        switch (ctx.orientation) {
            case Flow(direction, options):
                performFlowLayout(ctx, direction, options);
            case _:
                // Other box types don't need special end handling
        }
        
        containerStack.pop();
        Dimensions.reduceOrder();
    }

    /**
    * Make the next element fill available space in the current box.
    **/
    public function setFill(fill:Bool = true):Void {
        fillNext = fill;
    }

    /**
    * Make the next element stretch to container width/height.
    **/
    public function setStretch(stretch:Bool = true):Void {
        stretchNext = stretch;
    }

    /**
    * Position the next element at specific coordinates (relative to stack box)
    **/
    public function positionNext(x:Float, y:Float):Void {
        if (currentContainer == null || currentContainer?.orientation != Stack) {
            throw "positionNext can only be used inside a Stack box";
        }
        
        currentContainer.nextX = x;
        currentContainer.nextY = y;
    }

    /**
    * Position next element at center of stack box
    **/
    public function positionNextCenter():Void {
        if (currentContainer == null || currentContainer?.orientation != Stack) {
            throw "positionNextCenter can only be used inside a Stack box";
        }
        
        // Will be calculated in positionInContainer based on element size
        currentContainer.nextX = -1; // Special flag for center
        currentContainer.nextY = -1;
    }

    /**
    * Make the next element in a Stack box draggable
    * @param options Optional drag configuration
    **/
    public function setNextStackDraggable(draggable:Bool = true, ?options:DragOptions):Void {
        if (currentContainer == null || currentContainer.orientation != Stack) {
            throw "setNextStackDraggable can only be used inside a Stack box";
        }
        
        nextDraggable = draggable;
        nextDragOptions = options;
    }

    /**
    * Track element for flow layout (call after SceneObject is added to stack)
    * @param sceneObj The SceneObject to track
    **/
    private function trackFlowElement(sceneObj:SceneObject):Void {
        if (currentContainer == null) return;
        
        switch (currentContainer.orientation) {
            case Flow(direction, options):
                // Track this item for later layout
                if (currentContainer.flowItems == null) {
                    currentContainer.flowItems = [];
                }
                currentContainer.flowItems.push(sceneObj);
            case _:
                // Not a flow box, nothing to track
        }
    }

    /**
    * Position element in current container
    **/
    private function positionInContainer(elementDim:Dim, elementIndex:DimIndex):Void {
        // Check if we're in a grid context first
        if (currentGrid != null) {
            if (!positionInGrid(elementDim, elementIndex)) {
                throw "Grid is full - cannot position more elements";
            }
            return;
        }

        if (currentContainer == null) return;
    
        var ctx = currentContainer;

        if (currentContainer.boxRef != null && currentContainer.boxRef.vectorSpace != null) {
            if (!currentContainer.boxRef.vectorSpace.children.contains(elementIndex)) {
                currentContainer.boxRef.vectorSpace.addChild(elementIndex);
            }
        }

        var gtx = Application.instance.graphicsCtx;
        var x:Float = 0;
        var y:Float = 0;

        // Track items for flow boxes
        switch (currentContainer.orientation) {
            case Flow(direction, options): {
                switch (direction) {
                    case Down | Up: {
                        if (stretchNext) elementDim.width = ctx.bounds.width - (ctx.padding * 2);
                    }
                    case Left | Right: {
                        if (stretchNext) elementDim.height = ctx.bounds.height - (ctx.padding * 2);
                    }
                }
            }
            case Vertical: {
                x = ctx.bounds.x + ctx.padding;
                y = ctx.bounds.y + ctx.offsetV;
                
                if (stretchNext) elementDim.width = ctx.bounds.width - (ctx.padding * 2);
                ctx.offsetV += elementDim.height + ctx.spacing;
            }
            case Horizontal: {
                x = ctx.bounds.x + ctx.offsetH;
                y = ctx.bounds.y + ctx.padding;
                
                if (stretchNext) elementDim.height = ctx.bounds.height - (ctx.padding * 2);
                ctx.offsetH += elementDim.width + ctx.spacing;
            }
            case Stack: {
                if (ctx.nextX == -1 && ctx.nextY == -1) {
                    // Center the element
                    x = ctx.bounds.x + (ctx.bounds.width - elementDim.width) / 2;
                    y = ctx.bounds.y + (ctx.bounds.height - elementDim.height) / 2;
                } else {
                    // Manual position (relative to container bounds + padding)
                    x = ctx.bounds.x + ctx.padding + ctx.nextX;
                    y = ctx.bounds.y + ctx.padding + ctx.nextY;
                }
                
                // Apply stretch in Stack box (both directions if set)
                if (stretchNext) {
                    elementDim.width = ctx.bounds.width - (ctx.padding * 2);
                    elementDim.height = ctx.bounds.height - (ctx.padding * 2);
                }
                
                // Apply draggable settings for Stack box
                if (nextDraggable) {
                    var indices = new Array<Int>();
                    switch (elementIndex) {
                        case Direct(idx, _): indices.push(idx);
                        case Group(idx, _): {
                            // For groups, apply to all indices in the group
                            var group = gtx.getDimIndicesAtGroupIndex(idx);
                            if (group.length > 0) {
                                indices.concat(group);
                            }
                        }
                    }
                    
                    for (idx in indices) {
                        var query = gtx.queries[idx];
                        query.allowDragging = true;
                        
                        if (nextDragOptions != null) {
                            query.dragOptions = nextDragOptions;
                        }
                    }
                }
                
                // Reset manual position and draggable settings
                ctx.nextX = ctx.padding;
                ctx.nextY = ctx.padding;
                nextDraggable = false;
                nextDragOptions = null;
            }
            case Grid: {
                // do nothing. Shouldn't get here
                return;
            }
        }
        
        elementDim.x = x;
        elementDim.y = y;

        gtx.setOrReinitDim(elementIndex, elementDim);
        
        // Reset flags
        fillNext = false;
        stretchNext = false;
    }

    /**
    * Used internally by Twinspire to mark the builder as updating.
    **/
    public function prepareForUpdate():Void {
        isUpdate = true;
        currentSceneObject = 0;
        currentUpdatingIndex = 0;
    }
    
    /**
    * Remove an item from the builder.
    * After removal, call `addOrUpdateDim` again to ensure dimensions are updated.
    **/
    public function removeSceneObject(index:Int):Bool {
        if (index >= 0 && index < sceneObjects.length) {
            sceneObjects.splice(index, 1);
            return true;
        }
        return false;
    }
    
    /**
    * Get an array of the scene objects.
    **/
    public function getSceneObjects():Array<SceneObject> {
        return sceneObjects;
    }

}