package twinspire.render;

import twinspire.scenes.SceneObject;
import twinspire.geom.Dim;

class TrackingObject {
    
    /**
    * The data that this tracking object contains.
    **/
    public var data:Map<String, Dynamic>;
    /**
    * The init callback for this tracking object.
    **/
    public var init:(GraphicsContext, SceneObject) -> SceneObject;
    /**
    * The update callback for this tracking object.
    **/
    public var update:(UpdateContext, SceneObject) -> Void;
    /**
    * The render callback for this tracking object.
    **/
    public var render:(GraphicsContext, SceneObject) -> Void;
    /**
    * The end callback for this tracking object.
    **/
    public var end:(GraphicsContext, UpdateContext, SceneObject) -> Void;

    public function new() {
        data = [];
        init = null;
        update = null;
        render = null;
        end = null;
    }

}