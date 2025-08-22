package twinspire.maps;

import twinspire.Id;

class TileMap {
    
    /**
    * The unique Id of this map.
    **/
    public var id:Id;
    /**
    * The width in number of cells across.
    **/
    public var width:Int;
    /**
    * The height in number of cells down.
    **/
    public var height:Int;
    /**
    * Determines the perspective of the map.
    **/
    public var perspective:TileMapPerspective;
    /**
    * Set of layers.
    **/
    public var layers:Array<TileMapLayer>;

    public function new() {
        id = Id.None;
        layers = [];
    }

}