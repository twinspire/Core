package twinspire;

using kha.StringExtensions;
using StringTools;

/**
* Our own `StringBuffer` because Haxe's `StringBuf` has very limited functionality.
**/
class StringBuffer {

    private var current:Int;
    private var s:Array<Int>;
    private var maxLength:Int;

    public var length(get, never):Int;
    function get_length() return s.length;

    public inline function hasNext() {
        if (current >= s.length) {
            current = 0;
            return false;
        }
        return true;
    }

    public inline function next() {
        return s[current++];
    }

    public inline function get(index:Int) {
        if (index < 0 || index > s.length - 1) {
            return null;
        }
        return s[index];
    }

    public inline function setPosition(index:Int) {
        if (index >= 0 || index < s.length - 1) {
            current = index;
        }
    }

    public inline function getData() {
        return s;
    }

    public inline function new(?max:Int = 0) {
        s = [];
        current = 0;
        maxLength = max;
    }

    public function addChar(c:Int) {
        if (maxLength > 0 && s.length + 1 < maxLength || maxLength == 0) {
            s.push(c);
        }
    }

    public function addString(value:String) {
        var temp = value.toCharArray();

        if (maxLength > 0 && s.length + value.length < maxLength || maxLength == 0) {
            for (i in 0...temp.length) {
                s.push(temp[i]);
            }
        }
    }

    public function addInt(value:Int) {
        var str = "" + value;

        if (maxLength > 0 && s.length + 1 < maxLength || maxLength == 0) {
            for (v in str.toCharArray()) {
                s.push(v);
            }
        }
    }

    public function addFloat(value:Float) {
        var str = "" + value;

        if (maxLength > 0 && s.length + str.length < maxLength || maxLength == 0) {
            for (v in str.toCharArray()) {
                s.push(v);
            }
        }
    }

    public function addQuoted(value:String) {
        var str = '"' + value + '"';
        if (maxLength > 0 && s.length + value.length + 2 < maxLength || maxLength == 0) {
            for (v in str.toCharArray()) {
                s.push(v);
            }
        }
    }

    public function addCharAt(c:Int, at:Int) {
        if (maxLength > 0 && s.length + 1 < maxLength || maxLength == 0) {
            s.insert(at, c);
        }
    }

    public function addStringAt(value:String, at:Int) {
        var temp = value.toCharArray();

        if (maxLength > 0 && s.length + value.length < maxLength || maxLength == 0) {
            for (i in 0...temp.length) {
                s.insert(at + i, temp[i]);
            }
        }
    }

    public function addIntAt(value:Int, at:Int) {
        var temp = ("" + value).toCharArray();

        if (maxLength > 0 && s.length + temp.length < maxLength || maxLength == 0) {
            for (i in 0...temp.length) {
                s.insert(at + i, temp[i]);
            }
        }
    }

    public function addFloatAt(value:Float, at:Int) {
        var temp = ("" + value).toCharArray();

        if (maxLength > 0 && s.length + temp.length < maxLength || maxLength == 0) {
            for (i in 0...temp.length) {
                s.insert(at + i, temp[i]);
            }
        }
    }

    public function addQuotedAt(value:String, at:Int) {
        var temp = ('"' + value + '"').toCharArray();

        if (maxLength > 0 && s.length + value.length + 2 < maxLength || maxLength == 0) {
            for (i in 0...temp.length) {
                s.insert(at + i, temp[i]);
            }
        }
    }

    public function remove(low:Int, high:Int) {
        s.splice(low, high - low);
    }

    public function reset() {
        s = [];
    }

    public function clearFrom(index:Int) {
        s.splice(index, s.length - index);
    }

    public inline function toString() {
        var result = "";
        for (c in s) {
            result += String.fromCharCode(c);
        }
        return result;
    }

}