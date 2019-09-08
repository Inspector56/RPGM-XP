#BIG TODO: so moveto checks boundaries and prevents moving offscreen
#moveby uses moveto, so it does as well
#things that use other components, like this button list, use moveby in their
#moveto, SO, if moving a cluster WOULD put an internal component offscreen, it will
#instead just be smushed into the cluster, messing up the relative positioning within the cluster

#TODO: not all features adequately tested

class ButtonCollection
  attr_reader   :buttons
  
  def initialize
    @buttons = []
  end
  
end

#==============================================================================
# ** ButtonList
#------------------------------------------------------------------------------
#  A vertical collection of buttons, navigable via mouse or keyboard input
# ----------------
# Configuration:
#   - name : ("btn") name/prefix for set of corresponding image files/assets used for the button
#   - x, y, z : x (0), y (0), and z coordinates for the button
#   - background : name of image file to be displayed, or a Color object to fill a rectangle, or Boolean false
#       for no background.
#   - margins : (5) only useful for rectangular/colored background, margin around buttons
#   - space : (0) vertical space/gap between buttons
#   - highlight_above : (false) should the highlight sprite be displayed in front of (or behind) the buttons
#   - scroll : (false) is the list scrollable, or are all items/buttons always displayed?
#   - max_i : only used in scrollable lists; maximum number of items/buttons displayed on the list at a time
#   - keys_locked : (false) whether not the list responds to keyboard input
# Attributes:
#   - x, y
#   - width, height
#   - visible, active
# Methods:
#==============================================================================

