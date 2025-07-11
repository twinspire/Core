package twinspire;

import twinspire.Id;

enum DimIndex {
    /**
    * Specifies to obtain a direct index from the main dimension stack.
    **/
    Direct(index:Int, ?render:Id);
    /**
    * Specifies to obtain a group index from the dimension groups.
    **/
    Group(index:Int, ?render:Id);
}

class DimIndexUtils {

    public static inline function getDirectIndex(index:DimIndex) {
        return switch (index) {
            case Direct(item): item;
            case Group(item): Application.instance.graphicsCtx.getLastDimIndexAtGroup(item);
        }
    }

    public static inline function getDirectIndexOrThrow(index:DimIndex) {
        return switch (index) {
            case Direct(item): item;
            default: {
                throw "No Direct index found.";
            }
        }
    }

}