package twinspire.scenes;

import twinspire.geom.Dim;

/**
* The base class for objects to contain custom data related to
* a render state.
**/
class SceneObject {

    /**
    * The render type.
    **/
    public var type:Id;
    /**
    * The resulting index for this object.
    **/
    public var index:DimIndex;
    /**
    * The initial target container when this object is first created.
    **/
    public var targetContainer:Dim;
    /**
    * The dimension of this object when it was last changed.
    **/
    public var lastChangedDim:Dim;
    
    public function new() {

    }

}