package twinspire.scenes;

import twinspire.render.TrackingObject;
using twinspire.extensions.ArrayExtensions;

/**
The Scene class is used for creating simple scenes for scene management.

It uses a collection of `indices` that are used to refer to dimensions added
to the `GraphicsContext`. Use derived versions of this class to construct your scenes.

Requires the tracking object module to be enabled.
**/
class Scene {
    
    /**
    * The scene ID.
    **/
    public var id:Id;
    /**
    * The scene name.
    **/
    public var name:String;
    /**
    * A collection of indices for this scene.
    **/
    public var indices:Array<DimIndex>;

    public function new() {
        indices = [];
    }

    /**
    * Gets the DimIndex from the given `index` and obtain a series
    * of `SceneObject`s that contain queries, input states and containers,
    * if any are related to it.
    **/
    public function getObjectsFromIndex(index:Int) {
        var gtx = Application.instance.graphicsCtx;
        var dimindex = indices[index];

        var results = new Array<SceneObject>();
        switch (dimindex) {
            case Direct(item): {
                results.push({
                    query: gtx.queries[item],
                    container: gtx.containers.find((c) -> c.dimIndex == item),
                    textInput: gtx.textInputs.find((ti) -> ti.index.dimIndex == dimindex)
                });
            }
            case Group(group): {
                for (g in gtx.getDimIndicesAtGroupIndex(group)) {
                    var gindex = gtx.getDimIndexFromInt(g);
                    results.push({
                        query: gtx.queries[g],
                        container: gtx.containers.find((c) -> c.dimIndex == g),
                        textInput: gtx.textInputs.find((ti) -> ti.index.dimIndex == gindex)
                    });
                }
            }
        }
        return results;
    }

}