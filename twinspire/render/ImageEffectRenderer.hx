/**
* Most code here generated with Claude AI on 2025-08-14 and adapted for use.
**/

package twinspire.render;

import kha.math.Vector2i;
import haxe.io.Bytes;
import kha.Image;
import kha.Color;

enum SharpenMethod {
    /**
    * Uses an unsharp masking approach to sharpening image edges.
    **/
    Quality;
    /**
    * Uses a direct convolution kernel, which is more performant.
    **/
    Performance;
}

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
    public function sharpen(strength:Float, method:SharpenMethod) {
        if (strength <= 0.0) {
            return this;
        }

        switch (method) {
            case Performance: {
                // Clamp strength to reasonable values
                strength = Math.min(strength, 10.0);
                
                var bytesPerPixel = 4; // RGBA format
                var tempData = Bytes.alloc(_data.length);
                
                // Create sharpening kernel based on strength
                // Standard 3x3 sharpening kernel with adjustable center weight
                var kernelSize = 3;
                var radius = 1;
                var kernel = [
                    0.0, -strength, 0.0,
                    -strength, 1.0 + (4.0 * strength), -strength,
                    0.0, -strength, 0.0
                ];
                
                // Apply convolution
                for (y in 0...height) {
                    for (x in 0...width) {
                        var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
                        
                        for (ky in 0...kernelSize) {
                            for (kx in 0...kernelSize) {
                                var sampleX = x + kx - radius;
                                var sampleY = y + ky - radius;
                                
                                // Handle edge pixels by clamping
                                sampleX = clampInt(sampleX, 0, width - 1);
                                sampleY = clampInt(sampleY, 0, height - 1);
                                
                                var pixelIndex = (sampleY * width + sampleX) * bytesPerPixel;
                                var kernelIndex = ky * kernelSize + kx;
                                var weight = kernel[kernelIndex];
                                
                                r += _data.get(pixelIndex) * weight;
                                g += _data.get(pixelIndex + 1) * weight;
                                b += _data.get(pixelIndex + 2) * weight;
                                // Keep alpha unchanged for most sharpening operations
                                if (kx == radius && ky == radius) {
                                    a = _data.get(pixelIndex + 3); // Center pixel alpha
                                }
                            }
                        }
                        
                        var outputIndex = (y * width + x) * bytesPerPixel;
                        tempData.set(outputIndex, clampPixel(Math.round(r)));
                        tempData.set(outputIndex + 1, clampPixel(Math.round(g)));
                        tempData.set(outputIndex + 2, clampPixel(Math.round(b)));
                        tempData.set(outputIndex + 3, Math.round(a));
                    }
                }
                
                // Copy result back to main data
                for (i in 0..._data.length) {
                    _data.set(i, tempData.get(i));
                }
            }
            case Quality: {
                // Clamp strength to reasonable values (0.1 to 5.0 for unsharp mask)
                strength = Math.min(strength, 5.0);
                
                var bytesPerPixel = 4;
                
                // First, create a blurred version of the image
                var blurredData = Bytes.alloc(_data.length);
                
                // Copy original data to blurred buffer
                for (i in 0..._data.length) {
                    blurredData.set(i, _data.get(i));
                }
                
                // Apply a slight blur to create the "unsharp" mask
                applySimpleBlur(blurredData, 1.0);
                
                // Apply unsharp mask: Original + strength * (Original - Blurred)
                for (y in 0...height) {
                    for (x in 0...width) {
                        var pixelIndex = (y * width + x) * bytesPerPixel;
                        
                        for (channel in 0...3) { // RGB channels only
                            var original = _data.get(pixelIndex + channel);
                            var blurred = blurredData.get(pixelIndex + channel);
                            var difference = original - blurred;
                            var sharpened = original + (strength * difference);
                            
                            _data.set(pixelIndex + channel, clampPixel(sharpened));
                        }
                        // Alpha channel remains unchanged
                    }
                }
            }
        }

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

    /**
    * Clamp pixel values to valid 0-255 range.
    **/
    private static inline function clampPixel(value:Float):Int {
        if (value < 0) return 0;
        if (value > 255) return 255;
        return Std.int(value);
    }

    /**
    * Apply a simple box blur for unsharp mask.
    **/
    private function applySimpleBlur(data:Bytes, radius:Float) {
        var kernelSize = 3; // Simple 3x3 blur
        var kernelRadius = 1;
        var bytesPerPixel = 4;
        var tempData = Bytes.alloc(data.length);
        
        // Simple averaging kernel
        var weight = 1.0 / 9.0; // 3x3 kernel
        
        for (y in 0...height) {
            for (x in 0...width) {
                var r = 0.0, g = 0.0, b = 0.0;
                
                for (ky in 0...kernelSize) {
                    for (kx in 0...kernelSize) {
                        var sampleX = clampInt(x + kx - kernelRadius, 0, width - 1);
                        var sampleY = clampInt(y + ky - kernelRadius, 0, height - 1);
                        
                        var pixelIndex = (sampleY * width + sampleX) * bytesPerPixel;
                        
                        r += data.get(pixelIndex) * weight;
                        g += data.get(pixelIndex + 1) * weight;
                        b += data.get(pixelIndex + 2) * weight;
                    }
                }
                
                var outputIndex = (y * width + x) * bytesPerPixel;
                tempData.set(outputIndex, Math.round(r));
                tempData.set(outputIndex + 1, Math.round(g));
                tempData.set(outputIndex + 2, Math.round(b));
                tempData.set(outputIndex + 3, data.get(outputIndex + 3)); // Keep alpha
            }
        }
        
        // Copy back to original data
        for (i in 0...data.length) {
            data.set(i, tempData.get(i));
        }
    }

}