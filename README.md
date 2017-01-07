# PICO8-WTK
A simple widget toolkit for PICO-8. A demo cart can be found [here](http://www.lexaloffle.com/bbs/?tid=28467).

####Reference

######Widget
These properties are common to all widgets.
```lua
-- The widget's size and position. Position is relative to parent.
widget.x
widget.y
widget.w
widget.h

-- If false, the widget is not drawn and receives no input.
widget.visible

-- Used to find the widget with gui_root:find() or panel:find().
widget.name
```
######GUI root
The ancestor of all other widgets. Create a gui_root at the start of the  program and add widgets to it to activate them.
```lua
-- The widget at the pointer's position that will receive input if the button
-- is clicked. nil if there is no widget at the pointer's position or if
-- no widget at that position wants input.
gui_root.widget_under_mouse

-- The widget that has been clicked. nil if the mouse button is not pressed
-- or if it was not pressed over a widget that wanted input.
gui_root.clicked_widget

-- True if the mouse is over a visible widget, whether that widget wants input
-- or not. In other words, this indicates whether the GUI is blocking the mouse
-- from reaching whatever else is on the screen. Note that this only checks the
-- root's immediate children; if a panel has a child that extends beyond it,
-- that won't be detected.
gui_root:mouse_blocked()

-- Create a new GUI root.
gui_root.new()

-- Update all widgets in the tree.
gui_root:update()

-- Draw all visible widgets in the tree.
gui_root:draw()

-- Add widget w to the GUI at x, y.
gui_root:add_child(w, x, y)

-- Remove widget w from the GUI.
gui_root:remove_child(w)

-- Find a widget with the given name.
gui_root:find(name)
```
######Panel
A simple panel to which other widgets can be added.
```lua
-- The panel's color.
panel.c

-- The panel's style.
-- 1: Convex
-- 2: Concave
-- 3: Flat
panel.style

-- Creates a new panel. If draggable is true, the user can click and drag
-- the panel to move it. Styles are the same as above.
panel.new([width, height,] [color,] [draggble,] [style])

-- Add widget w to this panel. x and y are relative. The panel will expand
-- if the widget would not fit, but negative x and y values won't be
-- accounted for.
panel:add_child(w, x, y)

-- Remove widget w from the panel.
panel:remove_child(w)

-- Find a widget with the given name in this panel.
panel:find(name)
```
######Label
A text label. Can be made clickable.
The text of a label can be fixed, or it can be provided by a function. If a function is used, it will be called every time the label is drawn. The label will be passed as an argument. See also the note about labels below.
```lua
-- The label's text or the function that returns its text.
label.text

-- The label's color.
label.c

-- Create a new label. Text can be a string, a number, or a function.
-- func is a function to be called when the label is clicked. The label
-- will be passed as an argument.
label.new(text, [color,] [func])
```
######Icon
An 8x8 icon, which may be clickable.
Like labels, an icon can have its data provided by a function called when the icon is drawn. The icon will be passed as an argument.
```lua
-- The icon's sprite number or the function that provides it.
icon.num

-- This color will be made transparent when the icon is drawn. Transparency
-- will be reset to default afterward. If this is nil, transparency will not
-- be changed.
icon.trans

-- Create a new icon. num can be a number or a function. func is a function to
-- be called when the icon is clicked. The icon will be passed as an argument.
icon.new(num, [trans,] [func])
```
######Button
```lua
-- The button's color.
button.c

-- Create a new button. label is a string, a number, a function, or a widget.
-- See the note about labels below. func will be called when the button is
-- clicked, and the button will be passed as an argument.
button.new(label, func, [color])
```
######Spinner
```lua
-- The spinner's current value.
spinner.value

-- Create a new spinner. initval defaults to minval. step defaults to 1.
-- func is a function to be called when the value changes. The spinner
-- will be passed as an argument.
spinner.new(minval, maxval, [initval,] [step,] [func])
```
######Checkbox
```lua
-- Boolean value indicating whether the checkbox is currently clicked.
checkbox.value

-- Create a new checkbox. label is a string, a number, a function, or a widget.
-- See the note about labels below. func will be called when the checkbox is
-- toggled, and the checkbox will be passed as an argument.
checkbox.new(text, [value,] [func])
```
######Radio button group
Before creating any radio buttons, you must create a group for them to share.
Note that a radio button group is not a widget and cannot be retrieved with widget:find(). You can instead find an individual radio button and get its group using `radio.group`.
```lua
-- The currently selected radio button, if any is selected.
rbgroup.selected

-- Create a new radio button group. func will be called when the selection
-- changes. The selected radio button will be passed as an argument.
rbgroup.new([func])

-- Select the radio button with the given value. If none has that value,
-- no button will be selected.
-- Radio buttons are all deselected by default; use this function after
-- adding buttons to the group to set the initial selection.
rbgroup:select(value)
```
######Radio button
```lua
-- The rbgroup this button belongs to.
radio.group

-- Whether this radio button is selected.
radio.selected

-- The value of this radio button. This can be any type of data.
radio.value

-- Create a new radio button. label is a string, a number, a function, or a
-- widget. See the note about labels below.
function radio.new(group, label, value)
```
####A note about labels
`button.new()`, `radio.new()`, and `checkbox.new()` can take a string, a number, a function, or another widget as the label argument. A string will produce a text label and a number will produce an icon. If it's a function, the function will be called with no argument. If it returns a number, it's an icon; if it returns a string, it's text. If this is a text function, it will be called again by `label.new()`. The value returned by this call will determine the widget's width, and it will not be updated if the text changes.

Most of this also applies to `label.new()`, but that will be a text label even if the function returns a number.
####Miscellaneous tips
You can set gui_root.visible to false to hide the interface completely. Of course, you can also just not update or draw it.

You only really need one, but you could use multiple GUI roots for different program modes with totally different interfaces (e.g. one for a map editor and another for a sprite editor).

Note that the checkbox, radio button, and spinner all use a field named `value` for their current value. This makes it easy to write a callback that can handle all three. Just add to the widget a field indicating which property it controls. For instance:
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
