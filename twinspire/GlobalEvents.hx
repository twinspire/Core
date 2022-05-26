package twinspire;

import twinspire.events.Event;
import twinspire.events.EventType;

import kha.input.KeyCode;

@:build(twinspire.macros.StaticBuilder.build())
class GlobalEvents
{

	@:local
	var mouseX:Int;
	var mouseY:Int;
	var mouseMoveX:Int;
	var mouseMoveY:Int;
	var mouseButton:Int;
	var mouseReleased:Bool;
	var mouseDown:Bool;
	var mouseDelta:Int;
	var mouseLocked:Bool;

	var keysUp:Array<Bool>;
	var keysDown:Array<Bool>;
	var keyChar:String;

	var touchX:Int;
	var touchY:Int;
	var touchDown:Bool;
	var touchReleased:Bool;
	var touchFingers:Int;

	var filesDropped:Array<String>;

	var appActivated:Bool;
	var appDeactivated:Bool;


	@:global
	function init()
	{
		keysUp = [ for (i in 0...255) false ];
		keysDown = [ for (i in 0...255) false ];
	}

	function end()
	{
		mouseReleased = false;
		appActivated = false;
		appDeactivated = false;
		filesDropped = [];
		keysUp = [ for (i in 0...255) false ];
		mouseDelta = 0;
		touchReleased = false;
		mouseMoveX = mouseMoveY = 0;

	}

	function isKeyUp(code:KeyCode)
	{
		return keysUp[code];
	}

}