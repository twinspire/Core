package twinspire.render.vector;

import twinspire.events.Buttons;
import twinspire.geom.Dim;
import twinspire.DimIndex;
import kha.math.FastVector2;

enum VectorSpaceAlignment {
    TopLeft;    // Default - align to top-left
    Center;     // Center both horizontally and vertically
    TopCenter;  // Center horizontally, align to top
    CenterLeft; // Center vertically, align to left
}

class VectorSpace {
    
    private var _bounds:Dim;
    private var _scrollable:Bool;
    private var _scrollButtons:Buttons;
    private var _smoothScrolling:Bool;
    private var _infiniteScroll:Bool = false;
    private var _children:Array<DimIndex>;
    private var _contentBounds:Dim;
    private var _zoom:Float = 1.0;
    private var _translation:FastVector2;
    private var _tessellationCache:Map<String, Array<FastVector2>>;
    private var _isActive:Bool = false;

    // Smooth scrolling properties
    private var _targetTranslation:FastVector2;
    private var _scrollSpeed:Float = 8.0; // Higher = faster scrolling
    private var _scrollThreshold:Float = 0.5; // When to stop smooth scrolling
    private var _isSmoothing:Bool = false;

    private var _alignment:VectorSpaceAlignment = TopLeft;

    public var children(get, never):Array<DimIndex>;
    function get_children():Array<DimIndex> {
        return _children;
    }

    public var translation(get, never):FastVector2;
    public function get_translation():FastVector2 {
        return _translation;
    }

    public var scrollable(get, never):Bool;
    public function get_scrollable():Bool {
        return _scrollable;
    }

    public var scrollButtons(get, never):Buttons;
    function get_scrollButtons():Buttons {
        return _scrollButtons;
    }

    public var zoom(get, set):Float;
    function get_zoom():Float {
        return _zoom;
    }
    function set_zoom(value:Float):Float {
        _zoom = value;
        return _zoom;
    }

    public var isSmoothing(get, never):Bool;
    function get_isSmoothing():Bool {
        return _isSmoothing;
    }
    
