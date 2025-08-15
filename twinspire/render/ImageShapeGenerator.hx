/**
* Generated with assistance from Claude AI - 2025-08-15.
**/

package twinspire.render;

import haxe.io.Bytes;
import kha.math.FastMatrix3;
import kha.Color;
import kha.Image;
import kha.math.FastVector2;

enum ImageShape {
    Star(pos:FastVector2, size:FastVector2, ?modifier:ImageShapeModifier);
    Triangle(points:Array<FastVector2>, ?modifier:ImageShapeModifier);
    Hexagon(pos:FastVector2, size:FastVector2, ?modifier:ImageShapeModifier);
    Oval(pos:FastVector2, size:FastVector2, ?modifier:ImageShapeModifier);
    Cylinder(pos:FastVector2, size:FastVector2, ?modifier:ImageShapeModifier);
    Circle(centrePos:FastVector2, radius:Float, ?modifier:ImageShapeModifier);
    Donut(centrePos:FastVector2, radius:Float, thickness:Float, ?modifier:ImageShapeModifier);
    Spike(centrePos:FastVector2, startDepth:Float, endDepth:Float, curvature:Float, ?modifier:ImageShapeModifier);
    Rectangle(pos:FastVector2, size:FastVector2, ?modifier:ImageShapeModifier);
    Tree(basePoint:FastVector2, height:Float, spread:Float, branches:Float, ?modifier:ImageShapeModifier);
}

typedef ShadowCast = {
    var color:Color;
    /**
    * Whether to cast a circular shadow directly underneath the shape or cast a shadow to
    * the precise shape.
    **/
    var ?circular:Bool;
}

typedef LightCast = {
    var ?color:Color;
    /**
    * Determines the gradient generated on the subject shape. Light casting requires the shape
    * to have a 3D point coordinates assigned to it.
    **/
    var ?glowStrength:Float;
}

typedef Shape = {
    var shape:ImageShape;
    var color:Color;
    var position:FastVector2;
    var ?outline:Float;
    var ?outlineColor:Color;
    var ?transform:FastMatrix3;
    /**
    * The angle of any casting, where 0 means to cast south and 180 north.
    **/
    var ?castingAngle:Float;
    /**
    * Any shadow casted from the shape, where the casting angle causes the shadow to drop from the
    * shape at the given direction.
    **/
    var ?shadow:ShadowCast;
    /**
    * Any light casted towards the shape, where the casting angle is the angle from which the light
    * is cast.
    **/
    var ?light:LightCast;
    /**
    * A collection of points in 2D space upon the subject shape, defining the areas where light can be exposed.
    * The median of the 2D coordinates is used to generate gradients where light hits, and any zones
    * outside the points defined are considered not exposed to light.
    *
    * When precise shape shadow casting is used, the combination of the casting angle and the defined points
    * determine the final shape of the shadow.
    *
    * If the shadow is cast behind the shape, it is rendered before the shape, otherwise after.
    **/
    var ?points3D:Array<FastVector2>;
}

typedef Layer = {
    var name:String;
    var shapes:Array<Shape>;
    var visible:Bool;
    var opacity:Float;
}

/**
* A CPU-bound shape generation tool. Useful for generating static images.
**/
class ImageShapeGenerator {

    /**
    * private variables
    **/
    private var width:Int;
    private var height:Int;
    private var finalImage:Image;
    private var layers:Array<Layer>;
    private var _renderer:ImageEffectRenderer;

    /**
    * Get the renderer for this shape generator to add effects.
    **/
    public var renderer(get, never):ImageEffectRenderer;
    function get_renderer():ImageEffectRenderer {
        if (_renderer == null) {
            // Create a blank image for the renderer if needed
            var blankImage = Image.createRenderTarget(width, height);
            _renderer = new ImageEffectRenderer(blankImage);
        }
        return _renderer;
    }

    /**
    * Background colour of this image.
    **/
    public var background:Color;
    
    public function new(width:Float, height:Float) {
        this.width = Std.int(width);
        this.height = Std.int(height);
        this.background = Color.White;
        this.layers = [];
        this.finalImage = null;
        
        // Create default layer
        addLayer("Background");
    }

    /**
    * Resize the image, clipping any shapes if shrinking.
    **/
    public function resize(width:Float, height:Float) {
        this.width = Std.int(width);
        this.height = Std.int(height);
        
        // Reset the renderer to match new dimensions
        _renderer = null;
        finalImage = null;
        
        // Clip shapes that are now outside bounds if shrinking
        for (layer in layers) {
            for (shape in layer.shapes) {
                // Clamp position to new bounds
                if (shape.position.x > width) {
                    shape.position.x = width;
                }
                if (shape.position.y > height) {
                    shape.position.y = height;
                }
            }
        }
    }

