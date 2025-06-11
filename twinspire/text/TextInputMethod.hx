package twinspire.text;

import twinspire.text.TextBuffer;

enum TextInputMethod {
    ImSingleLine;
    ImMultiLine(breaks:Array<Int>);
    Buffered(buffer:TextBuffer);
}