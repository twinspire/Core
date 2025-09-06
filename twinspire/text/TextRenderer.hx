package twinspire.text;

import kha.Image;
import kha.Color;
import twinspire.geom.Dim;
import twinspire.render.UpdateContext;
import twinspire.render.GraphicsContext;
import kha.math.FastVector2;

enum abstract TextAlignment(Int) {
    var TextLeft;
    var TextCentre;
    var TextRight;
    var TextJustified;
}

enum abstract TextRenderColors(Int) to Int {
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

enum TextRenderMode {
    /**
    * Direct rendering for single lines and small text - no caching, immediate drawing.
    **/
    Simple;
    /**
    * Complex rendering with word cache, line layout, and optimization for large documents.
    **/
    Complex;
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
    private var _options:TextRendererOptions;
    private var _isDirty:Bool = true;
    private var _selectionStart:Int = -1;
    private var _selectionEnd:Int = -1;
    private var _isSelecting:Bool = false;
    private var _isFocused:Bool = false;
    private var _selectionStartPos:Int = -1;
    private var _selectionEndPos:Int = -1;
    private var _cursorBlinkTime:Float;
    private var _cursorBlinkInterval:Float = 0.5; // Blink every 0.5 seconds
    private var _cursorVisible:Bool = false;

    private var _scrollOffsetX:Float = 0.0;
    private var _scrollOffsetY:Float = 0.0;
    private var _maxScrollX:Float = 0.0;
    private var _maxScrollY:Float = 0.0;

    private var _wordDirtyFlags:Array<Bool>;  // Track which cached words need recalculation
    private var _lineDirtyFlags:Array<Bool>;  // Track which lines need relayout
    private var _cursorPosition:Int = 0;      // Current cursor position for editing

    // Rendering mode determination
    private var _renderMode:TextRenderMode;
    private var _characterThreshold:Int = 500;  // Switch to complex mode above this
    private var _lineThreshold:Int = 10;        // Or above this many lines

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
        _formats = [];
        
        // Set default options
        if (_options.editable == null) _options.editable = false;
        if (_options.selectable == null) _options.selectable = false;
        if (_options.wordWrap == null) _options.wordWrap = true;
        if (_options.alignment == null) _options.alignment = TextLeft;
        if (_options.rightToLeft == null) _options.rightToLeft = false;
        if (_options.animateCursor == null) _options.animateCursor = true;
        if (_options.fadeCursor == null) _options.fadeCursor = true;

        _determineRenderMode();
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
        if (_source == null || value.length == 0) return;
        
        _source.addValue(value, pos);
        
        // Check if we need to switch rendering modes
        _determineRenderMode();
        
        if (_renderMode == Simple) {
            _handleSimpleInsertion(pos, value);
        } else {
            _handleComplexInsertion(pos, value);
        }
        
        // Update cursor position
        if (_options.editable) {
            _cursorPosition = pos + value.length;
        }
        
        _adjustSelectionForInsertion(pos, value.length);
    }

    /**
    * Highlight a selection of text.
    **/
    public function select(start:Int, end:Int) {
        if (!_options.selectable) return;
        
        _selectionStart = cast Math.min(start, end);
        _selectionEnd = cast Math.max(start, end);
        
        // Clamp to valid range
        var maxLen = _source.length();
        _selectionStart = cast Math.max(0, Math.min(_selectionStart, maxLen));
        _selectionEnd = cast Math.max(0, Math.min(_selectionEnd, maxLen));
    }

    /**
    * Determine whether to use simple or complex rendering based on content size.
    **/
    private function _determineRenderMode() {
        if (_source == null) {
            _renderMode = Simple;
            return;
        }
        
        var textLength = _source.length();
        var text = Std.string(_source.getStringData());
        var lineCount = 1;
        
        if (text != null) {
            // Quick line count
            for (i in 0...text.length) {
                if (text.charCodeAt(i) == 10) { // newline
                    lineCount++;
                }
            }
        }
        
        // Switch to complex mode for larger content or when word wrapping is critical
        var needsComplex = textLength > _characterThreshold || 
                          lineCount > _lineThreshold ||
                          (_options.wordWrap && _options.constraints != null);
        
        var previousMode = _renderMode;
        _renderMode = needsComplex ? Complex : Simple;
        
        // If switching from simple to complex, initialize complex structures
        if (_renderMode == Complex && previousMode == Simple) {
            _initializeComplexMode();
        }
    }

    /**
    * Initialize complex rendering structures when switching from simple mode.
    **/
    private function _initializeComplexMode() {
        _lines = [];
        _wordCache = [];
        _words = [];
        _wordDirtyFlags = [];
        _lineDirtyFlags = [];
        _isDirty = true;
    }

    /**
    * Get the current render state (typically a back buffer).
    **/
    public function getRenderState() {
        // This would return a cached render buffer if buffered rendering is enabled
        if (_options.buffered) {
            // TODO: Implement buffer management
            return null;
        }
        return null;
    }

    /**
    * Render using the given graphics context.
    **/
    public function render(gtx:GraphicsContext) {
        if (_isDirty) {
            _updateLayout(gtx);
            _updateScrollLimits(); // Update scroll limits when layout changes
        }

        if (_renderMode == Simple) {
            _renderSimple(gtx);
        } else {
            _renderComplex(gtx);
        }
    }

    /**
    * Update the renderer, updating cursor blinking based on frame rate,
    * repeated key strokes, key modifiers and cursor position.
    **/
    public function update(utx:UpdateContext) {
        // Handle cursor blinking, input events, etc.
        if (_options.editable || _options.selectable) {
            _handleInputEvents(utx);
            _updateCursorAnimation(utx);
        }
    }

    /**
    * Simple insertion - just invalidate and let render handle it.
    **/
    private function _handleSimpleInsertion(pos:Int, value:String) {
        // For simple mode, no caching - just mark as dirty for next render
        _isDirty = true;
    }

    /**
    * Simple deletion - just invalidate and let render handle it.
    **/
    private function _handleSimpleDeletion(pos:Int, length:Int) {
        // For simple mode, no caching - just mark as dirty for next render
        _isDirty = true;
    }

    /**
    * Complex insertion with word cache management (from previous implementation).
    **/
    private function _handleComplexInsertion(pos:Int, value:String) {
        var affectedWordIndex = _findWordAtPosition(pos);
        var affectedLineIndex = _findLineAtPosition(pos);
        
        if (_isWordBoundaryChar(value)) {
            _handleWordBoundaryInsertion(pos, value, affectedWordIndex, affectedLineIndex);
        } else {
            _handleInWordInsertion(pos, value, affectedWordIndex, affectedLineIndex);
        }
    }

