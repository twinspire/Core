package twinspire;

import twinspire.Dimensions.DimInitCommand;
import twinspire.Id;
import twinspire.geom.Dim;
import twinspire.DimIndex;

typedef DimObjectResult = {
    var ?ident:String;
    var ?dim:Dim;
    var ?autoSize:Bool;
    var ?clipped:Bool;
    var ?id:Id;
    var ?textInput:Bool;
    var ?requestedContainer:Bool;
    var ?parentIndex:Int;
    var ?resultIndex:DimIndex;
    var ?originalCommand:DimInitCommand;
}

typedef DimObjectOptions = {
    var ?forceClipping:Bool;
    var ?makeContainer:Bool;
}