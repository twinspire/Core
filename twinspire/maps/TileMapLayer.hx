package twinspire.maps;

class TileMapLayer {
    
    /**
    * The name of the layer.
    **/
    public var name:String;
    /**
    * Whether the layer should be loaded as a bitmap.
    * If dynamic changes are required, leave this `false`.
    **/
    public var buffered:Bool;
    /**
    * Specifies if the layer is considered the "ground".
    * This alters sprite physics in `UpdateContext`.
    **/
    public var isGround:Bool;
    /**
    * Set of tiles.
    **/
    public var tiles:Array<Tile>;

}