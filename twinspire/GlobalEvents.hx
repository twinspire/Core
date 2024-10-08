package twinspire;

import twinspire.geom.Dim;
import kha.math.Vector3;
import kha.math.Vector2;
import twinspire.Application;
import twinspire.events.Event;
import twinspire.events.EventType;
import twinspire.events.TouchState;
import twinspire.events.GamepadState;
import twinspire.events.KeyModifiers;

import kha.input.KeyCode;

@:allow(Application)
@:build(twinspire.macros.StaticBuilder.build())
class GlobalEvents
{

	@:local
	@:noCompletion var lastMouseX:Int;
	@:noCompletion var lastMouseY:Int;

	@:noCompletion var mouseX:Int;
	@:noCompletion var mouseY:Int;
	@:noCompletion var mouseMoveX:Int;
	@:noCompletion var mouseMoveY:Int;
	@:noCompletion var mouseButton:Int;
	@:noCompletion var mouseReleased:Bool;
	@:noCompletion var mouseDown:Bool;
	@:noCompletion var mouseDelta:Int;
	@:noCompletion var mouseLocked:Bool;

	@:noCompletion var keysUp:Array<Bool>;
	@:noCompletion var keysDown:Array<Bool>;
	@:noCompletion var keyChar:String;

	@:noCompletion var recentlyTouchedIndex:Int;
	@:noCompletion var lastTouchedIndex:Int;
	@:noCompletion var touchStates:Array<TouchState>;

	@:noCompletion var accelerometerX:Float;
	@:noCompletion var accelerometerY:Float;
	@:noCompletion var accelerometerZ:Float;

	@:noCompletion var gyroscopeX:Float;
	@:noCompletion var gyroscopeY:Float;
	@:noCompletion var gyroscopeZ:Float;

	@:noCompletion var penX:Int;
	@:noCompletion var penY:Int;
	@:noCompletion var penPressure:Float;
	@:noCompletion var penReleased:Bool;
	@:noCompletion var penDown:Bool;

	@:noCompletion var filesDropped:Array<String>;

	@:noCompletion var appActivated:Bool;
	@:noCompletion var appDeactivated:Bool;
	@:noCompletion var appPaused:Bool;
	@:noCompletion var appShutdownRequested:Bool;

	@:noCompletion var pasteData:String;

	@:noCompletion var recentlyConnectedGamepad:Int;
	@:noCompletion var gamepadStates:Array<GamepadState>;

	@:global
	var copyValue:String;

	/**
	 * Initialise the fields for this `GlobalEvents` class.
	 */
	function init()
	{
		touchStates = [];
		gamepadStates = [];
		filesDropped = [];
		keysUp = [ for (i in 0...255) false ];
		keysDown = [ for (i in 0...255) false ];
	}

	/**
	 * This function should be called at the end of each render loop to
	 * reset one-time event values.
	 */
	function end()
	{
		mouseReleased = false;
		appActivated = false;
		appDeactivated = false;
		filesDropped = [];
		keysUp = [ for (i in 0...255) false ];
		mouseDelta = 0;
		mouseMoveX = mouseMoveY = 0;
		for (touch in touchStates)
		{
			touch.touchReleased = false;
		}

		recentlyConnectedGamepad = -1;
		recentlyTouchedIndex = -1;
		lastTouchedIndex = -1;
		pasteData = "";
	}

	/**
	 * Determine if the following key has been released.
	 * @param code The key to look for.
	 */
	function isKeyUp(code:KeyCode, modifiers:Int)
	{
		var needsShift = (modifiers & MOD_SHIFT) != 0;
		var needsAlt = (modifiers & MOD_ALT) != 0;
		var needsControl = (modifiers & MOD_CONTROL) != 0;
		var needsAltGr = (modifiers & MOD_ALTGR) != 0;
		var hasShift = false;
		var hasAlt = false;
		var hasControl = false;
		var hasAltGr = false;

		if (modifiers != 0)
		{
			hasShift = needsShift && keysDown[KeyCode.Shift];
			hasControl = needsControl && keysDown[KeyCode.Control];
			hasAlt = needsAlt && keysDown[KeyCode.Alt];
			hasAltGr = needsAltGr && keysDown[KeyCode.AltGr];
		}

		if (!needsShift && !keysDown[KeyCode.Shift])
			hasShift = true;
		
		if (!needsAlt && !keysDown[KeyCode.Alt])
			hasAlt = true;
		
		if (!needsAltGr && !keysDown[KeyCode.AltGr])
			hasAltGr = true;

		if (!needsControl && !keysDown[KeyCode.Control])
			hasControl = true;

		return keysUp[code] && (hasAlt) && (hasAltGr) && (hasControl) && (hasShift);
	}

