package twinspire.story;

import haxe.Constraints.Function;
import twinspire.Application;
import kha.Blob;

using twinspire.story.CommandType;
using StringTools;

class Parser {
    private var _blocks:Array<CommandBlock>;
    private var _commands:Array<Command>;
    private var isAChoice:Bool;
    private var isDialogueBlock:Bool;
    private var choices:Array<String>;
    private var currentBlock:CommandBlock;
    private var addedResources:Array<String>;
    private var blocksAdded:Int = 0;

    /**
     * The function callback used to parse a string of code, normally in conjunction with `hscript`.
     */
    public var parseCodeCb:(String) -> Dynamic;

    /**
     * The function callback used to execute or evaluate code, normally in conjunction with `hscript`.
     */
    public var executeCodeCb:(Dynamic) -> Dynamic;
    
    public function new() {
        Command.GLOBAL_ID = 0;
        
        _blocks = [];
        _commands = [];
        addedResources = [];
    }

    /**
     * If for some reason you want to clear all the parsed content,
     * you can do so by calling this function.
     */
    public function clear() {
        _blocks = [];
        _commands = [];
    }
    
    /**
     * Parse a file into `CommandBlock`s using the Twinspire resource pipeline.
     * Returns an integer value that indicates the number of `CommandBlock`s generated.
     * This can be useful if you need to manage the layout of your conversations according to your application.
     * @param file The name of the story file resource to parse
     * @return Int The number of command blocks generated
     */
    public function parseFile(file:String):Int {
        var content = "";
        
        try 
        {
            var blob = Application.resources.getBlob(file);
            if (blob == null)
            {
                postError('Failed to load story file resource: $file');
                return 0;
            }
            
            content = blob.readUtf8String();
            if (content == null || content.length == 0)
            {
                postError('Story file resource is empty: $file');
                return 0;
            }
        }
        catch (e:Dynamic)
        {
            postError('Error loading story file resource: $file - $e');
            return 0;
        }

        blocksAdded = validate(content, file);
        return blocksAdded;
    }

    /**
     * Parse story content from a string directly.
     * @param content The story content as a string
     * @param sourceName Optional name for error reporting
     * @return Int The number of command blocks generated
     */
    public function parseString(content:String, sourceName:String = "string"):Int {
        blocksAdded = validate(content, sourceName);
        return blocksAdded;
    }

