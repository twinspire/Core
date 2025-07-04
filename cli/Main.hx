package;

import sys.io.File;
import sys.FileSystem;

import haxe.io.Path;
import haxe.Template;

using StringTools;

enum abstract Command(Int) {
    var None;
    var Create;
    var Help;
}

class Main {
    
    static var command:Command;

    static var dir:String;
    static var projectName:String;
    static var isVerbose:Bool;

    static var flags:Array<String>;
    static var options:Map<String, String>;
    static var commands:Array<String>;

    public static function main() {
        var twinspireDir = Sys.programPath();
        twinspireDir = twinspireDir.substr(0, twinspireDir.length - "run.n".length);

        command = None;

        flags = [];
        options = [];
        commands = [];

        var args = Sys.args();
        dir = args[args.length - 1];
        if (args.length == 1) {
            printHelp();
            return;
        }

        for (i in 0...args.length-1) {
            var arg = args[i];

            if (i == 0) {
                switch (arg) {
                    case "create": {
                        command = Create;
                    }
                    case "help": {
                        command = Help;
                    }
                }
            }
            else {
                if (arg.startsWith("--")) {
                    flags.push(arg.substr(2));
                }
                else if (arg.startsWith("-")) {
                    var equalsIndex = arg.indexOf("=");
                    if (equalsIndex == -1) {
                        options[arg.substr(1)] = "";
                    }
                    else {
                        var key = arg.substr(1, equalsIndex - 1);
                        var value = arg.substr(equalsIndex + 1);
                        options[key] = value;
                    }
                }
                else {
                    switch (command) {
                        case Create: {
                            commands.push(arg);
                        }
                        case Help: {
                            commands.push(arg);
                        }
                        default: {
                            Sys.println('Invalid command: ${args[0]}');
                            Sys.println('');
                            printHelp();
                        }
                    }
                }
            }
        }

        isVerbose = flags.contains("v") || flags.contains("verbose");

        switch (command) {
            case Help: {
                if (commands.length == 1) {
                    printHelp(commands[0]);
                }
                else {
                    Sys.println('Invalid number of parameters.');
                    printHelp();
                }
            }
            case Create: {
                if (!(commands.length >= 1 && commands.length < 3)) {
                    Sys.println('Invalid number of parameters.');
                    printHelp();
                }

                if (!options.exists("code-style") || (options["code-style"] != "oop" && options["code-style"] != "proc")) {
                    options["code-style"] = "oop";
                }

                projectName = commands[0];
                var template = "quick-start";
                if (commands.length == 2) {
                    template = commands[1];
                }

                var templatesDir = Path.join([ twinspireDir, "start" ]);
                var templatePath = Path.join([ templatesDir, template ]);
                if (!FileSystem.exists(templatePath)) {
                    Sys.println('Template "${template}" does not exist.');
                    return;
                }

                var data:Dynamic = {};
                if (options["code-style"] == "oop") {
                    data = getOopData();
                }
                else if (options["code-style"] == "proc") {
                    data = getProcData();
                }

                if (flags.contains("reset")) {
                    var files = FileSystem.readDirectory(dir);
                    for (f in files) {
                        var fullPath = Path.join([ dir, f ]);
                        if (FileSystem.isDirectory(fullPath)) {
                            deleteDirectory(fullPath);
                        }
                        else {
                            FileSystem.deleteFile(fullPath);
                        }
                    }
                }
                
                copyDirectory(templatePath, dir, data);
            }
            default: {

            }
        }
    }

    static function getOopData():Dynamic {
        return {
            setupScenesInit: 'app.sceneManager = new SceneManager();',
            setupScenesInstance: 'package;

import twinspire.render.GraphicsContext;
import twinspire.render.UpdateContext;
import twinspire.ISceneManager;

class SceneManager implements ISceneManager {
    
    public function new() {

    }

    public function resize() {

    }
    
    public function init(gtx:GraphicsContext) {

    }

    public function update(utx:UpdateContext) {

    }
    
    public function render(gtx:GraphicsContext) {

    }
    
    public function end(gtx:GraphicsContext, utx:UpdateContext) {

    }
}'
        };
    }

