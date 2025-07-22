package twinspire.events.args;

class DropFilesEventArgs extends EventArgs {

    public var files:Array<String>;
    
    public function new() {
        super();

        files = [];
    }

}