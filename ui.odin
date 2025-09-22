ppackage ui

import "core:fmt"
import "core:hash"
import "core:path/filepath"
import "core:strings"
import "vendor:raylib"


Vec2 :: raylib.Vector2
Vec3 :: raylib.Vector3
Vec4 :: raylib.Vector4
Color :: raylib.Color
Rect :: struct {
    minx, miny: f32,
    maxx, maxy: f32,
}


Element_Flag :: enum {
    DRAW_BACKGROUND,
    DRAW_BORDER,
    DRAW_TEXT,

    HOVERABLE,
    FOCUSABLE,
    PRESSABLE,
    CLICKABLE,
    DRAGGABLE,

    CLIP_CHILDREN,
}
Element_Flags :: bit_set[Element_Flag; u32]

Element :: struct {
    next: ^Element,
    first_child: ^Element,
    parent: ^Element,

    flags: Element_Flags,

    hash_next: ^Element,
    hash: u32,
    key: string,

    layout_axis: Axis,
    bg_color: Color,
    fg_color: Color,
    text_color: Color,
    border_width: f32,
    font: ^Font,
    font_size: f32,

    semantic_size: [Axis]Size,
    minimum_size: [Axis]Size,
    intrinsic_size: [Axis]f32,
    computed_size: [Axis]f32,

    rect: Rect,
    text: string,

    signal: Signal,
}

root: ^Element
table: []^Element



find :: proc(table: ^[]^Element, key: string) -> (^Element, bool) #optional_ok {
    hash := hash.murmur32(transmute([]byte) key)
    index := hash % cast(u32) len(table)
    head := table[index]
    for p := head; p != nil; p = p.hash_next {
        if p.hash == hash && p.key == key {
            return p, true
        }
    }
    return nil, false
}

place :: proc(table: ^[]^Element, key: string) -> ^Element {
    hash := hash.murmur32(transmute([]byte) key)
    index := hash % cast(u32) len(table)
    head := table[index]
    elem: ^Element
    for p := head; p != nil; p = p.hash_next {
        if p.hash == hash && p.key == key {
            elem = p
            elem.parent = nil
            elem.next = nil
            elem.first_child = nil
            break
        }
    }
    if elem == nil {
        elem = new(Element)
        elem.hash = hash
        elem.hash_next = head
        elem.key = strings.clone(key)
        table[index] = elem
    }

    elem.parent = top_parent()
    elem.flags = top_flags()
    elem.layout_axis = top_layout_axis()
    elem.bg_color = top_bg_color()
    elem.fg_color = top_fg_color()
    elem.text_color = top_text_color()
    elem.border_width = top_border_width()
    elem.font = top_font()
    elem.font_size = top_font_size()
    elem.semantic_size = top_size()
    elem.minimum_size = {}
    elem.intrinsic_size = {}
    elem.computed_size = {}
    elem.rect = {}

    if elem.parent != nil {
        if elem.parent.first_child == nil {
            elem.parent.first_child = elem
        } else {
            for p := elem.parent.first_child;; p = p.next {
                if p.next == nil {
                    p.next = elem
                    break
                }
            }
        }
    }

    return elem
}


cut_left :: #force_inline proc "contextless" (r: Rect, a: f32) -> (Rect, Rect) {
    return {r.minx, r.miny, r.minx+a, r.maxy},
           {r.minx+a, r.miny, r.maxx, r.maxy};
}
cut_right :: #force_inline proc "contextless" (r: Rect, a: f32) -> (Rect, Rect) {
    return {r.minx, r.miny, r.maxx-a, r.maxy},
           {r.maxx-a, r.miny, r.maxx, r.maxy};
}
cut_top :: #force_inline proc "contextless" (r: Rect, a: f32) -> (Rect, Rect) {
    return {r.minx, r.miny, r.maxx, r.miny+a},
           {r.minx, r.miny+a, r.maxx, r.maxy};
}
cut_bottom :: #force_inline proc "contextless" (r: Rect, a: f32) -> (Rect, Rect) {
    return {r.minx, r.miny, r.maxx, r.maxy-a},
           {r.minx, r.maxy-a, r.maxx, r.maxy};
}

