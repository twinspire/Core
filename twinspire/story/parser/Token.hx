package twinspire.story.parser;

/**
 * A token in the expression
 */
class Token {
    public var type:TokenType;
    public var value:String;
    public var position:Int;
    
    public function new(type:TokenType, value:String, position:Int) {
        this.type = type;
        this.value = value;
        this.position = position;
    }
    
    public function toString():String {
        return '${type}(${value})@${position}';
    }
}