package twinspire.script;

enum Token {
    TOpenBracket;
    TCloseBracket;
    TPipe;
    TIdent(value:String);
    TEquals;
    TNum(value:String);
    TDoubleQuote;
    TSingleQuote;
    TString(value:String);
    TDot;
    TSpace;
    TNewLine;
}