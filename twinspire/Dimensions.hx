package twinspire;

import twinspire.DimIndex;
import haxe.ds.ArraySort;

import kha.AssetError;
import twinspire.DimIndex.DimIndexUtils;
import haxe.io.Path;
import twinspire.events.EventArgs;
import twinspire.events.DimBindingOptions;
import twinspire.render.GraphicsContext;
import twinspire.render.ComplexResult;
import twinspire.DimObjectResult;
import twinspire.DimObjectResult.DimObjectOptions;
import twinspire.Id;
import twinspire.DimSize;
import twinspire.geom.Box;
import twinspire.geom.Dim;
import twinspire.geom.DimCellSize;
import twinspire.geom.DimCellSize.DimCellSizing;
import twinspire.scenes.Scene;
import twinspire.scenes.SceneObject;
import twinspire.Application;
using twinspire.extensions.ArrayExtensions;
using kha.StringExtensions;

import kha.graphics2.Graphics;
import kha.math.FastVector2;
import kha.System;
import kha.Font;

#if assertion
import Assertion.*;
#end

enum abstract HorizontalAlign(Int) from Int to Int {
	var HALIGN_NONE				=	0;
	var HALIGN_LEFT				=	1;
	var HALIGN_MIDDLE			=	2;
	var HALIGN_RIGHT			=	3;
}

enum abstract VerticalAlign(Int) from Int to Int {
	var VALIGN_NONE				=	0;
	var VALIGN_TOP				=	1;
	var VALIGN_CENTRE			=	2;
	var VALIGN_BOTTOM			=	3;
}

enum abstract Direction(Int) to Int {
    var Up;
    var Down;
    var Left;
    var Right;
}

enum abstract DimBehaviourFlags(Int) from Int to Int {
    /**
     * A dimension behaviour which specifies no events are to be handled by the simulation engine.
     */
    var DIM_NO_EVENTS           =   0;
    /**
     * A dimension behaviour specifying mouse movements in and out of the dimension affects the render results.
     */
    var DIM_MOUSE_EVENTS        =   0x01;
    /**
     * A dimension behaviour specifying that the mouse wheel affects the position of dimensions contained in this dimension.
     */
    var DIM_SCROLL_EVENTS       =   0x02;
}

enum abstract ContainerMethods(Int) from Int to Int {
    var FLOW_FIXED      =   0;
    var FLOW_VARIABLE   =   1;
}

enum DimAlignment {
    None;
    DimVAlign(valign:VerticalAlign);
    DimHAlign(halign:HorizontalAlign);
    DimAlign(valign:VerticalAlign, halign:HorizontalAlign);
}

enum DimInitCommand {
    FromDim(dim:Dim);
    CentreScreenY(width:Float, height:Float, offsetY:Float);
    CentreScreenX(width:Float, height:Float, offsetX:Float);
    CentreScreenFromSize(width:Float, height:Float);
    CreateDimAlignScreen(width:Float, height:Float, valign:VerticalAlign, halign:HorizontalAlign, offset:FastVector2);
    CreateFromOffset(from:DimIndex, offset:FastVector2);
    CreateGridEquals(container:DimIndex, columns:Int, rows:Int, indices:Array<DimIndex>);
    CreateGridFloats(container:DimIndex, columns:Array<Float>, rows:Array<Float>, indices:Array<DimIndex>);
    CreateGrid(container:DimIndex, columns:Array<DimCellSize>, rows:Array<DimCellSize>, indices:Array<DimIndex>);
    MeasureText(font:Font, fontSize:Int, text:String, ?id:Id);
    DimOffsetX(a:DimIndex, offsetX:Float);
    DimOffsetY(a:DimIndex, offsetY:Float);
}

enum DimCommand {
    CreateFixedFlow(container:DimIndex, itemSize:DimSize, dir:Direction, indices:Array<DimIndex>);
    CreateVariableFlow(container:DimIndex, dir:Direction, indices:Array<DimIndex>);
    ScreenAlignX(halign:HorizontalAlign, offset:FastVector2);
    ScreenAlignY(valign:VerticalAlign, offset:FastVector2);
    DimAlign(to:DimIndex, halign:HorizontalAlign, valign:VerticalAlign);
    DimAlignOffset(to:DimIndex, halign:HorizontalAlign, valign:VerticalAlign, hoffset:Float, voffset:Float);
    DimVAlign(to:DimIndex, valign:VerticalAlign);
    DimHAlign(to:DimIndex, halign:HorizontalAlign);
    DimVAlignOffset(to:DimIndex, valign:VerticalAlign, offset:Float);
    DimHAlignOffset(to:DimIndex, halign:HorizontalAlign, offset:Float);
    DimScale(scaleX:Float, scaleY:Float);
    DimScaleX(scaleX:Float);
    DimScaleY(scaleY:Float);
    DimShrink(amount:Float);
    DimShrinkW(amount:Float);
    DimShrinkH(amount:Float);
    DimGrow(amount:Float);
    DimGrowW(amount:Float);
    DimGrowH(amount:Float);
}

typedef CommandResult = {
    var ?index:DimIndex;
    var ?init:DimInitCommand;
    var ?cmd:DimCommand;
    var ?matchScreenWidth:Bool;
    var ?matchScreenHeight:Bool;
}

enum ContainerAddLogic {
    Empty(?linked:DimIndex);
    Ui(?id:Id, ?linked:DimIndex);
    Static(?id:Id, ?linked:DimIndex);
    Sprite(?id:Id, ?linked:DimIndex);
}

typedef DimResult = {
    var ?index:DimIndex;
    var ?dim:Dim;
}

typedef DependencyRecord = {
    var id:Int;                           // The unique ID for this dimension
    var dependsOn:Array<Int>;            // IDs this dimension depends on
    var dependents:Array<Int>;           // IDs that depend on this dimension  
    var originalCommands:Array<DimCommand>; // Commands as originally defined
    var resolvedCommands:Array<DimCommand>; // Commands with dependencies resolved
}

typedef CommandGroup = {
    var id:Int;                          // Unique ID for this group
    var initCommand:Null<DimInitCommand>; // Initial creation command
    var commands:Array<DimCommand>;      // Transformation commands
    var dependencies:DependencyRecord;   // Dependency information
}

typedef GridFlowGroup = {
    var containerId:Int;                    // The container this grid/flow belongs to
    var type:GridFlowType;                  // Grid or Flow type
    var parameters:GridFlowParameters;      // Specific parameters for recreation
    var memberIds:Array<Int>;               // IDs of all dimensions in this grid/flow
    var memberIndices:Array<DimIndex>;      // Current indices (may change)
}

enum GridFlowType {
    GridEquals(columns:Int, rows:Int);
    GridFloats(columns:Array<Float>, rows:Array<Float>);
    GridCustom(columns:Array<DimCellSize>, rows:Array<DimCellSize>);
    FlowFixed(itemSize:DimSize, direction:Direction);
    FlowVariable(direction:Direction);
}

typedef GridFlowParameters = {
    var ?columns:Dynamic;        // Int, Array<Float>, or Array<DimCellSize>
    var ?rows:Dynamic;           // Int, Array<Float>, or Array<DimCellSize>
    var ?itemSize:DimSize;       // For fixed flows
    var ?direction:Direction;    // For flows
}

