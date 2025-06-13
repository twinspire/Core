package twinspire.text.edit;

class InputState {

    public var selection:Array<Int>;
    public var lineStart:Int;
    public var lineEnd:Int;
    public var builder:StringBuffer;
    public var upIndex:Int;
    public var downIndex:Int;
    public var undo:Array<UndoState>;
    public var redo:Array<UndoState>;
    public var id:Int;

    public var userData:Dynamic;

    public static var setClipboard:(Dynamic, String) -> Bool;
    public static var getClipboard:() -> String;

    public function new() {
        builder = new StringBuffer();
        selection = [ 0, 0 ];
    }

    public function update() {
        selection = [ builder.length, 0 ];
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
            redoPushState();
            var item = undo.pop();
            selection = item.selection.copy();
            builder.reset();
            builder.addString(item.text);
        }
    }

    public function undoClear() {
        undo = [];
    }

    public function undoCheck() {
        undoClear();
        undoPushState();
    }

     public function redoPushState() {
        var text = builder.toString();
        var item = new UndoState();
        item.selection = selection.copy();
        item.len = text.length;
        item.text = text;
        redo.push(item);
    }

    public function performRedo() {
        if (redo.length > 0) {
            undoPushState();
            var item = undo.pop();
            selection = item.selection.copy();
            builder.reset();
            builder.addString(item.text);
        }
    }

    public function redoClear() {
        redo = [];
    }

    public function redoCheck() {
        redoClear();
        redoPushState();
    }

    public function inputText(text:String) {
        if (text.length < 0) {
            return 0;
        }

        if (hasSelection()) {
            selectionDelete();
        }

        insertAt(selection[0], text);
        var offset = selection[0] + text.length;
        selection = [ offset, offset ];
        return offset;
    }

    public function insertAt(index:Int, text:String) {
        builder.addStringAt(text, index);
    }

    public function remove(low:Int, high:Int) {
        undoCheck();
        builder.remove(low, high);
    }

    public function hasSelection() {
        return selection[0] != selection[1];
    }

    public function sortedSelection() {
        var start = selection[0];
        var end = selection[1];
        if (start > end) {
            var temp = end;
            end = start;
            start = temp;
        }
        
        if (start > builder.length - 1) {
            start = builder.length - 1;
        }

        if (start < 0) {
            start = 0;
        }
        
        if (end > builder.length - 1) {
            end = builder.length - 1;
        }

        if (end < 0) {
            end = 0;
        }

        return { start: start, end: end };
    }

    public function selectionDelete() {
        var select = sortedSelection();
        builder.remove(selection[0], selection[1]);
        selection = [ select.start, select.start ];
    }

    public function isContinuation(c:Null<Int>) {
        if (c == null) {
            return false;
        }

        return c >= 0x80 && c < 0xc0;
    }

    public function translatePosition(t:Translation) {
        function isSpace(i:Int) {
            var v = builder.get(i);
            if (v == null) {
                return false;
            }
            var temp = String.fromCharCode(v);
            return StringTools.isSpace(temp, 0);
        }

        var pos = selection[0];
        if (pos < 0) {
            pos = 0;
        }
        if (pos > builder.length) {
            pos = builder.length;
        }

        switch (t) {
            case Start: {
                pos = 0;
            }
            case End: {
                pos = builder.length;
            }
            case Left: {
                pos -= 1;
                while (pos >= 0 && isContinuation(builder.get(pos))) {
                    pos -= 1;
                }
            }
            case Right: {
                pos += 1;
                while (pos < builder.length && isContinuation(builder.get(pos))) {
                    pos += 1;
                }
            }
            case Up: {
                pos = upIndex;
            }
            case Down: {
                pos = downIndex;
            }
            case Word_Left: {
                while (pos > 0 && isSpace(pos - 1)) {
                    pos -= 1;
                }

                while (pos > 0 && !isSpace(pos - 1)) {
                    pos -= 1;
                }
            }
            case Word_Right: {
                while (pos < builder.length && isSpace(pos)) {
                    pos += 1;
                }

                while (pos < builder.length && !isSpace(pos)) {
                    pos += 1;
                }
            }
            case Word_Start: {
                while (pos > 0 && !isSpace(pos - 1)) {
                    pos -= 1;
                }
            }
            case Word_End: {
                while (pos < builder.length && !isSpace(pos)) {
                    pos += 1;
                }
            }
            case Soft_Line_Start: {
                pos = lineStart;
            }
            case Soft_Line_End: {
                pos = lineEnd;
            }
        }

        if (pos < 0) {
            pos = 0;
        }
        if (pos > builder.length) {
            pos = builder.length;
        }

        return pos;
    }

    public function moveTo(t:Translation) {
        if (t == Left && hasSelection()) {
            var select = sortedSelection();
            selection = [ select.start, select.start ];
        }
        else if (t == Right && hasSelection()) {
            var select = sortedSelection();
            selection = [ select.end, select.end ];
        }
        else {
            var pos = translatePosition(t);
            selection = [ pos, pos ];
        }
    }

    public function selectTo(t:Translation) {
        selection[0] = translatePosition(t);
    }

    public function deleteTo(t:Translation) {
        if (hasSelection()) {
            selectionDelete();
        }
        else {
            var low = selection[0];
            var high = translatePosition(t);
            var newLow = cast Math.min(low, high);
            var newHigh = cast Math.max(low, high);
            remove(newLow, newHigh);
            selection = [ newLow, newLow ];
        }
    }

    public function currentSelectedText() {
        var select = sortedSelection();
        builder.setPosition(select.start);
        var result = [ for (s in builder) s ].toString() ?? "";
        builder.setPosition(0);
        return result;
    }

    public function copy() {
        if (setClipboard != null) {
            return setClipboard(userData, currentSelectedText());
        }

        return setClipboard != null;
    }

    public function cut() {
        if (copy()) {
            selectionDelete();
            return true;
        }
        return false;
    }

    public function paste() {
        if (getClipboard != null) {
            inputText(getClipboard());
            return true;
        }

        return getClipboard != null;
    }

    public function performCommand(cmd:Command) {
        switch (cmd) {
            case None:              // nothing
            case Undo:              performUndo();
            case Redo:              performRedo();
            case New_Line:          inputText("\n");
            case Cut:               cut();
            case Copy:              copy();
            case Paste:             paste();
            case Select_All:        selection = [ builder.length, 0 ];
            case Backspace:         deleteTo(Left);
            case Delete:            deleteTo(Right);
            case Delete_Word_Left:  deleteTo(Word_Left);
            case Delete_Word_Right: deleteTo(Word_Right);
            case Left:              moveTo(Left);
            case Right:             moveTo(Right);
            case Up:                moveTo(Up);
            case Down:              moveTo(Down);
            case Word_Left:         moveTo(Word_Left);
            case Word_Right:        moveTo(Word_Right);
            case Start:             moveTo(Start);
            case End:               moveTo(End);
            case Line_Start:        moveTo(Soft_Line_Start);
            case Line_End:          moveTo(Soft_Line_End);
            case Select_Left:       selectTo(Left);
            case Select_Right:      selectTo(Right);
            case Select_Up:         selectTo(Up);
            case Select_Down:       selectTo(Down);
            case Select_Word_Left:  selectTo(Word_Left);
            case Select_Word_Right: selectTo(Word_Right);
            case Select_Start:      selectTo(Start);
            case Select_End:        selectTo(End);
            case Select_Line_Start: selectTo(Soft_Line_Start);
            case Select_Line_End:   selectTo(Soft_Line_End);
        }
    }

}