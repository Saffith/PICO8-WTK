-- wtk


-- utils

function _wtk_draw_frame(x0, y0, x1, y1, color, style)
 rectfill(x0, y0, x1, y1, color)
 local tl, br
 if style==1 then
  tl, br=7, 5
 elseif style==2 then
  tl, br=5, 7
 else
  return
 end
 line(x0, y1-1, x0, y0, tl)
 line(x1-1, y0)
 line(x0+1, y1, x1, y1, br)
 line(x1, y0+1)
end

-- used to draw button frames.
function _wtk_draw_clickable_frame(w, x, y)
 local style=1
 if w._clicked and w._under_mouse then
  style=2
 end
 _wtk_draw_frame(
  x, y,
  x+w.w-1, y+w.h-1,
  w.color, style
 )
end

-- returns val or val(arg)
-- depending on whether val
-- is a function.
function _wtk_eval(val, arg)
 return type(val)=="function" and
  val(arg) or
  val
end

-- evaluates val as a widget
-- label and returns a new
-- widget to display it.
-- if val itself is a widget,
-- val is returned.
function _wtk_make_label(val)
 local t=type(_wtk_eval(val))
 if t=="number" then
  return icon.new{ num=val }
 elseif t=="string" or t==nil then
  return label.new{ text=val }
 else
  return val
 end
end

function _wtk_subwidget(t)
 t.__index=t
 return setmetatable(t, widget)
end

function _wtk_dummy()
end

-- base widget

widget={
 x=0, y=0,
 w=0, h=0,
 visible=true,
 name="",
 _draw=_wtk_dummy,
 _update=_wtk_dummy,
 _on_mouse_enter=_wtk_dummy,
 _on_mouse_exit=_wtk_dummy,
 _on_mouse_press=_wtk_dummy,
 _on_mouse_release=_wtk_dummy,
 _on_mouse_move=_wtk_dummy,
 _on_click=_wtk_dummy,
 _on_change=_wtk_dummy
}
widget.__index=widget

-- create a widget with the
-- given metatable and
-- additional properties.
-- private is a list of keys
-- to prefix with '_'.
function _wtk_make_widget(mt, user_props, private)
 local w={ _children={} }
 setmetatable(w, mt)
 if user_props then
  for k, v in pairs(user_props) do
   -- we don't need the table
   -- again, so just use del()
   -- to check if it contains
   -- an item.
   if del(private, k) then
    w["_"..k]=v
   else
    w[k]=v
   end
  end
 end
 return w
end

-- draw this widget and all of
-- its children.
function widget:_draw_all(px, py)
 if self.visible then
  self:_draw(px, py)
  foreach(
   self._children,
   function(c)
    c:_draw_all(px+c.x, py+c.y)
   end
  )
 end
end

-- update this widget and all
-- of its children.
function widget:_update_all()
 if self.visible then
  self:_update()
  foreach(
   self._children,
   widget._update_all
  )
 end
end

function widget:add_child(c, x, y)
 if c._parent then
  c._parent:remove_child(c)
 end
 
 c.x=x
 c.y=y
 c._parent=self
 add(self._children, c)
end

function widget:remove_child(c)
 del(self._children, c)
 c._parent=nil
end

function widget:find(n)
 if self.name==n then
  return self
 end
 
 for c in all(self._children) do
  local w=c:find(n)
  if w then
   return w
  end
 end
end

-- find the deepest widget at
-- the mouse position that
-- accepts mouse input.
function widget:_get_under_mouse(x, y)
 if not self.visible or
  not self:_contains_point(x, y)
 then
  return nil
 end
 
 local ret=
  self._wants_mouse and self
 
 foreach(
  self._children,
  function(c)
   ret=c:_get_under_mouse(
    x-self.x,
    y-self.y
   ) or ret
  end
 )
 
 return ret
end

-- sets the widget's value and
-- calls its callback.
function widget:_set_value(val)
 self.value=val
 self:_on_change()