    static function getProcData():Dynamic {
        return {
            setupScenesInit: 'app.init = SceneManager.init;
                app.resize = SceneManager.resize;
                app.update = SceneManager.update;
                app.render = SceneManager.render;
                app.end = SceneManager.end;',
            setupScenesInstance: 'package;

import twinspire.render.GraphicsContext;
import twinspire.render.UpdateContext;

class SceneManager {

    public static function resize() {

    }
    
    public static function init(gtx:GraphicsContext) {

    }

    public static function update(utx:UpdateContext) {

    }
    
    public static function render(gtx:GraphicsContext) {

    }
    
    public static function end(gtx:GraphicsContext, utx:UpdateContext) {

    }
}'          
        };
    }

    static function printHelp(subCommand:String = "") {
        switch (subCommand) {
            case "flags": {
                Sys.println('The following flags are available:');
                Sys.println('  --overwrite     - Overwrite all existing files and copy new files.');
                Sys.println('                    When using "create" command.');
                Sys.println('  --reset         - Reset the directory, deleting all contents and starting over.');
                Sys.println('                    When using "create" command.');
                Sys.println('  --v, --verbose  - Detailed information.');
            }
            case "options": {
                Sys.println('The following options are available:');
                Sys.println('  -code-style=oop  - Creates a SceneManager implementing ISceneManager instance');
                Sys.println('                     for generating the setup of the project (default).');
                Sys.println('  -code-style=proc - Generates static functions as callbacks for the');
                Sys.println('                     Application instance.');
            }
            case "start-templates": {
                Sys.println('The following start templates are available:');
                Sys.println('  quick-start - This gives a very basic Twinspire Core application');
                Sys.println('                to start working with.');
            }
            default: {
                Sys.println('To use Twinspire Core CLI, use the following syntax:');
                Sys.println('');
                Sys.println('  haxelib run twinspire-core #command [?flags] [?options]');
                Sys.println('');
                Sys.println('The following commands are available:');
                Sys.println('  create - Create a new project in the current working directory.');
                Sys.println('           This command expects the following arguments:');
                Sys.println('               projectName - Give the name for the project.');
                Sys.println('               start - (Optional) Specify the start template. "quick-start" is default.');
                Sys.println('');
                Sys.println('  help - Displays this help.');
                Sys.println('         To see more detailed help, check out the following commands:');
                Sys.println('             flags, options, start-templates');
            }
        }
    }

    static function deleteDirectory(dir:String) {
        var files = FileSystem.readDirectory(dir);
        for (f in files) {
            var fullPath = Path.join([ dir, f ]);
            if (FileSystem.isDirectory(fullPath)) {
                deleteDirectory(fullPath);
            }
            else {
                try {
                    FileSystem.deleteFile(fullPath);
                }
                catch(ex) {
                    Sys.println('Could not delete file $fullPath. Error: ${ex.message}.');
                }
            }
        }

        try {
            FileSystem.deleteDirectory(dir);
        }
        catch(ex) {
            Sys.println('Could not delete directory $dir. Error: ${ex.message}.');
        }
    }

    static function copyDirectory(dir:String, to:String, ?other:Dynamic) {
        var files = FileSystem.readDirectory(dir);
        for (f in files) {
            var fullPath = Path.join([ dir, f ]);
            if (FileSystem.isDirectory(fullPath)) {
                var destDir = Path.join([ to, f ]);
                FileSystem.createDirectory(destDir);
                copyDirectory(fullPath, destDir, other);
            }
            else {
                var dest = Path.join([ to, f ]);
                copyFile(fullPath, dest, other);
            }
        }
    }

    static function copyFile(src:String, dest:String, ?other:Dynamic) {
        if (!flags.contains("overwrite") && FileSystem.exists(dest)) {
            return;
        }

        if (isVerbose) {
            Sys.println('Copying $src ...');
            Sys.println('  to $dest ...');
            Sys.println('');
        }

        if (src.endsWith(".hx") || src.endsWith(".js")) {
            var content = File.getContent(src);
            var temp = new Template(content);
            var setupScenesInit = "";
            if (other.setupScenesInit != null) {
                setupScenesInit = other.setupScenesInit;
            }

            var setupScenesInstance = "";
            if (other.setupScenesInstance != null) {
                setupScenesInstance = other.setupScenesInstance;
            }

            var result = temp.execute({
                projectName: projectName,
                setupScenesInit: setupScenesInit,
                setupScenesInstance: setupScenesInstance
            }); 
            try {
                File.saveContent(dest, result);
            }
            catch (ex) {
                Sys.println('Error copying file: ${ex.message}');
            }
        }
        else {
            try {
                File.copy(src, dest);
            }
            catch (ex) {
                Sys.println('Error copying file: ${ex.message}');
            }
        }
    }

}