package twinspire.ui;

import twinspire.ui.widgets.Button;
import twinspire.scenes.SceneObject;
import twinspire.render.UpdateContext;
import twinspire.render.GraphicsContext;
import twinspire.IdAssoc;

class UITemplate extends Template {
    
    // Static Id variables for UI components
    public static var buttonId:Id;
    

    // Keep a reference to the current builder for each named component
    private var currentBuilders:Map<String, UIBuilder> = new Map();
    
    public function new() {
        super();
        
        // Override builder callback to use UIBuilder
        initBuilderCallback = (name:String, isUpdate:Bool) -> {
            var existingBuilder = currentBuilders.get(name);
            
            if (existingBuilder != null && isUpdate) {
                // Reuse existing builder to preserve SceneObjects
                existingBuilder.prepareForUpdate();
                return existingBuilder;
            } else {
                // Create new builder for first time or non-update scenarios
                var newBuilder = new UIBuilder();
                currentBuilders.set(name, newBuilder);
                return newBuilder;
            }
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
        IdAssoc.assoc[buttonId].update = Button.update;
        IdAssoc.assoc[buttonId].render = Button.render;
        IdAssoc.assoc[buttonId].end = Button.end;

    }
    
    /**
    * Get all SceneObjects for a named component
    */
    public function getUIObjects(name:String):Array<SceneObject> {
        var builder = currentBuilders.get(name);
        return builder != null ? builder.getSceneObjects() : [];
    }
    
    /**
    * Get a specific SceneObject by name and index
    */
    public function getUIObject(name:String, index:Int):SceneObject {
        var objects = getUIObjects(name);
        return (index >= 0 && index < objects.length) ? objects[index] : null;
    }
    
    /**
    * Remove a SceneObject at specific index
    */
    public function removeUIObject(name:String, index:Int):Bool {
        var builder = currentBuilders.get(name);
        return builder != null ? builder.removeSceneObject(index) : false;
    }
    
    public override function addOrUpdateDim(name:String, builder:(IDimBuilder) -> Void, ?scope:AddLogic, ?dependsOn:String) {
        // Call parent implementation - this uses our initBuilderCallback
        super.addOrUpdateDim(name, builder, scope ?? AddLogic.Ui(), dependsOn);
        
        
    }
    
    // Lifecycle methods remain the same but use currentBuilders
    public function updateUI(utx:UpdateContext):Void {
        var gtx = Application.instance.graphicsCtx;
        
        for (builder in currentBuilders) {
            for (obj in builder.getSceneObjects()) {
                if (!gtx.isDimIndexValid(obj.index)) continue;
                
                switch (obj.index) {
                    case Direct(index, render) | Group(index, render): {
                        if (render != null) {
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
        for (builder in currentBuilders) {
            for (obj in builder.getSceneObjects()) {
                if (!gtx.isDimIndexValid(obj.index)) continue;
                
                switch (obj.index) {
                    case Direct(index, render) | Group(index, render): {
                        if (render != null) {
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
        for (builder in currentBuilders) {
            for (obj in builder.getSceneObjects()) {
                if (!gtx.isDimIndexValid(obj.index)) continue;
                
                switch (obj.index) {
                    case Direct(index, render) | Group(index, render): {
                        if (render != null) {
                            IdAssoc.assoc[render].end(gtx, utx, obj);
                        }
                    }
                }
            }
        }
    }

}