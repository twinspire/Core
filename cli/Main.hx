package;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;

import haxe.io.Path;
import haxe.Template;

using StringTools;

enum abstract Command(Int) {
    var None;
    var Create;
    var Help;
    var AddComponent;
}

enum abstract ProjectType(String) to String {
    var Basic;
    var Module;
}

typedef Component = {
    var name:String;
    var path:String;
}

typedef Project = {
    var ?type:ProjectType;
    var ?template:String;
    var ?componentPath:String;
    var ?setupPath:String;
    var ?startPack:String;
    var ?components:Array<Component>;
}

class Main {
    
    static var command:Command;

    static var dir:String;
    static var projectName:String;
    static var isVerbose:Bool;

    static var sharedPath:String;

    static var flags:Array<String>;
    static var options:Map<String, String>;
    static var commands:Array<String>;

    public static function main() {
        var twinspireDir = Sys.programPath();
        twinspireDir = twinspireDir.substr(0, twinspireDir.length - "run.n".length);

        sharedPath = Path.join([ twinspireDir, "shared" ]);
        if (!FileSystem.exists(sharedPath)) {
            FileSystem.createDirectory(sharedPath);
        }

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
                    case "add": {
                        command = AddComponent;
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
                        case AddComponent: {
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
            case AddComponent: {
                final projectFile = "tsproj.json";
                final projectFilePath = Path.join([ dir, projectFile ]);
                if (!FileSystem.exists(projectFilePath)) {
                    Sys.println("There is no project file. 'tsproj.json' file is missing.");
                    return;
                }

                var projectContent:String = "";
                var project:Project = {};
                try {
                    projectContent = File.getContent(projectFilePath);
                    project = Json.parse(projectContent);
                }
                catch (ex) {
                    Sys.println('There was an error attempting to open and read the project file:');
                    Sys.println('  ${ex.message}');
                    return;
                }

                if (!(commands.length >= 1 && commands.length < 3)) {
                    Sys.println('Too many or not enough parameters for "add" command.');
                }

                var name = commands[0];
                var startPack = project.startPack;
                if (project.startPack != "") {
                    startPack += ".";
                }
                var pack = startPack + project.componentPath.replace("/", ".").replace("\\", ".");
                if (commands.length == 2) {
                    pack = startPack + commands[1].toLowerCase();
                }

                if (project.components.filter((c) -> c.name == name).length > 0) {
                    Sys.println('Component name ${name} already exists.');
                    return;
                }

                var component:Component = {
                    name: name,
                    path: pack
                };

                project.components.push(component);

                var entries = [];
                var assocs = [];
                for (i in 0...project.components.length) {
                    var comp = project.components[i];

                    var componentsPath = Path.join([ dir, project.setupPath, Path.normalize(project.componentPath) ]);
                    if (!FileSystem.exists(componentsPath)) {
                        Sys.println('The component path $componentsPath does not exist.');
                        return;
                    }

                    entries.push(generateIdCode(comp.name));
                    assocs.push(generateIdAssocCode(comp.name));

                    var clsFilePath = Path.join([ componentsPath, comp.name + ".hx" ]);
                    if (FileSystem.exists(clsFilePath)) {
                        continue;
                    }

                    // save new class file if it doesn't exist yet
                    var clsFileContent = generateClass(comp.name, pack);
                    File.saveContent(clsFilePath, clsFileContent);
                }

                // update id entries file
                var idFilePath = Path.join([ dir, project.setupPath, "IdEntries.hx" ]);
                var idFileContent = generateIdEntriesClass(project.startPack, entries, assocs);
                File.saveContent(idFilePath, idFileContent);

                // update project file
                projectContent = Json.stringify(project);
                File.saveContent(projectFilePath, projectContent);
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
                Sys.println('  add    - Add a component to the current project.');
                Sys.println('           This command expects the following arguments:');
                Sys.println('               name - A Haxe class name representing the class and ID types to generate.');
                Sys.println('               pack - (Optional) The package (if different from component path).');
                Sys.println('');
                Sys.println('  help   - Displays this help.');
                Sys.println('           To see more detailed help, check out the following commands:');
                Sys.println('               flags, options, start-templates');
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

    static function generateIdCode(name:String) {
        return '
public static var ${name.toLowerCase()}:Id;
        '.trim();
    }

    static function generateIdAssocCode(name:String) {
        return '
        ${name.toLowerCase()} = Application.createId(true);
        IdAssoc.assoc[${name.toLowerCase()}].init = ${name}.init;
        IdAssoc.assoc[${name.toLowerCase()}].update = ${name}.update;
        IdAssoc.assoc[${name.toLowerCase()}].render = ${name}.render;
        IdAssoc.assoc[${name.toLowerCase()}].end = ${name}.end;
        '.trim();
    }

    static function generateIdEntriesClass(startPack:String, entries:Array<String>, assocs:Array<String>) {
        return '
package $startPack;

import twinspire.Application;
import twinspire.IdAssoc;
import twinspire.Id;

class IdEntries {

    ${entries.join("\r\n\t")}

    public static function init() {
        ${assocs.join("\r\n\t\t")}
    }

}
        '.trim();
    }

    static function generateClass(name:String, pack:String) {
        return '
package ${pack};

import twinspire.render.GraphicsContext;
import twinspire.render.UpdateContext;
import twinspire.scenes.SceneObject;

class ${name} extends SceneObject {

    public function new() {
        super();
    }

    public static function init(gtx:GraphicsContext, obj:SceneObject):SceneObject {

    }

    public static function update(utx:UpdateContext, obj:SceneObject) {

    }

    public static function render(gtx:UpdateContext, obj:SceneObject) {

    }

    public static function end(gtx:GraphicsContex, utx:UpdateContext, obj:SceneObject) {

    }

}
        '.trim();
    }

}