    /**
    * Complex deletion with selective updates (from previous implementation).
    **/
    private function _handleComplexDeletion(pos:Int, length:Int) {
        var startWordIndex = _findWordAtPosition(pos);
        var endWordIndex = _findWordAtPosition(pos + length - 1);
        var startLineIndex = _findLineAtPosition(pos);
        var endLineIndex = _findLineAtPosition(pos + length - 1);
        
        _handleDeletion(pos, length, startWordIndex, endWordIndex, startLineIndex, endLineIndex);
    }

    /**
    * Simple rendering for small documents - direct text drawing.
    **/
    private function _renderSimple(gtx:GraphicsContext) {
        if (_source == null || _index == null) return;
        
        var dims = gtx.getClientDimensionsAtIndex(_index);
        if (dims.length == 0) return;
        
        var dim = dims[0];
        if (dim == null) return;
        var format = getTextFormat();
        if (format == null) return;
        
        var text = Std.string(_source.getStringData());
        if (text == null || text.length == 0) return;
        
        // Set up clipping to text field bounds
        gtx.scissor(_index);
        
        // Apply scroll offset to rendering position
        var renderX = dim.x - _scrollOffsetX;
        var renderY = dim.y - _scrollOffsetY;

        if (_options.selectable || _options.editable) {
            // Render selection and cursor with scroll offset
            _renderSelectionWithOffset(gtx, text, renderX, renderY, dim, format);
        }

        gtx.setColor(_options.colors != null ? _options.colors[TextForegroundColor] : Color.Black);
        gtx.setFont(format.font);
        gtx.setFontSize(format.fontSize);
        
        if (!_options.wordWrap || text.indexOf('\n') == -1) {
            // Single line rendering with horizontal scroll
            _renderSingleLineWithOffset(gtx, text, renderX, renderY, dim, format);
        } else {
            // Multi-line rendering with vertical scroll
            _renderMultiLineWithOffset(gtx, text, renderX, renderY, dim, format);
        }
        
        // Render cursor (with scroll offset)
        if (_options.selectable || _options.editable) {
            _renderCursorWithOffset(gtx, text, renderX, renderY, dim, format);
        }
        
        // Disable clipping
        gtx.disableScissor();
    }

    private function _renderSelectionWithOffset(gtx:GraphicsContext, text:String, x:Float, y:Float, dim:Dim, format:TextFormat) {
        if (_selectionStart == -1 || _selectionEnd == -1 || _selectionStart == _selectionEnd) return;
        
        var selectionColor = _options.colors != null ? _options.colors[HighlightColor] : Color.fromBytes(0, 120, 215);
        gtx.setColor(selectionColor);
        
        // Calculate selection bounds with scroll offset
        var beforeSelection = text.substring(0, _selectionStart);
        var selectedText = text.substring(_selectionStart, _selectionEnd);
        
        var beforeWidth = format.font.width(format.fontSize, beforeSelection);
        var selectedWidth = format.font.width(format.fontSize, selectedText);
        var lineHeight = format.font.height(format.fontSize);
        
        // Apply scroll offset to selection rendering
        var selectionX = x + beforeWidth;
        var selectionY = y;
        
        gtx.getCurrentGraphics().fillRect(selectionX, selectionY, selectedWidth, lineHeight);
    }

    private function _renderCursorWithOffset(gtx:GraphicsContext, text:String, x:Float, y:Float, dim:Dim, format:TextFormat) {
        if (!_options.editable || !_isFocused || !_cursorVisible) return;
        
        var cursorColor = _options.colors != null ? _options.colors[CursorColor] : Color.Black;
        gtx.setColor(cursorColor);
        if (_options.fadeCursor) {
            var alpha = _cursorBlinkTime / _cursorBlinkInterval; // Fade in/out effect
            gtx.setOpacity(alpha);
        } else {
            gtx.setOpacity(1.0); // Always visible if not fading
        }
        
        var beforeCursor = text.substring(0, _cursorPosition);
        var cursorX = x + format.font.width(format.fontSize, beforeCursor);
        var lineHeight = format.font.height(format.fontSize);
        
        // Apply scroll offset to cursor position
        var finalCursorX = cursorX;
        var finalCursorY = y;

        // Only draw cursor if it's within visible bounds
        if (finalCursorX >= dim.x && finalCursorX <= dim.x + dim.width &&
            finalCursorY >= dim.y && finalCursorY <= dim.y + dim.height) {
            gtx.getCurrentGraphics().drawLine(finalCursorX, finalCursorY, finalCursorX, finalCursorY + lineHeight, 1.0);
        }

        gtx.setOpacity(1.0); // Reset opacity after drawing
    }

    /**
    * Render single line of text.
    **/
    private function _renderSingleLineWithOffset(gtx:GraphicsContext, text:String, x:Float, y:Float, dim:Dim, format:TextFormat) {
        // Apply text alignment (but consider scroll offset)
        var textX = x;
        if (_options.alignment != TextLeft && _scrollOffsetX == 0) {
            var textWidth = format.font.width(format.fontSize, text);
            switch (_options.alignment) {
                case TextCentre: textX += (dim.width - textWidth) * 0.5;
                case TextRight: textX += dim.width - textWidth;
                default:
            }
        }
        
        gtx.getCurrentGraphics().drawString(text, textX, y);
    }

    private function _renderMultiLineWithOffset(gtx:GraphicsContext, text:String, x:Float, y:Float, dim:Dim, format:TextFormat) {
        var lines = text.split('\n');
        var lineHeight = format.font.height(format.fontSize) * 1.2;
        var currentY = y;
        
        // Only render visible lines for performance
        var firstVisibleLine = Math.floor(_scrollOffsetY / lineHeight);
        var lastVisibleLine = Math.ceil((_scrollOffsetY + dim.height) / lineHeight);
        
        firstVisibleLine = cast Math.max(0, firstVisibleLine);
        lastVisibleLine = cast Math.min(lines.length - 1, lastVisibleLine);
        
        for (i in firstVisibleLine...lastVisibleLine + 1) {
            if (i >= lines.length) break;
            
            var line = lines[i];
            var lineY = currentY + (i * lineHeight);
            
            // Skip lines that are completely above or below visible area
            if (lineY + lineHeight < dim.y || lineY > dim.y + dim.height) {
                continue;
            }
            
            var lineX = x;
            
            // Apply alignment for each line (consider horizontal scroll)
            if (_options.alignment != TextLeft && line.length > 0 && _scrollOffsetX == 0) {
                var lineWidth = format.font.width(format.fontSize, line);
                switch (_options.alignment) {
                    case TextCentre: lineX += (dim.width - lineWidth) * 0.5;
                    case TextRight: lineX += dim.width - lineWidth;
                    default:
                }
            }
            
            gtx.getCurrentGraphics().drawString(line, lineX, lineY);
        }
    }

