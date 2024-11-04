package twinspire.render;

import kha.math.FastVector2;

import twinspire.math.UnitMeasurement;

class Container {

    /**
    * The index of the container dim in `GraphicsContext`.
    **/
    public var dimIndex:Int;
    /**
    * The offset of the position of dimensions associated with this container.
    * This offset is measured as defined by the unit measurement in this container.
    **/
    public var offset:FastVector2;
    /**
    * The size of the content for this container. This is automatically worked out at the end of each frame.
    **/
    public var content:FastVector2;
    /**
    * The unit measurement type this container uses for measuring its children. If this container
    * is used for containing sprites, `UNIT_POINTS` is preferred, otherwise if used for containing
    * UI or Static dimensions, `UNIT_PIXELS` or `UNIT_PIXELS_BUFFER` is preferred.
    **/
    public var measurement:UnitMeasurement;
    /**
    * Either a pixel or point incremental value depending on the measurement type.
    * This is also used for automated events, such as mouse scroll for the container.
    **/
    public var increment:Float;

    public function new() {
        
    }

}