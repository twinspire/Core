package twinspire.text;

import kha.input.KeyCode;
import kha.math.FastVector2;
import kha.Font;
import twinspire.render.ActivityType;
import twinspire.render.UpdateContext;
import twinspire.render.GraphicsContext;
import twinspire.render.Container;
import twinspire.geom.Dim;
import twinspire.text.edit.Command;
using twinspire.extensions.Graphics2;
import kha.Color;

typedef KeyRepeatInfo = {
    var initialDelay:Float;
    var repeatRate:Float;
    var timeHeld:Float;
    var isRepeating:Bool;
    var lastRepeatTime:Float;
}

class InputRenderer {
    
    public static var RenderId:Id;
    
    public var keyRepeatStates:Map<KeyCode, KeyRepeatInfo>;

    private var gtx:GraphicsContext;
    private var utx:UpdateContext;

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
        keyRepeatStates = new Map<KeyCode, KeyRepeatInfo>();

        this.containerIndex = containerIndex;
        this.inputIndex = inputIndex;

        cursorBlinkTime = 0.5;
        cursorVisible = false;
        cursorColor = Color.White;
        selectionColor = Color.fromFloats(0, .6, .9, .6);
        textColor = Color.White;
    }

    public function update(ctx:UpdateContext) {
        var container:Container = null;
        @:privateAccess(UpdateContext) {
            if (containerIndex < ctx._gctx.containers.length) {
                container = ctx._gctx.containers[containerIndex];
            }
        }

        if (container == null) {
            return;
        }

        ctx.isMouseOver(Direct(container.dimIndex));
        ctx.isMouseReleased(Direct(container.dimIndex));
        ctx.isMouseScrolling(Direct(container.dimIndex));

        var isActive = ctx.getActivatedIndex() == container.dimIndex;
        if (isActive) {
            cursorBlinkTime += UpdateContext.deltaTime;
            if (cursorBlinkTime >= 0.5) {
                cursorVisible = !cursorVisible;
                cursorBlinkTime = 0.0;
            }

            ctx.isDragging(Direct(container.dimIndex));
            if (ctx.isKeyEnter(Direct(container.dimIndex))) {
                cursorVisible = true;
                cursorBlinkTime = 0.0;
            }
            ctx.isKeyDown(Direct(container.dimIndex));
            ctx.isKeyUp(Direct(container.dimIndex));
        }
        else {
            cursorVisible = false;
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
        var dim = gtx.getClientDimensionsAtIndex(Direct(container.dimIndex))[0];
        
        var lineHeight = fontSize * 1.1;
        var select = inputState.inputHandler.sortedSelection();
        var x = dim.x - container.offset.x;
        var y = dim.y - container.offset.y;

        gtx.g2.scissorDim(dim);

        switch (inputState.method) {
            case ImSingleLine: {
                var state = inputState.inputHandler.builder;

                var line = getLineData(inputState, 0);
                if (select.start != select.end && select.end > line.start && select.start < line.end) {
                    var lineSelStart = Math.max(select.start - line.start, 0);
                    var lineSelEnd = Math.min(select.end - line.start, state.length);

                    if (lineSelStart < lineSelEnd) {
                        var selX = x;
                        if (lineSelStart > 0) {
                            selX += font.widthOfCharacters(fontSize, state.getData(), line.start, cast lineSelStart);
                        }

                        var selWidth = font.widthOfCharacters(fontSize, state.getData(), cast lineSelStart, cast (lineSelEnd - lineSelStart));
                        gtx.g2.color = selectionColor;
                        gtx.g2.fillRectDim(new Dim(selX, y, selWidth, lineHeight));
                    }
                }
                
                gtx.g2.color = textColor;
                gtx.g2.font = font;
                gtx.g2.fontSize = fontSize;
                
                if (state.length > 0) {
                    gtx.g2.drawCharacters(state.getData(), 0, state.length, x, y);
                }

                
            }
            case ImMultiLine(breaks): {
                var lineHeight = fontSize * 1.1;

                for (i in 0...breaks.length) {

                }
            }
            case Buffered(buffer): {
                
            }
        }

        if (cursorVisible && inputState.inputHandler.selection[0] == inputState.inputHandler.selection[1]) {
            var cursorPos = inputState.inputHandler.selection[0];
            var cursorCoord = getCursorCoordinates(inputState, cursorPos);
            var cursorHeight = fontSize;
            var cursorY = cursorCoord.y + y + (lineHeight - cursorHeight) / 2;
            gtx.g2.color = cursorColor;
            gtx.g2.fillRect(cursorCoord.x + x, cursorY, 2, cursorHeight);
        }

        gtx.g2.disableScissor();
        
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

        if (!active) {
            container.offset.x = 0;
            container.offset.y = 0;
            return;
        }

        this.gtx = gtx;
        this.utx = utx;

        var keys = utx.getActivity(container.dimIndex, ACTIVITY_KEY_ENTER);
        if (keys != null) {
            for (k in keys) {
                inputState.inputHandler.inputText(Std.string(k));
            }
            updateScroll(inputState);
        }

        handleKeyWithRepeat(KeyCode.Backspace, UpdateContext.deltaTime, () -> {
            inputState.inputHandler.performCommand(Backspace);
            updateLineInfo(inputState);
            updateScroll(inputState);
        });

        handleKeyWithRepeat(KeyCode.Delete, UpdateContext.deltaTime, () -> {
            inputState.inputHandler.performCommand(Delete);
            updateLineInfo(inputState);
            updateScroll(inputState);
        });

        if (inputState.method != ImSingleLine) {
            if (utx.hasActivityData(container.dimIndex, ACTIVITY_KEY_UP, KeyCode.Return)) {
                inputState.inputHandler.performCommand(New_Line);
                updateLineInfo(inputState);
                updateScroll(inputState);
            }
        }

        handleKeyWithRepeat(KeyCode.Left, UpdateContext.deltaTime, () -> {
            if (GlobalEvents.isKeyDown(KeyCode.Shift)) {
                inputState.inputHandler.performCommand(Select_Left);
            }
            else {
                inputState.inputHandler.performCommand(Command.Left);
            }
            cursorVisible = true;
            cursorBlinkTime = 0.0;
            updateScroll(inputState);
        });

        handleKeyWithRepeat(KeyCode.Right, UpdateContext.deltaTime, () -> {
            if (GlobalEvents.isKeyDown(KeyCode.Shift)) {
                inputState.inputHandler.performCommand(Select_Right);
            }
            else {
                inputState.inputHandler.performCommand(Command.Right);
            }
            cursorVisible = true;
            cursorBlinkTime = 0.0;
            updateScroll(inputState);
        });

        if (inputState.method != ImSingleLine) {
            handleKeyWithRepeat(KeyCode.Up, UpdateContext.deltaTime, () -> {
                updateUpDownIndices(inputState);
                if (GlobalEvents.isKeyDown(KeyCode.Shift)) {
                    inputState.inputHandler.performCommand(Select_Up);
                }
                else {
                    inputState.inputHandler.performCommand(Command.Up);
                }
                cursorVisible = true;
                cursorBlinkTime = 0.0;
                updateScroll(inputState);
            });

            handleKeyWithRepeat(KeyCode.Down, UpdateContext.deltaTime, () -> {
                updateUpDownIndices(inputState);
                if (GlobalEvents.isKeyDown(KeyCode.Shift)) {
                    inputState.inputHandler.performCommand(Select_Down);
                }
                else {
                    inputState.inputHandler.performCommand(Command.Down);
                }
                cursorVisible = true;
                cursorBlinkTime = 0.0;
                updateScroll(inputState);
            });
        }

        if (GlobalEvents.isKeyDown(KeyCode.Control)) {
            if (utx.hasActivityData(container.dimIndex, ACTIVITY_KEY_UP, KeyCode.A)) {
                inputState.inputHandler.performCommand(Select_All);
                updateScroll(inputState);
            }
            if (utx.hasActivityData(container.dimIndex, ACTIVITY_KEY_UP, KeyCode.C)) {
                inputState.inputHandler.performCommand(Copy);
            }
            if (utx.hasActivityData(container.dimIndex, ACTIVITY_KEY_UP, KeyCode.X)) {
                inputState.inputHandler.performCommand(Cut);
                updateLineInfo(inputState);
                updateScroll(inputState);
            }
            if (utx.hasActivityData(container.dimIndex, ACTIVITY_KEY_UP, KeyCode.V)) {
                inputState.inputHandler.performCommand(Paste);
                updateLineInfo(inputState);
                updateScroll(inputState);
            }
            if (utx.hasActivityData(container.dimIndex, ACTIVITY_KEY_UP, KeyCode.Z)) {
                inputState.inputHandler.performCommand(Undo);
                updateLineInfo(inputState);
                updateScroll(inputState);
            }
            if (utx.hasActivityData(container.dimIndex, ACTIVITY_KEY_UP, KeyCode.Y)) {
                inputState.inputHandler.performCommand(Redo);
                updateLineInfo(inputState);
                updateScroll(inputState);
            }
        }
    }

    private function updateLineInfo(inputState:TextInputState) {
        var destination = gtx.getClientDimensionsAtIndex(inputState.index.dimIndex)[0];

        switch (inputState.method) {
            case ImMultiLine(breaks): {
                var currentBreaks = new Array<Int>();
                var index = 0;
                var lastChance = -1;
                var lastBreak = 0;
                var characters = inputState.inputHandler.builder.getData();
                while (index < characters.length)
                {
                    var width = font.widthOfCharacters(fontSize, characters, lastBreak, index - lastBreak);
                    if (width >= destination.width)
                    {
                        if (lastChance < 0)
                        {
                            lastChance = index - 1;
                        }
                        currentBreaks.push(lastChance + 1);
                        lastBreak = lastChance + 1;
                        index = lastBreak;
                        lastChance = -1;
                    }

                    if (characters[index] == " ".code)
                    {
                        lastChance = index;
                    }
                    else if (characters[index] == "\n".code || characters[index] == "\r".code)
                    {
                        if (inputState.crlf && characters[index] == "\n".code)
                        {
                            index += 1;
                            continue;
                        }

                        currentBreaks.push(index + 1);
                        lastBreak = index + 1;
                        lastChance = -1;
                    }

                    index += 1;
                }

                breaks = currentBreaks;
            }
            default: {

            }
        }
    }

    private function getCursorCoordinates(inputState:TextInputState, position:Int):FastVector2 {
        var y = 0.0;
        var lineHeight = fontSize * 1.1;

        switch (inputState.method) {
            case ImSingleLine: {
                var x = font.widthOfCharacters(fontSize, inputState.inputHandler.builder.getData(), 0, position);
                return new FastVector2(x, y);
            }
            case ImMultiLine(breaks): {
                var start = 0;
                for (i in 0...breaks.length) {
                    var end = breaks[i];
                    if (i > 0) {
                        start = breaks[i];
                        if (i == breaks.length - 1) {
                            end = inputState.inputHandler.builder.length;
                        }
                        else {
                            end = breaks[i + 1];
                        }
                    }

                    if (position >= start && position <= end) {
                        var x = 0.0;
                        var linePos = position - start;

                        if (linePos > 0 && linePos <= end - start) {
                            x = font.widthOfCharacters(fontSize, inputState.inputHandler.builder.getData(), start, linePos);
                        }

                        return new FastVector2(x, y);
                    }

                    y += lineHeight;
                }
            }
            default: {

            }
        }

        return new FastVector2();
    }

    private function handleKeyWithRepeat(key:KeyCode, deltaTime:Float, action:() -> Void) {
        var dimIndex = gtx.containers[containerIndex].dimIndex;
        if (GlobalEvents.isKeyDown(key)) {
            if (!keyRepeatStates.exists(key)) {
                action();
                var repeat:KeyRepeatInfo = {
                    timeHeld: 0.0,
                    isRepeating: false,
                    initialDelay: 0.5,
                    repeatRate: 0.05,
                    lastRepeatTime: 0.0
                };

                keyRepeatStates.set(key, repeat);
            }
            else {
                var repeatInfo = keyRepeatStates.get(key);
                repeatInfo.timeHeld += deltaTime;
                if (!repeatInfo.isRepeating) {
                    if (repeatInfo.timeHeld >= repeatInfo.initialDelay) {
                        repeatInfo.isRepeating = true;
                        repeatInfo.lastRepeatTime = 0.0;
                        action();
                    }
                }
                else {
                    repeatInfo.lastRepeatTime += deltaTime;
                    if (repeatInfo.lastRepeatTime >= repeatInfo.repeatRate) {
                        repeatInfo.lastRepeatTime = 0.0;
                        action();
                    }
                }
            }
        }
        else if (GlobalEvents.isKeyUp(key, 0)) {
            keyRepeatStates.remove(key);
        }
    }

    private function updateUpDownIndices(inputState:TextInputState) {
        var cursorPos = inputState.inputHandler.selection[0];
        var lineHeight = fontSize * 1.1;

        switch (inputState.method) {
            case ImSingleLine: {
                inputState.inputHandler.upIndex = 0;
                inputState.inputHandler.downIndex = inputState.inputHandler.builder.length - 1;
            }
            case ImMultiLine(breaks): {
                var chars = inputState.inputHandler.builder.getData();

                var start = 0;
                for (i in 0...breaks.length) {
                    var end = breaks[i];
                    if (i > 0) {
                        start = breaks[i];
                        if (i == breaks.length - 1) {
                            end = inputState.inputHandler.builder.length;
                        }
                        else {
                            end = breaks[i + 1];
                        }
                    }

                    if (cursorPos >= start && cursorPos <= end) {
                        var x = 0.0;
                        var linePos = cursorPos - start;

                        if (linePos > 0 && linePos <= end - start) {
                            x = font.widthOfCharacters(fontSize, chars, start, cursorPos);
                        }

                        if (i > 0) {
                            inputState.inputHandler.upIndex = findPositionInLine(inputState, getLineData(inputState, i - 1), x);
                        }
                        else {
                            inputState.inputHandler.upIndex = start;
                        }

                        if (i < breaks.length - 1) {
                            inputState.inputHandler.downIndex = findPositionInLine(inputState, getLineData(inputState, i + 1), x);
                        }
                        else {
                            inputState.inputHandler.downIndex = end;
                        }

                        inputState.inputHandler.lineStart = start;
                        inputState.inputHandler.lineEnd = end;
                        break;
                    }
                }
            }
            default: {

            }
        }
    }

    private function findPositionInLine(inputState:TextInputState, line:{ start: Int, end: Int }, targetX:Float) {
        var length = line.end - line.start;
        if (length <= 0) return line.start;

        var currentX = 0.0;
        for (i in 0...length) {
            if (i > 0) {
                var newX = font.widthOfCharacters(fontSize, inputState.inputHandler.builder.getData(), line.start, i);
                if (newX >= targetX) {
                    if (targetX - currentX < newX - targetX) {
                        return line.start + i - 1;
                    }
                    else {
                        return line.start + i;
                    }
                }
                currentX = newX;
            }
        }

        return line.end;
    }

    private function updateScroll(inputState:TextInputState) {
        var container = gtx.containers[containerIndex];
        var dim = gtx.dimensions[container.dimIndex];
        var cursorCoord = getCursorCoordinates(inputState, inputState.inputHandler.selection[0]);
        var lineHeight = fontSize * 1.1;

        if (cursorCoord.x < container.offset.x) {
            container.offset.x = cursorCoord.x;
        }
        else if (cursorCoord.x - container.offset.x + 10 > dim.width + 10) {
            container.offset.x = cursorCoord.x - dim.width + 10;
        }

        if (cursorCoord.y < container.offset.y) {
            container.offset.y = cursorCoord.y;
        }
        else if (cursorCoord.y - container.offset.y + lineHeight > dim.height) {
            container.offset.y = cursorCoord.y + lineHeight - dim.height;
        }

        container.offset.x = Math.max(0.0, container.offset.x);
        container.offset.y = Math.max(0.0, container.offset.y);
    }

    private function getLineData(inputState:TextInputState, line:Int):{start: Int, end:Int} {
        var start = 0;
        var end = 0;

        switch (inputState.method) {
            case ImSingleLine: {
                start = 0;
                end = inputState.inputHandler.builder.length;
            }
            case ImMultiLine(breaks): {
                if (line < 0 || line >= breaks.length) {
                    return { start: start, end: end };
                }

                if (line > 0) {
                    start = breaks[line];
                }

                if (line + 1 >= breaks.length) {
                    end = inputState.inputHandler.builder.length;
                }
                else {
                    end = breaks[line + 1];
                }
            }
            default: {

            }
        }

        return { start: start, end: end };
    }

}