package twinspire.render;

class ComplexResult {

    private var _gtx:GraphicsContext;
    
    public var indices:Array<DimIndex>;

    public var containerIndices:Array<Int>;

    public var textInputIndices:Array<Int>;

    public function new(gtx:GraphicsContext) {
        _gtx = gtx;

        indices = [];
        containerIndices = [];
        textInputIndices = [];
    }

    /**
    * Define a group within the index results, returning the group index.
    **/
    public function defineGroups() {

    }

    

}