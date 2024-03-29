package twinspire.utils;

/**
* A series of extra mathematical functions.
*/
class ExtraMath
{

	/**
	* Round a floating-point number to the nearest integral or decimal number with the given precision.
	* Unlike `froundPrecise2`, only the multiplication part is rounded and its result divided by its power.
	*
	* @param n The floating-point number to round.
	* @param prec The precision to round to.
	*
	* @return Return the resulting rounded value.
	*/
	public static function froundPrecise(n:Float, prec:Int)
	{
		var pow:Int = cast Math.pow(10, prec);
		var result = Math.round(n * pow) / pow;
		return result;
	}


	public static function froundAddPrecise(a:Float, b:Float, prec:Int)
	{
		var _aI:Int = cast (a * prec);
		var _bI:Int = cast (b * prec);
		var sum:Int = _aI + _bI;
		var result:Float = sum / prec;
		return result;
	}

	/**
	* Round a floating-point number to the nearest integral or decimal number with the given precision.
	* Unlike `froundPrecise`, the full result of the precision multiplication/division is rounded.
	*
	* @param n The floating-point number to round.
	* @param prec The precision to round to.
	*
	* @return Return the resulting rounded value.
	*/
	public static function froundPrecise2(n:Float, prec:Int)
	{
		var pow = Math.pow(10, prec);
		var result = Math.round((n * pow) / pow);
		return result;
	}

	/**
	* Gets the minimum number from a series of values.
	*
	* @param values The `values` to check.
	*
	* @return Returns the lowest value from the given array.
	*/
	public static function min(values:Array<Float>)
	{
		var result:Float = 0;
		for (v in values)
		{
			if (v < result)
				result = v;
		}			
		
		return result;
	}

	/**
	* Gets the maximum number from a series of values.
	*
	* @param values The `values` to check.
	*
	* @return Returns the highest value from the given array.
	*/
	public static function max(values:Array<Float>)
	{
		var result:Float = 0;
		for (v in values)
		{
			if (v > result)
				result = v;
		}
		
		return result;
	}


	public static function getRadians(angle:Float):Float
	{
		var total = Math.PI * 2;
		var totalDegrees = 360.0;
		var ratioDegrees = angle / totalDegrees;
		return total * ratioDegrees;
	}

	/**
	* Gets the average from a series of values.
	*
	* @param values The `values` to use.
	*
	* @return Returns the average of the values given as an integer.
	**/
	public static function average(values:Array<Float>)
	{
		return Std.int(fAverage(values));
	}

	/**
	* Gets the average from a series of values.
	*
	* @param values The `values` to use.
	*
	* @return Returns the average of the values given as a floating-point.
	**/
	public static function fAverage(values:Array<Float>)
	{
		var count = values.length;
		var total = 0.0;
		for (v in values)
			total += v;
		
		return total / count;
	}

	public static function safeRatioN(numerator:Float, divisor:Float, n:Float)
	{
		var result = n;

		if (divisor != 0.0)
		{
			result = numerator / divisor;
		}

		return result;
	}

	public static function safeRatio0(numerator:Float, divisor:Float)
	{
		var result = safeRatioN(numerator, divisor, 0.0);

		return result;
	}

	public static function random(start:Int, end:Int)
	{
		var result = Math.ceil(start + (end - start) * Math.random());

		return result;
	}

}