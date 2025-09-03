package twinspire.text;

import twinspire.text.roped.RopedString;

class RopedInputString extends InputString {
  
    public var data:RopedString;
    
    public function new() {
        super();
    }

    public function getStringData():Dynamic {
        return data.getStringData();
    }
    
    public function length():Int {
        return data.length();
    }
    
    public function addChar(s:Int, pos:Int):Void {
        data.addChar(s, pos);
    }
    
    public function addValue(value:String, pos:Int):Void {
        data.addValue(value, pos);
    }
    
    public function remove(pos:Int):Void {
        data.remove(pos);
    }
    
    public function removeRange(start:Int, end:Int):Void {
        data.removeRange(start, end);
    }
    
    public function search(data:Array<Int>):Array<{start:Int, end:Int}> {
        return this.data.search(data);
    }
  
}