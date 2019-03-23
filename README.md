# PICO8-WTK
A simple widget toolkit for PICO-8. A demo cart can be found [here](http://www.lexaloffle.com/bbs/?tid=28467).

## Reference

Undocumented functions and variables (prefixed with `_`) are not meant to be used. They may not work as expected, and they may be changed or removed without notice in future updates.

All widget constructors take a table of property settings as their only argument. Lua allows you to omit parentheses in this case. For example:
```lua
local s=spinner.new{
 value=curr_size,
 min=min_size,
 max=max_size,
 on_change=set_size
}
```
Note that not all properties are available to change after construction.

Arbitrary data in these tables will be included in the widget, as well. This can be useful in callbacks, as the widget itself is passed as an argument. For example:
```lua
local function clicked(w)
 printh("button number "..w.my_data.." was clicked")
end

local b=button.new{
 label="click me",
 on_click=clicked,
 -- `my_data` is not used by the button at all;
 -- this is just for the `clicked` function
 my_data=42
}
```

#### Widget

These properties are common to all widgets.

`widget.x`
`widget.y`
`widget.w`
`widget.h`

The widget's size and position. Position is relative to parent.

`widget.visible`

If false, the widget and its children are not drawn and receive no input.

`widget.name`

Used to find the widget with `gui_root:find()` or `panel:find()`.

`widget:abs_x()`
`widget:abs_y()`

Get the absolute position of this widget on the screen.

#### GUI root

The ancestor of all other widgets. Create a GUI root at the start of the program and add widgets to it to activate them.

`gui_root.widget_under_mouse`

The widget at the pointer's position that will receive input if the button is clicked. `nil` if there is no widget at the pointer's position or if no widget at that position accepts input.

`gui_root.clicked_widget`

The widget that has been clicked. `nil` unless the mouse button was pressed over a widget that accepts input.

`gui_root.new([props])`

Create a new GUI root. There are no settings for this widget, but the constructor accepts an argument like any other.

`gui_root:update()`

Update all widgets in the tree.

`gui_root:mouse_blocked()`

Returns true if the mouse is over a visible widget, whether that widget accepts input or not. In other words, this indicates whether the GUI is covering whatever else is on the screen, "blocking" what would otherwise be under the pointer. Note that this only checks the root's immediate children; if a panel has a child that extends beyond it, that won't be detected.

`gui_root:has_keyboard_focus()`

Returns true if a text field is currently handling keyboard input.

`gui_root:set_keyboard_focus([tf])`

Set the given text field to handle keyboard focus or, if no argument is given, stop all text fields from handling keyboard input.

`gui_root:draw()`

Draw all visible widgets in the tree. Note that the widgets drawn may affect the draw state. Drawing a color picker will reset the palette to the default. Drawing an icon will reset palette transparency if it has a transparent color set. Drawing a text field or spinner will reset the clipping region.

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
 level_data[w.prop]=w.value
end
```

#### Panel

A simple panel to which other widgets can be added. It can be flat or have a beveled edge.

`panel.color`

The panel's color.

`panel.style`

The panel's border style. Accepted values are `panel.raised`, `panel.sunken`, and `panel.flat`.

`panel.new([props])`

Creates a new panel. Properties:
* `color`: The panel's color. Default: `6`
* `style`: The panel's border style. Default: `panel.raised`
* `draggable`: If true, the panel can moved by clicking and dragging. Default: `false`

`panel:add_child(w, x, y)`

Add widget `w` to this panel. `x` and `y` are relative to the panel. The panel will automatically expand downward and to the right if the widget would not fit, but negative `x` and `y` values won't be accounted for.

`panel:remove_child(w)`

Remove widget w from the panel.

`panel:find(name)`

Find a widget with the given name in this panel.

`panel:each([widget_type])`

An iterator used to loop over this widget and all its children. Works the same as `gui_root:each()`.

#### Label

A text label. Can be made clickable.

The text of a label can be fixed, or it can be provided by a function. If a function is used, it will be called every time the label is drawn. The label will be passed as an argument. See also the note about labels below.

`label.text`

The label's text or the function that returns its text.

`label.color`

The label's color.

`label.new([props])`
Create a new text label. Properties:
* `text`: The label's text. This can be a string, a number, or a function returning either. The label will be passed as an argument to the function. Default: `""`
* `color`: The text color. Default: `0`
* `on_click`: A function to be called when the label is clicked. The label will be passed as an argument to the function. Default: `nil`

#### Icon

An 8x8 icon, which may be clickable.

Like labels, an icon can have its data provided by a function called when the icon is drawn. The icon will be passed as an argument.

`icon.num`

The icon's sprite number or the function that provides it.

`icon.trans`

This color will be made transparent when the icon is drawn. If this is set to a number, that color will be made transparent, and the palette will be reset after drawing. If this is `nil` the palette will not be affected.

`icon.new([props])`
Create a new icon. Properties:
* `num`: The number of the icon or a function returning that number. The icon will be passed as an argument to the function. Default: `0`
* `on_click`: A function to be called when the icon is clicked. The icon will be passed as an argument to the function. Default: `nil`

#### Button

A clickable button that can be labeled with either text or an icon.

`button.color`

The button's background color.

`button.new([props])`

Create a new button. Properties:
* `label`: A string, a number, a function returning a string or number, or a widget. See the note about labels below. The button will be passed as an argument to the function. Default: `""`
* `color`: The button's background color. Default: `6`
* `on_click`: The function to call when the button is clicked. The button will be passed as an argument to the function. Default: `nil`

#### Spinner

A widget for number entry. This can also be used as a simple text list, but the values will still be numbers.

`spinner.value`

The spinner's current value.

`spinner.presenter`

If this is set, the spinner will use it when drawing to get a string to display instead of the numeric value. This should be either a function that takes a number as an argument and returns a string or a table with appropriate numeric indices and string values.

`spinner.new([props])`

Create a new spinner. Properties:
* `min`: The minimum value. Default: `0`
* `max`: The maximum value. Default: `16384`
* `step`: The amount to increase or decrease the value when a button is clicked. Default: `1`
* `value`: The initial value. Default: `min`
* `presenter`: A table or function to convert values to strings. Default: `nil`
* `on_change`: A function to be called when the value changes. The spinner will be passed as an argument to the function. Default: `nil`

#### Checkbox

`checkbox.value`
Either `true` or `false`, indicating whether the checkbox is currently clicked.

`checkbox.new([props])`
Create a new checkbox. Properties:
* `label`: A string, a number, a function returning a string or number, or a widget. See the note about labels below. The checkbox will be passed as an argument to the function. Default: `""`
* `value`: The initial value. Default: `false`
* `on_change`: A function to be called when the value changes. The checkbox will be passed as an argument to the function. Default: `nil`

#### Radio button group

Before creating any radio buttons, you must create a group for them to share.

Note that a radio button group is not a widget. It should not be added as a child of a panel or GUI root. It cannot be retrieved with `find()`; you can instead find an individual radio button and get its group using `radio.group`.

`rbgroup.selected`

The currently selected radio button, or `nil` if none is selected.

`rbgroup.new([props])`

Create a new radio button group. Properties:
* `on_change`: A function to be called when the selection changes. The selected radio button will be passed as an argument. Default: `nil`

`rbgroup:select(value)`

Select the radio button with the given value. If none has that value, no button will be selected.

#### Radio button

`radio.group`

The rbgroup this button belongs to.

`radio.selected`

Either `true` or `false`, indicating whether this radio button is selected.

`radio.value`

The value of this radio button. This can be any type of data.

`radio.new([props])`

Create a new radio button. Properties:
* `group`: The group this radio button should be added to. Default: `nil`
* `label`: A string, a number, a function returning a string or number, or a widget. See the note about labels below. The radio button will be passed as an argument to the function. Default: `""`
* `value`: The value associated with this radio button. Default: `nil`

#### Text field

A widget that allows text entry using the keyboard.

Note that glyph characters (Shift + A-Z) can be entered, but the cursor currently doesn't handle them properly. Also, because `stat(31)` doesn't report arrow keys, `btnp(0)` and `btnp(1)` are used to move the cursor. This will cause problems if directions are mapped to text keys such as WASD.

See also `gui_root:has_keyboard_focus()` and `gui_root:set_keyboard_focus()`.

`text_field.value`

The current text.

`text_field.new([props])`

Create a new text field. Properties:
* `value`: The initial text. Default: `""`
* `max_len`: The maximum text length allowed. Default: `32767`
* `on_change`: A function to be called when the value changes. The text field will be passed as an argument to the function. Default: `nil`

#### Color picker

`color_picker.value`

The currently selected color. May be nil.

`color_picker.new([props])`

Create a new color picker. Properties:
* `value`: The initial selection. Default: `nil`
* `on_change`: A function to be called when the value changes. The color picker will be passed as an argument to the function. Default: `nil`

## A note about labels

`button.new()`, `radio.new()`, and `checkbox.new()` can take a string, a number, a function, or another widget as the `label` property. A string will produce a text label and a number will produce an icon. If it's a function, the function will be called with no argument. If it returns a number, it's an icon; if it returns a string, it's text. If this is a text function, it will be called again by `label.new()`. The value returned by this call will determine the widget's width, and it will not be updated if the text changes.

Most of this also applies to the `text` property of `label.new()`, but that will be a text label even if the function returns a number.

## Miscellaneous tips

If you want to remove unused widgets to save tokens, any of these can be safely deleted without affecting anything else:
* Panel
* Button
* Spinner (`spinner` and `spinbtn` together)
* Checkbox
* Radio button (`radio` and `rbgroup` together)
* Text field
* Color picker

Each widget's code is all together and marked with a comment at the beginning.

You can set `gui_root.visible` to false to hide and disable the interface completely. Of course, you can also just not update or draw it.

You only really need one, but you could use multiple GUI roots for different program modes with totally different interfaces (e.g. one for a map editor and another for a sprite editor).

Checkboxed, radio buttons, spinners, and color pickers all use a field named `value` for their current value. This makes it easy to write a single callback that can handle all of them. Just add to the widget a field indicating which property it controls. For instance:
```lua
local sp=spinner.new{
 min=16,
 max=128,
 value=level_data.size,
 on_change=set_level_data,
 prop="size"
}
p:add_child(sp, 2, 2)

local grp=rbgroup.new{ on_change=set_level_data }
local rb1=radio.new{
 group=grp,
 label="Outdoor",
 prop="tileset",
 value=1
}
local rb2=radio.new{
 group=grp,
 label="Cave",
 prop="tileset",
 value=2
}
local rb3=radio.new{
 group=grp,
 label="Castle",
 prop="tileset",
 value=3
}
grp:select(level_data.tileset)
p:add_child(rb1, 2, 13)
p:add_child(rb2, 2, 20)
p:add_child(rb3, 2, 27)
```
Then the `set_level_data` function might simply be:
```lua
function set_level_data(w)
 level_data[w.prop]=w.value
end
```
This could include buttons and clickable labels and icons, as well. None of those has a `value` field normally, but there's no reason you can't add one.
