package twinspire.ui.widgets;

import kha.Color;
import kha.Font;
import twinspire.render.ActivityType;
import twinspire.render.GraphicsContext;
import twinspire.render.UpdateContext;
import twinspire.scenes.SceneObject;
using twinspire.extensions.ArrayExtensions;

class Checkbox extends SceneObject {

    public var text:String;
    public var checked:Bool = false;
    public var textIndex:DimIndex;
    public var boxIndex:DimIndex;
    public var tickIndex:DimIndex;
    public var font:Font;
    public var fontSize:Int;

    public function new() {
        super();
    }

    public static function update(utx:UpdateContext, obj:SceneObject) {
        var casted = cast(obj, Checkbox);
        
        var mouseOver = utx.isMouseOver(obj.index, true);
        var mouseDown = utx.isMouseDown(obj.index, true);
        var mouseReleased = utx.isMouseReleased(obj.index, true);
    }

    public static function render(gtx:GraphicsContext, obj:SceneObject) {
        var casted = cast(obj, Checkbox);
        
        // Draw checkbox box
        gtx.setColor(Color.White);
        gtx.fillRect(casted.boxIndex);
        gtx.setColor(Color.Black);
        gtx.drawRect(casted.boxIndex, 2);
        
        // Draw tick if checked
        if (casted.checked) {
            gtx.setColor(Color.Black);
            gtx.fillRect(casted.tickIndex);
        }
        
        // Draw text
        gtx.setColor(Color.Black);
        gtx.setFont(casted.font);
        gtx.setFontSize(casted.fontSize);
        gtx.drawString(casted.textIndex, casted.text);
    }

    public static function end(gtx:GraphicsContext, utx:UpdateContext, obj:SceneObject) {
        var casted = cast(obj, Checkbox);
        
        // Check for mouse click activities on the group to toggle checked state
        switch (casted.index) {
            case Group(groupIndex, _): {
                var activities = gtx.getActivities(casted.index);
                
                // Use ArrayExtensions.any to check if any activity is a mouse click
                if (activities.any(activityArray -> 
                        activityArray.any(activity -> 
                            activity.type == ACTIVITY_MOUSE_CLICKED)))
                {
                    casted.checked = !casted.checked;
                }
            }
            case _: {
                // Shouldn't happen as checkbox should always be a group
            }
        }
    }
}