package twinspire.render;

import twinspire.Application;
import kha.graphics2.Graphics;
import twinspire.render.QueryType;
import twinspire.render.RenderQuery;
import twinspire.geom.Dim;

@:allow(Application)
class GraphicsContext {

    private var _dimTemp:Array<Dim>;
    private var _ended:Bool;

    /**
    * A collection of dimensions within this context. Do not write directly.
    **/
    public var dimensions:Array<Dim>;
    /**
    * A collection of render queries. Do not write directly.
    **/
    public var queries:Array<RenderQuery>;
    /**
    * A collection of activities. Do not write directly.
    **/
    public var activities:Array<Activity>;

    private var _g2:Graphics;
    public var g2(get, default):Graphics;
    function get_g2() return _g2;

    public function new() {
        _dimTemp = [];
        dimensions = [];
        queries = [];
        activities = [];
        _ended = false;
    }

    /**
    * Add a static dimension with the given render type. Static dimensions are not considered to be
    * affected by user input or physics simulations.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    **/
    public function addStatic(dim:Dim, renderType:Id) {
        if (_ended) {
            throw "Cannot add to context once the current frame has ended.";
        }
        
        _dimTemp.push(dim);

        var query = new RenderQuery();
        query.type = QUERY_STATIC;
        query.renderType = renderType;
        queries.push(query);

        activities.push(null);
    }

    /**
    * Add a UI dimension with the given render type. UI dimensions are considered to be
    * affected by user input but not physics simulations.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    **/
    public function addUI(dim:Dim, renderType:Id) {
        if (_ended) {
            throw "Cannot add to context once the current frame has ended.";
        }

        _dimTemp.push(dim);

        var query = new RenderQuery();
        query.type = QUERY_UI;
        query.renderType = renderType;
        queries.push(query);

        activities.push(null);
    }

    /**
    * Add a Sprite dimension with the given render type. Sprite dimensions are considered to be
    * affected physics simulations but not user input.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    **/
    public function addSprite(dim:Dim, renderType:Id) {
        if (_ended) {
            throw "Cannot add to context once the current frame has ended.";
        }

        _dimTemp.push(dim);

        var query = new RenderQuery();
        query.type = QUERY_SPRITE;
        query.renderType = renderType;
        queries.push(query);

        activities.push(null);
    }

    public function begin() {
        _ended = false;
    }

    /**
    * Adds any temporary dimensions previously added in the current frame into permanent storage, refreshing
    * any activities that were also performed on this frame.
    *
    * NOTE: Temporary dimensions added are copied directly into dimensions, overriding any existing dimensions.
    * This happens to mimic scene changes without needing to perform a full re-initialisation. To disable this
    * behaviour, set `noVirtualSceneChange` param to `true`.
    **/
    public function end(noVirtualSceneChange:Bool = false) {
        if (!noVirtualSceneChange) {
            if (_dimTemp.length > 0) {
                dimensions = _dimTemp.copy();
            }
        }
        else {
            for (i in 0..._dimTemp.length) {
                dimensions.push(_dimTemp[i]);
            }
        }
        _dimTemp = [];

        for (i in 0...activities.length) {
            activities[i] = null;
        }

        _ended = true;
    }

}