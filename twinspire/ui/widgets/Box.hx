package twinspire.ui.widgets;

import kha.Color;
import kha.Font;
import twinspire.render.GraphicsContext;
import twinspire.render.UpdateContext;
import twinspire.render.vector.VectorSpace;
import twinspire.scenes.SceneObject;
import twinspire.ui.UITemplate;

enum BoxOrientation {
    Vertical;
    Horizontal;
    Stack;
}

class Box extends SceneObject {

    public var nextX:Float = 0;
    public var nextY:Float = 0;
    
    public var orientation:BoxOrientation;
    public var spacing:Float;
    public var padding:Float;
    public var vectorSpace:VectorSpace;
    
    // Reference to parent template for auto-rebuild
    public var ownerTemplate:UITemplate;
    public var containerName:String;
    
    // Track dynamic content factories
    public var dynamicContent:Array<() -> SceneObject> = [];
    
    // Property that references the VectorSpace children
    public var children(get, never):Array<DimIndex>;
    function get_children():Array<DimIndex> {
        return vectorSpace != null ? vectorSpace.children.copy() : [];
    }
    
    public function new() {
        super();
    }
    
    /**
    * Add dynamic content - triggers template rebuild
    **/
    public function addDynamic(factory:() -> SceneObject):Void {
        if (ownerTemplate != null && containerName != null) {
            ownerTemplate.addToContainer(containerName, factory);
        }
    }
    
    /**
    * Remove dynamic content at index - triggers template rebuild
    **/
    public function removeDynamic(index:Int):Void {
        if (ownerTemplate != null && containerName != null) {
            ownerTemplate.removeFromContainer(containerName, index);
        }
    }

    public static function update(utx:UpdateContext, obj:SceneObject) {
        
    }

    public static function render(gtx:GraphicsContext, obj:SceneObject) {
        
    }

    public static function end(gtx:GraphicsContext, utx:UpdateContext, obj:SceneObject) {
        
    }
}