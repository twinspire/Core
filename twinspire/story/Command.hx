package twinspire.story;

using twinspire.story.CommandType;

class Command
{
    public static var GLOBAL_ID:Int;
    
    /**
     * The ID of the command. This is set internally, do not set!
     */
    public var id:Int;
    
    /**
     * The type of the command.
     */
    public var type:Int;

    /**
     * The data stored as a series of strings.
     */
    public var data:Array<String>;
    
    public function new()
    {
        data = [];
    }
    
    public static function createCharacterCommand(characterName:String, color:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = CHARACTER;
        command.data.push(characterName);
        command.data.push(color);
        return command;
    }
    
    public static function createBlockTitle(name:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = BLOCK_START;
        command.data.push(name);
        return command;
    }
    
    public static function createNarrative(description:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = NARRATIVE;
        command.data.push(description);
        return command;
    }
    
    public static function createDialogue(character:String, dialogue:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = DIALOGUE;
        command.data.push(character);
        command.data.push(dialogue);
        return command;
    }

    public static function createDialogueBlock(character:String, states:Array<String>):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = DIALOGUE_BLOCK;
        command.data.push(character);
        for (val in states)
            command.data.push(val);
        return command;
    }
    
    public static function createOverlayTitle(title:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = OVERLAY_TITLE;
        command.data.push(title);
        return command;
    }
    
    public static function createCodeLine(code:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = CODE_LINE;
        command.data.push(code);
        return command;
    }
    
    public static function createInternalDialogue(char:String, text:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = INTERNAL_DIALOGUE;
        command.data.push(char);
        command.data.push(text);
        return command;
    }
    
    public static function createNewConvo(title:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = NEW_CONVO;
        command.data.push(title);
        return command;
    }
    
    public static function createChoices(choices:Array<String>):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = CHOICES;
        for (choice in choices)
            command.data.push(choice);
        
        return command;
    }

    public static function createGoto(convoName:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = GOTO;
        command.data.push(convoName);
        return command;
    }

    public static function createOptionConditional(conditional:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = OPTION_CONDITIONAL;
        command.data.push(conditional);
        return command;
    }

    public static function createOption(text:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = OPTION;
        command.data.push(text);
        return command;
    }

    public static function createFallThrough(code:String):Command
    {
        var command = new Command();
        command.id = GLOBAL_ID++;
        command.type = FALLTHROUGH;
        command.data.push(code);
        return command;
    }
}