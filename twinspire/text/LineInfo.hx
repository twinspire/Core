package twinspire.text;

class LineInfo
{

	public var start:Int;
	public var end:Int;
	public var lineStartX:Float;
	public var lineStartY:Float;
	public var lineEndX:Float;
	public var lineEndY:Float;

	public inline function new(start:Int, end:Int)
	{
		this.start = start;
		this.end = end;
	}

}