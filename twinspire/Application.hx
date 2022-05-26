package twinspire;

import twinspire.GlobalEvents;
import kha.math.FastVector2;
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
import kha.input.Sensor;
import kha.input.SensorType;
#if !js
import kha.input.Pen;
#end
import kha.Font;
import kha.System;
import kha.Assets;
import kha.Framebuffer;
import kha.Image;
import kha.Blob;
import kha.Window;

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

	private function new()
	{
		initEvents();
	}

	// Event Handling routines

	private function initEvents()
	{
		GlobalEvents.init();
		_events = [];

		System.notifyOnApplicationState(_app_foreground, _app_resume, _app_pause, _app_background, _app_shutdown);
		System.notifyOnDropFiles(_app_dropFiles);
		System.notifyOnCutCopyPaste(_clipboard_cut, _clipboard_copy, _clipboard_paste);

		if (Keyboard.get(0) != null)
			Keyboard.get(0).notify(_keyboard_onKeyDown, _keyboard_onKeyUp, _keyboard_onKeyPress);
		
		if (Mouse.get(0) != null)
		{
			Mouse.get(0).notify(_mouse_onMouseDown, _mouse_onMouseUp, _mouse_onMouseMove, _mouse_onMouseWheel);
			Mouse.get(0).notifyOnLockChange(_mouse_onLockChange, _mouse_onLockError);
		}

		Gamepad.notifyOnConnect(_gamepad_connected, _gamepad_disconnected);
		
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

		if (Sensor.get(Accelerometer) != null)
		{
			Sensor.get(Accelerometer).notify(_accelerometer_move);
		}

		if (Sensor.get(Gyroscope) != null)
		{
			Sensor.get(Gyroscope).notify(_gyroscope_move);
		}
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

		@:privateAccess(GlobalEvents) GlobalEvents.keysDown[e.key] = true;

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

		@:privateAccess(GlobalEvents) GlobalEvents.keysUp[e.key] = true;
		@:privateAccess(GlobalEvents) GlobalEvents.keysDown[e.key] = false;

		_events.push(e);
	}

	private function _keyboard_onKeyPress(char:String)
	{
		var e = new Event();
		e.type = EVENT_KEY_PRESS;
		e.char = char;

		@:privateAccess(GlobalEvents) GlobalEvents.keyChar = char;

		_events.push(e);
	}

	private function _mouse_onMouseDown(button:Int, x:Int, y:Int)
	{
		var e = new Event();
		e.type = EVENT_MOUSE_DOWN;
		e.mouseButton = button;
		e.mouseX = x;
		e.mouseY = y;

		@:privateAccess(GlobalEvents) GlobalEvents.mouseButton = button;
		@:privateAccess(GlobalEvents) GlobalEvents.mouseX = mouseX;
		@:privateAccess(GlobalEvents) GlobalEvents.mouseY = mouseY;

		_events.push(e);
	}

	private function _mouse_onMouseUp(button:Int, x:Int, y:Int)
	{
		var e = new Event();
		e.type = EVENT_MOUSE_UP;
		e.mouseButton = button;
		e.mouseX = x;
		e.mouseY = y;

		@:privateAccess(GlobalEvents) GlobalEvents.mouseButton = button;
		@:privateAccess(GlobalEvents) GlobalEvents.mouseX = x;
		@:privateAccess(GlobalEvents) GlobalEvents.mouseY = y;

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

		@:privateAccess(GlobalEvents) GlobalEvents.mouseX = x;
		@:privateAccess(GlobalEvents) GlobalEvents.mouseY = y;
		@:privateAccess(GlobalEvents) GlobalEvents.mouseMoveX = movementX;
		@:privateAccess(GlobalEvents) GlobalEvents.mouseMoveY = movementY;

		_events.push(e);
	}

	private function _mouse_onMouseWheel(delta:Int)
	{
		var e = new Event();
		e.type = EVENT_MOUSE_WHEEL;
		e.mouseDelta = delta;

		@:privateAccess(GlobalEvents) GlobalEvents.mouseDelta = delta;

		_events.push(e);
	}

	private function _mouse_onLockChange()
	{
		var e = new Event();
		e.type = EVENT_MOUSE_LOCK_CHANGE;

		@:privateAccess(GlobalEvents) GlobalEvents.mouseLocked = !GlobalEvents.mouseLocked;

		_events.push(e);
	}

	private function _mouse_onLockError()
	{
		var e = new Event();
		e.type = EVENT_MOUSE_LOCK_ERROR;
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

	private function _accelerometer_move(x:Float, y:Float, z:Float)
	{
		var e = new Event();
		e.type = EVENT_ACCELEROMETER;
		e.accelerometerX = x;
		e.accelerometerY = y;
		e.accelerometerZ = z;
		_events.push(e);
	}

	private function _gyroscope_move(x:Float, y:Float, z:Float)
	{
		var e = new Event();
		e.type = EVENT_GYROSCOPE;
		e.gyroscopeX = x;
		e.gyroscopeY = y;
		e.gyroscopeZ = z;
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

	private function _gamepad_connected(id:Int)
	{
		var e = new Event();
		e.type = EVENT_GAMEPAD_CONNECTED;
		e.gamepadId = id;
		_events.push(e);

		var pad = Gamepad.get(id);
		if (pad != null)
		{
			if (id == 0)
				pad.notify(_gamepad_onAxis0, _gamepad_onButton0);
			else if (id == 1)
				pad.notify(_gamepad_onAxis1, _gamepad_onButton1);
			else if (id == 2)
				pad.notify(_gamepad_onAxis2, _gamepad_onButton2);
			else if (id == 3)
				pad.notify(_gamepad_onAxis3, _gamepad_onButton3);
		}
	}

	private function _gamepad_disconnected(id:Int)
	{
		var e = new Event();
		e.type = EVENT_GAMEPAD_DISCONNECTED;
		e.gamepadId = id;
		_events.push(e);

		var pad = Gamepad.get(id);
		if (pad != null)
		{
			if (id == 0)
				pad.remove(_gamepad_onAxis0, _gamepad_onButton0);
			else if (id == 1)
				pad.remove(_gamepad_onAxis1, _gamepad_onButton1);
			else if (id == 2)
				pad.remove(_gamepad_onAxis2, _gamepad_onButton2);
			else if (id == 3)
				pad.remove(_gamepad_onAxis3, _gamepad_onButton3);
		}
	}

	//
	// Static Fields and Functions
	//

	/**
	* Get the current Application instance.
	**/
	public static var instance:Application;

	/**
	* Get the current Resource Manager instance.
	**/
	public static var resources:ResourceManager;

	/**
	 * Do not asset load on startup.
	 */
	public static var noAssetLoading:Bool;

	/**
	* Set the style of the preloader to use when loading the application.
	**/
	public static var preloader:PreloaderStyle = 0;

	/**
	* If using a custom preload style, create a class that extends `Preloader`
	* and assign it to this variable.
	**/
	public static var loader:Preloader;

	private static var buffer:BackBuffer;

	/**
	* Creates a new secondary buffer with the following width and height values.
	**/
	public static function createBackBuffer(width:Int, height:Int)
	{
		buffer = new BackBuffer(width, height);
	}

	/**
	* Sets a new size for the current back buffer.
	**/
	public static function setBufferSize(width:Int, height:Int)
	{
		buffer.adjustBufferSize(width, height);
	}

	/**
	 * Get the current size of the current back buffer. If no back buffer is found, `null` is returned.
	 * Note that this returns the size of the buffer, NOT the size of the game window. Use native `Kha.System` functions for this.
	 */
	public static function getBufferSize():FastVector2
	{
		if (buffer != null)
		{
			return new FastVector2(buffer.clientWidth, buffer.clientHeight);
		}
		
		return null;
	}

	/**
	* Gets the actual image from the back buffer to render.
	**/
	public static function getBufferContext()
	{
		return buffer.getImage();
	}

	/**
	* Get the 2D graphics context from the current back buffer.
	**/
	public static function getGraphics2D()
	{
		if (buffer != null)
		{
			return buffer.g2;
		}

		return null;
	}

	/**
	* Get the 3D graphics context from the current back buffer.
	**/
	public static function getGraphics3D()
	{
		if (buffer != null)
		{
			return buffer.g4;
		}

		return null;
	}

	/**
	* Create an `Application`, initialise the system and load all available assets.
	*
	* @param options The system options used to declare title and size of the game client.
	* @param callback The function handler that is called when all assets have been loaded.
	*/
	public static function create(options:SystemOptions, callback:Void -> Void)
	{
		System.start(options, (window:Window) ->
		{
			if (preloader == 0)
				preloader = PRELOADER_BASIC;
			
			if (loader == null)
				loader = new Preloader(preloader);
			
			System.notifyOnFrames(loader.render);

			if (!noAssetLoading)
			{
				Assets.loadEverything(() ->
				{
					instance = new Application();
					resources = new ResourceManager();

					System.removeFramesListener(loader.render);
					callback();
				});
			}
			else
			{
				instance = new Application();
				resources = new ResourceManager();

				System.removeFramesListener(loader.render);
				callback();
			}
		});
	}

}