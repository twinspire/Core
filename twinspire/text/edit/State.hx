package twinspire.text.edit;

import haxe.Timer;

class State {
    
    static inline var DEFAULT_UNDO_TIMEOUT = 300 * 1000;

    public var selection:Array<Int>;
    public var lineStart:Int;
    public var lineEnd:Int;
    public var builder:StringBuf;
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
            builder = null;
            builder = new StringBuf(); // overwrite existing buffer
            selection = [];
            cleared = true;
        }

        return cleared;
    }

    public function undoPushState() {
        var text = builder.toString();
        
    }

}