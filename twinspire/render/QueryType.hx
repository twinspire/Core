package twinspire.render;

enum abstract QueryType(Int) from Int to Int {
    /**
    * A static render operation that is not considered for
    * eventing nor physics.
    **/
    var QUERY_STATIC        =   0;
    /**
    * A render operation that is subject to event simulations,
    * but not subject to physics.
    **/
    var QUERY_UI            =   1;
    /**
    * A render operation that is subject to physics but not
    * event simulations.
    **/
    var QUERY_SPRITE        =   2;
}