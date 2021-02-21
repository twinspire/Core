package twinspire.events;

@:enum
abstract EventType(Int) from Int to Int
{
	/**
	* A mouse button is down.
	*/
	var EVENT_MOUSE_DOWN		=	1;
	/**
	* A mouse button has released.
	*/
	var EVENT_MOUSE_UP			=	2;
	/**
	* The mouse has moved.
	*/
	var EVENT_MOUSE_MOVE		=	3;
	/**
	* The mouse wheel has moved.
	*/
	var EVENT_MOUSE_WHEEL		=	4;
	/**
	* A keyboard button has been pressed down.
	*/
	var EVENT_KEY_DOWN			=	5;
	/**
	* A keyboard button has been released.
	*/
	var EVENT_KEY_UP			=	6;
	/**
	* A keyboard button has been pressed down and released.
	**/
	var EVENT_KEY_PRESS			=	12;
	/**
	* A gamepad axis has moved.
	*/
	var EVENT_GAMEPAD_AXIS		=	7;
	/**
	* A gamepad button has been pressed.
	*/
	var EVENT_GAMEPAD_BUTTON	=	8;
	/**
	* The game screen has been touched.
	*/
	var EVENT_TOUCH_START		=	9;
	/**
	* Any or all fingers have been released from the game screen.
	*/
	var EVENT_TOUCH_END			=	10;
	/**
	* Any or all fingers have moved on the game screen.
	*/
	var EVENT_TOUCH_MOVE		=	11;
	/**
	* Occurs when the pen from a tablet device is pressed down.
	**/
	var EVENT_PEN_DOWN			=	13;
	/**
	* Occurs when the pen from a tablet device is released.
	**/
	var EVENT_PEN_UP			=	14;
	/**
	* Occurs when the pen from a tablet device moves.
	**/
	var EVENT_PEN_MOVE			=	15;
	/**
	* Occurs when the state of the application becomes the active window on the screen.
	**/
	var EVENT_FOREGROUND		=	16;
	/**
	* Occurs when the state of the application is no longer the active window on the screen.
	**/
	var EVENT_BACKGROUND		=	17;
	/**
	* Occurs when the state of the application is paused. Only applicable if using a gamepad with the pause button on it, or on a mobile device with any such key.
	**/
	var EVENT_PAUSE				=	18;
	/**
	* Occurs when the state of the application resumes. Only applicable if using a gamepad with the pause button on it, or on a mobile device with any such key.
	**/
	var EVENT_RESUME			=	19;
	/**
	* Occurs when a shutdown request is made to the application, including when the 'cross' in the corner is pressed (only occurs on certain targets).
	**/
	var EVENT_SHUTDOWN			=	20;
	/**
	* Occurs when a file is dropped into the client bounds of the application using drag-and-drop with the mouse.
	**/
	var EVENT_DROP_FILES		=	21;
	/**
	* Occurs when the cut event (Ctrl+X) is triggered from the keyboard. Only works with text.
	**/
	var EVENT_CLIPBOARD_CUT		=	22;
	/**
	* Occurs when the copy event (Ctrl+C) is triggered from the keyboard. Only works with text.
	**/
	var EVENT_CLIPBOARD_COPY	=	23;
	/**
	* Occurs when the paste event (Ctrl+V) is triggered from the keyboard. Only works with text.
	**/
	var EVENT_CLIPBOARD_PASTE	=	24;
}