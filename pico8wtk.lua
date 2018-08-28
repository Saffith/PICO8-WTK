-- wtk


-- utils

function _wtk_draw_convex_frame(x0, y0, x1, y1, c)
 rectfill(x0, y0, x1, y1, c)
 line(x0, y0, x0, y1-1, 7)
 line(x0, y0, x1-1, y0, 7)
 line(x0+1, y1, x1, y1, 5)
 line(x1, y0+1, x1, y1, 5)
end

function _wtk_draw_concave_frame(x0, y0, x1, y1, c)
 rectfill(x0, y0, x1, y1, c)
 line(x0, y0, x0, y1-1, 5)
 line(x0, y0, x1-1, y0, 5)
 line(x0+1, y1, x1, y1, 7)
 line(x1, y0+1, x1, y1, 7)
end

-- evaluates val as a widget
-- label and returns a new
-- widget to display it.
-- if val itself is a widget,
-- val is returned.
function _wtk_make_label(val)
 local t=type(val)
 if t=="number" then
  return icon.new(val)
 elseif t=="string" then
  return label.new(val)
 elseif t=="function" then
  local ret=val()
  if type(ret)=="number" then
   return icon.new(val)
  else
   return label.new(val)
  end
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
 _on_mouse_move=_wtk_dummy
}
widget.__index=widget

-- create a widget with the
-- given metatable. more_props
-- is a table of additional
-- properties to add or set.
function _wtk_make_widget(mt, more_props)
 local w={ _children={} }
 setmetatable(w, mt)
 if more_props then
  for k, v in pairs(more_props) do
   w[k]=v
  end
 end
 return w
end

-- draw this widget and all of
-- its children.
function widget:_draw_all(px, py)
 if self.visible then
  self:_draw(px, py)
  for c in all(self._children) do
   c:_draw_all(px+c.x, py+c.y)
  end
 end
end

-- update this widget and all
-- of its children.
function widget:_update_all()
 if self.visible then
  self:_update()
  for c in all(self._children) do
   c:_update_all()
  end
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
 if not self.visible then
  return nil
 end
 
 x-=self.x
 y-=self.y
 if x>=0 and x<self.w and y>=0 and y<self.h then
  local ret=nil
  if self._wants_mouse then
   ret=self
  end
  
  for c in all(self._children) do
   local mc=c:_get_under_mouse(x, y)
   if mc then
    ret=mc
   end
  end
  return ret
 end
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
  getmetatable(self)==widget_type then
   add(widgets, self)
 end
 
 for c in all(self._children) do
  for w in c:each(widget_type) do
   add(widgets, w)
  end
 end
 
 return function()
  pos+=1
  return widgets[pos]
 end
end

-- gui root

gui_root=_wtk_subwidget{}

function gui_root.new()
 return _wtk_make_widget(
  gui_root,
  {
   w=128,
   h=128,
   _lastx=0,
   _lasty=0,
   _lastbt=0
  })
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
 -- released, forget. also call
 -- _on_mouse_press() or
 -- _on_mouse_release() as
 -- appropriate. also remember
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
 
 for c in all(self._children) do
  c:_update_all()
 end
end

function gui_root:draw()
 if self.visible then
  for c in all(self._children) do
   c:_draw_all(c.x, c.y)
  end
 end
end

function gui_root:mouse_blocked()
 -- only check immediate
 -- children.
 if self.visible then
  local x=stat(32)
  local y=stat(33)
  for c in all(self._children) do
   if c.visible and x>=c.x and x<c.x+c.w and y>=c.y and y<c.y+c.h then
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
 _wants_mouse=true
}

function panel.new(w, h, c, d, s)
 return _wtk_make_widget(
  panel,
  {
   w=w or 5,
   h=h or 5,
   c=c or 6,
   style=s or 1,
   _draggable=d
  })
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
 if self.style==1 then
  _wtk_draw_convex_frame(x, y, x+self.w-1, y+self.h-1, self.c)
 elseif self.style==2 then
  _wtk_draw_concave_frame(x, y, x+self.w-1, y+self.h-1, self.c)
 else
  rectfill(x, y, x+self.w-1, y+self.h-1, self.c)
 end
end

function panel:_on_mouse_press()
 if self._draggable then
  self._drag=true
 end
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

label=_wtk_subwidget{}

