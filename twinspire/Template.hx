package twinspire;

import twinspire.geom.Dim;
import twinspire.Dimensions.DimResult;
import twinspire.DimIndex.DimIndexUtils;
import twinspire.render.GraphicsContext;
using twinspire.extensions.ArrayExtensions;

typedef Dependent = {
    // as an index of the current position in the stack
    var ?current:Int;
    // as indices of positions in the stack
    var ?depends:Array<Int>;
}

class Template {
    
    private var dimensionRefs:Map<String, Array<DimResult>> = new Map();
    private var groupRefs:Map<String, Array<DimIndex>> = new Map();
    private var dependencies:Array<Dependent>;


    private var initBuilderCallback:(String, Bool, ?Dim, ?DimIndex) -> IDimBuilder = (name, isUpdate, ?bounds, ?parentDimIndex) -> {
        return new DimBuilder([], isUpdate, bounds, parentDimIndex);
    };


    /**
    * A collection of indices that this template belongs to.
    **/
    public var indices:Array<DimIndex>;
    /**
    * A collection of callbacks for each index reference.
    **/
    public var callbacks:Array<(DimIndex, GraphicsContext) -> DimIndex>;

    public function new() {
        indices = [];
        callbacks = [];
        dependencies = [];

        initBuilderCallback = (name:String, isUpdate:Bool, ?bounds:Dim, ?parentDimIndex:DimIndex) -> {
            return new DimBuilder([], isUpdate, bounds, parentDimIndex);
        };
    }

    /**
    * Adds or updates a dimension from a given name using the given callback and scope. Unlike `addAndInvoke`,
    * this function manages creating or updating dimensions for specific items within the template.
    *
    * Moreover, use this function for better organisation and managing your use of `useDimension` in `GraphicsContext`.
    *
    * @param name The name to map the callback `dimProvider` to.
    * @param dimProvider The callback used to create and update dimensions. The string is the `name` given, and an optional `DimIndex`. Return a 
    * `Map<DimIndex, Dim>` from this callback.
    * @param scope The `AddLogic` used to determine what type of dimension should be created in `GraphicsContext`.
    * @param dependsOn An optional string value specifying which `name` this dimension should depend on.
    **/
    public function addOrUpdateDim(name:String, builder:(IDimBuilder) -> Void, ?scope:AddLogic, ?dependsOn:String, ?bounds:Dim, ?parentDimIndex:DimIndex) {
        var existingResults = dimensionRefs.get(name);
        var isUpdate = existingResults != null;
        
        // GraphicsContext automatically handles VectorSpace setup based on bounds and parentDimIndex
        var dimBuilder = initBuilderCallback(name, isUpdate, bounds, parentDimIndex);
        
        // Rest unchanged
        if (isUpdate) {
            Dimensions.beginEdit();
        }

        Dimensions.setBuilderContext(dimBuilder);
        builder(dimBuilder);
        Dimensions.clearBuilderContext();
        
        if (isUpdate) {
            Dimensions.endEdit();
        }
        
        var newResults = dimBuilder.getResults();
        var groups = dimBuilder.getGroups();
        var groupIndices = dimBuilder.getGroupIndices(); // New method to get group DimIndices
        var gctx = Application.instance.graphicsCtx;
        
        if (isUpdate) {
            Dimensions.beginEdit();
            
            // Update existing dimensions
            for (i in 0...newResults.length) {
                if (i < existingResults.length && existingResults[i].index != null) {
                    gctx.setOrReinitDim(existingResults[i].index, newResults[i].dim);
                    newResults[i].index = existingResults[i].index;
                } else {
                    // Create new dimension (array grew)
                    var result = Dimensions.createFromDim(newResults[i].dim, scope ?? Empty());
                    newResults[i] = result;
                }
            }
            
            // Clean up excess dimensions
            for (i in newResults.length...existingResults.length) {
                if (existingResults[i].index != null) {
                    gctx.removeIndex(existingResults[i].index);
                }
            }
            
            Dimensions.endEdit();
        } else {
            // Set up group linking after all indices are created
            for (i in 0...groups.length) {
                var group = groups[i];
                var groupIndex = switch (groupIndices[i]) {
                    case Group(index, render): {
                        index;
                    }
                    default: {
                        -1;
                    }
                };
                gctx.beginGroup(groupIndex);

                if (group.length > 1) {
                    var firstIndex = newResults[group[0]].index;
                    gctx.addToGroup(firstIndex);
                    for (j in 1...group.length) {
                        var childIndex = newResults[group[j]].index;
                        gctx.addToGroup(childIndex);
                        if (firstIndex != null && childIndex != null) {
                            gctx.setupDirectLink(childIndex, firstIndex);
                        }
                    }
                }

                gctx.endGroup();
            }
        }
        
        dimensionRefs.set(name, newResults);
        groupRefs.set(name, groupIndices);
    }

    /**
    * Get the DimIndex for a specific group within a named dimension set.
    **/
    public function getGroupIndex(name:String, groupIndex:Int):DimIndex {
        var groups = groupRefs.get(name);
        return (groups != null && groupIndex < groups.length) ? groups[groupIndex] : null;
    }
    
    /**
    * Get all group indices for a named dimension set.
    **/
    public function getGroupIndices(name:String):Array<DimIndex> {
        return groupRefs.get(name) ?? [];
    }

    /**
    * Get all DimResults for a named dimension group.
    **/
    public function getDimResults(name:String):Array<DimResult> {
        return dimensionRefs.get(name) ?? [];
    }
    
    /**
    * Get a specific DimResult by index.
    **/
    public function getDimResult(name:String, index:Int):DimResult {
        var results = dimensionRefs.get(name);
        return (results != null && index < results.length) ? results[index] : null;
    }

