package twinspire.ui.widgets;

import twinspire.DimIndex.DimIndexUtils;
import twinspire.scenes.SceneObject;
import twinspire.render.GraphicsContext;
import twinspire.render.UpdateContext;
import twinspire.render.ActivityType;
import twinspire.Duration;
using twinspire.extensions.ArrayExtensions;

enum TabPageStyle {
    StraightCorners;
    RoundedCorners;
    TriangularRight;
    TriangularRightHalf;
}

class TabPage extends SceneObject {

    // internals
    public var closeButtonOver:Bool;
    public var closeButtonRelease:Bool;
    public var mouseOver:Bool;
    public var mouseReleased:Bool;

    public var wrapperIndex:DimIndex;
    public var textIndex:DimIndex;
    public var closeButtonIndex:DimIndex;

    // public variables
    public var text:String;
    public var selected:Bool;
    public var showClose:Bool;

    // events
    public var onSelected:Array<() -> Void>;
    public var onCloseClicked:Array<() -> Void>;

    public function new() {
        super();

        onSelected = [];
        onCloseClicked = [];
    }

    public static function update(utx:UpdateContext, obj:SceneObject) {
        var casted = cast(obj, TabPage);

        casted.mouseOver = utx.isMouseOver(casted.wrapperIndex, true);
        casted.mouseReleased = utx.isMouseReleased(casted.wrapperIndex, true);

        casted.closeButtonOver = utx.isMouseOver(casted.closeButtonIndex);
        casted.closeButtonRelease = utx.isMouseReleased(casted.closeButtonRelease);
    }

    public static function render(gtx:GraphicsContext, obj:SceneObject) {
        var casted = cast(obj, TabPage);
    }

    public static function end(gtx:GraphicsContext, utx:UpdateContext, obj:SceneObject) {
        var casted = cast(obj, TabPage);

        if (casted.showClose && casted.closeButtonRelease && casted.onCloseClicked != null) {
            casted.onCloseClicked.each((cb) -> {
                cb();
                return true;
            });
        }

        if (casted.mouseReleased) {
            if (!casted.selected) {
                casted.selected = true;
                if (casted.onSelected != null) {
                    casted.onSelected.each((cb) -> {
                        cb();
                        return true;
                    });
                }
            }
        }
    }

}