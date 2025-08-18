package twinspire.extensions;

import twinspire.utils.ExtraMath;

import twinspire.render.Sprite;
import twinspire.geom.Dim;
import twinspire.render.Patch;

import kha.math.FastVector2;
import kha.math.Vector2;
import kha.graphics2.Graphics;
import kha.Image;
import kha.Video;
import kha.Color;

enum abstract TriangleDirection(Int) from Int to Int
{
	var TRIANGLE_LEFT			=	0x01;
	var TRIANGLE_RIGHT			=	0x02;
	var TRIANGLE_UP				=	0x04;
	var TRIANGLE_DOWN			=	0x08;
}

enum abstract BorderFlags(Int) from Int to Int
{
	var BORDER_NONE				=	0;
	var BORDER_TOP				=	0x01;
	var BORDER_LEFT				=	0x02;
	var BORDER_RIGHT			=	0x04;
	var BORDER_BOTTOM			=	0x08;
	var BORDER_ALL				=	0x0F;
}

enum PolarEdgeEffect {
    /**
    * Clamp values at the edge
    **/
    Clamp;
    /**
    * Wrap values around at the edge
    **/
    Wrap;
    /**
    * Mirror values at the edge
    **/
    Mirror;
}

class Graphics2
{

	private static var _forceMultilineUpdate:Bool;
	private static var _useCrlf:Bool;

	public static function drawImageDim(g2:Graphics, img:Image, dim:Dim) {
		if (dim == null || img == null) {
            return;
        }

        g2.drawImage(img, dim.x, dim.y);
	}

	public static function drawSubImageDim(g2:Graphics, img:Image, source:Dim, destination:Dim) {
		if (destination == null || img == null || source == null) {
            return;
        }

        g2.drawSubImage(img, source.x, source.y, source.width, source.height, destination.x, destination.y);
	}

	public static function drawScaledImageDim(g2:Graphics, img:Image, destination:Dim) {
		if (destination == null || img == null) {
            return;
        }

        g2.drawScaledImage(img, destination.x, destination.y, destination.width, destination.height);
	}

	public static function drawScaledSubImageDim(g2:Graphics, img:Image, source:Dim, destination:Dim) {
		if (destination == null || img == null || source == null) {
            return;
        }

        g2.drawScaledSubImage(img, source.x, source.y, source.width, source.height,
                             destination.x, destination.y, destination.width, destination.height);
	}

	public static function drawPatchedImage(g2:Graphics, img:Image, patch:Patch, destination:Dim) {
		if (destination == null || img == null || patch == null) {
			return;
		}

		var segments = patch.getSegments();
		if (segments.length != 9) {
			drawScaledSubImageDim(g2, img, patch.source, destination);
			return;
		}

		var tl = new Dim(destination.x, destination.y, segments[TopLeft].width, segments[TopLeft].height);
		var tr = new Dim(destination.width - segments[TopRight].width + destination.x, destination.y, segments[TopRight].width, segments[TopRight].height);
		var tm = new Dim(destination.x + segments[TopLeft].width, destination.y, destination.width - tl.width - tr.width, tl.height);
		var bl = new Dim(destination.x, destination.height - segments[BottomLeft].height + destination.y, segments[BottomLeft].width, segments[BottomLeft].height);
		var br = new Dim(destination.width - segments[BottomRight].width + destination.x, destination.height - segments[BottomRight].height + destination.y, segments[BottomRight].width, segments[BottomRight].height);
		var bm = new Dim(destination.x + bl.width, bl.y, destination.width - bl.width - br.width, bl.height);
		var cl = new Dim(destination.x, destination.y + tl.height, segments[CentreLeft].width, destination.height - tl.height - bl.height);
		var cr = new Dim(destination.width - segments[CentreRight].width + destination.x, destination.y + tr.height, segments[CentreRight].width, destination.height - tr.height - br.height);
		var cm = new Dim(destination.x + tl.width, destination.y + tl.height, destination.width - tl.width - tr.width, destination.height - tm.height - bm.height);

		drawSubImageDim(g2, img, segments[TopLeft], tl);
		
		if (patch.repeatMethods[PatchMethodIndex.Top] == PatchStretch) {
			drawScaledSubImageDim(g2, img, segments[TopMiddle], tm);
		}
		else {
			drawImageRepeat(g2, img, segments[TopMiddle], tm, 2);
		}

		drawSubImageDim(g2, img, segments[TopRight], tr);

		if (patch.repeatMethods[PatchMethodIndex.Left] == PatchStretch) {
			drawScaledSubImageDim(g2, img, segments[CentreLeft], cl);
		}
		else {
			drawImageRepeat(g2, img, segments[CentreLeft], cl, 1);
		}

		if (patch.repeatMethods[PatchMethodIndex.Centre] == PatchStretch) {
			drawScaledSubImageDim(g2, img, segments[CentreMiddle], cm);
		}
		else {
			drawImageRepeat(g2, img, segments[CentreMiddle], cm, 0);
		}
		
		if (patch.repeatMethods[PatchMethodIndex.Right] == PatchStretch) {
			drawScaledSubImageDim(g2, img, segments[CentreRight], cr);
		}
		else {
			drawImageRepeat(g2, img, segments[CentreRight], cr, 1);
		}
		
		drawSubImageDim(g2, img, segments[BottomLeft], bl);

		if (patch.repeatMethods[PatchMethodIndex.Bottom] == PatchStretch) {
			drawScaledSubImageDim(g2, img, segments[BottomMiddle], bm);
		}
		else {
			drawImageRepeat(g2, img, segments[BottomMiddle], bm, 2);
		}
		
		drawSubImageDim(g2, img, segments[BottomRight], br);
	}

	/**
	* axis: 0 = both; 1 = vertical, 2 = horizontal
	**/
	public static function drawImageRepeat(g2:Graphics, img:Image, source:Dim, destination:Dim, axis:Int = 0) {
		if (destination == null || img == null || source == null) {
			return;
		}

		var yRepeat = 0.0;
		var xRepeat = 0.0;
		var yRemainder = 0.0;
		var xRemainder = 0.0;

		if (destination.width < source.width && axis != 1) {
			xRemainder = destination.width - source.width;
		}
		else if (axis != 1) {
			xRepeat = Math.floor(destination.width / source.width);
			xRemainder = Math.ceil(destination.width % source.width);
		}

		if (destination.height < source.height && axis != 2) {
			yRemainder = destination.height - source.height;
		}
		else if (axis != 2) {
			yRepeat = Math.floor(destination.height / source.height);
			yRemainder = Math.ceil(destination.height % source.height);
		}

		if (xRepeat > 0.0 && yRepeat > 0.0) {
			// use a for loop as a grid for each row/column
			var castedX = cast(xRepeat, Int);
			var castedY = cast(yRepeat, Int);
			for (y in 0...castedY) {
				for (x in 0...castedX) {
					var targetDim = new Dim(destination.x + (x * source.width), destination.y + (y * source.height), source.width, source.height);
					drawSubImageDim(g2, img, source, targetDim);

					if (x == castedX - 1) {
						// last x in loop, draw remainder
						if (xRemainder > 0.0) {
							var clippedSource = new Dim(source.x, source.y, xRemainder, source.height);
							var targetDim = new Dim(destination.x + (xRepeat * source.width), destination.y + (y * source.height), xRemainder, source.height);
							drawSubImageDim(g2, img, clippedSource, targetDim);
						}
					}

					if (y == castedY - 1) {
						// last y in loop, draw remainder
						if (yRemainder > 0.0) {
							var clippedSource = new Dim(source.x, source.y, source.width, yRemainder);
							var targetDim = new Dim(destination.x + (x * source.width), destination.y + (yRepeat * source.height), source.width, yRemainder);
							drawSubImageDim(g2, img, clippedSource, targetDim);
						}
					}
				}
			}

			if (xRemainder > 0.0 && yRemainder > 0.0) {
				var clippedSource = new Dim(source.x, source.y, xRemainder, yRemainder);
				var targetDim = new Dim(destination.x + (xRepeat * source.width), destination.y + (yRepeat * source.height), xRemainder, yRemainder);
				drawSubImageDim(g2, img, clippedSource, targetDim);
			}

			return;
		}
		
		if (axis == 2 || axis == 0) {
			var x = xRepeat;
			var offset = 0.0;
			while (x > 0) {
				var targetDim = new Dim(destination.x + offset, destination.y, source.width, source.height);
				drawSubImageDim(g2, img, source, targetDim);
				offset += source.width;
				x -= 1;
			}

			if (xRemainder > 0) {
				var clippedSource = new Dim(source.x, source.y, xRemainder, source.height);
				var targetDim = new Dim(destination.x + offset, destination.y, xRemainder, source.height);
				drawSubImageDim(g2, img, clippedSource, targetDim);
			}
		}

		if (axis == 1 || axis == 0) {
			var y = yRepeat;
			var offset = 0.0;
			while (y > 0) {
				var targetDim = new Dim(destination.x, destination.y + offset, source.width, source.height);
				drawSubImageDim(g2, img, source, targetDim);
				offset += source.height;
				y -= 1;
			}

			if (yRemainder > 0) {
				var clippedSource = new Dim(source.x, source.y, source.width, yRemainder);
				var targetDim = new Dim(destination.x, destination.y + offset, source.width, yRemainder);
				drawSubImageDim(g2, img, clippedSource, targetDim);
			}
		}
	}

