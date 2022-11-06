package main

import rl "vendor:raylib"
import "core:strings"

HorizontalAlign :: enum {
    None,
    Left,
    Middle,
    Right,
}

VerticalAlign :: enum {
    None,
    Top,
    Centre,
    Bottom,
}

Dim :: struct {
    x, y, width, height : f32,
    order : int,
}

DimSizing :: enum {
    Pixels,
    Percent,
}

DimCellSize :: struct {
    sizing : DimSizing,
    value : f32,
}

CentreScreenScreenFromSize :: proc(width, height : f32) -> Dim {
    x := (f32(rl.GetRenderWidth()) - width) / 2
    y := (f32(rl.GetRenderHeight()) - height) / 2
    return Dim{ x, y, width, height, 0 }
}

CentreScreenY :: proc(width, height, offsetY : f32) -> Dim {
    x := (f32(rl.GetRenderWidth()) - width) / 2
    return Dim{ x, offsetY, width, height, 0 }
}

CentreScreenX :: proc(width, height, offsetX : f32) -> Dim {
    y := (f32(rl.GetRenderHeight()) - height) / 2
    return Dim{ offsetX, y, width, height, 0 }
}

ScreenAlignX :: proc(a : ^Dim, halign : HorizontalAlign, offset : rl.Vector2) {
    if halign == .Left {
        a.x = offset.x
        a.y = offset.y
    }
    else if halign == .Middle {
        a^ = CentreScreenY(a.width, a.height, offset.y)
        a.x = offset.x
    }
    else if halign == .Right {
        a.x = f32(rl.GetRenderWidth()) - a.width - offset.x
        a.y = offset.y
    }
}

ScreenAlignY :: proc(a : ^Dim, valign : VerticalAlign, offset : rl.Vector2) {
    if valign == .Top {
        a.x = offset.x
        a.y = offset.y
    }
    else if valign == .Centre {
        a^ = CentreScreenX(a.width, a.height, offset.x)
    }
    else if valign == .Bottom {
        a.y = f32(rl.GetRenderHeight()) - a.height - offset.y
        a.x = f32(rl.GetRenderWidth()) - a.width - offset.x
    }
}

DimGridEquals :: proc(container : Dim, columns, rows : int) -> [dynamic]Dim {
    cellWidth := cast(f32)(int(container.width) / columns)
    cellHeight := cast(f32)(int(container.height) / rows)
    results : [dynamic]Dim
    for c in 0..<columns {
        for r in 0..<rows {
            append(&results, Dim{ f32(c) * cellWidth + container.x, f32(r) * cellHeight + container.y, cellWidth, cellHeight, 0 })
        }
    }
    return results
}

DimGridFloats :: proc(container : Dim, columns, rows : []f32) -> [dynamic]Dim {
    results : [dynamic]Dim
    startY : f32 = 0.0
    for r in 0..<len(rows) {
        cellHeight := container.height * rows[r]
        startX : f32 = 0.0
        for c in 0..<len(columns) {
            cellWidth := container.width * columns[c]
            append(&results, Dim{ startX + container.x, startY + container.y, cellWidth, cellHeight, 0 })
            startX += cellWidth
        }

        startY += cellHeight
    }
    return results
}

DimGrid :: proc(container : Dim, columns, rows : []DimCellSize) -> [dynamic]Dim {
    totalPreciseWidth : f32 = 0.0
    totalPreciseHeight : f32 = 0.0
    for c in columns {
        if c.sizing == .Pixels {
            totalPreciseWidth += c.value
        }
    }

    for r in rows {
        if r.sizing == .Pixels {
            totalPreciseHeight += r.value
        }
    }

    remainingWidth := container.width - totalPreciseWidth
    remainingHeight := container.height - totalPreciseHeight
    contentWidth := totalPreciseWidth
    contentHeight := totalPreciseHeight

    for c in columns {
        if c.sizing == .Percent {
            contentWidth += c.value * remainingWidth
        }
    }

    for r in rows {
        if r.sizing == .Percent {
            contentHeight += r.value * remainingHeight
        }
    }

    contentX := ((container.width - contentWidth) / 2) + container.x
    contentY := ((container.height - contentHeight) / 2) + container.y

    results : [dynamic]Dim

    startY := contentY
    for r in rows {
        y : f32 = 0.0
        height : f32 = 0.0

        if r.sizing == .Percent {
            height = r.value * remainingHeight
            y = startY
            startY += height
        }
        else if r.sizing == .Pixels {
            y = startY
            height = r.value
            startY += height
        }

        startX := contentX
        for c in columns {
            x : f32 = 0.0
            width : f32 = 0.0

            if c.sizing == .Percent {
                width = c.value * remainingWidth
                x = startX
                startX += width
            }
            else if c.sizing == .Pixels {
                x = startX
                width = c.value
                startX += width
            }

            append(&results, Dim{ x, y, width, height, 0 })
        }
    }

    return results
}

DimMultiCellSize :: proc(cellSize : DimCellSize, count : int) -> [dynamic]DimCellSize {
    results : [dynamic]DimCellSize
    for _ in 0..<count {
        append(&results, cellSize)
    }
    return results
}

ColumnDirection :: enum {
    Up,
    Down,
}

