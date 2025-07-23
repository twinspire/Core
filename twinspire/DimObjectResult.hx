package twinspire;

import twinspire.events.DimBindingOptions;
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
    var ?textDim:Dim;
    var ?bindings:DimBindingOptions;
}

typedef DimObjectOptions = {
    var ?forceClipping:Bool;
    var ?makeContainer:Bool;
    var ?bindings:DimBindingOptions;
}