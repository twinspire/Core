package twinspire;

import twinspire.geom.Dim;
import twinspire.render.GraphicsContext;
import twinspire.render.vector.VectorSpace;
import twinspire.Dimensions.DimResult;
import twinspire.DimIndex;

import kha.math.FastVector2;

class DimBuilder implements IDimBuilder {
    private var results:Array<DimResult>;
    private var currentDimMap:Map<Int, Dim> = new Map();
    private var groups:Array<Array<Int>>;
    private var groupIndices:Array<Int> = [];
    private var isUpdate:Bool;
    private var currentGroupIndex:Int = -1;
    private var gctx:GraphicsContext;
    private var currentUpdatingIndex:Int;

    private var _containerResult:ContainerResult;

    public var bounds(get, never):Dim;
    function get_bounds():Dim { 
        return _containerResult?.space?.bounds;
    }
    
    public var vectorSpace(get, never):VectorSpace;
    function get_vectorSpace():VectorSpace { 
        return _containerResult?.space;
    }
    
    public var containerIndex(get, never):Int;
    function get_containerIndex():Int { 
        return _containerResult?.containerIndex ?? -1; 
    }

    public var updating(get, never):Bool;
    function get_updating() {
        return isUpdate;
    }
    
    public function new(existingResults:Array<DimResult>, isUpdate:Bool, ?bounds:Dim, ?parentDimIndex:DimIndex) {
        this.results = existingResults.copy();
        this.isUpdate = isUpdate;
        this.currentUpdatingIndex = 0;
        this.gctx = Application.instance.graphicsCtx;
        this.groups = [];
        this.groupIndices = [];

        if (bounds != null) {
            setBounds(bounds, parentDimIndex);
        }
    }

    public function setBounds(bounds:Dim, ?parentDimIndex:DimIndex):Void {
        if (_containerResult != null) {
            _containerResult.space.updateContentBounds(bounds);
        }
        else {
            _containerResult = gctx.createContainer(bounds, parentDimIndex, true, {smooth: true, speed: 6.0});
        }
    }

    public function enableScrolling(enabled:Bool, smooth:Bool = true, speed:Float = 6.0):Void {
        if (vectorSpace != null) {
            if (enabled) {
                vectorSpace.enableScrolling(BUTTON_LEFT, smooth);
                vectorSpace.setScrollSpeed(speed);
            } else {
                vectorSpace.setScrollSpeed(0);
            }
        }
    }

    public function scrollTo(x:Float, y:Float, immediate:Bool = false):Void {
        if (vectorSpace != null) {
            if (immediate) {
                vectorSpace.scrollToImmediate(x, y);
            } else {
                vectorSpace.scrollTo(x, y);
            }
        }
    }

    public function getScrollPosition():FastVector2 {
        if (vectorSpace != null) {
            return vectorSpace.getScrollPosition();
        }
        return new FastVector2(0, 0);
    }

    /**
    * Get the current (updated) dimension at the given index.
    * Returns null if not found in this builder.
    **/
    public function getCurrentDimAtIndex(index:DimIndex):Dim {
        var directIndex = DimIndexUtils.getDirectIndex(index);
        return currentDimMap.get(directIndex);
    }
    
    /**
    * Update a dimension at the given index within this builder.
    **/
    public function updateDimAtIndex(index:DimIndex, newDim:Dim) {
        var directIndex = DimIndexUtils.getDirectIndex(index);
        currentDimMap.set(directIndex, newDim);
        
        // Also update in results array if it exists
        for (i in 0...results.length) {
            if (results[i].index != null && DimIndexUtils.equals(results[i].index, index)) {
                results[i].dim = newDim;
                break;
            }
        }
    }
    
    /**
    * Add a dimension to the current group or top level.
    * Returns the index in the current array.
    **/
    public function add(dimResult:DimResult):Int {
        var index:Int;
        
        if (isUpdate) {
            index = currentUpdatingIndex;
            currentUpdatingIndex++;
            
            if (index < results.length) {
                // Update existing dimension
                results[index].dim = dimResult.dim;
                dimResult.index = results[index].index;
                
                // Track the updated dimension
                if (results[index].index != null) {
                    var directIndex = DimIndexUtils.getDirectIndex(results[index].index);
                    currentDimMap.set(directIndex, dimResult.dim);
                }
            } else {
                // Add new dimension (array is growing)
                results.push({
                    dim: dimResult.dim,
                    index: dimResult.index
                });
            }
        } else {
            // Create mode - always add new
            index = results.length;
            results.push({
                dim: dimResult.dim,
                index: dimResult.index
            });
        }
        
        // Add to current group if we're in one
        if (currentGroupIndex >= 0) {
            groups[currentGroupIndex].push(index);
        }
        
        return index;
    }
    
    /**
    * Begin a group of dimensions. All subsequent add() calls will be part of this group.
    **/
    public function beginGroup():Int {
        if (currentGroupIndex != -1) {
            throw "Cannot nest groups - call endGroup() first";
        }
        
        currentGroupIndex = groups.length;
        groups.push([]); // Create new empty group
        
        if (!isUpdate) {
            gctx.beginGroup();
        }
        
        return currentGroupIndex;
    }
    
    /**
    * End the current group and link all child dimensions to the first dimension in the group.
    **/
    public function endGroup():Int {
        if (currentGroupIndex == -1) {
            throw "No active group - call beginGroup() first";
        }
        
        var currentGroup = groups[currentGroupIndex];
        var groupIndex = -1;
        
        if (!isUpdate) {
            groupIndex = gctx.endGroup();
            groupIndices.push(groupIndex);
        }
        
        currentGroupIndex = -1;
        return groupIndex;
    }
    
    /**
    * Get the current results array.
    **/
    public function getResults():Array<DimResult> {
        return results;
    }
    
    /**
    * Get the groups array for Template to process linking.
    **/
    public function getGroups():Array<Array<Int>> {
        return groups;
    }

    /**
    * Gets `DimIndex` values of `Group` from each group defined
    * in this builder.
    **/
    public function getGroupIndices():Array<DimIndex> {
        var results = new Array<DimIndex>();
        for (g in groupIndices) {
            results.push(Group(g));
        }
        return results;
    }
    
    /**
    * Get the number of dimensions currently in the builder.
    **/
    public function length():Int {
        return results.length;
    }
    
    /**
    * Check if we're currently in a group.
    **/
    public function inGroup():Bool {
        return currentGroupIndex != -1;
    }
    
    /**
    * Reset the updating index (useful for multiple update passes).
    **/
    public function resetUpdateIndex() {
        currentUpdatingIndex = 0;
    }
}