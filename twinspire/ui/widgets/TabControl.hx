package twinspire.ui.widgets;

import twinspire.scenes.SceneObject;
import twinspire.render.GraphicsContext;
import twinspire.render.UpdateContext;
import twinspire.render.vector.VectorSpace;
import twinspire.ui.UITemplate;
import twinspire.ui.UIBuilder;
import twinspire.IDimBuilder;

class TabControl extends SceneObject {

    // Container indices for different parts of the tab control
    public var tabsContainerIndex:DimIndex;        // Container for tab buttons
    public var tabContentIndex:DimIndex;           // Container for selected tab content  
    private var tabsExtraIndex:DimIndex;           // Container for extra controls
    private var tabsDropdownListIndex:DimIndex;    // Container for overflow dropdown

    // Internal state
    private var tabs:Array<TabPage>;
    private var tabContents:Array<(IDimBuilder) -> Void>;
    private var selectedTab:Int;
    private var tabPageHeight:Float;
    private var extraControls:Bool;
    private var extraControlWidth:Float;

    // Public properties
    public var name:String;
    public var selected(get, never):Int;
    function get_selected() return selectedTab;

    // VectorSpace for tab content container
    public var contentVectorSpace:VectorSpace;

    // Events
    public var onTabSelected:(Int) -> Void;

    public function new() {
        super();
        tabs = [];
        tabContents = [];
        selectedTab = -1;
    }

    /**
     * Add a tab page to this control.
     */
    public function addTabPage(page:TabPage, template:UITemplate, contentCallback:(IDimBuilder) -> Void):Int {
        var length = tabs.length;
        tabContents.push(contentCallback);

        // Set up tab selection event
        page.onSelected.push(() -> {
            selectedTab = length;
            
            // Call event handler if set
            if (onTabSelected != null) {
                onTabSelected(selectedTab);
            }

            // Update the content container with the selected tab's content
            template.addOrUpdateDim(name, tabContents[selectedTab]);
        });

        // Set up tab close event
        page.onCloseClicked.push(() -> {
            selectedTab = -1;

            if (onTabSelected != null) {
                onTabSelected(selectedTab);
            }

            // Clear content when tab is closed
            template.addOrUpdateDim(name, (builder) -> {
                var casted = cast(builder, UIBuilder);
                casted.begin();
                casted.end();
            });
        });

        return tabs.push(page) - 1;
    }

    /**
     * Select a specific tab by index
     */
    public function selectTab(index:Int):Void {
        if (index >= 0 && index < tabs.length) {
            tabs[index].selected = true;
            // Deselect other tabs
            for (i in 0...tabs.length) {
                if (i != index) {
                    tabs[i].selected = false;
                }
            }
        }
    }

    public static function update(utx:UpdateContext, obj:SceneObject) {
        var casted = cast(obj, TabControl);
        // Update logic will be handled by individual TabPages
    }

    public static function render(gtx:GraphicsContext, obj:SceneObject) {
        var casted = cast(obj, TabControl);
        // Rendering is handled by the container system and individual components
    }

    public static function end(gtx:GraphicsContext, utx:UpdateContext, obj:SceneObject) {
        var casted = cast(obj, TabControl);
        // Cleanup if needed
    }

}