/**
Copyright 2017 Colour Multimedia Enterprises, and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

package twinspire;

import kha.graphics2.Graphics;
import kha.Color;
import kha.System;
import kha.Assets;
import kha.Framebuffer;

@:enum
abstract PreloaderStyle(Int) from Int to Int
{
	var PRELOADER_BASIC			=	1;
	var PRELOADER_STYLISH		=	2;

	var PRELOADER_CUSTOM		=	-1;
}

class Preloader
{

	var x:Float;
	var y:Float;
	var width:Float;
	var height:Float;

	public var backColor:Color;
	public var fillColor:Color;
	public var borderColor:Color;
	public var border:Int;

	public function new(style:Int)
	{
		switch (style)
		{
			case PRELOADER_BASIC:
				width = System.windowWidth() * .5;
				height = 30;
				x = (System.windowWidth() - width) / 2;
				y = (System.windowHeight() - height) / 2;
				backColor = Color.White;
				fillColor = borderColor = Color.fromFloats(.5, .5, .5);
				border = 1;
		}
	}

	public function render(buffer:Framebuffer)
	{
		var g = buffer.g2;

		g.begin(true, backColor);

		if (border > 0)
		{
			g.color = borderColor;
			g.drawRect(x, y, width, height, border);
		}

		g.color = fillColor;
		
		var actual_width = (width - border / 2 - 4) * Assets.progress;
		g.fillRect(x + 2 + border, y + 2 + border, actual_width - border / 2 - 2, height - border / 2 - 2);

		g.end();
	}

}