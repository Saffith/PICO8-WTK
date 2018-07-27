-- utils

function draw_convex_frame(x0, y0, x1, y1, c)
 rectfill(x0, y0, x1, y1, c)
 line(x0, y0, x0, y1-1, 7)
 line(x0, y0, x1-1, y0, 7)
 line(x0+1, y1, x1, y1, 5)
 line(x1, y0+1, x1, y1, 5)
end

function draw_concave_frame(x0, y0, x1, y1, c)
 rectfill(x0, y0, x1, y1, c)
 line(x0, y0, x0, y1-1, 5)
 line(x0, y0, x1-1, y0, 5)
 line(x0+1, y1, x1, y1, 7)
 line(x1, y0+1, x1, y1, 7)
end

function make_label(val)
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

function subwidget(t)
 t.__index=t
 setmetatable(t, { __index=widget })
end

function dummy()
end

-- base widget

widget={
 x=0, y=0,
 w=0, h=0,
 visible=true,
 name="",
 draw=dummy,
 update=dummy,
 on_mouse_enter=dummy,
 on_mouse_exit=dummy,
 on_mouse_press=dummy,
 on_mouse_release=dummy,
 on_mouse_move=dummy
}
widget.__index=widget

function widget.new()
 local w={ children={} }
 setmetatable(w, widget)
 return w
end

function widget:draw_all(px, py)
 if self.visible then
  self:draw(px, py)
  for c in all(self.children) do
   c:draw_all(px+c.x, py+c.y)
  end
 end
end

function widget:update_all()
 self:update()
 for c in all(self.children) do
  c:update_all()
 end
end

function widget:add_child(c, x, y)
 if (c.parent) c.parent:remove_child(c)
 c.x=x
 c.y=y
 c.parent=self
 add(self.children, c)
end

function widget:remove_child(c)
 del(self.children, c)
 c.parent=nil
end

function widget:find(n)
 if (self.name==n) return self
 for c in all(self.children) do
  local w=c:find(n)
  if (w) return w
 end
end

function widget:get_under_mouse(x, y)
 if (not self.visible) return nil
 
 x-=self.x
 y-=self.y
 if x>=0 and x<self.w and y>=0 and y<self.h then
  local ret=nil
  if (self.wants_mouse) ret=self
  for c in all(self.children) do
   local mc=c:get_under_mouse(x, y)
   if (mc) ret=mc
  end
  return ret
 end
end

function widget:abs_x()
 return self.parent:abs_x()+self.x
end

function widget:abs_y()
 return self.parent:abs_y()+self.y
end

-- gui root

gui_root={}
subwidget(gui_root)

function gui_root.new()
 local g=widget.new()
 setmetatable(g, gui_root)
 g.w=128
 g.h=128
 g.lastx=0
 g.lasty=0
 g.lastbt=0
 return g
end

function gui_root:update()
 local x=stat(32)
 local y=stat(33)
 local dx=x-self.lastx
 local dy=y-self.lasty
 local bt=band(stat(34), 1)==1
 
 local wum=self:get_under_mouse(x, y)
 if wum!=self.widget_under_mouse then
  if self.widget_under_mouse then
   self.widget_under_mouse:on_mouse_exit()
  end
  self.widget_under_mouse=wum
  if wum then
   wum:on_mouse_enter()
  end
 end
 
 if dx!=0 or dy!=0 then
  local w=self.clicked_widget or self.widget_under_mouse
  if (w) w:on_mouse_move(dx, dy)
 end
 
 if self.lastbt then
  if not bt and self.clicked_widget then
   self.clicked_widget:on_mouse_release()
   self.clicked_widget=nil
  end
 elseif bt then
  self.clicked_widget=self.widget_under_mouse
  if self.clicked_widget then
   self.clicked_widget:on_mouse_press()
  end
 end
 
 self.lastx=x
 self.lasty=y
 self.lastbt=bt
 
 for c in all(self.children) do
  c:update_all()
 end
end

function gui_root:draw()
 if self.visible then
  for c in all(self.children) do
   c:draw_all(c.x, c.y)
  end
 end
end

function gui_root:mouse_blocked()
 if self.visible then
  local x=stat(32)
  local y=stat(33)
  for c in all(self.children) do
   if c.visible and x>=c.x and x<c.x+c.w and y>=c.y and y<c.y+c.h then
    return true
   end
  end
 end
 return false
