package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Spritesheet :: struct {
    source : ^rl.Texture2D,
    spriteSize : rl.Vector2,
    spriteGroups : [][]int,
    individuals : bool,
}

Spritesheet_Push :: proc(using game : ^Game, spritesheet : ^Spritesheet) -> int {
    append(&spritesheets, spritesheet);
    return len(&spritesheets) - 1;
}

Spritesheet_Render :: proc(using game : ^Game, index, spriteIndex : int, x, y : f32, dw := 0.0, dh := 0.0) {
    spritesheet := spritesheets[index];

    if spritesheet.spriteGroups == nil {
        return;
    }

    assert(spritesheet.source != nil, "Spritesheet source is null.");

    position := -1;
    if !spritesheet.individuals {
        spriteGroup := spritesheet.spriteGroups[spriteIndex];
        if len(spriteGroup) == 0 {
            position = 0;
        }
        else {
            if len(spriteGroup) > 1 && nextSpritesheetDelay > 0.0 {
                if nextSpritesheetTime + rl.GetFrameTime() > nextSpritesheetDelay {
                    nextSpritesheetGroupIndex += nextSpritesheetDir;
                    if nextSpritesheetGroupIndex >= len(spriteGroup) && nextSpritesheetDir == 1 {
                        if nextSpritesheetReverse {
                            nextSpritesheetDir = -1;
                        }

                        nextSpritesheetGroupIndex = len(spriteGroup) - 1;
                    }
                    else if nextSpritesheetDir == -1 && nextSpritesheetGroupIndex < 0 {
                        if nextSpritesheetReverse {
                            nextSpritesheetDir = 1;
                        }

                        nextSpritesheetGroupIndex = 0;
                    }

                    nextSpritesheetTime = 0.0;
                }
                else {
                    nextSpritesheetTime += rl.GetFrameTime();
                }
            }
            else {
                nextSpritesheetGroupIndex = 0;
            }

            position = spriteGroup[nextSpritesheetGroupIndex];
        }
    }
    else {
        position = spriteIndex;
    }

    width := spritesheet.spriteSize.x;
    height := spritesheet.spriteSize.y;
    if dw > 0.0 {
        width = f32(dw);
    }
    if dh > 0.0 {
        height = f32(dh);
    }

    rem := position % (int(spritesheet.source.width) / int(width));
    srcX := math.floor_f32(f32(rem)) * width;
    srcY := math.floor_f32(f32(position) / (f32(spritesheet.source.width) / width)) * height;
    _x, _y := Translate_XY(game, i32(x), i32(y));
    _width, _height : = Translate_XY(game, i32(width), i32(height));

    rl.DrawTexturePro(spritesheet.source^, 
        rl.Rectangle{ srcX, srcY, width, height },
        rl.Rectangle{ f32(_x), f32(_y), f32(_width), f32(_height) },
        rl.Vector2{ 0, 0 }, 0, rl.WHITE);
}

Spritesheet_NextAnimate :: proc(using game : ^Game, delay : f32, loop : bool = false, reverse : bool = false) {
    nextSpritesheetDelay = delay;
    nextSpritesheetLoop = loop;
    nextSpritesheetReverse = reverse;
}