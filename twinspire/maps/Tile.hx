package twinspire.maps;

class Tile {
    
    /**
    * The index of the tile to draw from a tileset.
    **/
    public var index:Int;
    /**
    * The offset from its current position.
    **/
    public var offset:FastVector2;
    /**
    * The color tint. Default is White.
    **/
    public var tint:Color;
    /**
    * Transform of the tile.
    **/
    public var transform:FastMatrix3;

    public function new() {
        
    }

}