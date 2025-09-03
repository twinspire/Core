package twinspire.text.roped;

class RopedString {
  
    private var tokens:Array<Token>;
  
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
    
    public function new() {
        nodes = [];
        tokens = [];
    }

    private function updateTokens(insertPos:Int, deltaLength:Int):Void {
        if (tokenCallback != null) {
            var currentText = toString();
            var tokenResult = tokenCallback(currentText);
            if (tokenResult.tokenize) {
                // Reset and create new token
                var token = new Token(tokenResult.type, insertPos, insertPos + deltaLength);
                tokens.push(token);
            }
        }
        
        // Update existing token positions
        for (token in tokens) {
            if (token.start >= insertPos) {
                token.start += deltaLength;
            }
            if (token.end >= insertPos) {
                token.end += deltaLength;
            }
        }
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
    
    public function getLines(limit:Int = 100, startPos:Int = 0):Array<{data:Array<Int>, nextNodeStart:Int}> {
      
    }
    
    public function getLine(line:Int):Array<Int> {
      
    }
    
    public function findInLine(line:Int, chars:Array<Int>):Int {
      
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
        var needle = String.fromCharCodes(chars);
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
      
    }
    
    public function removeRange(start:Int, end:Int) {
      
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
        var node = nodes[result.node];
        var leaf = node.leaves[result.leaf];
        var localPos = index;
        
        // Calculate local position within the leaf
        for (i in 0...result.node) {
            for (leafItem in nodes[i].leaves) {
                localPos -= leafItem.length();
            }
        }
        for (i in 0...result.leaf) {
            localPos -= node.leaves[i].length();
        }
        
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
        var needle = "";
        for (charCode in data) {
            needle += String.fromCharCode(charCode);
        }
        
        var haystack = toString();
        var foundIndex = haystack.indexOf(needle);
        while (foundIndex > -1) {
            results.push({start: foundIndex, end: foundIndex + data.length});
            foundIndex = haystack.indexOf(needle, foundIndex + 1);
        }
        return results;
    }

    public function insert(char:Int, pos:Int):Void {
        insertChars([char], pos);
    }

    public function insertChars(chars:Array<Int>, pos:Int):Void {
        if (nodes.length == 0) {
            // Create first node and leaf
            var node = new Node();
            var leaf = new Leaf(chars);
            node.leaves.push(leaf);
            node.updateTotalLength();
            nodes.push(node);
            updateTokens(pos, chars.length);
            return;
        }
        
        var result = findNodeLeafFromPosition(pos);
        var node = nodes[result.node];
        var leaf = node.leaves[result.leaf];
        
        // Calculate local position within the leaf
        var localPos = calculateLocalPosition(pos, result.node, result.leaf);
        
        var insertResult = leaf.insert(localPos, chars);
        if (insertResult == null) {
            // Need to split the leaf
            var splitResult = leaf.split(localPos);
            
            // Replace current leaf with left part
            node.leaves[result.leaf] = splitResult.left;
            
            // Insert chars into right part
            splitResult.right.insert(0, chars);
            
            // Insert right part after current position
            node.leaves.insert(result.leaf + 1, splitResult.right);
            
            // Check if node is too large and needs splitting
            if (node.leaves.length > MAX_NODE_SIZE) {
                splitNode(result.node);
            }
        }
        
        node.updateTotalLength();
        updateTokens(pos, chars.length);
    }

    private static var MAX_NODE_SIZE:Int = 8; // Adjust as needed

    private function calculateLocalPosition(globalPos:Int, nodeIndex:Int, leafIndex:Int):Int {
        var localPos = globalPos;
        
        // Subtract lengths from previous nodes
        for (i in 0...nodeIndex) {
            localPos -= nodes[i].totalLength;
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
                
                if (pos >= currentPos && pos <= currentPos + leafLength) {
                    return {node: nodeIndex, leaf: leafIndex};
                }
                
                currentPos += leafLength;
            }
        }
        
        // Return last valid position if pos is beyond string length
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
    
  
}