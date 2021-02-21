package twinspire;

class Animate
{

	/**
	 * Get or set the maximum number of animations that can be used.
	 */
	public static var animateMax:Int = 1000;

	static var animateTicks:Array<Float>;
	static var animateTicksDelays:Array<Float>;
	static var animateTickReset:Array<Bool>;
	static var animateTickLoopDir:Array<Int>;
	static var lastAnimateSecondsValue:Float;
	static var animateIndex:Int = -1;
	static var deltaTime:Float;

	/**
	 * Initialise Animations.
	 */
	public static function animateInit()
	{
		animateClear();
		animateIndex = -1;
	}

	/**
	 * Set the time passed between frames (delta time).
	 * @param dt The value of the delta time.
	 */
	public static function animateTime(dt:Float)
	{
		deltaTime = dt;
	}

	/**
	 * Create an animation at a given index.
	 * @return Returns a new index for this animation.
	 */
	public static function animateCreateTick()
	{
		return ++animateIndex;
	}

	/**
	 * Reset all animation ticks that require a reset, setting all their values to 0.
	 */
	public static function animateResetTicks()
	{
		for (i in 0...animateTickReset.length)
		{
			if (animateTickReset[i])
			{
				animateTicks[i] = 0.0;
				animateTickReset[i] = false;
			}
		}
	}

	/**
	 * Clear all data for all animations and reset all values to zero.
	 */
	public static function animateClear()
	{
		animateTicks = [ for (i in 0...animateMax) 0.0 ];
		animateTickReset = [ for (i in 0...animateMax) false ];
		animateTickLoopDir = [ for (i in 0...animateMax) 1 ];
		animateTicksDelays = [ for (i in 0...animateMax) 0.0 ];
	}

	/**
	 * Tick an animation index up to a certain number of seconds, and return `true` when this time passes.
	 * @param index The index for which animation to tick.
	 * @param seconds The number of seconds to wait before this animation ticks over.
	 * @param delay The number of seconds to wait before ticking again.
	 * @return Returns `true` if the number of seconds given has passed, `false` otherwise.
	 */
	public static function animateTick(index:Int, seconds:Float, ?delay:Float = 0.0)
	{
		var result = false;
		lastAnimateSecondsValue = seconds;

		if (delay > 0.0)
		{
			if (animateTicks[index] + deltaTime > seconds)
			{
				result = true;
				if (animateTicksDelays[index] + deltaTime > delay)
				{
					result = false;
					animateTicksDelays[index] = 0.0;
					animateTickReset[index] = true;
				}
				else
				{
					animateTicksDelays[index] += deltaTime;
				}
			}
			else 
			{
				animateTicks[index] += deltaTime;
			}
		}
		else
		{
			if (animateTicks[index] + deltaTime > seconds)
			{
				result = true;
			}
			else 
			{
				animateTicks[index] += deltaTime;
			}
		}

		return result;
	}

	/**
	 * Like `animateTick`, ticks for the given number of seconds at the given index, but on a given condition.
	 * @param index The index for which animation to tick.
	 * @param seconds The number of seconds to wait before this animation ticks over.
	 * @param conditional The condition on which this animation will tick.
	 * @return Returns `true` if the number of seconds given has passed, `false` otherwise.
	 */
	public static function animateTickCond(index:Int, seconds:Float, conditional:Bool)
	{
		if (conditional)
		{
			return animateTick(index, seconds);
		}
		else
		{
			return false;
		}
	}

	/**
	 * Exactly the same as `animateTick`, except when the number of seconds has passed, the value for the tick interval
	 * decrements, rather than increments, then once it reaches zero it increments again. Each time either zero or the number
	 * of seconds passes, this function returns `true`.
	 * @param index The index for which animation to tick.
	 * @param seconds The number of seconds to wait before this animation ticks over.
	 * @param delay The number of seconds to wait before ticking again.
	 * @return Returns `true` if the number of seconds given has passed or reaches zero, `false` otherwise.
	 */
	public static function animateTickLoop(index, seconds:Float, ?delay:Float = 0.0)
	{
		var result = false;
		lastAnimateSecondsValue = seconds;

		if (animateTickLoopDir[index] == 1)
		{
			if (animateTicks[index] + deltaTime > seconds)
			{
				result = true;
				animateTickLoopDir[index] = -1;
			}
			else 
			{
				animateTicks[index] += deltaTime;
			}
		}
		else if (animateTickLoopDir[index] == -1)
		{
			if (animateTicksDelays[index] + deltaTime > delay)
			{
				if (animateTicks[index] - deltaTime < 0)
				{
					result = true;
					animateTickLoopDir[index] = 1;
				}
				else
				{
					animateTicks[index] -= deltaTime;
				}

				animateTicksDelays[index] = 0.0;
			}
			else 
			{
				animateTicksDelays[index] += deltaTime;
			}
		}

		return result;
	}

	/**
	 * Returns the ratio of the animation based on the current seconds of in-game time passed.
	 * e.g. 0.5 seconds passed / 2.0 seconds given in a *tick function = 0.25.
	 * Make sure you use a *tick function before calling this function.
	 * @param index The index of the animation.
	 * @return A floating-point value indicating the ratio of the current seconds passed for this animation
	 * versus the total time given.
	 */
	public static function animateGetRatio(index:Int)
	{
		return animateTicks[index] / lastAnimateSecondsValue;
	}

}