	public static function drawRectDim(g2:Graphics, destination:Dim, lineThickness:Float = 1.0) {
		if (destination == null) {
            return;
        }
        
        g2.drawRect(destination.x, destination.y, destination.width, destination.height, lineThickness);
	}

	public static function drawBorders(g2:Graphics, destination:Dim, lineThickness:Float = 1.0, borders:Int = BORDER_ALL) {
		if (destination == null) {
			return;
		}

		if ((borders & BORDER_TOP) != 0)
		{
			g2.drawLine(destination.x + lineThickness / 2, destination.y + lineThickness / 2, 
				destination.x + destination.width - lineThickness / 2, destination.y + lineThickness / 2, lineThickness);
		}

		if ((borders & BORDER_LEFT) != 0)
		{
			g2.drawLine(destination.x + lineThickness / 2, destination.y + lineThickness / 2, 
				destination.x + lineThickness / 2, destination.y + destination.height - lineThickness / 2, lineThickness);
		}

		if ((borders & BORDER_RIGHT) != 0)
		{
			g2.drawLine(destination.x + destination.width - lineThickness / 2, destination.y + lineThickness / 2, 
				destination.x + destination.width - lineThickness / 2, destination.y + destination.height - lineThickness / 2, lineThickness);
		}

		if ((borders & BORDER_BOTTOM) != 0)
		{
			g2.drawLine(destination.x + lineThickness / 2, destination.y + destination.height - lineThickness / 2,
				destination.x + destination.width - lineThickness / 2, destination.y + destination.height - lineThickness / 2, lineThickness);
		}
	}

	public static function fillRectDim(g2:Graphics, destination:Dim) {
		if (destination == null) {
            return;
        }

        g2.fillRect(destination.x, destination.y, destination.width, destination.height);
	}

	public static function drawStringDim(g2:Graphics, text:String, destination:Dim) {
		if (destination == null || text == null) {
            return;
        }

        g2.drawString(text, destination.x, destination.y);
	}

	public static function forceMultilineUpdate() {
		_forceMultilineUpdate = true;
	}

	public static function disableMultilineUpdate() {
		_forceMultilineUpdate = false;
	}

	public static function useCRLF(crlf:Bool) {
		_useCrlf = crlf;
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
	public static function drawCharactersDim(g2:Graphics, characters:Array<Int>, start:Int, length:Int, destination:Dim, autoWrap:Bool = false, clipping:Bool = false, breaks:Array<Int> = null):Array<Int> {
		if (destination == null || characters == null || characters.length == 0) {
			return null;
		}

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
						if (_useCrlf && characters[index] == "\n".charCodeAt(0))
						{
							index += 1;
							continue;
						}

						currentBreaks.push(index + 1);
						lastBreak = index + 1;
						lastChance = -1;
					}

					index += 1;
				}
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

	public static function drawVideoDim(g2:Graphics, video:Video, destination:Dim) {
		if (destination == null || video == null) {
			return;
		}

		g2.drawVideo(video, destination.x, destination.y, destination.width, destination.height);
	}

	public static function drawCircleDim(g2:Graphics, destination:Dim, strength:Float = 1.0) {
        if (destination == null) {
            return;
        }

        var cx = destination.x + (destination.width / 2);
        var cy = destination.y + (destination.height / 2);
        var radius = destination.width / 2;
        
        drawCircle(g2, cx, cy, radius, strength);
    }

	public static function fillCircleDim(g2:Graphics, destination:Dim) {
		if (destination == null) {
            return;
        }

        fillCircle(g2, cx, cy, radius);
	}

	public static function fillTriangleDim(g2:Graphics, destination:Dim, direction:Int) {
		if (destination == null) {
			return;
		}

		var x1 = 0.0, x2 = 0.0, x3 = 0.0, y1 = 0.0, y2 = 0.0, y3 = 0.0;

		if ((direction & TRIANGLE_UP) != 0) {
			if ((direction & TRIANGLE_LEFT) != 0) {
				x1 = destination.x;
				y1 = destination.y;
				x2 = destination.x + (destination.width * .75);
				y2 = destination.y;
				x3 = destination.x;
				y3 = destination.y + (destination.height * .75);
			}
			else if ((direction & TRIANGLE_RIGHT) != 0) {
				x1 = destination.x + (destination.width * .25);
				y1 = destination.y;
				x2 = destination.x + destination.width;
				y2 = destination.y + (destination.height * .75);
				x3 = destination.x + destination.width;
				y3 = destination.y;
			}
			else {
				x1 = destination.x + (destination.width * .5);
				y1 = destination.y;
				x2 = destination.x;
				y2 = destination.y + (destination.height * .75);
				x3 = destination.x + destination.width;
				y3 = destination.y + (destination.height * .75);
			}
		}
		else if ((direction & TRIANGLE_DOWN) != 0) {
			if ((direction & TRIANGLE_LEFT) != 0) {
				x1 = destination.x;
				y1 = destination.y + (destination.height * .25);
				x2 = destination.x;
				y2 = destination.y + destination.height;
				x3 = destination.x + (destination.width * .75);
				x3 = destination.y + destination.height;
			}
			else if ((direction & TRIANGLE_RIGHT) != 0) {
				x1 = destination.x + destination.width;
				y1 = destination.y + (destination.height * .25);
				x2 = destination.x + (destination.width * .25);
				y2 = destination.y + destination.height;
				x3 = destination.x + destination.width;
				y3 = destination.y + destination.height;
			}
			else {
				x1 = destination.x;
				y1 = destination.y + (destination.height * .25);
				x2 = destination.x + (destination.width * .5);
				y2 = destination.y + destination.height;
				x3 = destination.x + destination.width;
				y3 = destination.y + (destination.height * .25);
			}
		}
		else if ((direction & TRIANGLE_LEFT) != 0) {
			x1 = destination.x;
			y1 = destination.y + (destination.height * .5);
			x2 = destination.x + (destination.width * .75);
			y2 = destination.y + destination.height;
			x3 = destination.x + (destination.width * .75);
			y3 = destination.y;
		}
		else if ((direction & TRIANGLE_RIGHT) != 0) {
			x1 = destination.x + (destination.width * .25);
			y1 = destination.y;
			x2 = destination.x + (destination.width * .25);
			y2 = destination.y + destination.height;
			x3 = destination.x + destination.width;
			y3 = destination.y + (destination.height * .5);
		}

		g2.fillTriangle(x1, y1, x2, y2, x3, y3);
	}

	public function drawRoundedRect(g2:Graphics, x:Float, y:Float, width:Float, height:Float, radius:Float, strength:Float = 1.0) {
        var dim = new Dim(x, y, width, height);
        drawRoundedRectDim(g2, dim, radius, strength);
    }

