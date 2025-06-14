package twinspire.render;

enum abstract SpriteAnimationLoop(Int) {
    /**
    * No animation repeat.
    **/
    var None;
    /**
    * Animation repeats from start.
    **/
    var Repeat;
    /**
    * Animation repeats ping-pong.
    **/
    var RepeatInverse;
}