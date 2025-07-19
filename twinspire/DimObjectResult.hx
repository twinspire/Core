package twinspire;

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
}

typedef DimObjectOptions = {
    var ?forceClipping:Bool;
    var ?makeContainer:Bool;
}