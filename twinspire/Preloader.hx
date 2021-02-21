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

	public function render(buffers:Array<Framebuffer>)
	{
		var g = buffers[0].g2;

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