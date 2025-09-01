package twinspire;

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
    
    private var dependencies:Array<Dependent>;

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