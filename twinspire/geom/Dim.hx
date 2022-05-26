package twinspire.geom;

class Dim
{

	public var x:Float;
	public var y:Float;
    public var order:Int;
	public var width:Float;
	public var height:Float;

	public inline function new(x:Float, y:Float, width:Float, height:Float, order:Int = 0)
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
        this.order = order;
	}

	public static var Zero(get, never):Dim;
	private static function get_Zero()
	{
		return new Dim(0, 0, 0, 0);
	}

}