    /**
    * Adds a shape to a given layer, returning the index.
    **/
    public function addShape(shape:Shape, layerIndex:Int):Int {
        if (layerIndex < 0 || layerIndex >= layers.length) {
            return -1;
        }
        
        layers[layerIndex].shapes.push(shape);
        return layers[layerIndex].shapes.length - 1;
    }

    /**
    * Move a shape within shapes.
    **/
    public function moveShape(index:Int, newIndex:Int) {
        // Find shape across all layers
        for (layer in layers) {
            if (index < layer.shapes.length) {
                var shape = layer.shapes[index];
                layer.shapes.splice(index, 1);
                
                // Clamp newIndex to valid range
                if (newIndex < 0) newIndex = 0;
                if (newIndex >= layer.shapes.length) newIndex = layer.shapes.length;
                
                layer.shapes.insert(newIndex, shape);
                return;
            }
            index -= layer.shapes.length;
        }
    }

    /**
    * Delete a shape at the given index.
    **/
    public function deleteShape(index:Int) {
        // Find and remove shape across all layers
        for (layer in layers) {
            if (index < layer.shapes.length) {
                layer.shapes.splice(index, 1);
                return;
            }
            index -= layer.shapes.length;
        }
    }

    /**
    * Modify the internal shape at a given index.
    **/
    public function modifyShape(index:Int, shape:ImageShape) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            foundShape.shape = shape;
        }
    }

    /**
    * Modify the colour of a shape.
    **/
    public function modifyShapeColor(index:Int, color:Color) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            foundShape.color = color;
        }
    }

    /**
    * Modify the position of a shape.
    **/
    public function modifyShapePosition(index:Int, position:FastVector2) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            foundShape.position = position;
        }
    }

    /**
    * Set transformation of a shape.
    **/
    public function modifyShapeTransform(index:Int, transform:FastMatrix3) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            foundShape.transform = transform;
        }
    }

    /**
    * Rotate a shape.
    **/
    public function modifyShapeRotate(index:Int, angle:Float) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            var rotation = FastMatrix3.rotation(angle);
            if (foundShape.transform != null) {
                foundShape.transform = foundShape.transform.multmat(rotation);
            } else {
                foundShape.transform = rotation;
            }
        }
    }

    /**
    * Rotate a shape to look towards 3D coordinates, translated to a 2D matrix.
    **/
    public function modifyShapeRotate3D(index:Int, x:Float, y:Float, z:Float) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            // Calculate 3D vector from shape position to target point
            var dx = x - foundShape.position.x;
            var dy = y - foundShape.position.y;
            var dz = z; // Z difference from the 2D plane (assumed at z=0)
            
            // Calculate horizontal rotation (yaw) - rotation around Z axis
            var yaw = Math.atan2(dy, dx);
            
            // Calculate vertical rotation (pitch) - creates skewing effect
            var horizontalDistance = Math.sqrt(dx * dx + dy * dy);
            var pitch = Math.atan2(dz, horizontalDistance);
            
            // Create perspective transformation matrix
            // This simulates looking up/down by skewing the shape
            var perspectiveMatrix = FastMatrix3.identity();
            
            // Apply pitch as skew transformation
            // Positive Z (looking up) creates upward skew
            // Negative Z (looking down) creates downward skew
            var skewFactor = Math.sin(pitch) * 0.5; // Scale factor for skew intensity
            
            // Apply horizontal rotation
            var cosYaw = Math.cos(yaw);
            var sinYaw = Math.sin(yaw);
            
            // Rotation matrix for yaw
            perspectiveMatrix._00 = cosYaw;
            perspectiveMatrix._01 = -sinYaw;
            perspectiveMatrix._10 = sinYaw;
            perspectiveMatrix._11 = cosYaw;
            
            // Add skew effect for pitch (Z component)
            // Skew in Y direction based on X position for pitch effect
            perspectiveMatrix._01 += skewFactor;
            
            // Apply foreshortening effect for Z distance
            var distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
            var foreShorten = 1.0 / (1.0 + Math.abs(dz) * 0.001); // Subtle foreshortening
            perspectiveMatrix._00 *= foreShorten;
            perspectiveMatrix._11 *= foreShorten;
            
            if (foundShape.transform != null) {
                foundShape.transform = foundShape.transform.multmat(perspectiveMatrix);
            } else {
                foundShape.transform = perspectiveMatrix;
            }
        }
    }

    /**
    * Bevel a shape using a transform from a given anchor point and stretch/shrink based on the strength value.
    **/
    public function modifyShapeBevel(index:Int, anchor:FastVector2, strength:Float) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            // Create bevel transform (skew effect from anchor point)
            var dx = foundShape.position.x - anchor.x;
            var dy = foundShape.position.y - anchor.y;
            var distance = Math.sqrt(dx * dx + dy * dy);
            
            var bevelFactor = strength * (1.0 / Math.max(distance, 1.0));
            var bevel = FastMatrix3.identity();
            bevel._20 = bevelFactor * (dx / distance);
            bevel._21 = bevelFactor * (dy / distance);
            
            if (foundShape.transform != null) {
                foundShape.transform = foundShape.transform.multmat(bevel);
            } else {
                foundShape.transform = bevel;
            }
        }
    }

    /**
    * Skew a shape by an amount on the x or y axis.
    **/
    public function modifyShapeSkew(index:Int, skew:FastVector2) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            var skewMatrix = FastMatrix3.identity();
            skewMatrix._10 = skew.x;
            skewMatrix._01 = skew.y;
            
            if (foundShape.transform != null) {
                foundShape.transform = foundShape.transform.multmat(skewMatrix);
            } else {
                foundShape.transform = skewMatrix;
            }
        }
    }

    /**
    * Modify the shapes outline.
    **/
    public function modifyShapeOutline(index:Int, outline:Float) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            foundShape.outline = outline;
        }
    }

    /**
    * Modify the shapes outline colour.
    **/
    public function modifyShapeOutlineColor(index:Int, outlineColor:Color) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            foundShape.outlineColor = outlineColor;
        }
    }

    /**
    * Modify a shape's casting angle.
    **/
    public function modifyShapeCasting(index:Int, castingAngle:Float) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            foundShape.castingAngle = castingAngle;
        }
    }

    public function modifyShapeShadow(index:Int, shadow:ShadowCast) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            foundShape.shadow = shadow;
        }
    }

    public function modifyShapeLight(index:Int, light:LightCast) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            foundShape.light = light;
        }
    }

    public function modifyShapePoints(index:Int, points3D:Array<FastVector2>) {
        var foundShape = getShapeRef(index);
        if (foundShape != null) {
            foundShape.points3D = points3D;
        }
    }

    public function getShape(index:Int):Shape {
        return getShapeRef(index);
    }

    public function moveShapeToLayer(index:Int, layerIndex:Int) {
        if (layerIndex < 0 || layerIndex >= layers.length) {
            return;
        }
        
        // Find and remove shape from current layer
        var shape:Shape = null;
        for (layer in layers) {
            if (index < layer.shapes.length) {
                shape = layer.shapes[index];
                layer.shapes.splice(index, 1);
                break;
            }
            index -= layer.shapes.length;
        }
        
        // Add to new layer
        if (shape != null) {
            layers[layerIndex].shapes.push(shape);
        }
    }

    /**
    * Add a layer with the given name and return the index.
    **/
    public function addLayer(name:String):Int {
        var layer:Layer = {
            name: name,
            shapes: [],
            visible: true,
            opacity: 1.0
        };
        
        layers.push(layer);
        return layers.length - 1;
    }

    /**
    * Rename a layer at the given index.
    **/
    public function renameLayer(index:Int, name:String) {
        if (index >= 0 && index < layers.length) {
            layers[index].name = name;
        }
    }

    /**
    * Move a given layer.
    **/
    public function moveLayer(index:Int, newIndex:Int) {
        if (index < 0 || index >= layers.length || newIndex < 0 || newIndex >= layers.length) {
            return;
        }
        
        var layer = layers[index];
        layers.splice(index, 1);
        layers.insert(newIndex, layer);
    }

    /**
    * Delete a given layer and any shapes assigned to it.
    **/
    public function deleteLayer(index:Int) {
        if (index >= 0 && index < layers.length) {
            // Don't allow deletion of the last layer
            if (layers.length <= 1) {
                return;
            }
            
            layers.splice(index, 1);
        }
    }

    /**
    * Get the pixel data of a layer.
    **/
    public function getLayerData(index:Int):haxe.io.Bytes {
        if (index < 0 || index >= layers.length) {
            return null;
        }
        
        var layer = layers[index];
        if (!layer.visible) {
            // Return transparent layer data
            return createTransparentLayer();
        }
        
        // Create byte buffer for RGBA data
        var bytesPerPixel = 4;
        var totalBytes = width * height * bytesPerPixel;
        var layerData = haxe.io.Bytes.alloc(totalBytes);
        
        // Initialize with transparent background
        for (i in 0...totalBytes) {
            layerData.set(i, 0);
        }
        
        // Render each shape in the layer
        for (shape in layer.shapes) {
            renderShapeToBytes(shape, layerData);
        }
        
        // Apply layer opacity
        if (layer.opacity < 1.0) {
            applyOpacity(layerData, layer.opacity);
        }
        
        return layerData;
    }
    
    /**
    * Create a transparent layer of the current dimensions.
    **/
    private function createTransparentLayer():haxe.io.Bytes {
        var bytesPerPixel = 4;
        var totalBytes = width * height * bytesPerPixel;
        var transparentData = haxe.io.Bytes.alloc(totalBytes);
        
        for (i in 0...totalBytes) {
            transparentData.set(i, 0);
        }
        
        return transparentData;
    }
    
    /**
    * Render a single shape to the byte buffer.
    **/
    private function renderShapeToBytes(shape:Shape, buffer:haxe.io.Bytes) {
        switch (shape.shape) {
            case Rectangle(pos, size, modifier): {
                renderRectangle(shape, pos, size, buffer);
            }
            default: {
                // TODO: Implement other shapes
                trace('Shape rendering not yet implemented: ${shape.shape}');
            }
        }
    }
    
    /**
    * Render a rectangle shape to the byte buffer.
    **/
    private function renderRectangle(shape:Shape, pos:FastVector2, size:FastVector2, buffer:haxe.io.Bytes) {
        // Apply transform if present
        var renderPos = shape.position.add(pos);
        var renderSize = size;
        
        if (shape.transform != null) {
            // Apply transformation to corners and calculate bounding box
            var corners = [
                new FastVector2(renderPos.x, renderPos.y),
                new FastVector2(renderPos.x + renderSize.x, renderPos.y),
                new FastVector2(renderPos.x + renderSize.x, renderPos.y + renderSize.y),
                new FastVector2(renderPos.x, renderPos.y + renderSize.y)
            ];
            
            // Transform all corners
            for (i in 0...corners.length) {
                corners[i] = transformPoint(corners[i], shape.transform);
            }
            
            // Render transformed rectangle using scanline algorithm
            renderTransformedRectangle(corners, shape, buffer);
            return;
        }
        
        // Simple axis-aligned rectangle
        var startX = Std.int(Math.max(0, renderPos.x));
        var startY = Std.int(Math.max(0, renderPos.y));
        var endX = Std.int(Math.min(width, renderPos.x + renderSize.x));
        var endY = Std.int(Math.min(height, renderPos.y + renderSize.y));
        
        // Extract color components
        var r = Std.int(shape.color.R * 255);
        var g = Std.int(shape.color.G * 255);
        var b = Std.int(shape.color.B * 255);
        var a = Std.int(shape.color.A * 255);
        
        // Draw filled rectangle
        for (y in startY...endY) {
            for (x in startX...endX) {
                var pixelIndex = (y * width + x) * 4;
                
                // Handle outline
                var isOutline = false;
                if (shape.outline != null && shape.outline > 0) {
                    var distanceFromEdge = Math.min(
                        Math.min(x - startX, endX - 1 - x),
                        Math.min(y - startY, endY - 1 - y)
                    );
                    isOutline = distanceFromEdge < shape.outline;
                }
                
                if (isOutline && shape.outlineColor != null) {
                    // Draw outline
                    buffer.set(pixelIndex, Std.int(shape.outlineColor.R * 255));
                    buffer.set(pixelIndex + 1, Std.int(shape.outlineColor.G * 255));
                    buffer.set(pixelIndex + 2, Std.int(shape.outlineColor.B * 255));
                    buffer.set(pixelIndex + 3, Std.int(shape.outlineColor.A * 255));
                } else {
                    // Draw fill
                    buffer.set(pixelIndex, r);
                    buffer.set(pixelIndex + 1, g);
                    buffer.set(pixelIndex + 2, b);
                    buffer.set(pixelIndex + 3, a);
                }
            }
        }
    }
    
    /**
    * Render a transformed rectangle using scanline algorithm.
    **/
    private function renderTransformedRectangle(corners:Array<FastVector2>, shape:Shape, buffer:haxe.io.Bytes) {
        // Find bounding box of transformed rectangle
        var minX = Math.floor(corners[0].x);
        var maxX = Math.ceil(corners[0].x);
        var minY = Math.floor(corners[0].y);
        var maxY = Math.ceil(corners[0].y);
        
        for (i in 1...corners.length) {
            minX = Math.min(minX, Math.floor(corners[i].x));
            maxX = Math.max(maxX, Math.ceil(corners[i].x));
            minY = Math.min(minY, Math.floor(corners[i].y));
            maxY = Math.max(maxY, Math.ceil(corners[i].y));
        }
        
        // Clamp to image bounds
        minX = Math.max(0, Std.int(minX));
        maxX = Math.min(width, Std.int(maxX));
        minY = Math.max(0, Std.int(minY));
        maxY = Math.min(height, Std.int(maxY));
        
        // Extract color components
        var r = Std.int(shape.color.R * 255);
        var g = Std.int(shape.color.G * 255);
        var b = Std.int(shape.color.B * 255);
        var a = Std.int(shape.color.A * 255);
        
        // Test each pixel in bounding box
        for (y in minY...maxY) {
            for (x in minX...maxX) {
                var point = new FastVector2(x, y);
                
                // Use point-in-polygon test
                if (isPointInPolygon(point, corners)) {
                    var pixelIndex = (y * width + x) * 4;
                    
                    buffer.set(pixelIndex, r);
                    buffer.set(pixelIndex + 1, g);
                    buffer.set(pixelIndex + 2, b);
                    buffer.set(pixelIndex + 3, a);
                }
            }
        }
    }
    
    /**
    * Transform a point using a FastMatrix3.
    **/
    private function transformPoint(point:FastVector2, transform:FastMatrix3):FastVector2 {
        var x = point.x * transform._00 + point.y * transform._10 + transform._20;
        var y = point.x * transform._01 + point.y * transform._11 + transform._21;
        return new FastVector2(x, y);
    }
    
    /**
    * Test if a point is inside a polygon using ray casting algorithm.
    **/
    private function isPointInPolygon(point:FastVector2, vertices:Array<FastVector2>):Bool {
        var inside = false;
        var j = vertices.length - 1;
        
        for (i in 0...vertices.length) {
            var vi = vertices[i];
            var vj = vertices[j];
            
            if (((vi.y > point.y) != (vj.y > point.y)) &&
                (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x)) {
                inside = !inside;
            }
            j = i;
        }
        
        return inside;
    }
    
    /**
    * Apply opacity to a layer's byte data.
    **/
    private function applyOpacity(buffer:haxe.io.Bytes, opacity:Float) {
        var bytesPerPixel = 4;
        var totalPixels = Std.int(buffer.length / bytesPerPixel);
        
        for (i in 0...totalPixels) {
            var alphaIndex = i * bytesPerPixel + 3;
            var currentAlpha = buffer.get(alphaIndex);
            var newAlpha = Std.int(currentAlpha * opacity);
            buffer.set(alphaIndex, newAlpha);
        }
    }

    /**
    * Flatten parts or all the layers to a single layer, ensuring the last layer is always
    * the top-most.
    **/
    public function flatten(?indices:Array<Int>) {
        if (indices == null) {
            // Flatten all layers
            indices = [for (i in 0...layers.length) i];
        }
        
        if (indices.length <= 1) {
            return;
        }
        
        // Sort indices to process from bottom to top
        indices.sort((a, b) -> a - b);
        
        // Collect all shapes from specified layers
        var allShapes:Array<Shape> = [];
        var targetLayer = layers[indices[0]];
        
        for (i in indices) {
            if (i >= 0 && i < layers.length) {
                var layer = layers[i];
                for (shape in layer.shapes) {
                    allShapes.push(shape);
                }
            }
        }
        
        // Clear target layer and add all shapes
        targetLayer.shapes = allShapes;
        targetLayer.name = "Flattened Layer";
        
        // Remove other layers (in reverse order to maintain indices)
        var layersToRemove = indices.copy();
        layersToRemove.shift(); // Don't remove target layer
        layersToRemove.reverse();
        
        for (i in layersToRemove) {
            if (i < layers.length) {
                layers.splice(i, 1);
            }
        }
    }

    /**
    * Export the image to a byte array in the given format.
    *
    * Valid format extensions: png, jpg
    **/
    public function export(format:String) {
        // TODO: Implement image export
        // This would render all visible layers to a final image
        // and export in the specified format
    }

    /**
    * Helper function to get a reference to a shape by global index.
    **/
    private function getShapeRef(index:Int):Shape {
        for (layer in layers) {
            if (index < layer.shapes.length) {
                return layer.shapes[index];
            }
            index -= layer.shapes.length;
        }
        return null;
    }

}