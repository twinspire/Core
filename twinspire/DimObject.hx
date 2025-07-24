package twinspire;

import twinspire.Dimensions.DimCommand;
import twinspire.Dimensions.DimInitCommand;
import twinspire.scenes.SceneObject;

class DimObject extends SceneObject {

    private var _text:String;
    private var isMouseDown:Bool;
    private var isMouseOver:Bool;

    
    public var dimObjectResult:DimObjectResult;
    public var initCommand:DimInitCommand;

    public function new() {
        super();
    }

    /**
    * Finds the first matching `MeasureText` command if one exists and returns
    * the text value associated with it.
    **/
    public function getText() {
        if (_text != "" && _text != null) {
            return _text;
        }

        var text = findTextFromInit(initCommand);
        _text = text; // cache result
        return text;
    }

    private function findTextFromInit(init:DimInitCommand) {
        var text = "";

        switch (init) {
            case CreateWrapper(_, then): {
                text = findText(then);
            }
            case CreateEmpty(then): {
                text = findText(then);
            }
            case CreateOnInit(_, cmd): {
                text = findTextFromInit(cmd);
            }
            case CentreScreenY(_, _, _, inside): {
                for (i in inside) {
                    var item = findTextFromInit(i);
                    if (item != null) {
                        text = item;
                        break;
                    }
                }
            }
            case CentreScreenX(_, _, _, inside): {
                for (i in inside) {
                    var item = findTextFromInit(i);
                    if (item != null) {
                        text = item;
                        break;
                    }
                }
            }
            case CentreScreenFromSize(_, _, inside): {
                for (i in inside) {
                    var item = findTextFromInit(i);
                    if (item != null) {
                        text = item;
                        break;
                    }
                }
            }
            case CreateDimAlignScreen(_, _, _, _, inside): {
                for (i in inside) {
                    var item = findTextFromInit(i);
                    if (item != null) {
                        text = item;
                        break;
                    }
                }
            }
            case CreateFromOffset(_, inside): {
                for (i in inside) {
                    var item = findTextFromInit(i);
                    if (item != null) {
                        text = item;
                        break;
                    }
                }
            }
            case CreateGridEquals(_, _, items): {
                for (i in items) {
                    var item = findTextFromInit(i);
                    if (item != null) {
                        text = item;
                        break;
                    }
                }
            }
            case CreateGridFloats(_, _, items): {
                for (i in items) {
                    var item = findTextFromInit(i);
                    if (item != null) {
                        text = item;
                        break;
                    }
                }
            }
            case CreateGrid(_, _, items): {
                for (i in items) {
                    var item = findTextFromInit(i);
                    if (item != null) {
                        text = item;
                        break;
                    }
                }
            }
            case CreateFixedFlow(_, _, items): {
                for (i in items) {
                    var item = findTextFromInit(i);
                    if (item != null) {
                        text = item;
                        break;
                    }
                }
            }
            case CreateVariableFlow(_, items): {
                for (i in items) {
                    var item = findTextFromInit(i);
                    if (item != null) {
                        text = item;
                        break;
                    }
                }
            }
            case CreateFlowComplex(_, items): {
                for (i in items) {
                    var item = findTextFromInit(i);
                    if (item != null) {
                        text = item;
                        break;
                    }
                }
            }
            case Reference(id): {
                if (Dimensions.mappedObjects.exists(id)) {
                    var item = findTextFromInit(Dimensions.mappedObjects[id]);
                    if (item != null) {
                        text = item;
                    }
                }
            }
        }

        return text;
    }

    private function findText(commands:Array<DimCommand>) {
        for (c in commands) {
            switch (c) {
                case MeasureText(text, _, _): {
                    return text;
                }
                default: {

                }
            }
        }

        return null;
    }

}