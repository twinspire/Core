package twinspire.story.parser;

/**
 * Token types for expression parsing
 */
enum TokenType {
    IDENTIFIER;     // alice_met, tools_found
    NUMBER;         // 3, 0.5, 42
    BOOLEAN;        // true, false
    STRING;         // "text"
    
    // Operators
    AND;            // &&
    OR;             // ||
    NOT;            // !
    
    // Comparisons
    EQUALS;         // ==
    NOT_EQUALS;     // !=
    GREATER;        // >
    GREATER_EQUAL;  // >=
    LESS;           // <
    LESS_EQUAL;     // <=
    
    // Punctuation
    LPAREN;         // (
    RPAREN;         // )
    DOT;            // .
    LBRACKET;       // [
    RBRACKET;       // ]
    
    EOF;            // End of input
    INVALID;        // Error token
}