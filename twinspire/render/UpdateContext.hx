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

        var isMouseDown = -1;
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
    * End event context and complete the final simulations.
    **/
    public function end() {

    }

}