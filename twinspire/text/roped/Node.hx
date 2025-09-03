package twinspire.text.roped;

class Node {
  
    public var leaves:Array<Leaf>;
    public var lastNodeIndex:Int;
    public var nextNodeIndex:Int;
    public var totalLength:Int; // Cache total length for this node
    
    public inline function new() {
        leaves = [];
        totalLength = 0;
    }
    
    public function updateTotalLength():Void {
        totalLength = 0;
        for (leaf in leaves) {
            totalLength += leaf.length();
        }
    }
  
}