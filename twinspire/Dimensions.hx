package twinspire;

import twinspire.geom.Dim;
import twinspire.Application;

import kha.math.FastVector2;
import kha.System;

enum abstract HorizontalAlign(Int) from Int to Int
{
	var HALIGN_NONE				=	0;
	var HALIGN_LEFT				=	1;
	var HALIGN_MIDDLE			=	2;
	var HALIGN_RIGHT			=	3;
}

enum abstract VerticalAlign(Int) from Int to Int
{
	var VALIGN_NONE				=	0;
	var VALIGN_TOP				=	1;
	var VALIGN_CENTRE			=	2;
	var VALIGN_BOTTOM			=	3;
}

class Dimensions
{

    /**
	 * Create a dimension block from the given width and height, centering in the middle of the screen.
	 * @param width The width of the object to centre.
	 * @param height The height of the object to centre.
	 */
	public static function centreScreenFromSize(width:Float, height:Float)
    {
        var x = (System.windowWidth() - width) / 2;
        var y = (System.windowHeight() - height) / 2;
        return new Dim(x, y, width, height);
    }

    /**
     * Create a dimension block from the given width and given offset on the Y-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetY The offset from the top of the screen.
     */
    public static function centreScreenY(width:Float, height:Float, offsetY:Float)
    {
        var x = (System.windowWidth() - width) / 2;
        return new Dim(x, offsetY, width, height);
    }

    /**
     * Create a dimension block from the given width and given offset on the X-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetX The offset from the top of the screen.
     */
    public static function centreScreenX(width:Float, height:Float, offsetX:Float)
    {
        var y = (System.windowHeight() - height) / 2;
        return new Dim(offsetX, y, width, height);
    }

    /**
     * Create a dimension block from the given width and given offset on the Y-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetY The offset from the top of the screen.
     */
    public static function centreBufferY(width:Float, height:Float, offsetY:Float)
    {
        var x = (Application.getBufferSize().x - width) / 2;
        return new Dim(x, offsetY, width, height);
    }

    /**
     * Align the given dimension along the x-axis of the current game client.
     * @param a The dimension.
     * @param halign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static inline function screenAlignX(a:Dim, halign:Int, offset:FastVector2)
    {
        if (halign == HALIGN_LEFT)
        {
            a.x = offset.x;
            a.y = offset.y;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            a = centreScreenY(a.width, a.height, offset.y);
            a.x = offset.x;
        }
        else if (halign == HALIGN_RIGHT)
        {
            a.x = System.windowWidth() - a.width - offset.x;
            a.y = offset.y;
        }
    }

    /**
     * Align the given dimension along the y-axis of the current game client.
     * @param a The dimension.
     * @param valign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static inline function screenAlignY(a:Dim, valign:Int, offset:FastVector2)
    {
        if (valign == VALIGN_TOP)
        {
            a.x = offset.x;
            a.y = offset.y;
        }
        else if (valign == VALIGN_CENTRE)
        {
            a = centreScreenX(a.width, a.height, offset.x);
        }
        else if (valign == VALIGN_BOTTOM)
        {
            a.y = System.windowHeight() - a.height - offset.y;
            a.x = System.windowHeight() - a.width - offset.x;
        }
    }

    /**
     * Align the given dimension along the x-axis of the current back buffer.
     * @param a The dimension.
     * @param halign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static inline function bufferAlignX(a:Dim, halign:Int, offset:FastVector2)
    {
        if (halign == HALIGN_LEFT)
        {
            a.x = offset.x;
            a.y = offset.y;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            a = centreBufferY(a.width, a.height, offset.y);
            a.x = offset.x;
        }
        else if (halign == HALIGN_RIGHT)
        {
            a.x = Application.getBufferSize().x - a.width - offset.x;
            a.y = offset.y;
        }
    }

    /**
     * Align the given dimension along the y-axis of the current back buffer.
     * @param a The dimension.
     * @param valign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static inline function bufferAlignY(a:Dim, valign:Int, offset:FastVector2)
    {
        if (valign == VALIGN_TOP)
        {
            a.x = offset.x;
            a.y = offset.y;
        }
        else if (valign == VALIGN_CENTRE)
        {
            a = centreBufferX(a.width, a.height, offset.x);
        }
        else if (valign == VALIGN_BOTTOM)
        {
            a.y = Application.getBufferSize().y - a.height - offset.y;
            a.x = Application.getBufferSize().y - a.width - offset.x;
        }
    }

    /**
     * Create a dimension block from the given width and given offset on the X-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetX The offset from the top of the screen.
     */
    public static function centreBufferX(width:Float, height:Float, offsetX:Float)
    {
        var y = (Application.getBufferSize().y - height) / 2;
        return new Dim(offsetX, y, width, height);
    }

