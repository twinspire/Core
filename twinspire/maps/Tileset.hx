package twinspire.maps;

import twinspire.geom.Dim;
import kha.math.FastVector2;
import kha.Image;

class Tileset {
    
    /**
    * The image source for this tileset.
    **/
    public var image:Image;
    /**
    * The size of each tile in this tileset.
    **/
    public var tileSize:FastVector2;
    /**
    * An array of rectangles, relative to the tile index from the
    * source image, defining the collision bounds in the tile.
    **/
    public var collisions:Array<Dim>;
    /**
    * An array of flags for each tile at a given index when
    * collision is detected.
    **/
    public var colliderFlags:Array<Int>;
    /**
    * An array of flags for each tile at a given index.
    **/
    public var flags:Array<Int>;

    public function new() {
        collisions = [];
        colliderFlags = [];
        flags = [];
    }

}