package twinspire.text;

import twinspire.render.GraphicsContext.TextInputResult;
import twinspire.text.edit.InputState;
import twinspire.render.GraphicsContext.ContainerResult;

class TextInputState {
    
    /**
    * The method for rendering the underlying text state.
    **/
    public var method:TextInputMethod;
    /**
    * The input renderer used for rendering the input state.
    **/
    public var inputRenderer:InputRenderer;
    /**
    * A value determining if this input state is currently active.
    **/
    public var inputActive:Bool;
    /**
    * The associated dimension and container index to which this input state belongs.
    **/
    public var index:ContainerResult;
    /**
    * The handler used to manage and obtain input text data.
    **/
    public var inputHandler:InputState;

    public function new() {

    }

    public function setup(index:TextInputResult, method:TextInputMethod) {
        this.index = index;
        this.method = method;

        inputRenderer = new InputRenderer(index.containerIndex, index.textInputIndex);
        inputHandler = new InputState();
    }

}