    public function fillRoundedRect(g2:Graphics, x:Float, y:Float, width:Float, height:Float, radius:Float) {
        var dim = new Dim(x, y, width, height);
        fillRoundedRectDim(g2, dim, radius);
    }

	public function drawRoundedRectDim(g2:Graphics, destination:Dim, radius:Float, strength:Float = 1.0) {
		if (destination == null) {
            return;
        }

        drawPixelRoundedRect(g2, destination.x, destination.y, destination.width, destination.height, radius, strength, false);
	}

	public function fillRoundedRectDim(g2:Graphics, destination:Dim, radius:Float, strength:Float = 1.0) {
		if (destination == null) {
            return;
        }

    	drawPixelRoundedRect(g2, destination.x, destination.y, destination.width, destination.height, radius, 0, true);
	}

	public function drawRoundedRectCornersDim(g2:Graphics, destination:Dim, topLeft:Float, topRight:Float, bottomRight:Float, bottomLeft:Float, strength:Float = 1.0) {
		if (destination == null) {
			return;
		}

		drawPixelRoundedRectCorners(g2, destination.x, destination.y, destination.width, destination.height, topLeft, topRight, bottomRight, bottomLeft, strength, false);
	}

	public function fillRoundedRectCornersDim(g2:Graphics, destination:Dim, topLeft:Float, topRight:Float, bottomRight:Float, bottomLeft:Float, strength:Float = 1.0) {
		if (destination == null) {
			return;
		}

		drawPixelRoundedRectCorners(g2, destination.x, destination.y, destination.width, destination.height, topLeft, topRight, bottomRight, bottomLeft, strength, true);
	}
    
	private static function drawPixelRoundedRect(g2:Graphics, x:Float, y:Float, width:Float, height:Float, radius:Float, strength:Float, filled:Bool) {
        var maxRadius = Math.min(width, height) * 0.5;
        radius = Math.min(radius, maxRadius);
        
        if (filled) {
            fillPixelRoundedRectParts(g2, x, y, width, height, radius);
        } else {
            drawPixelRoundedRectOutline(g2, x, y, width, height, radius, strength);
        }
    }
    
    private static function drawPixelRoundedRectCorners(g2:Graphics, x:Float, y:Float, width:Float, height:Float, 
                                               topLeft:Float, topRight:Float, bottomRight:Float, bottomLeft:Float, 
                                               strength:Float, filled:Bool) {
        var maxRadius = Math.min(width, height) * 0.5;
        topLeft = Math.min(topLeft, maxRadius);
        topRight = Math.min(topRight, maxRadius);
        bottomRight = Math.min(bottomRight, maxRadius);
        bottomLeft = Math.min(bottomLeft, maxRadius);
        
        if (filled) {
            fillPixelRoundedRectWithCorners(g2, x, y, width, height, topLeft, topRight, bottomRight, bottomLeft);
        } else {
            drawPixelRoundedRectOutlineWithCorners(g2, x, y, width, height, topLeft, topRight, bottomRight, bottomLeft, strength);
        }
    }
    
    private static function fillPixelRoundedRectParts(g2:Graphics, x:Float, y:Float, width:Float, height:Float, radius:Float) {
        // Fill the main rectangles
        g2.fillRect(x + radius, y, width - radius * 2, height); // Center
        g2.fillRect(x, y + radius, radius, height - radius * 2); // Left
        g2.fillRect(x + width - radius, y + radius, radius, height - radius * 2); // Right
        
        // Fill corner circles
        fillQuarterCircle(g2, x + radius, y + radius, radius, 2); // Top-left
        fillQuarterCircle(g2, x + width - radius, y + radius, radius, 3); // Top-right
        fillQuarterCircle(g2, x + width - radius, y + height - radius, radius, 0); // Bottom-right
        fillQuarterCircle(g2, x + radius, y + height - radius, radius, 1); // Bottom-left
    }
    
    private static function fillPixelRoundedRectWithCorners(g2:Graphics, x:Float, y:Float, width:Float, height:Float, 
                                                   topLeft:Float, topRight:Float, bottomRight:Float, bottomLeft:Float) {
        // Calculate the main rectangle area
        var mainY = y + Math.max(topLeft, topRight);
        var mainHeight = height - Math.max(topLeft, topRight) - Math.max(bottomLeft, bottomRight);
        var mainX = x + Math.max(topLeft, bottomLeft);
        var mainWidth = width - Math.max(topLeft, bottomLeft) - Math.max(topRight, bottomRight);
        
        // Fill main center rectangle
        if (mainWidth > 0 && mainHeight > 0) {
            g2.fillRect(mainX, mainY, mainWidth, mainHeight);
        }
        
        // Fill top rectangle
        var topY = y + Math.max(topLeft, topRight);
        var topX = x + topLeft;
        var topWidth = width - topLeft - topRight;
        if (topWidth > 0 && topY > y) {
            g2.fillRect(topX, y, topWidth, topY - y);
        }
        
        // Fill bottom rectangle
        var bottomY = y + height - Math.max(bottomLeft, bottomRight);
        var bottomX = x + bottomLeft;
        var bottomWidth = width - bottomLeft - bottomRight;
        if (bottomWidth > 0 && bottomY < y + height) {
            g2.fillRect(bottomX, bottomY, bottomWidth, (y + height) - bottomY);
        }
        
        // Fill left rectangle
        var leftX = x + Math.max(topLeft, bottomLeft);
        var leftY = y + topLeft;
        var leftHeight = height - topLeft - bottomLeft;
        if (leftX > x && leftHeight > 0) {
            g2.fillRect(x, leftY, leftX - x, leftHeight);
        }
        
        // Fill right rectangle
        var rightX = x + width - Math.max(topRight, bottomRight);
        var rightY = y + topRight;
        var rightHeight = height - topRight - bottomRight;
        if (rightX < x + width && rightHeight > 0) {
            g2.fillRect(rightX, rightY, (x + width) - rightX, rightHeight);
        }
        
        // Fill corner circles
        if (topLeft > 0) fillQuarterCircle(g2, x + topLeft, y + topLeft, topLeft, 2);
        if (topRight > 0) fillQuarterCircle(g2, x + width - topRight, y + topRight, topRight, 3);
        if (bottomRight > 0) fillQuarterCircle(g2, x + width - bottomRight, y + height - bottomRight, bottomRight, 0);
        if (bottomLeft > 0) fillQuarterCircle(g2, x + bottomLeft, y + height - bottomLeft, bottomLeft, 1);
    }
    
    private static function drawPixelRoundedRectOutline(g2:Graphics, x:Float, y:Float, width:Float, height:Float, radius:Float, strength:Float) {
        // Draw straight lines
        g2.drawLine(x + radius, y, x + width - radius, y, strength); // Top
        g2.drawLine(x + width, y + radius, x + width, y + height - radius, strength); // Right
        g2.drawLine(x + width - radius, y + height, x + radius, y + height, strength); // Bottom
        g2.drawLine(x, y + height - radius, x, y + radius, strength); // Left
        
        // Draw corner arcs
        drawQuarterCircle(g2, x + radius, y + radius, radius, 2, strength); // Top-left
        drawQuarterCircle(g2, x + width - radius, y + radius, radius, 3, strength); // Top-right
        drawQuarterCircle(g2, x + width - radius, y + height - radius, radius, 0, strength); // Bottom-right
        drawQuarterCircle(g2, x + radius, y + height - radius, radius, 1, strength); // Bottom-left
    }
    
    private static function drawPixelRoundedRectOutlineWithCorners(g2:Graphics, x:Float, y:Float, width:Float, height:Float, 
                                                          topLeft:Float, topRight:Float, bottomRight:Float, bottomLeft:Float, 
                                                          strength:Float) {
        // Draw straight lines
        g2.drawLine(x + topLeft, y, x + width - topRight, y, strength); // Top
        g2.drawLine(x + width, y + topRight, x + width, y + height - bottomRight, strength); // Right
        g2.drawLine(x + width - bottomRight, y + height, x + bottomLeft, y + height, strength); // Bottom
        g2.drawLine(x, y + height - bottomLeft, x, y + topLeft, strength); // Left
        
        // Draw corner arcs
        if (topLeft > 0) drawQuarterCircle(g2, x + topLeft, y + topLeft, topLeft, 2, strength);
        if (topRight > 0) drawQuarterCircle(g2, x + width - topRight, y + topRight, topRight, 3, strength);
        if (bottomRight > 0) drawQuarterCircle(g2, x + width - bottomRight, y + height - bottomRight, bottomRight, 0, strength);
        if (bottomLeft > 0) drawQuarterCircle(g2, x + bottomLeft, y + height - bottomLeft, bottomLeft, 1, strength);
    }



