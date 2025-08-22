package twinspire.maps;

import kha.Image;

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
    * Determines how isometric layers are rendered.
    **/
    public var isGround:Bool;
    /**
    * Set of tiles.
    **/
    public var tiles:Array<Tile>;
    /**
    * The buffer image(s) if any.
    **/
    public var buffer:Array<Image>;
    /**
    * The currently active tile indices in the form of "chunks".
    * Used if the underlying `TileMap` is setup for chunk loading.
    *
    * Prefer to render based on this array compared to `tiles`.
    **/
    public var chunks:Array<Int>;
    /**
    * The tileset for this layer.
    **/
    public var tileset:Tileset;

    public function new() {
        name = "";
        buffered = false;
        isGround = false;
        tiles = [];
        buffer = [];
        chunks = [];
    }

}