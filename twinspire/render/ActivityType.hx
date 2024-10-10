package twinspire.render;

enum abstract ActivityType(Int) from Int to Int {
    var ACTIVITY_NONE               =   0;
    var ACTIVITY_MOUSE_OVER         =   1;
    var ACTIVITY_MOUSE_DOWN         =   2;
    var ACTIVITY_MOUSE_CLICKED      =   3;
    var ACTIVITY_MOUSE_SCROLL       =   4;

    var ACTIVITY_MAX                =   5;
}