DimColumn :: struct {
    container : Dim,
    direction : ColumnDirection,
    height : f32,
    cell : int,
}

GetNewDimColumn :: proc(column : ^DimColumn) -> Dim {
    x := column.container.x
    y := column.container.y
    width := column.container.width
    height := column.container.height
    if column.direction == .Up {
        y -= column.height * f32(column.cell)
        height = column.height
    }
    else if column.direction == .Down {
        y += column.height * f32(column.cell)
        height = column.height
    }

    column.cell += 1
    return Dim{ x, y, width, height, 0 }
}

RowDirection :: enum {
    Left,
    Right,
}

DimRow :: struct {
    container : Dim,
    direction : RowDirection,
    width : f32,
    cell : int,
}

GetNewDimRow :: proc(row : ^DimRow) -> Dim {
    x := row.container.x
    y := row.container.y
    width := row.container.width
    height := row.container.height
    if row.direction == .Left {
        x -= row.width * f32(row.cell)
        width = row.width
    }
    else if row.direction == .Right {
        x += row.width * f32(row.cell)
        width = row.width
    }

    row.cell += 1
    return Dim{ x, y, width, height, 0 }
}

DimOffsetX :: proc(a : Dim, offsetX : f32) -> Dim {
    if offsetX >= 0 {
        return Dim{ a.x + a.width + offsetX, a.y, a.width, a.height, a.order }
    }
    else if offsetX < 0 {
        return Dim{ a.x - a.width - offsetX, a.y, a.width, a.height, a.order }
    }

    return Dim{ 0, 0, 0, 0, 0 }
}

DimOffsetY :: proc(a : Dim, offsetY : f32) -> Dim {
    if offsetY >= 0 {
        return Dim{ a.x, a.y + a.height + offsetY, a.width, a.height, a.order }
    }
    else if offsetY < 0 {
        return Dim{ a.x, a.y - a.height - offsetY, a.width, a.height, a.order }
    }

    return Dim{ 0, 0, 0, 0, 0 }
}

DimAlign :: proc(a : Dim, b : ^Dim, valign : VerticalAlign, halign : HorizontalAlign) {
    DimVAlign(a, b, valign)
    DimHAlign(a, b, halign)
}

DimVAlign :: proc(a : Dim, b : ^Dim, valign : VerticalAlign) {
    if valign == .Top {
        b.y = a.y
    }
    else if valign == .Bottom {
        b.y = a.y - (b.height - a.height)
    }
    else if valign == .Centre {
        b.y = a.y - ((b.height - a.height) / 2)
    }
}

DimHAlign :: proc(a : Dim, b : ^Dim, halign : HorizontalAlign) {
    if halign == .Left {
        b.x = a.x
    }
    else if halign == .Right {
        b.x = a.x - (b.width - a.width)
    }
    else if halign == .Middle {
        b.x = a.x - ((b.width - a.width) / 2)
    }
}

DimAlignOffset :: proc(a : Dim, b : ^Dim, halign : HorizontalAlign, valign : VerticalAlign, hoffset, voffset : f32) {
    DimVAlignOffset(a, b, valign, voffset)
    DimHAlignOffset(a, b, halign, hoffset)
}

DimVAlignOffset :: proc(a : Dim, b : ^Dim, valign : VerticalAlign, offset : f32) {
    if valign == .Top {
        b.y = a.y - b.height - offset
    }
    else if valign == .Bottom {
        b.y = a.y + a.height + offset
    }
    else if valign == .Centre {
        b.y = a.y - ((b.height - a.height) / 2)
    }
}

DimHAlignOffset :: proc(a : Dim, b : ^Dim, halign : HorizontalAlign, offset : f32) {
    if halign == .Left {
        b.x = a.x - b.width - offset
    }
    else if halign == .Right {
        b.x = a.x + a.width + offset
    }
    else if halign == .Middle {
        b.x = a.x - ((b.width - a.width) / 2)
    }
}

DimScale :: proc(a : Dim, scaleX, scaleY : f32) -> Dim {
    ratioWidth := a.width * scaleX
    ratioX := a.x + ((a.width - ratioWidth) / 2)
    ratioHeight := a.height * scaleY
    ratioY := a.y + ((a.height - ratioHeight) / 2)
    return Dim{ ratioX, ratioY, ratioWidth, ratioHeight, a.order }
}

DimScaleX :: proc(a : Dim, scaleX : f32) -> Dim {
    ratioWidth := a.width * scaleX
    ratioX := a.x + ((a.width - ratioWidth) / 2)
    return Dim{ ratioX, a.y, ratioWidth, a.height, a.order }
}

DimScaleY :: proc(a : Dim, scaleY : f32) -> Dim {
    ratioHeight := a.height * scaleY
    ratioY := a.y + ((a.height - ratioHeight) / 2)
    return Dim{ a.x, ratioY, a.width, ratioHeight, a.order }
}

GetTextDim :: proc(text : string, font : ^rl.Font, fontSize : f32) -> Dim {
    cvalue := strings.clone_to_cstring(text)
    defer delete(cvalue)
    textSize := rl.MeasureTextEx(font^, cvalue, fontSize, 0)
    return Dim{ 0, 0, f32(textSize.x), f32(textSize.y), 0 }
}