    private function _renderComplexWithScroll(gtx:GraphicsContext) {
        // TODO: Implement complex mode rendering with scroll offset support
        // This would use the _words and _lines arrays and apply scroll offsets
        // For now, fall back to simple mode
        _renderSimple(gtx);
    }

    /**
    * Render simple multi-line (only natural line breaks, no word wrapping).
    **/
    private function _renderSimpleMultiLine(gtx:GraphicsContext, text:String, dim:Dim, format:TextFormat) {
        var lines = text.split('\n');
        var lineHeight = format.font.height(format.fontSize) * 1.2; // Add some line spacing
        var y = dim.y;
        
        for (line in lines) {
            if (y + lineHeight > dim.y + dim.height) break; // Clip to bounds
            
            var x = dim.x;
            
            // Apply alignment for each line
            if (_options.alignment != TextLeft && line.length > 0) {
                var lineWidth = format.font.width(format.fontSize, line);
                switch (_options.alignment) {
                    case TextCentre: x += (dim.width - lineWidth) * 0.5;
                    case TextRight: x += dim.width - lineWidth;
                    default:
                }
            }
            
            gtx.getCurrentGraphics().drawString(line, x, y);
            y += lineHeight;
        }
    }

    /**
    * Simple selection rendering without word cache.
    **/
    private function _renderSimpleSelection(gtx:GraphicsContext, text:String, dim:Dim, format:TextFormat) {
        if (_selectionStart == -1 || _selectionEnd == -1 || _selectionStart == _selectionEnd) return;
        
        var selectionColor = _options.colors != null ? _options.colors[HighlightColor] : Color.fromBytes(0, 120, 215);
        gtx.setColor(selectionColor);
        
        // For simple mode, just calculate selection bounds directly
        var beforeSelection = text.substring(0, _selectionStart);
        var selectedText = text.substring(_selectionStart, _selectionEnd);
        
        var beforeWidth = format.font.width(format.fontSize, beforeSelection);
        var selectedWidth = format.font.width(format.fontSize, selectedText);
        var lineHeight = format.font.height(format.fontSize);
        
        gtx.getCurrentGraphics().fillRect(dim.x + beforeWidth, dim.y, selectedWidth, lineHeight);
    }

    /**
    * Simple cursor rendering.
    **/
    private function _renderSimpleCursor(gtx:GraphicsContext, text:String, dim:Dim, format:TextFormat) {
        if (!_options.editable) return;
        
        var cursorColor = _options.colors != null ? _options.colors[CursorColor] : Color.Black;
        gtx.setColor(cursorColor);
        
        var beforeCursor = text.substring(0, _cursorPosition);
        var cursorX = dim.x + format.font.width(format.fontSize, beforeCursor);
        var lineHeight = format.font.height(format.fontSize);
        
        // Simple cursor line
        gtx.getCurrentGraphics().drawLine(cursorX, dim.y, cursorX, dim.y + lineHeight, 1.0);
    }

    /**
    * Complex rendering with full word cache and layout system.
    **/
    private function _renderComplex(gtx:GraphicsContext) {
        if (_isDirty) {
            _updateComplexLayout(gtx);
        }
        
        if (_options.buffered && getRenderState() != null) {
            _renderFromBuffer(gtx);
        } else {
            _renderDirectComplex(gtx);
        }
    }

    /**
    * Get render mode for external inspection.
    **/
    public function getRenderMode():TextRenderMode {
        return _renderMode;
    }

    /**
    * Force a specific render mode (useful for testing or special cases).
    **/
    public function setRenderMode(mode:TextRenderMode) {
        if (_renderMode != mode) {
            _renderMode = mode;
            if (mode == Complex && _lines == null) {
                _initializeComplexMode();
            }
            _isDirty = true;
        }
    }

    /**
    * Set thresholds for automatic mode switching.
    **/
    public function setRenderThresholds(charThreshold:Int, lineThreshold:Int) {
        _characterThreshold = charThreshold;
        _lineThreshold = lineThreshold;
        _determineRenderMode();
    }

    private function _invalidateLayout() {
        _isDirty = true;
        _lines = [];
        _wordCache = [];
        _words = [];
    }

    private function _updateLayout(gtx:GraphicsContext) {
        if (_source == null) return;
        
        // Get dimension bounds for layout constraints
        var dims = gtx.getClientDimensionsAtIndex(_index);
        if (dims.length == 0) return;
        
        var dim = dims[0];
        if (dim == null) return;

        var maxWidth = _options.constraints != null ? _options.constraints.x : dim.width;
        var maxHeight = _options.constraints != null ? _options.constraints.y : dim.height;
        
        _buildWordCache();
        _layoutWords(maxWidth, maxHeight);
        _isDirty = false;
    }

    private function _buildWordCache() {
        _wordCache = [];
        
        var text = Std.string(_source.getStringData());
        if (text == null || text.length == 0) return;
        
        var words = text.split(" ");
        var currentPos = 0;
        
        for (i in 0...words.length) {
            var word = words[i];
            if (word.length > 0) {
                // TODO: Calculate actual width using font metrics
                var width = word.length * 8.0; // Placeholder calculation
                
                _wordCache.push({
                    text: word,
                    width: width,
                    formatIndex: 0 // TODO: Determine format index based on position
                });
            }
            currentPos += word.length + 1; // +1 for space
        }
    }

    private function _layoutWords(maxWidth:Float, maxHeight:Float) {
        _words = [];
        _lines = [];
        
        if (_wordCache.length == 0) return;
        
        var currentLine = 0;
        var currentX = 0.0;
        var lineHeight = 16.0; // TODO: Get from font metrics
        var currentY = 0.0;
        
        var lineStartIndex = 0;
        
        for (i in 0..._wordCache.length) {
            var word = _wordCache[i];
            var spaceWidth = 8.0; // TODO: Calculate space width
            
            // Check if word fits on current line
            var wordWithSpace = word.width + (i < _wordCache.length - 1 ? spaceWidth : 0);
            
            if (_options.wordWrap && currentX + wordWithSpace > maxWidth && currentX > 0) {
                // Finalize current line
                _finalizeLine(lineStartIndex, i - 1, currentLine, 0.0, currentY, currentX, currentY + lineHeight);
                
                // Start new line
                currentLine++;
                currentX = 0.0;
                currentY += lineHeight;
                lineStartIndex = i;
                
                // Check height constraint
                if (maxHeight > 0 && currentY + lineHeight > maxHeight) {
                    break;
                }
            }
            
            // Add word to current line
            _words.push({
                wordIndex: i,
                space: i < _wordCache.length - 1 ? spaceWidth : 0,
                lineIndex: currentLine,
                offset: currentX
            });
            
            currentX += word.width;
            if (i < _wordCache.length - 1) {
                currentX += spaceWidth;
            }
        }
        
        // Finalize last line
        if (_words.length > 0) {
            _finalizeLine(lineStartIndex, _wordCache.length - 1, currentLine, 0.0, currentY, currentX, currentY + lineHeight);
        }
    }

