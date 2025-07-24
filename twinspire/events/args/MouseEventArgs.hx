package twinspire.events.args;

import kha.math.Vector2;
import kha.math.FastVector2;

class MouseEventArgs extends EventArgs {

    /**
    * The button that was pressed, if any.
    **/
    public var button:Buttons;
    /**
    * The cursor's position relative to the target dimension.
    **/
    public var relativePosition:FastVector2;
    /**
    * The cursor's position relative to the client.
    **/
    public var clientPosition:Vector2;

    public function new() {
        super();
        
    }
    
}