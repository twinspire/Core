package twinspire.text.roped;

class Node {
  
    public var leaves:Array<Leaf>;
    // refers to root level last node index before this node
    public var lastNodeIndex:Int;
    // refers to root level next node index after this node
    public var nextNodeIndex:Int;
    // refers to root level node collection for indices
    public var childNodeRanges:Array<{last:Int, next:Int}>;
    
    public inline function new() {
        leaves = [];
        lastNodeIndex = -1;
        nextNodeIndex = -1;
        childNodeRanges = [];
    }
  
}