    private function _finalizeLine(startWordIndex:Int, endWordIndex:Int, lineIndex:Int, 
                                 startX:Float, startY:Float, endX:Float, endY:Float) {
        var startCharIndex = 0;
        var endCharIndex = 0;
        
        // TODO: Calculate character indices from word indices
        
        _lines.push({
            start: startCharIndex,
            end: endCharIndex,
            lineStartX: startX,
            lineStartY: startY,
            lineEndX: endX,
            lineEndY: endY,
            height: endY - startY
        });
    }

    private function _updateComplexLayout(gtx:GraphicsContext) {
        
    }
    
    private function _renderDirectComplex(gtx:GraphicsContext) {
        
    }

    private function _renderDirect(gtx:GraphicsContext) {
        // TODO: Implement direct rendering
        // This would iterate through _words and render each word
        // with proper positioning and formatting
    }

    private function _renderFromBuffer(gtx:GraphicsContext) {
        // TODO: Implement buffer-based rendering
    }

    private function _handleInputEvents(utx:UpdateContext) {
        // TODO: Handle keyboard input, mouse selection, etc.
    }

    private function _updateCursorAnimation(utx:UpdateContext) {
        _cursorBlinkTime += UpdateContext.deltaTime;
        if (_options.fadeCursor) {
            // Fade cursor in and out
            var alpha = _cursorBlinkTime / _cursorBlinkInterval; // Fade in/out effect
            _cursorVisible = alpha > _cursorBlinkInterval; // Visible when alpha is above threshold
        }

        if (_cursorBlinkTime >= _cursorBlinkInterval) { // Blink every 0.5 seconds
            _cursorVisible = !_cursorVisible;
            _cursorBlinkTime = 0.0;
        }
    }

    /**
    * Find the word index that contains the given character position.
    **/
    private function _findWordAtPosition(pos:Int):Int {
        if (_wordCache.length == 0) return -1;
        
        var charCount = 0;
        for (i in 0..._wordCache.length) {
            var wordLength = _wordCache[i].text.length;
            if (pos >= charCount && pos <= charCount + wordLength) {
                return i;
            }
            charCount += wordLength + 1; // +1 for space between words
        }
        return _wordCache.length - 1;
    }
    
    /**
    * Find the line index that contains the given character position.
    **/
    private function _findLineAtPosition(pos:Int):Int {
        for (i in 0..._lines.length) {
            if (pos >= _lines[i].start && pos <= _lines[i].end) {
                return i;
            }
        }
        return _lines.length > 0 ? _lines.length - 1 : -1;
    }

    /**
    * Forces the text renderer to lose focus, hiding the cursor and stopping any animations.
    **/
    public function loseFocus() {
        _isFocused = false;
        _cursorVisible = false; // Hide cursor when not focused
    }

    /**
    * Get the current cursor position in the text.
    **/
    public function getCursorPosition():Int {
        return _cursorPosition;
    }
    
    /**
    * Set the cursor position.
    **/
    public function setCursorPosition(pos:Int) {
        _isFocused = true;
        _cursorPosition = cast Math.max(0, Math.min(pos, _source.length()));
        _resetCursorBlink();
    }
    
    /**
    * Move cursor by a relative amount.
    **/
    public function moveCursor(delta:Int) {
        _isFocused = true;
        setCursorPosition(_cursorPosition + delta);
    }
    
    /**
    * Move cursor to the start of the current line.
    **/
    public function moveCursorToLineStart() {
        var lineStart = _getCurrentLineStart();
        setCursorPosition(lineStart);
    }
    
    /**
    * Move cursor to the end of the current line.
    **/
    public function moveCursorToLineEnd() {
        var lineEnd = _getCurrentLineEnd();
        setCursorPosition(lineEnd);
    }
    
    /**
    * Move cursor up one line (multi-line text only).
    **/
    public function moveCursorUp() {
        if (!isMultiLine()) return;
        
        var text = Std.string(_source.getStringData());
        if (text == null) return;
        
        var currentLineStart = _getCurrentLineStart();
        if (currentLineStart == 0) return; // Already on first line
        
        // Find start of previous line
        var prevLineEnd = currentLineStart - 2; // Skip the \n
        while (prevLineEnd >= 0 && text.charCodeAt(prevLineEnd) != 10) {
            prevLineEnd--;
        }
        var prevLineStart = prevLineEnd + 1;
        
        // Calculate column position in current line
        var currentColumn = _cursorPosition - currentLineStart;
        
        // Calculate length of previous line
        var prevLineLength = (currentLineStart - 1) - prevLineStart;
        
        // Set cursor to same column in previous line, or end if line is shorter
        var newPos = prevLineStart + Math.min(currentColumn, prevLineLength);
        setCursorPosition(cast newPos);
    }
    
    /**
    * Move cursor down one line (multi-line text only).
    **/
    public function moveCursorDown() {
        if (!isMultiLine()) return;
        
        var text = Std.string(_source.getStringData());
        if (text == null) return;
        
        var currentLineStart = _getCurrentLineStart();
        var currentLineEnd = _getCurrentLineEnd();
        
        // Find start of next line
        var nextLineStart = currentLineEnd + 1;
        if (nextLineStart >= text.length) return; // Already on last line
        
        // Find end of next line
        var nextLineEnd = nextLineStart;
        while (nextLineEnd < text.length && text.charCodeAt(nextLineEnd) != 10) {
            nextLineEnd++;
        }
        
        // Calculate column position in current line
        var currentColumn = _cursorPosition - currentLineStart;
        
        // Calculate length of next line
        var nextLineLength = nextLineEnd - nextLineStart;
        
        // Set cursor to same column in next line, or end if line is shorter
        var newPos = nextLineStart + Math.min(currentColumn, nextLineLength);
        setCursorPosition(cast newPos);
    }
    
    /**
    * Check if this text renderer supports multi-line text.
    **/
    public function isMultiLine():Bool {
        return _options.wordWrap == true;
    }
    
    /**
    * Check if currently selecting text.
    **/
    public function isSelecting():Bool {
        return _isSelecting;
    }
    
    /**
    * Start a text selection at the given position.
    **/
    public function startSelection(pos:Int) {
        _isSelecting = true;
        _isFocused = true;
        _selectionStartPos = cast Math.max(0, Math.min(pos, _source.length()));
        _selectionEndPos = _selectionStartPos;
        _selectionStart = _selectionStartPos;
        _selectionEnd = _selectionEndPos;
    }
    
