package twinspire;

enum Duration {
    /**
    * Specify a duration in seconds.
    **/
    Seconds(value:Float);
    /**
    * Specify a duration by factor of frames. Unlike `seconds`, frame-based duration is used for continuous timings. The `factor` is a speed translated from seconds.
    * E.g. `factor` of 60 / 60fps = 1 second
    **/
    Frames(factor:Float);
}