package twinspire.render;

import twinspire.render.QueryType;
import twinspire.render.RenderQuery;
import twinspire.geom.Dim;

class GraphicsContext {

    /**
    * A collection of dimensions within this context. Do not write directly.
    **/
    public var dimensions:Array<Dim>;
    /**
    * A collection of render queries. Do not write directly.
    **/
    public var queries:Array<RenderQuery>;

    public function new() {
        dimensions = [];
        queries = [];
    }

    public function addStatic(dim:Dim, renderType:Int) {
        dimensions.push(dim);

        var query = new RenderQuery();
        query.type = QUERY_STATIC;
        query.renderType = renderType;
        queries.push(query);
    }

    public function addUI(dim:Dim, renderType:Int) {
        dimensions.push(dim);

        var query = new RenderQuery();
        query.type = QUERY_UI;
        query.renderType = renderType;
        queries.push(query);
    }

    public function addSprite(dim:Dim, renderType:Int) {
        dimensions.push(dim);

        var query = new RenderQuery();
        query.type = QUERY_SPRITE;
        query.renderType = renderType;
        queries.push(query);
    }

}