	/**
	* Get the integer value of the first `kha.input.KeyCode` found to be released by
	* the user.
	**/
	function isAnyKeyUp():Array<Int> {
		var temp = [];
		for (i in 0...keysUp.length) {
			if (keysUp[i]) temp.push(i);
		}

		return temp;
	}

	/**
	 * Determines if the following key is held down by the user.
	 * @param code The key to check.
	 */
	function isKeyDown(code:KeyCode)
	{
		return keysDown[code];
	}

	/**
	* Get the integer value of the first `kha.input.KeyCode` found to be pressed by
	* the user.
	**/
	function isAnyKeyDown():Array<Int> {
		var temp = [];
		for (i in 0...keysDown.length) {
			if (keysDown[i]) temp.push(i);
		}

		return temp;
	}

	/**
	 * Gets the recently pressed character(s) as ASCII character(s).
	 * If the code value of the character being passed is not an ASCII character (0-255),
	 * the value is ignored.
	 * 
	 * This function is useful if you need to ensure compatibility with an
	 * ASCII character set.
	 * 
	 * Returns an `Array<Int>` representing the character codes recently pressed.
	 */
	function getKeyCharCodesA():Array<Int>
	{
		var result = [];
		for (i in 0...keyChar.length)
		{
			if ((StringTools.fastCodeAt(keyChar, i) | 0xFF) == 0xFF)
				result.push(StringTools.fastCodeAt(keyChar, i));
		}
		return result;
	}

	/**
	 * Gets the recently pressed character(s) as ASCII character(s).
	 * If the code value of the character being passed is not an ASCII character (0-255),
	 * the value is ignored.
	 * 
	 * This function is useful if you need to ensure compatibility with an
	 * ASCII character set.
	 * 
	 * Returns a `String` representing the characters recently pressed.
	 */
	function getKeyCharA()
	{
		var result = "";
		for (i in 0...keyChar.length)
		{
			if ((StringTools.fastCodeAt(keyChar, i) | 0xFF) == 0xFF)
				result += keyChar.charAt(i);
		}
		return result;
	}

	/**
	 * Gets the recently pressed character(s) as Unicode.
	 */
	function getKeyChar():String
	{
		return keyChar;
	}

	/**
	 * Gets the recently pressed character(s) as Unicode code-points as an array of integers.
	 * @return Array<Int>
	 */
	function getKeyCharCode():Array<Int>
	{
		var result = [];
		for (i in 0...keyChar.length)
		{
			result.push(StringTools.fastCodeAt(keyChar, i));
		}
		return result;
	}

	/**
	 * Get the current mouse position in the client window.
	 * @return Vector2
	 */
	function getMousePosition():Vector2
	{
		return new Vector2(mouseX, mouseY);
	}

	/**
	 * Get a value determining if the given mouse button has been pressed.
	 * 
	 * Pressed checks if no other mouse buttons are currently being pressed down.
	 * @param button Which button to check.
	 * @return Bool
	 */
	function isMouseButtonPressed(button:Int):Bool
	{
		return (mouseButton == button && mouseReleased && !mouseDown);
	}

	/**
	 * Get a value determining if the given mouse button has been pressed down.
	 * @param button Which button to check.
	 * @return Bool
	 */
	function isMouseButtonDown(button:Int):Bool
	{
		return (mouseButton == button && mouseDown);
	}

