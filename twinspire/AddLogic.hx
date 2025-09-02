package twinspire;

enum AddLogic {
    Empty(?linked:DimIndex);
    Ui(?id:Id, ?linked:DimIndex);
    Static(?id:Id, ?linked:DimIndex);
    Sprite(?id:Id, ?linked:DimIndex);
}