function label.new(text, c, func)
 local l=_wtk_make_widget(
  label,
  {
   h=5,
   c=c or 0
  })
 if func then
  l._wants_mouse=true
  l._func=func
 end
 if type(text)=="function" then
  l.text=text
  l.w=max(#(""..text(self))*4-1, 0)
 else
  l.text=tostr(text)
  l.w=max(#l.text*4-1, 0)
 end
 return l
end

function label:_draw(x, y)
 if type(self.text)=="function" then
  print(tostr(self.text(self)),
   x, y, self.c)
 else
  print(tostr(self.text),
   x, y, self.c)
 end
end

function label:_on_mouse_press()
 self:_func()
end

-- icon

icon=_wtk_subwidget{}

function icon.new(n, t, f)
 local i=_wtk_make_widget(
  icon,
  {
   num=n,
   trans=t,
   w=8,
   h=8
  })
 if f then
  i._wants_mouse=true
  i._func=f
 end
 return i
end

function icon:_draw(x, y)
 if self.trans then
  palt()
  palt(0, false)
  palt(self.trans, true)
 end
 if type(self.num)=="number" then
  spr(self.num, x, y)
 else
  spr(self.num(self), x, y)
 end
 if self.trans then
  palt()
 end
end

function icon:_on_mouse_press()
 self:_func()
end

-- button

button=_wtk_subwidget{
 _wants_mouse=true
}

function button.new(lbl, func, c)
 local l=_wtk_make_label(lbl)
 local b=_wtk_make_widget(
  button,
  {
   w=l.w+4,
   h=l.h+4,
   c=c or 6,
   _func=func
  })
  b:add_child(l, 2, 2)
 return b
end

function button:_draw(x, y)
 if self._clicked and self._under_mouse then
  _wtk_draw_concave_frame(
   x, y,
   x+self.w-1, y+self.h-1,
   self.c)
 else
  _wtk_draw_convex_frame(
   x, y,
   x+self.w-1, y+self.h-1,
   self.c)
 end
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
  self:_func()
 end
end

-- text field

text_field=_wtk_subwidget{
 _wants_mouse=true,
 _wants_kbd=true
}

function text_field.new(text, f, maxlen)
 return _wtk_make_widget(
  text_field,
  {
   w=55,
   h=9,
   value=tostr(text),
   _maxlen=maxlen or 32767,
   _func=f or _wtk_dummy,
   _x_offset=0,
   _cursor_pos=0,
   _blink_timer=0
  })
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
    self.value=
     sub(first, 1, #first-1)..
     second
    cp-=1
    self:_func()
   end
  elseif #self.value<self._maxlen then
   self.value=first..c..second
   cp+=1
   self:_func()
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
  7)
 clip(
  x+2, y+2,
  self.w-4, self.h-4)
 print(
  self.value,
  x+2-self._x_offset*4, y+2,
  0)
 clip()
 
 -- cursor
 if self._has_kbd and
  self._blink_timer<15 then
   local cx=
    x+1+
    (self._cursor_pos-
     self._x_offset)*4
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

spinner=_wtk_subwidget{}

spinbtn=_wtk_subwidget{
 _wants_mouse=true
}

function spinner.new(minv, maxv, v, step, f, p)
 local s=_wtk_make_widget(
  spinner,
  {
   w=53,
   h=9,
   _minv=minv,
   _maxv=maxv,
   _step=step or 1,
   value=v or minv,
   _func=f,
   presenter=p
  })
 local b=spinbtn.new("+", s, 1)
 s:add_child(b, 46, 0)
 b=spinbtn.new("-", s, -1)
 s:add_child(b, 0, 0)
 return s
end

function spinner:_draw(x, y)
 rectfill(x, y, x+self.w-1, y+self.h-1, 7)
 local p=self.presenter
 local v
 if type(p)=="table" then
  v=p[self.value]
 elseif type(p)=="function" then
  v=p(self.value)
 end
 x+=8
 clip(x, y, self.w-16, self.h)
 print(v or self.value, x, y+2, 0)
 clip()
end

-- adjust the value. amt is
-- multiplied by step, so
-- a single button click should
-- be +1 or -1.
function spinner:_adjust(amt)
 self.value=mid(
  self.value+amt*self._step,
  self._minv, self._maxv)
 if self._func then
  self:_func()
 end
end

function spinbtn.new(t, p, s)
 return _wtk_make_widget(
  spinbtn,
  {
   w=7,
   h=9,
   _text=t,
   _parent=p,
   _sign=s,
   _timer=0
  })
end

function spinbtn:_draw(x, y)
 if self._clicked and self._under_mouse then
  _wtk_draw_concave_frame(x, y, x+self.w-1, y+self.h-1, 6)
 else
  _wtk_draw_convex_frame(x, y, x+self.w-1, y+self.h-1, 6)
 end
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
   self._parent:_adjust(self._sign*500)
  elseif self._timer>=100 then
   self._parent:_adjust(self._sign*50)
  elseif self._timer>=10 then
   self._parent:_adjust(self._sign)
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
 _wants_mouse=true
}

function checkbox.new(lbl, v, f)
 local l=_wtk_make_label(lbl)
 local c=_wtk_make_widget(
  checkbox,
  {
   w=l.w+6,
   h=7,
   value=v or false,
   _func=f
  })
 c:add_child(l, 6, 0)
 return c
end

function checkbox:_draw(x, y)
 rectfill(x, y, x+4, y+4, 7)
 if self.value then
  line(x+1, y+1, x+3, y+3, 0)
  line(x+1, y+3, x+3, y+1, 0)
 end
end

function checkbox:_on_mouse_press()
 self.value=not self.value
 if self._func then
  self:_func()
 end
end

-- radio button

radio=_wtk_subwidget{
 _wants_mouse=true
}

rbgroup={}
rbgroup.__index=rbgroup

function rbgroup.new(f)
 local g={
  _func=f,
  _btns={}
 }
 setmetatable(g, rbgroup)
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
 
 if self._func then
  self._func(self.selected)
 end
end

function radio.new(grp, lbl, val)
 local l=_wtk_make_label(lbl)
 local r=_wtk_make_widget(
  radio,
  {
   w=6+l.w,
   h=5,
   value=val,
   group=grp,
   selected=false
  })
 r:add_child(l, 6, 0)
 add(grp._btns, r)
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
 _wants_mouse=true
}

function color_picker.new(sel, func)
 return _wtk_make_widget(
  color_picker,
  {
   w=18,
   h=18,
   _func=func,
   value=sel
  })
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
 if self.value then
  local cx=x+(self.value%4)*4
  local cy=y+band(self.value, 12)
  rect(cx, cy, cx+3, cy+3, 0)
  rect(cx-1, cy-1, cx+4, cy+4, 7)
 end
end

function color_picker:_on_mouse_press(x, y)
 -- find the color under the 
 -- the pointer.
 local cx=flr((x-1)/4)
 local cy=flr((y-1)/4)
 if cx>=0 and cx<4 and cy>=0 and cy<4 then
  self.value=cy*4+cx
  if self._func then
   self:_func()
  end
 end
end
