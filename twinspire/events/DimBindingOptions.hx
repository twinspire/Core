package twinspire.events;

import twinspire.DimIndex;
import twinspire.events.EventArgs;

typedef DimBindingOptions = {
    var ?target:DimIndex;
    var ?onClick:(EventArgs) -> Void;
    var ?onMouseOver:(EventArgs) -> Void;
    var ?onMouseDown:(EventArgs) -> Void;
    var ?onBeginDrag:(EventArgs) -> Void;
    var ?onEndDrag:(EventArgs) -> Void;
    var ?onDragging:(EventArgs) -> Void;
    var ?onKeyUp:(EventArgs) -> Void;
    var ?onKeyDown:(EventArgs) -> Void;
    var ?onKeyPress:(EventArgs) -> Void;
    var ?toggler:Toggler;
    var ?customEvents:Array<String>;
}

typedef Toggler = {
    var ?triggers:String;
    var ?path:String;
    var ?triggeredBy:Int;
    var ?initialVisibility:Bool;
}