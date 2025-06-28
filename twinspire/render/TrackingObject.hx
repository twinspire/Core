package twinspire.render;

class TrackingObject {
    
    /**
    * The data that this tracking object contains.
    **/
    public var data:Map<String, Dynamic>;
    /**
    * The update callback for this tracking object.
    **/
    public var update:(UpdateContext, DimIndex) -> Void;
    /**
    * The render callback for this tracking object.
    **/
    public var render:(GraphicsContext, DimIndex) -> Void;
    /**
    * The end callback for this tracking object.
    **/
    public var end:(GraphicsContext, UpdateContext, DimIndex) -> Void;

    public function new() {
        data = [];
        update = null;
        render = null;
        end = null;
    }

}