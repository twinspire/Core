package twinspire.render;

class Sprite {
    
    /**
    * This is an array of states representing what sprites could look like.
    * Use multiple states for input effects.
    **/
    public var states:Array<SpriteState>;

    public function new() {
        states = [];
    }

}