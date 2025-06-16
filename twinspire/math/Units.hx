package twinspire.math;

import twinspire.utils.ExtraMath;

class Units {

    static var fromYards:Array<Float> = [ 1.0, 0.9144, 3.0, 0.000568181818, 0.0009144 ];
    static var fromMetres:Array<Float> = [ 1.0936133, 1.0, 3.2808399, 0.000621371192, 0.001 ];
    static var fromFeet:Array<Float> = [ 0.3334, 0.3048, 1.0, 0.000189393939, 0.0003048 ];
    static var fromMiles:Array<Float> = [ 1760, 1609.344, 5280, 1.0, 1.609344 ];
    static var fromKilometres:Array<Float> = [ 1093.6133, 1000, 3280.8399, 0.621371192, 1.0 ];
    
    /**
    * A pixel conversion to yards.
    **/
    public static var yards:Float;
    /**
    * A pixel conversion to metres.
    **/
    public static var metres:Float;
    /**
    * A pixel conversion to feet.
    **/
    public static var feet:Float;
    /**
    * A pixel conversion to miles.
    **/
    public static var miles:Float;
    /**
    * A pixel conversion to kilometres.
    **/
    public static var kilometres:Float;

    /**
    * The measurement basis for Yards.
    **/
    public static inline var MEASURE_YARD:Int = 0;
    /**
    * The measurement basis for Metres.
    **/
    public static inline var MEASURE_METRE:Int = 1;
    /**
    * The measurement basis for Feet.
    **/
    public static inline var MEASURE_FEET:Int = 2;
    /**
    * The measurement basis for Miles.
    **/
    public static inline var MEASURE_MILES:Int = 3;
    /**
    * The measurement basis for Kilometres.
    **/
    public static inline var MEASURE_KILOMETRES:Int = 4;

    /**
    * The current basis used for unit measurements.
    **/
    public static var currentBasis:Int;

    /**
    * Set the basis to measure pixel units by when referring to buffer space. This is typically used
    * in conjunction with `UNIT_POINTS`, the default for most measurements in buffer space (outside the primary buffer provided by Kha directly).
    *
    * Specify the basis and the rate in pixels for that basis. This function automatically calculates the pixel units for all other bases,
    * but will ensure the specified `basis` is used as the default measurement.
    *
    * @param value The pixel rate used for the given basis.
    * @param basis The basis used as the default unit measurement.
    **/
    public static function setMeasureBasis(value:Float, basis:Int) {
        switch (basis) {
            case MEASURE_YARD: {
                yards = value;
                metres = ExtraMath.froundPrecise(fromYards[MEASURE_METRE] * value, 3);
                feet = ExtraMath.froundPrecise(fromYards[MEASURE_FEET] * value, 3);
                miles = ExtraMath.froundPrecise(fromYards[MEASURE_MILES] * value, 3);
                kilometres = ExtraMath.froundPrecise(fromYards[MEASURE_KILOMETRES] * value, 3);
            }
            case MEASURE_FEET: {
                yards = ExtraMath.froundPrecise(fromFeet[MEASURE_YARD] * value, 3);
                metres = ExtraMath.froundPrecise(fromFeet[MEASURE_METRE] * value, 3);
                feet = value;
                miles = ExtraMath.froundPrecise(fromFeet[MEASURE_MILES] * value, 3);
                kilometres = ExtraMath.froundPrecise(fromFeet[MEASURE_KILOMETRES] * value, 3);
            }
            case MEASURE_METRE: {
                yards = ExtraMath.froundPrecise(fromMetres[MEASURE_YARD] * value, 3);
                metres = value;
                feet = ExtraMath.froundPrecise(fromMetres[MEASURE_FEET] * value, 3);
                miles = ExtraMath.froundPrecise(fromMetres[MEASURE_MILES] * value, 3);
                kilometres = ExtraMath.froundPrecise(fromMetres[MEASURE_KILOMETRES] * value, 3);
            }
            case MEASURE_KILOMETRES: {
                yards = ExtraMath.froundPrecise(fromKilometres[MEASURE_YARD] * value, 3);
                metres = ExtraMath.froundPrecise(fromKilometres[MEASURE_METRE] * value, 3);
                feet = ExtraMath.froundPrecise(fromKilometres[MEASURE_FEET] * value, 3);
                miles = ExtraMath.froundPrecise(fromKilometres[MEASURE_MILES] * value, 3);
                kilometres = value;
            }
            default: {
                return;
            }
        }

        currentBasis = basis;
    }

    /**
    * Convert screen-based pixels to the given converted unit.
    *
    * @param value The number of pixels.
    * @param convert The unit measurement to convert to.
    *
    * @return Returns the converted value. If the `convert` is not a valid basis, returns `-1`.
    **/
    public static function fromPixels(value:Float, convert:Int) {
        switch (convert) {
            case MEASURE_FEET: {
                return value / feet;
            }
            case MEASURE_KILOMETRES: {
                return value / kilometres;
            }
            case MEASURE_METRE: {
                return value / metres;
            }
            case MEASURE_MILES: {
                return value / miles;
            }
            case MEASURE_YARD: {
                return value / yards;
            }
            default: {
                return -1;
            }
        }
    }

    /**
    * Convert unit points to screen-based pixels using the given conversion.
    *
    * @param value The number of units.
    * @param convert The unit measurement to convert from.
    *
    * @return Returns the converted value. If the `convert` is not a valid basis, returns `-1`.
    **/
    public static function toPixels(value:Float, convert:Int) {
        switch (convert) {
            case MEASURE_FEET: {
                return value * feet;
            }
            case MEASURE_KILOMETRES: {
                return value * kilometres;
            }
            case MEASURE_METRE: {
                return value * metres;
            }
            case MEASURE_MILES: {
                return value * miles;
            }
            case MEASURE_YARD: {
                return value * yards;
            }
            default: {
                return -1;
            }
        }
    }

}