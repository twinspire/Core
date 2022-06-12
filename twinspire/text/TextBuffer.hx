package twinspire.text;

import twinspire.text.TextFormat;
import twinspire.text.LineInfo;
import twinspire.Dimensions.*;
using twinspire.extensions.Graphics2;

import kha.graphics4.DepthStencilFormat;
import kha.graphics4.TextureFormat;
import kha.graphics2.Graphics;
import kha.math.Vector2;
import kha.Image;
import kha.Font;
import kha.Color;
using kha.StringExtensions;

using StringTools;

enum abstract MarkdownFormat(Int) from Int to Int
{
	var FORMAT_REGULAR			=	1;
	var FORMAT_BOLD				=	2;
	var FORMAT_ITALIC			=	3;
	var FORMAT_BOLDITALIC		=	4;
}

enum MarkdownToken
{
	Link(display:String, link:String);
	Text(text:String, format:Int);
	Heading(text:String, level:Int);
	Bullet(text:String, indent:Int);
	ListItem(text:String, number:Int, indent:Int);
	HorizontalLine();
}

class TextBuffer
{

	private var _defaultFont:Font;
	private var _defaultFontSize:Int;

	private var _textBuffer:Image;
	private var _textStates:Array<TextState>;
	private var _textFormats:Array<TextFormat>;
	private var _requiresUpdates:Array<Bool>;
	private var _init:Bool;

	public var paragraphSpacing:Float = 18.0;

	/**
	 * Create a new `TextBuffer` with the given width and height.
	 * The size given is the constraints of the text to be drawn to the buffer.
	 * Any text that is drawn outside these constraints will not be rendered.
	 * @param width The width of the text buffer.
	 * @param height The height of the text buffer.
	 */
	public function new(width:Int, height:Int)
	{
		_textBuffer = Image.createRenderTarget(width, height);
		_textStates = [];
		_requiresUpdates = [];
		_textFormats = [];
		_init = false;
	}

	/**
	 * Set the default font and font size for the Text Buffer.
	 * @param font The default font to use when no other format is used.
	 * @param fontSize The default font size to use when no other font size is used.
	 */
	public function setDefaults(font:Font, fontSize:Int)
	{
		_defaultFont = font;
		_defaultFontSize = fontSize;

		var defaultFormat = new TextFormat();
		defaultFormat.name = "Default";
		defaultFormat.color = Color.Black;
		defaultFormat.font = _defaultFont;
		defaultFormat.fontSize = _defaultFontSize;
		_textFormats.push(defaultFormat);
	}

	/**
	 * Add a new `TextFormat` instance to this buffer that can be used between
	 * states.
	 * @param format The `TextFormat` to add.
	 */
	public function addTextFormat(format:TextFormat)
	{
		_textFormats.push(format);
	}

	/**
	 * Create a new state in which contains a chunk of text that will be rendered on screen.
	 * @param id The name of this state.
	 * @param x The X-position in the display buffer this state should be displayed at.
	 * @param y The Y-position in the display buffer this state should be displayed at.
	 * @param width The maximum width of the text. Text will automatically wrap based on this value.
	 * @param height The maximum height of the text. Ignored if clipping is not applied to the final render.
	 * @param clipping Determine if the text in this state's dimensions should clip.
	 */
	public function createNewState(id:String, x:Float, y:Float, width:Float, height:Float, clipping:Bool = false)
	{
		var state = new TextState(x, y, width, height);
		state.name = id;
		state.clipping = clipping;
		_requiresUpdates.push(false);
		return _textStates.push(state) - 1;
	}

	/**
	 * Add a single character value as an Integer character code using the default font and font size.
	 * 
	 * This function is faster that `addText` for single character input, but should be used sparingly.
	 * @param stateIndex The index of the state to add to.
	 * @param value The integer value representing a character code.
	 * @param crlf Determine the line feed character should be `\r\n`.
	 */
	public function addChar(stateIndex:Int, value:Int, crlf:Bool = false)
	{
		addCharFormatted(stateIndex, value, "Default", crlf);
	}

