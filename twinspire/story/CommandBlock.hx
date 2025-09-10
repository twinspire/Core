package twinspire.story;

class CommandBlock
{
    /**
     * The ID of the Command Block. Set internally, do not set!
     */
    public var id:Int;
    
    /**
     * The title.
     */
    public var title:String;
    
    /**
     * Determines if the choices within the block appears only once.
     */
    public var isExclusive:Bool;
    
    /**
     * Determines whether to clear the current conversation.
     */
    public var clearCurrent:Bool;
    
    /**
     * The name of the resource where this command block resides.
     */
    public var resourceOrigin:String;
    
    /**
     * The commands within this command block.
     */
    public var commands:Array<Command>;
    
    /**
     * The extra data found inside of parenthesis.
     */
    public var extraData:Array<String>;
    
    /**
     * Options that exist within this conversation.
     */
    public var options:Array<String>;
    
    public function new()
    {
        commands = [];
        extraData = [];
        options = [];
        clearCurrent = true;
        isExclusive = false;
        id = 0;
    }
}