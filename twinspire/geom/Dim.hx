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

	public function getX()
	{
		var x:Float = 0.0;
		x = this.x;
		return x;
	}

	public function getY()
	{
		var y:Float = 0.0;
		y = this.y;
		return y;
	}

	public function getWidth()
	{
		var width:Float = 0.0;
		width = this.width;
		return width;
	}

	public function getHeight()
	{
		var height:Float = 0.0;
		height = this.height;
		return height;
	}

	/**
	 * Return a new dimension with all zero values.
	 * This value should not be used as is.
	 */
	public static var zero(get, never):Dim;
	private static function get_zero()
	{
		return new Dim(0, 0, 0, 0, 0);
	}

}