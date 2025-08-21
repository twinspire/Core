package twinspire;

import kha.math.FastVector2;
import kha.Color;
import kha.math.FastMatrix3;

typedef AnimObject = {
    /**
    * For complex transformations.
    **/
    var ?transform:FastMatrix3;
    /**
    * Rotate an object.
    **/
    var ?rotation:Float;
    /**
    * Rotation pivot.
    **/
    var ?rotationPivot:FastVector2;
    /**
    * Opacity
    **/
    var ?opacity:Float;
    /**
    * Tint.
    **/
    var ?color:Color;
    /**
    * Sized from centre.
    **/
    var ?scale:Float;
}