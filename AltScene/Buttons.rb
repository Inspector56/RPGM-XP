#TODO: different text color, size, font for hover/toggle 

$moused_over = []
$mouse_held = false

def viewport_swap(sprite, viewport)
  new_sprite = RPG::Sprite.new(viewport)
  new_sprite.bitmap = sprite.bitmap
  new_sprite.x, new_sprite.y = sprite.x, sprite.y
  new_sprite.ox, new_sprite.oy = sprite.ox, sprite.oy
  new_sprite.visible = sprite.visible
  new_sprite.zoom_x, new_sprite.zoom_y, new_sprite.angle = sprite.zoom_x, sprite.zoom_y, sprite.angle
  new_sprite.opacity, new_sprite.color, new_sprite.tone = sprite.opacity, sprite.color, sprite.tone
  if !sprite.disposed? then sprite.dispose end
  return new_sprite
end

#==============================================================================
# ** Button
#------------------------------------------------------------------------------
#  Any graphic item that responds to being clicked on by the cursor/mouse
# ----------------
# Configuration:
#   - name : ("btn") name/prefix for set of corresponding image files/assets used for the button
#   - x, y, z : x (0), y (0), and z coordinates for the button
#   - hover : (true) whether or not to display a different sprite when the mouse is hovered over the button
#   - shaped : (false) whether or not the button should be treated as a bounding rectangle, or shape sensitive to the sprite
#   - toggle : (false) whether or not the button is a toggle type, and has a toggle image; sensitive to hover
#              (if it is a toggle type AND hover type button, then it expects 4 assets)
#   - text : words/string, if any, to be displayed over the button graphic
#   - text_align : alignment of text displayed over button graphic; 0 for left, 1 for center, 2 for right
#   - scale : scale of the button image
#   - rotation : angle/rotation of the button image
#   - font : Font object for optional cover text
#   - directory : ("Graphics/UI/Buttons/") path where the assets will be looked for
# Attributes:
#   - x, y
#   - width, height
#   - visible, active
# Methods:
#   - in_bounds : returns true if the cursor is within the rectangle defining this box
#   - moveby(dx, dy) : move the button by <dx, dy>
#   - moveto(x, y) : move the button to (x, y)
#   - set_rect(width, height) : force the rectangle's dimensions
#   - set_shaped : tells the system to consider the button 'shaped'
#   - center : sets the (x, y) coordinates of the Button to be at the center
#   - topleft : sets the (x, y) coordinates of the Button to be at the topleft corner
#   - set_toggle(value) : makes the button a toggle-type button, with value being the initial state (default "on")
#   - set_callback(func, obj, *args) : func is the name of a function to execute when the button is clicked; obj is the executing object, *args are the args passed
#==============================================================================

