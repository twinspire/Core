package twinspire.render.particles;

import twinspire.render.GraphicsContext;

class Engine {
    
    public var emitters:Array<Emitter>;

    public function new() {
        emitters = [];
    }

    public function addEmitter(emitter:Emitter):Int {
        return emitters.push(emitter) - 1;
    }

    public function removeEmitter(index:Int):Void {
        if (index >= 0 && index < emitters.length) {
            emitters.splice(index, 1);
        }
    }

    public function update(deltaTime:Float):Void {
        for (emitter in emitters) {
            emitter.update(deltaTime);
        }
    }

    public function render(gtx:GraphicsContext):Void {
        for (emitter in emitters) {
            emitter.render(gtx);
        }
    }

    static var _instance:Engine;
    public static var instance(get, never):Engine;
    static function get_instance():Engine {
        if (_instance == null) {
            _instance = new Engine();
        }
        return _instance;
    }

}