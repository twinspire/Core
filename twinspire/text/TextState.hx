package twinspire.text;

import kha.math.Vector2;
import twinspire.geom.Dim;

class TextState
{

	public var name:String;
	public var dimension:Dim;
	public var lines:Array<LineInfo>;
	public var characters:Array<Int>;
	public var formatRanges:Array<Vector2>;
	public var formatIndices:Array<Int>;
	public var clipping:Bool;

	public inline function new(x:Float, y:Float, width:Float, height:Float)
	{
		dimension = new Dim(x, y, width, height);
		lines = [];
		characters = [];
		formatRanges = [];
		formatIndices = [];
		clipping = false;
	}

}