    /**
    * Update the selection end position.
    **/
    public function updateSelection(pos:Int) {
        if (!_isSelecting) return;
        
        _selectionEndPos = cast Math.max(0, Math.min(pos, _source.length()));
        
        // Update the actual selection range (keeping start/end in correct order)
        _selectionStart = cast Math.min(_selectionStartPos, _selectionEndPos);
        _selectionEnd = cast Math.max(_selectionStartPos, _selectionEndPos);
    }
    
    /**
    * End the current selection.
    **/
    public function endSelection() {
        _isSelecting = false;
        // Keep the selection range for later operations (copy, delete, etc.)
    }
    
    /**
    * Clear the current selection.
    **/
    public function clearSelection() {
        _isSelecting = false;
        _selectionStart = -1;
        _selectionEnd = -1;
        _selectionStartPos = -1;
        _selectionEndPos = -1;
    }
    
    /**
    * Get character position from mouse coordinates.
    **/
    public function getCharacterPositionFromMouse(mouseX:Float, mouseY:Float):Int {
        if (_renderMode == Simple) {
            return _getCharacterPositionSimple(mouseX, mouseY);
        } else {
            return _getCharacterPositionComplex(mouseX, mouseY);
        }
    }
    
    /**
    * Copy selected text to clipboard.
    **/
    public function copySelection() {
        if (_selectionStart == -1 || _selectionEnd == -1 || _selectionStart == _selectionEnd) {
            return;
        }
        
        var text = Std.string(_source.getStringData());
        if (text == null) return;
        
        var selectedText = text.substring(_selectionStart, _selectionEnd);
        
        // Set clipboard data - this would need platform-specific implementation
        // For now, store in Application's cutData for compatibility
        Application.instance.cutData = selectedText;
    }
    
    /**
    * Cut selected text to clipboard.
    **/
    public function cutSelection() {
        if (!_options.editable) return;
        
        copySelection(); // Copy first
        
        // Then delete selection
        if (_selectionStart != -1 && _selectionEnd != -1 && _selectionStart != _selectionEnd) {
            delete(_selectionStart, _selectionEnd - _selectionStart);
            setCursorPosition(_selectionStart);
            clearSelection();
        }
    }
    
    /**
    * Paste text from clipboard.
    **/
    public function pasteFromClipboard() {
        if (!_options.editable) return;
        
        // Get clipboard data - for now use Application's cutData
        var clipboardText = Application.instance.cutData;
        if (clipboardText == null || clipboardText.length == 0) return;
        
        // If there's a selection, replace it
        if (_selectionStart != -1 && _selectionEnd != -1 && _selectionStart != _selectionEnd) {
            delete(_selectionStart, _selectionEnd - _selectionStart);
            insertAt(clipboardText, _selectionStart);
            setCursorPosition(_selectionStart + clipboardText.length);
            clearSelection();
        } else {
            // Otherwise insert at cursor position
            insertAt(clipboardText, _cursorPosition);
        }
    }
    
    /**
    * Undo last operation (placeholder - would need undo stack implementation).
    **/
    public function undo() {
        if (!_options.editable) return;
        
        // TODO: Implement undo stack
        // For now, this is a placeholder
    }
    
    /**
    * Redo last undone operation (placeholder - would need redo stack implementation).
    **/
    public function redo() {
        if (!_options.editable) return;
        
        // TODO: Implement redo stack  
        // For now, this is a placeholder
    }
    
    /**
    * Enhanced delete method that handles selections properly.
    **/
    public function delete(pos:Int = -1, ?length:Int = 0) {
        if (!_options.editable || _source == null) return;
        
        var deletePos = pos;
        var deleteLength = length;
        
        // Handle selection deletion
        if (_selectionStart >= 0 && _selectionEnd >= 0 && _selectionStart != _selectionEnd) {
            deletePos = _selectionStart;
            deleteLength = _selectionEnd - _selectionStart;
            clearSelection();
        } else if (pos == -1) {
            // Default to cursor position - backspace behavior
            deletePos = _cursorPosition > 0 ? _cursorPosition - 1 : 0;
            deleteLength = 1;
        }
        
        if (deletePos < 0 || deletePos >= _source.length()) return;
        
        deleteLength = cast Math.min(deleteLength, _source.length() - deletePos);
        if (deleteLength <= 0) return;
        
        // Update the source
        _source.removeRange(deletePos, deletePos + deleteLength);
        
        // Handle cache updates based on rendering mode
        if (_renderMode == Simple) {
            _isDirty = true; // Simple mode just marks as dirty
        } else {
            // Complex mode uses selective updates (existing logic)
            var startWordIndex = _findWordAtPosition(deletePos);
            var endWordIndex = _findWordAtPosition(deletePos + deleteLength - 1);
            var startLineIndex = _findLineAtPosition(deletePos);
            var endLineIndex = _findLineAtPosition(deletePos + deleteLength - 1);
            
            _handleDeletion(deletePos, deleteLength, startWordIndex, endWordIndex, startLineIndex, endLineIndex);
        }
        
        // Update cursor
        _cursorPosition = cast Math.min(deletePos, _source.length());
        
        // Adjust selection if it exists
        _adjustSelectionForDeletion(deletePos, deleteLength);
    }
    
    /**
    * Reset cursor blink animation.
    **/
    private function _resetCursorBlink() {
        _cursorBlinkTime = 0.0;
        _cursorVisible = true;
    }
    
    /**
    * Get character position from mouse coordinates (simple mode).
    **/
    private function _getCharacterPositionSimple(mouseX:Float, mouseY:Float):Int {
        var gtx = Application.instance.graphicsCtx;
        var dims = gtx.getDimensionsAtIndex(_index);
        if (dims.length == 0) return 0;
        
        var dim = dims[0];
        var format = getTextFormat();
        if (format == null) return 0;
        
        var text = Std.string(_source.getStringData());
        if (text == null) return 0;
        
        var relativeX = mouseX - dim.x;
        var relativeY = mouseY - dim.y;
        
        // Clamp to text bounds and handle out-of-bounds gracefully
        if (relativeY < 0) {
            // Above text area - return start position
            return 0;
        }
        
        // For single line, just find character based on X position
        if (!_options.wordWrap || text.indexOf('\n') == -1) {
            if (relativeX <= 0) return 0;
            
            var charPos = 0;
            var currentWidth = 0.0;
            
            while (charPos < text.length) {
                var charWidth = format.font.width(format.fontSize, text.substring(charPos, charPos + 1));
                if (currentWidth + charWidth * 0.5 > relativeX) {
                    break;
                }
                currentWidth += charWidth;
                charPos++;
            }
            
            return cast Math.min(charPos, text.length);
        }
        
        // For simple multi-line, find line first, then character
        var lines = text.split('\n');
        var lineHeight = format.font.height(format.fontSize) * 1.2;
        var targetLine = Math.floor(relativeY / lineHeight);
        
        // Clamp line to valid range
        if (targetLine >= lines.length) {
            // Below text area - return end position
            return text.length;
        }
        targetLine = cast Math.max(0, targetLine);
        
        var lineText = lines[targetLine];
        
        // Handle X position within the line
        if (relativeX <= 0) {
            // Left of line - return line start
            var lineStart = 0;
            for (i in 0...targetLine) {
                lineStart += lines[i].length + 1; // +1 for newline
            }
            return lineStart;
        }
        
        // Find character within line
        var charPos = 0;
        var currentWidth = 0.0;
        
        while (charPos < lineText.length) {
            var charWidth = format.font.width(format.fontSize, lineText.substring(charPos, charPos + 1));
            if (currentWidth + charWidth * 0.5 > relativeX) {
                break;
            }
            currentWidth += charWidth;
            charPos++;
        }
        
        // Convert line-relative position to absolute position
        var absolutePos = 0;
        for (i in 0...targetLine) {
            absolutePos += lines[i].length + 1; // +1 for newline
        }
        absolutePos += cast Math.min(charPos, lineText.length);
        
        return cast Math.min(absolutePos, text.length);
    }
    
