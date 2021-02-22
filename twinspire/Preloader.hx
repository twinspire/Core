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

	/**
	* The back colour of the entire screen.
	**/
	public var backColor:Color;
	/**
	* The colour to use for progress.
	**/
	public var fillColor:Color;
	/**
	* The border colour of the progress bar.
	**/
	public var borderColor:Color;
	/**
	* The border width, if any, to use. 0 for no border.
	**/
	public var border:Int;

	/**
	* Create a new Preloader with the given style.
	* Passing PRELOADER_CUSTOM means you can customise the preloader by overriding the `render` function.
	**/
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
			case PRELOADER_STYLISH:
				width = System.windowWidth() * .75;
				height = 17;
				x = (System.windowWidth() - width) / 2;
				y = System.windowHeight() * .65;
				backColor = Color.Black;
				fillColor = Color.fromFloats(.8, .12, 0);
		}
	}

	/**
	* Render the progress results on screen. Override in a derived class to customise.
	**/
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