	/**
	 * Get a value determining if the given mouse button has been released.
	 * Released is not the same as Pressed. 
	 * @param button 
	 * @return Bool
	 */
	function isMouseButtonReleased(button:Int):Bool
	{
		return (mouseButton == button && mouseReleased);
	}
	
	/**
	 * Get a value determining how far the mouse has moved since the last frame.
	 * @return Vector2
	 */
	function getMouseMovement():Vector2
	{
		return new Vector2(mouseMoveX, mouseMoveY);
	}

	/**
	 * Gets the delta of the mouse wheel to determine if it is either scrolling up or down.
	 * @return Int
	 */
	function getMouseDelta():Int
	{
		return mouseDelta;
	}

	/**
	 * Get the index of the finger that was first pressed on the screen.
	 * @return Int
	 */
	function getTouchFingerStarted():Int
	{
		return recentlyTouchedIndex;
	}

	/**
	 * Get the index of the finger that was released on the screen.
	 * @return Int
	 */
	function getTouchFingerEnded():Int
	{
		return lastTouchedIndex;
	}

	/**
	 * Get the position of a finger at a given index.
	 * @param index The index of a given finger.
	 * @return Vector2
	 */
	function getTouchFingerPosition(index:Int):Vector2
	{
		if (index < touchStates.length)
		{
			return new Vector2(touchStates[index].touchX, touchStates[index].touchY);
		}

		return null;
	}

	/**
	 * Get a value determining if all fingers have been released from the screen.
	 * @return Bool
	 */
	function isTouchReleasedAll():Bool
	{
		var result = true;
		for (i in 0...touchStates.length)
		{
			if (touchStates[i].touchDown)
				return false;
		}
		return result;
	}

	/**
	 * Get a value determining if the finger at the given index has been released from the screen.
	 * @param index The index of the finger.
	 * @return Bool
	 */
	function isTouchReleased(index:Int):Bool
	{
		if (index < touchStates.length)
		{
			return !touchStates[index].touchDown && touchStates[index].touchReleased;
		}

		return false;
	}

	/**
	 * Get a value determining if the finger at the given index is currently pressing down on the screen.
	 * @param index The index of the finger.
	 * @return Bool
	 */
	function isTouchDown(index:Int):Bool
	{
		if (index < touchStates.length)
		{
			return touchStates[index].touchDown;
		}

		return false;
	}

	/**
	 * Get a value determining how many fingers are currently pressed down on the screen.
	 * @return Int
	 */
	function getTotalTouchesDown():Int
	{
		var result = 0;
		for (i in 0...touchStates.length)
		{
			if (touchStates[i].touchDown)
				result += 1;
		}
		return result;
	}

	/**
	 * Gets the current position of the accelerometer.
	 * @return Vector3
	 */
	function getAccelerometerPosition():Vector3
	{
		return new Vector3(accelerometerX, accelerometerY, accelerometerZ);
	}

	/**
	 * Gets the current position of the gyroscope.
	 * @return Vector3
	 */
	function getGyroscopePosition():Vector3
	{
		return new Vector3(gyroscopeX, gyroscopeY, gyroscopeZ);
	}

	/**
	 * Gets the position of the pen.
	 * @return Vector2
	 */
	function getPenPosition():Vector2
	{
		return new Vector2(penX, penY);
	}

	/**
	 * Get a value determining the pressure of the pen on the display.
	 * @return Float
	 */
	function getPenPressure():Float
	{
		return penPressure;
	}

	/**
	 * Get a value determining if the pen is pressing down on the display.
	 * @return Bool
	 */
	function isPenDown():Bool
	{
		return penDown;
	}

	/**
	 * Get a value determining if the pen has released from the display.
	 * @return Bool
	 */
	function isPenReleased():Bool
	{
		return penReleased;
	}

	/**
	 * Get a value determining if the pan has pressed down and released from the display.
	 * @return Bool
	 */
	function isPenPressed():Bool
	{
		return !penDown && penReleased;
	}

	/**
	 * Get all the file paths for recently dragged files into the client.
	 * @return Array<String>
	 */
	function getFilesDropped():Array<String>
	{
		return filesDropped;
	}

