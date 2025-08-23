package twinspire.maps;

import twinspire.geom.Dim;
import twinspire.Id;

import kha.math.FastMatrix3;
import kha.math.FastVector2;
import kha.Image;
import kha.Color;

using StringTools;

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
    /**
    * A copy of collision information loaded from each tile layer.
    **/
    public var collisions:Array<Array<Dim>>;
    /**
    * A copy of collider flag data from tilesets for each tile layer.
    **/
    public var colliderFlags:Array<Array<Int>>;
    /**
    * A copy of flag data from tilesets for each tile layer.
    **/
    public var flags:Array<Array<Int>>;
    /**
    * The size, in tiles across and down, of each chunk in memory.
    * Use `loadChunksDynamic` to load/unload dynamically
    * chunks of data into layers.
    **/
    public var chunks:FastVector2;
    /**
    * Determines if the map should be loaded in chunks, rather
    * than altogether from file.
    **/
    public var chunked:Bool;
    /**
    * Determines if this map should be streamed from file.
    * 
    * If chunks are used, only parts of the map are streamed, based on the chunk
    * configuration.
    **/
    public var stream:Bool;
    /**
    * Stored custom data.
    **/
    public var custom:Map<String, Dynamic>;

    public function new() {
        id = Id.None;
        layers = [];

        collisions = [];
        colliderFlags = [];
        flags = [];
    }

    /**
    * Load and unload chunks based on the given `centerX` and `centerY` parameters.
    * These values are considered the scope from which to scan tiles around it, loading
    * all the visible chunks and chunks immediately adjacent to them.
    *
    * The chunks loaded are returned as an array of integers as indices of the chunks
    * loaded in memory.
    *
    * Any chunks already loaded that are not part of the resulting array are removed
    * from memory. Call this function as many times as necessary.
    **/
    public function loadChunksDynamic(centerX:Float, centerY:Float):Array<Int> {
        return null;
    }

    /**
    * Get CSV data from a given resource name and attempt to convert each value to integers.
    *
    * If there is a parsing error, the returned value is `null`.
    **/
    public static function getCsvData(resource:String):Array<Int> {
        try {
            var blob = Application.resources.getBlob(resource);
            if (blob == null) {
                trace('Failed to load CSV resource: $resource');
                return null;
            }
            
            var csvText = blob.readUtf8String();
            if (csvText == null || csvText.length == 0) {
                trace('CSV resource is empty: $resource');
                return null;
            }
            
            var data = new Array<Int>();
            var lines = csvText.split('\n');
            
            for (line in lines) {
                // Skip empty lines
                if (line.trim().length == 0) {
                    continue;
                }
                
                var values = line.split(',');
                for (value in values) {
                    var trimmedValue = value.trim();
                    if (trimmedValue.length > 0) {
                        var intValue = Std.parseInt(trimmedValue);
                        if (intValue == null) {
                            trace('Failed to parse CSV value to integer: $trimmedValue in resource: $resource');
                            return null;
                        }
                        data.push(intValue);
                    }
                }
            }
            
            return data;
        }
        catch (e:Dynamic) {
            trace('Error loading CSV data from resource: $resource - $e');
            return null;
        }
    }

    /**
    * Create and load a tile map with the given parameters.
    *
    * If any tileset or data is `null`, `null` is returned from this function and an error logged.
    *
    * @param name Name of the tile map.
    * @param width Width of the map in tiles.
    * @param height Height of the map in tiles.
    * @param tilesets An array of tilesets used for each layer.
    * @param data An array of arrays, where the first dimension of the array is the layer, and the second dimension are indices
    * referring to the tile source of the respective tileset.
    **/
    public static function loadMap(name:String, width:Int, height:Int, tilesets:Array<Tileset>, data:Array<Array<Int>>):TileMap {
        // Validate input parameters
        if (tilesets == null || tilesets.length == 0) {
            trace('Cannot create tile map "$name": tilesets array is null or empty');
            return null;
        }
        
        if (data == null || data.length == 0) {
            trace('Cannot create tile map "$name": data array is null or empty');
            return null;
        }
        
        if (data.length != tilesets.length) {
            trace('Cannot create tile map "$name": data layers (${data.length}) do not match tileset count (${tilesets.length})');
            return null;
        }
        
        if (width <= 0 || height <= 0) {
            trace('Cannot create tile map "$name": invalid dimensions ($width x $height)');
            return null;
        }
        
        // Create the tile map
        var tileMap = new TileMap();
        tileMap.id = Application.createId();
        tileMap.width = width;
        tileMap.height = height;
        tileMap.perspective = TileMapPerspective.TopDown;
        tileMap.layers = [];
        tileMap.collisions = [];
        tileMap.colliderFlags = [];
        tileMap.flags = [];
        tileMap.chunked = false;
        tileMap.stream = false;
        tileMap.custom = new Map<String, Dynamic>();
        tileMap.custom.set("name", name);
        
        var expectedDataSize = width * height;
        
        // Create layers from data
        for (layerIndex in 0...data.length) {
            var layerData = data[layerIndex];
            var tileset = tilesets[layerIndex];
            
            if (tileset == null) {
                trace('Cannot create tile map "$name": tileset at layer $layerIndex is null');
                return null;
            }
            
            if (layerData == null) {
                trace('Cannot create tile map "$name": data at layer $layerIndex is null');
                return null;
            }
            
            if (layerData.length != expectedDataSize) {
                trace('Cannot create tile map "$name": layer $layerIndex data size (${layerData.length}) does not match expected size ($expectedDataSize)');
                return null;
            }
            
            // Create the layer
            var layer = new TileMapLayer();
            layer.name = 'Layer_$layerIndex';
            layer.buffered = false;
            layer.isGround = layerIndex == 0; // First layer is ground by default
            layer.tiles = [];
            layer.buffer = [];
            layer.chunks = [];
            layer.tileset = tileset;
            
            // Create tiles from data
            for (tileIndex in 0...layerData.length) {
                var tileId = layerData[tileIndex];
                
                var tile = new Tile();
                tile.index = tileId;
                tile.offset = new FastVector2(0, 0);
                tile.tint = Color.White;
                tile.transform = FastMatrix3.identity();
                
                layer.tiles.push(tile);
            }
            
            tileMap.layers.push(layer);
            
            // Copy collision data from tileset
            var layerCollisions = new Array<Dim>();
            var layerColliderFlags = new Array<Int>();
            var layerFlags = new Array<Int>();
            
            for (tileIndex in 0...layerData.length) {
                var tileId = layerData[tileIndex];
                
                // Get collision data for this tile from tileset
                if (tileId >= 0 && tileId < tileset.collisions.length && tileset.collisions[tileId] != null) {
                    layerCollisions.push(tileset.collisions[tileId]);
                } else {
                    layerCollisions.push(null);
                }
                
                // Get collider flags for this tile from tileset
                if (tileId >= 0 && tileId < tileset.colliderFlags.length) {
                    layerColliderFlags.push(tileset.colliderFlags[tileId]);
                } else {
                    layerColliderFlags.push(0);
                }
                
                // Get flags for this tile from tileset
                if (tileId >= 0 && tileId < tileset.flags.length) {
                    layerFlags.push(tileset.flags[tileId]);
                } else {
                    layerFlags.push(0);
                }
            }
            
            tileMap.collisions.push(layerCollisions);
            tileMap.colliderFlags.push(layerColliderFlags);
            tileMap.flags.push(layerFlags);
        }
        
        return tileMap;
    }

    /**
    * Load a tileset from an image and JSON resource containing tileset data.
    *
    * @param image The image source for this tileset.
    * @param resource The resource name of the JSON file containing tileset data.
    * @return A new Tileset instance or null if loading fails.
    **/
    public static function loadTileset(image:Image, resource:String):Tileset {
        if (image == null) {
            trace('Cannot load tileset: image is null');
            return null;
        }
        
        try {
            var blob = Application.resources.getBlob(resource);
            if (blob == null) {
                trace('Failed to load tileset resource: $resource');
                return null;
            }
            
            var jsonText = blob.readUtf8String();
            if (jsonText == null || jsonText.length == 0) {
                trace('Tileset resource is empty: $resource');
                return null;
            }
            
            var jsonData = haxe.Json.parse(jsonText);
            if (jsonData == null) {
                trace('Failed to parse JSON from tileset resource: $resource');
                return null;
            }
            
            var tileset = new Tileset();
            tileset.image = image;
            
            // Parse tile size
            if (jsonData.tileSize != null) {
                if (jsonData.tileSize.x != null && jsonData.tileSize.y != null) {
                    tileset.tileSize = new FastVector2(jsonData.tileSize.x, jsonData.tileSize.y);
                } else {
                    trace('Invalid tileSize format in tileset resource: $resource');
                    return null;
                }
            } else {
                trace('Missing tileSize in tileset resource: $resource');
                return null;
            }
            
            // Parse collisions array
            if (jsonData.collisions != null) {
                tileset.collisions = [];
                for (collisionData in cast(jsonData.collisions, Array<Dynamic>)) {
                    if (collisionData == null) {
                        tileset.collisions.push(null);
                    } else {
                        if (collisionData.x != null && collisionData.y != null && 
                            collisionData.width != null && collisionData.height != null) {
                            var collision = new Dim(collisionData.x, collisionData.y, 
                                                collisionData.width, collisionData.height);
                            tileset.collisions.push(collision);
                        } else {
                            trace('Invalid collision data format at index ${tileset.collisions.length} in tileset resource: $resource');
                            return null;
                        }
                    }
                }
            } else {
                tileset.collisions = [];
            }
            
            // Parse colliderFlags array
            if (jsonData.colliderFlags != null) {
                tileset.colliderFlags = [];
                for (flagData in cast (jsonData.colliderFlags, Array<Dynamic>)) {
                    if (flagData == null) {
                        tileset.colliderFlags.push(0); // Default to 0 for null flags
                    } else {
                        tileset.colliderFlags.push(cast(flagData, Int));
                    }
                }
            } else {
                tileset.colliderFlags = [];
            }
            
            // Parse flags array
            if (jsonData.flags != null) {
                tileset.flags = [];
                for (flagData in cast(jsonData.flags, Array<Dynamic>)) {
                    if (flagData == null) {
                        tileset.flags.push(0); // Default to 0 for null flags
                    } else {
                        tileset.flags.push(cast(flagData, Int));
                    }
                }
            } else {
                tileset.flags = [];
            }
            
            return tileset;
        }
        catch (e:Dynamic) {
            trace('Error loading tileset from resource: $resource - $e');
            return null;
        }
    }

    /**
    * Load a map from a Tiled (*.tmx) file. Tiled specific data is stored in `custom` of the `TileMap` instance.
    *
    * @param resource The resource name of the Tiled file.
    * @param convert Attempt to convert custom properties into a Twinspire-specific equivalent. Use this for better syncing between
    * Twinspire and Tiled.
    **/
    public static function loadMapFromTiled(resource:String, ?convert:Bool):TileMap {
        return null;
    }

    /**
    * Convert the supplied `map` to a Tiled map to the given `output` path.
    * 
    * Any Twinspire-specific data is converted to custom properties in the Tiled format for the map, tilesets and tiles.
    * This function only works on native platforms or targets where `sys` is available.
    *
    * @param map The map to convert.
    * @param output The output file path.
    **/
    public static function convertMapToTiled(map:TileMap, output:String) {

    }

}