end

function gui_root:abs_x()
 return self.x
end

function gui_root:abs_y()
 return self.y
end

-- panel

panel={ wants_mouse=true }
subwidget(panel)

function panel.new(w, h, c, d, s)
 local p=widget.new()
 setmetatable(p, panel)
 p.w=w or 5
 p.h=h or 5
 p.c=c or 6
 p.style=s or 1
 if (d) p.draggable=true
 return p
end

function panel:add_child(c, x, y)
 local ex=2
 if (self.style==3) ex=1
 self.w=max(self.w, x+c.w+ex)
 self.h=max(self.h, y+c.h+ex)
 widget.add_child(self, c, x, y)
end

function panel:draw(x, y)
 if self.style==1 then
  draw_convex_frame(x, y, x+self.w-1, y+self.h-1, self.c)
 elseif self.style==2 then
  draw_concave_frame(x, y, x+self.w-1, y+self.h-1, self.c)
 else
  rectfill(x, y, x+self.w-1, y+self.h-1, self.c)
 end
end

function panel:on_mouse_press()
 if (self.draggable) self.drag=true
end

function panel:on_mouse_release()
 self.drag=false
end

function panel:on_mouse_move(dx, dy)
 if self.drag then
  self.x+=dx
  self.y+=dy
 end
end

-- label

label={}
subwidget(label)

