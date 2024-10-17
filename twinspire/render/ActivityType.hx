package twinspire.render;

enum abstract ActivityType(Int) from Int to Int {
    var ACTIVITY_NONE               =   0;
    var ACTIVITY_MOUSE_OVER         =   1;
    var ACTIVITY_MOUSE_DOWN         =   2;
    var ACTIVITY_MOUSE_CLICKED      =   3;
    var ACTIVITY_MOUSE_SCROLL       =   4;
    var ACTIVITY_KEY_UP             =   5;
    var ACTIVITY_KEY_DOWN           =   6;
    var ACTIVITY_KEY_ENTER          =   7;

    var ACTIVITY_MAX                =   8;
}