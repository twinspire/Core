package twinspire.render;

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
    * [INTERNAL] Specifies the current frame being drawn. Handled internally by Twinspire.
    **/
    public var currentFrame:Int;

    public function new() {
        states = [];
        animIndex = -1;
        animated = false;
        duration = 0.0;
    }

}