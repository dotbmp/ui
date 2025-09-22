package ui

Property :: struct($T: typeid) {
    next: ^Property(T),
    value: T,
    once: bool,
}

push_property :: proc(stack: ^^Property($T), value: T) {
    head := stack^
    next := new(Property(T))
    next.next = head
    next.value = value
    next.once = false
    stack^ = next
}

next_property :: proc(stack: ^^Property($T), value: T) {
    head := stack^
    next := new(Property(T))
    next.next = head
    next.value = value
    next.once = true
    stack^ = next
}

pop_property :: proc(stack: ^^Property($T)) -> T {
    head := stack^
    defer free(head)
    stack^ = head.next
    return head.value
}

top_property :: proc(stack: ^^Property($T)) -> T {
    head := stack^
    if head.once {
        defer free(head)
        stack^ = head.next
        return head.value
    } else {
        return head.value
    }
}

// SPECIALIZED SIZE HELPERS

push_size :: proc(size: [Axis]Size, min: [Axis]Size = {}) { push_property(&x_size_stack, size[.X]); push_property(&y_size_stack, size[.Y]) }
next_size :: proc(size: [Axis]Size, min: [Axis]Size = {}) { next_property(&x_size_stack, size[.X]); next_property(&y_size_stack, size[.Y]) }
pop_size :: proc() -> [Axis]Size { return { .X = pop_property(&x_size_stack), .Y = pop_property(&y_size_stack) } }
top_size :: proc() -> [Axis]Size { return { .X = top_property(&x_size_stack), .Y = top_property(&y_size_stack) } }
@(deferred_none=scope_exit_size)
scope_size :: proc(size: [Axis]Size) { push_property(&x_size_stack, size[.X]); push_property(&y_size_stack, size[.Y]) }
scope_exit_size :: proc() { pop_property(&x_size_stack); pop_property(&y_size_stack) }

parent_stack: ^Property(^Element)
push_parent :: #force_inline proc(parent: ^Element) { push_property(&parent_stack, parent) }
next_parent :: #force_inline proc(parent: ^Element) { next_property(&parent_stack, parent) }
pop_parent :: #force_inline proc() -> ^Element { return pop_property(&parent_stack) }
top_parent :: #force_inline proc() -> ^Element { return top_property(&parent_stack) }
@(deferred_none=scope_exit_parent)
scope_parent :: #force_inline proc(parent: ^Element) { push_property(&parent_stack, parent) }
scope_exit_parent :: #force_inline proc() { pop_property(&parent_stack) }

flags_stack: ^Property(Element_Flags)
push_flags :: #force_inline proc(flags: Element_Flags) { push_property(&flags_stack, flags) }
next_flags :: #force_inline proc(flags: Element_Flags) { next_property(&flags_stack, flags) }
pop_flags :: #force_inline proc() -> Element_Flags { return pop_property(&flags_stack) }
top_flags :: #force_inline proc() -> Element_Flags { return top_property(&flags_stack) }
@(deferred_none=scope_exit_flags)
scope_flags :: #force_inline proc(flags: Element_Flags) { push_property(&flags_stack, flags) }
scope_exit_flags :: #force_inline proc() { pop_property(&flags_stack) }

layout_axis_stack: ^Property(Axis)
push_layout_axis :: #force_inline proc(layout_axis: Axis) { push_property(&layout_axis_stack, layout_axis) }
next_layout_axis :: #force_inline proc(layout_axis: Axis) { next_property(&layout_axis_stack, layout_axis) }
pop_layout_axis :: #force_inline proc() -> Axis { return pop_property(&layout_axis_stack) }
top_layout_axis :: #force_inline proc() -> Axis { return top_property(&layout_axis_stack) }
@(deferred_none=scope_exit_layout_axis)
scope_layout_axis :: #force_inline proc(layout_axis: Axis) { push_property(&layout_axis_stack, layout_axis) }
scope_exit_layout_axis :: #force_inline proc() { pop_property(&layout_axis_stack) }

bg_color_stack: ^Property(Color)
push_bg_color :: #force_inline proc(bg_color: Color) { push_property(&bg_color_stack, bg_color) }
next_bg_color :: #force_inline proc(bg_color: Color) { next_property(&bg_color_stack, bg_color) }
pop_bg_color :: #force_inline proc() -> Color { return pop_property(&bg_color_stack) }
top_bg_color :: #force_inline proc() -> Color { return top_property(&bg_color_stack) }
@(deferred_none=scope_exit_bg_color)
scope_bg_color :: #force_inline proc(bg_color: Color) { push_property(&bg_color_stack, bg_color) }
scope_exit_bg_color :: #force_inline proc() { pop_property(&bg_color_stack) }

