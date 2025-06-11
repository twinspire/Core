package twinspire.text;

import twinspire.text.TextBuffer;

enum TextInputMethod {
    /**
    * Specifies that text rendering is done by immediately passing the content of the input handler
    * into the graphics context, rendered as a single line.
    *
    * Uses the font and font size of the `InputRenderer`.
    **/
    ImSingleLine;
    /**
    * Specifies that text rendering is done by immediately passing the content of the input handler
    * into the graphics context, rendered as multi-line.
    *
    * Uses the font and font size of the `InputRenderer`.
    **/
    ImMultiLine(breaks:Array<Int>);
    /**
    * Specifies that the text is drawn to a buffer passed by the user. The user is required to ensure
    * the relevant formatting is available for the buffer and does not use internal fonts used
    * by default in the `InputRenderer`.
    *
    * Buffer mode is more efficient for large volumes of text with or without multiple formats.
    **/
    Buffered(buffer:TextBuffer);
}