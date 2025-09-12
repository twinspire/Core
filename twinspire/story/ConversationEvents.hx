package twinspire.story;

/**
 * Event handlers for conversation events
 */
class ConversationEvents
{
    /**
     * Callbacks for dialogue events
     */
    public var onDialogueCallbacks:Array<String -> Character -> Void>;
    
    /**
     * Callbacks for conversation change events
     */
    public var onConversationChangeCallbacks:Array<String -> String -> Void>;
    
    /**
     * Callbacks for choice events
     */
    public var onChoiceCallbacks:Array<Int -> Dynamic -> Void>;
    
    /**
     * Callbacks for exit events
     */
    public var onExitCallbacks:Array<Void -> Void>;
    
    public function new()
    {
        onDialogueCallbacks = [];
        onConversationChangeCallbacks = [];
        onChoiceCallbacks = [];
        onExitCallbacks = [];
    }
    
    /**
     * Register a dialogue event callback
     */
    public function onDialogue(callback:String -> Character -> Void):Void
    {
        onDialogueCallbacks.push(callback);
    }
    
    /**
     * Register a conversation change event callback
     */
    public function onConversationChange(callback:String -> String -> Void):Void
    {
        onConversationChangeCallbacks.push(callback);
    }
    
    /**
     * Register a choice event callback
     */
    public function onChoice(callback:Int -> Dynamic -> Void):Void
    {
        onChoiceCallbacks.push(callback);
    }
    
    /**
     * Register an exit event callback
     */
    public function onExit(callback:Void -> Void):Void
    {
        onExitCallbacks.push(callback);
    }
    
    /**
     * Trigger dialogue event
     */
    public function triggerDialogue(dialogue:String, ?character:Character):Void
    {
        for (callback in onDialogueCallbacks) {
            callback(dialogue, character);
        }
    }
    
    /**
     * Trigger conversation change event
     */
    public function triggerConversationChange(previous:String, next:String):Void
    {
        for (callback in onConversationChangeCallbacks) {
            callback(previous, next);
        }
    }
    
    /**
     * Trigger choice event
     */
    public function triggerChoice(choice:Int, data:Dynamic):Void
    {
        for (callback in onChoiceCallbacks) {
            callback(choice, data);
        }
    }
    
    /**
     * Trigger exit event
     */
    public function triggerExit():Void
    {
        for (callback in onExitCallbacks) {
            callback();
        }
    }
}