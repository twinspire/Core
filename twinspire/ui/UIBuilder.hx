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
import twinspire.AddLogic;

typedef ContainerContext = {
    bounds: Dim,
    orientation: BoxOrientation,
    spacing: Float,
    padding: Float,
    offsetV: Float,  // Current vertical offset
    offsetH: Float,  // Current horizontal offset
    nextX: Float,    // For manual positioning in Stack
    nextY: Float 
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
            dimResult.dim = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(dimResult.index));
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
        
        containerDim = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(containerResult.index));
        
        // Push context onto stack with Stack-specific initialization
        containerStack.push({
            bounds: containerDim,
            orientation: orientation,
            spacing: spacing,
            padding: padding,
            offsetV: padding,
            offsetH: padding,
            nextX: padding,  // Default to padding for Stack
            nextY: padding
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
    * End the current box layout.
    **/
    public function endBox():Void {
        if (containerStack.length == 0) throw "endBox without beginBox";
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
    * Position element in current container
    **/
    private function positionInContainer(elementDim:Dim, elementIndex:DimIndex):Void {
        if (currentContainer == null) return;
    
        var ctx = currentContainer;
        var gtx = Application.instance.graphicsCtx;
        var x:Float = 0;
        var y:Float = 0;
        
        if (ctx.orientation == Vertical) {
            x = ctx.bounds.x + ctx.padding;
            y = ctx.bounds.y + ctx.offsetV;
            
            if (stretchNext) elementDim.width = ctx.bounds.width - (ctx.padding * 2);
            ctx.offsetV += elementDim.height + ctx.spacing;
            
        } else if (ctx.orientation == Horizontal) {
            x = ctx.bounds.x + ctx.offsetH;
            y = ctx.bounds.y + ctx.padding;
            
            if (stretchNext) elementDim.height = ctx.bounds.height - (ctx.padding * 2);
            ctx.offsetH += elementDim.width + ctx.spacing;
            
        } else { // Stack - manual positioning
            // Check for center positioning flag
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