package twinspire;

import twinspire.render.TrackingObject;

abstract Id(Int) to Int {

    private static var _lastId:Int = 0;

    public function new() {
        this = _lastId;
        _lastId += 1;
    }

    static var _none:Id;
    /**
    * Get an Id value that is considered not to reference anything.
    **/
    public static var None(get, never):Id;
    static function get_None() {
        if (_none == null) {
            _none = Application.createId();
        }
        return _none;
    }

}