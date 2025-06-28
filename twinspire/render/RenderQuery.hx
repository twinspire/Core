package twinspire.render;

import twinspire.render.DragOptions;

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
    /**
    * Allows this dimension to be dragged with the mouse.
    **/
    public var allowDragging:Bool;
    /**
    * Add options for dragging this query.
    **/
    public var dragOptions:DragOptions;
    
    public function new() {
        acceptsKeyInput = false;
        acceptsTextInput = false;
        allowDragging = false;
        
        dragOptions = new DragOptions();
    }

    public function clone() {
        var result = new RenderQuery();
        result.acceptsKeyInput = acceptsKeyInput;
        result.acceptsTextInput = acceptsTextInput;
        result.allowDragging = allowDragging;
        result.dragOptions = dragOptions;
        result.renderType = renderType;
        result.type = type;
        return result;
    }

}