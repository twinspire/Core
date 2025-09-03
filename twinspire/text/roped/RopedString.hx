//
// Developed with assistance from Claude AI - 2025-09-03
//

package twinspire.text.roped;

class RopedString {
  
    private var tokens:Array<Token>;
    private var untokenizedBuffer:String; 
    private var bufferStartPos:Int;
  
    /**
     * A collection of nodes representing chunks of text.
     */
    public var nodes:Array<Node>;
    
    /**
     * A callback function that is called each time a value is appended to this string.
     * The resulting string is passed vianthe first parameter, allowing you to check the value.
     * Return `true` in `tokenize` to reset the string and a numeric value `type` to specify a user-defined token, stored internally.
     */
    public var tokenCallback:(String) -> { tokenize: Bool, type: Int };

    public function getTokens() {
        return tokens;
    }
    
    public function new() {
        nodes = [];
        tokens = [];
        untokenizedBuffer = "";
        bufferStartPos = 0;
    }

    private function updateTokensWithText(insertPos:Int, deltaLength:Int, insertedText:String):Void {
        // First, update existing token positions for any insertions before them
        for (token in tokens) {
            if (token.start >= insertPos) {
                token.start += deltaLength;
            }
            if (token.end >= insertPos) {
                token.end += deltaLength;
            }
        }
        
        // If this is the first text being added, set buffer start position
        if (untokenizedBuffer.length == 0) {
            bufferStartPos = insertPos;
        }
        
        // Add the newly inserted text to the buffer
        untokenizedBuffer += insertedText;
        
        // Check if we should tokenize
        if (tokenCallback != null) {
            var tokenResult = tokenCallback(untokenizedBuffer);
            if (tokenResult.tokenize) {
                // Create token for the entire buffer
                var token = new Token(tokenResult.type, bufferStartPos, bufferStartPos + untokenizedBuffer.length);
                tokens.push(token);
                
                // Reset buffer and advance position
                bufferStartPos += untokenizedBuffer.length;
                untokenizedBuffer = "";
            }
        }
    }

    private function updateTokens(insertPos:Int, deltaLength:Int):Void {
        updateTokensWithText(insertPos, deltaLength, "");
    }

    public function toString():String {
        var result = "";
        for (node in nodes) {
            for (leaf in node.leaves) {
                result += leaf.toString();
            }
        }
        return result;
    }
    
    public function getLines(limit:Int = 100, startLine:Int = 0):Array<{data:Array<Int>, nextNodeStart:Int}> {
        var lines:Array<{data:Array<Int>, nextNodeStart:Int}> = [];
        var currentLine:Array<Int> = [];
        var linesFound = 0;
        var currentLineIndex = 0;
        var nodeStartForFirstLine = 0;
        var foundStartLine = false;
        
        for (nodeIndex in 0...nodes.length) {
            if (linesFound >= limit) break;
            
            var node = nodes[nodeIndex];
            for (leaf in node.leaves) {
                var data = leaf.getData();
                for (charCode in data) {
                    if (charCode == 10) { // Line feed
                        if (currentLineIndex >= startLine && !foundStartLine) {
                            // Mark the node where our first requested line starts
                            nodeStartForFirstLine = nodeIndex;
                            foundStartLine = true;
                        }
                        
                        if (currentLineIndex >= startLine) {
                            lines.push({
                                data: currentLine.copy(),
                                nextNodeStart: nodeStartForFirstLine
                            });
                            linesFound++;
                            if (linesFound >= limit) break;
                        }
                        
                        currentLine = [];
                        currentLineIndex++;
                    } else if (charCode != 13) { // Skip carriage return
                        if (currentLineIndex >= startLine) {
                            currentLine.push(charCode);
                        }
                    }
                }
                if (linesFound >= limit) break;
            }
            if (linesFound >= limit) break;
        }
        
        // Add final line if it has content and we're within our range
        if (currentLine.length > 0 && currentLineIndex >= startLine && linesFound < limit) {
            if (!foundStartLine) {
                nodeStartForFirstLine = nodes.length > 0 ? nodes.length - 1 : 0;
            }
            lines.push({
                data: currentLine,
                nextNodeStart: nodeStartForFirstLine
            });
        }
        
        return lines;
    }
    
