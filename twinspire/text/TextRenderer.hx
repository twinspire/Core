package twinspire.text;

import kha.Image;
import kha.Color;
import twinspire.render.UpdateContext;
import twinspire.render.GraphicsContext;
import kha.math.FastVector2;

abstract enum TextAlignment(Int) {
    var TextLeft;
    var TextCentre;
    var TextRight;
    var TextJustified;
}

abstract enum TextRenderColors(Int) to Int {
    var TextForegroundColor;
    var TextHighlightedColor;
    var HighlightColor;
    var CursorColor;
}

typedef TextBufferOptions = {
    /**
    * Determines if the buffer should be generated partially before rendering or not.
    **/
    var ?chunks:Bool;
    /**
    * Determines the number of lines pre-rendered from a given Y offset.
    * If this container is scrolled, new portions of the image is generated prior to rendering.
    **/
    var ?chunkLineSize:Float;
    /**
    * Determines the number of frames to delay reproducing the buffer when invisible portions
    * of the source text are brought into view. Use this only if you see a drop in performance.
    **/
    var ?frameDelay:Float;
}

typedef LineInfo = {
    /**
    * Starting character index for this line.
    **/
    var start:Int;
    /**
    * Ending character index for this line.
    **/
    var end:Int;
    /**
    * X coordinate where line starts.
    **/
    var lineStartX:Float;
    /**
    * Y coordinate where line starts.
    **/
    var lineStartY:Float;
    /**
    * X coordinate where line ends.
    **/
    var lineEndX:Float;
    /**
    * Y coordinate where line ends.
    **/
    var lineEndY:Float;
    /**
    * Height of this line.
    **/
    var height:Float;
}

typedef TextRendererOptions = {
    /**
    * Define if the text in this renderer should be editable.
    **/
    var ?editable:Bool;
    /**
    * Define if the text in this renderer should be selectable.
    **/
    var ?selectable:Bool;
    /**
    * Define if the text in this renderer should be drawn to a back buffer.
    **/
    var ?buffered:Bool;
    /**
    * Specify the options for the buffered image.
    **/
    var ?bufferOptions:TextBufferOptions;
    /**
    * Specify size constraints. If this is set at (0, 0), the renderer is allowed
    * to grow infinitely. If an `x` is present, this is used to limit the number of characters
    * drawn horizontally. Same is the case for `y`.
    **/
    var ?constraints:FastVector2;
    /**
    * Whether to enable word-wrapping.
    **/
    var ?wordWrap:Bool;
    /**
    * The alignment of the text.
    **/
    var ?alignment:TextAlignment;
    /**
    * The alignment of the last line of text rendered.
    **/
    var ?lastLineAlignment:TextAlignment;
    /**
    * Whether to use right-to-left writing.
    **/
    var ?rightToLeft:Bool;
    /**
    * Determines whether to animate the cursor's position.
    **/
    var ?animateCursor:Bool;
    /**
    * Determines whether to use opacity for the cursor blinking effect.
    **/
    var ?fadeCursor:Bool;
    /**
    * An array of colours for rendering text and effects. See `TextRenderColors` enum.
    **/
    var ?colors:Array<Color>;
}

typedef Word = {
    /**
    * The value of the word.
    **/
    var text:String;
    /**
    * The width of the word in given format index.
    **/
    var width:Float;
    /**
    * The index of the format used to render this text.
    **/
    var formatIndex:Int;
}

typedef WordPosition = {
    /**
    * The index of the cached word.
    **/
    var wordIndex:Int;
    /**
    * The space between this word and the next. Zero if this word is on
    * its own or is at the end of this line.
    **/
    var space:Float;
    /**
    * The line this word is on. Determines the `y` offset and baseline based on
    * the line's height.
    **/
    var lineIndex:Int;
    /**
    * The offset of this word from the beginning of the line. In right-to-left
    * writing mode, this becomes the right-side of the line rather than the left.
    **/
    var offset:Float;
}

