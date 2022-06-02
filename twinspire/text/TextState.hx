package twinspire.text;

import twinspire.geom.Dim;

class TextState
{

	public var name:String;
	public var dimension:Dim;
	public var lines:Array<LineInfo>;
	public var characters:Array<Int>;
	public var formats:Array<TextFormat>;

	public inline function new(x:Float, y:Float, width:Float, height:Float)
	{
		dimension = new Dim(x, y, width, height);
		lines = [];
		characters = [];
		formats = [];
	}

}