    public function getLine(line:Int):Array<Int> {
        var currentLineIndex = 0;
        var currentLine:Array<Int> = [];
        
        for (node in nodes) {
            for (leaf in node.leaves) {
                var data = leaf.getData();
                for (charCode in data) {
                    if (charCode == 10) { // Line feed
                        if (currentLineIndex == line) {
                            return currentLine;
                        }
                        currentLine = [];
                        currentLineIndex++;
                    } else if (charCode != 13) { // Skip carriage return
                        currentLine.push(charCode);
                    }
                }
            }
        }
        
        // Return the line if we're at the target line index
        if (currentLineIndex == line) {
            return currentLine;
        }
        
        return [];
    }
    
    public function findInLine(line:Int, chars:Array<Int>):Int {
        var lineData = getLine(line);
        if (lineData.length == 0 || chars.length == 0) return -1;
        
        // Convert search chars to string for comparison
        var needle = "";
        for (charCode in chars) {
            needle += String.fromCharCode(charCode);
        }
        
        // Convert line data to string
        var lineText = "";
        for (charCode in lineData) {
            lineText += String.fromCharCode(charCode);
        }
        
        // Find position within the line
        var foundIndex = lineText.indexOf(needle);
        if (foundIndex == -1) return -1;
        
        // Convert line-relative position to global position
        var globalPos = 0;
        var currentLineIndex = 0;
        
        for (node in nodes) {
            for (leaf in node.leaves) {
                var data = leaf.getData();
                for (charCode in data) {
                    if (charCode == 10) { // Line feed
                        if (currentLineIndex == line) {
                            return globalPos - lineData.length + foundIndex;
                        }
                        currentLineIndex++;
                    } else if (charCode != 13) { // Skip carriage return
                        // Count position
                    }
                    globalPos++;
                }
            }
        }
        
        return -1;
    }
    
    public function find(chars:Array<Int>):Int {
        if (chars.length == 0) return -1;
    
        var needle = "";
        for (charCode in chars) {
            needle += String.fromCharCode(charCode);
        }
        
        var haystack = toString();
        return haystack.indexOf(needle);
    }
    
    public function findNextToken(type:Int):String {
        for (token in tokens) {
            if (token.type == type) {
                return toString().substring(token.start, token.end);
            }
        }
        return "";
    }
    
    public function findInTokenRange(startType:Int, endType:Int, chars:Array<Int>):Int {
        var needle = "";
        for (charCode in chars) {
            needle += String.fromCharCode(charCode);
        }
        var fullText = toString();
        
        for (token in tokens) {
            if (token.type >= startType && token.type <= endType) {
                var tokenText = fullText.substring(token.start, token.end);
                var foundIndex = tokenText.indexOf(needle);
                if (foundIndex != -1) {
                    return token.start + foundIndex;
                }
            }
        }
        
        return -1;
    }
    
    public function insertToken(char:Int, token:Int, pos:Int):Void {
        insert(char, pos);
        // Create a token at the insertion position
        tokens.push(new Token(token, pos, pos + 1));
    }
    
    public function getTokenId(type:Int):String {
        return findNextToken(type);
    }
    
    public function getTokensInRange(startType:Int, endType:Int):Array<String> {
        var results:Array<String> = [];
        var fullText = toString();
        
        for (token in tokens) {
            if (token.type >= startType && token.type <= endType) {
                results.push(fullText.substring(token.start, token.end));
            }
        }
        
        return results;
    }
    
    public function removeAt(pos:Int) {
        removeRange(pos, pos + 1);
    }
    
