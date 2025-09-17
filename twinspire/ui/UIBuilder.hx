package twinspire.ui;

import twinspire.DimIndex.DimIndexUtils;
import twinspire.ui.widgets.Button;
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
    private var isUpdating:Bool = false;

    private var font:Font;
    private var fontSize:Int;
    
    public function new(?existingResults:Array<DimResult>, ?isUpdate:Bool) {
        super(existingResults ?? [], isUpdate ?? false);
        isUpdating = isUpdate ?? false;
    }

    private function advanceSceneObject() {
        return currentSceneObject++;
    }

    private function createText(text:String, parent:DimIndex = null) {
        var result = Dimensions.getTextDim(font, fontSize, text, Ui(null, parent));
        add(result);
        return result;
    }

    public function begin() {
        Dimensions.setBuilderContext(this);
    }

    public function end() {
        Dimensions.clearBuilderContext();
    }

    public function setFont(font:Font) {
        this.font = font;
    }

    public function setFontSize(size:Int) {
        this.fontSize = size;
    }

    /**
    * Create a button.
    **/
    public function button(text:String, ?size:FastVector2):Button {
        var gtx = Application.instance.graphicsCtx;

        var dim = new Dim(0, 0, size != null ? size.x : 0, size != null ? size.y : 0);
        var dimResult = Dimensions.createFromDim(dim, Ui());
        var textDimResult = createText(text, dimResult.index);

        if (size == null) {
            Dimensions.dimGrowW(dimResult.index, textDimResult.dim.width + 6);
            Dimensions.dimGrowH(dimResult.index, textDimResult.dim.height + 6);
            dimResult.dim = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(dimResult.index));
            Dimensions.dimAlign(dimResult.index, textDimResult.index, VALIGN_CENTRE, HALIGN_MIDDLE);
        }
        
        add(dimResult);
        var dimIndex = advanceSceneObject();
        
        var button:Button;
        
        if (isUpdating && dimIndex < sceneObjects.length) {
            // Update existing SceneObject
            button = cast(sceneObjects[dimIndex], Button);
            button.targetContainer = dimResult.dim;

        } else {
            // Create new SceneObject
            button = new Button();
            button.type = UITemplate.buttonId;
            button.text = text;
            button.font = font;
            button.fontSize = fontSize;
            button.wrapperIndex = dimResult.index;
            button.textIndex = textDimResult.index;
            button.targetContainer = dimResult.dim;

            gtx.beginGroup();
            gtx.addToGroup(dimResult.index);
            gtx.addToGroup(textDimResult.index);
            button.index = Group(gtx.endGroup(), UITemplate.buttonId);
            
            if (dimIndex < sceneObjects.length) {
                sceneObjects[dimIndex] = button;
            } else {
                sceneObjects.push(button);
            }
        }
        
        return button;
    }

    public function prepareForUpdate():Void {
        isUpdating = true;
        
    }
    
    public function removeSceneObject(index:Int):Bool {
        if (index >= 0 && index < sceneObjects.length) {
            sceneObjects.splice(index, 1);
            return true;
        }
        return false;
    }
    
    public function getSceneObjects():Array<SceneObject> {
        return sceneObjects;
    }
}