shrink_a :: #force_inline proc "contextless" (r: Rect, a: f32) -> Rect {
    return {r.minx+a, r.miny+a, r.maxx-a, r.maxy-a}
}
shrink_h :: #force_inline proc "contextless" (r: Rect, a: f32) -> Rect {
    return {r.minx+a, r.miny, r.maxx-a, r.maxy}
}
shrink_v :: #force_inline proc "contextless" (r: Rect, a: f32) -> Rect {
    return {r.minx, r.miny+a, r.maxx, r.maxy-a}
}
shrink :: #force_inline proc "contextless" (r: Rect, la, ra, ta, ba: f32) -> Rect {
    return {r.minx+la, r.miny+ta, r.maxx-ra, r.maxy-ba}
}

expand_a :: #force_inline proc "contextless" (r: Rect, a: f32) -> Rect {
    return {r.minx-a, r.miny-a, r.maxx+a, r.maxy+a}
}
expand_h :: #force_inline proc "contextless" (r: Rect, a: f32) -> Rect {
    return {r.minx-a, r.miny, r.maxx+a, r.maxy}
}
expand_v :: #force_inline proc "contextless" (r: Rect, a: f32) -> Rect {
    return {r.minx, r.miny-a, r.maxx, r.maxy+a}
}
expand :: #force_inline proc "contextless" (r: Rect, la, ra, ta, ba: f32) -> Rect {
    return {r.minx-la, r.miny-ta, r.maxx+ra, r.maxy+ba}
}


convert :: #force_inline proc "contextless" (using rect: Rect) -> raylib.Rectangle {
    return {minx, miny, maxx-minx, maxy-miny}
}


hover_root: ^Element
focus_root: ^Element
drag_root: ^Element


Signal :: struct {
    drag_delta: Vec2,
    is_hovered: bool,
    is_focused: bool,
    is_pressed: bool,
    is_clicked: bool,
    is_dragged: bool,
}


Axis :: enum { X, Y }

Size_Kind :: enum {
    PX,
    EM,
    TXT,
    SUM_OF_CHILDREN,
    PCT_OF_PARENT,
    FILL,
}

Size :: struct {
    kind: Size_Kind,
    value: f32,
}

px :: proc { px1, px2 }
px1 :: #force_inline proc(x: f32) -> Size {
    return {kind=.PX, value=x}
}
px2 :: #force_inline proc(x, y: f32) -> [Axis]Size {
    return { .X = {kind=.PX, value=x}, .Y = {kind=.PX, value=y} }
}

em :: proc { em1, em2 }
em1 :: #force_inline proc(x: f32) -> Size {
    return {kind=.EM, value=x}
}
em2 :: #force_inline proc(x, y: f32) -> [Axis]Size {
    return { .X = {kind=.EM, value=x}, .Y = {kind=.EM, value=y} }
}

txt :: proc { txt1, txt2 }
txt1 :: #force_inline proc(x: f32) -> Size {
    return  {kind=.TXT, value=x}
}
txt2 :: #force_inline proc(x, y: f32) -> [Axis]Size {
    return  { .X = {kind=.TXT, value=x}, .Y = {kind=.TXT, value=y} }
}

pct :: proc { pct1, pct2 }
pct1 :: #force_inline proc(x: f32) -> Size {
    return {kind=.PCT_OF_PARENT, value=x}
}
pct2 :: #force_inline proc(x, y: f32) -> [Axis]Size {
    return { .X = {kind=.PCT_OF_PARENT, value=x}, .Y = {kind=.PCT_OF_PARENT, value=y} }
}

sum_of_children :: #force_inline proc() -> Size {
    return {kind=.SUM_OF_CHILDREN, value=1}
}
sum_of_children2 :: #force_inline proc() -> [Axis]Size {
    return { .X = {kind=.SUM_OF_CHILDREN, value=1}, .Y = {kind=.SUM_OF_CHILDREN, value=1} }
}

fill :: #force_inline proc() -> Size {
    return {kind=.FILL, value=1}
}
fill2 :: #force_inline proc() -> [Axis]Size {
    return { .X = {kind=.FILL, value=1}, .Y = {kind=.FILL, value=1} }
}