    public function removeRange(start:Int, end:Int) {
        if (start >= end || start < 0) return;
        
        var deleteLength = end - start;
        var currentPos = 0;
        var nodesToRemove:Array<Int> = [];
        
        for (nodeIndex in 0...nodes.length) {
            var node = nodes[nodeIndex];
            var leavesToRemove:Array<Int> = [];
            
            for (leafIndex in 0...node.leaves.length) {
                var leaf = node.leaves[leafIndex];
                var leafLength = leaf.length();
                var leafStart = currentPos;
                var leafEnd = currentPos + leafLength;
                
                if (start < leafEnd && end > leafStart) {
                    // This leaf is affected by the deletion
                    var deleteStart = cast (Math.max(0, start - leafStart), Int);
                    var deleteEnd = cast (Math.min(leafLength, end - leafStart), Int);
                    var leafDeleteLength = deleteEnd - deleteStart;
                    
                    if (deleteStart == 0 && deleteEnd == leafLength) {
                        // Remove entire leaf
                        leavesToRemove.push(leafIndex);
                    } else {
                        // Partial deletion within leaf
                        leaf.delete(deleteStart, leafDeleteLength);
                    }
                }
                
                currentPos += leafLength;
            }
            
            // Remove marked leaves (in reverse order to maintain indices)
            leavesToRemove.reverse();
            for (leafIndex in leavesToRemove) {
                node.leaves.splice(leafIndex, 1);
            }
            
            // Mark empty nodes for removal
            if (node.leaves.length == 0) {
                nodesToRemove.push(nodeIndex);
            }
        }
        
        // Remove empty nodes (in reverse order)
        nodesToRemove.reverse();
        for (nodeIndex in nodesToRemove) {
            removeEmptyNode(nodeIndex);
        }
        
        updateTokensAfterDeletion(start, deleteLength);
    }
    
    public function removeToken(type:Int, ?upto:Int):Void {
        var tokensToRemove:Array<Int> = [];
        var removed = 0;
        
        for (i in 0...tokens.length) {
            if (tokens[i].type == type) {
                tokensToRemove.push(i);
                removed++;
                if (upto != null && removed >= upto) {
                    break;
                }
            }
        }
        
        // Remove the tokens and their associated text
        tokensToRemove.reverse();
        for (tokenIndex in tokensToRemove) {
            var token = tokens[tokenIndex];
            removeRange(token.start, token.end);
            tokens.splice(tokenIndex, 1);
        }
    }
    
    public function removeTokenRange(startType:Int, endType:Int):Void {
        var tokensToRemove:Array<Int> = [];
        
        for (i in 0...tokens.length) {
            if (tokens[i].type >= startType && tokens[i].type <= endType) {
                tokensToRemove.push(i);
            }
        }
        
        tokensToRemove.reverse();
        for (tokenIndex in tokensToRemove) {
            var token = tokens[tokenIndex];
            removeRange(token.start, token.end);
            tokens.splice(tokenIndex, 1);
        }
    }

    public function length():Int {
        var totalLength = 0;
        for (node in nodes) {
            for (leaf in node.leaves) {
                totalLength += leaf.length();
            }
        }
        return totalLength;
    }

    public function charAt(index:Int):Int {
        var result = findNodeLeafFromPosition(index);
        if (result.node == -1 || result.leaf == -1) {
            return 0; // Return null character for invalid positions
        }
        
        var node = nodes[result.node];
        var leaf = node.leaves[result.leaf];
        var localPos = calculateLocalPosition(index, result.node, result.leaf);
        
        return leaf.charAt(localPos);
    }

    public function substring(start:Int, end:Int):String {
        var result = "";
        for (i in start...end) {
            result += String.fromCharCode(charAt(i));
        }
        return result;
    }

    public function getStringData():Dynamic {
        return this; // Return the RopedString itself
    }

    public function addChar(char:Int, pos:Int):Void {
        insert(char, pos);
    }

    public function addValue(value:String, pos:Int):Void {
        var chars = [for (i in 0...value.length) value.charCodeAt(i)];
        insertChars(chars, pos);
    }

    public function remove(pos:Int):Void {
        removeAt(pos);
    }

    public function search(data:Array<Int>):Array<{start:Int, end:Int}> {
        var results:Array<{start:Int, end:Int}> = [];
        if (data.length == 0) return results;
        
        var needle = "";
        for (charCode in data) {
            needle += String.fromCharCode(charCode);
        }
        
        var haystack = toString();
        var searchPos = 0;
        
        while (true) {
            var foundIndex = haystack.indexOf(needle, searchPos);
            if (foundIndex == -1) break;
            
            results.push({start: foundIndex, end: foundIndex + data.length});
            searchPos = foundIndex + 1; // Continue search from next position
        }
        
        return results;
    }

    public function insert(char:Int, pos:Int):Void {
        insertChars([char], pos);
    }

