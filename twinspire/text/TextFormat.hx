package twinspire.text;

import kha.Color;
import kha.Font;

class TextFormat
{

	public var name:String;
	public var color:Color;
	public var backColor:Color;
	public var font:Font;
	public var fontSize:Int;
	public var underline:Bool;
	public var superscript:Bool;
	public var subscript:Bool;
	public var fraction:Int;

	public function new()
	{
		
	}

	public function clone()
	{
		var format = new TextFormat();
		format.font = this.font;
		format.fontSize = this.fontSize;
		format.color = this.color;
		format.backColor = this.backColor;
		format.underline = this.underline;
		format.superscript = this.superscript;
		return format;
	}

}