layout_strict_size :: proc(elem: ^Element, $axis: Axis) {
    for p := elem.first_child; p != nil; p = p.next {
        layout_strict_size(p, axis)
    }
    switch elem.semantic_size[axis].kind {
    case .PX:            elem.intrinsic_size[axis] = elem.semantic_size[axis].value
    case .EM:            elem.intrinsic_size[axis] = elem.semantic_size[axis].value * elem.font_size
    case .TXT:           elem.intrinsic_size[axis] = elem.semantic_size[axis].value * measure_text(elem.font, elem.font_size, elem.text)[axis]
    case .PCT_OF_PARENT: elem.intrinsic_size[axis] = 0 // depends on parent size
    case .SUM_OF_CHILDREN, .FILL:
        min_abs: f32
        #partial switch elem.minimum_size[axis].kind {
        case .PX:  min_abs = elem.minimum_size[axis].value
        case .EM:  min_abs = elem.minimum_size[axis].value * elem.font_size
        case .TXT: min_abs = elem.minimum_size[axis].value * measure_text(elem.font, elem.font_size, elem.text)[axis]
        }
        if elem.layout_axis == axis {
            F, proportion, fill_min: f32
            for p := elem.first_child; p != nil; p = p.next {
                switch p.semantic_size[axis].kind {
                case .PCT_OF_PARENT:
                    proportion += p.semantic_size[axis].value
                case .FILL:
                    m: f32
                    #partial switch p.minimum_size[axis].kind {
                    case .PX:  m = p.minimum_size[axis].value
                    case .EM:  m = p.minimum_size[axis].value * p.font_size
                    case .TXT: m = p.minimum_size[axis].value * measure_text(elem.font, elem.font_size, elem.text)[axis]
                    }
                    fill_min += m
                case .PX, .EM, .TXT, .SUM_OF_CHILDREN:
                    F += p.intrinsic_size[axis]
                }
            }
            P: f32
            if proportion >= 1.0 {
                // Degenerate case: treat % as saturating
                P = F + fill_min
            } else {
                P = (F + fill_min) / (1 - proportion)
            }
            elem.intrinsic_size[axis] = max(P, min_abs)
        } else {
            M: f32
            for p := elem.first_child; p != nil; p = p.next {
                M = max(M, p.intrinsic_size[axis])
            }
            elem.intrinsic_size[axis] = max(M, min_abs)
        }
    }
}

