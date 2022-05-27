package twinspire.events;

enum abstract KeyModifiers(Int) from Int to Int
{
	var MOD_CONTROL			=	0x01;
	var MOD_SHIFT			=	0x02;
	var MOD_ALT				=	0x04;
	var MOD_ALTGR			=	0x08;
}