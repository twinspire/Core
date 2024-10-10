package twinspire.render;

class Activity {

    /**
    * The type of activity.
    **/
    public var type:Int;
    /**
    * The data (if any) associated with the activity.
    **/
    public var data:Array<Dynamic>;

    public function new() {
        type = 0;
        data = [];
    }

}