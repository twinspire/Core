package twinspire;

import twinspire.geom.Dim;
import twinspire.render.vector.VectorSpace;
import twinspire.Dimensions.DimResult;

import kha.math.FastVector2;

interface IDimBuilder {
    var updating(get, never):Bool;
    var bounds(get, never):Dim;                    
    var vectorSpace(get, never):VectorSpace;       
    var containerIndex(get, never):Int;            
    
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
    
    // VectorSpace management
    function setBounds(bounds:Dim, ?parentDimIndex:DimIndex):Void;
    function enableScrolling(enabled:Bool, smooth:Bool = true, speed:Float = 6.0):Void;
    function scrollTo(x:Float, y:Float, immediate:Bool = false):Void;
    function getScrollPosition():FastVector2;
}