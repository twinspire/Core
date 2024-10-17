package twinspire.render;

class RenderQuery {

    /**
    * Specifies the type of query.
    **/
    public var type:Int;
    /**
    * A unique identifier used to determine what is rendered.
    **/
    public var renderType:Id;
    /**
    * A value defining that the dimension this query relates to accepts text input.
    **/
    public var acceptsTextInput:Bool;
    /**
    * A value defining that the dimension this query relates to accepts key input.
    **/
    public var acceptsKeyInput:Bool;
    
    public function new() {
        acceptsKeyInput = false;
        acceptsTextInput = false;
        
    }

}