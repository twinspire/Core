package twinspire;

enum abstract ResourceType(Int) from Int to Int
{
	var RESOURCE_ART		=	0;
	var RESOURCE_FONT		=	1;
	var RESOURCE_SOUND		=	2;
	var RESOURCE_VIDEO		=	3;
	var RESOURCE_MISC		=	4;
}