	/**
	 * Get a value determining if the application is currently active.
	 * @return Bool
	 */
	function isAppActive():Bool
	{
		return appActivated;
	}

	/**
	 * Get a value determining if the application is running (i.e. not paused).
	 * @return Bool
	 */
	function isAppRunning():Bool
	{
		return !appPaused;
	}

	/**
	 * Get a value determining if the app is currently deactivated.
	 * @return Bool
	 */
	function isAppDeactivated():Bool
	{
		return appDeactivated;
	}

	/**
	 * Get a value determining if the application has requested shutdown.
	 * @return Bool
	 */
	function hasAppRequestedShutdown():Bool
	{
		return appShutdownRequested;
	}

	/**
	 * If a value has been pasted, such as when the user types `CTRL+V` on the keyboard, this
	 * value represents the pasted data.
	 * @return String
	 */
	function getPasteData():String
	{
		return pasteData;
	}

	/**
	 * Get the last gamepad that was connected to the computer or device as an index.
	 * @return Int
	 */
	function getConnectedGamepad():Int
	{
		return recentlyConnectedGamepad;
	}

	/**
	 * Get a value determining if the given gamepad index is currently connected.
	 * 
	 * If the index cannot be found, `false` is returned.
	 * @param index The index of the gamepad.
	 * @return Bool
	 */
	function isGamepadConnected(index:Int):Bool
	{
		if (index < gamepadStates.length)
		{
			return gamepadStates[index].connected;
		}

		return false;
	}

	/**
	 * Gets a value determining if a gamepad button was fully pressed and released.
	 * @param index The index of the gamepad to check.
	 * @param button The button index on the gamepad.
	 * @return Bool
	 */
	function isGamepadButtonPressed(index:Int, button:Int):Bool
	{
		if (index < gamepadStates.length)
		{
			var state = gamepadStates[index];
			if (state.previousButtons[button] > 0.0 && state.buttons[button] == 0.0)
			{
				return true;
			}
		}

		return false;
	}

	/**
	 * Gets a value determining if a gamepad button is currently being pressed down.
	 * @param index The index of the gamepad to check.
	 * @param button The button index on the gamepad.
	 * @return Bool
	 */
	function isGamepadButtonDown(index:Int, button:Int):Bool
	{
		if (index < gamepadStates.length)
		{
			var state = gamepadStates[index];
			// Should probably check if 0.8 is a reasonable value
			// on gamepad controls, like the left and right trigger
			// buttons on PS3/XBOX controllers where pressure is likely
			// to be recorded, and if this value should be considered
			// pressed down or not.
			if (state.buttons[button] >= 0.8)
			{
				return true;
			}
		}

		return false;
	}

	/**
	 * Get a value of the pressure for a specific button on the gamepad.
	 * @param index The index of the gamepad to check.
	 * @param button The button index on the gamepad.
	 * @return Float
	 */
	function getGamepadButtonPressure(index:Int, button:Int):Float
	{
		if (index < gamepadStates.length)
		{
			var state = gamepadStates[index];
			return state.buttons[button];
		}

		return 0.0;
	}

	/**
	 * Get a value determining the axis values as a `Vector2`, for a given analogue stick.
	 * @param index The index of the gamepad to check.
	 * @param axis The index of the analogue stick.
	 * @return Vector2
	 */
	function getGamepadAxisValue(index:Int, axis:Int):Vector2
	{
		if (index < gamepadStates.length)
		{
			var state = gamepadStates[index];
			var axis1 = axis * 2;
			var axis2 = axis1 + 1;
			return new Vector2(state.axes[axis1], state.axes[axis2]);
		}

		return null;
	}

	/**
	 * Determines if the mouse is over the current dimension.
	 * @param dim The dim instance to check against.
	 */
	@:global
	function isMouseOverDim(dim:Dim)
	{
		var result = (mouseX > dim.x && mouseX < dim.x + dim.width && mouseY > dim.y && mouseY < dim.y + dim.height);
		return result;
	}

}