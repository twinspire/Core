package twinspire.scenes;

import twinspire.text.TextInputState;
import twinspire.render.Container;
import twinspire.render.RenderQuery;

typedef SceneObject = {
    /**
    * The query of this object.
    **/
    var query:RenderQuery;
    /**
    * The container of this object, if any.
    **/
    var ?container:Container;
    /**
    * The text input state of this object, if any.
    **/
    var ?textInput:TextInputState;
}