	public static function scissorDim(g2:Graphics, dim:Dim) {
		if (dim == null) {
			return;
		}

		g2.scissor(cast dim.x, cast dim.y, cast dim.width, cast dim.height);
	}

	static function getAnimateSpriteFrameIndex(sprite:Sprite, ?stateIndex:Int, ?group:String) {
		if (sprite == null || sprite.states == null || sprite.states.length == 0) {
			return -1;
		}

		var state = sprite.currentFrame;
		if (stateIndex != null) {
			state = stateIndex;
		}

		if (sprite.states.length == 0) {
			return -1;
		}

		var indexRange = [];
		var spriteState = sprite.states[state];
		var animationLoop = sprite.animationLoop;

		if (group != null) {
			if (!spriteState.groups.exists(group)) {
				return -1;
			}

			indexRange = spriteState.groups.get(group);
			if (spriteState.animationLoop.exists(group)) {
				animationLoop = spriteState.animationLoop[group];
			}
		}
		else {
			indexRange = [ for (i in 0...spriteState.patches.length) i ];
		}

		var frameComplete = Animate.animateTickLoop(sprite.animIndex, sprite.duration);

		switch (animationLoop) {
			case None: {
				if (frameComplete) {
					if (sprite.currentFrame < indexRange.length - 1) {
						sprite.currentFrame += 1;
					}
				}
			}
			case Repeat: {
				if (frameComplete) {
					if (sprite.currentFrame < indexRange.length - 1) {
						sprite.currentFrame += 1;
					}
					else {
						sprite.currentFrame = 0;
					}
				}
			}
			case RepeatInverse: {
				if (frameComplete) {
					sprite.currentFrame += sprite.animDir;
					var isEnd = sprite.animDir == 1 ? sprite.currentFrame == indexRange.length - 1 : sprite.currentFrame == 0;
					if (isEnd) {
						sprite.animDir = -sprite.animDir;
					}
				}
			}
		}

		return sprite.currentFrame;
	}

	public static function drawSprite(g2:Graphics, sprite:Sprite, index:Int, dim:Dim) {
		if (sprite == null || sprite.states == null || sprite.states.length == 0 || index < 0 || index >= sprite.states.length) {
			return;
		}

		var state = sprite.states[index];
		if (state.patches.length == 0) {
			drawScaledImageDim(g2, state.image, dim);
		}
		else {
			var animStateIndex = 0;
			if (sprite.animated) {
				var temp = getAnimateSpriteFrameIndex(sprite, index);
				animStateIndex = temp > -1 ? temp : 0;
			}

			var dest = dim;
			if (sprite.size.x > 0 && sprite.size.y > 0) {
				var destination = state.getDestinationDims()[animStateIndex];
				dest = new Dim(dim.x + destination.x, dim.y + destination.y, sprite.size.x, sprite.size.y);
			}

			drawPatchedImage(g2, state.image, state.patches[animStateIndex], dim);
		}
	}

	public static function drawSpritePatch(g2:Graphics, sprite:Sprite, stateIndex:Int, patchIndex:Int, dim:Dim) {
		if (sprite == null || sprite.states == null || sprite.states.length == 0 || stateIndex < 0 || stateIndex >= sprite.states.length) {
			return;
		}

		var state = sprite.states[stateIndex];
		drawPatchedImage(g2, state.image, state.patches[patchIndex], dim);
	}

	public static function drawSpriteGroup(g2:Graphics, sprite:Sprite, index:Int, group:String, dim:Dim) {
		if (sprite == null || sprite.states == null || sprite.states.length == 0 || index < 0 || index >= sprite.states.length) {
			return;
		}
		
		var state = sprite.states[index];
		if (state.groups.exists(group)) {
			var animateIndex = 0;
			if (sprite.animated) {
				var temp = getAnimateSpriteFrameIndex(sprite, index, group);
				animateIndex = temp > -1 ? temp : 0;
			}

			var groupIndices = state.groups.get(group);
			var dest = dim;
			if (sprite.size.x > 0 && sprite.size.y > 0) {
				var destination = state.getDestinationDims()[animateIndex];
				dest = new Dim(dim.x + destination.x, dim.y + destination.y, sprite.size.x, sprite.size.y);
			}

			drawPatchedImage(g2, state.image, state.patches[groupIndices[animateIndex]], dest);
		}
	}

	public function generateVerticalGradient(width:Int, height:Int, colors:Array<Color>, stops:Array<Float>, inverse:Bool):Image {
		var image = Image.create(width, height);
		var pixels = image.lock();
		var bytesPerPixel = 4; // RGBA
		
		for (y in 0...height) {
			var progress = y / (height - 1);
			
			if (inverse) {
				// Mirror gradient from center outward
				var center = 0.5;
				progress = Math.abs(progress - center) * 2;
				progress = Math.min(progress, 1.0);
			}
			
			var color = interpolateColorFromStops(colors, stops, progress);
			
			for (x in 0...width) {
				var pixelIndex = (y * width + x) * bytesPerPixel;
				pixels.set(pixelIndex, Math.round(color.Rb));     // Red
				pixels.set(pixelIndex + 1, Math.round(color.Gb)); // Green
				pixels.set(pixelIndex + 2, Math.round(color.Bb)); // Blue
				pixels.set(pixelIndex + 3, Math.round(color.A * 255)); // Alpha
			}
		}
		
		image.unlock();
		return image;
	}

	public function generateHorizontalGradient(width:Int, height:Int, colors:Array<Color>, stops:Array<Float>, inverse:Bool):Image {
		var image = Image.create(width, height);
		var pixels = image.lock();
		var bytesPerPixel = 4; // RGBA
		
		for (x in 0...width) {
			var progress = x / (width - 1);
			
			if (inverse) {
				// Mirror gradient from center outward
				var center = 0.5;
				progress = Math.abs(progress - center) * 2;
				progress = Math.min(progress, 1.0);
			}
			
			var color = interpolateColorFromStops(colors, stops, progress);
			
			for (y in 0...height) {
				var pixelIndex = (y * width + x) * bytesPerPixel;
				pixels.set(pixelIndex, Math.round(color.Rb));     // Red
				pixels.set(pixelIndex + 1, Math.round(color.Gb)); // Green
				pixels.set(pixelIndex + 2, Math.round(color.Bb)); // Blue
				pixels.set(pixelIndex + 3, Math.round(color.A * 255)); // Alpha
			}
		}
		
		image.unlock();
		return image;
	}

	public function generateCircularGradient(width:Int, height:Int, colors:Array<Color>, stops:Array<Float>):Image {
		var image = Image.create(width, height);
		var pixels = image.lock();
		var bytesPerPixel = 4; // RGBA
		
		var centerX = width / 2;
		var centerY = height / 2;
		var maxRadius = Math.sqrt(centerX * centerX + centerY * centerY);
		
		for (y in 0...height) {
			for (x in 0...width) {
				var dx = x - centerX;
				var dy = y - centerY;
				var distance = Math.sqrt(dx * dx + dy * dy);
				var progress = Math.min(distance / maxRadius, 1.0);
				
				var color = interpolateColorFromStops(colors, stops, progress);
				var pixelIndex = (y * width + x) * bytesPerPixel;
				pixels.set(pixelIndex, Math.round(color.Rb));     // Red
				pixels.set(pixelIndex + 1, Math.round(color.Gb)); // Green
				pixels.set(pixelIndex + 2, Math.round(color.Bb)); // Blue
				pixels.set(pixelIndex + 3, Math.round(color.A * 255)); // Alpha
			}
		}
		
		image.unlock();
		return image;
	}