end

-- returns true if the x, y is
-- within this widget.
function widget:_contains_point(x, y)
 return x>=self.x and
  x<self.x+self.w and
  y>=self.y and
  y<self.y+self.h
end

function widget:abs_x()
 return self._parent:abs_x()+self.x
end

function widget:abs_y()
 return self._parent:abs_y()+self.y
end

function widget:each(widget_type)
 local widgets, pos={}, 0
 if not widget_type or
  getmetatable(self)==widget_type
 then
   add(widgets, self)
 end
 
 foreach(
  self._children,
  function(c)
   for w in c:each(widget_type) do
    add(widgets, w)
   end
  end
 )
 
 return function()
  pos+=1
  return widgets[pos]
 end
end

-- gui root

gui_root=_wtk_subwidget{
 w=128,
 h=128,
 _lastx=0,
 _lasty=0,
 _lastbt=0
}

function gui_root.new(props)
 return _wtk_make_widget(
  gui_root,
  props
 )
end

function gui_root:update()
 local x=stat(32)
 local y=stat(33)
 local dx=x-self._lastx
 local dy=y-self._lasty
 local bt=band(stat(34), 1)==1
 
 -- see if the mouse has moved
 -- to a new widget. call
 -- _on_mouse_exit() and
 -- _on_mouse_enter() as
 -- appropriate.
 local wum=self:_get_under_mouse(x, y)
 if wum~=self.widget_under_mouse then
  if self.widget_under_mouse then
   self.widget_under_mouse:_on_mouse_exit()
  end
  self.widget_under_mouse=wum
  if wum then
   wum:_on_mouse_enter()
  end
 end
 
 -- if something should be
 -- notified that the mouse
 -- has moved, do so.
 if dx~=0 or dy~=0 then
  local w=self.clicked_widget or
   self.widget_under_mouse
  if w then
   w:_on_mouse_move(dx, dy)
  end
 end
 
 -- if the mouse button was
 -- pressed, remember what was
 -- clicked. if the button was
 -- released, forget. call
 -- _on_mouse_press() or
 -- _on_mouse_release() as
 -- appropriate. also, remember
 -- if the clicked widget
 -- grabs the keyboard.
 if self._lastbt then
  if not bt and self.clicked_widget then
   self.clicked_widget:_on_mouse_release()
   self.clicked_widget=nil
  end
 elseif bt then
  self.clicked_widget=
   self.widget_under_mouse
  if self.clicked_widget then
   self.clicked_widget:
    _on_mouse_press(
     x-self.clicked_widget:abs_x(),
     y-self.clicked_widget:abs_y())
  end
  self:set_keyboard_focus(self.clicked_widget)
 end
 
 self._lastx=x
 self._lasty=y
 self._lastbt=bt
 
 foreach(
  self._children,
  widget._update_all
 )
end

function gui_root:draw()
 self:_draw_all(self.x, self.y)
end

-- only checks the last visible
-- modal child if there are any;
-- otherwise, does nothing
-- special.
function gui_root:_get_under_mouse(x, y)
 local mc
 foreach(
  self._children,
  function(c)
   if c._modal and c.visible then
    mc=c
   end
  end
 )
 if mc then
  return mc:_get_under_mouse(
   x-self.x,
   y-self.y
  )
 else
  return widget._get_under_mouse(
   self,
   x, y
  )
 end
end

function gui_root:mouse_blocked()
 -- only check immediate
 -- children.
 if self.visible then
  local x=stat(32)
  local y=stat(33)
  for c in all(self._children) do
   if c.visible and
    c:_contains_point(x, y)
   then
    return true
   end
  end
 end
 return false
end

function gui_root:has_keyboard_focus()
 return self._kbd_widget~=nil
end

function gui_root:set_keyboard_focus(w)
 if self._kbd_widget then
  self._kbd_widget._has_kbd=false
  self._kbd_widget=nil
 end
 
 if w and w._wants_kbd then
  -- clear any pending input
  -- first
  while stat(30) do
   stat(31)
  end
  self._kbd_widget=w
  w._has_kbd=true
 end