class TextRenderer {

    private var _index:DimIndex;

    private var _buffers:Array<Image>;
    private var _visibleBufferChunk:Int;
    private var _bufferChunksToLoad:Array<Int>;

    private var _source:IInputString;
    private var _lines:Array<LineInfo>;
    private var _wordCache:Array<Word>;
    private var _words:Array<WordPosition>;
    private var _formats:Array<TextFormat>;
    private var _currentTextFormat:Int;
    private var _index:DimIndex;
    private var _options:TextRendererOptions;
    private var _isDirty:Bool = true;
    private var _selectionStart:Int = -1;
    private var _selectionEnd:Int = -1;

    /**
    * The source input string.
    **/
    public var source(get, never):IInputString;
    function get_source() {
        return _source;
    }
    /**
    * The index reference to which this renderer obtains its dimension bounds from.
    **/
    public var index(get, set):DimIndex;
    function get_index() {
        return _index;
    }
    function set_index(value:DimIndex):DimIndex {
        _index = value;
        _isDirty = true; // Dimension change requires relayout
        return value;
    }

    public function new(sourceData:IInputString, ?options:TextRendererOptions) {
        _source = sourceData;

        _options = options != null ? options : {};
        
        // Initialize arrays
        _lines = [];
        _wordCache = [];
        _words = [];
        _formats = [];
        
        // Set default options
        if (_options.editable == null) _options.editable = false;
        if (_options.selectable == null) _options.selectable = false;
        if (_options.wordWrap == null) _options.wordWrap = true;
        if (_options.alignment == null) _options.alignment = TextLeft;
        if (_options.rightToLeft == null) _options.rightToLeft = false;
        if (_options.animateCursor == null) _options.animateCursor = true;
        if (_options.fadeCursor == null) _options.fadeCursor = true;
    }

    /**
    * Add a new text format for rendering.
    **/
    public function addTextFormat(format:TextFormat) {
        return _formats.push(format) - 1;
    }

    /**
    * Get the currently used text format.
    **/
    public function getTextFormat() {
        if (_currentTextFormat < 0 || _currentTextFormat >= _formats.length) {
            return null;
        }

        return _formats[_currentTextFormat];
    }

    /**
    * Use a different text format.
    **/
    public function useFormatIndex(index:Int) {
        _currentTextFormat = index;
    }

    /**
    * Insert text at the end of the renderer.
    **/
    public function insert(value:String) {
        insertAt(value, _source.length());
    }

    /**
    * Insert at given position.
    **/
    public function insertAt(value:String, pos:Int) {
        //
        // TODO: When adding any non-alphanumeric character, check and update word cache, append to word
        // positions, and advance the cursor (if selectable); otherwise, append to current word
        // and calculate new position based on currently edited word.
        //

        if (_source != null) {
            _source.addValue(value, pos);
        }
    }

    /**
    * Highlight a selection of text.
    **/
    public function select(start:Int, end:Int) {
        if (!_options.selectable) return;
        
        _selectionStart = Math.min(start, end);
        _selectionEnd = Math.max(start, end);
        
        // Clamp to valid range
        var maxLen = _source.length();
        _selectionStart = Math.max(0, Math.min(_selectionStart, maxLen));
        _selectionEnd = Math.max(0, Math.min(_selectionEnd, maxLen));
    }

    /**
    * Delete either the current selection or at the given optional `pos`
    * and specified `length`.
    **/
    public function delete(pos:Int = -1, ?length:Int = 0) {
        // TODO
    }

    /**
    * Get the current render state (typically a back buffer).
    **/
    public function getRenderState() {
        // TODO
    }

    /**
    * Render using the given graphics context.
    **/
    public function render(gtx:GraphicsContext) {
        // TODO
    }

    /**
    * Update the renderer, updating cursor blinking based on frame rate,
    * repeated key strokes, key modifiers and cursor position.
    **/
    public function update(utx:UpdateContext) {
        // TODO
    }

}