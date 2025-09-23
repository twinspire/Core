package twinspire.ui.widgets;

import haxe.ds.BalancedTree.TreeNode;
import twinspire.extensions.Graphics2.BorderFlags;
import kha.Color;
import kha.Font;
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
    public var _closeButtonOver:Bool;
    public var _closeButtonRelease:Bool;
    public var _mouseOver:Bool;
    public var _mouseReleased:Bool;

    public var wrapperIndex:DimIndex;
    public var textIndex:DimIndex;
    public var closeButtonIndex:DimIndex;

    // public variables
    public var text:String;
    public var selected:Bool;
    public var showClose:Bool;
    public var style:TabPageStyle;
    public var font:Font;
    public var fontSize:Int;

    // events
    public var onSelected:Array<() -> Void>;
    public var onCloseClicked:Array<() -> Void>;

    public function new() {
        super();

        onSelected = [];
        onCloseClicked = [];
        style = RoundedCorners;
        selected = false;
        showClose = false;
    }

    public static function update(utx:UpdateContext, obj:SceneObject) {
        var casted = cast(obj, TabPage);

        casted._mouseOver = utx.isMouseOver(casted.wrapperIndex, true);
        casted._mouseReleased = utx.isMouseReleased(casted.wrapperIndex, true);

        if (casted.showClose) {
            casted._closeButtonOver = utx.isMouseOver(casted.closeButtonIndex);
            casted._closeButtonRelease = utx.isMouseReleased(casted.closeButtonIndex); // Fixed bug
        }
    }

    public static function render(gtx:GraphicsContext, obj:SceneObject) {
        var casted = cast(obj, TabPage);
        
        // Determine tab colors based on state
        var backColor = casted.selected ? Color.fromFloats(.95, .95, .95) : Color.fromFloats(.85, .85, .85);
        var borderColor = Color.fromFloats(.6, .6, .6);
        
        if (casted._mouseOver && !casted.selected) {
            backColor = Color.fromFloats(.9, .9, .9);
        }
        
        // Render the tab background based on style
        gtx.setColor(backColor);
        
        switch (casted.style) {
            case StraightCorners:
                gtx.fillRect(casted.wrapperIndex);
                gtx.setColor(borderColor);
                gtx.drawBorders(casted.wrapperIndex, 1.0, BORDER_LEFT | BORDER_RIGHT | BORDER_TOP);
                
            case RoundedCorners:
                gtx.fillRoundedRectCorners(casted.wrapperIndex, 6, 6, 0, 0);
                
            case TriangularRight:
                // Draw triangle shape on right side
                var dims = gtx.getClientDimensionsAtIndex(casted.wrapperIndex);
                if (dims[0] != null) {
                    var dim = dims[0];
                    var g2 = gtx.getCurrentGraphics();
                    var triangleWidth = Math.min(dim.height, 15);

                    g2.fillRect(dim.x, dim.y, dim.width - triangleWidth, dim.height);
                    
                    // Create triangular right edge
                    g2.fillTriangle(
                        dim.x + dim.width - triangleWidth, dim.y,
                        dim.x + dim.width, dim.y + dim.height,
                        dim.x + dim.width - triangleWidth, dim.y + dim.height
                    );
                }
                
            case TriangularRightHalf:
                // Draw half triangle shape on right side
                var dims = gtx.getClientDimensionsAtIndex(casted.wrapperIndex);
                if (dims[0] != null) {
                    var dim = dims[0];
                    var g2 = gtx.getCurrentGraphics();
                    var triangleWidth = Math.min(dim.height * 0.25, 8);

                    g2.fillRect(dim.x, dim.y, dim.width - triangleWidth, dim.height);
                    
                    // Create half triangular right edge
                    g2.fillTriangle(
                        dim.x + dim.width - triangleWidth, dim.y,
                        dim.x + dim.width, dim.y + dim.height * 0.25,
                        dim.x + dim.width - triangleWidth, dim.y + dim.height * 0.25
                    );

                    g2.fillRect(dim.x + dim.width - triangleWidth, dim.y + dim.height * 0.25, triangleWidth, dim.height * 0.75);
                }
        }
        
        // Draw the text
        gtx.setColor(Color.Black);
        gtx.setFont(casted.font);
        gtx.setFontSize(casted.fontSize);
        gtx.drawString(casted.textIndex, casted.text);
        
        // Draw close button if enabled
        if (casted.showClose && (casted._mouseOver || casted._closeButtonOver)) {
            var closeColor = casted._closeButtonOver ? Color.fromFloats(.8, .8, .8) : Color.fromFloats(.5, .5, .5);
            var hoveredColor = casted._closeButtonOver ? Color.fromFloats(.1, .1, .1) : Color.Transparent;
            
            var dim = gtx.getClientDimensionsAtIndex(casted.closeButtonIndex);
            gtx.setFontSize(cast dim[0].height);

            if (casted._closeButtonOver) {
                gtx.setColor(hoveredColor);
                gtx.fillCircle(casted.closeButtonIndex);
            }

            gtx.setColor(closeColor);
            // Draw X symbol
            var g2 = gtx.getCurrentGraphics();
            g2.drawString("x", dim[0].x + 5, dim[0].y - 1);
        }
    }

    public static function end(gtx:GraphicsContext, utx:UpdateContext, obj:SceneObject) {
        var casted = cast(obj, TabPage);

        if (casted.showClose && casted._closeButtonRelease && casted.onCloseClicked != null) {
            casted.onCloseClicked.each((cb) -> {
                cb();
                return true;
            });
        }

        if (casted._mouseReleased && !casted._closeButtonRelease) {
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