package twinspire.ui;

import twinspire.DimIndex.DimIndexUtils;
import twinspire.ui.widgets.*;
import twinspire.geom.Dim;
import kha.Font;
import kha.math.FastVector2;
import twinspire.scenes.SceneObject;
import twinspire.Dimensions.VerticalAlign;
import twinspire.Dimensions.HorizontalAlign;
import twinspire.Dimensions.DimResult;
import twinspire.AddLogic;

class UIBuilder extends DimBuilder {
    
    // Track SceneObjects created by this builder
    private var sceneObjects:Array<SceneObject> = [];
    private var currentSceneObject:Int = 0;

    private var font:Font;
    private var fontSize:Int;

    private var nextId:Id;
    
    public function new(?existingResults:Array<DimResult>, ?isUpdate:Bool) {
        super(existingResults ?? [], isUpdate ?? false);
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
            checkbox.type = UITemplate.checkboxId;
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
            checkbox.index = Group(gtx.endGroup(), UITemplate.checkboxId);

            if (dimIndex < sceneObjects.length) {
                sceneObjects[dimIndex] = checkbox;
            } else {
                sceneObjects.push(checkbox);
            }
        }

        return checkbox;
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