    public function insertChars(chars:Array<Int>, pos:Int):Void {
        if (chars.length == 0) return;
        
        // Convert chars to string for tokenization
        var insertedText = "";
        for (charCode in chars) {
            insertedText += String.fromCharCode(charCode);
        }
        
        if (nodes.length == 0) {
            // Create first node and leaf
            var node = new Node();
            var leaf = new Leaf(chars);
            node.leaves.push(leaf);
            nodes.push(node);
            updateTokensWithText(pos, chars.length, insertedText);
            return;
        }
        
        var result = findNodeLeafFromPosition(pos);
        
        if (result.node == -1) {
            // Position is at or beyond end, append to last node
            var lastNode = nodes[nodes.length - 1];
            var lastLeaf = lastNode.leaves[lastNode.leaves.length - 1];
            
            if (lastLeaf.insert(lastLeaf.length(), chars) == null) {
                // Need to create new leaf
                var newLeaf = new Leaf(chars);
                lastNode.leaves.push(newLeaf);
            }
            
            updateTokensWithText(pos, chars.length, insertedText);
            return;
        }
        
        var node = nodes[result.node];
        var leaf = node.leaves[result.leaf];
        var localPos = calculateLocalPosition(pos, result.node, result.leaf);
        
        var insertResult = leaf.insert(localPos, chars);
        if (insertResult == null) {
            // Need to split the leaf
            var splitResult = leaf.split(localPos);
            
            // Replace current leaf with left part
            node.leaves[result.leaf] = splitResult.left;
            
            // Create a new leaf with just the inserted chars
            var insertedLeaf = new Leaf(chars);
            
            // Insert the new leaf and then the right part
            node.leaves.insert(result.leaf + 1, insertedLeaf);
            node.leaves.insert(result.leaf + 2, splitResult.right);
            
            // Check if node is too large and needs splitting
            if (node.leaves.length > MAX_NODE_SIZE) {
                splitNode(result.node);
            }
        }
        
        updateTokensWithText(pos, chars.length, insertedText);
    }

    private static var MAX_NODE_SIZE:Int = 8; // Adjust as needed

    private function calculateLocalPosition(globalPos:Int, nodeIndex:Int, leafIndex:Int):Int {
        var localPos = globalPos;
        
        // Subtract lengths from previous nodes
        for (i in 0...nodeIndex) {
            localPos -= nodes[i].getTotalLength();
        }
        
        // Subtract lengths from previous leaves in current node
        var node = nodes[nodeIndex];
        for (i in 0...leafIndex) {
            localPos -= node.leaves[i].length();
        }
        
        return localPos;
    }
    
    private function findNodeLeafFromPosition(pos:Int):{node:Int, leaf:Int} {
        if (nodes.length == 0) return {node: -1, leaf: -1};
        
        var currentPos = 0;
        
        for (nodeIndex in 0...nodes.length) {
            var node = nodes[nodeIndex];
            for (leafIndex in 0...node.leaves.length) {
                var leaf = node.leaves[leafIndex];
                var leafLength = leaf.length();
                
                // Fix: Should check if position falls within this leaf
                if (pos >= currentPos && pos <= currentPos + leafLength) {
                    return {node: nodeIndex, leaf: leafIndex};
                }
                
                currentPos += leafLength;
            }
        }
        
        // If position is at the very end, return the last leaf
        if (nodes.length > 0) {
            var lastNode = nodes[nodes.length - 1];
            if (lastNode.leaves.length > 0) {
                return {node: nodes.length - 1, leaf: lastNode.leaves.length - 1};
            }
        }
        
        return {node: -1, leaf: -1};
    }
    
