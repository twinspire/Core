package twinspire.text;

import kha.Font;
import twinspire.render.ActivityType;
import twinspire.render.UpdateContext;
import twinspire.render.GraphicsContext;
import twinspire.render.Container;
using twinspire.extensions.Graphics2;
import kha.Color;

class InputRenderer {
    
    public static var RenderId:Id = new Id();

    private var containerIndex:Int;
    private var inputIndex:Int;

    public var textColor:Color;
    public var selectionColor:Color;
    public var cursorColor:Color;
    public var font:Font;
    public var fontSize:Int;

    public var cursorBlinkTime:Float;
    public var cursorVisible:Bool;

    private var mouseIsOver:Bool;
    private var active:Bool;


    public function new(containerIndex:Int, inputIndex:Int) {
        trace(containerIndex);
        this.containerIndex = containerIndex;
        this.inputIndex = inputIndex;

        cursorBlinkTime = 0.5;
        cursorVisible = false;
        textColor = Color.White;
    }

    public function update(ctx:UpdateContext) {
        var container:Container = null;
        @:privateAccess(UpdateContent) {
            if (containerIndex < ctx._gctx.containers.length) {
                container = ctx._gctx.containers[containerIndex];
            }
        }

        if (container == null) {
            return;
        }

        ctx.isMouseOver(container.dimIndex);
        ctx.isMouseReleased(container.dimIndex);
        ctx.isMouseScrolling(container.dimIndex);

        var isActive = ctx.getActivatedIndex() == container.dimIndex;
        if (isActive) {
            ctx.isDragging(container.dimIndex);
            ctx.isKeyEnter(container.dimIndex);
            ctx.isKeyDown(container.dimIndex);
            ctx.isKeyUp(container.dimIndex);
        }
    }

    public function render(gtx:GraphicsContext) {
        if (containerIndex >= gtx.containers.length) {
            return;
        }

        if (inputIndex >= gtx.textInputs.length) {
            return;
        }

        var container = gtx.containers[containerIndex];
        var inputState = gtx.textInputs[inputIndex];
        var dim = gtx.getClientDimensionAtIndex(container.dimIndex);
        
        var select = inputState.inputHandler.sortedSelection();
        switch (inputState.method) {
            case ImSingleLine: {
                gtx.g2.scissorDim(dim);
                gtx.g2.color = textColor;
                gtx.g2.font = font;
                gtx.g2.fontSize = fontSize;
                var state = inputState.inputHandler.builder;
                if (state.length > 0) {
                    gtx.g2.drawCharacters(state.getData(), 0, state.length, dim.x, dim.y);
                }

                gtx.g2.disableScissor();
            }
            case ImMultiLine(breaks): {
                
            }
            case Buffered(buffer): {
                
            }
        }

        
    }

    public function end(gtx:GraphicsContext, utx:UpdateContext) {
        if (containerIndex >= gtx.containers.length) {
            return;
        }

        if (inputIndex >= gtx.textInputs.length) {
            return;
        }

        var container = gtx.containers[containerIndex];
        var inputState = gtx.textInputs[inputIndex];

        active = utx.getActivatedIndex() == container.dimIndex;
        mouseIsOver = false;
        for (a in gtx.activities[container.dimIndex]) {
            if (a.type == ActivityType.ACTIVITY_MOUSE_OVER) {
                mouseIsOver = true;
            }
            else if (a.type == ACTIVITY_KEY_ENTER) {
                var select = inputState.inputHandler.sortedSelection();
                var str = "";
                for (s in a.data) {
                    str += Std.string(s);
                }
                inputState.inputHandler.insertAt(select.start, str);
                inputState.inputHandler.moveTo(Right);
            }
            
        }
    }

}