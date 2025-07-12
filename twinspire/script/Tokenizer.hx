package twinspire.script;

using StringTools;

class Tokenizer {
    
    private var _currentCursor:Int;
    private var _currentLine:Int;

    public var errors:Array<String>;
    public var tokens:Array<Token>;

    public function new(content:String) {
        errors = [];

        processTokens(content);
    }

    private function processTokens(content:String) {
        tokens = [];
        _currentCursor = 0;
        _currentLine = 1;

        var value = "";
        var firstIsNum = false;
        var isIdent = false;
        var isString = false;
        for (i in 0...content.length) {
            var code = content.fastCodeAt(i);

            if (isString && code != '"'.code) {
                value += content.charAt(i);
            }
            else if (isLetter(code)) {
                if (firstIsNum) {
                    addError('The letter ${content.charAt(i)} does not form part of a number.');
                }
                else {
                    isIdent = true;
                }

                value += content.charAt(i);
            }
            else if (isNumber(code)) {
                if (value == "") {
                    firstIsNum = true;
                }

                value += content.charAt(i);
            }
            else if (isSpace(code)) {
                if (value != "") {
                    if (firstIsNum) {
                        tokens.push(TNum(value));
                        firstIsNum = false;
                    }
                    else if (isIdent) {
                        tokens.push(TIdent(value));
                        isIdent = false;
                    }

                    value = "";
                }

                tokens.push(TSpace);
            }
            else if (isNewLine(code)) {
                if (value != "") {
                    if (firstIsNum) {
                        tokens.push(TNum(value));
                        firstIsNum = false;
                    }
                    else if (isIdent) {
                        tokens.push(TIdent(value));
                        isIdent = false;
                    }

                    value = "";
                }

                if (getLastToken() != TNewLine && getLastToken() != null) {
                    _currentLine += 1;
                    _currentCursor = 0;
                }

                tokens.push(TNewLine);
            }
            else {
                switch (code) {
                    case "[".code: {
                        tokens.push(TOpenBracket);
                    }
                    case "]".code: {
                        tokens.push(TCloseBracket);
                    }
                    case "|".code: {
                        tokens.push(TPipe);
                    }
                    case "=".code: {
                        tokens.push(TEquals);
                    }
                    case '"'.code: {
                        if (isString) {
                            tokens.push(TString(value));
                            value = "";
                        }
                        
                        tokens.push(TDoubleQuote);

                        isString = !isString;
                    }
                }
            }
        }
    }

    private function getLastToken() {
        if (tokens.length == 0) {
            return null;
        }

        return tokens[tokens.length - 1];
    }

    private function addError(message:String) {
        errors.push('${_currentLine}, ${_currentCursor} : ${message}');
    }

    private function isLetter(code:Int) {
        return (code >= "A".code && code <= "Z".code) || (code >= "a".code && code <= "z".code);
    }

    private function isNumber(code:Int) {
        return code >= "0".code && code <= "9".code;
    }

    private function isSpace(code:Int) {
        return code <= 32 && code != 10 && code != 13;
    }

    private function isNewLine(code:Int) {
        return code == 10 || code == 13;
    }

}