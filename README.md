# Twinspire
Twinspire is a 2D rendering and application framework using the innovative Haxe programming language, built on-top of the low-level library, Kha.

![Diagram](https://github.com/twinspire/Core/raw/master/img/ts_diag.png)

This is the Core library, which features the bare-bones to enable functionality for the three other sub-libraries. You could consider them modules, if you like. This library contains the ability to create `Application`'s, which handles and loads all of your resources for you. It provides for a typical event polling system and render loop which is favoured over abstracting and creating too many dependencies.

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