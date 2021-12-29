package twinspire.events;

enum abstract JoystickButtons(Int) from Int to Int
{
	var JOYSTICK_A				=	0;
	var JOYSTICK_B				=	1;
	var JOYSTICK_X				=	2;
	var JOYSTICK_Y				=	3;
	var JOYSTICK_LB				=	4;
	var JOYSTICK_RB				=	5;
	var JOYSTICK_LT				=	6;
	var JOYSTICK_RT				=	7;
	var JOYSTICK_BACK			=	8;
	var JOYSTICK_START			=	9;
	var JOYSTICK_LEFT_ANALOG	=	10;
	var JOYSTICK_RIGHT_ANALOG	=	11;
	var JOYSTICK_DPAD_UP		=	12;
	var JOYSTICK_DPAD_DOWN		=	13;
	var JOYSTICK_DPAD_LEFT		=	14;
	var JOYSTICK_DPAD_RIGHT		=	15;

	var JOYSTICK_MAX			=	16;
}