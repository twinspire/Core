package twinspire.ui;

import twinspire.ui.widgets.*;
import twinspire.scenes.SceneObject;
import twinspire.render.UpdateContext;
import twinspire.render.GraphicsContext;
import twinspire.IdAssoc;

typedef ContainerState = {
    builderCallback: (IDimBuilder) -> Void,
    dynamicElements: Array<() -> SceneObject>,
    scope: AddLogic,
    containerName: String
}

class UITemplate extends Template {
    
    // Static Id variables for UI components
    public static var buttonId:Id;
    public static var checkboxId:Id;
    public static var boxId:Id;
    

    public var containerStates:Map<String, ContainerState> = new Map();

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

        checkboxId = Application.createId(true);
        IdAssoc.assoc[checkboxId].update = Checkbox.update;
        IdAssoc.assoc[checkboxId].render = Checkbox.render;
        IdAssoc.assoc[checkboxId].end = Checkbox.end;

        boxId = Application.createId(true);
        IdAssoc.assoc[boxId].update = Box.update;
        IdAssoc.assoc[boxId].render = Box.render;
        IdAssoc.assoc[boxId].end = Box.end;
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
        if (!containerStates.exists(name)) {
            containerStates.set(name, {
                builderCallback: builder,
                dynamicElements: [],
                scope: scope ?? AddLogic.Ui(),
                containerName: name
            });
        } else {
            // Update existing state's callback
            var state = containerStates.get(name);
            state.builderCallback = builder;
        }

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

    /**
    * Add a dynamic element to a container - triggers auto-rebuild
    **/
    public function addToContainer(containerName:String, elementFactory:() -> SceneObject):Void {
        var state = containerStates.get(containerName);
        if (state == null) {
            throw 'Container "$containerName" not found';
        }
        
        // Add factory to dynamic elements
        state.dynamicElements.push(elementFactory);
        
        // Auto-rebuild the container
        super.addOrUpdateDim(containerName, state.builderCallback, state.scope);
    }

    /**
    * Remove a dynamic element (by index in dynamic array)
    **/
    public function removeFromContainer(containerName:String, index:Int):Void {
        var state = containerStates.get(containerName);
        if (state != null && index >= 0 && index < state.dynamicElements.length) {
            state.dynamicElements.splice(index, 1);
            
            // Auto-rebuild
            super.addOrUpdateDim(containerName, state.builderCallback, state.scope);
        }
    }

    /**
    * Clear all dynamic elements from a container
    **/
    public function clearContainerDynamic(containerName:String):Void {
        var state = containerStates.get(containerName);
        if (state != null) {
            state.dynamicElements = [];
            
            // Auto-rebuild
            super.addOrUpdateDim(containerName, state.builderCallback, state.scope);
        }
    }

    /**
    * Get dynamic element count for a container
    **/
    public function getDynamicCount(containerName:String):Int {
        var state = containerStates.get(containerName);
        return state != null ? state.dynamicElements.length : 0;
    }

}