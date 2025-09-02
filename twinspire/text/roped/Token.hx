package twinspire.text.roped;

class Token {
  
    public var type:Int;
    public var start:Int;
    public var end:Int;
    
    public inline function new(type:Int, start:Int, end:Int) {
      this.start = start;
      this.end = end;
      this.type = type;
    }
  
}