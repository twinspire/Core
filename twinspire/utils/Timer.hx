/**
Copyright 2017 Colour Multimedia Enterprises, and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

package twinspire.utils;

import kha.System;

class Timer
{

	private var _lastTime:Float;
	private var _dt:Float;
	private var _tickValues:Array<Float>;
	private var _tickValueIndex:Int;

	public function new(timers:Int)
	{
		_tickValues = [];
		
		for (i in 0...timers)
			_tickValues.push(0);

		_lastTime = System.time;
	}

	public function begin()
	{
		_tickValueIndex = -1;
		_dt = System.time - _lastTime;
	}

	public function tick(seconds:Float, ?index:Int = -1)
	{
		var index_in = 0;
		if (index > -1)
			index_in = index;
		else
			index_in = ++_tickValueIndex;
		
		_tickValues[index_in] += _dt;
		if (_tickValues[index_in] >= seconds)
		{
			_tickValues[index_in] = 0.0;
			return true;
		}

		return false;
	}

	public function end()
	{
		_tickValueIndex = -1;
		_lastTime = System.time;
	}

}