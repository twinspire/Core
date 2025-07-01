package twinspire;

abstract Id(Int) {

    private static var _lastId:Int = 0;

    public inline function new() {
        _lastId += 1;
        this = _lastId;
    }

    static var _none:Id;
    /**
    * Get an Id value that is considered not to reference anything.
    **/
    public static var None(get, never):Id;
    static function get_None() {
        if (_none == null) {
            _none = new Id();
        }
        return _none;
    }

}