end

function gui_root:abs_x()
 return self.x
end

function gui_root:abs_y()
 return self.y
end

-- panel

panel=_wtk_subwidget{
 trans=0,
 raised=1,
 sunken=2,
 flat=3,
 
 w=5,
 h=5,
 color=6,
 style=1
}

function panel.new(props)
 local p=_wtk_make_widget(
  panel,
  props,
  { "draggable", "modal" }
 )
 p._wants_mouse=p._draggable
 return p
end

function panel:add_child(c, x, y)
 -- extend to add the child if
 -- necessary. extend a pixel
 -- farther if there's a frame.
 local ex=2
 if self.style==3 then
  ex=1
 end
 self.w=max(self.w, x+c.w+ex)
 self.h=max(self.h, y+c.h+ex)
 widget.add_child(self, c, x, y)
end

function panel:_draw(x, y)
 if self.style>0 then
  _wtk_draw_frame(
   x, y,
   x+self.w-1, y+self.h-1,
   self.color, self.style
  )
 end
end

function panel:_on_mouse_press()
 self._drag=true
end

function panel:_on_mouse_release()
 self._drag=false
end

function panel:_on_mouse_move(dx, dy)
 if self._drag then
  self.x+=dx
  self.y+=dy
 end
end

-- label

label=_wtk_subwidget{
 text="",
 h=5,
 color=0
}

