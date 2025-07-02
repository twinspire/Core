package twinspire.events;

import twinspire.events.GameEventProcessAction;

typedef GameEventOptions = {
    /**
    * Forces the game event to run infinitely until manually removed from the stack.
    **/
    var ?continuous:Bool;
    /**
    * Allows event change via a user action.
    **/
    var ?userAction:Bool;
    /**
    * Requires user action to run this event to completion. `userAction` must also be `true` for this to take effect.
    **/
    var ?actionRequired:Bool;
    /**
    * The action options for the game event.
    **/
    var ?action:GameEventAction;
}

typedef GameEventAction = {
    /**
    * A callback used to satisfy the conditions of user action.
    **/
    var actionCallback:() -> Bool;
    /**
    * An action that is executed when the action callback returns `true`.
    **/
    var processAction:GameEventProcessAction;
}