package twinspire.text;

import twinspire.render.UpdateContext;
import twinspire.render.GraphicsContext;
import twinspire.render.Container;
using twinspire.extensions.Graphics2;
import kha.Color;

class InputRenderer {
    
    public static inline var RenderId:Id = new Id();

    private var containerIndex:Int;
    private var inputIndex:Int;

    private var textColor:Color;
    private var selectionColor:Color;
    private var cursorColor:Color;

    private var cursorBlinkTime:Float;
    private var cursorVisible:Bool;
    


    public function new(containerIndex:Int, inputIndex:Int) {
        this.containerIndex = containerIndex;
        this.inputIndex = inputIndex;
    }

    public function update(ctx:UpdateContext) {
        var container:Container = null;
        @:privateAccess(UpdateContent) {
            container = ctx._gctx.containers[containerIndex];
        }

        ctx.isMouseOver(container.dimIndex);
        ctx.isMouseReleased(container.dimIndex);
        ctx.isMouseScrolling(container.dimIndex);

        if (ctx.getFocusedIndex() == container.dimIndex) {
            ctx.isDragging(container.dimIndex);
            ctx.isKeyEnter(container.dimIndex);
            ctx.isKeyDown(container.dimIndex);
            ctx.isKeyUp(container.dimIndex);
        }
    }

    public function render(gtx:GraphicsContext) {
        var container = gtx.containers[containerIndex];
        var inputState = gtx.textInputs[inputIndex];
        var dim = gtx.getClientDimensionAtIndex(container.dimIndex);
        
        var select = inputState.inputHandler.sortedSelection();
        switch (inputState.method) {
            case ImSingleLine: {
                
            }
            case ImMultiLine(breaks): {
                
            }
            case Buffered(buffer): {
                
            }
        }
    }

    public function end(gtx:GraphicsContext, utx:UpdateContext) {
        
    }

}