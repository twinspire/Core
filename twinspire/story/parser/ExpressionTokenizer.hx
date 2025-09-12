package twinspire.story.parser;

/**
 * Tokenizes expression strings into tokens
 */
class ExpressionTokenizer {
    private var input:String;
    private var position:Int;
    private var currentChar:String;
    
    public function new() {}
    
    public function tokenize(input:String):Array<Token> {
        this.input = input;
        this.position = 0;
        this.currentChar = position < input.length ? input.charAt(position) : "";
        
        var tokens:Array<Token> = [];
        
        while (position < input.length) {
            skipWhitespace();
            
            if (currentChar == "") break;
            
            var token = nextToken();
            if (token.type == INVALID) {
                throw 'Invalid token "${token.value}" at position ${token.position}';
            }
            
            tokens.push(token);
        }
        
        tokens.push(new Token(EOF, "", position));
        return tokens;
    }
    
    private function nextToken():Token {
        var startPos = position;
        
        // Numbers
        if (isDigit(currentChar)) {
            return readNumber();
        }
        
        // Identifiers and keywords
        if (isAlpha(currentChar) || currentChar == "_") {
            return readIdentifier();
        }
        
        // Strings
        if (currentChar == '"') {
            return readString();
        }
        
        // Two-character operators
        if (position + 1 < input.length) {
            var twoChar = currentChar + input.charAt(position + 1);
            switch (twoChar) {
                case "&&": advance(); advance(); return new Token(AND, "&&", startPos);
                case "||": advance(); advance(); return new Token(OR, "||", startPos);
                case "==": advance(); advance(); return new Token(EQUALS, "==", startPos);
                case "!=": advance(); advance(); return new Token(NOT_EQUALS, "!=", startPos);
                case ">=": advance(); advance(); return new Token(GREATER_EQUAL, ">=", startPos);
                case "<=": advance(); advance(); return new Token(LESS_EQUAL, "<=", startPos);
            }
        }
        
        // Single-character operators
        switch (currentChar) {
            case "(": advance(); return new Token(LPAREN, "(", startPos);
            case ")": advance(); return new Token(RPAREN, ")", startPos);
            case "[": advance(); return new Token(LBRACKET, "[", startPos);
            case "]": advance(); return new Token(RBRACKET, "]", startPos);
            case ".": advance(); return new Token(DOT, ".", startPos);
            case "!": advance(); return new Token(NOT, "!", startPos);
            case ">": advance(); return new Token(GREATER, ">", startPos);
            case "<": advance(); return new Token(LESS, "<", startPos);
        }
        
        // Invalid character
        var invalidChar = currentChar;
        advance();
        return new Token(INVALID, invalidChar, startPos);
    }
    
    private function readNumber():Token {
        var startPos = position;
        var value = "";
        
        while (isDigit(currentChar)) {
            value += currentChar;
            advance();
        }
        
        // Handle decimal point
        if (currentChar == ".") {
            value += currentChar;
            advance();
            
            while (isDigit(currentChar)) {
                value += currentChar;
                advance();
            }
        }
        
        return new Token(NUMBER, value, startPos);
    }
    
    private function readIdentifier():Token {
        var startPos = position;
        var value = "";
        
        while (isAlphaNumeric(currentChar) || currentChar == "_") {
            value += currentChar;
            advance();
        }
        
        // Check for keywords
        switch (value) {
            case "true": return new Token(BOOLEAN, "true", startPos);
            case "false": return new Token(BOOLEAN, "false", startPos);
            default: return new Token(IDENTIFIER, value, startPos);
        }
    }
    
    private function readString():Token {
        var startPos = position;
        var value = "";
        
        advance(); // Skip opening quote
        
        while (currentChar != "" && currentChar != '"') {
            if (currentChar == "\\") {
                advance();
                if (currentChar == "") break;
                // Handle escape sequences
                switch (currentChar) {
                    case "n": value += "\n";
                    case "t": value += "\t";
                    case "r": value += "\r";
                    case "\\": value += "\\";
                    case '"': value += '"';
                    default: value += currentChar;
                }
            } else {
                value += currentChar;
            }
            advance();
        }
        
        if (currentChar == '"') {
            advance(); // Skip closing quote
        }
        
        return new Token(STRING, value, startPos);
    }
    
    private function advance() {
        position++;
        currentChar = position < input.length ? input.charAt(position) : "";
    }
    
    private function skipWhitespace() {
        while (currentChar == " " || currentChar == "\t" || currentChar == "\n" || currentChar == "\r") {
            advance();
        }
    }
    
    private function isDigit(char:String):Bool {
        return char >= "0" && char <= "9";
    }
    
    private function isAlpha(char:String):Bool {
        return (char >= "a" && char <= "z") || (char >= "A" && char <= "Z");
    }
    
    private function isAlphaNumeric(char:String):Bool {
        return isAlpha(char) || isDigit(char);
    }
}