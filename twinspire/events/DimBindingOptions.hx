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
    var ?togglePath:String;
}