package twinspire.render;

import kha.math.FastVector2;
import twinspire.geom.Dim;
import kha.Image;

class SpriteState {
    
    private var _destinationDims:Array<Dim>;

    /**
    * The image for this sprite.
    **/
    public var image:Image;
    /**
    * Patches defining the regions of this sprite to render.
    **/
    public var patches:Array<Patch>;
    /**
    * Groups are a map of string keys to an array of indices of patches to render.
    * When groups are used, ensure to favour using `drawSpriteGroup` over the basic `drawSprite` option.
    * This is suitable for state machines.
    **/
    public var groups:Map<String, Array<Int>>;
    /**
    * Specifies the animation looping method, if any should exist.
    **/
    public var animationLoop:Map<String, SpriteAnimationLoop>;

    public function new() {
        patches = [];
        groups = [];
        animationLoop = [];
    }

    /**
    * Calculate the target dimensions of each patch in this `SpriteState` using the given parameters.
    * Favour using the underlying `updateSizes` function of the `Sprite` class, instead of using this function directly.
    *
    * @param targetSize The target size to aim for.
    * @param method The sprite sizing method to use.
    * @param baseline The baseline floating-point value to target when anchoring.
    * @param anchor The destination anchor point to align the patch towards.
    **/
    public function calculateSizing(targetSize:FastVector2, method:SpriteSizingMethod, baseline:Float, anchor:Anchor) {
        for (i in 0...patches.length) {
            var p = patches[i];
            switch (method) {
                case Stretch: {
                    _destinationDims.push(new Dim(0, 0, targetSize.x, targetSize.y));
                }
                case FillGapsClip: {
                    var destX = 0.0;
                    var destY = 0.0;
                    var destWidth = 0.0;
                    var destHeight = 0.0;

                    if (p.source.width > targetSize.x) {
                        destWidth = targetSize.x;
                        var clippedSpace = p.source.width - targetSize.x;
                        switch (anchor) {
                            case AnchorRight: {
                                destX = -(clippedSpace + baseline);
                            }
                            default: {

                            }
                        }
                    }
                    else {
                        var gap = p.source.width - targetSize.x;
                        destWidth = p.source.width;
                        switch (anchor) {
                            case AnchorRight: {
                                destX = gap - baseline;
                            }
                            default: {
                                destX = (targetSize.x - (gap / 2));
                            }
                        }
                    }

                    if (p.source.height > targetSize.y) {
                        destHeight = targetSize.y;
                        var clippedSpace = p.source.height - targetSize.y;
                        switch (anchor) {
                            case AnchorBottom: {
                                destY = -(clippedSpace + baseline);
                            }
                            default: {

                            }
                        }
                    }
                    else {
                        var gap = p.source.height - targetSize.y;
                        destHeight = p.source.height;
                        switch (anchor) {
                            case AnchorBottom: {
                                destY = gap - baseline;
                            }
                            default: {
                                destY = (targetSize.y - (gap / 2));
                            }
                        }
                    }

                    _destinationDims.push(new Dim(destX, destY, destWidth, destHeight));
                }
                case FillGapsProportional: {
                    var destX = 0.0;
                    var destY = 0.0;
                    var destWidth = 0.0;
                    var destHeight = 0.0;

                    var ratioW = 0.0;
                    if (p.source.width > targetSize.x) {
                        ratioW = targetSize.x / p.source.width;
                    }

                    var ratioH = 0.0;
                    if (p.source.height > targetSize.y) {
                        ratioH = targetSize.y / p.source.height;
                    }

                    var ratio = 0.0;
                    if (ratioW != 0.0 && ratioH != 0.0) {
                        ratio = Math.min(ratioW, ratioH);
                    }
                    else {
                        ratio = Math.max(ratioW, ratioH);
                    }

                    if (ratio > 0.0) {
                        // source size exceeds destination size, resize
                        destWidth = ratio * p.source.width;
                        destHeight = ratio * p.source.height;
                    }
                    else {
                        destWidth = p.source.width;
                        destHeight = p.source.height;
                    }
                    
                    switch (anchor) {
                        case AnchorBottom: {
                            
                        }
                    }
                }
            }
        }
    }

}