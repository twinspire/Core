package twinspire.render.vector;

import kha.math.FastVector2;

class VectorSpace {
    private var _zoom:Float = 1.0;
    private var _translation:FastVector2;
    private var _tessellationCache:Map<String, Array<FastVector2>>;
    private var _isActive:Bool = false;

    public var zoom(get, set):Float;
    public function get_zoom():Float {
        return _zoom;
    }
    public function set_zoom(value:Float):Float {
        _zoom = value;
        return _zoom;
    }
    
    public function new() {
        _translation = new FastVector2(0, 0);
        _tessellationCache = new Map();
    }
    
    public function begin(zoom:Float = 1.0, translation:FastVector2 = null) {
        _zoom = zoom;
        _translation = translation ?? new FastVector2(0, 0);
        _isActive = true;
        
        // Clear cache if zoom changed significantly
        if (Math.abs(zoom - _zoom) > 0.1) {
            _tessellationCache.clear();
        }
    }
    
    public function end() {
        _isActive = false;
    }
    
    public function isActive():Bool {
        return _isActive;
    }
    
    public function transformPoint(x:Float, y:Float):FastVector2 {
        return new FastVector2(
            (x + _translation.x) * _zoom,
            (y + _translation.y) * _zoom
        );
    }
    
    public function transformDistance(distance:Float):Float {
        return distance * _zoom;
    }
    
    public function getOptimalSegments(pathLength:Float):Int {
        var baseSegments = Math.ceil(pathLength / 10);
        var zoomFactor = Math.max(1.0, _zoom * 0.5);
        return Math.floor(Math.min(baseSegments * zoomFactor, 200));
    }
    
    public function getCacheKey(identifier:String):String {
        return '${identifier}_${Math.floor(_zoom * 10) / 10}';
    }
    
    public function getCachedPath(key:String):Array<FastVector2> {
        return _tessellationCache.get(key);
    }
    
    public function setCachedPath(key:String, points:Array<FastVector2>) {
        _tessellationCache.set(key, points);
    }
}