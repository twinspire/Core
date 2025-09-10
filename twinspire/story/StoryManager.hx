package twinspire.story;

import twinspire.Application;

/**
 * A high-level manager class for handling story parsing and execution.
 * This provides a convenient interface for working with the story system.
 */
class StoryManager
{
    private var parser:Parser;
    private var currentBlock:CommandBlock;
    private var variables:Map<String, Dynamic>;
    
    public function new() {
        parser = new Parser();
        variables = new Map<String, Dynamic>();
    }
    
    /**
     * Load and parse a story file from the Twinspire resources.
     * @param resourceName The name of the story resource to load
     * @return Bool True if the story was loaded successfully, false otherwise
     */
    public function loadStory(resourceName:String):Bool {
        try 
        {
            var blocksCreated = parser.parseFile(resourceName);
            return blocksCreated > 0;
        }
        catch (e:Dynamic)
        {
            trace('Failed to load story: $resourceName - Error: $e');
            return false;
        }
    }
    
    /**
     * Parse story content directly from a string.
     * @param content The story content as a string
     * @param sourceName Optional name for error reporting
     * @return Bool True if parsing was successful, false otherwise
     */
    public function parseStoryContent(content:String, sourceName:String = "direct"):Bool {
        try 
        {
            var blocksCreated = parser.parseString(content, sourceName);
            return blocksCreated > 0;
        }
        catch (e:Dynamic)
        {
            trace('Failed to parse story content: $sourceName - Error: $e');
            return false;
        }
    }
    
    /**
     * Start a conversation by title.
     * @param title The title of the conversation to start
     * @return Array<Command> The translated commands for this conversation, or null if not found
     */
    public function startConversation(title:String):Array<Command> {
        var block = parser.getBlockByTitle(title);
        if (block == null)
        {
            trace('Conversation not found: $title');
            return null;
        }
        
        currentBlock = block;
        return translateCurrentBlock();
    }
    
    /**
     * Get the current conversation block.
     * @return CommandBlock The current block, or null if none is set
     */
    public function getCurrentBlock():CommandBlock {
        return currentBlock;
    }
    
    /**
     * Translate the current block with the current variable state.
     * @return Array<Command> The translated commands
     */
    public function translateCurrentBlock():Array<Command> {
        if (currentBlock == null)
            return [];
        
        var options:TranslateOptions = {
            autoParse: true,
            parseMap: variables,
            fallThroughRealTime: false
        };
        
        return parser.translateBlock(currentBlock, options);
    }
    
    /**
     * Set a variable that can be used in story parsing.
     * @param name The variable name
     * @param value The variable value
     */
    public function setVariable(name:String, value:Dynamic):Void {
        variables.set(name, value);
    }
    
    /**
     * Get a variable value.
     * @param name The variable name
     * @return Dynamic The variable value, or null if not found
     */
    public function getVariable(name:String):Dynamic {
        return variables.get(name);
    }
    
    /**
     * Check if a variable exists.
     * @param name The variable name
     * @return Bool True if the variable exists, false otherwise
     */
    public function hasVariable(name:String):Bool {
        return variables.exists(name);
    }
    
    /**
     * Clear all variables.
     */
    public function clearVariables():Void {
        variables.clear();
    }
    
    /**
     * Get all available conversation titles.
     * @return Array<String> Array of conversation titles
     */
    public function getConversationTitles():Array<String> {
        var titles = new Array<String>();
        var blocks = parser.getBlocks();
        for (block in blocks)
        {
            if (block.title != null)
                titles.push(block.title);
        }
        return titles;
    }
    
    /**
     * Get all character commands defined in the story.
     * @return Array<Command> Array of character commands
     */
    public function getCharacters():Array<Command> {
        return parser.getCharacters();
    }
    
    /**
     * Set custom code parsing and execution callbacks for advanced scripting support.
     * @param parseCallback Function to parse code strings
     * @param executeCallback Function to execute parsed code
     */
    public function setScriptingCallbacks(parseCallback:(String) -> Dynamic, executeCallback:(Dynamic) -> Dynamic):Void {
        parser.parseCodeCb = parseCallback;
        parser.executeCodeCb = executeCallback;
    }
    
    /**
     * Generate story content from a conversation block.
     * @param title The title of the conversation to generate content for
     * @return String The generated story content, or empty string if not found
     */
    public function generateStoryContent(title:String):String {
        var block = parser.getBlockByTitle(title);
        if (block == null)
            return "";
        
        return parser.generateContent(block);
    }
    
    /**
     * Clear all parsed story data.
     */
    public function clear():Void {
        parser.clear();
        currentBlock = null;
        variables.clear();
    }
}