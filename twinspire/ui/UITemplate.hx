package twinspire.ui;

import twinspire.scenes.SceneObject;
import twinspire.render.UpdateContext;
import twinspire.render.GraphicsContext;
import twinspire.IdAssoc;

class UITemplate extends Template {
    
    // Static Id variables for UI components
    public static var buttonId:Id;
    

    // SceneObject management
    private var sceneObjects:Map<String, Array<SceneObject>> = new Map();
    
    public function new() {
        super();
        
        // Override builder callback to use UIBuilder
        initBuilderCallback = (name:String, isUpdate:Bool) -> {
            var existingResults = dimensionRefs.get(name) ?? [];
            return new UIBuilder(existingResults, isUpdate);
        };

        if (buttonId == null) {
            initIds();
        }
    }
    
    /**
    * Initialize static Id values - call this during application startup
    */
    public static function initIds():Void {
        buttonId = Application.createId(true);
        
    }
    
    public override function addOrUpdateDim(name:String, builder:(IDimBuilder) -> Void, ?scope:AddLogic, ?dependsOn:String) {
        var existingResults = dimensionRefs.get(name);
        var isUpdate = existingResults != null;
        
        var uiBuilder = cast(initBuilderCallback(name, isUpdate), UIBuilder);
        
        if (isUpdate) {
            Dimensions.beginEdit();
        }

        Dimensions.setBuilderContext(uiBuilder);
        builder(uiBuilder);
        Dimensions.clearBuilderContext();
        
        if (isUpdate) {
            Dimensions.endEdit();
        }
        
        // Get results from builder
        var newResults = uiBuilder.getResults();
        var createdObjects = uiBuilder.getSceneObjects();
        var gctx = Application.instance.graphicsCtx;
        
        if (isUpdate) {
            // Handle dimension updates
            for (i in 0...newResults.length) {
                if (i < existingResults.length && existingResults[i].index != null) {
                    gctx.setOrReinitDim(existingResults[i].index, newResults[i].dim);
                    newResults[i].index = existingResults[i].index;
                    
                    // Update corresponding SceneObject index if it exists
                    if (i < createdObjects.length) {
                        createdObjects[i].index = newResults[i].index;
                    }
                } else {
                    // Create new dimension
                    var result = Dimensions.createFromDim(newResults[i].dim, scope ?? AddLogic.Ui());
                    newResults[i] = result;
                    
                    // Update corresponding SceneObject index
                    if (i < createdObjects.length) {
                        createdObjects[i].index = result.index;
                    }
                }
            }
            
            Dimensions.endEdit();
        }
        
        // Store results and objects
        dimensionRefs.set(name, newResults);
        sceneObjects.set(name, createdObjects);
        
        // Handle groups if any
        var groups = uiBuilder.getGroups();
        var groupIndices = uiBuilder.getGroupIndices();
        if (groups.length > 0) {
            groupRefs.set(name, groupIndices);
        }
    }
    
    /**
    * Update all UI components - call this from your main update loop
    */
    public function updateUI(utx:UpdateContext):Void {
        var gtx = Application.instance.graphicsCtx;
        
        for (objectArray in sceneObjects) {
            for (obj in objectArray) {
                if (!gtx.isDimIndexValid(obj.index)) continue;
                
                switch (obj.index) {
                    case Direct(index, render) | Group(index, render): {
                        if (render != null && IdAssoc.assoc.exists(render)) {
                            IdAssoc.assoc[render].update(utx, obj);
                        }
                    }
                }
            }
        }
    }
    
    /**
    * Render all UI components - call this from your main render loop
    */
    public function renderUI(gtx:GraphicsContext):Void {
        for (objectArray in sceneObjects) {
            for (obj in objectArray) {
                if (!gtx.isDimIndexValid(obj.index)) continue;
                
                switch (obj.index) {
                    case Direct(index, render) | Group(index, render): {
                        if (render != null && IdAssoc.assoc.exists(render)) {
                            IdAssoc.assoc[render].render(gtx, obj);
                        }
                    }
                }
            }
        }
    }
    
    /**
    * End frame for all UI components - call this from your main end loop  
    */
    public function endUI(gtx:GraphicsContext, utx:UpdateContext):Void {
        for (objectArray in sceneObjects) {
            for (obj in objectArray) {
                if (!gtx.isDimIndexValid(obj.index)) continue;
                
                switch (obj.index) {
                    case Direct(index, render) | Group(index, render): {
                        if (render != null && IdAssoc.assoc.exists(render)) {
                            IdAssoc.assoc[render].end(gtx, utx, obj);
                        }
                    }
                }
            }
        }
    }
    
    /**
    * Get all SceneObjects for a given component name
    */
    public function getUIObjects(name:String):Array<SceneObject> {
        return sceneObjects.get(name) ?? [];
    }
}