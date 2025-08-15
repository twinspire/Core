/**
* Generated with Claude AI - 2025-08-14
**/

package twinspire.utils;

import kha.math.Vector2i;

/**
* A utility class for generating Perlin noise values for procedural generation.
* Based on Ken Perlin's improved noise function (2002).
**/
class PerlinNoise {
    
    private static var _permutation:Array<Int>;
    private static var _gradients:Array<Array<Float>>;
    private static var _initialized:Bool = false;
    
    /**
    * Initialize the Perlin noise generator with a given seed.
    * Call this once before using any noise functions.
    **/
    public static function init(?seed:Int) {
        if (seed == null) {
            seed = Math.round(Date.now().getTime() % 1000000);
        }
        
        // Initialize permutation table
        _permutation = [];
        for (i in 0...256) {
            _permutation.push(i);
        }
        
        // Shuffle using seed-based random
        shuffleArray(_permutation, seed);
        
        // Duplicate the permutation table to avoid overflow
        for (i in 0...256) {
            _permutation.push(_permutation[i]);
        }
        
        // Initialize gradient vectors (12 gradients as used in improved Perlin noise)
        _gradients = [
            [1, 1, 0], [-1, 1, 0], [1, -1, 0], [-1, -1, 0],
            [1, 0, 1], [-1, 0, 1], [1, 0, -1], [-1, 0, -1],
            [0, 1, 1], [0, -1, 1], [0, 1, -1], [0, -1, -1]
        ];
        
        _initialized = true;
    }
    
    /**
    * Generate a 2D Perlin noise value at the given coordinates.
    * Returns a value typically between -1.0 and 1.0, but can exceed this range slightly.
    **/
    public static function noise2D(x:Float, y:Float):Float {
        if (!_initialized) {
            init();
        }
        
        // Find unit grid cell containing point
        var xi = Math.floor(x) & 255;
        var yi = Math.floor(y) & 255;
        
        // Get relative position within cell
        var xf = x - Math.floor(x);
        var yf = y - Math.floor(y);
        
        // Compute fade curves for xf and yf
        var u = fade(xf);
        var v = fade(yf);
        
        // Hash coordinates of 4 corners
        var aa = _permutation[_permutation[xi] + yi];
        var ab = _permutation[_permutation[xi] + yi + 1];
        var ba = _permutation[_permutation[xi + 1] + yi];
        var bb = _permutation[_permutation[xi + 1] + yi + 1];
        
        // Calculate gradient dot products at each corner
        var x1 = lerp(grad2D(aa, xf, yf), grad2D(ba, xf - 1, yf), u);
        var x2 = lerp(grad2D(ab, xf, yf - 1), grad2D(bb, xf - 1, yf - 1), u);
        
        return lerp(x1, x2, v);
    }
    
    /**
    * Generate fractal (octave-based) Perlin noise for more natural-looking results.
    * 
    * @param x X coordinate
    * @param y Y coordinate  
    * @param octaves Number of noise layers to combine
    * @param persistence How much each octave contributes (typically 0.5)
    * @param scale Overall scale of the noise pattern
    **/
    public static function fractalNoise2D(x:Float, y:Float, octaves:Int, persistence:Float, scale:Float):Float {
        var value = 0.0;
        var amplitude = 1.0;
        var frequency = scale;
        var maxValue = 0.0;
        
        for (i in 0...octaves) {
            value += noise2D(x * frequency, y * frequency) * amplitude;
            maxValue += amplitude;
            amplitude *= persistence;
            frequency *= 2.0;
        }
        
        return value / maxValue; // Normalize to approximately -1 to 1
    }
    
    /**
    * Generate a grid of Perlin noise values and map them to palette indices.
    * Returns an array of integers representing palette indices.
    **/
    public static function generateNoiseGrid(width:Int, height:Int, scale:Float, octaves:Int, persistence:Float, paletteSize:Int):Array<Int> {
        var result = new Array<Int>();
        var minValue = Math.POSITIVE_INFINITY;
        var maxValue = Math.NEGATIVE_INFINITY;
        var noiseValues = new Array<Float>();
        
        // Generate all noise values and find min/max
        for (y in 0...height) {
            for (x in 0...width) {
                var noiseValue = fractalNoise2D(x, y, octaves, persistence, scale);
                noiseValues.push(noiseValue);
                minValue = Math.min(minValue, noiseValue);
                maxValue = Math.max(maxValue, noiseValue);
            }
        }
        
        // Map to palette indices
        var range = maxValue - minValue;
        for (value in noiseValues) {
            var normalized = (value - minValue) / range; // 0.0 to 1.0
            var paletteIndex = Math.floor(normalized * (paletteSize - 1));
            paletteIndex = cast Math.max(0, Math.min(paletteSize - 1, paletteIndex));
            result.push(paletteIndex);
        }
        
        return result;
    }
    
    // Helper functions
    private static function fade(t:Float):Float {
        return t * t * t * (t * (t * 6 - 15) + 10); // 6t^5 - 15t^4 + 10t^3
    }
    
    private static function lerp(a:Float, b:Float, t:Float):Float {
        return a + t * (b - a);
    }
    
    private static function grad2D(hash:Int, x:Float, y:Float):Float {
        var h = hash & 3; // Use lower 2 bits
        var u = h < 2 ? x : y;
        var v = h < 2 ? y : x;
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
    }
    
    private static function shuffleArray(array:Array<Int>, seed:Int) {
        for (i in 0...array.length) {
            seed = (seed * 1103515245 + 12345) & 0x7fffffff;
            var j = seed % (i + 1);
            var temp = array[i];
            array[i] = array[j];
            array[j] = temp;
        }
    }
}