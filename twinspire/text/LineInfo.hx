package twinspire.text;

class LineInfo
{

	/**
	* The starting character position from source data.
	**/
	public var start:Int;
	/**
	* The ending character position from source data.
	**/
	public var end:Int;
	/**
	* The total height of this line.
	**/
	public var height:Float;

	public inline function new(start:Int, end:Int) {
		this.start = start;
		this.end = end;
		height = 0.0;
	}

}