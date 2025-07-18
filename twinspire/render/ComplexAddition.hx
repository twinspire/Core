package twinspire.render;

import twinspire.text.TextInputMethod;
import twinspire.DimIndex;

typedef ComplexAddition = {
    var requiresInput:Bool;
    var requiresContainer:Bool;
    var textInputMethod:TextInputMethod;
    var parent:Int;
    var child:Int;
    var index:DimIndex;
}