fg_color_stack: ^Property(Color)
push_fg_color :: #force_inline proc(fg_color: Color) { push_property(&fg_color_stack, fg_color) }
next_fg_color :: #force_inline proc(fg_color: Color) { next_property(&fg_color_stack, fg_color) }
pop_fg_color :: #force_inline proc() -> Color { return pop_property(&fg_color_stack) }
top_fg_color :: #force_inline proc() -> Color { return top_property(&fg_color_stack) }
@(deferred_none=scope_exit_fg_color)
scope_fg_color :: #force_inline proc(fg_color: Color) { push_property(&fg_color_stack, fg_color) }
scope_exit_fg_color :: #force_inline proc() { pop_property(&fg_color_stack) }

text_color_stack: ^Property(Color)
push_text_color :: #force_inline proc(text_color: Color) { push_property(&text_color_stack, text_color) }
next_text_color :: #force_inline proc(text_color: Color) { next_property(&text_color_stack, text_color) }
pop_text_color :: #force_inline proc() -> Color { return pop_property(&text_color_stack) }
top_text_color :: #force_inline proc() -> Color { return top_property(&text_color_stack) }
@(deferred_none=scope_exit_text_color)
scope_text_color :: #force_inline proc(text_color: Color) { push_property(&text_color_stack, text_color) }
scope_exit_text_color :: #force_inline proc() { pop_property(&text_color_stack) }

font_stack: ^Property(^Font)
push_font :: #force_inline proc(font: ^Font) { push_property(&font_stack, font) }
next_font :: #force_inline proc(font: ^Font) { next_property(&font_stack, font) }
pop_font :: #force_inline proc() -> ^Font { return pop_property(&font_stack) }
top_font :: #force_inline proc() -> ^Font { return top_property(&font_stack) }
@(deferred_none=scope_exit_font)
scope_font :: #force_inline proc(font: ^Font) { push_property(&font_stack, font) }
scope_exit_font :: #force_inline proc() { pop_property(&font_stack) }

font_size_stack: ^Property(f32)
push_font_size :: #force_inline proc(font_size: f32) { push_property(&font_size_stack, font_size) }
next_font_size :: #force_inline proc(font_size: f32) { next_property(&font_size_stack, font_size) }
pop_font_size :: #force_inline proc() -> f32 { return pop_property(&font_size_stack) }
top_font_size :: #force_inline proc() -> f32 { return top_property(&font_size_stack) }
@(deferred_none=scope_exit_font_size)
scope_font_size :: #force_inline proc(font_size: f32) { push_property(&font_size_stack, font_size) }
scope_exit_font_size :: #force_inline proc() { pop_property(&font_size_stack) }

border_width_stack: ^Property(f32)
push_border_width :: #force_inline proc(border_width: f32) { push_property(&border_width_stack, border_width) }
next_border_width :: #force_inline proc(border_width: f32) { next_property(&border_width_stack, border_width) }
pop_border_width :: #force_inline proc() -> f32 { return pop_property(&border_width_stack) }
top_border_width :: #force_inline proc() -> f32 { return top_property(&border_width_stack) }
@(deferred_none=scope_exit_border_width)
scope_border_width :: #force_inline proc(border_width: f32) { push_property(&border_width_stack, border_width) }
scope_exit_border_width :: #force_inline proc() { pop_property(&border_width_stack) }

x_size_stack: ^Property(Size)
push_x_size :: #force_inline proc(x_size: Size) { push_property(&x_size_stack, x_size) }
next_x_size :: #force_inline proc(x_size: Size) { next_property(&x_size_stack, x_size) }
pop_x_size :: #force_inline proc() -> Size { return pop_property(&x_size_stack) }
top_x_size :: #force_inline proc() -> Size { return top_property(&x_size_stack) }
@(deferred_none=scope_exit_x_size)
scope_x_size :: #force_inline proc(x_size: Size) { push_property(&x_size_stack, x_size) }
scope_exit_x_size :: #force_inline proc() { pop_property(&x_size_stack) }

y_size_stack: ^Property(Size)
push_y_size :: #force_inline proc(y_size: Size) { push_property(&y_size_stack, y_size) }
next_y_size :: #force_inline proc(y_size: Size) { next_property(&y_size_stack, y_size) }
pop_y_size :: #force_inline proc() -> Size { return pop_property(&y_size_stack) }
top_y_size :: #force_inline proc() -> Size { return top_property(&y_size_stack) }
@(deferred_none=scope_exit_y_size)
scope_y_size :: #force_inline proc(y_size: Size) { push_property(&y_size_stack, y_size) }
scope_exit_y_size :: #force_inline proc() { pop_property(&y_size_stack) }
