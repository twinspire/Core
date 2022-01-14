# Twinspire
Twinspire is a 2D rendering and application framework using the innovative Haxe programming language, built on-top of the low-level library, Kha.

![Diagram](https://github.com/twinspire/Core/raw/master/img/ts_diag.png)

This is the Core library, which features the bare-bones to enable functionality for the three other sub-libraries. You could consider them modules, if you like. This library contains the ability to create `Application`'s, which handles and loads all of your resources for you. It provides for a typical event polling system and render loop which is favoured over abstracting and creating too many dependencies.

## ODIN Support
New ODIN source files have been added to this repository which is to support the ODIN programming language.

To use these files, simply copy into your project and use as is.

The same tutorials for Twinspire applies to the ODIN source files, but you may require to use pointers (which ODIN supports) accordingly.

The key difference between the Haxe version and ODIN is in the `ResourceManager`, which adds a function and more data structures:

`Resources_Create()` is a "procedure" or function that returns a `ResourceManager`. This should be called by passing in an instance of a `ResourceDirectories` struct, indicating the directory paths your resources are contained in.

## Future of Twinspire
Over time, support for Haxe will be slowly phased out in favour of ODIN. This is not to say Haxe doesn't have its merits, but circumstances have changed and this shift we hope will inspire current Haxe developers to consider this new language.

In conjunction with `raylib`, a C/C++ library with first-class bindings in ODIN, Twinspire will be taking advantage of multi-threading and memory management for more efficient performance on native platforms (unlike Haxe generated C++ code).

## Roadmap
The `ResourceManager.odin` file will eventually contain procedures allowing for multiple threads to be run, as well as file streams, for efficient file and resource management for video games and other software applications.

Other APIs built in other parts of the StoryDev repositories and my own repositories will be migrated over time for a more complete framework.

## Installation
You will require `Git` to install Twinspire on your computer. It is recommended to use it in conjunction with Haxelib for easier updating:

    haxelib git twinspire https://github.com/twinspire/Core.git

Alternatively, you can use `git clone` but you will have to setup a `haxelib dev` environment yourself.

## How to Use Twinspire
The [WIKI page](https://github.com/twinspire/Core/wiki) contains tutorials and information on how you can get started with using Twinspire.

## Features

The following features in the Core library include:

 1. Application creation
 2. Event handling
 3. Resource management
 4. Some basic, useful utilities

## Support
If you find a bug or an issue, please use the issue tracker here.