package twinspire.scenes;

import twinspire.render.UpdateContext;
import twinspire.render.GraphicsContext;

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
    * A collection of objects for this scene.
    **/
    public var objects:Array<SceneObject>;

    public function new() {
        objects = [];
    }

    /**
    * Adds an object to the scene. You can optionally invoke initialisation
    * if this subject object hasn't been initialised yet.
    *
    * @param obj The scene object to add.
    * @param needsInit (Optional) A value determining whether to invoke initialisation.
    **/
    public function addObject(obj:SceneObject, needsInit:Bool = false) {
        var result = obj;
        var gtx = Application.instance.graphicsCtx;
        if (needsInit) {
            switch (obj.index) {
                case Direct(index, render) | Group(index, render): {
                    if (render != null) {
                        result = IdAssoc.assoc[render].init(gtx, obj);
                    }
                }
            }
        }

        objects.push(result);
    }

    /**
    * Gets an objects exact integers in the dimension stack of the `GraphicsContext`.
    *
    * @param index The object index to look in.
    **/
    public function getObjectDimInt(index:Int) {
        var results = new Array<Int>();
        if (index < 0 || index > objects.length - 1) {
            results.push(null);
            return results;
        }
        
        var gtx = Application.instance.graphicsCtx;

        if (!gtx.isDimIndexValid(objects[index].index)) {
            results.push(null);
            return results;
        }

        switch (objects[index].index) {
            case Direct(index, render): {
                results.push(index);
            }
            case Group(index, render): {
                results = gtx.getDimIndicesAtGroupIndex(index);
            }
        }

        return results;
    }

    // hide dimensions in the dimension stack
    public function hideObjects() {
        var gtx = Application.instance.graphicsCtx;
        for (o in objects) {
            gtx.activateDimensions([ o.index ], false);
            for (dim in gtx.getDimensionsAtIndex(o.index)) {
                dim.visible = true;
            };
        }
    }

    // show dimensions in the dimension stack
    public function showObjects() {
        var gtx = Application.instance.graphicsCtx;
        for (o in objects) {
            gtx.activateDimensions([ o.index ], true);
            for (dim in gtx.getDimensionsAtIndex(o.index)) {
                dim.visible = true;
            };
        }
    }

    /**
    * Gets a collection of indices from all the objects in this scene.
    **/
    public function getObjectIndices() {
        var indices = new Array<DimIndex>();
        var gtx = Application.instance.graphicsCtx;
        for (o in objects) {
            if (gtx.isDimIndexValid(o.index)) {
                indices.push(o.index);
            }
        }
        return indices;
    }

    /**
    * Remove an object at the given index. Does not remove any active dimensions
    * in the dimension stack. Use `gtx.removeIndex` to remove the objects' state
    * in the dimension stack before removing it from the scene.
    **/
    public function removeObjectAt(index:Int) {
        if (index < 0 || index > objects.length - 1) {
            return;
        }

        objects.splice(index, 1);
    }

    /**
    * Initialise this scene with starting objects.
    **/
    public function init(gtx:GraphicsContext, objects:Array<SceneObject>) {
        this.objects = [];
        for (o in objects) {
            if (o.type != null) {
                this.objects.push(o);
            }
        }

        for (o in this.objects) {
            IdAssoc.assoc[o.type].init(gtx, o);
        }
    }

    /**
    * Update the scene.
    **/
    public function update(utx:UpdateContext) {
        var gtx = Application.instance.graphicsCtx;

        for (o in objects) {
            if (!gtx.isDimIndexValid(o.index)) {
                continue;
            }

            switch (o.index) {
                case Direct(index, render) | Group(index, render): {
                    if (render != null) {
                        IdAssoc.assoc[render].update(utx, o);
                    }
                }
            }
        }
    }

    /**
    * Render the scene.
    **/
    public function render(gtx:GraphicsContext) {
        for (o in objects) {
            if (!gtx.isDimIndexValid(o.index)) {
                continue;
            }

            switch (o.index) {
                case Direct(index, render) | Group(index, render): {
                    if (render != null) {
                        IdAssoc.assoc[render].render(gtx, o);
                    }
                }
            }
        }
    }

    /**
    * End the scene.
    **/
    public function end(gtx:GraphicsContext, utx:UpdateContext) {
        for (o in objects) {
            if (!gtx.isDimIndexValid(o.index)) {
                continue;
            }

            switch (o.index) {
                case Direct(index, render) | Group(index, render): {
                    if (render != null) {
                        IdAssoc.assoc[render].end(gtx, utx, o);
                    }
                }
            }
        }
    }

}