package twinspire;

import twinspire.DimMap;
import twinspire.Id;
import kha.Font;
import kha.math.FastVector2;
import twinspire.geom.Box;
import twinspire.Dimensions.DimFlow;
import twinspire.Dimensions.DimAlignment;

typedef DimObject = {
    var ?id:Id;
    var ?scope:DimScope;
    var ?asGroup:Bool;

    var ?alignTo:String;
    var ?align:DimAlignment;
    var ?alignOffset:FastVector2;
    var ?flow:DimFlow;
    var ?padding:Box;
    var ?margin:Box;
    var ?width:Float;
    var ?height:Float;
    var ?size:DimSize;

    var ?text:String;
    var ?font:Font;
    var ?fontSize:Int;
    var ?growToTextSize:Bool;

    var ?items:DimMap;
}