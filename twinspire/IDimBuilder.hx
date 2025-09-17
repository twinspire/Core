package twinspire;

import twinspire.geom.Dim;
import twinspire.Dimensions.DimResult;

interface IDimBuilder {
    var updating(get, never):Bool;
    function getCurrentDimAtIndex(index:DimIndex):Dim;
    function updateDimAtIndex(index:DimIndex, newDim:Dim):Void;
    function add(dimResult:DimResult):Int;
    function beginGroup():Int;
    function endGroup():Int;
    function getResults():Array<DimResult>;
    function getGroups():Array<Array<Int>>;
    function getGroupIndices():Array<DimIndex>;
    function length():Int;
    function inGroup():Bool;
    function resetUpdateIndex():Void;
}