function label.new(text, c, func)
 local l=widget.new()
 setmetatable(l, label)
 l.h=5
 l.c=c or 0
 if func then
  l.wants_mouse=true
  l.func=func
 end
 if type(text)=="function" then
  l.text=text
  l.w=max(#(""..text(self))*4-1, 0)
 else
  l.text=""..text
  l.w=max(#l.text*4-1, 0)
 end
 return l
end

function label:draw(x, y)
 if(type(self.text)=="string") then
  print(self.text, x, y, self.c)
 else
  print(""..self.text(self), x, y, self.c)
 end
end

function label:on_mouse_press()
 self.func(self)
end

-- icon

icon={}
subwidget(icon)

function icon.new(n, t, f)
 local i=widget.new()
 setmetatable(i, icon)
 i.num=n
 i.trans=t
 i.w=8
 i.h=8
 if f then
  i.wants_mouse=true
  i.func=f
 end
 return i
end

function icon:draw(x, y)
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
 if (self.trans) palt()
end

function icon:on_mouse_press()
 self.func(self)
end

-- button

button={ wants_mouse=true }
subwidget(button)

function button.new(lbl, func, c)
 local b=widget.new()
 setmetatable(b, button)
 local l=make_label(lbl)
 b:add_child(l, 2, 2)
 b.w=l.w+4
 b.h=l.h+4
 b.c=c or 6
 b.func=func
 return b
end

function button:draw(x, y)
 if self.clicked and self.under_mouse then
  draw_concave_frame(x, y, x+self.w-1, y+self.h-1, self.c)
 else
  draw_convex_frame(x, y, x+self.w-1, y+self.h-1, self.c)
 end
end

function button:on_mouse_enter()
 self.under_mouse=true
end

function button:on_mouse_exit()
 self.under_mouse=false
end

function button:on_mouse_press()
 self.clicked=true
end

function button:on_mouse_release()
 self.clicked=false
 if self.under_mouse then
  self.func(self)
 end
end

-- spinner

spinner={}
subwidget(spinner)

spinbtn={ wants_mouse=true }
subwidget(spinbtn)

function spinner.new(minv, maxv, v, step, f)
 local s=widget.new()
 setmetatable(s, spinner)
 s.w=53
 s.h=9
 s.minv=minv
 s.maxv=maxv
 s.step=step or 1
 s.value=v or minv
 s.func=f
 local b=spinbtn.new("+", s, 1)
 s:add_child(b, 39, 0)
 b=spinbtn.new("-", s, -1)
 s:add_child(b, 46, 0)
 return s
end

function spinner:draw(x, y)
 rectfill(x, y, x+self.w-1, y+self.h-1, 7)
 print(self.value, x+2, y+2, 0)
end

function spinner:adjust(amt)
 self.value=mid(
  self.value+amt*self.step,
  self.minv, self.maxv)
 if self.func then
  self.func(self)
 end
end

function spinbtn.new(t, p, s)
 local b=widget.new()
 setmetatable(b, spinbtn)
 b.w=7
 b.h=9
 b.text=t
 b.parent=p
 b.sign=s
 b.timer=0
 return b
end

function spinbtn:draw(x, y)
 if self.clicked and self.under_mouse then
  draw_concave_frame(x, y, x+self.w-1, y+self.h-1, 6)
 else
  draw_convex_frame(x, y, x+self.w-1, y+self.h-1, 6)
 end
 print(self.text, x+2, y+2, 1)
end

function spinbtn:update()
 if (self.timer<200) self.timer+=1
 if self.clicked and self.under_mouse then
  if self.timer>=200 then
   self.parent:adjust(self.sign*500)
  elseif self.timer>=100 then
   self.parent:adjust(self.sign*50)
  elseif self.timer>=10 then
   self.parent:adjust(self.sign)
  end
 end
end

function spinbtn:on_mouse_enter()
 self.under_mouse=true
end

function spinbtn:on_mouse_exit()
 self.under_mouse=false
end

function spinbtn:on_mouse_press()
 self.clicked=true
 self.timer=0
 
 local p=self.parent
 self.parent:adjust(self.sign)
end

function spinbtn:on_mouse_release()
 self.clicked=false
end

-- checkbox

checkbox={ wants_mouse=true }
subwidget(checkbox)

function checkbox.new(lbl, v, f)
 local c=widget.new()
 setmetatable(c, checkbox)
 local l=make_label(lbl)
 c:add_child(l, 6, 0)
 c.w=l.w+6
 c.h=7
 c.value=v or false
 c.func=f
 return c
end

function checkbox:draw(x, y)
 rectfill(x, y, x+4, y+4, 7)
 if self.value then
  line(x+1, y+1, x+3, y+3, 0)
  line(x+1, y+3, x+3, y+1, 0)
 end
end

function checkbox:on_mouse_press()
 self.value=not self.value
 if self.func then
  self.func(self)
 end
end

-- radio button

radio={ wants_mouse=true }
subwidget(radio)

rbgroup={}
rbgroup.__index=rbgroup

function rbgroup.new(f)
 local g=widget.new()
 setmetatable(g, rbgroup)
 g.func=f
 g.btns={}
 return g
end

function rbgroup:select(val)
 if self.selected then
  self.selected.selected=false
 end
 
 self.selected=nil
 for r in all(self.btns) do
  if r.value==val then
   self.selected=r
   r.selected=true
   break
  end
 end
 
 if self.func then
  self.func(self.selected)
 end
end

function radio.new(grp, lbl, val)
 local r=widget.new()
 setmetatable(r, radio)
 local l=make_label(lbl)
 r:add_child(l, 6, 0)
 r.w=6+l.w
 r.h=5
 r.value=val
 r.group=grp
 r.selected=false
 add(grp.btns, r)
 return r
end

function radio:on_mouse_press()
 self.group:select(self.value)
end

function radio:draw(x, y)
 circfill(x+2, y+2, 2, 7)
 if self.selected then
  circfill(x+2, y+2, 1, 0)
 end
end

-- color picker

color_picker={ wants_mouse=true }
subwidget(color_picker)

function color_picker.new(sel, func)
 local c=widget.new()
 setmetatable(c, color_picker)
 c.w=18
 c.h=18
 c.func=func
 c.value=sel
 return c
end

function color_picker:draw(x, y)
 pal()
 palt(0, false)
 
 rect(x, y, x+17, y+17, 0)
 x+=1
 y+=1
 
 for c=0, 15 do
  local cx=x+(c%4)*4
  local cy=y+band(c, 12)
  rectfill(cx, cy, cx+3, cy+3, c)
 end
 
 if self.value then
  local cx=x+(self.value%4)*4
  local cy=y+band(self.value, 12)
  rect(cx, cy, cx+3, cy+3, 0)
  rect(cx-1, cy-1, cx+4, cy+4, 7)
 end
end

function color_picker:on_mouse_press()
 -- it would probably make more
 -- sense to take the position
 -- as arguments, but this will
 -- do...
 local mx=stat(32)-self:abs_x()-1
 local my=stat(33)-self:abs_y()-1
 local cx=flr(mx/4)
 local cy=flr(my/4)
 if cx>=0 and cx<4 and cy>=0 and cy<4 then
  self.value=cy*4+cx
  if (self.func) self.func(self)
 end
end