layout_flex_size :: proc(elem: ^Element, $axis: Axis, parent_size: f32, start: f32) {
    // compute our absolute minimum under THIS parent
    minimum: f32
    #partial switch elem.minimum_size[axis].kind {
    case .PX:            minimum = elem.minimum_size[axis].value
    case .EM:            minimum = elem.minimum_size[axis].value * elem.font_size
    case .TXT:           minimum = elem.minimum_size[axis].value * measure_text(elem.font, elem.font_size, elem.text)[axis]
    case .PCT_OF_PARENT: minimum = elem.minimum_size[axis].value * parent_size;
    }

    // compute from semantics; if parent is already assigned, never shrink
    current := elem.computed_size[axis]
    computed: f32
    switch elem.semantic_size[axis].kind {
    case .PX:              computed = max(minimum, elem.semantic_size[axis].value)
    case .EM:              computed = max(minimum, elem.semantic_size[axis].value * elem.font_size)
    case .TXT:             computed = max(minimum, elem.semantic_size[axis].value * measure_text(elem.font, elem.font_size, elem.text)[axis])
    case .PCT_OF_PARENT:   computed = max(minimum, elem.semantic_size[axis].value * parent_size)
    case .SUM_OF_CHILDREN: computed = max(minimum, elem.intrinsic_size[axis])
    case .FILL:
        // parent should normally assign; as a root fallback, honor min only
        if current < minimum {
            elem.computed_size[axis] = minimum
        }
    }
    // skip the max() merge for FILL; parent remains authoritative
    if elem.semantic_size[axis].kind != .FILL && computed > current {
        elem.computed_size[axis] = computed
    }

    // set our rect along this axis
    switch axis {
    case .X: elem.rect.minx = start; elem.rect.maxx = start + elem.computed_size[axis]
    case .Y: elem.rect.miny = start; elem.rect.maxy = start + elem.computed_size[axis]
    }

    // if no children, we're done
    if elem.first_child == nil {
        return
    }

    // distribute space to children linearly along this axis only if this is the parent's flow axis
    P := elem.computed_size[axis]
    if elem.layout_axis != axis {
        // cross-axis: don't advance a cursor
        for p := elem.first_child; p != nil; p = p.next {
            minc: f32
            #partial switch p.minimum_size[axis].kind {
            case .PX:            minc = p.minimum_size[axis].value
            case .EM:            minc = p.minimum_size[axis].value * p.font_size
            case .TXT:           minc = p.minimum_size[axis].value * measure_text(p.font, p.font_size, p.text)[axis]
            case .PCT_OF_PARENT: minc = p.minimum_size[axis].value * P
            }
            s: f32
            switch p.semantic_size[axis].kind {
            case .PX:              s = max(minc, p.semantic_size[axis].value)
            case .EM:              s = max(minc, p.semantic_size[axis].value * p.font_size)
            case .TXT:             s = max(minc, p.semantic_size[axis].value * measure_text(p.font, p.font_size, p.text)[axis])
            case .PCT_OF_PARENT:   s = max(minc, p.semantic_size[axis].value * P)
            case .SUM_OF_CHILDREN: s = max(minc, p.intrinsic_size[axis])
            case .FILL:            s = max(minc, P) // stretch on cross-axis
            }
            p.computed_size[axis] = s
            // all children share the same cross-axis start; no cursor advance
            layout_flex_size(p, axis, s, start)
        }
        return
    }

    // main axis: linear sequencing with cursor & FILL distribution
    sum_assigned: f32
    num_fills: u32
    fill_min_sum: f32

    // first pass: assign sizes to non-FILL children and tally FILL mins
    for p := elem.first_child; p != nil; p = p.next {
        minc: f32
        #partial switch p.minimum_size[axis].kind {
        case .PX:            minc = p.minimum_size[axis].value
        case .EM:            minc = p.minimum_size[axis].value * p.font_size
        case .TXT:           minc = p.minimum_size[axis].value * measure_text(p.font, p.font_size, p.text)[axis]
        case .PCT_OF_PARENT: minc = p.minimum_size[axis].value * P
        }

        switch p.semantic_size[axis].kind {
        case .PX:
            s := p.semantic_size[axis].value
            if s < minc {
                s = minc
            }
            p.computed_size[axis] = s
            sum_assigned += s

        case .EM:
            s := p.semantic_size[axis].value * p.font_size
            if s < minc {
                s = minc
            }
            p.computed_size[axis] = s
            sum_assigned += s

        case .TXT:
            s := p.semantic_size[axis].value * measure_text(p.font, p.font_size, p.text)[axis]
            if s < minc {
                s = minc
            }
            p.computed_size[axis] = s
            sum_assigned += s

        case .PCT_OF_PARENT:
            s := p.semantic_size[axis].value * P
            if s < minc {
                s = minc
            }
            p.computed_size[axis] = s
            sum_assigned += s

        case .SUM_OF_CHILDREN:
            s := p.intrinsic_size[axis]
            if s < minc {
                s = minc
            }
            p.computed_size[axis] = s
            sum_assigned += s

        case .FILL:
            num_fills += 1
            fill_min_sum += minc
            // assigned later
        }
    }

    remaining := max(P - sum_assigned, 0)
    extra := max(remaining - fill_min_sum, 0)
    fill_extra_each: f32
    if num_fills > 0 {
        fill_extra_each = extra / f32(num_fills)
    }

    // second: finalize FILL sizes
    for p := elem.first_child; p != nil; p = p.next {
        if p.semantic_size[axis].kind == .FILL {
            minc: f32
            #partial switch p.minimum_size[axis].kind {
            case .PX:            minc = p.minimum_size[axis].value
            case .EM:            minc = p.minimum_size[axis].value * p.font_size
            case .TXT:           minc = p.minimum_size[axis].value * measure_text(p.font, p.font_size, p.text)[axis]
            case .PCT_OF_PARENT: minc = p.minimum_size[axis].value * P
            }
            s := minc + fill_extra_each
            if s < 0 {
                s = 0
            }
            p.computed_size[axis] = s
        }
    }

    // third: place children along the main axis and recurse
    cursor := start
    for p := elem.first_child; p != nil; p = p.next {
        // recurse: child will keep its preassigned compute_size[axis]
        layout_flex_size(p, axis, p.computed_size[axis], cursor)
        cursor += p.computed_size[axis]
    }
}


layout :: proc(elem: ^Element) {
    layout_strict_size(elem, .X)
    layout_flex_size(elem, .X, 1920, 0)
    layout_strict_size(elem, .Y)
    layout_flex_size(elem, .Y, 1080, 0)
}


