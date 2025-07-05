package twinspire;

import twinspire.render.UpdateContext;
import twinspire.render.GraphicsContext;

interface ISceneManager {
    function init(ctx:GraphicsContext):Void;
    function resize():Void;
    function render(ctx:GraphicsContext):Void;
    function update(ctx:UpdateContext):Void;
    function end(gtx:GraphicsContext, utx:UpdateContext):Void;
}