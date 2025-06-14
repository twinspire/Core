package twinspire.render;

import kha.math.FastVector2;

class Sprite {

    /**
    * This is an array of states representing what sprites could look like.
    * Use multiple states for input effects.
    **/
    public var states:Array<SpriteState>;
    /**
    * Determines whether this sprite should be animated.
    **/
    public var animated:Bool;
    /**
    * Specifies the index used by Twinspire to determine the specific index used to animate this sprite.
    **/
    public var animIndex:Int;
    /**
    * The animation speed in seconds between each sprite frame.
    **/
    public var duration:Float;
    /**
    * The animation loop method used for all states, unless overridden in an underlying state.
    **/
    public var animationLoop:SpriteAnimationLoop;
    /**
    * Specify the target size drawn for this sprite, overriding target dimension. 
    **/
    public var size:FastVector2;
    /**
    * Specify the sizing method for this sprite if size is set.
    **/
    public var sizingMethod:SpriteSizingMethod;
    /**
    * If any of the `Fill*` sizing methods is used, use this value as the baseline from an anchor point.
    **/
    public var fillBaseline:Float;
    /**
    * Specifies the anchor point of the sprite's source to the destination size, if size is used.
    * If `FillGapsClip` is used and the anchor point occupies the axis that's clipped, `fillAnchor`
    * will be used to force clipping to the opposing end of the target anchor.
    **/
    public var fillAnchor:Anchor;
    /**
    * [INTERNAL] Specifies the current frame being drawn. Handled internally by Twinspire.
    **/
    public var currentFrame:Int;

    public function new() {
        states = [];
        animIndex = -1;
        animated = false;
        duration = 0.0;
        sizingMethod = Stretch;
    }

}