class Button
  FONT = "Verdana"
  FSIZE = 16
  FCOLOR = Color.new(0,0,0)
  
  attr_accessor   :x
  attr_accessor   :y
  attr_accessor   :width
  attr_accessor   :height
  attr_accessor   :visible
  attr_accessor   :active
  attr_reader     :z
  attr_reader     :scale
  attr_reader     :rotation
  attr_reader     :mouse_over
  attr_reader     :opacity
  attr_reader     :disposed
  
  #put in on-click mouse code
  def initialize(specs, viewport)
    #name/prefix of image assets
    if specs.has_key?("name") then @name = specs['name'] else @name="btn" end
    #where to look for the assets
    if specs.has_key?("directory") then @direc = specs['directory'] else @direc="Graphics/UI/Buttons/" end
    #x, y, and z coords of grid component
    if specs.has_key?("x") then @x = specs['x'] else @x=0 end
    if specs.has_key?("y") then @y = specs['y'] else @y=0 end
    if specs.has_key?("z") then @z = specs['z'] else @z = viewport.z end
    @viewport = viewport
    @viewport.z = @z
    #whether to display another sprite when hovering over button
    if specs.has_key?("hover") then @hover_type = specs['hover'] else @hover_type=true end
    #whether to check for the shape of the button
    if specs.has_key?("shaped") then @shaped = specs['shaped'] else @shaped=false end
    #whether to display a toggled sprite when clicked/set
    if specs.has_key?("toggle") then @toggle_type = specs['toggle'] else @toggle_type=false end
    if @toggle_type then set_toggle end
    #image scale
    if specs.has_key?("scale") then @scale = specs['scale'] else @scale = [1.0, 1.0] end
    #image rotation
    if specs.has_key?("rotation") then @rotation = specs['rotation'] else @rotation = 0.0 end
    #font used for cover text
    if specs.has_key?("font")
      @font = specs['font']
    else 
      @font=Font.new(FONT, FSIZE)
      @font.bold, @font.italic, @font.color = false, false, FCOLOR
    end
    #text and text align
    if specs.has_key?("text") then @message_text = specs['text'] else @message_text = "" end
    if specs.has_key?("text_align")
      case specs['text_align']
      when "center"
        @align = 1
      when "left"
        @align = 0
      when "right"
        @align = 2
      end
    else
      #default left-aligned
      @align = 0
    end
    
    @sprite = RPG::Sprite.new(viewport)
    @sprite.x, @sprite.y = @x, @y
    @sprite.bitmap = RPG::Cache.load_bitmap(@direc,@name)
    if @hover_type
      @hover_sprite = RPG::Sprite.new(viewport)
      @hover_sprite.x, @hover_sprite.y = @x, @y
      @hover_sprite.bitmap = RPG::Cache.load_bitmap(@direc,@name+"1")
    end
    
    @width, @height = @sprite.bitmap.width, @sprite.bitmap.height
    @image_w, @image_h = @width, @height
    @text = RPG::Sprite.new(viewport)
    @text.x, @text.y = x, y
    @text.bitmap = Bitmap.new(@width,@height)
    refresh_text
    
    @mouse_over = false
    @active = true
    @visible = true
    @held = false #only used for dragables
    moveto(@x,@y) #@lastx, @lasty = @x, @y
    
    @disposed = false
    $scene.register(self)
  end
  
  def refresh_text
    @text.bitmap.clear
    @text.bitmap.font = @font
    @text.bitmap.draw_text(0,0,@width,@height,@message_text,@align)
  end
  
  def set_toggle(default_on=true)
    @toggle_type = true
    @toggle = default_on
    @toggled_sprite = RPG::Sprite.new(@viewport)
    @toggled_sprite.x, @toggled_sprite.y = @x, @y
    @toggled_sprite.bitmap = RPG::Cache.load_bitmap(@direc,@name+"_toggle")
    if @hover_type
      @toggled_hover = RPG::Sprite.new(@viewport)
      @toggled_hover.x, @toggled_hover.y = @x, @y
      @toggled_hover.bitmap = RPG::Cache.load_bitmap(@direc,@name+"_toggle1")
    end
  end
  
  def moveto(x, y)
    vx, vy = @viewport.rect.x, @viewport.rect.y
    x, y = Math::max(0, Math::min($SCREEN_WIDTH, x-vx)), Math::max(0, Math::min($SCREEN_HEIGHT, y-vy))
    @x, @y, @lastx, @lasty = x+vx, y+vy, x+vx, y+vy
    @sprite.x, @sprite.y = x, y
    @text.x, @text.y = x, y
    if @hover_type
      @hover_sprite.x, @hover_sprite.y = x, y
    end
    if @toggle_type
      @toggled_sprite.x, @toggled_sprite.y = x, y
      if @hover_type
        @toggled_hover.x, @toggled_hover.y = x, y
      end
    end
  end
  
  def moveby(delx, dely)
    moveto(@x+delx, @y+dely)
  end
  
  def change_viewport(new_view)
    @viewport = new_view
    @sprite = viewport_swap(@sprite, new_view)
    if @hover_type
      @hover_sprite = viewport_swap(@hover_sprite, new_view)
    end
    if @toggle_type
      @toggled_sprite = viewport_swap(@toggled_sprite, new_view)
      if @hover_type
        @toggled_hover = viewport_swap(@toggled_hover, new_view)
      end
    end
    @text = viewport_swap(@text, new_view)
    moveto(@x, @y)
  end
  
  def set_shaped
    @shaped = true
  end
  
  def in_bounds
    _x, _y = @x - self.ox, @y - self.oy
    return ($mouse.x >= _x && $mouse.x < (_x + @width)) && ($mouse.y >= _y && $mouse.y < (_y + @height))
  end
  
  def center
    @sprite.ox = @sprite.bitmap.width/2
    @sprite.oy = @sprite.bitmap.height/2
    if @hover_type
      @hover_sprite.ox = @hover_sprite.bitmap.width/2
      @hover_sprite.oy = @hover_sprite.bitmap.height/2
    end
    if @toggle_type
      @toggled_sprite.ox = @toggled_sprite.bitmap.width/2
      @toggled_sprite.oy = @toggled_sprite.bitmap.height/2
      if @hover_type
        @toggled_hover.ox = @toggled_hover.bitmap.width/2
        @toggled_hover.oy = @toggled_hover.bitmap.height/2
      end
    end
    @text.ox, @text.oy = @width/2, @height/2
    @centered = true
  end
  def topleft
    @sprite.ox, @sprite.oy = 0, 0
    if @hover_type
      @hover_sprite.ox, @hover_sprite.oy = 0, 0
    end
    if @toggle_type
      @toggled_sprite.ox, @toggled_sprite.oy = 0, 0
      if @hover_type
        @toggled_hover.ox, @toggled_hover.oy = 0, 0
      end
    end
    @text.ox, @text.oy = 0, 0
    @centered = false
  end
  def scale=(vals)
    if vals.is_a?(Array)
      zx, zy = vals[0], vals[1]
    else
      zx, zy = vals, vals
    end
    @sprite.zoom_x, @sprite.zoom_y = zx, zy
    if @hover_type
      @hover_sprite.zoom_x, @hover_sprite.zoom_y = zx, zy
    end
    if @toggle_type
      @toggled_sprite.zoom_x, @toggled_sprite.zoom_y = zx, zy
      if @hover_type
        @toggled_hover.zoom_x, @toggled_hover.zoom_y = zx, zy
      end
    end
    @scale = [zx, zy]
  end
  def rotation=(val)
    @sprite.angle = val
    if @hover_type
      @hover_sprite.angle = val
    end
    if @toggle_type
      @toggled_sprite.angle = val
      if @hover_type
        @toggled_hover.angle = val
      end
    end
    @rotation = val
  end
  
  def active_sprite
    if @toggled_hover && @toggled_hover.visible then sprite = @toggled_hover end
    if @toggled_sprite && @toggled_sprite.visible then sprite = @toggled_sprite end
    if @hover_sprite && @hover_sprite.visible then sprite = @hover_sprite end
    if sprite == nil then sprite = @sprite end
    return sprite
  end
  def ox
    return active_sprite.ox
  end
  def oy
    return active_sprite.oy
  end
  
  #force the height and width of the button
  #should this be affected by @scale? How so?
  def set_rect(width, height)
    @width, @height = width, height
    zoom_x, zoom_y = (@width.to_f/@image_w.to_f)*@scale[0], (@height.to_f/@image_h.to_f)*@scale[1]
    @sprite.zoom_x, @sprite.zoom_y = zoom_x, zoom_y
    if @hover_sprite then @hover_sprite.zoom_x, @hover_sprite.zoom_y = zoom_x, zoom_y end
    if @toggle_hover then @toggle_hover.zoom_x, @toggle_hover.zoom_y = zoom_x, zoom_y end
    if @toggle_sprite then @toggle_sprite.zoom_x, @toggle_sprite.zoom_y = zoom_x, zoom_y end
    @text.zoom_x, @text.zoom_y = zoom_x, zoom_y
  end
  
  def update
    #if someone moved it using the accessor x or y
    if @x != @lastx or @y != @lasty
      moveto(@x, @y)
    end
    if in_bounds
      sprite = active_sprite
      if !@shaped or (sprite.bitmap.get_pixel($mouse.x - (@x-sprite.ox), $mouse.y - (@y-sprite.oy)).alpha > 0)
        @mouse_over = true
        if !$moused_over.include?(self) then $moused_over.push(self) end
      else
        @mouse_over = false
        $moused_over.delete(self)
      end
    else
      @mouse_over = false
      $moused_over.delete(self)
    end
    #determine which of the potential four sprites is displayed/active
    if @toggle_type
      @toggled_sprite.visible = (@toggle && (!@hover_type or !@held) &&((!@mouse_over) or (!@hover_type)))
      if @hover_type then @toggled_hover.visible = (@toggle && ((@mouse_over && @hover_type) or @held)) end
      @sprite.visible = ((!@toggle) && (!@hover_type or !@held) &&((!@mouse_over) or (!@hover_type)))
      if @hover_type then @hover_sprite.visible = ((!@toggle) && ((@mouse_over && @hover_type) or @held)) end
    else
      @sprite.visible = (((!@mouse_over) or (!@hover_type)) && (@hover_type ? (!@held) : true))
      if @hover_type then @hover_sprite.visible = (@mouse_over or @held) end
    end
    active_sprite.visible &= @visible
    @text.visible = @visible
  end
  
  def toggle
    @toggle = !(@toggle)
  end
  def toggled?
    @toggle
  end
  
  #procname is a string, the name of the function to be invoked by obj
  #alternatively, procname is a Proc object
  def set_callback(procname, obj=self, *args)
    @proc = procname
    @owner = obj
    @args = args
  end
  
  def on_click
    if !@active then return end
    if @toggle_type
      toggle
    end
    if @proc
      if @proc.is_a?(Proc)
        @proc.call
      else
        @owner.send(@proc,*@args)
      end
    end
  end
    
  def opacity=(val)
    @sprite.opacity = val
    if @hover_type
      @hover_sprite.opacity = val
    end
    if @toggle_type
      @toggled_sprite.opacity = val
      if @hover_type
        @toggled_hover.opacity = val
      end
    end
    @text.opacity = val
  end
  
  def dispose
    @sprite.dispose
    if @hover_type
      @hover_sprite.dispose
    end
    if @toggle_type
      @toggled_sprite.dispose
      if @hover_type
        @toggled_hover.dispose
      end
    end
    @text.dispose
    
    @disposed = true
    $scene.unregister(self)
    $moused_over.delete(self)
  end