    public function validate(content:String, file:String):Int {
        var lines = content.split("\n");
        var lastCommand:Command = null;
        currentBlock = null;
        isAChoice = false;
        isDialogueBlock = false;
        var blocks = 0;

        // setup the local variables
        choices = [];
        var convo = false;
        var character = false;
        var overlay = false;
        var text = "";
        var narration = false;
        var dialogue = false;
        var isCode = false;
        var isGoto = false;
        var charName = "";
        var charColor = "";
        var choiceText = "";
        var choiceInstruction = "";
        var optionText = "";
        var option = false;
        var optionConditional = false;
        var codeText = "";
        var fallThrough = false;
        var fallThroughCode = "";
        var fallThroughEnd = false;

        for (i in 0...lines.length)
        {
            var line:String = lines[i];

            if (line == "" || line == "\r")
                continue;
            
            if (line.endsWith("\r"))
                line = line.substr(0, line.length - 1);

            var value = line;
            var data = getNextWord(value);
            var word = data.word;
            var arrow = false;
            var first = true;

            // Parse the line word by word
            while (value.length > 0)
            {
                if (word == "convo" && first)
                {
                    convo = true;
                }
                else if (word == "char" && first)
                {
                    character = true;
                }
                else if (word == "~" && first)
                {
                    overlay = true;
                }
                else if (word == ":" && first)
                {
                    narration = true;
                }
                else if (word == "!" && first)
                {
                    isCode = true;
                }
                else if (word == ">" && first && !fallThrough)
                {
                    isAChoice = true;
                    option = false;
                }
                else if (word == "+" && first)
                {
                    option = true;
                }
                else if (word == "<" && first)
                {
                    fallThrough = true;
                }
                else if (word == ">" && fallThrough)
                {
                    fallThroughEnd = true;
                }
                else if (word == "goto" && first)
                {
                    isGoto = true;
                }
                else if (word == "->" && isAChoice)
                {
                    arrow = true;
                }
                else if (word == "=" && first)
                {
                    optionConditional = true;
                }
                else if (word == ":")
                {
                    dialogue = true;
                }
                else
                {
                    if (character)
                    {
                        if (charColor == "")
                            charColor = word;
                        else
                            text += word + " ";
                    }
                    else if (convo || overlay || narration || isCode || isGoto || optionConditional)
                    {
                        text += word + " ";
                    }
                    else if (dialogue)
                    {
                        text += word + " ";
                    }
                    else if (isAChoice)
                    {
                        if (!arrow)
                            choiceText += word + " ";
                        else
                            choiceInstruction += word + " ";
                    }
                    else if (fallThrough)
                    {
                        fallThroughCode += word + " ";
                    }
                    else if (option)
                    {
                        optionText += word + " ";
                    }
                    else
                    {
                        charName = word;
                        dialogue = true;
                    }
                }

                value = data.line;
                data = getNextWord(value);
                word = data.word;
                first = false;
            }

            // Process parsed line data
            if (convo)
            {
                checkChoices();

                if (currentBlock != null)
                {
                    _blocks.push(currentBlock);
                    blocks++;
                    currentBlock = new CommandBlock();
                }
                
                if (currentBlock == null)
                    currentBlock = new CommandBlock();
                
                currentBlock.id = Command.GLOBAL_ID++;
                currentBlock.title = text.substr(0, text.length - 1);
                currentBlock.resourceOrigin = file;
                text = "";
                convo = false;
            }
            else if (narration)
            {
                text = text.substr(0, text.length - 1);
                lastCommand = Command.createNarrative(text);
                currentBlock.commands.push(lastCommand);
                text = "";
                narration = false;
            }
            else if (character)
            {
                text = text.substr(0, text.length - 1);
                lastCommand = Command.createCharacterCommand(text, charColor);
                _commands.push(lastCommand);
                text = "";
                character = false;
                charColor = "";
            }
            else if (dialogue)
            {
                if (text != null)
                {
                    if (text != "")
                        text = text.substr(0, text.length - 1);
                }
                
                if (charName == null || charName == "")
                {
                    postError('Invalid syntax on line $i. Expected a dialogue.');
                    return -1;
                }
                
                lastCommand = Command.createDialogue(charName, text);
                currentBlock.commands.push(lastCommand);
                text = "";
                charName = "";
                dialogue = false;
            }
            else if (overlay)
            {
                text = text.substr(0, text.length - 1);
                lastCommand = Command.createOverlayTitle(text);
                currentBlock.commands.push(lastCommand);
                text = "";
                overlay = false;
            }
            else if (isGoto)
            {
                text = text.substr(0, text.length - 1);
                lastCommand = Command.createGoto(text);
                currentBlock.commands.push(lastCommand);
                text = "";
                isGoto = false;
            }
            else if (option)
            {
                optionText = optionText.substr(0, optionText.length - 1);
                lastCommand = Command.createOption(optionText);
                currentBlock.commands.push(lastCommand);
                optionText = "";
                option = false;
            }
            else if (optionConditional)
            {
                text = text.substr(0, text.length - 1);
                lastCommand = Command.createOptionConditional(text);
                currentBlock.commands.push(lastCommand);
                text = "";
                optionConditional = false;
            }
            else if (fallThroughEnd)
            {
                if (!fallThrough)
                {
                    postError('Line $i: You must start a fall through with `<` before ending. You must enter `>` to end the fall through.');
                    return -1;
                }

                currentBlock.commands.push(Command.createFallThrough(fallThroughCode));
                fallThroughCode = "";
                fallThrough = false;
                fallThroughEnd = false;
            }
            else if (isAChoice)
            {
                if (!arrow)
                {
                    postError('Line $i: There must be an `->` arrow that indicates where to go in a choice.');
                    return -1;
                }

                if (isCode)
                    choiceInstruction = codeText;
                
                if (!isCode)
                    choiceInstruction = choiceInstruction.substr(0, choiceInstruction.length - 1);
                
                choiceText = choiceText.substr(0, choiceText.length - 1);
                choices.push(choiceText + "|" + choiceInstruction);
                choiceText = "";
                choiceInstruction = "";
                codeText = "";
            }
            else if (isCode)
            {
                currentBlock.commands.push(Command.createCodeLine(codeText));
                codeText = "";
                isCode = false;
            }
            else
            {
                postError('Invalid syntax at line $i. What were you trying to do?');
                return -1;
            }

            if (i == lines.length - 1)
            {
                if (currentBlock != null)
                {
                    checkChoices();
                    _blocks.push(currentBlock);
                    blocks++;
                }
            }
        }

        return blocks;
    }

