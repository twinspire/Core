package twinspire.events.game;

class SceneChangeEvent extends GameEvent {
    
    public static var id:Id;

    public var fromScene:Int;
    public var toScene:Int;
    public var duration:Float;
    public var animIndex:Int;

    public function new(from:Int, to:Int, duration:Float) {
        if (SceneChangeEvent.id == null) {
            SceneChangeEvent.id = new Id();
        }
        super();

        this.id = SceneChangeEvent.id;
        fromScene = from;
        toScene = to;
        this.duration = duration;
        animIndex = Animate.animateCreateTick();
    }

    /**
    * The callback used to process a scene change. Assign to a function that handles
    * the scene change at the end of each frame.
    *
    * The scene change uses the `Animate` class. Use `Animate.animateGetRatio` to determine
    * the value between scene transitions.
    **/
    public static var process:(SceneChangeEvent) -> Void;

}