end

#==============================================================================
# ** Dragable
#------------------------------------------------------------------------------
#  A sprite that the user can drag around the screen or certain areas by clicking and holding
# ----------------
# Configuration:
#   - name : ("btn") name/prefix for set of corresponding image files/assets used for the button
#   - x, y, z : x (0), y (0), and z coordinates for the button
#   - hover : (true) whether or not to display a different sprite when the mouse is hovered over the button
#   - shaped : (false) whether or not the button should be treated as a bounding rectangle, or shape sensitive to the sprite
#   - toggle : (false) whether or not the button is a toggle type, and has a toggle image; sensitive to hover
#              (if it is a toggle type AND hover type button, then it expects 4 assets)
#   - text : words/string, if any, to be displayed over the button graphic
#   - text_align : alignment of text displayed over button graphic; 0 for left, 1 for center, 2 for right
#   - scale : scale of the button image
#   - rotation : angle/rotation of the button image
#   - font : Font object for optional cover text
#   - directory : ("Graphics/UI/Buttons/") path where the assets will be looked for
#   - magnet : (false) whether or not, onclick/pickup, the Dragable's center "magnets" to the cursor
#  initialize args:
#   - dropable : (false) is it possible for the cursor to "drop" a dragable it's holding if it moves too fast?
#   - is_topleft : (false) whether to start the coordinates as topleft or centered
# Attributes:
#   - x, y
#   - width, height
#   - visible, active
# Methods:
#   - in_bounds : returns true if the cursor is within the rectangle defining this box
#   - moveby(dx, dy) : move the button by <dx, dy>
#   - moveto(x, y) : move the button to (x, y)
#   - set_rect(width, height) : force the rectangle's dimensions
#   - set_shaped : tells the system to consider the button 'shaped'
#   - center : sets the (x, y) coordinates of the Button to be at the center
#   - topleft : sets the (x, y) coordinates of the Button to be at the topleft corner
#   - set_toggle(value) : makes the button a toggle-type button, with value being the initial state (default "on")
#   - set_callback(func, obj, *args) : func is the name of a function to execute when the button is clicked; obj is the executing object, *args are the args passed
#   - set_release_callback(func, obj, *args) : like set_callback, but callback is triggered when the Dragable is dropped/released
#==============================================================================