	/**
	 * Add a single character value as an Integer character code using the given format by name.
	 * 
	 * This function is faster that `addTextFormatted` for single character input, but should be used sparingly.
	 * @param stateIndex The index of the state to add to.
	 * @param value The integer value representing a character code.
	 * @param formatName The name of the format to use.
	 * @param crlf Determine the line feed character should be `\r\n`.
	 */
	public function addCharFormatted(stateIndex:Int, value:Int, formatName:String, crlf:Bool = false)
	{
		var state = _textStates[stateIndex];

		var formatIndex = 0;
		for (i in 0..._textFormats.length)
			if (_textFormats[i].name == formatName)
			{
				formatIndex = i;
				break;
			}
		
		var requiresNewFormat = false;
		if (state.formatIndices.length > 0 && state.formatIndices[state.formatIndices.length - 1] == formatIndex)
		{
			state.formatRanges[state.formatIndices.length - 1].y += 1;
		}
		else
		{
			requiresNewFormat = true;
		}

		state.characters.push(value);

		if (!crlf && value == 10)
		{
			state.lines.push(new LineInfo(state.characters.length, 1));
			return;
		}
		else if (crlf && (value == 10 || value == 13))
		{
			state.lines.push(new LineInfo(state.characters.length, 1));
			return;			
		}

		var lastLine:LineInfo = null;
		var lastLineWidth:Float = 0.0;
		if (state.lines.length > 0)
		{
			lastLine = state.lines[state.lines.length - 1];
			lastLineWidth = lastLine.lineEndX - lastLine.lineStartX;
		}

		if (requiresNewFormat)
		{
			var start = 0;
			if (lastLine != null)
				start = lastLine.end;

			state.formatRanges.push(new Vector2(start, start + 1));
			state.formatIndices.push(formatIndex);
		}
		
		var widthOfChar = _textFormats[formatIndex].font.widthOfCharacters(_textFormats[formatIndex].fontSize, [ value ], 0, 1);
		if (lastLineWidth + widthOfChar > state.dimension.width)
		{
			if (value == 32) // space, just create a new line
			{
				var line = new LineInfo(0, 0);
				if (lastLine != null)
					line.start = lastLine.end + 1;
				
				line.end = line.start + 1;
				line.lineStartX = state.dimension.x;
				line.lineEndX += widthOfChar;

				state.lines.push(line);
			}
			else if (value >= 33 && value != 127) // basically, any printable character
			{
				var lastSpace = lastLine.end;
				var isFirstLine = false;
				if (lastLine.start == 0)
					isFirstLine = true;
				
				while (state.characters[lastSpace] != 32 && 
					((isFirstLine && lastSpace >= 0) ||
					(!isFirstLine && lastSpace >= lastLine.start)))
					lastSpace -= 1;
				
				var start = 0;
				var end = 0;
				if ((isFirstLine && lastSpace != 0) || (!isFirstLine && lastSpace > lastLine.start))
				{
					// @TODO: Need to work out new lastLine.lineEndX based on whatever
					// format is being used between here and the last space.
					lastLine.end = lastSpace;
					start = lastSpace + 1;
					end = state.characters.length;
				}
				else
				{
					start = lastLine.end;
					end = start + 1;
				}
				
				var line = new LineInfo(start, end);
				line.lineStartX = state.dimension.x;
				line.lineEndX = state.dimension.x + widthOfChar;
				line.lineStartY = lastLine.lineEndY;
				line.lineEndY = line.lineStartY + _textFormats[formatIndex].font.height(_textFormats[formatIndex].fontSize);
				state.lines.push(line);
			}
		}
		else 
		{
			if (lastLine != null)
			{
				lastLine.end += 1;
				lastLine.lineEndX += widthOfChar;
			}
		}

		if (lastLine == null) // probably adding characters to the state for the first time
		{
			var line = new LineInfo(0, 1);
			line.lineStartX = state.dimension.x;
			line.lineStartY = state.dimension.y;
			line.lineEndX = state.dimension.x + widthOfChar;
			line.lineEndY = line.lineStartY + _textFormats[formatIndex].font.height(_textFormats[formatIndex].fontSize);
			state.lines.push(line);
		}
		
		_requiresUpdates[stateIndex] = true;
	}

	/**
	 * Add text to the given index using the default font and font size.
	 * 
	 * This function will perform a full update on the `TextState` and is not recommended
	 * for small quantities of text.
	 * 
	 * Paragraphs detected by `\n` will be separated into new states, unless `crlf` is `true`, meaning
	 * a `\r` should precede the `\n` to detect a new line.
	 * 
	 * @param stateIndex The state index to add text to.
	 * @param value The text to add.
	 * @param crlf Use CRLF (`\r\n`) for detecting new lines.
	 */
	public function addText(stateIndex:Int, value:String, crlf:Bool = false)
	{
		addTextFormatted(stateIndex, value, "Default", crlf);
	}