    private function splitNode(nodeIndex:Int):Void {
        var originalNode = nodes[nodeIndex];
        var totalLeaves = originalNode.leaves.length;
        var splitPoint = Math.floor(totalLeaves / 2);
        
        // Create new node for right half
        var newNode = new Node();
        
        // Move leaves from split point to end into new node
        var leavesToMove = originalNode.leaves.splice(splitPoint, totalLeaves - splitPoint);
        for (leaf in leavesToMove) {
            newNode.leaves.push(leaf);
        }
        
        // Update navigation pointers
        newNode.lastNodeIndex = nodeIndex;
        newNode.nextNodeIndex = originalNode.nextNodeIndex;
        originalNode.nextNodeIndex = nodeIndex + 1;
        
        // If there was a node after the original, update its previous pointer
        if (newNode.nextNodeIndex != -1 && newNode.nextNodeIndex < nodes.length) {
            nodes[newNode.nextNodeIndex].lastNodeIndex = nodeIndex + 1;
        }
        
        // Insert the new node into the nodes array
        nodes.insert(nodeIndex + 1, newNode);
        
        // Update all subsequent node indices in navigation pointers
        for (i in (nodeIndex + 2)...nodes.length) {
            var node = nodes[i];
            if (node.lastNodeIndex > nodeIndex) {
                node.lastNodeIndex++;
            }
            if (node.nextNodeIndex > nodeIndex && node.nextNodeIndex != -1) {
                node.nextNodeIndex++;
            }
        }
    }
    
    private function removeEmptyNode(nodeIndex:Int):Void {
        if (nodeIndex < 0 || nodeIndex >= nodes.length) return;
        
        var node = nodes[nodeIndex];
        
        // If this is the only node, just remove it and clear navigation
        if (nodes.length == 1) {
            nodes.splice(nodeIndex, 1);
            return;
        }
        
        // Update navigation pointers with bounds checking
        if (node.lastNodeIndex != -1 && node.lastNodeIndex < nodes.length) {
            nodes[node.lastNodeIndex].nextNodeIndex = node.nextNodeIndex;
        }
        if (node.nextNodeIndex != -1 && node.nextNodeIndex < nodes.length) {
            nodes[node.nextNodeIndex].lastNodeIndex = node.lastNodeIndex;
        }
        
        // Remove the node
        nodes.splice(nodeIndex, 1);
        
        // Update all subsequent node indices
        for (i in nodeIndex...nodes.length) {
            var currentNode = nodes[i];
            if (currentNode.lastNodeIndex >= nodeIndex) {
                currentNode.lastNodeIndex--;
            }
            if (currentNode.nextNodeIndex > nodeIndex && currentNode.nextNodeIndex != -1) {
                currentNode.nextNodeIndex--;
            }
        }
    }

    private function updateTokensAfterDeletion(deletePos:Int, deltaLength:Int):Void {
        // Update buffer if deletion affects it
        if (deletePos < bufferStartPos + untokenizedBuffer.length) {
            if (deletePos >= bufferStartPos) {
                // Deletion is within buffer
                var bufferDeleteStart = deletePos - bufferStartPos;
                var bufferDeleteEnd = cast (Math.min(untokenizedBuffer.length, bufferDeleteStart + deltaLength), Int);
                
                untokenizedBuffer = untokenizedBuffer.substring(0, bufferDeleteStart) + 
                                untokenizedBuffer.substring(bufferDeleteEnd);
            } else {
                // Deletion starts before buffer
                var remainingDelete = deltaLength - (bufferStartPos - deletePos);
                if (remainingDelete > 0) {
                    untokenizedBuffer = untokenizedBuffer.substring(cast (Math.min(remainingDelete, untokenizedBuffer.length), Int));
                }
                bufferStartPos = deletePos;
            }
        }
        
        // Update buffer position if deletion happened before buffer
        if (deletePos < bufferStartPos) {
            bufferStartPos -= cast (Math.min(deltaLength, bufferStartPos - deletePos), Int);
        }
        
        // Handle existing tokens (same as before)
        var tokensToRemove:Array<Int> = [];
        
        for (i in 0...tokens.length) {
            var token = tokens[i];
            
            if (token.end <= deletePos) {
                // Token is completely before deletion, no change needed
                continue;
            } else if (token.start >= deletePos + deltaLength) {
                // Token is completely after deletion, shift it back
                token.start -= deltaLength;
                token.end -= deltaLength;
            } else {
                // Token overlaps with deletion
                if (token.start < deletePos && token.end > deletePos + deltaLength) {
                    // Token spans across deletion, shrink it
                    token.end -= deltaLength;
                } else {
                    // Token is partially or completely within deletion, remove it
                    tokensToRemove.push(i);
                }
            }
        }
        
        // Remove marked tokens (in reverse order)
        tokensToRemove.reverse();
        for (tokenIndex in tokensToRemove) {
            tokens.splice(tokenIndex, 1);
        }
    }
  
}