    /**
     * Get all the characters defined in the file as commands.
     */
    public function getCharacters():Array<Command> {
        var commands = new Array<Command>();
        for (i in 0..._commands.length)
        {
            var cm = _commands[i];
            if (cm.type == CHARACTER)
            {
                commands.push(cm);
            }
        }
        return commands;
    }
    
    /**
     * Get a block of commands by the given title. The title of a block is denoted by 'convo'.
     * @param title The title to look for.
     */
    public function getBlockByTitle(title:String):CommandBlock {
        for (i in 0..._blocks.length)
        {
            if (_blocks[i].title == title)
                return _blocks[i];
        }
        return null;
    }
    
    /**
     * Get a block of commands by the given id.
     * @param id The identifier to look for.
     */
    public function getBlockById(id:Int):CommandBlock {
        for (i in 0..._blocks.length)
        {
            if (_blocks[i].id == id)
                return _blocks[i];
        }
        return null;
    }

    /**
     * Translate a given block by calculating the Optional Conditionals and Fallthroughs,
     * returning only the Commands that match any and all conditions. Make sure that 
     * `parseCodeCb` and `executeCodeCb` are assigned before calling this function if you
     * want to use conditional logic.
     * @param block The block to calculate.
     * @param options The options, if any, to use for parsing narrative/dialogue.
     * @return Array<Command>
     */
    public function translateBlock(block:CommandBlock, ?options:TranslateOptions):Array<Command> {
        var results = new Array<Command>();

        if (options == null)
        {
            options = {
                autoParse: false,
                parseMap: new Map<String, Dynamic>()
            };
        }

        var executeFrom = -1;
        var endExecution = -1;
        var choicesIndex = -1;

        for (i in 0...block.commands.length)
        {
            var command = block.commands[i];

            if (command.type == OPTION_CONDITIONAL)
            {
                if (executeFrom == -1)
                {
                    var code = command.data[0];
                    if (code != null)
                    {
                        if (code == "")
                        {
                            executeFrom = i;
                            continue;
                        }
                    }

                    if (parseCodeCb != null && executeCodeCb != null)
                    {
                        var parsed = parseCodeCb(code);
                        var executed = executeCodeCb(parsed);
                        var result = Std.is(executed, Bool);
                        if (result)
                        {
                            var casted = cast (executed, Bool);
                            if (casted)
                            {
                                executeFrom = i;
                                continue;
                            }
                        }
                    }
                    else
                    {
                        executeFrom = i;
                    }
                }
                else
                {
                    endExecution = i;
                    continue;
                }
            }
            else if (command.type == CHOICES)
            {
                choicesIndex = i;
            }
        }

        var skipToNextFallthrough = false;

        if (executeFrom == -1)
            executeFrom = 0;
        
        if (endExecution == -1)
            endExecution = block.commands.length;

        for (i in executeFrom...endExecution)
        {
            var command = block.commands[i];

            if (command.type == OPTION)
            {
                results.push(command);
            }
            else if (command.type == FALLTHROUGH && !options.fallThroughRealTime)
            {
                var code = command.data[0];
                if (code != null)
                {
                    if (code == "")
                    {
                        skipToNextFallthrough = false;
                        continue;
                    }
                }

                if (parseCodeCb != null && executeCodeCb != null)
                {
                    var parsed = parseCodeCb(code);
                    var executed = executeCodeCb(parsed);
                    if (Std.is(executed, Bool))
                    {
                        var casted = cast (executed, Bool);
                        skipToNextFallthrough = !casted;
                    }
                }
                else
                {
                    skipToNextFallthrough = false;
                }
            }
            else
            {
                if (!skipToNextFallthrough)
                {
                    var text = "";
                    if (command.type == NARRATIVE || command.type == OVERLAY_TITLE)
                    {
                        text = command.data[0];
                    }
                    else if (command.type == DIALOGUE)
                    {
                        text = command.data[1];
                    }

                    if (options.autoParse)
                    {
                        if (text.indexOf("$") > -1)
                        {
                            text = parseText(text, options.parseMap);
                        }
                    }

                    if (text != "")
                    {
                        if (command.type == NARRATIVE || command.type == OVERLAY_TITLE)
                        {
                            command.data[0] = text;
                        }
                        else if (command.type == DIALOGUE)
                        {
                            command.data[1] = text;
                        }
                    }

                    results.push(command);
                }
            }
        }

        if (choicesIndex > -1)
        {
            results.push(block.commands[choicesIndex]);
        }

        return results;
    }

