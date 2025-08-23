package twinspire.render;

import twinspire.geom.Dim;

enum abstract PatchIndex(Int) to Int {
    var TopLeft;
    var TopMiddle;
    var TopRight;
    var CentreLeft;
    var CentreMiddle;
    var CentreRight;
    var BottomLeft;
    var BottomMiddle;
    var BottomRight;
}

enum abstract PatchRepeatMethod(Int) to Int {
    /**
    * Specifies that the destination images are stretched. This is default behaviour.
    **/
    var PatchStretch;
    /**
    * Specifies that the destination images are repeated along their respective axis.
    **/
    var PatchRepeat;
}

enum abstract PatchMethodIndex(Int) to Int {
    var Top;
    var Left;
    var Centre;
    var Right;
    var Bottom;
}

class Patch {
    
    private var _segments:Array<Dim>;

    public var top:Float;
    public var left:Float;
    public var right:Float;
    public var bottom:Float;
    public var repeatMethods:Array<PatchRepeatMethod>;
    public var source:Dim;

    public inline function new(source:Dim, top:Float, left:Float, right:Float, bottom:Float, ?repeats:Array<PatchRepeatMethod> = null) {
        this.source = source;
        this.top = top;
        this.left = left;
        this.right = right;
        this.bottom = bottom;

        repeatMethods = [];
        
        if (repeats == null) {
            repeatMethods.push(PatchStretch); // Top
            repeatMethods.push(PatchStretch); // Left
            repeatMethods.push(PatchStretch); // Centre
            repeatMethods.push(PatchStretch); // Right
            repeatMethods.push(PatchStretch); // Bottom
        }
        else {
            repeatMethods = repeats;
        }

        _segments = [];
        createSegments();
    }

    private function createSegments() {
        if (top <= 0 || top > source.height || bottom <= 0 || bottom > source.height || left <= 0 || left > source.width || right <= 0 || right > source.width) {
            // @TODO: log
            return;
        }

        var tl = new Dim(source.x, source.y, left, top);
        var tr = new Dim(source.x + source.width - right, source.y, right, top);
        var tm = new Dim(tl.width, source.y, source.width - tl.width - tr.width, top);
        var bl = new Dim(source.x, source.y + source.height - bottom, left, bottom);
        var br = new Dim(source.x + source.width - right, source.y + source.height - bottom, right, bottom);
        var bm = new Dim(bl.width, source.y + source.height - bottom, source.width - bl.width - br.width, bottom);
        var cl = new Dim(source.x, source.y + tl.height, left, source.height - bl.height - tl.height);
        var cr = new Dim(source.x + source.width - right, source.y + tr.height, right, source.height - br.height - tr.height);
        var cm = new Dim(source.x + tl.width, source.y + tl.height, source.width - cl.width - cr.width, source.height - tm.height - bm.height);

        _segments = [ for (i in 0...9) new Dim(0, 0, 0, 0) ];
        _segments[TopLeft] = tl;
        _segments[TopMiddle] = tm;
        _segments[TopRight] = tr;
        _segments[CentreLeft] = cl;
        _segments[CentreMiddle] = cm;
        _segments[CentreRight] = cr;
        _segments[BottomLeft] = bl;
        _segments[BottomMiddle] = bm;
        _segments[BottomRight] = br;
    }

    public function getSegments() {
        return _segments;
    }

}