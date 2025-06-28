package twinspire.render;

class AutoTrackInfo {
    
    /**
    * A map of render types to callback functions used to create tracking objects
    * within the `GraphicsContext` class.
    **/
    public static var initTracks:Map<Id, (GraphicsContext, Dynamic)->TrackingObject>;
    /**
    * A map of render types to callback functions used for automatically mapping
    * update functions to newly created dimensions within the `GraphicsContext` class.
    **/
    public static var updateTracks:Map<Id, (UpdateContext, DimIndex)->Void>;
    /**
    * A map of render types to callback functions used for automatically mapping
    * render functions to newly created dimensions within the `GraphicsContext` class.
    **/
    public static var renderTracks:Map<Id, (GraphicsContext, DimIndex)->Void>;
    /**
    * A map of render types to callback functions used for automatically mapping
    * end functions to newly created dimensions within the `GraphicsContext` class.
    **/
    public static var endTracks:Map<Id, (GraphicsContext, UpdateContext, DimIndex)->Void>;

    /**
    * Called by Twinspire internally.
    **/
    public static function init() {
        updateTracks = [];
        renderTracks = [];
        endTracks = [];
    }

}