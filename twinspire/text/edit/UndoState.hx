package twinspire.text.edit;

class UndoState {
    
    public var selection:Array<Int>;
    public var len:Int;
    public var text:String;

    public function new() {
        selection = [ for(i in 0...2) -1 ];
    }

}