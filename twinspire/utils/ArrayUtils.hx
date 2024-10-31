package twinspire.utils;

class ArrayUtils {

    public static function clearFromTemp(arr:Array<Dynamic>, indices:Array<Int>) {
        var index = indices.length - 1;
        while (index > -1) {
            arr.splice(indices[index--], 1);
        }
    }

}