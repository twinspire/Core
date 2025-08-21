package twinspire;

import kha.math.Matrix3;

class AnimationState {
    
    public var current:AnimObject;
    public var from:AnimObject;
    public var to:AnimObject;

    /**
    * Animation index.
    **/
    public var index:Int;
    /**
    * The speed or duration of the animation.
    **/
    public var time:Duration;

    public function new() {
        
    }

}