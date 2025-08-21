package twinspire.extensions;

import twinspire.geom.Dim;
import kha.Image;

class ImageExtensions {
    
    public static function createDimAt(img:Image, x:Float, y:Float, order:Int = 0) {
        if (img != null) {
            return new Dim(x, y, img.realWidth, img.realHeight, order);
        }

        return null;
    }

}