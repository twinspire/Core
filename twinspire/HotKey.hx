package twinspire;

import kha.input.KeyCode;

enum abstract KeyInfoType(Int) {
    var Keyboard;
    var Gamepad;
    var OnScreenKey;
}

typedef KeyInfo = {
    var ?modifiers:Array<KeyInfo>;
    var button:Int;
    var type:KeyInfoType;
}

class HotKey {
    
    /**
    * The name that this hotkey represents.
    **/
    public var name:String;
    /**
    * The possible keys that can activate this hot key.
    **/
    public var keys:Array<KeyInfo>;
    /**
    * The callback function to execute when this hot key is activated.
    **/
    public var action:(DimIndex) -> Void;

    public function new() {
        name = "";
        keys = [];
        action = null;
    }

}