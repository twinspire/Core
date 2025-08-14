/**
* Most code here generated with Claude AI on 2025-08-14 and adapted for use.
**/

package twinspire.render;

import kha.math.Vector2i;
import haxe.io.Bytes;
import kha.Image;
import kha.Color;

enum ClampMode {
    /**
    * Extend the edge pixels outward (default behavior).
    **/
    ClampExtend;
    /**
    * Mirror the image at the edges.
    **/
    ClampMirror;
    /**
    * Wrap the image around (tiling effect).
    **/
    ClampWrap;
    /**
    * Fill edges with a solid color.
    **/
    ClampColor(color:kha.Color);
}

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

enum NoiseType {
    /**
    * Random scattered noise points.
    **/
    Scattered;
    /**
    * Uniform noise applied to all pixels.
    **/
    Uniform;
    /**
    * Film grain-like noise pattern.
    **/
    FilmGrain;
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
    * Clamp the edges within an image with different modes.
    **/
    public function clamp(?mode:ClampMode, ?borderSize:Int = 1, ?handleCorners:Bool = false) {
        if (mode == null) {
            mode = ClampExtend;
        }
        
        if (borderSize <= 0 || borderSize >= Math.min(width, height) / 2) {
            return this;
        }
        
        var bytesPerPixel = 4;
        
        switch (mode) {
            case ClampExtend: {
                return clampExtend(borderSize);
            }
            case ClampMirror: {
                if (handleCorners) {
                    return clampMirrorComplete(borderSize);
                }
                else {
                    return clampMirror(borderSize);
                }
            }
            case ClampWrap: {
                if (handleCorners) {
                    return clampWrapComplete(borderSize);
                }
                else {
                    return clampWrap(borderSize);
                }
            }
            case ClampColor(color): {
                return clampColor(color, borderSize);
            }
        }
        
        return this;
    }

