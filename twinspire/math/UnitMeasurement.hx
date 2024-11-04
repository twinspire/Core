package twinspire.math;

enum abstract UnitMeasurement(Int) from Int to Int {
    /**
    * The default units of measurement is points, which is a measurement based on
    * the expected buffer width and height bound to the client, as a percentage
    * from 0..1 on both axes. If no back buffer is used, the default buffer provided
    * by kha is used instead.
    **/
    var UNIT_POINTS         =   0;
    /**
    * A measurement based in pixels, irrespective of buffer used. Pixel measurements are
    * instead based on screen space rather than buffer space.
    **/
    var UNIT_PIXELS         =   1;
    /**
    * Like `UNIT_PIXELS`, except using the buffer for the basis of measurements, rather
    * than the screen.
    **/
    var UNIT_PIXELS_BUFFER  =   2;
}