    /**
    * Get character position from mouse coordinates (complex mode).
    * This would use the word cache and line information for precise positioning.
    **/
    private function _getCharacterPositionComplex(mouseX:Float, mouseY:Float):Int {
        // TODO: Implement complex mode character positioning using _words and _lines arrays
        // For now, fall back to simple mode
        return _getCharacterPositionSimple(mouseX, mouseY);
    }
    
    /**
    * Get the start position of the current line.
    **/
    private function _getCurrentLineStart():Int {
        var text = Std.string(_source.getStringData());
        if (text == null) return 0;
        
        var pos = _cursorPosition - 1;
        while (pos >= 0 && text.charCodeAt(pos) != 10) {
            pos--;
        }
        return pos + 1;
    }
    
    /**
    * Get the end position of the current line.
    **/
    private function _getCurrentLineEnd():Int {
        var text = Std.string(_source.getStringData());
        if (text == null) return 0;
        
        var pos = _cursorPosition;
        while (pos < text.length && text.charCodeAt(pos) != 10) {
            pos++;
        }
        return pos;
    }
    
    /**
    * Check if a character typically breaks words (spaces, punctuation).
    **/
    private function _isWordBoundaryChar(text:String):Bool {
        if (text.length == 0) return false;
        var char = text.charCodeAt(0);
        return char == 32 || // space
               char == 9 ||  // tab
               char == 10 || // newline
               char == 13 || // carriage return
               (char >= 33 && char <= 47) ||  // punctuation
               (char >= 58 && char <= 64) ||  // more punctuation
               (char >= 91 && char <= 96) ||  // brackets, etc.
               (char >= 123 && char <= 126);  // braces, etc.
    }
    
    /**
    * Handle insertion at word boundaries (spaces, punctuation).
    **/
    private function _handleWordBoundaryInsertion(pos:Int, value:String, affectedWordIndex:Int, affectedLineIndex:Int) {
        // For word boundary insertions, we might need to split existing words
        // or create new word entries
        
        if (affectedWordIndex >= 0 && affectedWordIndex < _wordCache.length) {
            var word = _wordCache[affectedWordIndex];
            var localPos = _getLocalPositionInWord(pos, affectedWordIndex);
            
            if (localPos == 0) {
                // Insertion at start of word - might create new word
                _insertNewWordBefore(value, affectedWordIndex);
            } else if (localPos >= word.text.length) {
                // Insertion at end of word - might create new word
                _insertNewWordAfter(value, affectedWordIndex);
            } else {
                // Insertion in middle of word - split the word
                _splitWordAtPosition(affectedWordIndex, localPos, value);
            }
        } else {
            // Insertion at very beginning or end of text
            _appendNewWord(value);
        }
        
        // Mark affected lines for relayout
        _markLinesForRelayout(affectedLineIndex);
    }
    
    /**
    * Handle insertion within a word (alphanumeric characters).
    **/
    private function _handleInWordInsertion(pos:Int, value:String, affectedWordIndex:Int, affectedLineIndex:Int) {
        if (affectedWordIndex >= 0 && affectedWordIndex < _wordCache.length) {
            var word = _wordCache[affectedWordIndex];
            var localPos = _getLocalPositionInWord(pos, affectedWordIndex);
            
            // Simply insert into existing word text
            var newText = word.text.substring(0, localPos) + value + word.text.substring(localPos);
            _wordCache[affectedWordIndex].text = newText;
            
            // Mark this word for width recalculation
            _markWordDirty(affectedWordIndex);
            
            // Mark affected line for relayout
            _markLinesForRelayout(affectedLineIndex);
        }
    }
    
    /**
    * Handle deletion efficiently by only updating affected words and lines.
    **/
    private function _handleDeletion(deletePos:Int, deleteLength:Int, startWordIndex:Int, endWordIndex:Int, 
                                   startLineIndex:Int, endLineIndex:Int) {
        
        // If deletion spans multiple words, we need to merge or remove words
        if (startWordIndex != endWordIndex && startWordIndex >= 0 && endWordIndex >= 0) {
            // Complex deletion spanning multiple words
            _handleMultiWordDeletion(deletePos, deleteLength, startWordIndex, endWordIndex);
        } else if (startWordIndex >= 0) {
            // Deletion within a single word
            _handleSingleWordDeletion(deletePos, deleteLength, startWordIndex);
        }
        
        // Shift positions of all words after the deletion
        _shiftWordsAfterDeletion(endWordIndex, deleteLength);
        
        // Mark affected lines for relayout
        for (i in startLineIndex...cast Math.min(endLineIndex + 2, _lines.length)) {
            _markLinesForRelayout(i);
        }
    }
    
    /**
    * Get the position within a specific word.
    **/
    private function _getLocalPositionInWord(globalPos:Int, wordIndex:Int):Int {
        var charCount = 0;
        for (i in 0...wordIndex) {
            charCount += _wordCache[i].text.length + 1; // +1 for space
        }
        return globalPos - charCount;
    }
    
    /**
    * Mark specific word as needing width recalculation.
    **/
    private function _markWordDirty(wordIndex:Int) {
        if (_wordDirtyFlags.length <= wordIndex) {
            // Extend array if needed
            while (_wordDirtyFlags.length <= wordIndex) {
                _wordDirtyFlags.push(false);
            }
        }
        _wordDirtyFlags[wordIndex] = true;
    }
    
