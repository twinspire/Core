package twinspire.extensions;

import twinspire.geom.Dim;

import kha.graphics2.Graphics;
import kha.Image;
import kha.Video;

enum abstract TriangleDirection(Int) from Int to Int
{
	var TRIANGLE_LEFT			=	0x01;
	var TRIANGLE_RIGHT			=	0x02;
	var TRIANGLE_UP				=	0x04;
	var TRIANGLE_DOWN			=	0x08;
}

class Graphics2
{

	private static var _forceMultilineUpdate:Bool;

	public static function drawImageDim(g2:Graphics, img:Image, dim:Dim)
	{
		g2.drawImage(img, dim.x, dim.y);
	}

	public static function drawSubImageDim(g2:Graphics, img:Image, destination:Dim, source:Dim)
	{
		g2.drawSubImage(img, destination.x, destination.y, source.x, source.y, source.width, source.height);
	}

	public static function drawScaledImageDim(g2:Graphics, img:Image, destination:Dim)
	{
		g2.drawScaledImage(img, destination.x, destination.y, destination.width, destination.height);
	}

	public static function drawScaledSubImageDim(g2:Graphics, img:Image, source:Dim, destination:Dim)
	{
		g2.drawScaledSubImage(img, source.x, source.y, source.width, source.height, destination.x, destination.y, destination.width, destination.height);
	}

	public static function drawRectDim(g2:Graphics, destination:Dim, lineThickness:Float = 1.0)
	{
		g2.drawRect(destination.x, destination.y, destination.width, destination.height, lineThickness);
	}

	public static function fillRectDim(g2:Graphics, destination:Dim)
	{
		g2.fillRect(destination.x, destination.y, destination.width, destination.height);
	}

	public static function drawStringDim(g2:Graphics, text:String, destination:Dim)
	{
		g2.drawString(text, destination.x, destination.y);
	}

	public static function forceMultilineUpdate()
	{
		_forceMultilineUpdate = true;
	}

	/**
	 * Draw characters using a destination `Dim`. If not auto-wrapping, this will draw using the basic `drawCharacters` function with the given
	 * `start` and `length` parameters. If `autoWrap` is true, additional logic is performed.
	 * 
	 * When using `autoWrap`, this function will require use of `breaks`. If `breaks` is not supplied, this function will repeatedly perform
	 * multiline wrapping of the given characters each frame it is called (it is not recommended to do this). In addition, the parameters `start` and
	 * `length` are ignored.
	 * 
	 * If using `clipping`, the `destination` will be used as the clipping region.
	 * 
	 * This function returns an `Array<Int>` indicating the breaks involved in a multiline scenario. When `autoWrap` is `false`, the result is always
	 * `null`.
	 * @param g2 
	 * @param characters 
	 * @param start 
	 * @param length 
	 * @param destination 
	 * @param autoWrap 
	 * @param clipping 
	 * @param breaks 
	 * @return Array<Int>
	 */
	public static function drawCharactersDim(g2:Graphics, characters:Array<Int>, start:Int, length:Int, destination:Dim, autoWrap:Bool = false, clipping:Bool = false, breaks:Array<Int> = null):Array<Int>
	{
		if (!autoWrap)
		{
			g2.drawCharacters(characters, start, length, destination.x, destination.y);
			return null;
		}
		else
		{
			var maxWidth = destination.width;
			if (clipping)
				scissorDim(g2, destination);

			var currentBreaks = breaks;
			if (currentBreaks == null || _forceMultilineUpdate)
			{
				currentBreaks = [];
				var index = 0;
				var lastChance = -1;
				var lastBreak = 0;
				while (index < characters.length)
				{
					var width = g2.font.widthOfCharacters(g2.fontSize, characters, lastBreak, index - lastBreak);
					if (width >= destination.width)
					{
						if (lastChance < 0)
						{
							lastChance = index - 1;
						}
						currentBreaks.push(lastChance + 1);
						lastBreak = lastChance + 1;
						index = lastBreak;
						lastChance = -1;
					}

					if (characters[index] == " ".charCodeAt(0))
					{
						lastChance = index;
					}
					else if (characters[index] == "\n".charCodeAt(0) || characters[index] == "\r".charCodeAt(0))
					{
						currentBreaks.push(index + 1);
						lastBreak = index + 1;
						lastChance = -1;
					}

					index += 1;
				}

				_forceMultilineUpdate = false;
			}

			var currentY = 0.0;

			if (currentBreaks.length > 0)
			{
				var lastBreak = 0;

				for (i in 0...currentBreaks.length)
				{
					var lineBreak = currentBreaks[i];
					g2.drawCharacters(characters, lastBreak, lineBreak - lastBreak, destination.x, destination.y + currentY);

					lastBreak = lineBreak;
					currentY += g2.font.height(g2.fontSize) + 1;
				}

				lastBreak = currentBreaks[currentBreaks.length - 1];
				g2.drawCharacters(characters, lastBreak, characters.length - lastBreak, destination.x, destination.y + currentY);
			}
			else
			{
				g2.drawCharacters(characters, 0, characters.length, destination.x, destination.y);
				currentY += g2.font.height(g2.fontSize) + 1;
			}
			
			if (clipping)
				g2.disableScissor();

			return currentBreaks;
		}
	}

	public static function drawVideoDim(g2:Graphics, video:Video, destination:Dim)
	{
		g2.drawVideo(video, destination.x, destination.y, destination.width, destination.height);
	}

	// Complete this function
	// Probably should be refactored
	public static function fillTriangle(g2:Graphics, destination:Dim, direction:Int)
	{
		var anchorX = 0.0;
		var anchorY = 0.0;
		if ((direction & TRIANGLE_UP) != 0)
		{
			if ((direction & TRIANGLE_LEFT) != 0)
			{
				anchorX = destination.x;
				anchorY = destination.y;
			}
			else if ((direction & TRIANGLE_RIGHT) != 0)
			{
				anchorX = destination.x + destination.width;
				anchorY = destination.y;
			}
			else
			{
				anchorX = destination.x + (destination.width / 2);
				anchorY = destination.y;
			}
		}
		else if ((direction & TRIANGLE_DOWN) != 0)
		{
			if ((direction & TRIANGLE_LEFT) != 0)
			{
				anchorX = destination.x;
				anchorY = destination.y + destination.height;
			}
			else if ((direction & TRIANGLE_RIGHT) != 0)
			{
				anchorX = destination.x + destination.width;
				anchorY = destination.y + destination.height;
			}
			else
			{
				anchorX = destination.x + (destination.width / 2);
				anchorY = destination.y + destination.height;
			}
		}
		else if ((direction & TRIANGLE_LEFT) != 0)
		{
			anchorX = destination.x;
			anchorY = destination.y + (destination.height / 2);
		}
		else if ((direction & TRIANGLE_RIGHT) != 0)
		{
			anchorX = destination.x + destination.width;
			anchorY = destination.y + (destination.height / 2);
		}

		var x2 = 0.0;
		var y2 = 0.0;
		var x3 = 0.0;
		var y3 = 0.0;

	}

	public static function scissorDim(g2:Graphics, dim:Dim)
	{
		g2.scissor(cast dim.x, cast dim.y, cast dim.width, cast dim.height);
	}

}