package twinspire;

import twinspire.DimSize;
import kha.math.FastVector2;
import twinspire.events.DimBindingOptions;
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
    var ?textDim:Dim;
    var ?bindings:DimBindingOptions;
    var ?path:String;
}

typedef DimObjectOptions = {
    var ?forceClipping:Bool;
    var ?makeContainer:Bool;
    var ?bindings:DimBindingOptions;
    var ?offsetFromPosition:FastVector2;
    var ?overrideSize:DimSize;
    var ?passthrough:Bool;
}