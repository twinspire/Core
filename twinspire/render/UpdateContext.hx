package twinspire.render;

import twinspire.events.Buttons;
import twinspire.GlobalEvents;
import twinspire.render.GraphicsContext;
import twinspire.render.RenderQuery;
import twinspire.render.QueryType;
import twinspire.geom.Dim;

class UpdateContext {

    private var _gctx:GraphicsContext;

    // UI stuff
    private var _tempUI:Array<Int>;
    private var _mouseFocusIndexUI:Int;
    private var _mouseIsDown:Int;
    private var _mouseIsScrolling:Int;
    private var _mouseScrollValue:Int;
    private var _mouseIsReleased:Int;

    public function new(gctx:GraphicsContext) {
        _gctx = gctx;

        _mouseFocusIndexUI = -1;
    }

    /**
    * Begin update context and start performing event simulations.
    **/
    public function begin() {
        _tempUI = [];
        _mouseFocusIndexUI = -1;

        var mousePos = GlobalEvents.getMousePosition();
        var currentOrder = -1;

        for (i in 0..._gctx.dimensions.length) {
            var query = _gctx.queries[i];
            if (GlobalEvents.isMouseOverDim(_gctx.dimensions[i]) && _gctx.dimensions[i].order > currentOrder
                && query.type == QUERY_UI) {
                _tempUI.push(i);
                currentOrder = _gctx.dimensions[i].order;
            }
        }

        _mouseIsDown = -1;
        var isMouseScrolling = -1;
        var isMouseReleased = -1;
        var isMouseOver = -1;

        var mouseScrollDelta = 0;

        for (i in _tempUI.length...0) {
            var index = _tempUI[i];
            var dim:Dim = _gctx.dimensions[index];
            var query:RenderQuery = _gctx.queries[index];

            isMouseOver = index;

            if (GlobalEvents.isMouseButtonReleased(BUTTON_LEFT)) {
                isMouseUp = index;
                break;
            }

            if (GlobalEvents.isMouseButtonDown(BUTTON_LEFT)) {
                isMouseDown = index;
                break;
            }

            if (GlobalEvents.getMouseDelta() != 0) {
                mouseScrollDelta = GlobalEvents.getMouseDelta();
                isMouseScrolling = index;
                break;
            }
        }

        _mouseFocusIndexUI = isMouseOver;
    }

    /**
    * Checks that the following dimension at the given index is receiving a mouse
    * down event.
    * @param index The index of the dimension to check.
    **/
    public function isMouseDown(index:Int) {
        return _mouseIsDown == index;
    }

    /**
    * Checks that the following dimension at the given index is receiving a mouse
    * released event.
    *
    * @param index The index of the dimension to check.
    **/
    public function isMouseReleased(index:Int) {
        return _mouseIsReleased == index;
    }

    /**
    * Checks that the following dimension at the given index is receiving a mouse
    * scroll event.
    *
    * @param index The index of the dimension to check.
    * @return Returns the value of the scroll. `0` or `MOUSE_SCROLL_NONE` is returned if no scroll event is passed.
    **/
    public function isMouseScrolling(index:Int):Int {
        if (_mouseIsScrolling == index) {
            return _mouseScrollValue;
        }

        return MOUSE_SCROLL_NONE;
    }

    /**
    * End event context and complete the final simulations.
    **/
    public function end() {
        _mouseIsReleased = -1;
        _mouseIsScrolling = -1;
    }

}