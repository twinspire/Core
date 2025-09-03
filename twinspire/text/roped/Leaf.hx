package twinspire.text.roped;

class Leaf {
    private var data:Array<Int>;        // Character codes for editing
    private var cachedString:String;    // Cached string for rendering
    private var stringDirty:Bool;       // Whether cache needs refresh
    private var _length:Int;
    
    public static var MAX_LEAF_SIZE:Int = 64;
    
    public function new(?initialData:Array<Int>) {
        data = initialData != null ? initialData : [];
        _length = data.length;
        stringDirty = true;
        cachedString = null;
    }
    
    public inline function length():Int {
        return _length;
    }
    
    public inline function charAt(index:Int):Int {
        return data[index];
    }
    
    public function getData():Array<Int> {
        return data;
    }
    
    public function toString():String {
        if (stringDirty || cachedString == null) {
            cachedString = "";
            for (charCode in data) {
                cachedString += String.fromCharCode(charCode);
            }
            stringDirty = false;
        }
        return cachedString;
    }
    
    public function insert(pos:Int, chars:Array<Int>):Leaf {
        if (_length + chars.length <= MAX_LEAF_SIZE) {
            for (i in 0...chars.length) {
                data.insert(pos + i, chars[i]);
            }
            _length += chars.length;
            stringDirty = true;
            return this;
        }
        return null; // Signal need to split
    }
    
    public function delete(start:Int, deleteLength:Int) {
        for (i in 0...deleteLength) {
            data.splice(start, 1);
        }
        _length -= deleteLength;
        stringDirty = true;
    }
    
    public function split(pos:Int):{left:Leaf, right:Leaf} {
        var leftData = data.slice(0, pos);
        var rightData = data.slice(pos);
        return {
            left: new Leaf(leftData),
            right: new Leaf(rightData)
        };
    }
}