class ButtonList < ButtonCollection
  attr_accessor   :x
  attr_accessor   :y
  attr_accessor   :active
  attr_accessor   :visible
  attr_reader     :width
  attr_reader     :height
  attr_reader     :z
  attr_reader     :disposed
  
  def initialize(specs, buttons=nil)
    #parse specifications
    
    #name of image assets used to make the grid
    if specs.has_key?("name") then @name = specs['name'] else @name="blist" end
    #x, y, and z coords of grid component
    if specs.has_key?("x") then @x = specs['x'] else @x=0 end
    if specs.has_key?("y") then @y = specs['y'] else @y=0 end
    if specs.has_key?("z") then z = specs['z'] else z=250 end
    #can be a Color, asset name, or Boolean false for no background, else it will try to load @name+"_back.png"
    if specs.has_key?("background") then @back = specs['background'] else @back = Color.new(40,40,40) end
    #margins outside the border of the buttons
    if specs.has_key?("margins") then @m_ = specs['margins'] else @m_=5 end
    #margins/space between buttons in the list
    if specs.has_key?("space") then @space = specs['space'] else @space=0 end
    #should the highlight sprite be above or behind the buttons? Behind, by default
    if specs.has_key?("highlight_above")
      @viewport2 = Viewport.new(0,0,$SCREEN_HEIGHT,$SCREEN_WIDTH)
      @viewport2.z = z+1
    end
    #are the arrow keys usable?
    if specs.has_key?("keys_locked") then @key_lock = specs['keys_locked'] else @key_lock = false end
    #is the list a scrolling list? if so, max_i is max buttons displayed at a time
    if specs.has_key?("scroll") then @scroll = specs['scroll'] else @scroll=false end
    if specs.has_key?("max_i") then @m_i = specs['max_i'] else @m_i = 1 end
    @last_x, @last_y = @x, @y
    
    @viewport = Viewport.new(0,0,$SCREEN_HEIGHT,$SCREEN_WIDTH)
    @viewport.z = @z = z
    @buttons = buttons ? buttons : []
    
    if @scroll
      @scroll_index = 0
      @up_arrow = Button.new( {
        'shaped'=>true,'name'=>@name+"_up",
        'hover'=>false
      }, @viewport)
      @down_arrow = Button.new( {
        'shaped'=>true,'name'=>@name+"_down",
        'hover'=>false
      }, @viewport)
      @up_arrow.center
      @down_arrow.center
      @up_arrow.set_callback("try_up", self)
      @down_arrow.set_callback("try_down", self)
    end
    
    dimensions
    
    @background = RPG::Sprite.new(@viewport)
    draw_back
    
    @highlight = RPG::Sprite.new((@viewport2 ? @viewport2 : @viewport))
    @highlight.bitmap = RPG::Cache.load_bitmap("Graphics/UI/Buttons/",@name+"_highlight")
    @highlight.ox, @highlight.oy = @highlight.bitmap.width/2, @highlight.bitmap.height/2
    @index = 0
    
    @visible = @active = true
    moveto(@x, @y)
    refresh
    
    @disposed = false
    $scene.register(self)
  end
  
  #if you want to use custom arrow buttons - ie, some with hover, or that don't
  #have the same properties - although the callbacks will be overriden
  def replace_arrows(up, down)
    if @scroll
      @up_arrow.dispose
      @down_arrow.dispose
      up.center
      down.center
      @up_arrow, @down_arrow = up, down
      @up_arrow.set_callback("try_up",self)
      @down_arrow.set_callback("try_down",self)
    end
  end
  
  def update
    if @last_x != @x or @last_y != @y
      moveto(@x, @y)
    end
    if @active && !@key_lock
      #check for inputs
      if Input.trigger?(Input::C)
        #handle decision/confirm input
        @buttons[@index].on_click
      elsif Input.trigger?(Input::B)
        #handle cancel input
        if @cancel_proc
          if @cancel_proc.is_a?(Proc)
            @cancel_proc.call
          else
            @cancel_obj.send(@cancel_proc)
          end
        else
          $game_system.se_play($data_system.buzzer_se)
        end
      elsif Input.trigger?(Input::UP)
        try_up
      elsif Input.trigger?(Input::DOWN)
        try_down
      end
    end
    for i in 0...@buttons.length
      if $moused_over.include?(@buttons[i])
        @highlight.x, @highlight.y = @buttons[i].x, @buttons[i].y
        if @index != i then $game_system.se_play($data_system.decision_se) end
        @index = i
      end
    end
  end
  
  def set_list(buttons)
    for button in @buttons
      if !buttons.include?(button)
        button.dispose
      end
    end
    @buttons = buttons
    if @index >= buttons.length then @index = (buttons.length - 1) end
    refresh
  end
  
  #creates the button list from a specs template; each button will have as cover text
  #one name from names; optionally, provide equal-length, corresponding arrays of
  #method names and objects to bind their on_click callbacks to
  def generate_list(template, names, methods=nil,objs=nil)
    if !template.has_key?('name') then template['name'] = @name end
    buttons = names.map {|name| template['text']=name; Button.new(template,@viewport)}
    if methods
      if !objs then objs = Array.new(names.length,self) end
      for i in 0...buttons.length
        buttons[i].set_callback(objs[i],methods[i])
      end
    end
    set_list(buttons)
  end
  
  #add button (insert at non-negative index i)
  def add_button(button,i=-1)
    button.center
    if i < 0
      @buttons.push(button)
    else
      @buttons.insert(i,button)
    end
    refresh
  end
  
  def refresh_arrow_visibility
    #if scroll/not all buttons fit/shown
    if @scroll && (@m_i < @buttons.length)
      @up_arrow.visible, @up_arrow.active = @visible, @active
      @down_arrow.visible, @down_arrow.active = @visible, @active
      if @scroll_index == 0
        @up_arrow.visible, @up_arrow.active = false, false
      elsif @scroll_index == (@buttons.length - @m_i)
        @down_arrow.visible, @down_arrow.active = false, false
      end
    end
  end
  
  def try_down
    _max = @scroll ? (@m_i - 1) : (@buttons.length - 1)
    index = @index+1
    if @scroll && (index - @scroll_index > _max)
      @scroll_index = Math::min(@scroll_index+1,@buttons.length - @m_i)
    end
    @index = Math::min(@buttons.length - 1, index)
    $game_system.se_play($data_system.decision_se)
    refresh
  end
  def try_up
    @index = Math::max(0, @index - 1)
    if @scroll && (@index < @scroll_index)
      @scroll_index = @index
    end
    $game_system.se_play($data_system.decision_se)
    refresh
  end
  
  def lock_keys
    @key_lock = true
  end
  def unlock_keys
    @key_lock = false
  end
  
  def set_cancel_proc(proc, obj=nil)
    @cancel_proc = proc
    @cancel_obj = obj
  end
  
  def moveby(dx, dy)
    moveto(@x+dx,@y+dy)
  end
  
  def moveto(x, y)
    x, y = Math::max(0, Math::min($SCREEN_WIDTH, x)), Math::max(0, Math::min($SCREEN_HEIGHT, y))
    dx, dy = x - @last_x, y - @last_y
    @background.x, @background.y = x, y
    if @scroll
      @up_arrow.moveby(dx,dy)
      @down_arrow.moveby(dx,dy)
    end
    for button in @buttons
      button.moveby(dx, dy)
    end
    if @index < @buttons.length
      @highlight.x, @highlight.y = @buttons[@index].x, @buttons[@index].y
    end
    @last_x, @last_y = x, y
    @x, @y = @last_x, @last_y
  end
  
  def visible=(value)
    @background.visible = value
    if @scroll
      @up_arrow.visible = value
      @down_arrow.visible = value
    end
    for button in @buttons
      button.visible = value
    end
    @highlight.visible = value
  end
  
  def dispose
    @background.dispose
    if @scroll
      @up_arrow.dispose
      @down_arrow.dispose
    end
    for button in @buttons
      button.dispose
    end
    @highlight.dispose
    @disposed = true
    $scene.unregister(self)
  end
  
  def active_buttons
    if @scroll
      return @buttons[@scroll_index, @m_i]
    else
      return @buttons
    end
  end
  
  def dimensions
    width, height = 0, 2*@m_
    for button in active_buttons
      height += @space+button.height
      width = Math.max(button.width, width)
    end
    if @buttons.length > 1
      height -= @space
    end
    width += 2*@m_
    @width, @height = width, height
  end
  
  def draw_back
    if @back
      dimensions
      if @background.bitmap && !@background.bitmap.disposed?
        @background.bitmap.clear
        @background.bitmap.dispose
      end
      if @back.is_a?(String)
        @background.bitmap = RPG::Cache.load_bitmap("Graphics/UI/Buttons/",@back)
      elsif @back.is_a?(Color)
        @background.bitmap = Bitmap.new(@width, @height)
        @background.bitmap.fill_rect(0,0,@width,@height,@back)
      else
        @background.bitmap = RPG::Cache.load_bitmap("Graphics/UI/Buttons/",@name+"_back")
        @background.x, @background.y = @width/2, @height/2
        @background.ox, @background.oy = @background.bitmap.width/2, @background.bitmap.height/2
      end
    end
  end
  
  def refresh
    draw_back #dimensions
    for button in @buttons
      button.visible, button.active = false, false
    end
    x, y = @x+@width/2, @y+@m_
    for button in active_buttons
      button.center
      #button.x, button.y = x, y+button.height/2
      button.moveto(x, y+button.height/2)
      y += button.height+@space
      button.visible, button.active = @visible, @active
    end
    if @index < @buttons.length
      @highlight.x, @highlight.y = @buttons[@index].x, @buttons[@index].y
    end
    if @scroll
      refresh_arrow_visibility
      @up_arrow.moveto(@x+@width/2, @y-@up_arrow.height/2-@m_)
      @down_arrow.moveto(@x+@width/2, @y+@height+@m_+@down_arrow.height/2)
    end
  end
  
