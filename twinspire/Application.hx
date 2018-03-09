/**
Copyright 2017 Colour Multimedia Enterprises, and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

package twinspire;

import twinspire.events.Event;

import kha.math.FastVector2 in FV2;
import kha.math.FastVector3 in FV3;
import kha.math.FastVector4 in FV4;
import kha.math.Vector2 in V2;
import kha.math.Vector4 in V4;
import kha.graphics2.Graphics in Graphics2;
import kha.input.Gamepad;
import kha.input.KeyCode;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.input.Surface;
#if !js
import kha.input.Pen;
#end
import kha.Font;
import kha.System;
import kha.Assets;
import kha.Framebuffer;
import kha.Image;
import kha.Blob;

import haxe.Json;

import twinspire.Preloader.PreloaderStyle;
using twinspire.events.EventType;
using StringTools;

/**
* The `Application` class handles primarily event handling in a coherent manner.
* 
* No rendering is done in the Application class.
*/
class Application
{

	private var g2:Graphics2;
	private var _events:Array<Event>;
	private var _error:String;
	private var _ctrl:Bool;
	private var _cutTrigger:Bool;

	/**
	* Gets the currently polled event.
	*/
	public var currentEvent:Event;

	/**
	* Gets whether or not a cut or copy event was triggered. Check this against an `EVENT_KEY_UP` event
	* to set the `cutData` variable just before the `CLIPBOARD_CUT` or `CLIPBOARD_COPY` event occurs.
	**/
	public var cutTriggered(get, null):Bool;
	function get_cutTriggered() return _cutTrigger;

	/**
	* Set the text value of the thing to cut when the event is triggered.
	* If this value is not filled at the time of the event, nothing will be cut.
	**/
	public var cutData:String;

	/**
	* Set the style of the preloader to use when loading the application.
	**/
	public static var preloader:PreloaderStyle;

	/**
	* If using a custom preload style, create a class that extends `Preloader`
	* and assign it to this variable.
	**/
	public static var loader:Preloader;

	/**
	* Create an `Application`, initialise the system and load all available assets.
	*
	* @param options The system options used to declare title and size of the game client.
	* @param callback The function handler that is called when all assets have been loaded.
	*/
	public static function create(options:SystemOptions, callback:Void -> Void)
	{
		System.init(options, function()
		{
			if (preloader == null)
				preloader = PRELOADER_BASIC;
			
			if (loader == null)
				loader = new Preloader(preloader);
			
			System.notifyOnRender(loader.render);

			Assets.loadEverything(function()
			{
				instance = new Application();
				resources = new ResourceManager();

				System.removeRenderListener(loader.render);
				callback();
			});
		});
	}

	public function new()
	{
		initEvents();
	}

	// Event Handling routines

	private function initEvents()
	{
		_events = [];

		System.notifyOnApplicationState(_app_foreground, _app_resume, _app_pause, _app_background, _app_shutdown);
		System.notifyOnDropFiles(_app_dropFiles);
		System.notifyOnCutCopyPaste(_clipboard_cut, _clipboard_copy, _clipboard_paste);

		if (Keyboard.get(0) != null)
			Keyboard.get(0).notify(_keyboard_onKeyDown, _keyboard_onKeyUp, _keyboard_onKeyPress);
		
		if (Mouse.get(0) != null)
			Mouse.get(0).notify(_mouse_onMouseDown, _mouse_onMouseUp, _mouse_onMouseMove, _mouse_onMouseWheel);
		
		if (Gamepad.get(0) != null)
			Gamepad.get(0).notify(_gamepad_onAxis0, _gamepad_onButton0);
		
		if (Gamepad.get(1) != null)
			Gamepad.get(1).notify(_gamepad_onAxis1, _gamepad_onButton1);

		if (Gamepad.get(2) != null)
			Gamepad.get(2).notify(_gamepad_onAxis2, _gamepad_onButton2);
		
		if (Gamepad.get(3) != null)
			Gamepad.get(3).notify(_gamepad_onAxis3, _gamepad_onButton3);
		
		if (Surface.get(0) != null)
			Surface.get(0).notify(_surface_onTouchStart, _surface_onTouchEnd, _surface_onTouchMove);
		
		#if !js
		if (Pen.get(0) != null)
			Pen.get(0).notify(_pen_onPenDown, _pen_onPenUp, _pen_onPenMove);
		#end
	}

