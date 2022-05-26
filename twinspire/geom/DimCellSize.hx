package twinspire.geom;

enum abstract DimCellSizing(Int) from Int to Int
{
	var DIM_SIZING_PERCENT			=	0;
	var DIM_SIZING_PIXELS			=	1;
}

typedef DimCellSize = {
	var value:Float;
	var sizing:DimCellSizing;
}