    /**
     * Create a new dimension from an existing dimension, offsetting by the value of x as a margin from the given dimension.
     * If `offsetX` is less than `0`, then the new dimension will appear on the left of the new dimension, rather than the right.
     * If `offsetX` is equal to `0`, the new dimension will be to the right with no margin.
     * @param a The current dimension to use.
     * @param offsetX The value to offset the new dimension.
     */
    public static function dimOffsetX(a:Dim, offsetX:Float)
    {
        if (offsetX >= 0)
            return new Dim(a.x + a.width + offsetX, a.y, a.width, a.height);
        else if (offsetX < 0)
            return new Dim(a.x - a.width - offsetX, a.y, a.width, a.height);
        
        return null;
    }

    /**
     * Create a new dimension from an existing dimension, offsetting by the value of y as a margin from the given dimension.
     * If `offsetY` is less than `0`, then the new dimension will appear above the new dimension, rather than below.
     * If `offsetY` is equal to `0`, the new dimension will be below with no margin.
     * @param a The current dimension to use.
     * @param offsetY The value to offset the new dimension.
     */
    public static function dimOffsetY(a:Dim, offsetY:Float)
    {
        if (offsetY >= 0)
            return new Dim(a.x, a.y + a.height + offsetY, a.width, a.height);
        else if (offsetY < 0)
            return new Dim(a.x, a.y - a.height - offsetY, a.width, a.height);

        return null;
    }

    /**
     * Aligns dimension `b` to `a`, with the given alignment options. If both alignment values are set to CENTRE/MIDDLE, `b` will effectively be centred to `a`.
     * @param a The first dimension.
     * @param b The second dimension.
     * @param valign The vertical alignment `b` should be to `a`.
     * @param halign The horizontal alignment `b` should be to `a`.
     */
    public static inline function dimAlign(a:Dim, b:Dim, valign:Int, halign:Int)
    {
        dimVAlign(a, b, valign);
        dimHAlign(a, b, halign);
    }

    /**
     * Aligns dimension `b` to `a` on the Y-axis using the given vertical alignment.
     * @param a The first dimension.
     * @param b The second dimension.
     * @param valign The vertical alignment `b` should be to `a`.
     */
    public static inline function dimVAlign(a:Dim, b:Dim, valign:Int)
    {
        if (valign == VALIGN_TOP)
        {
            b.y = a.y;
        }
        else if (valign == VALIGN_BOTTOM)
        {
            b.y = a.y - (b.height - a.height);
        }
        else if (valign == VALIGN_CENTRE)
        {
            b.y = a.y - ((b.height - a.height) / 2);
        }
    }

    /**
     * Aligns dimension `b` to `a` on the X-axis using the given horizontal alignment.
     * @param a The first dimension.
     * @param b The second dimension.
     * @param valign The horizontal alignment `b` should be to `a`.
     */
    public static inline function dimHAlign(a:Dim, b:Dim, halign:Int)
    {
        if (halign == HALIGN_LEFT)
        {
            b.x = a.x;
        }
        else if (halign == HALIGN_RIGHT)
        {
            b.x = a.x - (b.width - a.width);
        }
        else if (halign == HALIGN_MIDDLE)
        {
            b.x = a.x - ((b.width - a.width) / 2);
        }
    }

}