	public function generateConalGradient(width:Int, height:Int, colors:Array<Color>, stops:Array<Float>, clockwise:Bool):Image {
		var image = Image.create(width, height);
		var pixels = image.lock();
		var bytesPerPixel = 4; // RGBA
		
		var centerX = width / 2;
		var centerY = height / 2;
		
		for (y in 0...height) {
			for (x in 0...width) {
				var dx = x - centerX;
				var dy = y - centerY;
				
				// Calculate angle from center
				var angle = Math.atan2(dy, dx);
				
				// Convert to 0-1 range
				var progress = (angle + Math.PI) / (2 * Math.PI);
				
				if (!clockwise) {
					progress = 1.0 - progress;
				}
				
				// Ensure progress is in [0, 1] range
				progress = progress - Math.floor(progress);
				
				var color = interpolateColorFromStops(colors, stops, progress);
				var pixelIndex = (y * width + x) * bytesPerPixel;
				pixels.set(pixelIndex, Math.round(color.Rb));     // Red
				pixels.set(pixelIndex + 1, Math.round(color.Gb)); // Green
				pixels.set(pixelIndex + 2, Math.round(color.Bb)); // Blue
				pixels.set(pixelIndex + 3, Math.round(color.A * 255)); // Alpha
			}
		}
		
		image.unlock();
		return image;
	}

	public function generatePolarGradient(width:Int, height:Int, colors:Array<Color>, stops:Array<Float>, 
                                     scale:Float, offset:FastVector2, edge:PolarEdgeEffect):Image {
		var image = Image.create(width, height);
		var pixels = image.lock();
		var bytesPerPixel = 4; // RGBA
		
		var centerX = width / 2 + offset.x;
		var centerY = height / 2 + offset.y;
		
		for (y in 0...height) {
			for (x in 0...width) {
				var dx = (x - centerX) / scale;
				var dy = (y - centerY) / scale;
				
				// Convert to polar coordinates
				var radius = Math.sqrt(dx * dx + dy * dy);
				var angle = Math.atan2(dy, dx);
				
				// Apply polar inversion effect
				// This creates a complex distortion based on polar coordinates
				var u = radius * Math.cos(angle * 2) + radius * 0.5;
				var v = radius * Math.sin(angle * 2) + radius * 0.5;
				
				// Combine u and v to create a progress value
				var progress = Math.sqrt(u * u + v * v) * 0.5;
				
				// Apply edge effects
				switch (edge) {
					case Clamp: {
						progress = Math.max(0, Math.min(1, progress));
					}
					case Wrap: {
						progress = progress - Math.floor(progress);
						if (progress < 0) progress += 1;
					}
					case Mirror: {
						progress = Math.abs(progress);
						var intPart = Math.floor(progress);
						var fracPart = progress - intPart;
						if (Math.floor(intPart) % 2 == 1) {
							progress = 1 - fracPart;
						} else {
							progress = fracPart;
						}
					}
				}
				
				var color = interpolateColorFromStops(colors, stops, progress);
				var pixelIndex = (y * width + x) * bytesPerPixel;
				pixels.set(pixelIndex, Math.round(color.Rb));     // Red
				pixels.set(pixelIndex + 1, Math.round(color.Gb)); // Green
				pixels.set(pixelIndex + 2, Math.round(color.Bb)); // Blue
				pixels.set(pixelIndex + 3, Math.round(color.A * 255)); // Alpha
			}
		}
		
		image.unlock();
		return image;
	}

	private function interpolateColorFromStops(colors:Array<Color>, stops:Array<Float>, progress:Float):Color {
		// Clamp progress to [0, 1]
		progress = Math.max(0, Math.min(1, progress));
		
		// Find the two stops that bracket our progress
		var lowerIndex = 0;
		var upperIndex = colors.length - 1;
		
		for (i in 0...stops.length - 1) {
			if (progress >= stops[i] && progress <= stops[i + 1]) {
				lowerIndex = i;
				upperIndex = i + 1;
				break;
			}
		}
		
		// Handle edge cases
		if (progress <= stops[0]) {
			return colors[0];
		}
		if (progress >= stops[stops.length - 1]) {
			return colors[colors.length - 1];
		}
		
		// Calculate interpolation ratio between the two stops
		var lowerStop = stops[lowerIndex];
		var upperStop = stops[upperIndex];
		var localProgress = (progress - lowerStop) / (upperStop - lowerStop);
		
		// Interpolate between the two colors
		var lowerColor = colors[lowerIndex];
		var upperColor = colors[upperIndex];
		
		var r = Math.round((1 - localProgress) * lowerColor.Rb + localProgress * upperColor.Rb);
		var g = Math.round((1 - localProgress) * lowerColor.Gb + localProgress * upperColor.Gb);
		var b = Math.round((1 - localProgress) * lowerColor.Bb + localProgress * upperColor.Bb);
		var a = Math.round((1 - localProgress) * lowerColor.A + localProgress * upperColor.A);
		
		return Color.fromBytes(r, g, b, a);
	}

	/**
	* Draws a arc.
	* @param	ccw (optional) Specifies whether the drawing should be counterclockwise.
	* @param	segments (optional) The amount of lines that should be used to draw the arc.
	*/
	public static function drawArc(g2: Graphics, cx: Float, cy: Float, radius: Float, sAngle: Float, eAngle: Float, strength: Float = 1, ccw: Bool = false,
			segments: Int = 0): Void {
		#if kha_html5
		if (kha.SystemImpl.gl == null) {
			var g: kha.js.CanvasGraphics = cast g2;
			radius -= strength / 2; // reduce radius to fit the line thickness within image width/height
			g.drawArc(cx, cy, radius, sAngle, eAngle, strength, ccw);
			return;
		}
		#end

		sAngle = sAngle % (Math.PI * 2);
		eAngle = eAngle % (Math.PI * 2);

		if (ccw) {
			if (eAngle > sAngle)
				eAngle -= Math.PI * 2;
		}
		else if (eAngle < sAngle)
			eAngle += Math.PI * 2;

		radius += strength / 2;
		if (segments <= 0)
			segments = Math.floor(10 * Math.sqrt(radius));

		var theta = (eAngle - sAngle) / segments;
		var c = Math.cos(theta);
		var s = Math.sin(theta);

		var x = Math.cos(sAngle) * radius;
		var y = Math.sin(sAngle) * radius;

		for (n in 0...segments) {
			var px = x + cx;
			var py = y + cy;

			var t = x;
			x = c * x - s * y;
			y = c * y + s * t;

			drawInnerLine(g2, x + cx, y + cy, px, py, strength);
		}
	}
 
	/**
	* Draws a filled arc.
	* @param	ccw (optional) Specifies whether the drawing should be counterclockwise.
	* @param	segments (optional) The amount of lines that should be used to draw the arc.
	*/
	public static function fillArc(g2: Graphics, cx: Float, cy: Float, radius: Float, sAngle: Float, eAngle: Float, ccw: Bool = false,
			segments: Int = 0): Void {
		#if kha_html5
		if (kha.SystemImpl.gl == null) {
			var g: kha.js.CanvasGraphics = cast g2;
			g.fillArc(cx, cy, radius, sAngle, eAngle, ccw);
			return;
		}
		#end

		sAngle = sAngle % (Math.PI * 2);
		eAngle = eAngle % (Math.PI * 2);

		if (ccw) {
			if (eAngle > sAngle)
				eAngle -= Math.PI * 2;
		}
		else if (eAngle < sAngle)
			eAngle += Math.PI * 2;

		if (segments <= 0)
			segments = Math.floor(10 * Math.sqrt(radius));

		var theta = (eAngle - sAngle) / segments;
		var c = Math.cos(theta);
		var s = Math.sin(theta);

		var x = Math.cos(sAngle) * radius;
		var y = Math.sin(sAngle) * radius;
		var sx = x + cx;
		var sy = y + cy;

		for (n in 0...segments) {
			var px = x + cx;
			var py = y + cy;

			var t = x;
			x = c * x - s * y;
			y = c * y + s * t;

			g2.fillTriangle(px, py, x + cx, y + cy, sx, sy);
		}
	}
 
