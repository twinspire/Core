package twinspire;

import twinspire.render.GraphicsContext;
import twinspire.Dimensions.DimResult;
import twinspire.DimIndex;

class DimBuilder {
    private var results:Array<DimResult>;
    private var groups:Array<Array<Int>>;
    private var groupIndices:Array<Int> = [];
    private var isUpdate:Bool;
    private var currentGroupIndex:Int = -1;
    private var gctx:GraphicsContext;
    private var currentUpdatingIndex:Int;

    public var updating(get, never):Bool;
    function get_updating() {
        return isUpdate;
    }
    
    public function new(existingResults:Array<DimResult>, isUpdate:Bool) {
        this.results = existingResults.copy();
        this.isUpdate = isUpdate;
        this.currentUpdatingIndex = 0;
        this.gctx = Application.instance.graphicsCtx;
        this.groups = [];
        this.groupIndices = [];
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
        if (currentGroupIndex >= 0 && !isUpdate) {
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