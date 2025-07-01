package twinspire.events;

enum abstract TimelineProcessType(Int) {
    /**
    * Specifies that the timeline runs each node one after the other, taking into account duration of each node.
    * This is the default.
    **/
    var InSequence;
    /**
    * Specifies that the timeline attempts to execute all nodes at once, ignoring duration.
    **/
    var Altogether;
}