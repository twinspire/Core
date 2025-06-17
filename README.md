# Twinspire
Twinspire is a 2D rendering and application framework written in two different languages.

The goal of Twinspire is not to be another engine, but rather to supply a set of tools that perform trivial tasks and leaving the rest of the development to the developer.

## Features

The following features in the Core library include:

 1. Application creation
 2. Multiple back buffers
 3. Custom preloaders
 4. Dimensions and a Managed stack
 5. Extensions to the `kha.graphics2.Graphics` class, supporting repeat and patched images, multiline text, sprites, and the original kha extensions. Our `Graphics2` extension class also expands existing draw methods with native `twinspire.geom.Dim` support.
 6. Manage containers and manage children, enable automatic scrolling, infinite scrolling, scroll-drag and more.
 7. Automatic event system that handles Dimension dragging, proper mouse focus system, text input and user input via `activities`.
 8. Completely separate event and graphics contexts for proper order of operation.
 9. Options for Scene Management.
 10. Basic animation support through `Animate` class.
 11. Unique `Id`s.
 12. Manage resources by groups.
 13. Filter resources with wildcards (`*`).
 14. Load and unload resources from memory, individually or in groups.
 15. An improved version of `StringBuf`.
 16. Customisable `Menu` options for gamepad support.
 17. `Units` class for measuring distance
 18. `TextBuffer` class for multiline, multi-formatted text support.

Not all features in Twinspire Core are complete, but the features in the list above are considered to be in working order.

### On-Going Features

 1. Automated Event Simulations for user inputs.
 2. Automated Physics Simulations for any game event loop.
 3. Physics and Maths implementations
 4. Custom scripting support with interoperability between both Haxe and ODIN.

## Installation

### Haxe
You will require `Git` to install Twinspire on your computer. It is recommended to use it in conjunction with Haxelib for easier updating:

    haxelib git twinspire-core https://github.com/twinspire/Core.git

Alternatively, you can use `git clone` but you will have to setup a `haxelib dev` environment yourself.

### ODIN
It is not currently recommended to use ODIN. It is expected to have better support when the Haxe version is updated.

## How to Use Twinspire
The [WIKI page](https://github.com/twinspire/Core/wiki) contains tutorials and information on how you can get started with using Twinspire.

It is not recommended to use the new context system until it is ready for production purposes. There is currently no documentation for it as of yet.

## Support
If you find a bug or an issue, please use the issue tracker here.

## LICENSE
This library is licensed under MIT.