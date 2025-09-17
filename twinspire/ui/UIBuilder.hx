package twinspire.ui;

import twinspire.scenes.SceneObject;
import twinspire.Dimensions.DimResult;
import twinspire.AddLogic;

class UIBuilder extends DimBuilder {
    
    // Track SceneObjects created by this builder
    private var sceneObjects:Array<SceneObject> = [];
    
    public function new(existingResults:Array<DimResult>, isUpdate:Bool) {
        super(existingResults, isUpdate);

    }
    
    /**
    * Get all SceneObjects created by this builder
    */
    public function getSceneObjects():Array<SceneObject> {
        return sceneObjects;
    }
    
    /**
    * Clear the SceneObjects array (used when updating)
    */
    public function clearSceneObjects():Void {
        sceneObjects = [];
    }
}