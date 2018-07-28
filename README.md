# PICO8-WTK
A simple widget toolkit for PICO-8. A demo cart can be found [here](http://www.lexaloffle.com/bbs/?tid=28467).

### Reference

Undocumented functions and variables (prefixed with `_`) are not meant to be used. They may not work as expected, and they may be changed or removed without warning in future updates.
##### Widget

These properties are common to all widgets.

`widget.x`
`widget.y`
`widget.w`
`widget.h`

The widget's size and position. Position is relative to parent.

`widget.visible`

If false, the widget is not drawn and receives no input.

`widget.name`

Used to find the widget with gui_root:find() or panel:find().

`widget:abs_x()`
`widget:abs_y()`

Get the absolute position of this widget on the screen.

##### GUI root

The ancestor of all other widgets. Create a gui_root at the start of the program and add widgets to it to activate them.

`gui_root.widget_under_mouse`

The widget at the pointer's position that will receive input if the button is clicked. `nil` if there is no widget at the pointer's position or if no widget at that position wants input.

`gui_root.clicked_widget`

The widget that has been clicked. `nil` if the mouse button is not pressed or if it was not pressed over a widget that wanted input.

`gui_root.new()`

Create a new GUI root.

`gui_root:update()`

Update all widgets in the tree.

`gui_root:mouse_blocked()`

Returns true if the mouse is over a visible widget, whether that widget wants input or not. In other words, this indicates whether the GUI is covering whatever else is on the screen, "blocking" anything would otherwise be under the mouse. Note that this only checks the root's immediate children; if a panel has a child that extends beyond it, that won't be detected.

`gui_root:draw()`

Draw all visible widgets in the tree. Note that if there are any icons or color pickers, drawing them may affect the current palette.

`gui_root:add_child(w, x, y)`

Add widget w to the GUI at x, y.

`gui_root:remove_child(w)`

Remove widget w from the GUI.

`gui_root:find(name)`

Find a widget with the given name.

`gui_root:each([widget_type])`

An iterator used to loop over this widget and all its children. They're not guaranteed to be returned in any particular order. If an argument is given, only widgets of the specified type are returned.

For example:
```lua
for w in gui:each(checkbox) do
 data[checkbox.prop]=w.value
end
```

##### Panel

A simple panel to which other widgets can be added. It can be flat or have a beveled edge.

`panel.c`

The panel's color.

`panel.style`

The panel's style. Accepted values:
* 1: Convex
* 2: Concave
* 3: Flat

`panel.new([width, height,] [color,] [draggable,] [style])`

Creates a new panel. If draggable is true, the user can click and drag the panel to move it. Styles are the same as above.

`panel:add_child(w, x, y)`

Add widget `w` to this panel. `x` and `y` are relative to the panel. The panel will automatically expand downward and to the right if the widget would not fit, but negative `x` and `y` values won't be accounted for.

`panel:remove_child(w)`

Remove widget w from the panel.

`panel:find(name)`

Find a widget with the given name in this panel.

`panel:each([widget_type])`

An iterator used to loop over this widget and all its children. Works the same as `gui_root:find()`.

##### Label

A text label. Can be made clickable.

The text of a label can be fixed, or it can be provided by a function. If a function is used, it will be called every time the label is drawn. The label will be passed as an argument. See also the note about labels below.

`label.text`

The label's text or the function that returns its text.

`label.c`

The label's color.

`label.new(text, [color,] [func])`
Create a new label. `text` can be a string, a number, or a function that returns a string or number. `func` is a function to be called when the label is clicked. The label itself will be passed as an argument.

##### Icon

An 8x8 icon, which may be clickable.

Like labels, an icon can have its data provided by a function called when the icon is drawn. The icon will be passed as an argument.

`icon.num`

The icon's sprite number or the function that provides it.

`icon.trans`

This color will be made transparent when the icon is drawn. If this is set to a number, that color will be made transparent, and the palette will be reset after drawing. If this is `nil` the palette will not be affected.

`icon.new(num, [trans,] [func])`
Create a new icon. `num` can be a number or a function that returns a number. `func` is a function to be called when the icon is clicked. The icon will be passed as an argument.

##### Button

A clickable button that can be labeled with either text or an icon.

`button.c`

The button's color.

`button.new(label, func, [color])`

Create a new button. `label` is a string, a number, a function returning a string or number, or a widget. See the note about labels below. `func` will be called when the button is clicked, and the button will be passed as an argument.

##### Spinner

A widget for number entry.

`spinner.value`

The spinner's current value.

`spinner.new(minval, maxval, [initval,] [step,] [func])`

Create a new spinner. `initval` defaults to `minval`. `step` defaults to 1. `func` is a function to be called when the value changes. The spinner will be passed as an argument.

##### Checkbox

`checkbox.value`
Either `true` or `false`, indicating whether the checkbox is currently clicked.

`checkbox.new(text, [value,] [func])`
Create a new checkbox. `text` is a string, a number, a function returning a string or number, or a widget. See the note about labels below. `func` will be called when the checkbox is toggled, and the checkbox will be passed as an argument.

##### Radio button group

Before creating any radio buttons, you must create a group for them to share.

Note that a radio button group is not a widget and cannot be retrieved with widget:find(). You can instead find an individual radio button and get its group using 
`radio.group`.

`rbgroup.selected`

The currently selected radio button, or `nil` if none is selected.

`rbgroup.new([func])`

Create a new radio button group. `func` will be called when the selection changes. The selected radio button will be passed as an argument.

`rbgroup:select(value)`

Select the radio button with the given value. If none has that value, no button will be selected. Radio buttons are all deselected by default; use this function after adding buttons to the group to set the initial selection.

##### Radio button

`radio.group`

The rbgroup this button belongs to.

`radio.selected`

Either `true` or `false`, indicating whether this radio button is selected.

`radio.value`

The value of this radio button. This can be any type of data.

`radio.new(group, label, value)`

Create a new radio button. `label` is a string, a number, a function returning a string or number, or a widget. See the note about labels below.

##### Color picker

`color_picker.value`

The currently selected color. May be nil.

`color_picker.new([color,] [func])`

Create a new color picker. `color` is the initial selection. `func` will be called when a color is selected, and the color picker will be passed as an argument.

### A note about labels

`button.new()`, `radio.new()`, and `checkbox.new()` can take a string, a number, a function, or another widget as the label argument. A string will produce a text label and a number will produce an icon. If it's a function, the function will be called with no argument. If it returns a number, it's an icon; if it returns a string, it's text. If this is a text function, it will be called again by `label.new()`. The value returned by this call will determine the widget's width, and it will not be updated if the text changes.

Most of this also applies to `label.new()`, but that will be a text label even if the function returns a number.

### Miscellaneous tips

You can set `gui_root.visible` to false to hide the interface completely. Of course, you can also just not update or draw it.

You only really need one, but you could use multiple GUI roots for different program modes with totally different interfaces (e.g. one for a map editor and another for a sprite editor).

Note that the checkbox, radio button, spinner, and color picker all use a field named `value` for their current value. This makes it easy to write a callback that can handle all three. Just add to the widget a field indicating which property it controls. For instance:
```lua
local sp=spinner.new(16, 128, 16, 1, set_level_data)
sp.prop="size"
p:add_child(sp, 2, 2)

local grp=rbgroup.new(set_level_data)
local rb1=radio.new(grp, "Outdoor", 1)
rb1.prop="tileset"
local rb2=radio.new(grp, "Cave", 2)
rb2.prop="tileset"
local rb3=radio.new(grp, "Castle", 3)
rb3.prop="tileset"
grp:select(1)
p:add_child(rb1, 2, 13)
p:add_child(rb2, 2, 20)
p:add_child(rb3, 2, 27)
```
Then the set_level_data function might simply be:
```lua
function set_level_data(w)
 level_data[w.prop]=w.value
end
```
This could include buttons and clickable labels and icons, as well. None of those has a `value` field normally, but there's no harm in adding one.