function label.new(props)
 local l=_wtk_make_widget(
  label,
  props,
  { "on_click" }
 )
 if l._on_click~=_wtk_dummy then
  l._wants_mouse=true
 end
 if type(l.text)=="function" then
  l.w=max(#(""..l.text(self))*4-1, 0)
 else
  l.text=tostr(l.text)
  l.w=max(#l.text*4-1, 0)
 end
 return l
end

function label:_draw(x, y)
 print(
  tostr(
   _wtk_eval(self.text, self)
  ),
  x, y,
  self.color
 )
end

function label:_on_mouse_press()
 self:_on_click()
end

-- icon

icon=_wtk_subwidget{
 num=0,
 w=8,
 h=8
}

function icon.new(props)
 local i=_wtk_make_widget(
  icon,
  props,
  { "on_click" }
 )
 if i._on_click~=_wtk_dummy then
  i._wants_mouse=true
 end
 return i
end

function icon:_draw(x, y)
 if self.trans then
  palt()
  palt(0, false)
  palt(self.trans, true)
 end
 spr(
  _wtk_eval(self.num, self),
  x, y
 )
 if self.trans then
  palt()
 end
end

function icon:_on_mouse_press()
 self:_on_click()
end

-- button

button=_wtk_subwidget{
 _wants_mouse=true,
 color=6
}

function button.new(props)
 local l=_wtk_make_label(props.label)
 local b=_wtk_make_widget(
  button,
  props,
  { "on_click" }
 )
 b.w=l.w+4
 b.h=l.h+4
 b:add_child(l, 2, 2)
 return b
end

function button:_draw(x, y)
 _wtk_draw_clickable_frame(self, x, y)
end

function button:_on_mouse_enter()
 self._under_mouse=true
end

function button:_on_mouse_exit()
 self._under_mouse=false
end

function button:_on_mouse_press()
 self._clicked=true
end

function button:_on_mouse_release()
 self._clicked=false
 if self._under_mouse then
  self:_on_click()
 end
end

-- text field

text_field=_wtk_subwidget{
 _wants_mouse=true,
 _wants_kbd=true,
 w=55,
 h=9,
 value="",
 _max_len=32767,
 _x_offset=0,
 _cursor_pos=0,
 _blink_timer=0
}

function text_field.new(props)
 return _wtk_make_widget(
  text_field,
  props,
  { "max_len", "on_change" }
 )
end

function text_field:_update()
 if not self._has_kbd then
  return
 end
 
 -- update cursor blinking
 self._blink_timer+=1
 if self._blink_timer==30 then
  self._blink_timer=0
 end
 
 -- move cursor
 local cp=self._cursor_pos
 
 -- this is a problem if
 -- directions are mapped to
 -- wasd or something, but
 -- stat(31) doesn't report
 -- arrow keys...
 if btnp(0) then
  cp-=1
 end
 if btnp(1) then
  cp+=1
 end
 cp=mid(cp, 0, #self.value)
 
 -- handle keypresses
 
 while stat(30) do
  local c, first, second=
   stat(31),
   sub(self.value, 1, cp),
   sub(self.value, cp+1)
  
  if c=="\b" then
   if #first>0 then
    self:_set_value(
     sub(first, 1, #first-1)..
     second
    )
    cp-=1
   end
  elseif #self.value<self._max_len then
   self:_set_value(first..c..second)
   cp+=1
  end
 end
 
 -- move text display offset
 -- if needed
 local vislen=flr(self.w/4)-1
 if self._x_offset>cp-1 then
  self._x_offset=max(cp-1, 0)
 elseif cp>self._x_offset+vislen then
   self._x_offset=cp-vislen
 end
 
 self._cursor_pos=cp
end

function text_field:_draw(x, y)
 -- box and text
 rectfill(
  x, y,
  x+self.w-1, y+self.h-1,
  7
 )
 clip(
  x+2, y+2,
  self.w-4, self.h-4
 )
 print(
  self.value,
  x+2-self._x_offset*4, y+2,
  0
 )
 clip()
 
 -- cursor
 if self._has_kbd and
  self._blink_timer<15 then
   local cx=
    x+1+4*(
     self._cursor_pos-
     self._x_offset
    )
   line(cx, y+1, cx, y+self.h-2)
 end
end

function text_field:_on_mouse_press(x)
 -- no need to limit it;
 -- _update() will fix it.
 self._cursor_pos=
  flr(x/4)+self._x_offset
end

-- spinner

spinner=_wtk_subwidget{
 w=53,
 h=9,
 _min=0,
 _max=16384,
 _step=1
}

spinbtn=_wtk_subwidget{
 _wants_mouse=true,
 w=7,
 h=9,
 color=6,
 _timer=0
}

function spinner.new(props)
 local s=_wtk_make_widget(
  spinner,
  props,
  {
   "min",
   "max",
   "step",
   "on_change"
  }
 )
 s.value=s.value or s._min
 
 s:add_child(
  spinbtn.new("+", s, 1),
  46, 0
 )
 s:add_child(
  spinbtn.new("-", s, -1),
  0, 0
 )
 return s
end

function spinner:_draw(x, y)
 local p=self.presenter
 local v
 if type(p)=="table" then
  v=p[self.value]
 elseif type(p)=="function" then
  v=p(self.value)
 end
 
 rectfill(
  x, y,
  x+self.w-1, y+self.h-1,
  7
 )
 x+=8
 clip(x, y, self.w-16, self.h)
 print(
  v or self.value,
  x, y+2,
  0
 )
 clip()
end

-- adjust the value. amt is
-- multiplied by step, so
-- a single button click should
-- be +1 or -1.
function spinner:_adjust(amt)
 -- this doesn't do anything
 -- to avoid overflow...
 self:_set_value(mid(
  self.value+amt*self._step,
  self._min, self._max
 ))
end

function spinbtn.new(t, p, s)
 return _wtk_make_widget(
  spinbtn,
  {
   _text=t,
   _parent=p,
   _sign=s,
  }
 )
end

function spinbtn:_draw(x, y)
 _wtk_draw_clickable_frame(
  self, x, y
 )
 print(self._text, x+2, y+2, 1)
end

function spinbtn:_update()
 -- adjust the number if the
 -- button is down. if it's
 -- been held down for a while,
 -- adjust it more.
 if self._timer<200 then
  self._timer+=1
 end
 if self._clicked and self._under_mouse then
  if self._timer>=200 then
   self._parent:_adjust(
    self._sign*500
   )
  elseif self._timer>=100 then
   self._parent:_adjust(
    self._sign*50
   )
  elseif self._timer>=10 then
   self._parent:_adjust(
    self._sign
   )
  end
 end
end

function spinbtn:_on_mouse_enter()
 self._under_mouse=true
end

function spinbtn:_on_mouse_exit()
 self._under_mouse=false
end

function spinbtn:_on_mouse_press()
 self._clicked=true
 self._timer=0
 self._parent:_adjust(self._sign)
end

function spinbtn:_on_mouse_release()
 self._clicked=false
end

-- checkbox

checkbox=_wtk_subwidget{
 _wants_mouse=true,
 h=7,
 value=false
}

function checkbox.new(props)
 local l=_wtk_make_label(props.label)
 local c=_wtk_make_widget(
  checkbox,
  props,
  { "on_change" }
 )
 c.w=l.w+6
 c:add_child(l, 6, 0)
 return c
end

function checkbox:_draw(x, y)
 rectfill(x, y, x+4, y+4, 7)
 if self.value then
  line(x+1, y+1, x+3, y+3, 0)
  line(x+1, y+3, x+3, y+1)
 end
end

function checkbox:_on_mouse_press()
 self:_set_value(not self.value)
end

-- radio button

radio=_wtk_subwidget{
 _wants_mouse=true,
 h=5,
 value=false,
 selected=false
}

rbgroup={
 on_change=_wtk_dummy
}
rbgroup.__index=rbgroup

function rbgroup.new(props)
 local g={
  _btns={}
 }
 setmetatable(g, rbgroup)
 for k, v in pairs(props) do
  g[k]=v
 end
 return g
end

function rbgroup:select(val)
 -- unselect all buttons.
 if self.selected then
  -- maybe not the best choice
  -- of names. oh, well.
  self.selected.selected=false
 end
 self.selected=nil
 
 -- then try to find one
 -- with the right value
 -- and select it.
 for r in all(self._btns) do
  if r.value==val then
   self.selected=r
   r.selected=true
   break
  end
 end
 
 self.on_change(self.selected)
end

function radio.new(props)
 local l=_wtk_make_label(props.label)
 local r=_wtk_make_widget(
  radio,
  props
 )
 r.w=6+l.w
 r:add_child(l, 6, 0)
 if r.group then
  add(r.group._btns, r)
 end
 return r
end

function radio:_on_mouse_press()
 self.group:select(self.value)
end

function radio:_draw(x, y)
 circfill(x+2, y+2, 2, 7)
 if self.selected then
  circfill(x+2, y+2, 1, 0)
 end
end

-- color picker

color_picker=_wtk_subwidget{
 _wants_mouse=true,
 w=18,
 h=18
}

function color_picker.new(props)
 return _wtk_make_widget(
  color_picker,
  props,
  { "on_change" }
 )
end

function color_picker:_draw(x, y)
 pal()
 palt(0, false)
 
 -- draw the outline first.
 rect(x, y, x+17, y+17, 0)
 x+=1
 y+=1
 
 -- then the color grid.
 for c=0, 15 do
  local cx=x+(c%4)*4
  local cy=y+band(c, 12)
  rectfill(cx, cy, cx+3, cy+3, c)
 end
 
 -- then the selection
 -- indicator.
 local cx=x+(self.value%4)*4
 local cy=y+band(self.value, 12)
 rect(cx, cy, cx+3, cy+3, 0)
 rect(cx-1, cy-1, cx+4, cy+4, 7)
end

function color_picker:_on_mouse_press(x, y)
 -- find the color under the 
 -- the pointer.
 local cx=flr((x-1)/4)
 local cy=flr((y-1)/4)
 if cx>=0 and cx<4 and
  cy>=0 and cy<4
 then
  self:_set_value(cy*4+cx)
 end
end