	/**
	* Processes all of the events currently waiting in the event queue
	* until there is none left. This should be called before any rendering
	* takes place.
	*
	* @return Returns `true` if there are events waiting to be processed. Otherwise `false`.
	*/
	public function pollEvent():Bool
	{
		if (_events.length == 0)
		{
			currentEvent = null;
			return false;
		}

		currentEvent = _events[0].clone();
		_events.splice(0, 1);
		return true;
	}




	/**
	* Event handling functions
	*/

	private function _keyboard_onKeyDown(key:KeyCode)
	{
		var e = new Event();
		e.type = EVENT_KEY_DOWN;
		e.key = key;
		_ctrl = key == KeyCode.Control;

		_events.push(e);
	}

	private function _keyboard_onKeyUp(key:KeyCode)
	{
		var e = new Event();
		e.type = EVENT_KEY_UP;
		e.key = key;
		if ((key == KeyCode.X || key == KeyCode.C) && _ctrl)
			_cutTrigger = true;
		else
			_cutTrigger = false;

		_ctrl = !(key == KeyCode.Control);

		_events.push(e);
	}

	private function _keyboard_onKeyPress(char:String)
	{
		var e = new Event();
		e.type = EVENT_KEY_PRESS;
		e.char = char;
		_events.push(e);
	}

	private function _mouse_onMouseDown(button:Int, x:Int, y:Int)
	{
		var e = new Event();
		e.type = EVENT_MOUSE_DOWN;
		e.mouseButton = button;
		e.mouseX = x;
		e.mouseY = y;
		_events.push(e);
	}

	private function _mouse_onMouseUp(button:Int, x:Int, y:Int)
	{
		var e = new Event();
		e.type = EVENT_MOUSE_UP;
		e.mouseButton = button;
		e.mouseX = x;
		e.mouseY = y;
		_events.push(e);
	}

	private function _mouse_onMouseMove(x:Int, y:Int, movementX:Int, movementY:Int)
	{
		var e = new Event();
		e.type = EVENT_MOUSE_MOVE;
		e.mouseX = x;
		e.mouseY = y;
		e.mouseMovementX = movementX;
		e.mouseMovementY = movementY;
		_events.push(e);
	}

	private function _mouse_onMouseWheel(delta:Int)
	{
		var e = new Event();
		e.type = EVENT_MOUSE_WHEEL;
		e.mouseDelta = delta;
		_events.push(e);
	}

	private function _gamepad_onAxis0(axis:Int, value:Float)
	{
		var e = new Event();
		e.type = EVENT_GAMEPAD_AXIS;
		e.gamepadId = 0;
		e.gamepadAxis = axis;
		e.gamepadAxisValue = value;
		_events.push(e);
	}

	private function _gamepad_onButton0(button:Int, value:Float)
	{
		var e = new Event();
		e.type = EVENT_GAMEPAD_BUTTON;
		e.gamepadId = 0;
		e.gamepadButton = button;
		e.gamepadButtonValue = value;
		_events.push(e);
	}

	private function _gamepad_onAxis1(axis:Int, value:Float)
	{
		var e = new Event();
		e.type = EVENT_GAMEPAD_AXIS;
		e.gamepadId = 1;
		e.gamepadAxis = axis;
		e.gamepadAxisValue = value;
		_events.push(e);
	}

	private function _gamepad_onButton1(button:Int, value:Float)
	{
		var e = new Event();
		e.type = EVENT_GAMEPAD_BUTTON;
		e.gamepadId = 1;
		e.gamepadButton = button;
		e.gamepadButtonValue = value;
		_events.push(e);
	}

	private function _gamepad_onAxis2(axis:Int, value:Float)
	{
		var e = new Event();
		e.type = EVENT_GAMEPAD_AXIS;
		e.gamepadId = 2;
		e.gamepadAxis = axis;
		e.gamepadAxisValue = value;
		_events.push(e);
	}

