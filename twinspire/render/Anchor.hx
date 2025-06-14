package twinspire.render;

enum abstract Anchor(Int) {
    /**
    * No anchoring.
    **/
    var AnchorNone;
    /**
    * Anchors an object to the top of a destination dimension.
    **/
    var AnchorTop;
    /**
    * Anchors an object to the left of a destination dimension.
    **/
    var AnchorLeft;
    /**
    * Anchors an object to the right of a destination dimension.
    **/
    var AnchorRight;
    /**
    * Anchors an object to the bottom of a destination dimension.
    **/
    var AnchorBottom;
}