    private function clampExtend(borderSize:Int) {
        var bytesPerPixel = 4;
        
        // Same as the previous implementation
        for (borderY in 0...borderSize) {
            for (x in borderSize...(width - borderSize)) {
                var topSourceIndex = (borderSize * width + x) * bytesPerPixel;
                var topTargetIndex = (borderY * width + x) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(topTargetIndex + channel, _data.get(topSourceIndex + channel));
                }
                
                var bottomSourceIndex = ((height - borderSize - 1) * width + x) * bytesPerPixel;
                var bottomTargetIndex = ((height - borderY - 1) * width + x) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(bottomTargetIndex + channel, _data.get(bottomSourceIndex + channel));
                }
            }
        }
        
        for (borderX in 0...borderSize) {
            for (y in 0...height) {
                var leftSourceIndex = (y * width + borderSize) * bytesPerPixel;
                var leftTargetIndex = (y * width + borderX) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(leftTargetIndex + channel, _data.get(leftSourceIndex + channel));
                }
                
                var rightSourceIndex = (y * width + (width - borderSize - 1)) * bytesPerPixel;
                var rightTargetIndex = (y * width + (width - borderX - 1)) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(rightTargetIndex + channel, _data.get(rightSourceIndex + channel));
                }
            }
        }
        
        return this;
    }

    private function clampColor(color:kha.Color, borderSize:Int) {
        var bytesPerPixel = 4;
        var r = Math.round(color.R * 255);
        var g = Math.round(color.G * 255);
        var b = Math.round(color.B * 255);
        var a = Math.round(color.A * 255);
        
        // Fill top and bottom borders
        for (borderY in 0...borderSize) {
            for (x in 0...width) {
                var topIndex = (borderY * width + x) * bytesPerPixel;
                var bottomIndex = ((height - borderY - 1) * width + x) * bytesPerPixel;
                
                _data.set(topIndex, r);
                _data.set(topIndex + 1, g);
                _data.set(topIndex + 2, b);
                _data.set(topIndex + 3, a);
                
                _data.set(bottomIndex, r);
                _data.set(bottomIndex + 1, g);
                _data.set(bottomIndex + 2, b);
                _data.set(bottomIndex + 3, a);
            }
        }
        
        // Fill left and right borders
        for (borderX in 0...borderSize) {
            for (y in borderSize...(height - borderSize)) {
                var leftIndex = (y * width + borderX) * bytesPerPixel;
                var rightIndex = (y * width + (width - borderX - 1)) * bytesPerPixel;
                
                _data.set(leftIndex, r);
                _data.set(leftIndex + 1, g);
                _data.set(leftIndex + 2, b);
                _data.set(leftIndex + 3, a);
                
                _data.set(rightIndex, r);
                _data.set(rightIndex + 1, g);
                _data.set(rightIndex + 2, b);
                _data.set(rightIndex + 3, a);
            }
        }
        
        return this;
    }

    private function clampMirror(borderSize:Int) {
        var bytesPerPixel = 4;
        
        // Mirror top and bottom borders
        for (borderY in 0...borderSize) {
            for (x in borderSize...(width - borderSize)) {
                // Top border - mirror from valid area
                var mirrorY = borderSize + (borderSize - borderY - 1);
                var topSourceIndex = (mirrorY * width + x) * bytesPerPixel;
                var topTargetIndex = (borderY * width + x) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(topTargetIndex + channel, _data.get(topSourceIndex + channel));
                }
                
                // Bottom border - mirror from valid area
                var bottomMirrorY = (height - borderSize - 1) - (borderSize - borderY - 1);
                var bottomSourceIndex = (bottomMirrorY * width + x) * bytesPerPixel;
                var bottomTargetIndex = ((height - borderY - 1) * width + x) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(bottomTargetIndex + channel, _data.get(bottomSourceIndex + channel));
                }
            }
        }
        
        // Mirror left and right borders
        for (borderX in 0...borderSize) {
            for (y in 0...height) {
                // Left border - mirror from valid area
                var mirrorX = borderSize + (borderSize - borderX - 1);
                var leftSourceIndex = (y * width + mirrorX) * bytesPerPixel;
                var leftTargetIndex = (y * width + borderX) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(leftTargetIndex + channel, _data.get(leftSourceIndex + channel));
                }
                
                // Right border - mirror from valid area
                var rightMirrorX = (width - borderSize - 1) - (borderSize - borderX - 1);
                var rightSourceIndex = (y * width + rightMirrorX) * bytesPerPixel;
                var rightTargetIndex = (y * width + (width - borderX - 1)) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(rightTargetIndex + channel, _data.get(rightSourceIndex + channel));
                }
            }
        }
        
        return this;
    }

    private function clampWrap(borderSize:Int) {
        var bytesPerPixel = 4;
        
        // Wrap top and bottom borders
        for (borderY in 0...borderSize) {
            for (x in borderSize...(width - borderSize)) {
                // Top border - wrap from bottom of valid area
                var wrapY = (height - borderSize - 1) - borderY;
                var topSourceIndex = (wrapY * width + x) * bytesPerPixel;
                var topTargetIndex = (borderY * width + x) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(topTargetIndex + channel, _data.get(topSourceIndex + channel));
                }
                
                // Bottom border - wrap from top of valid area
                var bottomWrapY = borderSize + borderY;
                var bottomSourceIndex = (bottomWrapY * width + x) * bytesPerPixel;
                var bottomTargetIndex = ((height - borderY - 1) * width + x) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(bottomTargetIndex + channel, _data.get(bottomSourceIndex + channel));
                }
            }
        }
        
        // Wrap left and right borders
        for (borderX in 0...borderSize) {
            for (y in 0...height) {
                // Left border - wrap from right of valid area
                var wrapX = (width - borderSize - 1) - borderX;
                var leftSourceIndex = (y * width + wrapX) * bytesPerPixel;
                var leftTargetIndex = (y * width + borderX) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(leftTargetIndex + channel, _data.get(leftSourceIndex + channel));
                }
                
                // Right border - wrap from left of valid area
                var rightWrapX = borderSize + borderX;
                var rightSourceIndex = (y * width + rightWrapX) * bytesPerPixel;
                var rightTargetIndex = (y * width + (width - borderX - 1)) * bytesPerPixel;
                
                for (channel in 0...bytesPerPixel) {
                    _data.set(rightTargetIndex + channel, _data.get(rightSourceIndex + channel));
                }
            }
        }
        
        return this;
    }

    private function clampMirrorComplete(borderSize:Int) {
        var bytesPerPixel = 4;
        
        // Handle corners first to avoid conflicts
        handleCornersMirror(borderSize);
        
        // Mirror top and bottom borders (excluding corners)
        for (borderY in 0...borderSize) {
            for (x in borderSize...(width - borderSize)) {
                // Top border
                var mirrorY = borderSize + (borderSize - borderY - 1);
                copyPixel(mirrorY, x, borderY, x);
                
                // Bottom border
                var bottomMirrorY = (height - borderSize - 1) - (borderSize - borderY - 1);
                copyPixel(bottomMirrorY, x, height - borderY - 1, x);
            }
        }
        
        // Mirror left and right borders (excluding corners)
        for (borderX in 0...borderSize) {
            for (y in borderSize...(height - borderSize)) {
                // Left border
                var mirrorX = borderSize + (borderSize - borderX - 1);
                copyPixel(y, mirrorX, y, borderX);
                
                // Right border
                var rightMirrorX = (width - borderSize - 1) - (borderSize - borderX - 1);
                copyPixel(y, rightMirrorX, y, width - borderX - 1);
            }
        }
        
        return this;
    }

    private function clampWrapComplete(borderSize:Int) {
        var bytesPerPixel = 4;
        
        // Handle corners first
        handleCornersWrap(borderSize);
        
        // Wrap top and bottom borders (excluding corners)
        for (borderY in 0...borderSize) {
            for (x in borderSize...(width - borderSize)) {
                // Top border - wrap from bottom
                var wrapY = (height - borderSize - 1) - borderY;
                copyPixel(wrapY, x, borderY, x);
                
                // Bottom border - wrap from top
                var bottomWrapY = borderSize + borderY;
                copyPixel(bottomWrapY, x, height - borderY - 1, x);
            }
        }
        
        // Wrap left and right borders (excluding corners)
        for (borderX in 0...borderSize) {
            for (y in borderSize...(height - borderSize)) {
                // Left border - wrap from right
                var wrapX = (width - borderSize - 1) - borderX;
                copyPixel(y, wrapX, y, borderX);
                
                // Right border - wrap from left
                var rightWrapX = borderSize + borderX;
                copyPixel(y, rightWrapX, y, width - borderX - 1);
            }
        }
        
        return this;
    }

    private function handleCornersMirror(borderSize:Int) {
        // Top-left corner
        for (borderY in 0...borderSize) {
            for (borderX in 0...borderSize) {
                var mirrorY = borderSize + (borderSize - borderY - 1);
                var mirrorX = borderSize + (borderSize - borderX - 1);
                copyPixel(mirrorY, mirrorX, borderY, borderX);
            }
        }
        
        // Top-right corner
        for (borderY in 0...borderSize) {
            for (borderX in 0...borderSize) {
                var mirrorY = borderSize + (borderSize - borderY - 1);
                var mirrorX = (width - borderSize - 1) - (borderSize - borderX - 1);
                copyPixel(mirrorY, mirrorX, borderY, width - borderX - 1);
            }
        }
        
        // Bottom-left corner
        for (borderY in 0...borderSize) {
            for (borderX in 0...borderSize) {
                var mirrorY = (height - borderSize - 1) - (borderSize - borderY - 1);
                var mirrorX = borderSize + (borderSize - borderX - 1);
                copyPixel(mirrorY, mirrorX, height - borderY - 1, borderX);
            }
        }
        
        // Bottom-right corner
        for (borderY in 0...borderSize) {
            for (borderX in 0...borderSize) {
                var mirrorY = (height - borderSize - 1) - (borderSize - borderY - 1);
                var mirrorX = (width - borderSize - 1) - (borderSize - borderX - 1);
                copyPixel(mirrorY, mirrorX, height - borderY - 1, width - borderX - 1);
            }
        }
    }

    private function handleCornersWrap(borderSize:Int) {
        // Top-left corner -> Bottom-right of valid area
        for (borderY in 0...borderSize) {
            for (borderX in 0...borderSize) {
                var wrapY = (height - borderSize - 1) - borderY;
                var wrapX = (width - borderSize - 1) - borderX;
                copyPixel(wrapY, wrapX, borderY, borderX);
            }
        }
        
        // Top-right corner -> Bottom-left of valid area
        for (borderY in 0...borderSize) {
            for (borderX in 0...borderSize) {
                var wrapY = (height - borderSize - 1) - borderY;
                var wrapX = borderSize + borderX;
                copyPixel(wrapY, wrapX, borderY, width - borderX - 1);
            }
        }
        
        // Bottom-left corner -> Top-right of valid area
        for (borderY in 0...borderSize) {
            for (borderX in 0...borderSize) {
                var wrapY = borderSize + borderY;
                var wrapX = (width - borderSize - 1) - borderX;
                copyPixel(wrapY, wrapX, height - borderY - 1, borderX);
            }
        }
        
        // Bottom-right corner -> Top-left of valid area
        for (borderY in 0...borderSize) {
            for (borderX in 0...borderSize) {
                var wrapY = borderSize + borderY;
                var wrapX = borderSize + borderX;
                copyPixel(wrapY, wrapX, height - borderY - 1, width - borderX - 1);
            }
        }
    }

    /**
    * Generate noise with the given parameters and noise type.
    **/
    public function noise(amount:Float, intensity:Float, variation:Float, ?type:NoiseType) {
        if (type == null) {
            type = Scattered;
        }
        
        if (amount <= 0 || intensity <= 0) {
            return this;
        }
        
        // Clamp parameters
        amount = Math.min(amount, 1.0);
        intensity = Math.min(intensity, 1.0);
        variation = Math.min(variation, 1.0);
        
        switch (type) {
            case Scattered: {
                return applyScatteredNoise(amount, intensity, variation);
            }
            case Uniform: {
                return applyUniformNoise(amount, intensity, variation);
            }
            case FilmGrain: {
                return applyFilmGrainNoise(amount, intensity, variation);
            }
        }
        
        return this;
    }

    private function applyScatteredNoise(amount:Float, intensity:Float, variation:Float) {        
        var bytesPerPixel = 4;
        var baseSeed = Math.round(Date.now().getTime() % 1000000);
        
        for (y in 0...height) {
            for (x in 0...width) {
                // Use multiple large primes to ensure good distribution
                var pixelSeed = baseSeed + (y * 2654435761) + (x * 1610612741);
                
                if (randomFloat(cast pixelSeed, 0.0, 1.0) < amount) {
                    var pixelIndex = (y * width + x) * bytesPerPixel;
                    
                    var currentR = _data.get(pixelIndex);
                    var currentG = _data.get(pixelIndex + 1);
                    var currentB = _data.get(pixelIndex + 2);
                    var currentA = _data.get(pixelIndex + 3);
                    
                    // Generate base noise
                    var baseNoise = randomFloat(cast pixelSeed * 3, -1.0, 1.0);
                    
                    var noiseR = baseNoise;
                    var noiseG = baseNoise;
                    var noiseB = baseNoise;
                    
                    // Add color variation if requested
                    if (variation > 0.1) {
                        var colorSeedR = pixelSeed * 7 + 1234;
                        var colorSeedG = pixelSeed * 11 + 5678;
                        var colorSeedB = pixelSeed * 13 + 9101;
                        
                        var varR = randomFloat(cast colorSeedR, -variation, variation);
                        var varG = randomFloat(cast colorSeedG, -variation, variation);
                        var varB = randomFloat(cast colorSeedB, -variation, variation);
                        
                        noiseR = Math.max(-1.0, Math.min(1.0, baseNoise + varR));
                        noiseG = Math.max(-1.0, Math.min(1.0, baseNoise + varG));
                        noiseB = Math.max(-1.0, Math.min(1.0, baseNoise + varB));
                    }
                    
                    // Apply noise
                    var noiseAmount = intensity * 128;
                    var newR = currentR + (noiseR * noiseAmount);
                    var newG = currentG + (noiseG * noiseAmount);
                    var newB = currentB + (noiseB * noiseAmount);
                    
                    _data.set(pixelIndex, clampPixel(newR));
                    _data.set(pixelIndex + 1, clampPixel(newG));
                    _data.set(pixelIndex + 2, clampPixel(newB));
                    _data.set(pixelIndex + 3, currentA);
                }
            }
        }
        
        return this;
    }

    private function applyUniformNoise(amount:Float, intensity:Float, variation:Float) {
        var bytesPerPixel = 4;
        var seed = Math.round(Date.now().getTime() % 1000000);
        
        for (y in 0...height) {
            for (x in 0...width) {
                // Use amount as probability for each pixel
                var pixelSeed = seed + (y * width + x);
                var shouldApply = randomFloat(pixelSeed, 0.0, 1.0) < amount;
                
                if (shouldApply) {
                    addNoiseToPixel(x, y, intensity, variation, pixelSeed);
                }
            }
        }
        
        return this;
    }

    private function applyFilmGrainNoise(amount:Float, intensity:Float, variation:Float) {
        var bytesPerPixel = 4;
        var seed = Math.round(Date.now().getTime() % 1000000);
        
        // Film grain tends to be more clustered and varies with image brightness
        for (y in 0...height) {
            for (x in 0...width) {
                var pixelIndex = (y * width + x) * bytesPerPixel;
                
                // Get pixel brightness to influence grain intensity
                var r = _data.get(pixelIndex);
                var g = _data.get(pixelIndex + 1);
                var b = _data.get(pixelIndex + 2);
                var brightness = (r + g + b) / (3 * 255); // 0.0 to 1.0
                
                // Film grain is more visible in mid-tones
                var grainMultiplier = 1.0 - Math.abs(brightness - 0.5) * 2.0;
                grainMultiplier = Math.max(grainMultiplier, 0.1); // Minimum visibility
                
                var pixelSeed = seed + (y * width + x);
                var shouldApply = randomFloat(pixelSeed, 0.0, 1.0) < (amount * grainMultiplier);
                
                if (shouldApply) {
                    var adjustedIntensity = intensity * grainMultiplier;
                    addNoiseToPixel(x, y, adjustedIntensity, variation, pixelSeed);
                }
            }
        }
        
        return this;
    }

    private function addNoiseToPixel(x:Int, y:Int, intensity:Float, variation:Float, seed:Int) {
        var bytesPerPixel = 4;
        var pixelIndex = (y * width + x) * bytesPerPixel;
        
        // Get current pixel values
        var currentR = _data.get(pixelIndex);
        var currentG = _data.get(pixelIndex + 1);
        var currentB = _data.get(pixelIndex + 2);
        var currentA = _data.get(pixelIndex + 3);
        
        // Generate noise values
        var noiseR = randomFloat(seed * 1234, -255 * intensity, 255 * intensity);
        var noiseG = randomFloat(seed * 5678, -255 * intensity, 255 * intensity);
        var noiseB = randomFloat(seed * 9101, -255 * intensity, 255 * intensity);
        
        // Apply color variation
        if (variation < 0.5) {
            var baseNoise = randomFloat(seed * 1121, -255 * intensity, 255 * intensity);
            var variationFactor = variation * 2.0;
            
            noiseR = baseNoise + (noiseR - baseNoise) * variationFactor;
            noiseG = baseNoise + (noiseG - baseNoise) * variationFactor;
            noiseB = baseNoise + (noiseB - baseNoise) * variationFactor;
        }
        
        // Apply noise to pixel
        var newR = currentR + noiseR;
        var newG = currentG + noiseG;
        var newB = currentB + noiseB;
        
        // Clamp values and set pixel
        _data.set(pixelIndex, clampPixel(newR));
        _data.set(pixelIndex + 1, clampPixel(newG));
        _data.set(pixelIndex + 2, clampPixel(newB));
        _data.set(pixelIndex + 3, currentA);
    }

    /**
    * Generate perlin noise from a set of parameters, with an optional colour palette. When a colour palette is used, the underlying image is replaced.
    * If a colour palette is not used, perlin will base colours on each pixel value, detecting a range of colours based on the scale and grid size.
    * Finally, if transparent edges are detected, perlin will spill over the edges based on the `falloff` range.
    *
    * Function inspired by the Perlin noise generator here (https://mcperlin.streamlit.app / https://github.com/davidandrocket/blank-app/blob/main/streamlit_app.py)
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

    /**
    * Helper function to copy a pixel from source coordinates to target coordinates.
    **/
    private inline function copyPixel(srcY:Int, srcX:Int, targetY:Int, targetX:Int) {
        var bytesPerPixel = 4;
        var sourceIndex = (srcY * width + srcX) * bytesPerPixel;
        var targetIndex = (targetY * width + targetX) * bytesPerPixel;
        
        for (channel in 0...bytesPerPixel) {
            _data.set(targetIndex + channel, _data.get(sourceIndex + channel));
        }
    }

    /**
    * Generate a pseudo-random integer between min and max (inclusive).
    **/
    private function randomInt(seed:Int, min:Int, max:Int):Int {
        // Linear congruential generator
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        return min + (seed % (max - min + 1));
    }

    /**
    * Generate a pseudo-random float between min and max.
    **/
    private function randomFloat(seed:Int, min:Float, max:Float):Float {
        var hash = seed;
        hash = (hash ^ 61) ^ (hash >> 16);
        hash = hash + (hash << 3);
        hash = hash ^ (hash >> 4);
        hash = hash * 0x27d4eb2d;
        hash = hash ^ (hash >> 15);
        
        // Convert to 0-1 range
        var normalized = (hash & 0x7fffffff) / 0x7fffffff;
        return min + (normalized * (max - min));
    }

}