	/**
	* Draws a circle.
	* @param	segments (optional) The amount of lines that should be used to draw the circle.
	*/
	public static function drawCircle(g2: Graphics, cx: Float, cy: Float, radius: Float, strength: Float = 1, segments: Int = 0): Void {
		#if kha_html5
		if (kha.SystemImpl.gl == null) {
			var g: kha.js.CanvasGraphics = cast g2;
			radius -= strength / 2; // reduce radius to fit the line thickness within image width/height
			g.drawCircle(cx, cy, radius, strength);
			return;
		}
		#end
		radius += strength / 2;

		if (segments <= 0)
			segments = Math.floor(10 * Math.sqrt(radius));

		var theta = 2 * Math.PI / segments;
		var c = Math.cos(theta);
		var s = Math.sin(theta);

		var x = radius;
		var y = 0.0;

		for (n in 0...segments) {
			var px = x + cx;
			var py = y + cy;

			var t = x;
			x = c * x - s * y;
			y = c * y + s * t;
			drawInnerLine(g2, x + cx, y + cy, px, py, strength);
		}
	}
 
	static function drawInnerLine(g2: Graphics, x1: Float, y1: Float, x2: Float, y2: Float, strength: Float): Void {
		var side = y2 > y1 ? 1 : 0;
		if (y2 == y1)
			side = x2 - x1 > 0 ? 1 : 0;

		var vec = new FastVector2();
		if (y2 == y1)
			vec.setFrom(new FastVector2(0, -1));
		else
			vec.setFrom(new FastVector2(1, -(x2 - x1) / (y2 - y1)));
		vec.length = strength;
		var p1 = new FastVector2(x1 + side * vec.x, y1 + side * vec.y);
		var p2 = new FastVector2(x2 + side * vec.x, y2 + side * vec.y);
		var p3 = p1.sub(vec);
		var p4 = p2.sub(vec);
		g2.fillTriangle(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
		g2.fillTriangle(p3.x, p3.y, p2.x, p2.y, p4.x, p4.y);
	}
 
	/**
	* Draws a filled circle.
	* @param	segments (optional) The amount of lines that should be used to draw the circle.
	*/
	public static function fillCircle(g2: Graphics, cx: Float, cy: Float, radius: Float, segments: Int = 0): Void {
		#if kha_html5
		if (kha.SystemImpl.gl == null) {
			var g: kha.js.CanvasGraphics = cast g2;
			g.fillCircle(cx, cy, radius);
			return;
		}
		#end

		if (segments <= 0) {
			segments = Math.floor(10 * Math.sqrt(radius));
		}

		var theta = 2 * Math.PI / segments;
		var c = Math.cos(theta);
		var s = Math.sin(theta);

		var x = radius;
		var y = 0.0;

		for (n in 0...segments) {
			var px = x + cx;
			var py = y + cy;

			var t = x;
			x = c * x - s * y;
			y = c * y + s * t;

			g2.fillTriangle(px, py, x + cx, y + cy, cx, cy);
		}
	}

	/**
     * Draws a triangle outline using three points.
     * @param g2 The graphics context
     * @param x1 First point x coordinate
     * @param y1 First point y coordinate
     * @param x2 Second point x coordinate
     * @param y2 Second point y coordinate
     * @param x3 Third point x coordinate
     * @param y3 Third point y coordinate
     * @param strength Line thickness
     */
    public static function drawTriangle(g2:Graphics, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, strength:Float = 1.0) {
        drawTriangleBase(g2, x1, y1, x2, y2, x3, y3, strength);
    }

	private static function drawTriangleBase(g2:Graphics, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, strength:Float) {
        var vertices = [
            new Vector2(x1, y1),
            new Vector2(x2, y2),
            new Vector2(x3, y3)
        ];
        drawPolygon(g2, 0, 0, vertices, strength);
    }
    
    /**
     * Draws a triangle outline within a dimension with the specified direction.
     * @param g2 The graphics context
     * @param destination The bounding rectangle for the triangle
     * @param direction Triangle direction using TriangleDirection flags
     * @param strength Line thickness
     */
    public static function drawTriangleDim(g2:Graphics, destination:Dim, direction:Int, strength:Float = 1.0) {
        if (destination == null) {
            return;
        }
        
        var x1 = 0.0, x2 = 0.0, x3 = 0.0, y1 = 0.0, y2 = 0.0, y3 = 0.0;
        
        // Calculate triangle points based on direction (using your existing logic)
        if ((direction & TRIANGLE_UP) != 0) {
            if ((direction & TRIANGLE_LEFT) != 0) {
                x1 = destination.x;
                y1 = destination.y;
                x2 = destination.x + (destination.width * .75);
                y2 = destination.y;
                x3 = destination.x;
                y3 = destination.y + (destination.height * .75);
            }
            else if ((direction & TRIANGLE_RIGHT) != 0) {
                x1 = destination.x + (destination.width * .25);
                y1 = destination.y;
                x2 = destination.x + destination.width;
                y2 = destination.y + (destination.height * .75);
                x3 = destination.x + destination.width;
                y3 = destination.y;
            }
            else {
                x1 = destination.x + (destination.width * .5);
                y1 = destination.y;
                x2 = destination.x;
                y2 = destination.y + (destination.height * .75);
                x3 = destination.x + destination.width;
                y3 = destination.y + (destination.height * .75);
            }
        }
        else if ((direction & TRIANGLE_DOWN) != 0) {
            if ((direction & TRIANGLE_LEFT) != 0) {
                x1 = destination.x;
                y1 = destination.y + (destination.height * .25);
                x2 = destination.x;
                y2 = destination.y + destination.height;
                x3 = destination.x + (destination.width * .75);
                y3 = destination.y + destination.height;
            }
            else if ((direction & TRIANGLE_RIGHT) != 0) {
                x1 = destination.x + destination.width;
                y1 = destination.y + (destination.height * .25);
                x2 = destination.x + (destination.width * .25);
                y2 = destination.y + destination.height;
                x3 = destination.x + destination.width;
                y3 = destination.y + destination.height;
            }
            else {
                x1 = destination.x;
                y1 = destination.y + (destination.height * .25);
                x2 = destination.x + (destination.width * .5);
                y2 = destination.y + destination.height;
                x3 = destination.x + destination.width;
                y3 = destination.y + (destination.height * .25);
            }
        }
        else if ((direction & TRIANGLE_LEFT) != 0) {
            x1 = destination.x;
            y1 = destination.y + (destination.height * .5);
            x2 = destination.x + (destination.width * .75);
            y2 = destination.y + destination.height;
            x3 = destination.x + (destination.width * .75);
            y3 = destination.y;
        }
        else if ((direction & TRIANGLE_RIGHT) != 0) {
            x1 = destination.x + (destination.width * .25);
            y1 = destination.y;
            x2 = destination.x + (destination.width * .25);
            y2 = destination.y + destination.height;
            x3 = destination.x + destination.width;
            y3 = destination.y + (destination.height * .5);
        }
        
        drawTriangle(g2, x1, y1, x2, y2, x3, y3, strength);
    }
    
    /**
     * Helper function to create a triangle from three points and draw it.
     * @param g2 The graphics context
     * @param p1 First point
     * @param p2 Second point  
     * @param p3 Third point
     * @param strength Line thickness
     */
    public static function drawTriangleFromPoints(g2:Graphics, p1:FastVector2, p2:FastVector2, p3:FastVector2, strength:Float = 1.0) {
        drawTriangle(g2, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, strength);
    }
    
    /**
     * Draws an equilateral triangle centered at the given point.
     * @param g2 The graphics context
     * @param centerX Center x coordinate
     * @param centerY Center y coordinate
     * @param radius Distance from center to vertices
     * @param rotation Rotation angle in radians
     * @param strength Line thickness
     */
    public static function drawEquilateralTriangle(g2:Graphics, centerX:Float, centerY:Float, radius:Float, rotation:Float = 0.0, strength:Float = 1.0) {
        var angle1 = rotation;
        var angle2 = rotation + (Math.PI * 2 / 3);
        var angle3 = rotation + (Math.PI * 4 / 3);
        
        var x1 = centerX + Math.cos(angle1) * radius;
        var y1 = centerY + Math.sin(angle1) * radius;
        var x2 = centerX + Math.cos(angle2) * radius;
        var y2 = centerY + Math.sin(angle2) * radius;
        var x3 = centerX + Math.cos(angle3) * radius;
        var y3 = centerY + Math.sin(angle3) * radius;
        
        drawTriangle(g2, x1, y1, x2, y2, x3, y3, strength);
    }
    
    /**
     * Draws an isosceles triangle pointing in a specific direction.
     * @param g2 The graphics context
     * @param x Base center x coordinate
     * @param y Base center y coordinate
     * @param baseWidth Width of the triangle base
     * @param height Height of the triangle
     * @param direction Direction the triangle points (0=up, 1=right, 2=down, 3=left)
     * @param strength Line thickness
     */
    public static function drawIsoscelesTriangle(g2:Graphics, x:Float, y:Float, baseWidth:Float, height:Float, direction:Int = 0, strength:Float = 1.0) {
        var x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float;
        var halfBase = baseWidth * 0.5;
        
        switch (direction) {
            case 0: // Up
                x1 = x; y1 = y - height * 0.5; // Top point
                x2 = x - halfBase; y2 = y + height * 0.5; // Bottom left
                x3 = x + halfBase; y3 = y + height * 0.5; // Bottom right
            case 1: // Right
                x1 = x + height * 0.5; y1 = y; // Right point
                x2 = x - height * 0.5; y2 = y - halfBase; // Left top
                x3 = x - height * 0.5; y3 = y + halfBase; // Left bottom
            case 2: // Down
                x1 = x; y1 = y + height * 0.5; // Bottom point
                x2 = x - halfBase; y2 = y - height * 0.5; // Top left
                x3 = x + halfBase; y3 = y - height * 0.5; // Top right
            default: // Left (3)
                x1 = x - height * 0.5; y1 = y; // Left point
                x2 = x + height * 0.5; y2 = y - halfBase; // Right top
                x3 = x + height * 0.5; y3 = y + halfBase; // Right bottom
        }
        
        drawTriangle(g2, x1, y1, x2, y2, x3, y3, strength);
    }
 
	/**
	* Draws a convex polygon.
	*/
	public static function drawPolygon(g2: Graphics, x: Float, y: Float, vertices: Array<Vector2>, strength: Float = 1) {
		var iterator = vertices.iterator();
		var v0 = iterator.next();
		var v1 = v0;

		while (iterator.hasNext()) {
			var v2 = iterator.next();
			g2.drawLine(v1.x + x, v1.y + y, v2.x + x, v2.y + y, strength);
			v1 = v2;
		}
		g2.drawLine(v1.x + x, v1.y + y, v0.x + x, v0.y + y, strength);
	}
 
	/**
	* Draws a filled convex polygon.
	*/
	public static function fillPolygon(g2: Graphics, x: Float, y: Float, vertices: Array<Vector2>) {
		var iterator = vertices.iterator();

		if (!iterator.hasNext())
			return;
		var v0 = iterator.next();

		if (!iterator.hasNext())
			return;
		var v1 = iterator.next();

		while (iterator.hasNext()) {
			var v2 = iterator.next();
			g2.fillTriangle(v0.x + x, v0.y + y, v1.x + x, v1.y + y, v2.x + x, v2.y + y);
			v1 = v2;
		}
	}
 
	/**
	* Draws a cubic bezier using 4 pairs of points. If the x and y arrays have a length bigger then 4, the additional
	* points will be ignored. With a length smaller of 4 a error will occur, there is no check for this.
	* You can construct the curves visually in Inkscape with a path using default nodes.
	* Provide x and y in the following order: startPoint, controlPoint1, controlPoint2, endPoint
	* Reference: http://devmag.org.za/2011/04/05/bzier-curves-a-tutorial/
	*/
	public static function drawCubicBezier(g2: Graphics, x: Array<Float>, y: Array<Float>, segments: Int = 20, strength: Float = 1.0): Void {
		var t: Float;

		var q0 = calculateCubicBezierPoint(0, x, y);
		var q1: Array<Float>;

		for (i in 1...(segments + 1)) {
			t = i / segments;
			q1 = calculateCubicBezierPoint(t, x, y);
			g2.drawLine(q0[0], q0[1], q1[0], q1[1], strength);
			q0 = q1;
		}
	}

	/**
	* Draws multiple cubic beziers joined by the end point. The minimum size is 4 pairs of points (a single curve).
	*/
	public static function drawCubicBezierPath(g2: Graphics, x: Array<Float>, y: Array<Float>, segments: Int = 20, strength: Float = 1.0): Void {
		var i = 0;
		var t: Float;
		var q0: Array<Float> = null;
		var q1: Array<Float> = null;

		while (i < x.length - 3) {
			if (i == 0)
				q0 = calculateCubicBezierPoint(0, [x[i], x[i + 1], x[i + 2], x[i + 3]], [y[i], y[i + 1], y[i + 2], y[i + 3]]);

			for (j in 1...(segments + 1)) {
				t = j / segments;
				q1 = calculateCubicBezierPoint(t, [x[i], x[i + 1], x[i + 2], x[i + 3]], [y[i], y[i + 1], y[i + 2], y[i + 3]]);
				g2.drawLine(q0[0], q0[1], q1[0], q1[1], strength);
				q0 = q1;
			}

			i += 3;
		}
	}

	static function calculateCubicBezierPoint(t: Float, x: Array<Float>, y: Array<Float>): Array<Float> {
		var u: Float = 1 - t;
		var tt: Float = t * t;
		var uu: Float = u * u;
		var uuu: Float = uu * u;
		var ttt: Float = tt * t;

		// first term
		var p: Array<Float> = [uuu * x[0], uuu * y[0]];

		// second term
		p[0] += 3 * uu * t * x[1];
		p[1] += 3 * uu * t * y[1];

		// third term
		p[0] += 3 * u * tt * x[2];
		p[1] += 3 * u * tt * y[2];

		// fourth term
		p[0] += ttt * x[3];
		p[1] += ttt * y[3];

		return p;
	}

	
    public static function drawTessellatedCircle(g2:Graphics, cx:Float, cy:Float, radius:Float, strength:Float, filled:Bool) {
        var segments = Math.floor(Math.max(16, radius * 0.5)); // More segments for larger circles
        var points = new Array<FastVector2>();
        
        for (i in 0...segments) {
            var angle = (i / segments) * Math.PI * 2;
            points.push(new FastVector2(
                cx + Math.cos(angle) * radius,
                cy + Math.sin(angle) * radius
            ));
        }
        
        if (filled) {
            // For filled circles, draw triangles from center
            for (i in 0...points.length) {
                var next = (i + 1) % points.length;
                g2.fillTriangle(
                    cx, cy,
                    points[i].x, points[i].y,
                    points[next].x, points[next].y
                );
            }
        } else {
            drawTessellatedPath(g2, points, strength, true);
        }
    }
    
    public static function drawTessellatedPath(g2:Graphics, points:Array<FastVector2>, strength:Float, closed:Bool = false) {
        for (i in 0...points.length - 1) {
            g2.drawLine(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y, strength);
        }
        
        if (closed && points.length > 2) {
            var last = points[points.length - 1];
            var first = points[0];
            g2.drawLine(last.x, last.y, first.x, first.y, strength);
        }
    }
    
    public static function drawSimpleCurve(g2:Graphics, points:Array<FastVector2>, strength:Float) {
        for (i in 0...points.length - 1) {
            g2.drawLine(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y, strength);
        }
    }
    
    private static function calculatePathLength(points:Array<FastVector2>):Float {
        var length = 0.0;
        for (i in 0...points.length - 1) {
            var dx = points[i + 1].x - points[i].x;
            var dy = points[i + 1].y - points[i].y;
            length += Math.sqrt(dx * dx + dy * dy);
        }
        return length;
    }
    
    private static function getCurveIdentifier(points:Array<FastVector2>):String {
        var id = "";
        for (p in points) {
            id += '${Math.floor(p.x * 10)},${Math.floor(p.y * 10)},';
        }
        return id;
    }
    
    public static function calculateBezierCurve(controlPoints:Array<FastVector2>, segments:Int):Array<FastVector2> {
        var points = new Array<FastVector2>();
        
        if (controlPoints.length == 2) {
            // Linear
            for (i in 0...segments + 1) {
                var t = i / segments;
                var x = controlPoints[0].x * (1 - t) + controlPoints[1].x * t;
                var y = controlPoints[0].y * (1 - t) + controlPoints[1].y * t;
                points.push(new FastVector2(x, y)));
            }
        } else if (controlPoints.length == 3) {
            // Quadratic
            for (i in 0...segments + 1) {
                var t = i / segments;
                var mt = 1 - t;
                var x = mt * mt * controlPoints[0].x + 2 * mt * t * controlPoints[1].x + t * t * controlPoints[2].x;
                var y = mt * mt * controlPoints[0].y + 2 * mt * t * controlPoints[1].y + t * t * controlPoints[2].y;
                points.push(new FastVector2(x, y));
            }
        } else if (controlPoints.length >= 4) {
            // Cubic
            for (i in 0...segments + 1) {
                var t = i / segments;
                var mt = 1 - t;
                var x = mt * mt * mt * controlPoints[0].x + 
                       3 * mt * mt * t * controlPoints[1].x + 
                       3 * mt * t * t * controlPoints[2].x + 
                       t * t * t * controlPoints[3].x;
                var y = mt * mt * mt * controlPoints[0].y + 
                       3 * mt * mt * t * controlPoints[1].y + 
                       3 * mt * t * t * controlPoints[2].y + 
                       t * t * t * controlPoints[3].y;
                points.push(new FastVector2(x, y));
            }
        }
        
        return points;
    }



