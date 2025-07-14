package twinspire.geom;

class Box {
    
    public var top:Float;
    public var left:Float;
    public var right:Float;
    public var bottom:Float;

    public inline function new(all:Float) {
        top = all;
        left = all;
        right = all;
        bottom = all;
    }

}