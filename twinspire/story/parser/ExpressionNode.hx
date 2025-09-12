package twinspire.story.parser;

/**
 * Expression AST node types
 */
enum ExpressionNode {
    // Literals
    NumberLiteral(value:Float);
    BooleanLiteral(value:Bool);
    StringLiteral(value:String);
    
    // Variables and access
    Variable(name:String);
    PropertyAccess(object:ExpressionNode, property:String);
    CharacterStateAccess(character:String, state:String);
    
    // Binary operations
    BinaryOp(left:ExpressionNode, operator:String, right:ExpressionNode);
    
    // Unary operations
    UnaryOp(operator:String, operand:ExpressionNode);
}