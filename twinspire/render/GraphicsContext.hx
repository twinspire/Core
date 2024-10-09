package twinspire.render;

import twinspire.Application;
import kha.graphics2.Graphics;
import twinspire.render.QueryType;
import twinspire.render.RenderQuery;
import twinspire.geom.Dim;

@:allow(Application)
class GraphicsContext {

    private var _dimTemp:Array<Dim>;

    /**
    * A collection of dimensions within this context. Do not write directly.
    **/
    public var dimensions:Array<Dim>;
    /**
    * A collection of render queries. Do not write directly.
    **/
    public var queries:Array<RenderQuery>;

    private var _g2:Graphics;
    public var g2(get, default):Graphics;
    function get_g2() return _g2;

    public function new() {
        _dimTemp = [];
        dimensions = [];
        queries = [];
    }

    /**
    * Add a static dimension with the given render type. Static dimensions are not considered to be
    * affected by user input or physics simulations.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    **/
    public function addStatic(dim:Dim, renderType:Int) {
        _dimTemp.push(dim);

        var query = new RenderQuery();
        query.type = QUERY_STATIC;
        query.renderType = renderType;
        queries.push(query);
    }

    /**
    * Add a UI dimension with the given render type. UI dimensions are considered to be
    * affected by user input but not physics simulations.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    **/
    public function addUI(dim:Dim, renderType:Int) {
        _dimTemp.push(dim);

        var query = new RenderQuery();
        query.type = QUERY_UI;
        query.renderType = renderType;
        queries.push(query);
    }

    /**
    * Add a Sprite dimension with the given render type. Sprite dimensions are considered to be
    * affected physics simulations but not user input.
    *
    * @param dim The dimension.
    * @param renderType An integer used to determine what is rendered.
    **/
    public function addSprite(dim:Dim, renderType:Int) {
        _dimTemp.push(dim);

        var query = new RenderQuery();
        query.type = QUERY_SPRITE;
        query.renderType = renderType;
        queries.push(query);
    }

    /**
    * Adds any temporary dimensions previously added in the current frame into permanent storage.
    **/
    public function end() {
        dimensions = _dimTemp.copy();
        _dimTemp = [];
    }

}