	/**
	 * Add text to the given index using the given format.
	 * 
	 * This function will perform a full update on the `TextState` and is not recommended
	 * for small quantities of text.
	 * 
	 * Paragraphs detected by `\n` will be separated into new states, unless `crlf` is `true`, meaning
	 * a `\r` should precede the `\n` to detect a new line.
	 * @param stateIndex The state index to add text to.
	 * @param value The text to add.
	 * @param format The name of the text format to use. This should match the name of the format previously added to this buffer.
	 * @param crlf Use CRLF (`\r\n`) for detecting new lines.
	 */
	public function addTextFormatted(stateIndex:Int, value:String, formatName:String, crlf:Bool = false)
	{
		var state = _textStates[stateIndex];

		var formatIndex:Int = 0;
		
		for (i in 0..._textFormats.length)
			if (_textFormats[i].name == formatName)
			{
				formatIndex = i;
				break;
			}
		
		state.formatRanges.push(new Vector2(0, 0));
		state.formatIndices.push(formatIndex);

		// new paragraphs will be made into new `TextState`'s for efficiency
		var first = "";
		var upto = -1;
		for (i in 0...value.length)
		{
			if (StringTools.fastCodeAt(value, i) == 10 && !crlf)
			{
				upto = i;
				break;
			}
			else if (StringTools.fastCodeAt(value, i) == 13 && StringTools.fastCodeAt(value, i + 1) == 10 && crlf)
			{
				upto = i;
				break;
			}
		}

		if (upto == -1)
			upto = value.length;
		
		var chars = value.toCharArray();
		var startIndex:Int = 0;
		var lastChar:String = null;
		if (state.characters.length > 0)
		{
			startIndex = state.characters.length - 1;
			lastChar = String.fromCharCode(state.characters[startIndex]);
		}

		var endIndex:Int = startIndex + upto;

		for (i in 0...upto)
		{
			state.characters.push(chars[i]);
		}

		var lastLine:LineInfo = null;
		var firstLine = state.lines.length == 0 || state.lines.length == 1;
		if (state.lines.length > 0)
			lastLine = state.lines[state.lines.length - 1];
		
		// lines have startX, startY, endX, endY variables,
		// so we need to make sure we make adjustments to the way
		// text is rendered according to these positions.
		// this is to allow wrapping around objects other than text.

		var startX = 0.0;
		var startY = 0.0;
		var endX = 0.0;
		var endY = 0.0;
		var lastBreak = 0;

		var currentLine:LineInfo = null;
		if (lastLine != null)
		{
			currentLine = lastLine;
			startX = lastLine.lineStartX;
			startY = lastLine.lineStartY;
			lastBreak = lastLine.start;
			if (lastChar != "")
				startX += (lastLine.lineEndX - lastLine.lineStartX);
		}

		if (currentLine == null)
		{
			var line = new LineInfo(0, 0);
			line.lineStartY = state.dimension.y;
			line.lineStartX = state.dimension.x;
			state.lines.push(line);
			currentLine = state.lines[state.lines.length - 1];
		}

		var measurableWidth = state.dimension.width;
		var currentTextWidth = startX;
		var index = startIndex;
		var lastChance = -1;
		var linesAdded = 0;
		var maxHeight = 0.0;

		var range = state.formatRanges[state.formatRanges.length - 1];
		range.x = index;
		range.y = endIndex;

		while (index <= endIndex)
		{
			currentTextWidth = _textFormats[formatIndex].font.widthOfCharacters(_textFormats[formatIndex].fontSize, state.characters, currentLine.start, index - currentLine.start);
			if (currentTextWidth >= measurableWidth)
			{
				if (lastChance < 0)
				{
					lastChance = index - 1;
				}

				currentLine.end = lastChance + 1;
				currentLine.lineEndX = currentLine.lineStartX + currentTextWidth;

				var line = new LineInfo(currentLine.end, 0);
				line.lineStartX = state.dimension.x;
				line.lineStartY = currentLine.lineStartY + _textFormats[formatIndex].font.height(_textFormats[formatIndex].fontSize);
				line.lineEndY = line.lineStartY + _textFormats[formatIndex].font.height(_textFormats[formatIndex].fontSize);
				state.lines.push(line);
				currentLine = state.lines[state.lines.length - 1];

				lastBreak = lastChance + 1;
				index = lastBreak;
				lastChance = -1;
				maxHeight += _textFormats[formatIndex].font.height(_textFormats[formatIndex].fontSize);
			}

			if (state.characters[index] == " ".charCodeAt(0))
			{
				lastChance = index;
			}

			index += 1;
			currentLine.end = index;
			currentLine.lineEndX = currentTextWidth + currentLine.lineStartX;
			// @TODO: assumes we only use one format for the line. Should refactor.
			if (firstLine)
				currentLine.lineEndY = state.dimension.y + _textFormats[formatIndex].font.height(_textFormats[formatIndex].fontSize);
		}

		_requiresUpdates[stateIndex] = true;

		if (upto < value.length)
		{
			var current = "";
			var stateToUpdate = -1;
			var startNext = upto;
			while (StringTools.fastCodeAt(value, startNext) == 10 || StringTools.fastCodeAt(value, startNext) == 13)
				startNext += 1;

			if (state.clipping)
			{
				if (maxHeight > state.dimension.height)
					maxHeight = state.dimension.height;
			}

			for (i in upto...value.length)
			{
				if (StringTools.fastCodeAt(value, i) == 10 && !crlf)
				{
					stateToUpdate = createNewState(state.name + "_" + i, state.dimension.x, state.dimension.y + maxHeight + paragraphSpacing, state.dimension.width, state.dimension.height);
				}
				else if (StringTools.fastCodeAt(value, i) == 13 && StringTools.fastCodeAt(value, i + 1) == 10 && crlf)
				{
					stateToUpdate = createNewState(state.name + "_" + i, state.dimension.x, state.dimension.y + maxHeight + paragraphSpacing, state.dimension.width, state.dimension.height);					
				}
				else
				{
					if (StringTools.fastCodeAt(value, i) != 10)
						current += value.charAt(i);
				}
			}

			addTextFormatted(stateToUpdate, current, formatName, crlf);
		}
	}

