package twinspire.events;

class DimEventBindings {

    private var _options:DimBindingOptions;

    public var onClick(get, set):(EventArgs) -> Void;
    function get_onClick() return _options.onClick;
    function set_onClick(val) return _options.onClick = val;

    public var onMouseOver(get, set):(EventArgs) -> Void;
    function get_onMouseOver() return _options.onMouseOver;
    function set_onMouseOver(val) return _options.onMouseOver = val;

    public var onMouseDown(get, set):(EventArgs) -> Void;
    function get_onMouseDown() return _options.onMouseDown;
    function set_onMouseDown(val) return _options.onMouseDown = val;

    public var onBeginDrag(get, set):(EventArgs) -> Void;
    function get_onBeginDrag() return _options.onBeginDrag;
    function set_onBeginDrag(val) return _options.onBeginDrag = val;

    public var onEndDrag(get, set):(EventArgs) -> Void;
    function get_onEndDrag() return _options.onEndDrag;
    function set_onEndDrag(val) return _options.onEndDrag = val;

    public var onDragging(get, set):(EventArgs) -> Void;
    function get_onDragging() return _options.onDragging;
    function set_onDragging(val) return _options.onDragging = val;

    public var onKeyUp(get, set):(EventArgs) -> Void;
    function get_onKeyUp() return _options.onKeyUp;
    function set_onKeyUp(val) return _options.onKeyUp = val;

    public var onKeyDown(get, set):(EventArgs) -> Void;
    function get_onKeyDown() return _options.onKeyDown;
    function set_onKeyDown(val) return _options.onKeyDown = val;

    public var onKeyPress(get, set):(EventArgs) -> Void;
    function get_onKeyPress() return _options.onKeyDown;
    function set_onKeyPress(val) return _options.onKeyDown = val;

    public var togglePath(get, set):String;
    function get_togglePath() return _options.togglePath;
    function set_togglePath(val) return _options.togglePath = val;

    public function new(options:DimBindingOptions) {
        _options = options;
    }
    
}