    /**
    * Mark lines for relayout starting from the given line index.
    **/
    private function _markLinesForRelayout(fromLineIndex:Int) {
        if (fromLineIndex < 0) return;
        
        // Mark this line and all subsequent lines as dirty
        // because word wrapping can affect all following lines
        for (i in fromLineIndex..._lines.length) {
            if (i < _lineDirtyFlags.length) {
                _lineDirtyFlags[i] = true;
            } else {
                _lineDirtyFlags.push(true);
            }
        }
        
        _isDirty = true;
    }
    
    /**
    * Recalculate width for dirty words only.
    **/
    private function _updateDirtyWords() {
        var format = getTextFormat();
        if (format == null) return;
        
        for (i in 0..._wordCache.length) {
            if (i < _wordDirtyFlags.length && _wordDirtyFlags[i]) {
                var word = _wordCache[i];
                // Use font metrics to calculate actual width
                word.width = format.font.width(format.fontSize, word.text);
                _wordDirtyFlags[i] = false;
            }
        }
    }
    
    /**
    * Relayout only dirty lines.
    **/
    private function _relayoutDirtyLines() {
        if (_lines.length == 0) return;
        
        var format = getTextFormat();
        if (format == null) return;
        
        var lineHeight = format.font.height(format.fontSize);
        var spaceWidth = format.font.width(format.fontSize, " ");
        
        for (lineIndex in 0..._lines.length) {
            if (lineIndex >= _lineDirtyFlags.length || !_lineDirtyFlags[lineIndex]) {
                continue;
            }
            
            var line = _lines[lineIndex];
            
            // Recalculate line layout
            _recalculateLineLayout(lineIndex, line, lineHeight, spaceWidth);
            
            _lineDirtyFlags[lineIndex] = false;
        }
    }
    
    /**
    * Insert new word before the specified index.
    **/
    private function _insertNewWordBefore(text:String, beforeIndex:Int) {
        var format = getTextFormat();
        var width = format != null ? format.font.width(format.fontSize, text) : text.length * 8.0;
        
        var newWord:Word = {
            text: text,
            width: width,
            formatIndex: _currentTextFormat
        };
        
        _wordCache.insert(beforeIndex, newWord);
        _wordDirtyFlags.insert(beforeIndex, false);
    }
    
    /**
    * Insert new word after the specified index.
    **/
    private function _insertNewWordAfter(text:String, afterIndex:Int) {
        var format = getTextFormat();
        var width = format != null ? format.font.width(format.fontSize, text) : text.length * 8.0;
        
        var newWord:Word = {
            text: text,
            width: width,
            formatIndex: _currentTextFormat
        };
        
        _wordCache.insert(afterIndex + 1, newWord);
        _wordDirtyFlags.insert(afterIndex + 1, false);
    }
    
    /**
    * Append new word at the end.
    **/
    private function _appendNewWord(text:String) {
        var format = getTextFormat();
        var width = format != null ? format.font.width(format.fontSize, text) : text.length * 8.0;
        
        var newWord:Word = {
            text: text,
            width: width,
            formatIndex: _currentTextFormat
        };
        
        _wordCache.push(newWord);
        _wordDirtyFlags.push(false);
    }
    
    /**
    * Adjust selection indices after insertion.
    **/
    private function _adjustSelectionForInsertion(insertPos:Int, insertLength:Int) {
        if (_selectionStart >= insertPos) {
            _selectionStart += insertLength;
        }
        if (_selectionEnd >= insertPos) {
            _selectionEnd += insertLength;
        }
    }
    
    /**
    * Adjust selection indices after deletion.
    **/
    private function _adjustSelectionForDeletion(deletePos:Int, deleteLength:Int) {
        if (_selectionStart >= deletePos + deleteLength) {
            _selectionStart -= deleteLength;
        } else if (_selectionStart >= deletePos) {
            _selectionStart = deletePos;
        }
        
        if (_selectionEnd >= deletePos + deleteLength) {
            _selectionEnd -= deleteLength;
        } else if (_selectionEnd >= deletePos) {
            _selectionEnd = deletePos;
        }
        
        // Clear selection if it becomes invalid
        if (_selectionStart >= _selectionEnd) {
            _selectionStart = _selectionEnd = -1;
        }
    }
    
    /**
    * Handle deletion within a single word.
    **/
    private function _handleSingleWordDeletion(deletePos:Int, deleteLength:Int, wordIndex:Int) {
        var word = _wordCache[wordIndex];
        var localPos = _getLocalPositionInWord(deletePos, wordIndex);
        var localEndPos = cast (Math.min(localPos + deleteLength, word.text.length), Int);
        
        var newText = word.text.substring(0, localPos) + word.text.substring(localEndPos);
        
        if (newText.length == 0) {
            // Remove empty word
            _wordCache.splice(wordIndex, 1);
            if (wordIndex < _wordDirtyFlags.length) {
                _wordDirtyFlags.splice(wordIndex, 1);
            }
        } else {
            // Update word text and mark for width recalculation
            word.text = newText;
            _markWordDirty(wordIndex);
        }
    }
    
    /**
    * Handle deletion spanning multiple words.
    **/
    private function _handleMultiWordDeletion(deletePos:Int, deleteLength:Int, startWordIndex:Int, endWordIndex:Int) {
        // This is complex - we need to potentially merge partial words
        // and remove words in between
        
        var startWord = _wordCache[startWordIndex];
        var endWord = _wordCache[endWordIndex];
        
        var startLocalPos = _getLocalPositionInWord(deletePos, startWordIndex);
        var endLocalPos = _getLocalPositionInWord(deletePos + deleteLength, endWordIndex);
        
        // Create merged word from start and end portions
        var mergedText = startWord.text.substring(0, startLocalPos) + endWord.text.substring(endLocalPos);
        
        if (mergedText.length > 0) {
            // Update start word with merged text
            startWord.text = mergedText;
            _markWordDirty(startWordIndex);
            
            // Remove words in between and end word
            var removeCount = endWordIndex - startWordIndex;
            if (removeCount > 0) {
                _wordCache.splice(startWordIndex + 1, removeCount);
                _wordDirtyFlags.splice(startWordIndex + 1, cast Math.min(removeCount, _wordDirtyFlags.length - startWordIndex - 1));
            }
        } else {
            // Remove all affected words
            var removeCount = endWordIndex - startWordIndex + 1;
            _wordCache.splice(startWordIndex, removeCount);
            _wordDirtyFlags.splice(startWordIndex, cast Math.min(removeCount, _wordDirtyFlags.length - startWordIndex));
        }
    }
    
    /**
    * Shift word positions after deletion.
    **/
    private function _shiftWordsAfterDeletion(afterWordIndex:Int, deleteLength:Int) {
        // Word positions in _words array will be recalculated during relayout
        // This is more efficient than trying to manually adjust each position
    }
    