	private function _gamepad_onButton2(button:Int, value:Float)
	{
		var e = new Event();
		e.type = EVENT_GAMEPAD_BUTTON;
		e.gamepadId = 2;
		e.gamepadButton = button;
		e.gamepadButtonValue = value;
		_events.push(e);
	}

	private function _gamepad_onAxis3(axis:Int, value:Float)
	{
		var e = new Event();
		e.type = EVENT_GAMEPAD_AXIS;
		e.gamepadId = 3;
		e.gamepadAxis = axis;
		e.gamepadAxisValue = value;
		_events.push(e);
	}

	private function _gamepad_onButton3(button:Int, value:Float)
	{
		var e = new Event();
		e.type = EVENT_GAMEPAD_BUTTON;
		e.gamepadId = 3;
		e.gamepadButton = button;
		e.gamepadButtonValue = value;
		_events.push(e);
	}

	private function _surface_onTouchStart(index:Int, x:Int, y:Int)
	{
		var e = new Event();
		e.type = EVENT_TOUCH_START;
		e.touchIndex = index;
		e.touchX = x;
		e.touchY = y;
		_events.push(e);
	}

	private function _surface_onTouchEnd(index:Int, x:Int, y:Int)
	{
		var e = new Event();
		e.type = EVENT_TOUCH_END;
		e.touchIndex = index;
		e.touchX = x;
		e.touchY = y;
		_events.push(e);
	}

	private function _surface_onTouchMove(index:Int, x:Int, y:Int)
	{
		var e = new Event();
		e.type = EVENT_TOUCH_MOVE;
		e.touchIndex = index;
		e.touchX = x;
		e.touchY = y;
		_events.push(e);
	}

#if !js

	private function _pen_onPenDown(x:Int, y:Int, pressure:Float)
	{
		var e = new Event();
		e.type = EVENT_PEN_DOWN;
		e.penX = x;
		e.penY = y;
		e.penPressure = pressure;
		_events.push(e);
	}

	private function _pen_onPenUp(x:Int, y:Int, pressure:Float)
	{
		var e = new Event();
		e.type = EVENT_PEN_UP;
		e.penX = x;
		e.penY = y;
		_events.push(e);
	}

	private function _pen_onPenMove(x:Int, y:Int, pressure:Float)
	{
		var e = new Event();
		e.type = EVENT_PEN_MOVE;
		e.penX = x;
		e.penY = y;
		e.penPressure = pressure;
		_events.push(e);
	}

#end

	private function _app_foreground()
	{
		var e = new Event();
		e.type = EVENT_FOREGROUND;
		_events.push(e);
	}

	private function _app_resume()
	{
		var e = new Event();
		e.type = EVENT_RESUME;
		_events.push(e);
	}

	private function _app_pause()
	{
		var e = new Event();
		e.type = EVENT_PAUSE;
		_events.push(e);
	}

	private function _app_background()
	{
		var e = new Event();
		e.type = EVENT_BACKGROUND;
		_events.push(e);
	}

	private function _app_shutdown()
	{
		var e = new Event();
		e.type = EVENT_SHUTDOWN;
		_events.push(e);
	}

	private function _clipboard_cut()
	{
		var e = new Event();
		e.type = EVENT_CLIPBOARD_CUT;
		_events.push(e);

		var temp = cutData;
		cutData = "";
		return temp;
	}

	private function _clipboard_copy()
	{
		var e = new Event();
		e.type = EVENT_CLIPBOARD_COPY;
		_events.push(e);

		var temp = cutData;
		cutData = "";
		return temp;
	}

	private function _clipboard_paste(value:String)
	{
		var e = new Event();
		e.type = EVENT_CLIPBOARD_PASTE;
		e.clipboard = value;
		_events.push(e);
	}

	private function _app_dropFiles(path:String)
	{
		var e = new Event();
		e.type = EVENT_DROP_FILES;
		e.filePath = path;
		_events.push(e);
	}

	public static var instance:Application;
	public static var resources:ResourceManager;

}