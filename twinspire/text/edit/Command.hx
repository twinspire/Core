package twinspire.text.edit;

enum abstract Command(Int) {
    var None;
	var Undo;
	var Redo;
	var New_Line;    // multi-lines
	var Cut;
	var Copy;
	var Paste;
	var Select_All;
	var Backspace;
	var Delete;
	var Delete_Word_Left;
	var Delete_Word_Right;
	var Left;
	var Right;
	var Up;          // multi-lines
	var Down;        // multi-lines
	var Word_Left;
	var Word_Right;
	var Start;
	var End;
	var Line_Start;
	var Line_End;
	var Select_Left;
	var Select_Right;
	var Select_Up;   // multi-lines
	var Select_Down; // multi-lines
	var Select_Word_Left;
	var Select_Word_Right;
	var Select_Start;
	var Select_End;
	var Select_Line_Start;
	var Select_Line_End;
}