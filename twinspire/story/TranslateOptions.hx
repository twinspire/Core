package twinspire.story;

typedef TranslateOptions =
{
    /**
     * Indicate if dialogue should automatically parse anything prefixed with the dollar ($) sign.
     */
    @:optional var autoParse:Bool;
    
    /**
     * If `autoParse` is `true`, this map indicates the values of the variables found in dialogue.
     */
    @:optional var parseMap:Map<String, Dynamic>;
    
    /**
     * If `true`, you specify that `FALLTHROUGH` Commands will be executed on-the-fly, rather than
     * at initiation. You must therefore capture the type `FALLTHROUGH` and execute any condition
     * assigned to it accordingly.
     */
    @:optional var fallThroughRealTime:Bool;
}