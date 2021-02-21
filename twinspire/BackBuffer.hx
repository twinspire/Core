package twinspire;

import kha.graphics2.Graphics in Graphics2;
import kha.graphics4.Graphics in Graphics4;
import kha.Image;

class BackBuffer
{

    private var _image:Image;
    public function getImage() return _image;

    private var _clientWidth:Int;
    /**
    * Gets the width of the back buffer rendered on-screen.
    * This is NOT the width of the frame or window which this buffer renders in.
    **/
    public var clientWidth(get, never):Int;
    function get_clientWidth()
    {
        return _clientWidth;
    }

    private var _clientHeight:Int;
    /**
    * Gets the height of the back buffer rendered on-screen.
    * This is NOT the height of the frame or window which this buffer renders in.
    **/
    public var clientHeight(get, never):Int;
    function get_clientHeight()
    {
        return _clientHeight;
    }

    public var g2(get, never):Graphics2;
    function get_g2() return _image.g2;

    public var g4(get, never):Graphics4;
    function get_g4() return _image.g4;

    /**
    * Create a new back buffer with the following default width and height set.
    **/
    public function new(width:Int, height:Int)
    {
        adjustBufferSize(width, height);
    }

    public function adjustBufferSize(w:Int, h:Int)
    {
        _image = Image.createRenderTarget(w, h);
        _clientWidth = w;
        _clientHeight = h;
    }
    
}