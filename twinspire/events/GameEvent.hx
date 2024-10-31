package twinspire.events;

import twinspire.Id;

class GameEvent {
    
    public var id:Id;
    public var data:Array<Dynamic>;

    public function new() {
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

        data = [];
    }

    public static var ExitApp:Id = new Id();
    public static var MoveDim:Id = new Id();
    public static var SetDimPosition:Id = new Id();

    public static var coreEventsNum:Int = 3;

    public static var maximum:Int = 0;

}