    /**
    * Split word at position and insert text.
    **/
    private function _splitWordAtPosition(wordIndex:Int, localPos:Int, insertText:String) {
        var word = _wordCache[wordIndex];
        var beforeText = word.text.substring(0, localPos);
        var afterText = word.text.substring(localPos);
        
        // Update original word with before text + inserted text
        word.text = beforeText + insertText;
        _markWordDirty(wordIndex);
        
        // Insert new word with after text
        if (afterText.length > 0) {
            _insertNewWordAfter(afterText, wordIndex);
        }
    }
    
    /**
    * Recalculate layout for a specific line.
    **/
    private function _recalculateLineLayout(lineIndex:Int, line:LineInfo, lineHeight:Float, spaceWidth:Float) {
        // This would recalculate word positions, wrapping, etc. for just this line
        // and potentially affect subsequent lines if wrapping changes
        
        
    }

    /**
    * Check if the text can be scrolled horizontally.
    **/
    public function canScrollHorizontally():Bool {
        if (_renderMode == Simple) {
            return _canScrollHorizontallySimple();
        } else {
            return _canScrollHorizontallyComplex();
        }
    }
    
    /**
    * Check if the text can be scrolled vertically.
    **/
    public function canScrollVertically():Bool {
        if (_renderMode == Simple) {
            return _canScrollVerticallySimple();
        } else {
            return _canScrollVerticallyComplex();
        }
    }
    
    /**
    * Scroll horizontally by the given amount.
    **/
    public function scrollHorizontally(delta:Int) {
        var scrollAmount = delta * 10.0; // Adjust sensitivity
        _scrollOffsetX += scrollAmount;
        
        // Clamp to valid range
        _scrollOffsetX = Math.max(0, Math.min(_scrollOffsetX, _maxScrollX));
        
        // Mark as needing re-render
        _isDirty = true;
    }
    
    /**
    * Scroll vertically by the given amount.
    **/
    public function scrollVertically(delta:Int) {
        var scrollAmount = delta * 10.0; // Adjust sensitivity
        _scrollOffsetY += scrollAmount;
        
        // Clamp to valid range
        _scrollOffsetY = Math.max(0, Math.min(_scrollOffsetY, _maxScrollY));
        
        // Mark as needing re-render
        _isDirty = true;
    }
    
    /**
    * Get current horizontal scroll offset.
    **/
    public function getScrollOffsetX():Float {
        return _scrollOffsetX;
    }
    
    /**
    * Get current vertical scroll offset.
    **/
    public function getScrollOffsetY():Float {
        return _scrollOffsetY;
    }
    
    /**
    * Update scroll limits based on content size (call during layout updates).
    **/
    private function _updateScrollLimits() {
        var gtx = Application.instance.graphicsCtx;
        var dims = gtx.getClientDimensionsAtIndex(_index);
        if (dims.length == 0) return;
        
        var dim = dims[0];
        if (dim == null) return;
        var contentSize = _getContentSize();
        
        // Calculate maximum scroll distances
        _maxScrollX = Math.max(0, contentSize.x - dim.width);
        _maxScrollY = Math.max(0, contentSize.y - dim.height);
        
        // Clamp current offsets to new limits
        _scrollOffsetX = Math.max(0, Math.min(_scrollOffsetX, _maxScrollX));
        _scrollOffsetY = Math.max(0, Math.min(_scrollOffsetY, _maxScrollY));
    }
    
    /**
    * Get the total content size (width and height).
    **/
    private function _getContentSize():FastVector2 {
        if (_renderMode == Simple) {
            return _getContentSizeSimple();
        } else {
            return _getContentSizeComplex();
        }
    }
    
    /**
    * Get content size in simple mode.
    **/
    private function _getContentSizeSimple():FastVector2 {
        var format = getTextFormat();
        if (format == null) return new FastVector2(0, 0);
        
        var text = Std.string(_source.getStringData());
        if (text == null || text.length == 0) return new FastVector2(0, 0);
        
        if (!_options.wordWrap || text.indexOf('\n') == -1) {
            // Single line - width is text width, height is line height
            var textWidth = format.font.width(format.fontSize, text);
            var textHeight = format.font.height(format.fontSize);
            return new FastVector2(textWidth, textHeight);
        } else {
            // Multi-line - calculate based on lines
            var lines = text.split('\n');
            var maxWidth = 0.0;
            var lineHeight = format.font.height(format.fontSize) * 1.2;
            var totalHeight = lines.length * lineHeight;
            
            for (line in lines) {
                var lineWidth = format.font.width(format.fontSize, line);
                if (lineWidth > maxWidth) {
                    maxWidth = lineWidth;
                }
            }
            
            return new FastVector2(maxWidth, totalHeight);
        }
    }
    
    /**
    * Get content size in complex mode.
    **/
    private function _getContentSizeComplex():FastVector2 {
        if (_lines.length == 0) {
            return new FastVector2(0, 0);
        }
        
        var maxWidth = 0.0;
        var totalHeight = 0.0;
        
        for (line in _lines) {
            var lineWidth = line.lineEndX - line.lineStartX;
            if (lineWidth > maxWidth) {
                maxWidth = lineWidth;
            }
            totalHeight = Math.max(totalHeight, line.lineEndY);
        }
        
        return new FastVector2(maxWidth, totalHeight);
    }
    
    /**
    * Check horizontal scrolling capability in simple mode.
    **/
    private function _canScrollHorizontallySimple():Bool {
        var contentSize = _getContentSizeSimple();
        var gtx = Application.instance.graphicsCtx;
        var dims = gtx.getDimensionsAtIndex(_index);
        if (dims.length == 0) return false;
        
        var dim = dims[0];
        return contentSize.x > dim.width;
    }
    
    /**
    * Check vertical scrolling capability in simple mode.
    **/
    private function _canScrollVerticallySimple():Bool {
        var contentSize = _getContentSizeSimple();
        var gtx = Application.instance.graphicsCtx;
        var dims = gtx.getDimensionsAtIndex(_index);
        if (dims.length == 0) return false;
        
        var dim = dims[0];
        return contentSize.y > dim.height;
    }
    
    /**
    * Check horizontal scrolling capability in complex mode.
    **/
    private function _canScrollHorizontallyComplex():Bool {
        var contentSize = _getContentSizeComplex();
        var gtx = Application.instance.graphicsCtx;
        var dims = gtx.getDimensionsAtIndex(_index);
        if (dims.length == 0) return false;
        
        var dim = dims[0];
        return contentSize.x > dim.width;
    }
    
    /**
    * Check vertical scrolling capability in complex mode.
    **/
    private function _canScrollVerticallyComplex():Bool {
        var contentSize = _getContentSizeComplex();
        var gtx = Application.instance.graphicsCtx;
        var dims = gtx.getDimensionsAtIndex(_index);
        if (dims.length == 0) return false;
        
        var dim = dims[0];
        return contentSize.y > dim.height;
    }

}