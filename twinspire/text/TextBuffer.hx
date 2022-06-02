package twinspire.text;

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

	public function addText(stateIndex:Int, value:String)
	{
		var state = _textStates[stateIndex];
		var chars = value.toCharArray();
		var startIndex:Int = 0;
		var lastChar:String;
		if (state.characters.length > 0)
		{
			startIndex = state.characters.length - 1;
			lastChar = String.fromCharCode(state.characters[startIndex]);
		}

		var endIndex:Int = startIndex + chars.length;

		for (i in 0...chars.length)
		{
			state.characters.push(chars[i]);
		}

		var lastLine:LineInfo;
		if (state.lines.length > 0)
			lastLine = state.lines[state.lines.length - 1];
		
		var startLine:LineInfo;
		var endLine:LineInfo;
		// lines have startX, startY, endX, endY variables,
		// so we need to make sure we make adjustments to the way
		// text is rendered according to these positions.
		// this is to allow wrapping around objects other than text.

		var startX = 0.0;
		var startY = 0.0;
		var endX = 0.0;
		var endY = 0.0;

		if (lastLine != null)
		{
			startX = lastLine.lineStartX;
			startY = lastLine.lineStartY;
			if (lastChar != "")
				startX += _defaultFont.width(_defaultFontSize, lastChar);
		}

		var measurableWidth = state.dimension.width;
		var currentTextWidth = 0.0;
		var index = startIndex;
		while (index < endIndex)
		{
			

			index += 1;
		}

		_requiresUpdates[stateIndex] = true;
	}

	public function updateBuffer()
	{
		for (i in 0..._requiresUpdates.length)
		{
			if (_requiresUpdates[i])
			{
				performStateUpdate(i);
				_requiresUpdates[i] = false;
			}
		}
	}

	public function render(g2:Graphics)
	{
		g2.color = Color.White;
		g2.drawImage(_textBuffer, 0, 0);
	}

	private function performStateUpdate(index:Int)
	{
		var state = _textStates[index];

	}

}