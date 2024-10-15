package twinspire;

abstract Id(Int) {

    private static var _lastId:Int = 0;

    public inline function new() {
        _lastId += 1;
        this = _lastId;
    }

}