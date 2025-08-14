package twinspire.render;

import kha.math.Vector2i;
import haxe.io.Bytes;
import kha.Image;
import kha.Color;

class ImageEffectRenderer {

    private var width:Int;
    private var height:Int;
    private var _data:Bytes;
    
    public function new(img:Image) {
        var originalPixels = img.getPixels();
    
        if (originalPixels != null) {
            // Direct copy from original
            this.width = img.realWidth;
            this.height = img.realHeight;
            this._data = originalPixels;
        } else {
            // Software fallback - create empty buffer and manually copy pixel data
            var width = img.realWidth;
            var height = img.realHeight;
            var size = width * height * 4; // RGBA
            
            this._data = Bytes.alloc(size);
            
            // Try to extract pixels through alternative method
            if (!extractPixelsManually(img, width, height)) {
                trace("Warning: Could not extract pixel data, effects may not work properly");
                // Fill with transparent pixels as fallback
                for (i in 0...size) {
                    this._data.set(i, 0);
                }
            }

            this.width = width;
            this.height = height;
        }
    }

    private function extractPixelsManually(sourceImg:Image, width:Int, height:Int):Bool {
        try {
            // Create a temporary render target with a format that supports readback
            var tempTarget = Image.createRenderTarget(width, height, null, NoDepthAndStencil, 0);
            var g2 = tempTarget.g2;
            
            g2.begin(true, Color.Transparent);
            g2.drawImage(sourceImg, 0, 0);
            g2.end();
            
            // Try to get pixels after explicit end()
            var pixels = tempTarget.getPixels();
            if (pixels != null) {
                // Copy to our buffer
                for (i in 0...pixels.length) {
                    this._data.set(i, pixels.get(i));
                }
                return true;
            }
        } catch (e:Dynamic) {
            trace('Manual extraction failed: $e');
        }
        
        return false;
    }

    /**
    * Apply a gaussian blur by the given amount.
    **/
    public function blur(amount:Float) {
        if (amount <= 0) {
            return this;
        }

        // Calculate kernel size based on blur amount
        var kernelSize = Math.ceil(amount * 6) | 1; // Ensure odd number
        var radius = Math.floor(kernelSize / 2);
        
        // Generate gaussian kernel
        var kernel = generateGaussianKernel(kernelSize, amount);
        
        // Create temporary buffer for horizontal pass
        var tempData = Bytes.alloc(_data.length);
        
        var bytesPerPixel = 4; // Assuming RGBA format
        
        // Horizontal pass
        for (y in 0...height) {
            for (x in 0...width) {
                var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
                
                for (kx in 0...kernelSize) {
                    var sampleX = x + kx - radius;
                    sampleX = clampInt(sampleX, 0, width - 1);
                    
                    var pixelIndex = (y * width + sampleX) * bytesPerPixel;
                    var weight = kernel[kx];
                    
                    r += _data.get(pixelIndex) * weight;
                    g += _data.get(pixelIndex + 1) * weight;
                    b += _data.get(pixelIndex + 2) * weight;
                    a += _data.get(pixelIndex + 3) * weight;
                }
                
                var outputIndex = (y * width + x) * bytesPerPixel;
                tempData.set(outputIndex, Math.round(r));
                tempData.set(outputIndex + 1, Math.round(g));
                tempData.set(outputIndex + 2, Math.round(b));
                tempData.set(outputIndex + 3, Math.round(a));
            }
        }
        
        // Vertical pass (from temp buffer back to main data)
        for (y in 0...height) {
            for (x in 0...width) {
                var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
                
                for (ky in 0...kernelSize) {
                    var sampleY = y + ky - radius;
                    sampleY = clampInt(sampleY, 0, height - 1);
                    
                    var pixelIndex = (sampleY * width + x) * bytesPerPixel;
                    var weight = kernel[ky];
                    
                    r += tempData.get(pixelIndex) * weight;
                    g += tempData.get(pixelIndex + 1) * weight;
                    b += tempData.get(pixelIndex + 2) * weight;
                    a += tempData.get(pixelIndex + 3) * weight;
                }
                
                var outputIndex = (y * width + x) * bytesPerPixel;
                _data.set(outputIndex, Math.round(r));
                _data.set(outputIndex + 1, Math.round(g));
                _data.set(outputIndex + 2, Math.round(b));
                _data.set(outputIndex + 3, Math.round(a));
            }
        }

        return this;
    }

    /**
    * Sharpen the image by the given strength.
    **/
    public function sharpen(strength:Float) {

        return this;
    }

    /**
    * Clamp the transparent edges of the image.
    **/
    public function clamp() {

        return this;
    }

    /**
    * Generate basic noise with the given amount, intensity, and variation in colour.
    **/
    public function noise(amount:Float, intensity:Float, variation:Float) {

        return this;
    }

    /**
    * Generate perlin noise from a set of parameters.
    *
    * @param seed A numeric value to generate the perlin noise from.
    * @param scale Scale of the generated image.
    * @param grid Lower sizes generates larger spaces of the same color.
    * @param palette The colors to generate.
    * @param falloff Determines how much of the range of colours are used and how tightly close together the upper and lower bounds of the palette are to each other.
    * @param min Determines typical coverage of the lowest range on the color palette relative to the max
    * @param max Determines the coverage of the highest range on the color palette within spots not covered by the lowest range.
    **/
    public function perlin(seed:Int, scale:Float, grid:Vector2i, palette:Array<Color>, ?falloff:Float = 1.0, min:Float = 0.0, max:Float = 1.0) {

        return this;
    }

    /**
    * Mask this image by another image, where the given `effects` callback is used to
    * allow manipulation of the masking image over the current image.
    *
    * Any transparent areas of the masking image do not impact the underlying image.
    *
    * Once this function returns, the masking effects become final.
    **/
    public function mask(image:Image, effects:(ImageEffectRenderer) -> ImageEffectRenderer) {

        return this;
    }


    /**
    * Return the final image.
    **/
    public function getOutput() {
        return Image.fromBytes(this._data, width, height);
    }



    private function generateGaussianKernel(size:Int, sigma:Float):Array<Float> {
        var kernel = new Array<Float>();
        var sum = 0.0;
        var radius = Math.floor(size / 2);
        
        // Calculate gaussian values
        for (i in 0...size) {
            var x = i - radius;
            var value = Math.exp(-(x * x) / (2 * sigma * sigma));
            kernel.push(value);
            sum += value;
        }
        
        // Normalize kernel
        for (i in 0...kernel.length) {
            kernel[i] /= sum;
        }
        
        return kernel;
    }

    /**
    * Clamp an integer value between min and max bounds.
    **/
    private static inline function clampInt(value:Int, min:Int, max:Int):Int {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

}