    public function new(bounds:Dim) {
        _translation = new FastVector2(0, 0);
        _targetTranslation = new FastVector2(0, 0);
        _tessellationCache = new Map();
        _children = [];
        _contentBounds = new Dim(0, 0, 0, 0); // Initialize with zero bounds
        _bounds = bounds;
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

    public function setAlignment(alignment:VectorSpaceAlignment):VectorSpace {
        _alignment = alignment;
        clampScrolling(); // Reapply clamping with new alignment
        return this;
    }
    
    public function getAlignment():VectorSpaceAlignment {
        return _alignment;
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

    public function setChildren(children:Array<DimIndex>) {
        _children = children.copy();
    }
    
    public function updateContentBounds(bounds:Dim) {
        _contentBounds = bounds;
        clampScrolling();
    }
    
    public function getContentBounds():Dim {
        return _contentBounds;
    }
    
    public function hasChild(index:DimIndex):Bool {
        return _children.contains(index);
    }

    // Container management methods
    public function addChild(index:DimIndex, updateBounds:Bool = true):VectorSpace {
        if (!_children.contains(index)) {
            _children.push(index);
            if (updateBounds) {
                updateContentBounds(_bounds);
            }
        }
        return this;
    }
    
    public function removeChild(index:DimIndex):VectorSpace {
        _children.remove(index);
        updateContentBounds(_bounds);
        return this;
    }
    
    public function addChildren(indices:Array<DimIndex>):VectorSpace {
        for (index in indices) {
            addChild(index, false);
        }
        updateContentBounds(_bounds);
        return this;
    }
    
    // Scrolling configuration
    public function enableScrolling(buttons:Buttons = BUTTON_LEFT, smooth:Bool = false):VectorSpace {
        _scrollable = true;
        _scrollButtons = buttons;
        _smoothScrolling = smooth;
        return this;
    }
    
    public function setInfiniteScroll(infinite:Bool = true):VectorSpace {
        _infiniteScroll = infinite;
        return this;
    }

    public function setScrollSpeed(speed:Float):VectorSpace {
        _scrollSpeed = speed;
        return this;
    }
    
    public function setScrollThreshold(threshold:Float):VectorSpace {
        _scrollThreshold = threshold;
        return this;
    }

    // Immediate scrolling (bypasses smooth scrolling)
    public function scrollToImmediate(x:Float, y:Float):VectorSpace {
        _translation.x = -x;
        _translation.y = -y;
        _targetTranslation.x = _translation.x;
        _targetTranslation.y = _translation.y;
        _isSmoothing = false;
        clampScrolling();
        return this;
    }
    
    public function scrollByImmediate(deltaX:Float, deltaY:Float):VectorSpace {
        _translation.x -= deltaX;
        _translation.y -= deltaY;
        _targetTranslation.x = _translation.x;
        _targetTranslation.y = _translation.y;
        _isSmoothing = false;
        clampScrolling();
        return this;
    }
    
    // Convenient positioning methods
    public function scrollTo(x:Float, y:Float):VectorSpace {
        var newTargetX = -x;
        var newTargetY = -y;
        
        if (_smoothScrolling) {
            _targetTranslation.x = newTargetX;
            _targetTranslation.y = newTargetY;
            clampTargetScrolling();
            
            // Start smoothing if we're not already at the target
            var distanceX = Math.abs(_targetTranslation.x - _translation.x);
            var distanceY = Math.abs(_targetTranslation.y - _translation.y);
            
            if (distanceX > _scrollThreshold || distanceY > _scrollThreshold) {
                _isSmoothing = true;
            }
        } else {
            return scrollToImmediate(x, y);
        }
        
        return this;
    }
    
    public function scrollBy(deltaX:Float, deltaY:Float):VectorSpace {
        if (_smoothScrolling) {
            _targetTranslation.x -= deltaX;
            _targetTranslation.y -= deltaY;
            clampTargetScrolling();
            
            // Start smoothing if we're not already at the target
            var distanceX = Math.abs(_targetTranslation.x - _translation.x);
            var distanceY = Math.abs(_targetTranslation.y - _translation.y);
            
            if (distanceX > _scrollThreshold || distanceY > _scrollThreshold) {
                _isSmoothing = true;
            }
        } else {
            return scrollByImmediate(deltaX, deltaY);
        }
        
        return this;
    }
    
    // Get current scroll position (positive values)
    public function getScrollPosition():FastVector2 {
        return new FastVector2(-_translation.x, -_translation.y);
    }
    
    // Get target scroll position when smooth scrolling
    public function getTargetScrollPosition():FastVector2 {
        return new FastVector2(-_targetTranslation.x, -_targetTranslation.y);
    }
    
    // Update smooth scrolling - should be called every frame
    public function updateScrolling():VectorSpace {
        if (!_isSmoothing || !_smoothScrolling) {
            return this;
        }
        
        var deltaTime = UpdateContext.deltaTime;
        var lerpFactor = Math.min(1.0, _scrollSpeed * deltaTime);
        
        // Interpolate towards target
        var newX = _translation.x + (_targetTranslation.x - _translation.x) * lerpFactor;
        var newY = _translation.y + (_targetTranslation.y - _translation.y) * lerpFactor;
        
        _translation.x = newX;
        _translation.y = newY;
        
        // Check if we're close enough to the target to stop smoothing
        var distanceX = Math.abs(_targetTranslation.x - _translation.x);
        var distanceY = Math.abs(_targetTranslation.y - _translation.y);
        
        if (distanceX <= _scrollThreshold && distanceY <= _scrollThreshold) {
            _translation.x = _targetTranslation.x;
            _translation.y = _targetTranslation.y;
            _isSmoothing = false;
        }
        
        return this;
    }
    
    // Stop smooth scrolling and snap to current position
    public function stopSmoothing():VectorSpace {
        if (_isSmoothing) {
            _targetTranslation.x = _translation.x;
            _targetTranslation.y = _translation.y;
            _isSmoothing = false;
        }
        return this;
    }

    public function getVisibleArea():Dim {
        return new Dim(
            -_translation.x,
            -_translation.y,
            _bounds.width,
            _bounds.height
        );
    }
    
    // Clamp current translation
    private function clampScrolling() {
        if (_infiniteScroll) return;
    
        // Content bounds can now have negative x,y positions
        var contentLeft = _contentBounds.x;
        var contentTop = _contentBounds.y;
        var contentRight = _contentBounds.x + _contentBounds.width;
        var contentBottom = _contentBounds.y + _contentBounds.height;
        
        // Calculate how much we can scroll in each direction
        var maxScrollLeft = Math.max(0, -contentLeft); // How far we can scroll to show negative content
        var maxScrollRight = Math.max(0, contentRight - _bounds.width);
        var maxScrollUp = Math.max(0, -contentTop);
        var maxScrollDown = Math.max(0, contentBottom - _bounds.height);
        
        // Calculate alignment offsets for when content is smaller than container
        var alignmentOffsetX = 0.0;
        var alignmentOffsetY = 0.0;
        
        var totalContentWidth = contentRight - contentLeft;
        var totalContentHeight = contentBottom - contentTop;
        
        if (totalContentWidth < _bounds.width) {
            switch (_alignment) {
                case Center | TopCenter:
                    alignmentOffsetX = (_bounds.width - totalContentWidth) / 2 - contentLeft;
                case TopLeft | CenterLeft:
                    alignmentOffsetX = -contentLeft; // Align content's left edge to container's left
            }
        }
        
        if (totalContentHeight < _bounds.height) {
            switch (_alignment) {
                case Center | CenterLeft:
                    alignmentOffsetY = (_bounds.height - totalContentHeight) / 2 - contentTop;
                case TopLeft | TopCenter:
                    alignmentOffsetY = -contentTop; // Align content's top edge to container's top
            }
        }
        
        // Determine clamping bounds
        var minTranslationX:Float, maxTranslationX:Float;
        var minTranslationY:Float, maxTranslationY:Float;
        
        if (totalContentWidth <= _bounds.width) {
            // Content fits horizontally - fix to alignment position
            minTranslationX = maxTranslationX = alignmentOffsetX;
        } else {
            // Content larger than container - allow scrolling
            // Can scroll left to show negative content, right to show positive content
            minTranslationX = -maxScrollRight;
            maxTranslationX = maxScrollLeft;
        }
        
        if (totalContentHeight <= _bounds.height) {
            // Content fits vertically - fix to alignment position
            minTranslationY = maxTranslationY = alignmentOffsetY;
        } else {
            // Content larger than container - allow scrolling
            minTranslationY = -maxScrollDown;
            maxTranslationY = maxScrollUp;
        }
        
        // Apply clamping
        _translation.x = Math.max(minTranslationX, Math.min(maxTranslationX, _translation.x));
        _translation.y = Math.max(minTranslationY, Math.min(maxTranslationY, _translation.y));
        
        // Also clamp target if we're smoothing
        if (_smoothScrolling) {
            _targetTranslation.x = Math.max(minTranslationX, Math.min(maxTranslationX, _targetTranslation.x));
            _targetTranslation.y = Math.max(minTranslationY, Math.min(maxTranslationY, _targetTranslation.y));
        }
    }
    
    // Clamp target translation
    private function clampTargetScrolling() {
        clampScrolling();
    }

    public function doesContentFit():Bool {
        return _contentBounds.width <= _bounds.width && _contentBounds.height <= _bounds.height;
    }
    
    // Helper methods to check individual axes
    public function doesContentFitHorizontally():Bool {
        return _contentBounds.width <= _bounds.width;
    }
    
    public function doesContentFitVertically():Bool {
        return _contentBounds.height <= _bounds.height;
    }
}