package twinspire.text;

import twinspire.text.LineInfo;
import kha.graphics4.DepthStencilFormat;
import kha.graphics4.TextureFormat;
import kha.graphics2.Graphics;
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
	private var _requiresUpdates:Array<Bool>;

	public var paragraphSpacing:Float = 18.0;

	public function new(width:Int, height:Int)
	{
		_textBuffer = Image.createRenderTarget(width, height);
		_textStates = [];
		_requiresUpdates = [];
	}

	public function setDefaults(font:Font, fontSize:Int)
	{
		_defaultFont = font;
		_defaultFontSize = fontSize;
	}

	public function createNewState(id:String, x:Float, y:Float, width:Float, height:Float)
	{
		var state = new TextState(x, y, width, height);
		state.name = id;
		_requiresUpdates.push(false);
		return _textStates.push(state) - 1;
	}

	public function addText(stateIndex:Int, value:String, crlf:Bool = false)
	{
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

		var state = _textStates[stateIndex];
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

		while (index <= endIndex)
		{
			currentTextWidth = _defaultFont.widthOfCharacters(_defaultFontSize, state.characters, currentLine.start, index - currentLine.start);
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
				line.lineEndY = line.lineStartY = currentLine.lineStartY + _defaultFont.height(_defaultFontSize);
				line.lineEndX = state.dimension.x + currentTextWidth;
				state.lines.push(line);
				currentLine = state.lines[state.lines.length - 1];

				lastBreak = lastChance + 1;
				index = lastBreak;
				lastChance = -1;
				maxHeight += _defaultFont.height(_defaultFontSize);
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

			addText(stateToUpdate, current, crlf);
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
			for (i in 0...state.lines.length)
			{
				var line = state.lines[i];
				var x = state.dimension.x + line.lineStartX;
				var y = state.dimension.y + line.lineStartY;
				g2.drawCharacters(state.characters, line.start, line.end - line.start, x, y);
			}
		}

		g2.end();
	}

	public function render(g2:Graphics, offsetX:Float, offsetY:Float)
	{
		g2.color = Color.White;
		g2.drawImage(_textBuffer, offsetX, offsetY);
	}

}