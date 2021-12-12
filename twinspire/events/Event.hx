package twinspire.events;

import kha.input.KeyCode;

/**
* The `Event` class contains data related to the event handling used internally by the `Game` class.
*/
class Event
{

	/**
	* The type of event this is. Use `EventType` to check the types.
	*/
	public var type:Int;
	/**
	* The position of the mouse on the `x` axis, relative to the game client.
	*/
	public var mouseX:Int;
	/**
	* The position of the mouse on the `y` axis, relative to the game client.
	*/
	public var mouseY:Int;
	/**
	* Determines which mouse button was pressed. This value is zero-based.
	*/
	public var mouseButton:Int;
	/**
	* Determines by how much the mouse moved since the last event to MouseMove on the `x` axis.
	*/
	public var mouseMovementX:Int;
	/**
	* Determines by how much the mouse moved since the last event to MouseMove on the `y` axis.
	*/
	public var mouseMovementY:Int;
	/**
	* A value determining which direction the mouse wheel moved. 1 for down, -1 for up.
	*/
	public var mouseDelta:Int;
	/**
	* The key that was pressed during a KEY_EVENT.
	*/
	public var key:KeyCode;
	/**
	* The key pressed during the EVENT_KEY_PRESS event.
	*/
	public var char:String;
	/**
	* The index of the gamepad currently in use. This value is zero-based.
	*/
	public var gamepadId:Int;
	/**
	* The x or y-axis that was moved on the controller.
	*/
	public var gamepadAxis:Int;
	/**
	* A value determining how far in one direction the on which axis the analogue stick moves.
	*/
	public var gamepadAxisValue:Float;
	/**
	* The gamepad button pressed.
	*/
	public var gamepadButton:Int;
	/**
	* If pressure exists for a button, this value determines the pressure.
	*/
	public var gamepadButtonValue:Float;
	/**
	* If more than one finger touches the screen, this determines the index of the current finger.
	*/
	public var touchIndex:Int;
	/**
	* The x position of the finger in the game.
	*/
	public var touchX:Int;
	/**
	* The y position of the finger in the game.
	*/
	public var touchY:Int;
	/**
	* The x position of the pen relative to the upper-left corner of the drawing tablet.
	**/
	public var penX:Int;
	/**
	* The y position of the pen relative to the upper-left corner of the drawing tablet.
	**/
	public var penY:Int;
	/**
	* The amount of pressure of the pen on the drawing tablet. The pen can still move with a pressure of zero.
	**/
	public var penPressure:Float;
	/**
	* The current text data on the clipboard.
	**/
	public var clipboard:String;
	/**
	* The file path received from a drop event.
	**/
	public var filePath:String;
	/**
	* The G-Force value of the x axis.
	**/
	public var accelerometerX:Float;
	/**
	* The G-Force value of the y axis.
	**/
	public var accelerometerY:Float;
	/**
	* The G-Force value of the z axis.
	**/
	public var accelerometerZ:Float;
	/**
	* The x rotation rate.
	**/
	public var gyroscopeX:Float;
	/**
	* The y rotation rate.
	**/
	public var gyroscopeY:Float;
	/**
	* The z rotation rate.
	**/
	public var gyroscopeZ:Float;

	public function new()
	{
		
	}

	public function clone()
	{
		var e = new Event();
		e.type = this.type;
		e.mouseX = this.mouseX;
		e.mouseY = this.mouseY;
		e.mouseButton = this.mouseButton;
		e.mouseMovementX = this.mouseMovementX;
		e.mouseMovementY = this.mouseMovementY;
		e.mouseDelta = this.mouseDelta;
		e.key = this.key;
		e.char = this.char;
		e.gamepadAxis = this.gamepadAxis;
		e.gamepadAxisValue = this.gamepadAxisValue;
		e.gamepadButton = this.gamepadButton;
		e.gamepadButtonValue = this.gamepadButtonValue;
		e.touchIndex = this.touchIndex;
		e.touchX = this.touchX;
		e.touchY = this.touchY;
		e.penX = this.penX;
		e.penY = this.penY;
		e.penPressure = this.penPressure;
		e.clipboard = this.clipboard;
		e.filePath = this.filePath;
		e.accelerometerX = this.accelerometerX;
		e.accelerometerY = this.accelerometerY;
		e.accelerometerZ = this.accelerometerZ;
		e.gyroscopeX = this.gyroscopeX;
		e.gyroscopeY = this.gyroscopeY;
		e.gyroscopeZ = this.gyroscopeZ;
		return e;
	}

}