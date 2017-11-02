# Twinspire
Twinspire is a 2D video game engine using the innovative Haxe programming language, built on-top of the low-level framework Kha.

[!img](img/ts_diag.png)

This is the Core library, which features the bare-bones to enable functionality for the three other sub-libraries. You could consider them modules, if you like. This library contains the ability to create `Application`'s, which handles and loads all of your resources for you.

What you may find is that Twinspire does not follow some of the conventions `Kha` uses, which may confuse you. `Scheduler` is rarely used, if at all, as frame-by-frame processing of instructions seems more logical than scheduled instructions, which would otherwise cause unwanted behaviour.

It is recommended to follow the coding conventions of Twinspire to ensure your code works seamlessly between projects without much editing. As the codebase of Kha changes, so will Twinspire, but we will ensure your code doesn't need changing, with the exception of major releases.

## Installation
You will require `Git` to install Twinspire on your computer. It is recommended to use it in conjunction with Haxelib for easier updating:

    haxelib git twinspire https://github.com/twinspire/Core.git

Alternatively, you can use `git clone` but you will have to setup a `haxelib dev` environment yourself.

## Features

The following features in the Core library include:

 1. Application creation
 2. Event handling
 3. Resource management
 4. Some basic, useful utilities

## Community and Support
If you find a bug or an issue, please use the issue tracker here.

You can also find and discuss information, updates and features on our [community forums](http://community.colour-id.co.uk/).