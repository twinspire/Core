package twinspire.text.roped;

class Node {
  
    public var leaves:Array<Leaf>;
    public var lastNodeIndex:Int;
    public var nextNodeIndex:Int;
    
    public inline function new() {
        leaves = [];
    }
    
    public inline function getTotalLength():Int {
        var total = 0;
        for (leaf in leaves) {
            total += leaf.length();
        }
        return total;
    }
  
}