    private static function generateRoundedRectPath(x:Float, y:Float, width:Float, height:Float, 
                                           topLeft:Float, topRight:Float, bottomRight:Float, bottomLeft:Float):Array<FastVector2> {
        var points = new Array<FastVector2>();
        var segments = Math.floor(vectorSpace.getOptimalSegments(ExtraMath.max([ topLeft, topRight, bottomRight, bottomLeft ]) * 2 * Math.PI) / 4);
        
        // Start from top-left corner (after radius)
        points.push(new FastVector2(x + topLeft, y)));
        
        // Top edge
        points.push(new FastVector2(x + width - topRight, y));
        
        // Top-right corner
        if (topRight > 0) {
            var cornerPoints = generateQuarterCirclePath(x + width - topRight, y + topRight, topRight, 3, segments);
            for (p in cornerPoints) points.push(p);
        }
        
        // Right edge
        points.push(new FastVector2(x + width, y + height - bottomRight));
        
        // Bottom-right corner
        if (bottomRight > 0) {
            var cornerPoints = generateQuarterCirclePath(x + width - bottomRight, y + height - bottomRight, bottomRight, 0, segments);
            for (p in cornerPoints) points.push(p);
        }
        
        // Bottom edge
        points.push(new FastVector2(x + bottomLeft, y + height));
        
