package twinspire.events;

import twinspire.Id;

class GameEvent {
    
    public var id:Id;
    public var data:Array<Dynamic>;

    public function new() {
        data = [];

        if (maximum == 0) {
            if (cast(ExitApp, Int) > maximum) {
                maximum = cast(ExitApp, Int);
            }

            if (cast(MoveDim, Int) > maximum) {
                maximum = cast(MoveDim, Int);
            }

            if (cast(SetDimPosition, Int) > maximum) {
                maximum = cast(SetDimPosition, Int);
            }
        }
    }

    public static var ExitApp:Id;
    public static var MoveDim:Id;
    public static var SetDimPosition:Id;

    public static var coreEventsNum:Int = 3;

    public static var maximum:Int = 0;

    public static function init() {
        ExitApp = Application.createId();
        MoveDim = Application.createId();
        SetDimPosition = Application.createId();
    }

}