package twinspire.render;

enum abstract SpriteSizingMethod(Int) {
    /**
    * If the destination size does not match the source patch, stretch the image. This is the default.
    **/
    var Stretch;
    /**
    * If the destination size does not match the source patch, create gaps to fill the remaining space
    * and clip the image.
    **/
    var FillGapsClip;
    /**
    * If the destination size does not match the source patch, first attempt to shrink the source image
    * to the upper-most dimension and create gaps for space not yet filled.
    **/
    var FillGapsProportional;
}