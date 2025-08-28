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

    public static function equals(a:DimIndex, b:DimIndex) {
        var gtx = Application.instance.graphicsCtx;

        switch [a, b] {
            case [ Direct(aResult), Direct(bResult) ]: {
                return aResult == bResult;
            }
            case [ Direct(_), Group(_) ]: {
                return false;
            }
            case [ Group(aResult), Direct(bResult) ]: {
                var children = @:privateAccess(GraphicsContext) gtx._groups[aResult];
                return children.contains(bResult);
            }
            case [ Group(aResult), Group(bResult) ]: {
                return aResult == bResult;
            }
        }

        return false;
    }

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