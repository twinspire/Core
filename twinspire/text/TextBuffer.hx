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

class TextBuffer
{

	private var _defaultFont:Font;
	private var _defaultFontSize:Int;

	private var _textBuffer:Image;
	private var _textStates:Array<TextState>;
	private var _textFormats:Array<TextFormat>;
	private var _requiresUpdates:Array<Bool>;

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
	 * @param stateIndex 
	 * @param value 
	 */
	public function addChar(stateIndex:Int, value:Int)
	{

	}

	public function addCharFormat(stateIndex:Int, value:Int)
	{

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
				currentLine.lineEndY = currentLine.lineStartY;

				var line = new LineInfo(currentLine.end, 0);
				line.lineStartX = state.dimension.x;
				line.lineEndY = line.lineStartY = currentLine.lineStartY + _textFormats[formatIndex].font.height(_textFormats[formatIndex].fontSize);
				line.lineEndX = state.dimension.x + currentTextWidth;
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

	public function updateBuffer()
	{
		var g2 = _textBuffer.g2;

		g2.begin(true, Color.fromFloats(0, 0, 0, 0));

		// just update all the states for now.
		// should refactor to only update states when there is a need.

		g2.color = Color.Black;
		g2.font = _defaultFont;
		g2.fontSize = _defaultFontSize;
		for (i in 0..._textStates.length)
		{
			var state = _textStates[i];
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
					if ((fr.x >= line.start && fr.x <= line.end) ||
						(fr.y <= line.end && fr.y <= line.end))
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

	public function render(g2:Graphics, offsetX:Float, offsetY:Float)
	{
		g2.color = Color.White;
		g2.drawImage(_textBuffer, offsetX, offsetY);
	}

}