typedef EnhancedCommandGroup = {
    > CommandGroup,
    var ?gridFlowGroup:GridFlowGroup;    // Present if this is part of a grid/flow
    var ?isGridFlowContainer:Bool;       // True if this dimension contains grid/flow items
}

class Dimensions {

    private static var _order:Int;
    private static var _visibility:Bool;
    private static var _lastDimensions:Array<DimIndex>;

    private static var _commandResults:Array<CommandResult>;
    private static var _currentDimCommands:Array<DimCommand>;
    private static var _idCommand:Array<Int>;
    private static var _currentId:Int;
    private static var _idStack:Array<Int>;

    private static var _editMode:Bool = false;

    private static var _commandGroups:Map<Int, CommandGroup>;
    private static var _dependencyGraph:Map<Int, DependencyRecord>;
    private static var _idToIndex:Map<Int, DimIndex>;

    private static var _gridFlowGroups:Map<Int, GridFlowGroup>; // Container ID -> GridFlowGroup
    private static var _memberToGridFlow:Map<Int, Int>;         // Member ID -> Container ID

    /**
    * Used internally to store information about constructed dimensions before an `add` is called.
    **/
    public static function initContext() {
        resetContext();
        _lastDimensions = [];
        _commandGroups = new Map();
        _dependencyGraph = new Map();
        _idToIndex = new Map();
        _gridFlowGroups = new Map();
        _memberToGridFlow = new Map();
    }

    /**
    * Push an ID to the current stack. Use either a `String` or `Int`, but not both.
    **/
    public static function pushId(?ident:String, ?value:Int) {
        if (_idStack == null) {
            _idStack = [];
        }

        var newId:Int;
        
        if (value != null) {
            // For integer values, combine with current stack depth for uniqueness
            newId = hashCombine(_currentId, value);
        }
        else if (ident != null) {
            // Use the string-to-seed function for consistent hashing
            var stringHash = stringToSeed(ident);
            newId = hashCombine(_currentId, stringHash);
        }
        else {
            // Auto-increment if no identifier provided
            newId = hashCombine(_currentId, _idStack.length + 1);
        }
        
        // Ensure uniqueness by checking against existing commands
        while (_idCommand.contains(newId)) {
            newId = hashCombine(newId, 1);
        }
        
        _idStack.push(_currentId); // Push the previous ID
        _currentId = newId;        // Set new current ID
    }

    /**
    * Hash combine function for creating composite hash values.
    * This ensures good distribution.
    */
    static function hashCombine(seed:Int, value:Int):Int {
        // Based on boost::hash_combine algorithm
        var result = seed ^ (value + 0x9e3779b9 + (seed << 6) + (seed >> 2));
        return result & 0x7FFFFFFF; // Keep positive
}

    /**
    * Generate a seed integer from a string using DJB2 hash.
    */
    static function stringToSeed(input:String):Int {
        if (input == null || input.length == 0) {
            return 0;
        }
        
        var hash = 5381;
        
        for (i in 0...input.length) {
            var char = input.charCodeAt(i);
            hash = ((hash << 5) + hash) + char; // hash * 33 + char
            hash = hash & 0x7FFFFFFF; // Keep positive
        }
        
        return hash;
    }

    static function advanceId() {
        // Return because we have an ID pushed manually by the user
        if (_idStack.length > 0) {
            return;
        }
        
        // Generate next sequential ID
        var nextId = hashCombine(_currentId, 1);
        
        // Ensure uniqueness
        while (_idCommand.contains(nextId)) {
            nextId = hashCombine(nextId, 1);
        }
        
        _currentId = nextId;
    }

    static function addCommandId() {
        advanceId();
        _idCommand.push(_currentId);
    }

    /**
    * Remove the last identifier pushed to the stack.
    **/
    public static function popId():Int {
        if (_idStack.length == 0) {
            return -1;
        }
        
        var poppedId = _currentId;
        _currentId = _idStack.pop(); // Restore previous ID
        return poppedId;
    }

    /**
    * Resets the current context of dimensions, clearing the current dimension and any commands.
    **/
    public static function resetContext() {
        _idStack = [];
        _idCommand = [];
        _commandResults = [];
        _order = 0;
        _visibility = true;
        _currentId = 0;
    }

    public static function getCommandResultList() {
        return _commandResults;
    }

    public static function addDimIndex(dim:DimIndex) {
        if (_lastDimensions == null)
            _lastDimensions = [];
        _lastDimensions.push(dim);
    }

    static function addCommandResultInit(index:DimIndex, init:DimInitCommand) {
        var result:CommandResult = {};
        
        var gtx = Application.instance.graphicsCtx;
        var dim = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(index));
        result.matchScreenWidth = dim.width == Application.getScreenDim().width;
        result.matchScreenHeight = dim.height == Application.getScreenDim().height;
        result.index = index;
        result.init = init;
        
        if (_commandResults == null) {
            _commandResults = [];
        }
        
        _commandResults.push(result);
        
        // Handle grid/flow creation commands
        handleGridFlowInit(init, index);
        
        // Create standard command group
        if (!_commandGroups.exists(_currentId)) {
            var group:EnhancedCommandGroup = {
                id: _currentId,
                initCommand: init,
                commands: [],
                dependencies: {
                    id: _currentId,
                    dependsOn: [],
                    dependents: [],
                    originalCommands: [],
                    resolvedCommands: []
                }
            };
            
            _commandGroups.set(_currentId, group);
            _idToIndex.set(_currentId, index);
        }
        