	/**
	 * Update all states within the buffer.
	 */
	public function updateAll()
	{
		for (i in 0..._requiresUpdates.length)
		{
			_requiresUpdates[i] = true;
		}

		updateBuffer();
	}

	/**
	 * Updates the buffer. Only updates the states that require updating.
	 * This function is best used when you are dealing with large amounts of text
	 * and states.
	 * 
	 * This function will clear areas on the buffer where states update. This means
	 * that if one state overlaps another, the state being overlapped will also be cleared,
	 * but not updated if it is not tagged to update. As such, if states are likely to
	 * overlap, ensure those states are also updated and their positions moved
	 * accordingly.
	 */
	public function updateBuffer()
	{
		var g2 = _textBuffer.g2;

		if (!_init)
		{
			g2.begin(true, Color.fromFloats(0, 0, 0, 0));
			_init = true;
		}
		else
		{
			g2.begin(false);
		}

		for (i in 0..._textStates.length)
		{
			var state = _textStates[i];
			if (state.lines.length > 0)
			{
				var startY = state.lines[0].lineStartY;
				var endY = state.lines[0].lineEndY;
				if (state.lines.length > 1)
					endY = state.lines[state.lines.length - 1].lineEndY;

				var height = endY - startY;
				if (state.clipping)
					height = state.dimension.height;

				if (_requiresUpdates[i])
					_textBuffer.clear(cast state.dimension.x, cast state.dimension.y, 0, cast state.dimension.width, cast height, 0, Color.fromFloats(0, 0, 0, 0));
			}
		}

		for (i in 0..._textStates.length)
		{
			var state = _textStates[i];
			if (!_requiresUpdates[i])
				continue;

			if (state.clipping)
				g2.scissorDim(state.dimension);

			for (j in 0...state.lines.length)
			{
				var line = state.lines[j];
				var startX = line.lineStartX;
				var lastStartIndex = 0;
				var lastEndIndex = 0;

				for (k in 0...state.formatRanges.length)
				{
					var fr = state.formatRanges[k];
					if ((fr.x >= line.start || fr.y >= line.start) && (fr.x < line.end))
					{
						var f = _textFormats[state.formatIndices[k]];
						g2.font = f.font;
						g2.fontSize = f.fontSize;
						var start = lastStartIndex;
						var end = 0;
						if (fr.x < line.start)
							start = line.start;
						else if (fr.x > line.start && lastStartIndex != 0)
							start = cast fr.x;

						if (fr.y < line.end)
							end = cast fr.y;
						else
							end = line.end;

						var textWidth = g2.font.widthOfCharacters(g2.fontSize, state.characters, start, end - start);
						if (f.backColor != null)
						{
							g2.color = f.backColor;
							g2.fillRect(startX, line.lineStartY, textWidth, g2.font.height(g2.fontSize));
						}

						g2.color = f.color;
						g2.drawCharacters(state.characters, start, end - start, startX, line.lineStartY);

						if (f.underline)
							g2.drawLine(startX, line.lineStartY + g2.font.height(g2.fontSize), startX + textWidth, line.lineStartY + g2.font.height(g2.fontSize));

						startX += textWidth;
						lastStartIndex = end;
					}
				}
			}

			if (state.clipping)
				g2.disableScissor();
		}

		g2.end();
	}

	/**
	 * Render the buffer to the given 2D drawing context.
	 * @param g2 The `kha.graphics2.Graphics` graphics context to draw to.
	 * @param offsetX The x-position of the buffer.
	 * @param offsetY The y-position of the buffer.
	 */
	public function render(g2:Graphics, offsetX:Float, offsetY:Float)
	{
		g2.color = Color.White;
		g2.drawImage(_textBuffer, offsetX, offsetY);
	}

}