        // Bottom-left corner
        if (bottomLeft > 0) {
            var cornerPoints = generateQuarterCirclePath(x + bottomLeft, y + height - bottomLeft, bottomLeft, 1, segments);
            for (p in cornerPoints) points.push(p);
        }
        
        // Left edge
        points.push(new FastVector2(x, y + topLeft));
        
        // Top-left corner
        if (topLeft > 0) {
            var cornerPoints = generateQuarterCirclePath(x + topLeft, y + topLeft, topLeft, 2, segments);
            for (p in cornerPoints) points.push(p);
        }
        
        return points;
    }
    
    private static function generateQuarterCirclePath(cx:Float, cy:Float, radius:Float, quadrant:Int, segments:Int):Array<FastVector2> {
        var points = new Array<FastVector2>();
        var startAngle = quadrant * Math.PI * 0.5;
        var endAngle = startAngle + Math.PI * 0.5;
        
        for (i in 1...segments) { // Skip first point to avoid duplication
            var angle = startAngle + (i / segments) * (endAngle - startAngle);
            var x = cx + Math.cos(angle) * radius;
            var y = cy + Math.sin(angle) * radius;
            points.push(new FastVector2(x, y));
        }
        
        return points;
    }
    
    private static function fillQuarterCircle(g2:Graphics, cx:Float, cy:Float, radius:Float, quadrant:Int) {
        var segments = Math.floor(Math.max(8, radius * 0.5));
        var startAngle = quadrant * Math.PI * 0.5;
        var endAngle = startAngle + Math.PI * 0.5;
        
        for (i in 0...segments) {
            var angle1 = startAngle + (i / segments) * (endAngle - startAngle);
            var angle2 = startAngle + ((i + 1) / segments) * (endAngle - startAngle);
            
            var x1 = cx + Math.cos(angle1) * radius;
            var y1 = cy + Math.sin(angle1) * radius;
            var x2 = cx + Math.cos(angle2) * radius;
            var y2 = cy + Math.sin(angle2) * radius;
            
            g2.fillTriangle(cx, cy, x1, y1, x2, y2);
        }
    }
    
    public static function drawVectorRoundedRectCorners(g2:Graphics, x:Float, y:Float, width:Float, height:Float, 
                                                topLeft:Float, topRight:Float, bottomRight:Float, bottomLeft:Float, 
                                                strength:Float, filled:Bool) {
        var maxRadius = Math.min(width, height) * 0.5;
        topLeft = Math.min(topLeft, maxRadius);
        topRight = Math.min(topRight, maxRadius);
        bottomRight = Math.min(bottomRight, maxRadius);
        bottomLeft = Math.min(bottomLeft, maxRadius);
        
        var cacheKey = vectorSpace.getCacheKey('roundedRectCorners_${x}_${y}_${width}_${height}_${topLeft}_${topRight}_${bottomRight}_${bottomLeft}_${filled}');
        var cachedPath = vectorSpace.getCachedPath(cacheKey);
        
        if (cachedPath == null) {
            cachedPath = generateRoundedRectPath(x, y, width, height, topLeft, topRight, bottomRight, bottomLeft);
            vectorSpace.setCachedPath(cacheKey, cachedPath);
        }
        
        var scaledStrength = vectorSpace.transformDistance(strength);
        
        if (filled) {
            drawFilledPath(g2, cachedPath);
        } else {
            drawTessellatedPath(g2, cachedPath, scaledStrength, true);
        }
    }
    
    private static function drawQuarterCircle(g2:Graphics, cx:Float, cy:Float, radius:Float, quadrant:Int, strength:Float) {
        var segments = Math.floor(Math.max(8, radius * 0.3));
        var startAngle = quadrant * Math.PI * 0.5;
        var endAngle = startAngle + Math.PI * 0.5;
        
        for (i in 0...segments) {
            var angle1 = startAngle + (i / segments) * (endAngle - startAngle);
            var angle2 = startAngle + ((i + 1) / segments) * (endAngle - startAngle);
            
            var x1 = cx + Math.cos(angle1) * radius;
            var y1 = cy + Math.sin(angle1) * radius;
            var x2 = cx + Math.cos(angle2) * radius;
            var y2 = cy + Math.sin(angle2) * radius;
            
            g2.drawLine(x1, y1, x2, y2, strength);
        }
    }
    
    private static function drawFilledPath(g2:Graphics, points:Array<FastVector2>) {
        // Simple triangle fan fill from center
        if (points.length < 3) return;
        
        var centerX = 0.0;
        var centerY = 0.0;
        for (p in points) {
            centerX += p.x;
            centerY += p.y;
        }
        centerX /= points.length;
        centerY /= points.length;
        
        for (i in 0...points.length) {
            var next = (i + 1) % points.length;
            g2.fillTriangle(
                centerX, centerY,
                points[i].x, points[i].y,
                points[next].x, points[next].y
            );
        }
    }

}