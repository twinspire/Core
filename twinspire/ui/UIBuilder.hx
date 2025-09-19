package twinspire.ui;

import twinspire.DimIndex.DimIndexUtils;
import twinspire.ui.widgets.Box.BoxOrientation;
import twinspire.ui.widgets.*;
import twinspire.geom.Dim;
import kha.Font;
import kha.math.FastVector2;
import twinspire.scenes.SceneObject;
import twinspire.render.DragOptions;
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

class UIBuilder extends DimBuilder {
    
    // Track SceneObjects created by this builder
    private var sceneObjects:Array<SceneObject> = [];
    private var currentSceneObject:Int = 0;

    private var containerStack:Array<ContainerContext> = [];
    private var currentContainerName:String = null;
    private var currentTemplate:UITemplate = null;
    private var fillNext:Bool = false;
    private var stretchNext:Bool = false;

    private var font:Font;
    private var fontSize:Int;

    private var nextDraggable:Bool = false;
    private var nextDragOptions:DragOptions = null;

    private var nextId:Id;

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
            return results.find((res) -> res.index == index).dim;
        }
        else {
            return Application.instance.graphicsCtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(index));
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
    * Create a button.
    **/
    public function button(text:String, ?size:FastVector2):Button {
        var gtx = Application.instance.graphicsCtx;
        var id = getId(UITemplate.buttonId);

        var dim = new Dim(0, 0, size != null ? size.x : 0, size != null ? size.y : 0);
        var dimResult = Dimensions.createFromDim(dim, Ui());
        positionInContainer(dimResult.dim, dimResult.index);
        add(dimResult);

        var textDimResult = createText(text, dimResult.index);

        if (size == null) {
            Dimensions.dimGrowW(dimResult.index, textDimResult.dim.width + 6);
            Dimensions.dimGrowH(dimResult.index, textDimResult.dim.height + 6);
            dimResult.dim = getDimension(dimResult.index);
        }

        Dimensions.dimAlign(dimResult.index, textDimResult.index, VALIGN_CENTRE, HALIGN_MIDDLE);
        
        var dimIndex = advanceSceneObject();
        var button:Button;
        
        if (isUpdate && dimIndex < sceneObjects.length) {
            // Update existing SceneObject
            button = cast(sceneObjects[dimIndex], Button);
            button.targetContainer = dimResult.dim;

        } else {
            // Create new SceneObject
            button = new Button();
            button.type = id;
            button.text = text;
            button.font = font;
            button.fontSize = fontSize;
            button.wrapperIndex = dimResult.index;
            button.textIndex = textDimResult.index;
            button.targetContainer = dimResult.dim;

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
            checkbox.targetContainer = boxResult.dim;
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
            checkbox.targetContainer = boxResult.dim;

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
            box.targetContainer = containerResult.dim;
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
            box.targetContainer = containerResult.dim;
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
            box.targetContainer = containerResult.dim;
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
            box.targetContainer = containerResult.dim;
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

                // Update the dimension
                gtx.setOrReinitDim(sceneObj.index, itemDim);
                
                // Update children positions (linked dimensions)
                var children = gtx.getLinksFromIndex(sceneObj.index);
                for (childIndex in children) {
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
                fillNext = false;
                stretchNext = false;
                return;
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