class Dragable < Button
  attr_reader   :held
  
  def initialize(specs, viewport, dropable=false, is_topleft=false)
    super(specs, viewport)
    if specs.has_key?('magnet') then @magnet_type = specs['magnet'] else @magnet_type = false end
    #can the cursor "drop" this "accidentally" if they move too fast?
    @dropable = dropable
    #draggables are generally treated by their center
    @centered = !(is_topleft)
    
    if @centered
      center
    end
    @x_lock, @y_lock = false, false
    @disp_x, @disp_y = 0, 0
  end
  
  def set_toggle(default_on=true)
    super
    if @centered
      @toggled_sprite.ox = @toggled_sprite.width/2
      @toggled_sprite.oy = @toggled_sprite.height/2
      if @hover_type
        @toggled_hover.ox = @toggled_hover.bitmap.width/2
        @toggled_hover.oy = @toggled_hover.bitmap.height/2
      end
    end
  end
  
  def set_bound_box(x, y, width, height)
    @bounds = [x, x+width, y, y+height]
  end
  def lock_x
    @x_lock = true
  end
  def lock_y
    @y_lock = true
  end
  def unlock_x
    @x_lock = false
  end
  def unlock_y
    @y_lock = false
  end
  
  def on_click
    super
    @held = true
    #magnets suck the dragable so that it is centered on the cursor;
    #otherwise, keep initial displacement (relative positioning of cursor and dragable) constant
    if !@magnet_type
      @disp_x, @disp_y = $mouse.x - @x, $mouse.y - @y
    end
  end
  
  def in_bounds
    if @bounds
      if ($mouse.x >= Math::max(@bounds[0],0) && $mouse.x < Math::min(@bounds[1], $SCREEN_WIDTH)) \
        && ($mouse.y >= Math::max(@bounds[2],0) && $mouse.y < Math::min(@bounds[3], $SCREEN_WIDTH))
      else
        return false
      end
    end
    return super
  end
  
  def update
    if @held
      if $mouse_held && (!@dropable or @mouse_over)
        @toggle = true
      else
        @toggle = false
        @held = false #dropped
        release_callback
      end
    end
    #release_callback may result in this dragable being disposed/deleted
    if @disposed then return end
    super
    if @held
      x, y = $mouse.x - @disp_x, $mouse.y - @disp_y
      if @bounds
        x = Math::min(Math::max(x, @bounds[0]),@bounds[1])
        y = Math::min(Math::max(y, @bounds[2]),@bounds[3])
      end
      if @x_lock then x = @x end
      if @y_lock then y = @y end
      @x, @y = x, y
      moveto(x, y)
    end
  end
  
  def dragging?
    return @held
  end
  
  #can give the name of a method and its calling object, or a Proc
  def set_release_callback(procname, obj=nil, *args)
    @r_proc = procname
    @r_owner = obj
    @r_args = args
  end

  def release_callback
    if !@active or !@r_proc then return end
    if @r_proc.is_a?(Proc)
      @r_proc.call
    else
      @r_owner.send(@r_proc,*@r_args)
    end
  end
  
end