        analyzeDependencies(_currentId, init);
    }

    static function handleGridFlowInit(init:DimInitCommand, containerIndex:DimIndex) {
        switch (init) {
            case CreateGridEquals(container, columns, rows, indices): {
                createGridFlowGroup(
                    getIdFromDimIndex(container),
                    GridEquals(columns, rows),
                    {columns: columns, rows: rows},
                    indices
                );
            }
            case CreateGridFloats(container, columns, rows, indices): {
                createGridFlowGroup(
                    getIdFromDimIndex(container),
                    GridFloats(columns, rows),
                    {columns: columns, rows: rows},
                    indices
                );
            }
            case CreateGrid(container, columns, rows, indices): {
                createGridFlowGroup(
                    getIdFromDimIndex(container),
                    GridCustom(columns, rows),
                    {columns: columns, rows: rows},
                    indices
                );
            }
            default: // Not a grid/flow command
        }
    }

    static function addCommandResult(index:DimIndex, cmd:DimCommand) {
        if (_commandResults == null) {
            _commandResults = [];
        }
        _commandResults.push({
            index: index,
            cmd: cmd
        });
        
        // Handle flow commands
        handleGridFlowCommand(cmd, index);
        
        if (_commandGroups.exists(_currentId)) {
            var group = _commandGroups.get(_currentId);
            group.commands.push(cmd);
            group.dependencies.originalCommands.push(cmd);
            
            analyzeDependencies(_currentId, null, cmd);
        }
    }

    static function handleGridFlowCommand(cmd:DimCommand, containerIndex:DimIndex) {
        switch (cmd) {
            case CreateFixedFlow(container, itemSize, dir, indices): {
                createGridFlowGroup(
                    getIdFromDimIndex(container),
                    FlowFixed(itemSize, dir),
                    {itemSize: itemSize, direction: dir},
                    indices
                );
            }
            case CreateVariableFlow(container, dir, indices): {
                createGridFlowGroup(
                    getIdFromDimIndex(container),
                    FlowVariable(dir),
                    {direction: dir},
                    indices
                );
            }
            default: // Not a flow command
        }
    }
    
    static function createGridFlowGroup(containerId:Int, type:GridFlowType, parameters:GridFlowParameters, indices:Array<DimIndex>) {
        var memberIds:Array<Int> = [];
        
        // Generate IDs for all members if they don't exist
        for (i in 0...indices.length) {
            var memberId = _currentId + i + 1; // Generate sequential IDs
            memberIds.push(memberId);
            _memberToGridFlow.set(memberId, containerId);
            _idToIndex.set(memberId, indices[i]);
        }
        
        var gridFlowGroup:GridFlowGroup = {
            containerId: containerId,
            type: type,
            parameters: parameters,
            memberIds: memberIds,
            memberIndices: indices.copy()
        };
        
        _gridFlowGroups.set(containerId, gridFlowGroup);
        
        // Mark container as having grid/flow
        if (_commandGroups.exists(containerId)) {
            var containerGroup:EnhancedCommandGroup = cast _commandGroups.get(containerId);
            containerGroup.isGridFlowContainer = true;
            containerGroup.gridFlowGroup = gridFlowGroup;
        }
        
        // Create dependency records for all members
        for (memberId in memberIds) {
            createGridFlowMemberDependencies(memberId, containerId, memberIds);
        }
    }
    
    static function createGridFlowMemberDependencies(memberId:Int, containerId:Int, allMemberIds:Array<Int>) {
        // Each member depends on the container
        addDependency(memberId, containerId);
        
        // For flows, each member (except first) also depends on layout order
        var gridFlowGroup = _gridFlowGroups.get(containerId);
        if (gridFlowGroup != null) {
            switch (gridFlowGroup.type) {
                case FlowFixed(_, _) | FlowVariable(_): {
                    var memberIndex = allMemberIds.indexOf(memberId);
                    if (memberIndex > 0) {
                        // Flow items depend on previous item for positioning
                        addDependency(memberId, allMemberIds[memberIndex - 1]);
                    }
                }
                default: {
                    // Grid items only depend on container
                }
            }
        }
    }

    static function analyzeDependencies(currentId:Int, ?initCmd:DimInitCommand, ?cmd:DimCommand) {
        var dependencies:Array<Int> = [];
        
        if (initCmd != null) {
            dependencies = extractDependenciesFromInit(initCmd);
        } else if (cmd != null) {
            dependencies = extractDependenciesFromCommand(cmd);
        }
        
        // Update dependency records
        for (depId in dependencies) {
            addDependency(currentId, depId);
        }
    }

    static function extractDependenciesFromInit(cmd:DimInitCommand):Array<Int> {
        return switch (cmd) {
            case CreateFromOffset(from, offset): [getIdFromDimIndex(from)];
            case DimOffsetX(a, offsetX): [getIdFromDimIndex(a)];
            case DimOffsetY(a, offsetY): [getIdFromDimIndex(a)];
            default: [];
        };
    }

    static function extractDependenciesFromCommand(cmd:DimCommand):Array<Int> {
        return switch (cmd) {
            case DimAlign(to, halign, valign): [getIdFromDimIndex(to)];
            case DimAlignOffset(to, halign, valign, hoffset, voffset): [getIdFromDimIndex(to)];
            case DimVAlign(to, valign): [getIdFromDimIndex(to)];
            case DimHAlign(to, halign): [getIdFromDimIndex(to)];
            case DimVAlignOffset(to, valign, offset): [getIdFromDimIndex(to)];
            case DimHAlignOffset(to, halign, offset): [getIdFromDimIndex(to)];
            case CreateFixedFlow(container, itemSize, dir, indices): [getIdFromDimIndex(container)];
            case CreateVariableFlow(container, dir, indices): [getIdFromDimIndex(container)];
            default: [];
        };
    }

    static function getIdFromDimIndex(dimIndex:DimIndex):Int {
        // Look up the ID from the index
        for (id => idx in _idToIndex) {
            if (DimIndexUtils.equals(idx, dimIndex)) {
                return id;
            }
        }
        return -1; // No dependency found
    }

    static function addDependency(dependentId:Int, dependsOnId:Int) {
        if (dependsOnId == -1) return; // No valid dependency
        
        // Update dependent record
        if (!_dependencyGraph.exists(dependentId)) {
            _dependencyGraph.set(dependentId, {
                id: dependentId,
                dependsOn: [],
                dependents: [],
                originalCommands: [],
                resolvedCommands: []
            });
        }
        
        var dependentRecord = _dependencyGraph.get(dependentId);
        if (!dependentRecord.dependsOn.contains(dependsOnId)) {
            dependentRecord.dependsOn.push(dependsOnId);
        }
        
        // Update dependency provider record
        if (!_dependencyGraph.exists(dependsOnId)) {
            _dependencyGraph.set(dependsOnId, {
                id: dependsOnId,
                dependsOn: [],
                dependents: [],
                originalCommands: [],
                resolvedCommands: []
            });
        }
        
        var providerRecord = _dependencyGraph.get(dependsOnId);
        if (!providerRecord.dependents.contains(dependentId)) {
            providerRecord.dependents.push(dependentId);
        }
    }

    public static function removeDimensionGroup(id:Int) {
        if (!_commandGroups.exists(id)) {
            return;
        }
        
        var gtx = Application.instance.graphicsCtx;
        
        // Check if this is part of a grid/flow
        if (_memberToGridFlow.exists(id)) {
            removeGridFlowMember(id); // This calls removeIndex internally
            return;
        }
        
        // Check if this is a container with grid/flow
        if (_gridFlowGroups.exists(id)) {
            removeGridFlowContainer(id); // This calls removeIndex internally
            return;
        }
        
        // Standard removal for individual dimensions
        var removedGroup = _commandGroups.get(id);
        var dependencyRecord = _dependencyGraph.get(id);
        
        // Update dependent dimensions first
        for (dependentId in dependencyRecord.dependents) {
            resolveDependencyAfterRemoval(dependentId, id, removedGroup);
            gtx.recalculateIndividualDimensionDirect(dependentId);
        }
        
        // Clean up tracking
        _commandGroups.remove(id);
        _dependencyGraph.remove(id);
        
        var dimIndex = _idToIndex.get(id);
        if (dimIndex != null) {
            gtx.removeIndex(dimIndex);
        }
        
        _idToIndex.remove(id);
    }

    static function removeGridFlowMember(memberId:Int) {
        var containerId = _memberToGridFlow.get(memberId);
        var gridFlowGroup = _gridFlowGroups.get(containerId);
        
        if (gridFlowGroup == null) return;
        
        // Remove from member arrays
        gridFlowGroup.memberIds.remove(memberId);
        var memberIndex = gridFlowGroup.memberIds.indexOf(memberId);
        if (memberIndex >= 0) {
            gridFlowGroup.memberIndices.splice(memberIndex, 1);
        }
        
        // Update dependencies for flow items
        switch (gridFlowGroup.type) {
            case FlowFixed(_, _) | FlowVariable(_): {
                var removedIndex = gridFlowGroup.memberIds.indexOf(memberId);
                if (removedIndex > 0 && removedIndex < gridFlowGroup.memberIds.length - 1) {
                    var prevId = gridFlowGroup.memberIds[removedIndex - 1];
                    var nextId = gridFlowGroup.memberIds[removedIndex + 1];
                    addDependency(nextId, prevId);
                }
            }
            default: // Grid items don't need chain repair
        }
        
        // Clean up tracking
        _memberToGridFlow.remove(memberId);
        _commandGroups.remove(memberId);
        _dependencyGraph.remove(memberId);
        _idToIndex.remove(memberId);
        
        var gtx = Application.instance.graphicsCtx;
        var dimIndex = _idToIndex.get(memberId);
        if (dimIndex != null) {
            gtx.removeIndex(dimIndex);
        }
        
        // Recalculate the grid/flow
        gtx.recalculateGridFlowGroupDirect(containerId);
    }

    static function removeGridFlowContainer(containerId:Int) {
        var gridFlowGroup = _gridFlowGroups.get(containerId);
        if (gridFlowGroup == null) return;
        
        var gtx = Application.instance.graphicsCtx;
        
        for (memberId in gridFlowGroup.memberIds.copy()) {
            _memberToGridFlow.remove(memberId);
            _commandGroups.remove(memberId);
            _dependencyGraph.remove(memberId);
            
            var dimIndex = _idToIndex.get(memberId);
            if (dimIndex != null) {
                gtx.removeIndex(dimIndex);
            }
            
            _idToIndex.remove(memberId);
        }
        
        // Remove the container group
        _gridFlowGroups.remove(containerId);
        _commandGroups.remove(containerId);
        _dependencyGraph.remove(containerId);
        
        var containerIndex = _idToIndex.get(containerId);
        if (containerIndex != null) {
            gtx.removeIndex(containerIndex);
        }
        
        _idToIndex.remove(containerId);
    }

    static function resolveDependencyAfterRemoval(dependentId:Int, removedId:Int, removedGroup:CommandGroup) {
        var dependentGroup = _commandGroups.get(dependentId);
        var dependentRecord = _dependencyGraph.get(dependentId);
        
        // Find what the removed dimension was depending on
        var removedDependencies = _dependencyGraph.get(removedId).dependsOn;
        
        // Update commands that referenced the removed dimension
        var updatedCommands:Array<DimCommand> = [];
        
        for (cmd in dependentGroup.commands) {
            var updatedCmd = redirectCommand(cmd, removedId, removedDependencies, removedGroup);
            updatedCommands.push(updatedCmd);
        }
        
        // Update the group's commands
        dependentGroup.commands = updatedCommands;
        dependentGroup.dependencies.resolvedCommands = updatedCommands;
        
        // Update dependency relationships
        dependentRecord.dependsOn.remove(removedId);
        for (newDepId in removedDependencies) {
            if (newDepId != dependentId) { // Avoid self-dependency
                addDependency(dependentId, newDepId);
            }
        }
    }

    static function redirectCommand(cmd:DimCommand, removedId:Int, newDependencies:Array<Int>, removedGroup:CommandGroup):DimCommand {
        return switch (cmd) {
            case DimAlign(to, halign, valign): {
                if (getIdFromDimIndex(to) == removedId) {
                    // Redirect to what the removed dimension was aligned to
                    var newTarget = findBestAlignmentTarget(newDependencies, removedGroup.commands);
                    DimAlign(getIndexFromId(newTarget), halign, valign);
                } else {
                    cmd;
                }
            }
            case DimVAlign(to, valign): {
                if (getIdFromDimIndex(to) == removedId) {
                    var newTarget = findBestAlignmentTarget(newDependencies, removedGroup.commands);
                    DimVAlign(getIndexFromId(newTarget), valign);
                } else {
                    cmd;
                }
            }
            case DimHAlign(to, halign): {
                if (getIdFromDimIndex(to) == removedId) {
                    var newTarget = findBestAlignmentTarget(newDependencies, removedGroup.commands);
                    DimHAlign(getIndexFromId(newTarget), halign);
                } else {
                    cmd;
                }
            }
            // Add similar cases for other alignment commands
            default: cmd;
        };
    }

    static function findBestAlignmentTarget(dependencies:Array<Int>, removedCommands:Array<DimCommand>):Int {
        // Strategy: Find the most "primary" dependency
        // Priority: containers > positioned elements > other elements
        
        for (depId in dependencies) {
            if (_commandGroups.exists(depId)) {
                var group = _commandGroups.get(depId);
                // Prefer containers or screen-aligned elements
                if (isContainerOrScreenAligned(group)) {
                    return depId;
                }
            }
        }
        
        // Fallback to first available dependency
        return dependencies.length > 0 ? dependencies[0] : -1;
    }

    static function isContainerOrScreenAligned(group:CommandGroup):Bool {
        // Check if this is likely a container or screen-aligned element
        if (group.initCommand != null) {
            return switch (group.initCommand) {
                case CentreScreenY(_, _, _): true;
                case CentreScreenX(_, _, _): true;
                case CentreScreenFromSize(_, _): true;
                case CreateDimAlignScreen(_, _, _, _, _): true;
                default: false;
            };
        }
        
        // Check for screen alignment commands
        for (cmd in group.commands) {
            switch (cmd) {
                case ScreenAlignX(_, _): return true;
                case ScreenAlignY(_, _): return true;
                default: continue;
            }
        }
        
        return false;
    }

    public static function getIndexFromId(id:Int):DimIndex {
        return _idToIndex.exists(id) ? _idToIndex.get(id) : Direct(-1);
    }

    /**
    * Get IDs in topological order (dependencies first)
    * @param targetIds Optional array of specific IDs to order. If null, orders all IDs.
    */
    public static function getTopologicalOrder(?targetIds:Array<Int>):Array<Int> {
        if (targetIds == null) {
            targetIds = [for (id in _commandGroups.keys()) id];
        }
        
        var visited:Map<Int, Bool> = new Map();
        var result:Array<Int> = [];
        
        function visit(id:Int) {
            if (visited.get(id) || !targetIds.contains(id)) return;
            visited.set(id, true);
            
            if (_dependencyGraph.exists(id)) {
                var record = _dependencyGraph.get(id);
                for (depId in record.dependsOn) {
                    if (targetIds.contains(depId)) { // Only visit dependencies in our target set
                        visit(depId);
                    }
                }
            }
            
            result.push(id);
        }
        
        for (id in targetIds) {
            visit(id);
        }
        
        return result;
    }

    public static function getCommandGroup(id:Int):Null<CommandGroup> {
        return _commandGroups.get(id);
    }

    public static function getGridFlowGroup(containerId:Int):Null<GridFlowGroup> {
        return _gridFlowGroups.get(containerId);
    }

    public static function getGridFlowContainerIds():Array<Int> {
        var ids:Array<Int> = [];
        for (id in _gridFlowGroups.keys()) {
            ids.push(id);
        }
        return ids;
    }

    public static function getContainerIds():Array<Int> {
        var ids:Array<Int> = [];
        for (group in _commandGroups) {
            var enhancedGroup:EnhancedCommandGroup = cast group;
            if (enhancedGroup.isGridFlowContainer == true) {
                ids.push(group.id);
            }
        }
        return ids;
    }

    public static function getNonGridFlowIds():Array<Int> {
        var ids:Array<Int> = [];
        for (id in _commandGroups.keys()) {
            if (!_gridFlowGroups.exists(id) && !_memberToGridFlow.exists(id)) {
                ids.push(id);
            }
        }
        return ids;
    }

    static function addDimToGraphicsContext(dim:Dim, addLogic:ContainerAddLogic, ?parent:DimIndex) {
        var gtx = Application.instance.graphicsCtx;
        var result:DimIndex = null;
        switch (addLogic) {
            case Empty(linked): {
                result = gtx.addEmpty(dim, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1));
            }
            case Ui(id, linked): {
                result = gtx.addUI(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1));
            }
            case Static(id, linked): {
                result = gtx.addStatic(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1));
            }
            case Sprite(id, linked): {
                result = gtx.addSprite(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1));
            }
        }
        return result;
    }

    static function getDimensionIndicesFromGroup(group:Array<Dim>, addLogic:ContainerAddLogic, parent:DimIndex):Array<DimIndex> {
        var gtx = Application.instance.graphicsCtx;
        var resultIndices = new Array<DimIndex>();

        for (i in 0...group.length) {
            var dim = group[i];
            switch (addLogic) {
                case Ui(id, linked):
                    resultIndices.push(gtx.addUI(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1)));
                case Static(id, linked):
                    resultIndices.push(gtx.addStatic(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1)));
                case Sprite(id, linked):
                    resultIndices.push(gtx.addSprite(dim, id ?? Id.None, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1)));
                case Empty(linked):
                    resultIndices.push(gtx.addEmpty(dim, linked != null ? DimIndexUtils.getDirectIndex(linked) : (parent != null ? DimIndexUtils.getDirectIndex(parent) : -1)));
            }
        }

        return resultIndices;
    }

    public static function beginEdit() {
        _editMode = true;
    }

    public static function endEdit() {
        _editMode = false;
    }

    public static function advanceOrder() {
        _order += 1;
    }

    public static function reduceOrder() {
        _order -= 1;
    }

    public static function beginInvisible() {
        _visibility = false;
    }

    public static function endInvisible() {
        _visibility = true;
    }

    public static function createFromDim(dim:Dim, addLogic:ContainerAddLogic):DimResult {
        var result = dim.clone();
        result.order = _order;
        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
            addCommandResultInit(resultIndex, FromDim(dim));
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
	 * Create a dimension block from the given width and height, centering in the middle of the screen.
	 * @param width The width of the object to centre.
	 * @param height The height of the object to centre.
	 */
	public static function centreScreenFromSize(width:Float, height:Float, addLogic:ContainerAddLogic):DimResult {
        var x = (System.windowWidth() - width) / 2;
        var y = (System.windowHeight() - height) / 2;
        var result = new Dim(x, y, width, height, _order);
        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
            addCommandResultInit(resultIndex, CentreScreenFromSize(width, height));
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
     * Create a dimension block from the given width and given offset on the Y-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetY The offset from the top of the screen.
     */
    public static function centreScreenY(width:Float, height:Float, offsetY:Float, addLogic:ContainerAddLogic):DimResult {
        var x = (System.windowWidth() - width) / 2;
        var result = new Dim(x, offsetY, width, height, _order);
        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
            addCommandResultInit(resultIndex, CentreScreenY(width, height, offsetY));
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
     * Create a dimension block from the given width and given offset on the X-axis.
     * @param width The width of the object.
     * @param height The height of the object.
     * @param offsetX The offset from the left of the screen.
     */
    public static function centreScreenX(width:Float, height:Float, offsetX:Float, addLogic:ContainerAddLogic):DimResult {
        var y = (System.windowHeight() - height) / 2;
        var result = new Dim(offsetX, y, width, height, _order);
        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
            addCommandResultInit(resultIndex, CentreScreenX(width, height, offsetX));
        }

        return {
            index: resultIndex,
            dim: result
        };
    }

    /**
     * Create a dimension block aligned to the screen, with the given width and height, and the given vertical and horizontal alignment.
     * @param width The width of the dimension.
     * @param height The height of the dimension.
     * @param valign The vertical alignment to use.
     * @param halign The horizontal alignment to use.
     * @param offsetX The offset from the left of the screen.
     * @param offsetY The offset from the top of the screen.
     */
    public static function createDimAlignScreen(width:Float, height:Float, valign:VerticalAlign, halign:HorizontalAlign, offsetX:Float, offsetY:Float, addLogic:ContainerAddLogic):DimResult {
        var x = 0.0;
        var y = 0.0;
        if (valign == VALIGN_TOP)
        {
            y += offsetY;
        }
        else if (valign == VALIGN_CENTRE)
        {
            y = (System.windowHeight() - height) / 2;
            y += offsetY;
        }
        else if (valign == VALIGN_BOTTOM)
        {
            y = System.windowHeight() - height;
            y -= offsetY;
        }

        if (halign == HALIGN_LEFT)
        {
            x = offsetX;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            x = (System.windowWidth() - width) / 2;
            x += offsetX;
        }
        else if (halign == HALIGN_RIGHT)
        {
            x = System.windowWidth() - width;
            x -= offsetX;
        }

        var result = new Dim(x, y, width, height, _order);
        result.visible = _visibility;
        var resultIndex:DimIndex = null;

        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
            addCommandResultInit(resultIndex, CreateDimAlignScreen(width, height, valign, halign, new FastVector2(offsetX, offsetY)));
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
    * Create a new dimension offset from an existing dimension.
    *
    * @param from The dim to reference.
    * @param offset The offset value from the given dimension.
    **/
    public static function createFromOffset(fromIndex:DimIndex, offset:FastVector2, addLogic:ContainerAddLogic):DimResult {
        var gtx = Application.instance.graphicsCtx;
        var from = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(fromIndex));

        var result = new Dim(from.x + offset.x, from.y + offset.y, from.width, from.height, _order);
        result.visible = _visibility;
        var resultIndex:DimIndex = null;

        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic);
            addCommandResultInit(resultIndex, CreateFromOffset(fromIndex, offset));
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
     * Align the given dimension along the x-axis of the current game client.
     * @param a The dimension.
     * @param halign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static function screenAlignX(aIndex:DimIndex, halign:Int, offset:FastVector2) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        if (halign == HALIGN_LEFT)
        {
            a.x = offset.x;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            a.x = ((System.windowWidth() - a.width) / 2) + offset.x;
        }
        else if (halign == HALIGN_RIGHT)
        {
            a.x = System.windowWidth() - a.width - offset.x;
        }

        if (!_editMode) {
            addCommandResult(aIndex, ScreenAlignX(halign, offset));
        }
    }

    /**
     * Align the given dimension along the y-axis of the current game client.
     * @param a The dimension.
     * @param valign The alignment to give to the dimension.
     * @param offset A `FastVector2` offset from the anchor point of the alignment.
     */
    public static function screenAlignY(aIndex:DimIndex, valign:Int, offset:FastVector2) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        if (valign == VALIGN_TOP)
        {
            a.y = offset.y;
        }
        else if (valign == VALIGN_CENTRE)
        {
            a.y = ((System.windowHeight() - a.height) / 2) + offset.y;
        }
        else if (valign == VALIGN_BOTTOM)
        {
            a.y = System.windowHeight() - a.height + offset.y;
        }

        if (!_editMode) {
            addCommandResult(aIndex, ScreenAlignY(valign, offset));
        }
    }

    /**
     * Create a series of dimensions representing a grid, with each column and row of 
     * equal width and height proportionate to the number of given columns and rows to the container.
     * @param container The container dimension to create the grid from.
     * @param columns The number of equally sized columns.
     * @param rows The number of equally sized rows.
     */
    public static function dimGridEquals(containerIndex:DimIndex, columns:Int, rows:Int, ?addLogic:ContainerAddLogic):Array<DimResult> {
        var gtx = Application.instance.graphicsCtx;
        var container = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(containerIndex));

        var cellWidth = container.width / columns;
        var cellHeight = container.height / rows;
        var results = [];

        for (r in 0...rows)
        {
            for (c in 0...columns)
            {
                var cell = new Dim(c * cellWidth + container.x, r * cellHeight + container.y, cellWidth, cellHeight, _order);
                cell.visible = _visibility;
                results.push(cell);
            }
        }

        var resultIndices:Array<DimIndex> = [];

        if (!_editMode) {
            resultIndices = getDimensionIndicesFromGroup(results, addLogic ?? Empty(), containerIndex);
            addCommandResultInit(containerIndex, CreateGridEquals(containerIndex, columns, rows, resultIndices));
        }

        var dimResults:Array<DimResult> = [];
        for (i in 0...results.length) {
            var index:DimIndex = null;
            if (i < resultIndices.length) {
                index = resultIndices[i];
            }

            dimResults.push({
                dim: results[i],
                index: index
            });
        }

        return dimResults;
    }

    /**
     * Create a series of dimensions representing a grid, containing specific ratios for each set of columns and rows based on the size of the given container.
     * @param container The container dimension to create the grid from.
     * @param columns An array representing the ratios for the columns in the grid.
     * @param rows An array representing the ratios for the rows in the grid.
     */
    public static function dimGridFloats(containerIndex:DimIndex, columns:Array<Float>, rows:Array<Float>, ?addLogic:ContainerAddLogic):Array<DimResult> {
        var gtx = Application.instance.graphicsCtx;
        var container = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(containerIndex));

        var results = [];
        var startY = 0.0;
        for (r in 0...rows.length)
        {
            var cellHeight = container.height * rows[r];
            var startX = 0.0;
            for (c in 0...columns.length)
            {
                var cellWidth = container.width * columns[c];
                var cell = new Dim(startX + container.x, startY + container.y, cellWidth, cellHeight, _order);
                cell.visible = _visibility;
                results.push(cell);
                startX += cellWidth;
            }

            startY += cellHeight;
        }

        var resultIndices:Array<DimIndex> = [];

        if (!_editMode) {
            resultIndices = getDimensionIndicesFromGroup(results, addLogic ?? Empty(), containerIndex);
            addCommandResultInit(containerIndex, CreateGridFloats(containerIndex, columns, rows, resultIndices));
        }

        var dimResults:Array<DimResult> = [];
        for (i in 0...results.length) {
            var index:DimIndex = null;
            if (i < resultIndices.length) {
                index = resultIndices[i];
            }

            dimResults.push({
                dim: results[i],
                index: index
            });
        }

        return dimResults;
    }

    /**
     * Create a series of dimensions representing a grid, using the specific given columns and rows with varying size methods.
     * Any cell sizes with the method `DIM_SIZING_PIXELS` are calculated first, and the remaining width or height of the
     * column or row is then used to determine any sizes with the method `DIM_SIZING_PERCENT`. Any pixel sizes that
     * are greater than the width or height of the given container will supersede any provided percentage sizes.
     * @param container The container dimension to create the grid from.
     * @param columns An array of column sizes.
     * @param rows An array of row sizes.
     */
    public static function dimGrid(containerIndex:DimIndex, columns:Array<DimCellSize>, rows:Array<DimCellSize>, ?addLogic:ContainerAddLogic):Array<DimResult> {
        var gtx = Application.instance.graphicsCtx;
        var container = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(containerIndex));

        var totalPreciseWidth = 0.0;
        var totalPreciseHeight = 0.0;
        for (c in columns)
        {
            if (c.sizing == DIM_SIZING_PIXELS)
                totalPreciseWidth += c.value;
        }

        for (r in rows)
        {
            if (r.sizing == DIM_SIZING_PIXELS)
                totalPreciseHeight += r.value;
        }

        var remainingWidth = container.width - totalPreciseWidth;
        var remainingHeight = container.height - totalPreciseHeight;
        var contentWidth = totalPreciseWidth;
        var contentHeight = totalPreciseHeight;

        for (c in columns)
        {
            if (c.sizing == DIM_SIZING_PERCENT)
                contentWidth += (c.value * remainingWidth);
        }

        for (r in rows)
        {
            if (r.sizing == DIM_SIZING_PERCENT)
                contentHeight += (r.value * remainingHeight);
        }

        var contentX = ((container.width - contentWidth) / 2) + container.x;
        var contentY = ((container.height - contentHeight) / 2) + container.y;

        var results = [];

        var startY = contentY;
        for (r in rows)
        {
            var y = 0.0;
            var height = 0.0;

            if (r.sizing == DIM_SIZING_PERCENT)
            {
                height = (r.value * remainingHeight);
                y = startY;
                startY += height;
            }
            else if (r.sizing == DIM_SIZING_PIXELS)
            {
                y = startY;
                height = r.value;
                startY += height;
            }

            var startX = contentX;
            for (c in columns)
            {
                var x = 0.0;
                var width = 0.0;
                
                if (c.sizing == DIM_SIZING_PERCENT)
                {
                    width = (c.value * remainingWidth);
                    x = startX;
                    startX += width;
                }
                else if (c.sizing == DIM_SIZING_PIXELS)
                {
                    x = startX;
                    width = c.value;
                    startX += width;
                }

                var cell = new Dim(x, y, width, height, _order);
                cell.visible = _visibility;
                results.push(cell);
            }
        }

        
        var resultIndices:Array<DimIndex> = [];

        if (!_editMode) {
            resultIndices = getDimensionIndicesFromGroup(results, addLogic ?? Empty(), containerIndex);
            addCommandResultInit(containerIndex, CreateGrid(containerIndex, columns, rows, resultIndices));
        }

        var dimResults:Array<DimResult> = [];
        for (i in 0...results.length) {
            var index:DimIndex = null;
            if (i < resultIndices.length) {
                index = resultIndices[i];
            }

            dimResults.push({
                dim: results[i],
                index: index
            });
        }

        return dimResults;
    }

    public static function dimMultiCellSize(cellSize:DimCellSize, count:Int):Array<DimCellSize> {
        var results = [];
        for (i in 0...count)
            results.push({ value: cellSize.value, sizing: cellSize.sizing });
        return results;
    }

    static var containerColumnOrRow:Dim;
    static var containerDirection:Int;
    static var containerCellSize:Dim;
    static var containerCell:Int;
    static var containerMethod:Int;
    static var containerOffset:FastVector2;

    static var flowContainerIndex:DimIndex;
    static var flowResults:Array<Dim>;
    static var flowAddLogic:ContainerAddLogic;

    /**
     * Create a dimension column, within which each time the function `getNewDim` is called,
     * a row is created within this column below the last row created.
     * @param container The container to use for creating new rows.
     * @param size The dim of each cell.
     * @param direction 1 for up, 2 for down, 3 for left, 4 for right
     */
    public static function dimFixedFlow(containerIndex:DimIndex, size:Dim, direction:Int, ?addLogic:ContainerAddLogic) {
        var gtx = Application.instance.graphicsCtx;
        var container = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(containerIndex));

        flowContainerIndex = containerIndex;
        containerColumnOrRow = container;
        containerCellSize = size;
        containerDirection = direction;
        containerMethod = FLOW_FIXED;
        containerCell = 0;
        containerOffset = new FastVector2();
        flowAddLogic = addLogic != null ? addLogic : Empty();
        flowResults = [];

        if (direction == Direction.Up) {
            containerOffset = new FastVector2(0, containerColumnOrRow.getHeight() + containerColumnOrRow.getY());
        }
        else if (direction == Direction.Left) {
            containerOffset = new FastVector2(containerColumnOrRow.getWidth() + containerColumnOrRow.getX(), 0);
        }
    }

    /**
     * 
     * @param container The container to use for creating new rows.
     * @param direction 1 for up, 2 for down, 3 for left, 4 for right
     */
    public static function dimVariableFlow(containerIndex:DimIndex, direction:Int, ?addLogic:ContainerAddLogic) {
        var gtx = Application.instance.graphicsCtx;
        var container = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(containerIndex));

        flowContainerIndex = containerIndex;
        containerColumnOrRow = container;
        containerDirection = direction;
        containerOffset = new FastVector2();
        if (direction == Direction.Up) {
            containerOffset = new FastVector2(0, containerColumnOrRow.getHeight() + containerColumnOrRow.getY());
        }
        else if (direction == Direction.Left) {
            containerOffset = new FastVector2(containerColumnOrRow.getWidth() + containerColumnOrRow.getX(), 0);
        }

        containerMethod = FLOW_VARIABLE;
        containerCellSize = new Dim(0, 0, 0, 0);
        containerCell = 0;
        flowAddLogic = addLogic != null ? addLogic : Empty();
        flowResults = [];
    }

    public static function dimVariableSetNextDim(dim:Dim) {
        if (containerMethod == FLOW_VARIABLE) {
            containerCellSize = dim.clone();
        }
    }

    public static function getNewDim(padding:Float = 0):Dim {
        if (containerColumnOrRow != null && containerDirection > 0 && containerCellSize != null) {
            var x = containerColumnOrRow.getX();
            var y = containerColumnOrRow.getY();
            var width = containerColumnOrRow.getWidth();
            var height = containerColumnOrRow.getHeight();
            if (containerDirection == Direction.Up)
            {
                containerOffset.y -= containerCellSize.height + padding;
                y = containerOffset.y + y;
                height = containerCellSize.height;
            }
            else if (containerDirection == Direction.Down)
            {
                containerOffset.y += containerCellSize.height;
                y = containerOffset.y;

                height = containerCellSize.height;
            }
            else if (containerDirection == Direction.Left)
            {
                containerOffset.x -= containerCellSize.width + padding;
                x = containerOffset.x + x;

                width = containerCellSize.width;
            }
            else if (containerDirection == Direction.Right)
            {
                containerOffset.x += containerCellSize.width;
                x = containerOffset.x;
                width = containerCellSize.width;
            }

            var result = new Dim(x, y, width, height, _order);
            result.visible = _visibility;
            flowResults.push(result);
            return result;
        }

        return null;
    }

    /**
    * Ends the current flow of dimensions, returning an array of dimension indices that were created during the flow.
    * This function should be called after all dimensions have been created using `getNewDim`.
    * @return An array of `DimIndex` representing the dimensions created during the flow.
    **/
    public static function endFlow():Array<DimResult> {
        var resultIndices:Array<DimIndex> = [];

        if (!_editMode) {
            resultIndices = getDimensionIndicesFromGroup(flowResults, flowAddLogic, flowContainerIndex);

            if (containerMethod == FLOW_FIXED) {
                addCommandResult(flowContainerIndex, CreateFixedFlow(flowContainerIndex, containerCellSize, cast containerDirection, resultIndices));
            }
            else if (containerMethod == FLOW_VARIABLE) {
                addCommandResult(flowContainerIndex, CreateVariableFlow(flowContainerIndex, cast containerDirection, resultIndices));
            }
        }

        var dimResults:Array<DimResult> = [];
        for (i in 0...flowResults.length) {
            var index:DimIndex = null;
            if (i < resultIndices.length) {
                index = resultIndices[i];
            }

            dimResults.push({
                dim: flowResults[i],
                index: index
            });
        }

        flowResults = [];

        return dimResults;
    }

    /**
     * Create a new dimension from an existing dimension, offsetting by the value of x as a margin from the given dimension.
     * If `offsetX` is less than `0`, then the new dimension will appear on the left of the new dimension, rather than the right.
     * If `offsetX` is equal to `0`, the new dimension will be to the right with no margin.
     * @param a The current dimension to use.
     * @param offsetX The value to offset the new dimension.
     */ 
    public static function dimOffsetX(aIndex:DimIndex, offsetX:Float, ?addLogic:ContainerAddLogic):DimResult {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        var result:Dim = null;

        if (offsetX >= 0)
            result = new Dim(a.x + a.width + offsetX, a.y, a.width, a.height, _order);
        else if (offsetX < 0)
            result = new Dim(a.x - a.width - offsetX, a.y, a.width, a.height, _order);

        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic ?? Empty());
            addCommandResultInit(aIndex, DimOffsetX(aIndex, offsetX));
        }
        
        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
     * Create a new dimension from an existing dimension, offsetting by the value of y as a margin from the given dimension.
     * If `offsetY` is less than `0`, then the new dimension will appear above the new dimension, rather than below.
     * If `offsetY` is equal to `0`, the new dimension will be below with no margin.
     * @param a The current dimension to use.
     * @param offsetY The value to offset the new dimension.
     */
    public static function dimOffsetY(aIndex:DimIndex, offsetY:Float, ?addLogic:ContainerAddLogic):DimResult {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        var result:Dim = null;

        if (offsetY >= 0)
            result = new Dim(a.x, a.y + a.height + offsetY, a.width, a.height, _order);
        else if (offsetY < 0)
            result = new Dim(a.x, a.y - a.height - offsetY, a.width, a.height, _order);

        result.visible = _visibility;

        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic ?? Empty());
            addCommandResultInit(resultIndex, DimOffsetY(aIndex, offsetY));
        }

        return {
            dim: result,
            index: resultIndex
        };
    }

    /**
     * Aligns dimension `b` to `a`, with the given alignment options. If both alignment values are set to CENTRE/MIDDLE, `b` will effectively be centred to `a`.
     * @param a The first dimension.
     * @param b The second dimension.
     * @param valign The vertical alignment `b` should be to `a`.
     * @param halign The horizontal alignment `b` should be to `a`.
     */
    public static function dimAlign(aIndex:DimIndex, bIndex:DimIndex, valign:Int, halign:Int) {
        dimVAlign(aIndex, bIndex, valign, true);
        dimHAlign(aIndex, bIndex, halign, true);

        if (!_editMode) {
            addCommandResult(aIndex, DimAlign(bIndex, halign, valign));
        }
    }

    /**
     * Aligns dimension `b` to `a` on the Y-axis using the given vertical alignment.
     * @param a The first dimension.
     * @param b The second dimension.
     * @param valign The vertical alignment `b` should be to `a`.
     */
    public static function dimVAlign(aIndex:DimIndex, bIndex:DimIndex, valign:Int, noCommandCreation:Bool = false) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));
        var b = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(bIndex));

        if (valign == VALIGN_TOP)
        {
            b.y = a.y;
        }
        else if (valign == VALIGN_BOTTOM)
        {
            b.y = a.y + a.height - b.height;
        }
        else if (valign == VALIGN_CENTRE)
        {
            b.y = a.y + ((a.height - b.height) / 2);
        }

        if (!noCommandCreation && !_editMode) {
            addCommandResult(aIndex, DimVAlign(bIndex, valign));
        }
    }

    /**
     * Aligns dimension `b` to `a` on the X-axis using the given horizontal alignment.
     * @param a The first dimension.
     * @param b The second dimension.
     * @param valign The horizontal alignment `b` should be to `a`.
     */
    public static function dimHAlign(aIndex:DimIndex, bIndex:DimIndex, halign:Int, noCommandCreation:Bool = false) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));
        var b = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(bIndex));

        if (halign == HALIGN_LEFT)
        {
            b.x = a.x;
        }
        else if (halign == HALIGN_RIGHT)
        {
            b.x = a.x + a.width - b.width;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            b.x = a.x + ((a.width - b.width) / 2);
        }

        if (!noCommandCreation && !_editMode) {
            addCommandResult(aIndex, DimHAlign(bIndex, halign));
        }
    }

    public static function dimAlignOffset(a:DimIndex, b:DimIndex, halign:Int, valign:Int, hoffset:Float = 0.0, voffset:Float = 0.0) {
        dimVAlignOffset(a, b, valign, voffset, true);
        dimHAlignOffset(a, b, halign, hoffset, true);

        if (!_editMode) {
            addCommandResult(a, DimAlignOffset(b, halign, valign, hoffset, voffset));
        }
    }

    public static function dimVAlignOffset(aIndex:DimIndex, bIndex:DimIndex, valign:Int, offset:Float = 0.0, noCommandCreation:Bool = false) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));
        var b = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(bIndex));

        if (valign == VALIGN_TOP)
        {
            b.y = a.y - b.height - offset;
        }
        else if (valign == VALIGN_BOTTOM)
        {
            b.y = a.y + a.height + offset;
        }
        else if (valign == VALIGN_CENTRE)
        {
            b.y = a.y - ((b.height - a.height) / 2);
        }

        if (!noCommandCreation && !_editMode) {
            addCommandResult(aIndex, DimVAlignOffset(bIndex, valign, offset));
        }
    }

    public static function dimHAlignOffset(aIndex:DimIndex, bIndex:DimIndex, halign:Int, offset:Float = 0.0, noCommandCreation:Bool = false) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));
        var b = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(bIndex));

        if (halign == HALIGN_LEFT)
        {
            b.x = a.x - b.width - offset;
        }
        else if (halign == HALIGN_RIGHT)
        {
            b.x = a.x + a.width + offset;
        }
        else if (halign == HALIGN_MIDDLE)
        {
            b.x = a.x - ((b.width - a.width) / 2);
        }

        if (!noCommandCreation && !_editMode) {
            addCommandResult(aIndex, DimHAlignOffset(bIndex, halign, offset));
        }
    }

    /**
     * Scale a given dimension along the X-Axis and Y-Axis and return a new dimension with the results.
     * @param a The dimension to scale.
     * @param scaleX How much to scale, as a percentage (0-1), along the X-Axis.
     * @param scaleY How much to scale, as a percentage (0-1), along the Y-Axis.
     */
    public static function dimScale(aIndex:DimIndex, scaleX:Float, scaleY:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        var ratioWidth = a.width * scaleX;
        var ratioX = a.x + ((a.width - ratioWidth) / 2);
        var ratioHeight = a.height * scaleY;
        var ratioY = a.y + ((a.height - ratioHeight) / 2);
        a.x = ratioX;
        a.y = ratioY;
        a.width = ratioWidth;
        a.height = ratioHeight;

        if (!_editMode) {
            addCommandResult(aIndex, DimScale(scaleX, scaleY));
        }
    }

    /**
     * Scale a given dimension along the X-Axis and return a new dimension with the results.
     * @param a The dimension to scale.
     * @param scaleX How much to scale, as a percentage (0-1), along the X-Axis.
     */
    public static function dimScaleX(aIndex:DimIndex, scaleX:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        var ratioWidth = a.width * scaleX;
        var ratioX = a.x + ((a.width - ratioWidth) / 2);
        a.x = ratioX;
        a.width = ratioWidth;

        if (!_editMode) {
            addCommandResult(aIndex, DimScaleX(scaleX));
        }
    }

    /**
     * Scale a given dimension along the Y-Axis and return a new dimension with the results.
     * @param a The dimension to scale.
     * @param scaleY How much to scale, as a percentage (0-1), along the Y-Axis.
     */
    public static function dimScaleY(aIndex:DimIndex, scaleY:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        var ratioHeight = a.height * scaleY;
        var ratioY = a.y + ((a.height - ratioHeight) / 2);
        a.y = ratioY;
        a.height = ratioHeight;

        if (!_editMode) {
            addCommandResult(aIndex, DimScaleY(scaleY));
        }
    }

    /**
    * Shrink the given dimension by an `amount` in pixels.
    **/
    public static function dimShrink(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        a.width = a.width - amount;
        a.height = a.height - amount;

        if (!_editMode) {
            addCommandResult(aIndex, DimShrink(amount));
        }
    }

    /**
    * Shrink the width of a given dimension by an `amount` in pixels.
    **/
    public static function dimShrinkW(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        a.width = a.width - amount;

        if (!_editMode) {
            addCommandResult(aIndex, DimShrinkW(amount));
        }
    }

    /**
    * Shrink the height of a given dimension by an `amount` in pixels.
    **/
    public static function dimShrinkH(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        a.height = a.height - amount;

        if (!_editMode) {
            addCommandResult(aIndex, DimShrinkH(amount));
        }
    }

    /**
    * Grow the given dimension by an `amount` in pixels.
    **/
    public static function dimGrow(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        a.width = a.width + amount;
        a.height = a.height + amount;

        if (!_editMode) {
            addCommandResult(aIndex, DimGrow(amount));
        }
    }

    /**
    * Grow the width of a given dimension by an `amount` in pixels.
    **/
    public static function dimGrowW(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        a.width = a.width + amount;

        if (!_editMode) {
            addCommandResult(aIndex, DimGrowW(amount));
        }
    }

    /**
    * Grow the height of a given dimension by an `amount` in pixels.
    **/
    public static function dimGrowH(aIndex:DimIndex, amount:Float) {
        var gtx = Application.instance.graphicsCtx;
        var a = gtx.getTempOrCurrentDimAtIndex(DimIndexUtils.getDirectIndex(aIndex));

        a.height = a.height + amount;

        if (!_editMode) {
            addCommandResult(aIndex, DimGrowH(amount));
        }
    }

    /**
     * Measure the width and height of the given text with font and fontSize parameters provided by
     * the given `g2` instance.
     * @param font The instance of a font to measure against.
     * @param fontSize The size of the font.
     * @param text The text to measure.
     */
    public static function getTextDim(font:Font, fontSize:Int, text:String, ?addLogic:ContainerAddLogic):DimResult {
        var result = new Dim(0, 0, font.width(fontSize, text), font.height(fontSize), _order);
        result.visible = _visibility;
        var resultIndex:DimIndex = null;
        if (!_editMode) {
            resultIndex = addDimToGraphicsContext(result, addLogic ?? Empty());
            addCommandResultInit(resultIndex, MeasureText(font, fontSize, text));
        }

		return {
            dim: result,
            index: resultIndex
        };
	}

}