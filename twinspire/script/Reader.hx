package twinspire.script;

#if (hxnodejs || sys)
import sys.FileSystem;
import sys.io.File;
#end

class Reader {
    
    /**
    * Test and parse a `tss` file.
    * Used for debugging.
    **/
    public static function test(src:String) {
        var content = "";
        #if (hxnodejs || sys)
        if (FileSystem.exists(src)) {
            content = File.getContent(src);
            parse(content);
        }
        #else
        Application.resources.loadBlobs([ src ]);
        Application.resources.submitLoadRequest(() -> {
            content = Application.resources.getBlob(src).readUtf8String();
            parse(content);
        });
        #end
    }

    private static function parse(content:String) {
        var tokenizer = new Tokenizer(content);
        if (tokenizer.errors.length > 0) {
            // TODO: log
            return;
        }

        var parser = new Parser(tokenizer);
        parser.parseTokens();
        for (d in parser.dims) {
            for (k => v in d.data) {
                trace('$k: $v');
            }
        }
    }

}