input :: proc(elem: ^Element) -> Signal {
    using raylib
    for p := elem.first_child; p != nil; p = p.next {
        input(p)
    }
    if .HOVERABLE in elem.flags {
        elem.signal.is_hovered = CheckCollisionPointRec(GetMousePosition(), convert(elem.rect))
    } else {
        elem.signal.is_hovered = false
    }
    if .FOCUSABLE in elem.flags {
        // TODO: ...
    }
    if .CLICKABLE in elem.flags {
        elem.signal.is_clicked = elem.signal.is_pressed && CheckCollisionPointRec(GetMousePosition(), convert(elem.rect)) && IsMouseButtonReleased(.LEFT)
    }
    if .PRESSABLE in elem.flags {
        elem.signal.is_pressed = (elem.signal.is_pressed || (elem.signal.is_hovered && IsMouseButtonPressed(.LEFT))) && !IsMouseButtonUp(.LEFT)
    } else {
        elem.signal.is_pressed = false
    }
    if .DRAGGABLE in elem.flags {
        elem.signal.is_dragged = elem.signal.is_pressed
    } else {
        elem.signal.is_dragged = false
    }

    if elem.signal.is_hovered {
        hover_root = elem
    }
    if elem.signal.is_focused {
        focus_root = elem
    }
    if elem.signal.is_pressed {
        // TODO: ...
    }
    if elem.signal.is_clicked {
        // TODO: ...
    }
    if elem.signal.is_dragged  {
        drag_root = elem
        elem.signal.drag_delta = GetMouseDelta()
    }
    return elem.signal
}


draw :: proc(elem: ^Element) {
    using raylib
    rect: raylib.Rectangle = {elem.rect.minx, elem.rect.miny, elem.rect.maxx-elem.rect.minx, elem.rect.maxy-elem.rect.miny}
    if .DRAW_BACKGROUND in elem.flags {
        color := elem.bg_color
        switch {
        case elem.signal.is_pressed: color = BLUE
        case elem.signal.is_hovered: color = SKYBLUE
        }
        DrawRectangleRec(rect, color)
    }
    if .DRAW_BORDER in elem.flags {
        DrawRectangleLinesEx(rect, elem.border_width, elem.fg_color)
    }
    if .DRAW_TEXT in elem.flags {
        draw_text(elem.font, {rect.x, rect.y}, elem.font_size, elem.text, elem.text_color)
    }
    if .CLIP_CHILDREN in elem.flags {
        BeginScissorMode(
            i32(elem.rect.minx),
            i32(elem.rect.miny),
            i32(elem.rect.maxx-elem.rect.minx),
            i32(elem.rect.maxy-elem.rect.miny),
        )
    }
    for p := elem.first_child; p != nil; p = p.next {
        draw(p)
    }
    if .CLIP_CHILDREN in elem.flags {
        EndScissorMode()
    }
}



Font_Size :: struct {
    handle: raylib.Font,
    size: i32,
}

Font :: struct {
    name: string,
    file_path: string,
    sizes: [dynamic]Font_Size,
}


make_font :: proc(file_path: string) -> Font {
    name := filepath.base(file_path)
    return {name, strings.clone(file_path), nil}
}

get_font_size :: proc(font: ^Font, font_size: i32) -> raylib.Font {
    using raylib
    for &f in font.sizes {
        if f.size == font_size {
            return f.handle
        }
    }
    codepoints: [126-32+1]rune
    for c, i in 32..=126 {
        codepoints[i] = rune(c)
    }
    handle := LoadFontEx(fmt.ctprint(font.file_path), font_size, &codepoints[0], len(codepoints))
    append(&font.sizes, Font_Size{handle, font_size})
    return handle
}

draw_text :: proc(font: ^Font, pos: Vec2, font_size: f32, text: string, color: Color, spacing: f32 = 0) {
    using raylib
    handle := get_font_size(font, i32(font_size))
    DrawTextEx(handle, fmt.ctprint(text), pos, font_size, spacing, color)
}

measure_text :: proc(font: ^Font, font_size: f32, text: string, spacing: f32 = 0) -> Vec2 {
    using raylib
    handle := get_font_size(font, i32(font_size))
    return MeasureTextEx(handle, fmt.ctprint(text), font_size, spacing)
}



button :: proc(label: string) -> Signal {
    next_flags(top_flags() + {.DRAW_BACKGROUND, .DRAW_BORDER, .HOVERABLE, .FOCUSABLE, .PRESSABLE, .CLICKABLE})
    next_layout_axis(.X)
    next_size(sum_of_children2())
    box := place(&table, label)
    push_parent(box)

    spacer(fmt.tprintf("%s/center/left", label), pct(0.1))
    begin_container(fmt.tprintf("%s/center/y", label), .Y, { .X = sum_of_children(), .Y = fill() })
    spacer(fmt.tprintf("%s/center/top", label), pct(0.2))

    next_flags(top_flags() + {.DRAW_TEXT} - {.DRAW_BACKGROUND, .DRAW_BORDER})
    next_size(txt(1, 1))
    elem := place(&table, fmt.tprintf("%s/text", label))
    elem.text = label

    spacer(fmt.tprintf("%s/center/bottom", label), pct(0.2))
    end_container() // outer-y
    spacer(fmt.tprintf("%s/center/right", label), pct(0.1))
    pop_parent()
    return box.signal
}

