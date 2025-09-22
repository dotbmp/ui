package ui_meta

import "core:fmt"
import "core:strings"
import "core:os"


Property :: struct {
    name: string,
    type: string,
}

properties :: [?]Property {
    { name="parent", type="^Element" },
    { name="flags", type="Element_Flags" },
    { name="layout_axis", type="Axis" },
    { name="bg_color", type="Color" },
    { name="fg_color", type="Color" },
    { name="text_color", type="Color" },
    { name="font", type="^Font" },
    { name="font_size", type="f32" },
    { name="border_width", type="f32" },
    { name="x_size", type="Size" },
    { name="y_size", type="Size" },
}


PREAMBLE :: `package ui

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
`

TYPE_TEMPLATE :: `
{0}_stack: ^Property({1})
push_{0} :: #force_inline proc({0}: {1}) {{ push_property(&{0}_stack, {0}) }
next_{0} :: #force_inline proc({0}: {1}) {{ next_property(&{0}_stack, {0}) }
pop_{0} :: #force_inline proc() -> {1} {{ return pop_property(&{0}_stack) }
top_{0} :: #force_inline proc() -> {1} {{ return top_property(&{0}_stack) }
@(deferred_none=scope_exit_{0})
scope_{0} :: #force_inline proc({0}: {1}) {{ push_property(&{0}_stack, {0}) }
scope_exit_{0} :: #force_inline proc() {{ pop_property(&{0}_stack) }
`

main :: proc() {
    sb := strings.builder_make()
    strings.write_string(&sb, PREAMBLE)
    for p in properties {
        fmt.sbprintf(&sb, TYPE_TEMPLATE, p.name, p.type)
    }
    text := strings.to_string(sb)
    ok := os.write_entire_file("properties.odin", transmute([]byte) text)
    assert(ok)
}