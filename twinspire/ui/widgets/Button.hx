package twinspire.ui.widgets;

import kha.Color;
import kha.Font;
import twinspire.render.GraphicsContext;
import twinspire.render.UpdateContext;
import twinspire.scenes.SceneObject;

class Button extends SceneObject {

    private var _mouseOver:Bool;
    private var _mouseDown:Bool;
    private var _mouseReleased:Bool;
    
    public var text:String;
    public var textIndex:DimIndex;
    public var wrapperIndex:DimIndex;
    public var font:Font;
    public var fontSize:Int;

    public function new() {
        super();
    }

    public static function update(utx:UpdateContext, obj:SceneObject) {
        var casted = cast(obj, Button);
        
        casted._mouseOver = utx.isMouseOver(obj.index, true);
        casted._mouseDown = utx.isMouseDown(obj.index, true);
        casted._mouseReleased = utx.isMouseReleased(obj.index, true);
    }

    public static function render(gtx:GraphicsContext, obj:SceneObject) {
        var casted = cast(obj, Button);
        var backColor = Color.fromFloats(.9, .9, .9);
        if (casted._mouseDown) {
            backColor = Color.fromFloats(.8, .8, .8);
        }
        else if (casted._mouseOver) {
            backColor = Color.fromFloats(.95, .95, .95);
        }

        gtx.setColor(backColor);
        gtx.fillRoundedRect(casted.wrapperIndex, 6);
        gtx.setColor(Color.Black);
        gtx.setFont(casted.font);
        gtx.setFontSize(casted.fontSize);
        gtx.drawString(casted.textIndex, casted.text);
    }

    public static function end(gtx:GraphicsContext, utx:UpdateContext, obj:SceneObject) {
        
    }

}