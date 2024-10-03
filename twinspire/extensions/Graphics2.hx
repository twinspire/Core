package twinspire.extensions;

import twinspire.geom.Dim;

import kha.math.FastVector2;
import kha.math.Vector2;
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

enum abstract BorderFlags(Int) from Int to Int
{
	var BORDER_NONE				=	0;
	var BORDER_TOP				=	0x01;
	var BORDER_LEFT				=	0x02;
	var BORDER_RIGHT			=	0x04;
	var BORDER_BOTTOM			=	0x08;
	var BORDER_ALL				=	0x0F;
}

class Graphics2
{

	private static var _forceMultilineUpdate:Bool;
	private static var _useCrlf:Bool;

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

	public static function drawBorders(g2:Graphics, destination:Dim, lineThickness:Float = 1.0, borders:Int = BORDER_ALL)
	{
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
			g2.drawLine(destination.x + destination.width + lineThickness / 2, destination.y + lineThickness / 2, 
				destination.x + destination.width - lineThickness / 2, destination.y + destination.height - lineThickness / 2, lineThickness);
		}

		if ((borders & BORDER_BOTTOM) != 0)
		{
			g2.drawLine(destination.x + lineThickness / 2, destination.y + destination.height - lineThickness / 2,
				destination.x + destination.width - lineThickness / 2, destination.y + destination.height - lineThickness / 2, lineThickness);
		}
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

	public static function disableMultilineUpdate()
	{
		_forceMultilineUpdate = false;
	}

	public static function useCRLF(crlf:Bool)
	{
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

}