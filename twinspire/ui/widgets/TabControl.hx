package twinspire.ui.widgets;

import twinspire.scenes.SceneObject;
import twinspire.render.GraphicsContext;
import twinspire.render.UpdateContext;
import twinspire.ui.UITemplate;
import twinspire.ui.UIBuilder;
import twinspire.IDimBuilder;

class TabControl extends SceneObject {

    // internals
    private var tabsContainerIndex:DimIndex;
    public var tabContentIndex:DimIndex;
    private var tabsExtraIndex:DimIndex;
    private var tabsDropdownListIndex:DimIndex;

    private var tabs:Array<TabPage>;
    private var tabContents:Array<(IDimBuilder) -> Void>;
    private var selectedTab:Int;

    // fields

    // name is used for the container template and
    // underlying reference in the UI template.
    public var name:String;

    public var selected(get, never):Int;
    function get_selected() return selectedTab;

    // events
    public var onTabSelected:(Int) -> Void;

    public function new() {
        super();
    }

    /**
    * Add a tab page to this control.
    **/
    public function addTabPage(page:TabPage, template:UITemplate, contentCallback:(IDimBuilder) -> Void):Int {
        var length = tabs.length;
        tabContents.push(contentCallback);

        page.onSelected.push(() -> {
            selectedTab = length;
            if (onTabSelected != null) {
                onTabSelected(selectedTab);
            }

            template.addOrUpdateDim(name, tabContents[selectedTab]);
        });

        page.onCloseClicked.push(() -> {
            selectedTab = -1;

            if (onTabSelected != null) {
                onTabSelected(selectedTab);
            }

            template.addOrUpdateDim(name, (builder) -> {
                var casted = cast(builder, UIBuilder);
                casted.begin();
                casted.end();
            });
        });

        return tabs.push(page) - 1;
    }

    public static function update(utx:UpdateContext, obj:SceneObject) {
        var casted = cast(obj, TabControl);
        
    }

    public static function render(gtx:GraphicsContext, obj:SceneObject) {
        var casted = cast(obj, TabControl);

    }

    public static function end(gtx:GraphicsContext, utx:UpdateContext, obj:SceneObject) {
        var casted = cast(obj, TabControl);

        
    }

}