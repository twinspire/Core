package twinspire.script;

using StringTools;

class Parser {
    
    private var tokenizer:Tokenizer;
    private var currentToken:Int;

    public var dims:Array<DimStruct>;

    public function new(tokenizer:Tokenizer) {
        this.tokenizer = tokenizer;
        currentToken = -1;
        dims = [];
    }

    public function parseTokens() {
        var token = getNextToken();
        while (token != null) {
            if (token == TOpenBracket) {
                token = getNextToken();
                if (token == null) {
                    break;
                }

                var struct = parseDimStruct();
                dims.push(struct);
            }

            token = getNextToken();
        }
    }

    private function parseDimStruct() {
        var result:DimStruct = {
            data: [],
            structs: []
        };

        var token = tokenizer.tokens[currentToken];
        while (token != TCloseBracket && token != null) {
            skipWhitespace();
            token = tokenizer.tokens[currentToken];
            if (token == TCloseBracket) {
                break;
            }

            while (token != TPipe && token != null) {
                var key = switch (token) {
                    case TIdent(value): value;
                    default: "";
                };

                if (key == "") {
                    // error
                    break;
                }

                token = getNextToken();
                skipWhitespace();
                token = tokenizer.tokens[currentToken];
                if (token == null) {
                    // error
                    break;
                }
                
                if (token != TEquals) {
                    // error
                    break;
                }

                token = getNextToken();
                skipWhitespace();
                token = tokenizer.tokens[currentToken];
                if (token == null) {
                    // error
                    break;
                }

                var value = extractValues();
                result.data[key] = value;

                skipWhitespace();
                token = tokenizer.tokens[currentToken];
            }

            token = getNextToken();
        }

        return result;
    }

    private function getString() {
        var token = tokenizer.tokens[currentToken];
        if (token == TDoubleQuote || token == TSingleQuote) {
            token = getNextToken();
        }

        if (token == null) {
            return null;
        }

        var result = switch (token) {
            case TString(value): value;
            default: "";
        }

        token = getNextToken();
        if (token == null) {
            return null;
        }
        // skip the double get and get the next token afterwards
        token = getNextToken();
        if (token == null) {
            return null;
        }

        return result;
    }

    private function extractValues() {
        var result = [];
        var ident = "";
        var token = tokenizer.tokens[currentToken];
        while (token != null && token != TPipe && token != TOpenBracket && token != TCloseBracket) {
            switch(token) {
                case TIdent(value): {
                    ident += value;  
                }
                case TNum(value): {
                    ident += value;
                }
                case TDot: {
                    ident += ".";
                }
                case TSpace: {
                    result.push(ident);
                    ident = "";
                }
                case TDoubleQuote | TSingleQuote: {
                    ident = getString();
                }
                default: {

                }
            }

            token = getNextToken();
        }

        if (ident != "") {
            result.push(ident.trim());
        }

        return result;
    }

    private function skipWhitespace() {
        var token = tokenizer.tokens[currentToken];
        while (token == TSpace || token == TNewLine) {
            token = getNextToken();
        }
    }

    private function getNextToken() {
        if (currentToken + 1 < tokenizer.tokens.length) {
            currentToken += 1;
            return tokenizer.tokens[currentToken];
        }

        return null;
    }

}