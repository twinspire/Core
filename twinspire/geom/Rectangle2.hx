package twinspire.geom;

import kha.math.FastVector2 in FV2;

import twinspire.utils.ExtraMath;

class Rectangle2
{

	public var left:Float;
	public var right:Float;
	public var top:Float;
	public var bottom:Float;

	public inline function new(left:Float, right:Float, top:Float, bottom:Float)
	{
		this.top = top;
		this.left = left;
		this.right = right;
		this.bottom = bottom;
	}

	// public inline function invertedInfinity()
	// {
	// 	min.x = min.y = Math.POSITIVE_INFINITY;
	// 	max.x = max.y = -Math.POSITIVE_INFINITY;
	// }

	// public inline function union(other:Rectangle2)
	// {
	// 	min.x = (min.x < other.min.x) ? min.x : other.min.x;
	// 	min.y = (min.y < other.min.y) ? min.y : other.min.y;
	// 	max.x = (max.x > other.max.x) ? max.x : other.max.x;
	// 	max.y = (max.y > other.max.y) ? max.y : other.max.y;
	// }

	// public inline function getDimension()
	// {
	// 	return max.sub(min);
	// }

	// public inline function getCenter()
	// {
	// 	return min.add(max).mult(0.5);
	// }

	// public inline function isInRectangle(test:FV2)
	// {
	// 	var result = ((test.x >= min.x) &&
    //                  (test.y >= min.y) &&
    //                  (test.x < max.x) &&
    //                  (test.y < max.y));

    // 	return result;
	// }

	// public inline function intersects(other:Rectangle2)
	// {
	// 	var result = !((other.max.x <= min.x) ||
    //                (other.min.x >= max.x) ||
    //                (other.max.y <= min.y) ||
    //                (other.min.y >= max.y));

    // 	return result;
	// }

	// public inline function getBarycentric(p:FV2)
	// {
	// 	var result = new FV2(0, 0);

	// 	result.x = ExtraMath.safeRatio0(p.x - min.x, max.x - min.x);
	// 	result.y = ExtraMath.safeRatio0(p.y - min.y, max.y - min.y);

	// 	return result;
	// }

	// public inline function getArea()
	// {
	// 	var dim = getDimension();
	// 	var result = dim.x * dim.y;
	// 	return result;
	// }


}