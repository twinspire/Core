package twinspire.text;

interface IInputString {
    function getStringData():Dynamic;
    function length():Int;
    function addChar(s:Int, pos:Int):Void;
    function addValue(value:String, pos:Int):Void;
    function remove(pos:Int):Void;
    function removeRange(start:Int, end:Int):Void;
    function search(data:Array<Int>):Array<{start:Int, end:Int}>;
}