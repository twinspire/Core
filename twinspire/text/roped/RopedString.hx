package twinspire.text.roped;

class RopedString {
  
    private var tokens:Array<Token>;
  
    /**
     * A collection of nodes representing chunks of text.
     */
    public var nodes:Array<Node>;
    
    /**
     * A callback function that is called each time a value is appended to this string.
     * The resulting string is passed vianthe first parameter, allowing you to check the value.
     * Return `true` in `tokenize` to reset the string and a numeric value `type` to specify a user-defined token, stored internally.
     */
    public var tokenCallback:(String) -> { tokenize: Bool, type: Int };
    
    public function new() {
        nodes = [];
    }
    
    public function getLines(limit:Int = 100, startPos:Int = 0):Array<{data:Array<Int>, nextNodeStart:Int}> {
      
    }
    
    public function getLine(line:Int):Array<Int> {
      
    }
    
    public function findInLine(line:Int, chars:Array<Int>):Int {
      
    }
    
    public function find(chars:Array<Int>):Int {
      
    }
    
    public function findNextToken(type:Int):String {
      
    }
    
    public function findInTokenRange(startType:Int, endType:Int, chars:Array<Int>):Int {
      
    }
    
    public function insert(char:Int, pos:Int) {
      
    }
    
    public function insertToken(char:Int, token:Int, pos:Int) {
      
    }
    
    public function getTokenId(type:Int):String {
      
    }
    
    public function getTokensInRange(startType:Int, endType:Int):Array<String> {
      
    }
    
    public function removeAt(pos:Int) {
      
    }
    
    public function removeRange(start:Int, end:Int) {
      
    }
    
    public function removeToken(type:Int, ?upto:Int) {
      
    }
    
    public function removeTokenRange(startType:Int, endType:Int) {
      
    }
    
    private function findNodeLeafFromPosition(pos:Int):{node:Int, leaf:Int} {
      
    }
    
    
  
}