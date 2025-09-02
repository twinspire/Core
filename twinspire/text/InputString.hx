package twinspire.text;

abstract class InputString implements IInputString {
    
    public abstract function getStringData():Dynamic;
    public abstract function length():Int;
    public abstract function addChar(s:Int, pos:Int):Void;
    public abstract function addValue(value:String, pos:Int):Void;
    public abstract function remove(pos:Int):Void;
    public abstract function removeRange(start:Int, end:Int):Void;
    public abstract function search(data:Array<Int>):Array<{start:Int, end:Int}>;

    public function new() {
        
    }

}