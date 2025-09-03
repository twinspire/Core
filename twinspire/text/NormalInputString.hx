package twinspire.text;

import twinspire.StringBuffer;

class NormalInputString extends InputString {
    
    private var data:StringBuffer;

    public function new() {
        super();
    }

    public function getStringData():Dynamic {
        return data.toString();
    }

    public function length():Int {
        return data.length;    
    }

    public function addChar(s:Int, pos:Int):Void {
        data.addCharAt(s, pos);
    }

    public function addValue(value:String, pos:Int):Void {
        data.addStringAt(value, pos);
    }

    public function remove(pos:Int):Void {
        data.remove(pos, pos + 1);
    }

    public function removeRange(start:Int, end:Int):Void {
        data.remove(start, end);
    }

    public function search(query:Array<Int>):Array<{start:Int, end:Int}> {
        var value = data.toString();
        var toFind = "";
        for (q in query) {
            toFind += String.fromCharCode(q);
        }

        var results = new Array<{start:Int, end:Int}>();
        var foundIndex = value.indexOf(toFind);
        while (foundIndex > -1) {
            results.push({start: foundIndex, end: foundIndex + toFind.length});
            foundIndex = value.indexOf(toFind, foundIndex + 1);
        }

        return results;
    }

}