    /**
    * Adds a callback to the current callback stack in this template and 
    * returns the resulting `DimIndex` invoked into the index stack.
    **/
    public function addAndInvoke(cb:(DimIndex, GraphicsContext) -> DimIndex, ?dependsOn:DimIndex) {
        indices.push(cb(null, Application.instance.graphicsCtx));
        callbacks.push(cb);

        if (dependsOn != null) {
            var actualIndex = DimIndexUtils.getDirectIndex(indices[indices.length - 1]);
            var dependOnIndex = indices.findIndex(i -> DimIndexUtils.equals(i, dependsOn));
            var found = dependencies.find((d) -> d.current == actualIndex);
            // dependency must already be in the template
            if (dependOnIndex == -1) {
                return;
            }

            if (found != null) {
                found.depends.push(dependOnIndex);
            }
            else {
                dependencies.push({
                    current: indices.length - 1,
                    depends: [ dependOnIndex ]
                });
            }
        }
    }

    /**
    * Invoke all callbacks in this template.
    **/
    public function invokeAll() {
        var sortedIndices = resolveDependencyOrder();
    
        for (i in sortedIndices) {
            if (i < callbacks.length) {
                indices[i] = callbacks[i](indices[i], Application.instance.graphicsCtx);
            }
        }
    }

    /**
    * Invoke the specified index, if found.
    **/
    public function invokeIndex(index:DimIndex) {
        var found = -1;
        for (i in 0...indices.length) {
            if (DimIndexUtils.equals(indices[i], index)) {
                found = i;
                break;
            }
        }
        
        if (found > -1) {
            var toInvoke = [];
            var visited = [];
            collectDependencies(found, toInvoke, visited);
            
            // Invoke in dependency order
            for (i in toInvoke) {
                indices[i] = callbacks[i](indices[i], Application.instance.graphicsCtx);
            }
        }
    }

    /**
    * Remove an index from the template.
    **/
    public function removeIndex(index:DimIndex):Array<DimIndex> {
        var found = -1;
        for (i in 0...indices.length) {
            if (DimIndexUtils.equals(indices[i], index)) {
                found = i;
                break;
            }
        }
        
        if (found == -1) {
            return [];
        }
        
        var affectedIndices = [];
        
        // Find what depends on this index
        var dependents = dependencies.where(d -> d.depends != null && d.depends.contains(found));
        for (dep in dependents) {
            if (dep.current < indices.length) {
                affectedIndices.push(indices[dep.current]);
            }
        }
        
        // Remove the index
        indices.splice(found, 1);
        callbacks.splice(found, 1);
        
        // Update dependency indices (shift down after removal)
        for (dep in dependencies) {
            if (dep.current > found) {
                dep.current--;
            }
            if (dep.depends != null) {
                for (i in 0...dep.depends.length) {
                    if (dep.depends[i] > found) {
                        dep.depends[i]--;
                    }
                }
                // Remove references to the deleted index
                dep.depends.remove(found);
            }
        }
        
        // Remove empty dependencies
        dependencies = dependencies.where(d -> d.current != found);
        
        return affectedIndices;
    }
    
    /**
    * Update all dimensions in this template (useful for responsive layouts).
    **/
    public function updateAll(dimProvider:(String, Array<DimResult>) -> Array<DimResult>) {
        var gctx = Application.instance.graphicsCtx;
        
        Dimensions.beginEdit();
        for (name => dimResults in dimensionRefs) {
            var updatedResults = dimProvider(name, dimResults);
            
            for (i in 0...updatedResults.length) {
                if (i < dimResults.length && dimResults[i].index != null) {
                    gctx.setOrReinitDim(dimResults[i].index, updatedResults[i].dim);
                }
            }
            
            dimensionRefs.set(name, updatedResults);
        }
        Dimensions.endEdit();
    }

    /**
    * Get a collection of dependencies for the given index.
    **/
    public function getDependencyIndices(index:DimIndex):Array<DimIndex> {
        var found = -1;
        for (i in 0...indices.length) {
            if (DimIndexUtils.equals(indices[i], index)) {
                found = i;
                break;
            }
        }
        
        if (found == -1) {
            return [];
        }
        
        var deps = dependencies.find(d -> d.current == found);
        if (deps == null || deps.depends == null) {
            return [];
        }
        
        var result = [];
        for (depIndex in deps.depends) {
            if (depIndex < indices.length) {
                result.push(indices[depIndex]);
            }
        }
        
        return result;
    }

    private function resolveDependencyOrder():Array<Int> {
        var result = [];
        var visited = [];
        var visiting = [];
        
        for (i in 0...callbacks.length) {
            if (!visited.contains(i)) {
                visitDependency(i, visited, visiting, result);
            }
        }
        
        return result;
    }

    private function visitDependency(index:Int, visited:Array<Int>, visiting:Array<Int>, result:Array<Int>) {
        if (visiting.contains(index)) {
            throw "Circular dependency detected in template";
        }
        
        if (visited.contains(index)) {
            return;
        }
        
        visiting.push(index);
        
        // Find dependencies for this index
        var deps = dependencies.find(d -> d.current == index);
        if (deps != null) {
            for (depIndex in deps.depends) {
                visitDependency(depIndex, visited, visiting, result);
            }
        }
        
        visiting.remove(index);
        visited.push(index);
        result.push(index);
    }

    private function collectDependencies(index:Int, toInvoke:Array<Int>, visited:Array<Int>) {
        if (visited.contains(index)) {
            return;
        }
        
        visited.push(index);
        
        var deps = dependencies.find(d -> d.current == index);
        if (deps != null) {
            for (depIndex in deps.depends) {
                collectDependencies(depIndex, toInvoke, visited);
            }
        }
        
        toInvoke.push(index);
    }

}