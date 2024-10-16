package twinspire.events;

import twinspire.Id;

class GameEvent {
    
    public var id:Id;
    public var data:Array<Dynamic>;

    public function new() {
        data = [];
    }

    public static var ExitApp:Id = new Id();
    public static var MoveDim:Id = new Id();
    public static var SetDimPosition:Id = new Id();

}