    private function parseText(text:String, variables:Map<String, Dynamic>):String {
        var result = "";
        var isSpace = false;
        var isVariable = false;
        var variableName = "";
        var captured = false;
        
        for (i in 0...text.length)
        {
            var char = text.charAt(i);
            if (captured)
            {
                if (char == "}")
                {
                    captured = false;
                    if (variables.exists(variableName))
                    {
                        result += Std.string(variables.get(variableName));
                    }
                    variableName = "";
                    isVariable = false;
                }
                else
                {
                    variableName += char;
                }
            }
            else if (char == " ")
            {
                if (isVariable)
                {
                    if (variables.exists(variableName))
                    {
                        result += Std.string(variables.get(variableName));
                    }
                    variableName = "";
                    isVariable = false;
                }

                isSpace = true;
                result += char;
            }
            else if (char == "{" && isVariable)
            {
                captured = true;
            }
            else
            {
                if (char == "$" && isSpace)
                {
                    isVariable = true;
                }
                else
                {
                    if (isVariable)
                        variableName += char;
                    else
                        result += char;
                }

                isSpace = false;
            }
        }

        return result;
    }

    /**
     * Generate content from a CommandBlock back to the original story format.
     * @param block The CommandBlock to generate content from
     * @return String The generated story content
     */
    public function generateContent(block:CommandBlock):String {
        var content = "";
        if (block.title == null) return "";

        content = "convo " + block.title + "\n";
        if (block.isExclusive)
            content += "= EXCLUSIVE\n";

        for (i in 0...block.commands.length)
        {
            var command = block.commands[i];
            switch (command.type)
            {
                case CommandType.NARRATIVE:
                {
                    content += ": " + command.data[0] + "\n";
                }
                case CommandType.DIALOGUE:
                {
                    content += command.data[0] + " : " + command.data[1] + "\n";
                }
                case CommandType.OVERLAY_TITLE:
                {
                    content += "~ " + command.data[0] + "\n";
                }
                case CommandType.CODE_LINE:
                {
                    content += "! " + command.data[0] + "\n";
                }
                case CommandType.CHOICES:
                {
                    for (data in command.data)
                    {
                        var index = data.indexOf("|");
                        var choiceText = data.substr(0, index);
                        var choiceInstruction = data.substr(index + 1);
                        content += "> " + choiceText + " -> " + choiceInstruction + "\n";
                    }
                }
                case CommandType.INTERNAL_DIALOGUE:
                {
                    content += command.data[0] + " (internal) : " + command.data[1] + "\n";
                }
                case CommandType.GOTO:
                {
                    content += "goto " + command.data[0] + "\n";
                }
                case CommandType.OPTION:
                {
                    content += "+ " + command.data[0] + "\n";
                }
                case CommandType.OPTION_CONDITIONAL:
                {
                    content += "= " + command.data[0] + "\n";
                }
                case CommandType.FALLTHROUGH:
                {
                    content += "< " + command.data[0] + " >\n";
                }
            }
        }

        return content;
    }

    /**
     * Return all the parsed blocks/conversations.
     */
    public function getBlocks():Array<CommandBlock> {
        return _blocks;
    }

    function getNextWord(value:String):{ word:String, line:String } {
        var result = "";
        var index = 0;
        for (i in 0...value.length)
        {
            var char = value.charAt(i);
            index++;
            if (char == " ")
                break;
            else
                result += char;
        }

        value = value.substr(index);
        return { word: result, line: value };
    }
    
    function checkChoices():Bool {
        var result = false;
        if (isAChoice && currentBlock != null)
        {
            currentBlock.commands.push(Command.createChoices(choices));
            isAChoice = false;
            choices = [];

            result = true;
        }

        return result;
    }

    function postError(error:String):Void {
        trace(error);
    }
}