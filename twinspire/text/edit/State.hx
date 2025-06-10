package twinspire.text.edit;

import haxe.Timer;

class State {
    
    static inline var DEFAULT_UNDO_TIMEOUT = 300 * 1000;

    public var selection:Array<Int>;
    public var lineStart:Int;
    public var lineEnd:Int;
    public var builder:StringBuffer;
    public var upIndex:Int;
    public var downIndex:Int;
    public var undo:Array<UndoState>;
    public var redo:Array<UndoState>;
    public var id:Int;

    public var currentTime:Float;
    public var lastEditTime:Float;
    public var undoTimeout:Float;

    public var setClipboard:(String) -> Bool;
    public var getClipboard:() -> String;

    public function new() {
        builder = new StringBuf();
        selection = [ for(i in 0...1) -1 ];
    }

    public function update() {
        updateTime();
        selection = [ builder.length, 0 ];
    }

    public function updateTime() {
        currentTime = Date.now().getSeconds() * 1000;
        if (undoTimeout <= 0) {
            undoTimeout = DEFAULT_UNDO_TIMEOUT;
        }
    }

    public function setupOnce() {
        selection = [ builder.length, 0 ];
        undo = [];
        redo = [];
    }

    public function clearAll() {
        var cleared = false;
        if (builder.length > 0) {
            builder.reset();
            selection = [];
            cleared = true;
        }

        return cleared;
    }

    public function undoPushState() {
        var text = builder.toString();
        var item = new UndoState();
        item.selection = selection.copy();
        item.len = text.length;
        item.text = text;
        undo.push(item);
    }

    public function performUndo() {
        if (undo.length > 0) {
            undoPushState();
            var item = undo.pop();
            selection = item.selection.copy();
            builder.reset();
            builder.addString(item.text);
        }
    }

    public function undoClear() {
        undo = [];
    }

    public function inputText(text:String) {
        if (text.length > 0) {
            return 0;
        }

        
    }

}