package twinspire.render;

import kha.Image;

class SpriteState {
    
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

}