end

#==============================================================================
# ** RadialButtonList
#------------------------------------------------------------------------------
#  A radial collection of buttons that respond to mouse input
# ----------------
# Configuration:
#   - name : ("btn") name/prefix for set of corresponding image files/assets used for the button
#   - x, y, z : x (0), y (0), and z coordinates for the button
# Attributes:
#   - x, y
#   - width, height
#   - visible, active
# Methods:
#==============================================================================

class RadialButtonList < ButtonCollection
  attr_accessor   :x
  attr_accessor   :y
  attr_accessor   :active
  attr_reader     :visible
  attr_reader     :center
  attr_reader     :radius
  attr_reader     :disposed
  
  def initialize(specs, centerb=nil)
    #parse specifications
    
    #name of image assets used to make the grid
    if specs.has_key?("name") then @name = specs['name'] else @name="blist" end
    #x, y, and z coords of grid component
    if specs.has_key?("x") then @x = specs['x'] else @x=0 end
    if specs.has_key?("y") then @y = specs['y'] else @y=0 end
    if specs.has_key?("z") then @z = specs['z'] else @z=250 end
    #radius of arc of buttons
    if specs.has_key?("radius") then @radius = specs['radius'] else @radius=60 end
    #can be an asset name, or Boolean false for no background, else it will try to load @name+"_back.png"
    if specs.has_key?("background") then @back = specs['background'] else @back = true end
    #margins outside the border of the buttons
    if specs.has_key?("margins") then @m_ = specs['margins'] else @m_=5 end
    #angle/degrees of separation in a radial format
    if specs.has_key?("button_space") then @space = specs['button_space'] else @space=0 end
    #offset - by default (0 offset), like a "clock" - starts at top middle and goes around clockwise; angle offset is clockwise
    if specs.has_key?("offset") then @initial_offset = specs['offset'] else @initial_offset = 0 end
    #effects list for when buttons are being shown: scale, spin, fade
    if specs.has_key?("show_effects") then @show_effects = specs['show_effects'] else @show_effects = [] end
    #effects list for when buttons are being hidden: scale, spin, fade
    if specs.has_key?("hide_effects") then @hide_effects = specs['hide_effects'] else @hide_effects = [] end
    #show/hide duration (total frames)
    if specs.has_key?("show_duration") then @show_frames = specs['show_duration'] else @show_frames = 30 end
    if specs.has_key?("hide_duration") then @hide_frames = specs['hide_duration'] else @hide_frames = 30 end
    #when to show/hide: "radius" (mouse close enough to/too far from center), "toggle" (center clicked/unclicked), "always" (always show)
    #how much to spin on showing or hiding
    if specs.has_key?("show_rule") then @show_rule = specs['show_rule'] else @show_rule = 'toggle' end
    if specs.has_key?("hide_rule") then @hide_rule = specs['hide_rule'] else @hide_rule = 'toggle' end
    #if rule is radius, what is the trigger radius?
    if specs.has_key?("show_radius") then @show_radius = specs['show_radius'] else @show_radius = @radius end
    if specs.has_key?("hide_radius") then @hide_radius = specs['hide_radius'] else @hide_radius = (@radius.to_f*1.2).to_i end
    if @hide_radius < @show_radius then @hide_radius = @show_radius end
    #if it has the 'spin' effect in hide or show, what's the total spin angle?
    if specs.has_key?("spin_show") then @spin_show = specs['spin_show'] else @spin_show = 0 end
    if specs.has_key?("spin_hide") then @spin_hide = specs['spin_hide'] else @spin_hide = 0 end
    @last_x, @last_y = @x, @y
      
    @viewport = Viewport.new(0,0,$SCREEN_HEIGHT,$SCREEN_WIDTH)
    @viewport.z = @z
    @buttons, @angles = [], []
    @center = centerb
    if @center
      @center.center
      @center.x, @center.y = @x, @y
    end
    
    @background = RPG::Sprite.new(@viewport)
    draw_back
    
    @frame = 0
    @visible = @active = true
    moveto(@x, @y)
    @showing, @changed = true, true
    
    @disposed = false
    $scene.register(self)
  end
  
  def set_center(button)
    if @center then @center.dispose end
    button.center
    button.x, button.y = @x, @y
    @center = button
  end
  
  def set_angles(angles)
    @angles = []
    if angles.is_a?(Array)
      #if they specify an explicit array of angles...
      angle = 0.0
      for i in 0...@buttons.length
        if i < angles.length
          angle = angles[i].to_f
        else
          angle = (i <= 1) ? angle : (angle*(i.to_f/(i-1).to_f))
        end
        @angles.push(angle)
      end
    else
      #if they give a number, that is delta/angle between buttons
      angle = @initial_offset
      for i in 0...@buttons.length
        @angles.push(angle)
        angle += angles
      end
    end
    refresh
  end
  
  def show
    @changed = !@showing
    @showing = true
    if @center && @show_rule == "toggle" or @hide_rule == "toggle"
      if !@center.toggled? then @center.toggle end
    end
    refresh
  end
  def hide
    @changed = @showing
    @showing = false
    if @center && @show_rule == "toggle" or @hide_rule == "toggle"
      if @center.toggled? then @center.toggle end
    end
  end
  
  def set_list(buttons)
    for button in @buttons
      if !buttons.include?(button)
        button.dispose
      end
    end
    @buttons = buttons
    @buttons.each do |button|
      button.center
    end
    refresh
  end
  
  #creates the button list from a specs template; each button will have as cover text
  #one name from names; optionally, provide equal-length, corresponding arrays of
  #method names and objects to bind their on_click callbacks to
  def generate_list(template, names, angles=nil,methods=nil,objs=nil)
    if !template.has_key?('name') then template['name'] = @name end
    buttons = names.map {|name| template['text']=name; Button.new(template,@viewport)}
    if angles then @angles = angles end
    if methods
      if !objs then objs = Array.new(names.length,self) end
      for i in 0...buttons.length
        buttons[i].set_callback(objs[i],methods[i])
      end
    end
    set_list(buttons)
  end
  
  def update
    if @last_x != @x or @last_y != @y
      moveto(@x, @y)
    end
    if @center
      if @show_rule == 'toggle' && @center.toggled?
        show
      elsif @hide_rule == 'toggle' && !@center.toggled?
        hide
      end
    end
    if @changed
      #setup effects, turn off if hidden
      @frame = @showing ? @show_frames : (0-@hide_frames)
      for button in buttons
        button.active = @active && @showing
      end
      @changed = false
    else
      distance = Math.distance([$mouse.x, $mouse.y], [@x, @y])
      if @hide_rule == "radius"
        if @showing && distance > @hide_radius
          @showing, @changed = false, true
        end
      elsif @show_rule == "radius"
        if !@showing && distance < @show_radius
          @showing, @changed = true, true
        end
      end
    end
    #negative frame # = hiding
    #positve frame # = showing
    if @frame != 0
      #if transitioning, lock center
      if @center then @center.active = false end
      
      effect_frames = (@frame < 0) ? @hide_frames : @show_frames
      effects = (@frame < 0) ? @hide_effects : @show_effects
      spin_angle = (@frame < 0) ? @spin_hide : @spin_show
      
      frame = (@frame < 0) ? (@frame+effect_frames) : (effect_frames - @frame)
      frame_up_down = (@frame < 0) ? (0 - @frame) : (effect_frames - @frame)
      ratio = frame_up_down.to_f/effect_frames.to_f
      
      angles = @angles.clone
      radius = @radius.to_f
      
      offset = @initial_offset
      if @show_effects.include?("spin") && @frame < 0
        offset += @spin_show
      end
      angles = angles.map {|angle| (angle+offset)}
      #buttons fade in or fade out (0 opacity to 255 opacity)
      if effects.include?("fade")
        #opacity goes 0->255 on show, 255->0 on hide
        opacity = (255.0*(ratio)).to_i
        for button in @buttons
          button.opacity = opacity
        end
      end
      #adjust angles
      if effects.include?("spin")
        angles = angles.map {|angle| (angle.to_f+spin_angle.to_f*(ratio))}
      end
      #transform the radius
      if effects.include?("scale")
        # goes from 1/3 of radius to full radius
        radius = radius*(1.0+ (2.0*ratio))/3.0
      end
      #perform transformation on all buttons
      for i in 0...@buttons.length
        button = @buttons[i]
        angle = angle_correct((90.0 - angles[i].to_f)*(Math::PI/180.0))
        button.x, button.y = @x+(radius*Math.cos(angle)).to_i, @y-(radius*Math.sin(angle)).to_i
      end
      
      @frame = (@frame < 0) ? (@frame+1) : (@frame-1)
      #unlock center when transition ends
      if @frame == 0
        if @center then @center.active = @active end
        refresh
      end
    end
  end
  
  def moveby(dx, dy)
    moveto(@x+dx,@y+dy)
  end
  
  def distribute_evenly
    @angles, angle, delta = [], @initial_offset, 2.0*Math::PI/(@buttons.length.to_f)
    for i in 0...@buttons.length
      @angles.push(angle)
      angle += delta
    end
    refresh
  end
  
  def refresh
    if @frame == 0
      if @showing
        for i in 0...@buttons.length
          button = @buttons[i]
          button.opacity = 255
          button.visible, button.active = @visible, @active
          offset = @initial_offset
          if @show_effects.include?("spin")
            offset += @spin_show
          end
          angle = angle_correct((90.0 - (@angles[i].to_f+offset.to_f))*(Math::PI/180.0))
          button.x, button.y = @x+(@radius*Math.cos(angle)).to_i, @y-(@radius*Math.sin(angle)).to_i
        end
      else
        for button in @buttons
          button.visible, button.active = false, false
        end
      end
    end
  end
  
  def moveto(x, y)
    x, y = Math::max(0, Math::min($SCREEN_WIDTH, x)), Math::max(0, Math::min($SCREEN_HEIGHT, y))
    dx, dy = x - @last_x, y - @last_y
    @background.x, @background.y = x, y
    #for button in @buttons
      #button.moveby(dx, dy)
    #end
    @center.moveto(x, y)
    @last_x, @last_y = x, y
    @x, @y = @last_x, @last_y
    refresh
  end
  
  def visible=(value)
    @background.visible = value
    for button in @buttons
      button.visible = value
    end
    @center.visible = value
  end
  
  def dispose
    @background.dispose
    for button in @buttons
      button.dispose
    end
    #center button in radial?
    @disposed = true
    $scene.unregister(self)
  end
  
  def draw_back
    if @back
      if @background.bitmap && !@background.bitmap.disposed?
        @background.bitmap.dispose
      end
      if @back.is_a?(String)
        @background.bitmap = RPG::Cache.load_bitmap("Graphics/UI/Buttons/",@back)
      else
        @background.bitmap = RPG::Cache.load_bitmap("Graphics/UI/Buttons/",@name+"_back")
      end
      @background.ox, @background.oy = @background.bitmap.width/2, @background.bitmap.height/2
    end
  end
  
end
