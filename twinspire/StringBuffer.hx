package twinspire;

/**
* Our own `StringBuffer` because Haxe's `StringBuf` has very limited functionality.
**/
class StringBuffer {

    private var s:String;
    private var maxLength:Int;

    public inline function length(get, never):Int;
    inline function get_length() return s.length;

    public inline function new(?max:Int = 0) {
        s = "";
        if (max > 0) {
            maxLength = max;
        }
    }

    public function addChar(c:Int) {
        if (maxLength > 0 && s.length + 1 < maxLength || maxLength == 0) {
            s += String.fromCharCode(c);
        }
    }

    public function addString(value:String) {
        if (maxLength > 0 && s.length + value.length < maxLength || maxLength == 0) {
            s += value;
        }
    }

    public function addInt(value:Int) {
        if (maxLength > 0 && s.length + 1 < maxLength || maxLength == 0) {
            s += value;
        }
    }

    public function addFloat(value:Float) {
        if (maxLength > 0 && s.length + 1 < maxLength || maxLength == 0) {
            s += value;
        }
    }

    public function addQuoted(value:String) {
        if (maxLength > 0 && s.length + value.length + 2 < maxLength || maxLength == 0) {
            s += '"' + value + '"';
        }
    }

    public function reset() {
        s = "";
    }

    public function clearFrom(index:Int) {
        s = s.substr(clearFrom);
    }

    public inline function toString() {
        return s;
    }

}