@(deferred_none=end_container)
scope_container :: #force_inline proc(label: string, layout_axis: Axis, size: [Axis]Size) {
    begin_container(label, layout_axis, size)
}

begin_container :: proc(label: string, layout_axis: Axis, size: [Axis]Size) {
    flags := top_flags()
    next_flags(flags + {.CLIP_CHILDREN} - {.DRAW_BACKGROUND, .DRAW_BORDER})
    next_layout_axis(layout_axis)
    next_size(size)
    elem := place(&table, label)
    push_parent(elem)
}

end_container :: proc() {
    pop_parent()
}

// Centers subsequent children both horizontally and vertically.
begin_center :: proc(label: string, layout_axis: Axis, size: [Axis]Size) {
    begin_container(fmt.tprintf("%s/center/x", label), .X, fill2())
    spacer(fmt.tprintf("%s/center/left", label), fill())
    begin_container(fmt.tprintf("%s/center/y", label), .Y, { .X = {.SUM_OF_CHILDREN, 1}, .Y = {.FILL, 1} })
    spacer(fmt.tprintf("%s/center/top", label), fill())
    next_layout_axis(layout_axis)
    begin_container(fmt.tprintf("%s/center/content", label), layout_axis, size)
}

end_center :: proc(label: string, layout_axis: Axis, size: [Axis]Size) {
    end_container()
    spacer(fmt.tprintf("%s/center/bottom", label), fill())
    end_container() // outer-y
    spacer(fmt.tprintf("%s/center/right", label), fill())
    end_container() // outer-x
}

@(deferred_in=end_center)
scope_center :: #force_inline proc(label: string, layout_axis: Axis, size: [Axis]Size) {
    begin_center(label, layout_axis, size)
}

box :: proc(label: string) {
    next_flags(top_flags() + {.DRAW_BACKGROUND, .DRAW_BORDER})
    elem := place(&table, label)
}

spacer :: proc(label: string, size: Size) {
    parent := top_parent()
    next_flags(top_flags() - {.DRAW_BACKGROUND, .DRAW_BORDER})
    spacer_size: [Axis]Size
    spacer_size[parent.layout_axis] = size
    next_size(spacer_size)
    elem := place(&table, label)
}




main :: proc() {
    using raylib
    SetTraceLogLevel(.ERROR)
    InitWindow(1920, 1080, "ui")

    default_font := make_font("res/FiraMono-Regular.ttf")

    table = make([]^Element, 1024)

    push_parent(nil)
    push_flags(nil)
    push_layout_axis(.X)
    push_bg_color(BLUE)
    push_fg_color(BLACK)
    push_text_color(WHITE)
    push_border_width(0)
    push_font(&default_font)
    push_font_size(22)

    for !WindowShouldClose() {
        {
            push_size(px(1920, 1080))
            root = place(&table, "root")

            scope_parent(root)
            scope_flags({.DRAW_BACKGROUND, .DRAW_BORDER})
            scope_bg_color(MAROON)
            scope_text_color(BLACK)
            scope_border_width(2)

            {
                scope_center("wrapper", .Y, sum_of_children2())
                scope_bg_color(BEIGE)
                scope_border_width(1)

                if button("button-a").is_clicked {
                    fmt.println("blah")
                }

                spacer("sa", px(20))
                button("button-b")
                spacer("sb", px(20))
                button("button-c")
                spacer("sc", px(20))
                button("button-d")
            }
        }

        // print(root)
        layout(root)
        input(root)

        ClearBackground(DARKGRAY)
        BeginDrawing()
            draw(root)
        EndDrawing()
    }
}


print :: proc(elem: ^Element, indent := 0) {
    for _ in 0..<indent { fmt.print("    ") }
    fmt.printfln(`"{}": {} {}`, elem.key, elem.computed_size, elem.rect)
    for p := elem.first_child; p != nil; p = p.next {
        print(p, indent+1)
    }
}