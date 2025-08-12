package twinspire.render;

import kha.math.FastVector2;

class Camera {

    /**
    * Specifies the target index that the camera is looking at.
    * If none is supplied, the camera defaults to look at the top-left
    * most corner of the dimension stack.
    **/
    public var target:DimIndex;
    /**
    * A value determining by how much the target is anchored from the centre
    * of the camera.
    **/
    public var anchor:FastVector2;
    /**
    * The observable space within client bounds. This ultimately determines
    * the final position of dimensions within the stack after container positions
    * are calculated in `end`.
    **/
    public var size:FastVector2;
    /**
    * The position of the camera offset from the top-most corner of the dimension
    * stack.
    **/
    public var position:FastVector2;

    
    public function new() {

    }

}