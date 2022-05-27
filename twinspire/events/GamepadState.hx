package twinspire.events;

typedef GamepadState = {
	var connected:Bool;
	var id:Int;
	var axes:Array<Float>;
	var buttons:Array<Float>;
	var previousButtons:Array<Float>;
}