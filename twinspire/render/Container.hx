package twinspire.render;

import kha.Image;
import kha.math.FastVector2;

import twinspire.events.Buttons;
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
    * Tells that the offset should not be automatically adjusted internally by event simulations.
    **/
    public var manual:Bool;
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
    * Specifies the back buffer image used to target for rendering and perform event simulations.
    * Using this implies `measurement` to be `UNIT_PIXELS_BUFFER` unless `UNIT_POINTS` is used.
    **/
    public var bufferIndex:Int;
    /**
    * Sets the zoom factor of the buffer as a percentage of the original buffer size. Use
    * `Units.zoom` from `twinspire.math` to calculate a zoom factor for convenience.
    **/
    public var bufferZoomFactor:Float;
    /**
    * Set a value to determine if the buffer should receive user input events for dimensions inside it.
    * Sprites always receive events from user input (except mouse or touch events).
    * Default is `false`.
    **/
    public var bufferReceivesEvents:Bool;
    /**
    * Either a pixel or point incremental value depending on the measurement type.
    * This is also used for automated events, such as mouse scroll for the container.
    **/
    public var increment:Float;
    /**
    * Determines if this container should scroll infinitely. When this is `true`, `content` snapping is
    * disabled.
    **/
    public var infiniteScroll:Bool;
    /**
    * Set a soft limit on infinite scrolling, meaning that gaps between the maximum `width` or `height` of the `content`
    * value should not exceed this limit. This is a soft limit and is therefore not handled internally by
    * Twinspire. You should implement any content snapping yourself.
    **/
    public var softInfiniteLimit:Float;
    /**
    * Enables the ability to move the children of this container with right-click.
    **/
    public var enableScrollWithClick:Buttons;
    /**
    * Allow scrolling to be smoothly animated between start and finish when using the mouse wheel.
    **/
    public var smoothScrolling:Bool;
    /**
    * An array of indices linked to dimensions.
    **/
    public var childIndices:Array<DimIndex>;

    public function new() {
        enableScrollWithClick = BUTTON_NONE;
        softInfiniteLimit = 0.0;
        infiniteScroll = false;
        increment = 100;
        childIndices = [];
        offset = new FastVector2(0, 0);
        measurement = UNIT_POINTS;
        bufferIndex = -1;
        bufferZoomFactor = 1.0;
    }

}