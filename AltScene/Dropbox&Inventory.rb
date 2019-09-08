
#TODO: Add buttons, for things like sorting and coallescing and submitting
#TODO: Implement scrolling
#TODO: "visible" on grid that affects all boxes and items
#TODO: finish recipe comparison/crafting algorithm

#DEFINE MAX_STACK FUNCTIONS HERE
def ms_uniform(item_id, limit=1)
  return limit
end
def no_max(item_id)
  return true
end

# Sample item: [itemId, quantity=1, qaulity=0]; empty position: quantity or itemId=0

#mix recipes only require a total number of ingredients
$mix_recipes = [
    #[ [InputList] , [OutputList] ],
    
];
#ordered recipes take position/arrangement of the items into account
$ordered_recipes = [
    #[ [Input2DMatrix] , [OutputList] ],
];

class Game_Temp
  attr_reader   :recipe_trees
  attr_reader   :recipe_pools
  
  alias recipe_init initialize
  def initialize
    recipe_init
    create_recipe_trees
    recipe_condense
  end
  
  #an inefficient hashmap that relies on small numbers of
  #key-value pairs to save on memory
  class SmallMap
    attr_reader   :keys
    attr_reader   :values
    def initialize
      @keys = []
      @values = []
    end
    def has_key?(key)
      return @keys.include?(key)
    end
    def [](key)
      if @keys.include?(key)
        return @values[@keys.index(key)]
      else
        return nil
      end
    end
    def []=(key,val)
      if @keys.include?(key)
        @values[@keys.index(key)] = val
      else
        @keys.push(key)
        @values.push(val)
      end
    end
  end
  
  def create_recipe_trees
    @recipe_trees = SmallMap.new
    for pair in $ordered_recipes
      order = pair[0]
      w, h = pair[0].length, pair.length
      #find recipes for this inventory shape/dimensions
      if !@recipe_trees.has_key?([w, h])
        curr = @recipe_trees[([w, h])] = SmallMap.new
      else
        curr = @recipe_trees[([w, h])]
      end
      #walk through rows, branch as needed
      flat = pair[0].flatten(1)
      for component in flat
        #fill default values
        if component.length < 2
          component = [component[0],1,0]
        elsif component.length < 3
          component = [component[0], component[1], 0]
        end
        if curr.has_key?(component)
          curr = curr[component]
        else
          curr = curr[component] = SmallMap.new
        end
      end
      curr = pair[1]
    end
  end
  #condense & store imprecise/mix recipes
  def recipe_condense
    @recipe_pools = []
    for recipe in $mix_recipes
      input, output = recipe[0], recipe[1]
      input_s = []
      for component in input
        #fill default values
        if component.length < 2
          component = [component[0],1,0]
        elsif component.length < 3
          component = [component[0], component[1], 0]
        end
        updated = false
        for item in input_s
          #condense items of the same type
          if component[0] == item[0] && component[1] == item[1]
            item[2] += component[2]
            updated = true
            break
          end
        end
        if !updated then input_s.push(component) end
      end
      #sort input_s to have highest-quality requirements first, makes
      #things easier later
      input_s.sort! { |a, b| a[2] <=> b[2] }
      @recipe_pools.push([input_s, output])  
    end
  end
  
end

#==============================================================================
# ** Drop_Box
#------------------------------------------------------------------------------
#  Creates a tile/box that "accepts" draggable items dropped nearby
# ----------------
# Attributes:
#   - x, y
#   - width, height
#   - visible
#   - d_item : dragable item "contained" in the Drop_Box
# Methods:
#   - add_item(args) : attempts to merge a dragable item into this box
#   - is_in?(x, y) : returns true if the coordinates are within the rectangle defining this box
#   - moveby(dx, dy) : move the dropbox by <dx, dy>
#   - moveto(x, y) : move the dropbox to (x, y) (upper-left corner)
#   - release : disconnects/releases the draggable item sprite, if any are attached
#   - set_rect(width, height) : force the rectangle's dimensions
#==============================================================================

class Drop_Box
  attr_accessor :x
  attr_accessor :y
  attr_accessor :width
  attr_accessor :height
  attr_accessor :visible
  attr_accessor :d_item
  
  #back is either [width, height], [width, height, color] or the name of a background image
  #frame is the name of a frame image
  def initialize(x, y, back, viewport, frame=nil)
    @x, @y = x, y
    @viewport = viewport
    @background = Sprite.new(@viewport)
    #@width, @height = @viewport.rect.width, @viewport.rect.height
    if back.is_a?(String)
      @background.bitmap = RPG::Cache.load_bitmap("Graphics/UI/Inventory/",back)
      @background.x, @background.y = @x, @y
      @width, @height = @background.bitmap.width, @background.bitmap.height
    else
      @background.bitmap = Bitmap.new($SCREEN_WIDTH, $SCREEN_HEIGHT)
      if back.length < 3
        color = Color.new(15,15,15)
      else
        color = back[2]
      end
      @width, @height = back[0], back[1]
      @background.bitmap.fill_rect(x, y, back[0], back[1], color)
    end

    #show frame over item
    if frame
      @frame = Sprite.new(@viewport)
      @frame.x, @frame.y = @x, @y
      @frame.bitmap = RPG::Cache.load_bitmap("Graphics/UI/Inventory/",frame)
    end
    @visible = true
    @d_item, @last_item = nil, nil
  end
  
  def update
    if @last_item && @d_item && @d_item.item
      item = @d_item.item
      if @last_item.id != item.id
        add_item(item)
      elsif @last_item.quantity != item.quantity or @last_item.quality != item.quality
        refresh
      end
      @last_item = item.clone
    end
  end
  
  def visible=(value)
    if @visible != value
      @background.visible = value
      if @d_item then @d_item.visible = value end
      @visible = value
    end
  end
  
  def moveby(delx, dely)
    moveto(@x+delx, @y+dely)
  end
  
  def moveto(x, y)
    delx, dely = x - @x, y - @y
    @background.x, @background.y = x, y
    if @d_item then @d_item.moveby(delx, dely) end
    if frame then frame.x, frame.y = x, y end
    @x, @y = x, y
  end
  
  #force the height and width of the box
  def set_rect(width, height)
    @width, @height = width, height
    zoom_x, zoom_y = (@width.to_f/@image_w.to_f)*@scale[0], (@height.to_f/@image_h.to_f)*@scale[1]
    @background.zoom_x, @background.zoom_y = zoom_x, zoom_y
    if @frame then @frame.zoom_x, @frame.zoom_y = zoom_x, zoom_y end
  end
  
  #returns different case codes, see grid.add_item
  def add_item(d_item, name=nil)
    item = d_item.item
    if !name then name = item.name end
    #if we already have an item in this box
    if @d_item
      #if same item or
      if (item.id == @d_item.item.id) && (item.quality == @d_item.item.quality)
        max = @d_item.max?
        total = @d_item.item.quantity+item.quantity
        if total > max
          @d_item.item.quantity = max
          item.quantity = (total - max)
          @d_item.refresh
          return 2
        else
          @d_item.item.quantity += item.quantity
          @d_item.refresh
          return 1
        end
      end
      #if different item or quality, cannot merge
      return 2
    end
    #if empty, add the item
    @d_item, @last_item = d_item, item.clone
    @d_item.refresh
    return 3
  end
  
  def is_in?(x, y)
    if (@x <= x) && (x <= (@x+@width))
      if (@y <= y) && (y <= (@y+@height))
        return true
      end
    end
    return false
  end
  
  def release
    @d_item = nil
  end
  
  def dispose
    @background.dispose
    if @frame then @frame.dispose end
  end
  
end

#==============================================================================
# ** Game_Item
#------------------------------------------------------------------------------
#  Class to store information pertaining to items
#==============================================================================

class Game_Item
  MAX_QUANTITY=999
  MIN_QUANTITY=0
  
  attr_accessor   :quality
  attr_accessor   :quantity
  attr_reader   :id
  attr_reader   :name
  
  def initialize(id, quality=0, quantity=1)
    @id = id
    item = $data_items[id]
    @name = item.name
    @quality = quality
    @quantity = quantity
  end
  
  def to_array
    [@id, @quality, @quantity]
  end
  
  def add(amnt=1)
    @quantity += amnt
    @quantity = Math::min(@quantity,MAX_QUANTITY)
  end
  def reduce(amnt=1)
    @quantity -= amnt
    @quantity = Math::max(@quantity,MIN_QUANTITY)
  end
  def value
    (($data_items[@id].value)*(1.0+@quality.to_f/2.0)).to_i
  end
end

#==============================================================================
# ** Drag_Item
#------------------------------------------------------------------------------
#  A class of Dragable that carries information about an item
#   - directory - where the assets will be looked for: default "Graphics/UI/Inventory"
#   - hover - whether there is a separate sprite for hovering over it: default false
#==============================================================================

class Drag_Item < Dragable
  attr_accessor   :item
  attr_reader     :grid
  attr_reader     :i
  attr_reader     :j
  
  def initialize(item, specs, viewport, dropable=false, hover=false)
    @item = item
    @quality, @quantity = Sprite.new(viewport), Sprite.new(viewport)
    @quality.visible, @quantity.visible = false, true
    
    if !specs.has_key?('directory') then specs['directory']="Graphics/UI/Inventory/" end
    if !hover then specs['hover'] = false end
    if specs.has_key?('max_stack') then @max_stack=specs['max_stack'] else @max_stack='no_max' end#@max_stack='ms_uniform' end
    if !specs.has_key?('name') then specs['name'] = "item_"+item.id.to_s end
    super(specs, viewport, dropable)
    
    if @item.quality > 0
      @quality.bitmap = RPG::Cache.load_bitmap("Graphics/UI/Inventory/","quality_"+item.quality.to_s)
    else
      @quality.bitmap = Bitmap.new(@width,@height)
    end
    @quantity.bitmap = Bitmap.new(@width,@height)
    @quantity.bitmap.font.color = Color.new(250,250,250)
    @quantity.bitmap.font.size = 14
    moveto(@x, @y)
    
    if @centered
      center
    end
    
    #owning grid; owner was taken, I wasn't very forward-thinking with the names
    @grid = nil
    @i, @j = -1, -1
    refresh
  end
  
  #max_stack must be a function that takes an item id
  #and returns the corresponding maximum stack size
  def max?
    return send(@max_stack, @item.id)
  end
  
  def set_grid(grid, i, j)
    @grid = grid
    @i, @j = i, j
  end
  
  def center
    super
    if @quality && @quality.bitmap
      @quality.ox, @quality.oy = @quality.bitmap.width/2, @quality.bitmap.height/2
      @quantity.ox, @quantity.oy = @quantity.bitmap.width/2, @quantity.bitmap.height/2
    end
  end
  def topleft
    super
    if @quality && @quantity
      @quality.ox, @quality.oy = 0, 0
      @quantity.ox, @quantity.oy = 0, 0
    end
  end
  def set_rect(width, height)
    super
    if @quality && @quantity
      zoom_x, zoom_y = (@width.to_f/@image_w.to_f)*@scale[0], (@height.to_f/@image_h.to_f)*@scale[1]
      @quality.zoom_x, @quality.zoom_y = zoom_x, zoom_y
      @quantity.zoom_x, @quantity.zoom_y = zoom_x, zoom_y
    end
  end
  def change_viewport(new_view)
    super
    @quality = viewport_swap(@quality, new_view)
    @quantity = viewport_swap(@quantity, new_view)
  end
  
  def on_click(new_drag=false)
    vp = Viewport.new(0,0,$SCREEN_WIDTH,$SCREEN_HEIGHT)
    vp.z = @viewport.z
    change_viewport(vp)
    if @grid && (!new_drag)
      quantity = 1
      #Take the entire stack if special key is being held, or if the whole stack is just 1 item
      if (Input::trigger?(Input::Key['Ctrl']) or Input::repeat?(Input::Key['Ctrl']) or Input::press?(Input::Key['Ctrl'])) \
        or (Input::trigger?(Input::Key['Shift']) or Input::repeat?(Input::Key['Shift']) or Input::press?(Input::Key['Shift'])) \
        or (@item.quantity == 1)
        #this was getting called by the lone dragable created by the else block,
        #which defeats the purpose/is bad. If a stack should remain behind, can't release
        @grid.release(@i, @j)
        quantity = @item.quantity
        dispose
      else #Default: take 1 off the stack
        #inform this one that it has lost one
        @item.reduce
        refresh
      end
      #create a new, separate dragable sprite above old one, with same traits except
      #quantity 1
      top = Drag_Item.new(Game_Item.new(@item.id, @item.quality, quantity),
       {'directory'=>@direc,
       'hover'=>@hover_type,'toggle'=>@toggle_type,
       'max_stack'=>@max_stack,
       'magnet'=>false,
       'x'=>@x,'y'=>@y,'z'=>@viewport.z
      }, @viewport)
      top.set_grid(@grid, @i, @j)
      #top.update
      top.on_click(true)
      return
    end
    super()
  end
  
  def visible=(value)
    if @visible != value
      @quality.visible, @quantity.visible = value, value
      @visible = value
    end
  end
  
  def refresh
    if @item.quality > 0
      @quality.bitmap = RPG::Cache.load_bitmap("Graphics/UI/Inventory/","quality_"+@item.quality.to_s)
      @quality.visible = true
    else
      @quality.visible = false
    end
    @quantity.bitmap.clear
    quantity = @item.quantity
    if quantity && quantity > 1
      @quantity.bitmap.draw_text(10,@height-35,@width,35,quantity.to_s)
    end
  end
  
  def moveto(x, y)
    super
    vx, vy = @viewport.rect.x, @viewport.rect.y
    x, y = Math::max(0, Math::min($SCREEN_WIDTH, x-vx)), Math::max(0, Math::min($SCREEN_HEIGHT, y-vy))
    @quantity.x, @quantity.y = x, y
    @quality.x, @quality.y = x, y
  end
  
  def release_callback
    in_grid = false
    if $scene.grids
      for grid in $scene.grids
        i, j = grid.is_in?(@x, @y)
        if i != -1
          in_grid = true
          #tries to merge item into box
          case grid.add_item(self, i, j)
          when 1
            #this has been disposed of
            return
          when 2
            #returns to old spot, if not disposed of
            in_grid = false
          when 3
            #fills new box
            @grid = grid
            @i, @j = i, j
          end
          break
        end
      end
    end
    #if pulled into no-man's-land or otherwise has to "snap back" (failed merge),
    if !in_grid
      #try to add it to its old spot
      @grid.add_item(self, @i, @j)
    end
    #if this dragable is destroyed/no longer needed, don't try to refresh or move it
    if @disposed then return end
    refresh
    #snap back to last box/position, or into new one
    x, y = @grid.get_position(@i, @j, true)
    moveto(x, y)
    super
  end
  
  def dispose
    @quality.dispose
    @quantity.dispose
    super
  end
end

#==============================================================================
# ** Drag_Grid
#------------------------------------------------------------------------------
#  creates a grid of Drop_Boxes; can be scrollable, can contain a row of buttons
#==============================================================================

class Drag_Grid
  
  BACKCOLOR = Color.new(50,50,50)
  INLAYCOLOR = Color.new(120,120,120)
  
  def initialize(gridwidth, gridheight, specs)
    #parse specifications
    
    #name of image assets used to make the grid
    if specs.has_key?("name") then @name = specs['name'] else @name="grid" end
    #x, y, and z coords of grid component
    if specs.has_key?("x") then @x = specs['x'] else @x=0 end
    if specs.has_key?("y") then @y = specs['y'] else @y=0 end
    if specs.has_key?("z") then @z = specs['z'] else z=200 end
    #margins outside the border of the grid
    if specs.has_key?("margins") then @m_ = specs['margins'] else @m_=5 end
    #margins/space between tiles within the grid
    if specs.has_key?("tile_size") then @tile_height = @tile_width = specs['tile_size'] else @tile_height=@tile_width=0 end
    #margins/space between tiles within the grid
    if specs.has_key?("tile_space") then @ts_ = specs['tile_space'] else @ts_=0 end
    #max stack method for items in this grid
    if specs.has_key?("max_stack") then @max_stack = specs['max_stack'] else @max_stack='uniform' end
    #can the inventory scroll?
    if specs.has_key?("scroll") then @scroll_type = specs['scroll'] else @scroll_type=false end
    if specs.has_key?("max_j") then @m_j = Math::max(gridheight, specs['max_j']) else @m_j = gridheight end
    @scroll_index, @scroll_amnt = 0, 0
    @b_height = 0
    
    @gw, @gh = gridwidth, gridheight
    @b_viewport = Viewport.new(0,0,$SCREEN_WIDTH, $SCREEN_HEIGHT)
    @b_viewport.z = z
    @buttons, @b_height = [], 0
    @background = Sprite.new(@b_viewport)
    @background.bitmap = Bitmap.new($SCREEN_WIDTH, $SCREEN_HEIGHT)
    
    #try to get the dimensions of the boxes; forcing is true 
    forcing, temp = true, RPG::Cache.load_bitmap("Graphics/UI/Inventory/",@name+"_box")
    if @tile_height <= 0 || @tile_width <= 0
      @tile_height, @tile_width = temp.height, temp.width
      forcing = false
    end
    
    if @scroll_type
      @scroll_amnt = 0
      @scroller = Dragable.new({
        'x' => (@x + scroll_start), 'y' => (@y + grid_start_y),
        'name' => (@name+'_scroller'), 'directory' => "Graphics/UI/Inventory/"
      }, @b_viewport, false, true)
      @scroller.lock_x
      @scroller.set_bound_box(@x, @y+grid_start_y, @x+total_width, @y+grid_start_y+grid_height)
    end
    
    @grid_viewport = Viewport.new(@x+@m_,@y+grid_start_y,grid_width, grid_height)
    @grid_viewport.z = z + 1
    @tiles = []
    y = @ts_
    #scrollable will potentially have to show an extra row, if partially scrolled
    gh = gridheight + (@scroll_type ? 1 : 0)
    for j in 0...gh
      x, array = @ts_, []
      for i in 0...gridwidth
        tile = Drop_Box.new(x, y, @name+"_box", @grid_viewport)
        if forcing then tile.set_rect(@tile_width, @tile_height) end
        array.push(tile)
        x += @tile_width+@ts_
      end
      y += @tile_height+@ts_
      @tiles.push(array)
    end
    
    @visible = true
    @active = true
    $scene.register(self)
    
    refresh
  end
  
  def total_width
    #left margin, all tiles and spaces between them, right margin, scroller and its right margin
    scroll_start_x + scroll_width
  end
  def total_height
    #top margin, optional button height and its margin, all tiles and spaces between them, bottom margin
    grid_start_y+grid_height + @m_
  end
  def scroll_start_x
    2*@m_+ grid_width
  end
  def scroll_width
    (@scroll_type ? (@m_+@scroller.width): 0)
  end
  def grid_width
    @ts_+(@tile_width+@ts_)*@gw
  end
  def grid_height
    @ts_+(@tile_height+@ts_)*@gh
  end
  def grid_max_height #how big the whole grid would be in a scrollable, if it were all visible
    @ts_+(@tile_height+@ts_)*@max_j
  end
  def grid_start_y
    @m_+(@b_height > 0 ? (@b_height+@m_) : 0)
  end
  
  def set_contents(items, max_stack=@max_stack)
    i, j = 0, 0
    @max_stack = max_stack
    rec = @grid_viewport.rect
    #new_viewport = Viewport.new(0,0,$SCREEN_WIDTH, $SCREEN_HEIGHT)
    #new_viewport.z = @grid_viewport.z+1
    for row in @tiles
      i = 0
      for box in row
        #dispose of all existing Drag_Items
        if box.d_item
          box.d_item.dispose
          box.release
        end
        item = items[j*@gw+i]
        if item && item != []
          viewport = Viewport.new(rec.x,rec.y,rec.width,rec.height)
          viewport.z = @grid_viewport.z+1
          id = item[0]
          quality = (item[1] && item[1] >= 0) ? item[1] : 0
          quantity = (item[2] && item[2] >= 1) ? item[2] : 1
          x, y = get_position(i, j, true)
          #x, y = x+@x, y+@y
          box.add_item(Drag_Item.new(Game_Item.new(id, quality, quantity),
           { 'max_stack'=>max_stack,
            'magnet'=>false,
            'x'=>x,'y'=>y
          }, viewport))#new_viewport))
          box.d_item.set_grid(self, i, j)
        end
        i += 1
      end
      j += 1
    end
  end
  
  def scroll_change?
    start = grid_start_y
    new_scroll = (@scroller.y - (@y+start))
    new_scroll = new_scroll.to_f / grid_height.to_f
    #if scroller has changed position, update
    if new_scroll != @scroll_amnt
      delta = new_scroll - @scroll_amount
      @scroll_amnt = new_scroll
      #translate scroller position to grid scroll position
      grid_scroll = (delta*((grid_max_height - grid_height).to_f)).to_i
      do_scroll(grid_scroll)
    end
  end
  
  #TODO: this does nothing
  def change_gridview(dx, dy)
    rec = @grid_viewport.rect
    @grid_viewport.rect.set(rec.x+dx,rec.y+dy,rec.width,rec.height)
    for row in @tiles
      for box in row
        box.moveby(dx, dy)
      end
    end
  end
  
  def do_scroll(delta)
    #kind of confusing - upper is the lower boundary of the box on the screen, the higher y value
    upper, lower = @ts_, @ts_
    for row in @tiles
      for box in row
        box.moveby(0, delta)
      end
    end
  end
  
  def release(i, j)
    @tiles[j+@scroll_index][i].release
  end
  
  def present?(i, j)
    return (@tiles[j][i].d_item != nil)
  end
  
  def refresh
    @background.bitmap.clear
    #draw the background rectangle
    @background.bitmap.fill_rect(@x, @y, total_width, total_height, BACKCOLOR)
    #draw scroller region
    if @scroll_type
      @background.bitmap.fill_rect(@x+grid_start_x, @y+grid_start_y, @scroller.width, grid_height, INLAYCOLOR)
      @scroller.set_rect(@scroller.width, (grid_height.to_f*(@m_j.to_f/@gh.to_f)).to_i)
    end
    #draw button region
    if @b_height != 0
      @background.bitmap.fill_rect(@x+@m_, @y+@m_, grid_width, @b_height, INLAYCOLOR)
    end
    #draw grid/cubby region
    @background.bitmap.fill_rect(@x+@m_, @y+grid_start_y, grid_width, grid_height, INLAYCOLOR)
    #todo: shift all boxes and their items down if button added
  end
  
  def update
    #track scroll bar and perform necessary scrolling
    if @scroll_type
      scroll_change?
    end
  end
  
  def moveto(x, y)
    x, y = Math::max(0, Math::min($SCREEN_WIDTH, x)), Math::max(0, Math::min($SCREEN_HEIGHT, y))
    delx, dely = x - @x, y - @y
    @x, @y = x, y
    @background.x, @background.y = x, y
    @grid_viewport.rect.set(x+@m_, y+grid_start_y, grid_width, grid_height)
    #move all boxes
    #   define "moveto" boxes that moves sprites attached to them
    for row in @tiles
      for box in row
        box.moveby(delx, dely)
      end
    end
  end
  
  def visible=(value)
    if value != @visible
      @visible = value
      @background.visible = @visible
      for row in @tiles
        for tile in row
          tile.visible = @visible
        end
      end
    end
  end
  
  def add_button(button)
    @buttons.push(button)
    @b_height = Math::max(@b_height, button.height)
  end
  
  #modify this to work with scrolling
  def is_in?(x, y)
    if ((@x+@m_) <= x) && (x <= (@x+@m_+grid_width))
      if ((@y+grid_start_y) <= y) && (y <= (@y+grid_start_y+grid_height))
        x, y = x - (@x+@m_), y - (@y+grid_start_y)
        #make sure it's in the grid viewport
        gh = @gh + (@scroll_type ? 1 : 0)
        for j in 0...gh
          for i in 0...@gw
            if @tiles[j][i].is_in?(x, y)
              return [i, j]
            end
          end
        end
      end
    end
    return [-1, -1]
  end
  
  def get_position(i, j, center=false)
    x = @x+@m_+@tiles[j][i].x
    y = @y+grid_start_y+@tiles[j][i].y
    if center
      x += @tile_width/2
      y += @tile_height/2
    end
    return [x, y]
  end
  
  #must return true if item has actually moved
  def add_item(d_item, i, j)
    result = @tiles[j][i].add_item(d_item)
    #3 cases:
    #If an item is already in dest box:
    # 1) if they merge completely, change that item (dispose this one)
    # 2) if they do not fully merge, bounce this item back to original i,j
    #If no item already present:
    # 3) move this item to box
    case result
    when 1
      d_item.dispose
    when 2
      #i and j stay the same, restore items
    when 3
      rec = @grid_viewport.rect
      vp = Viewport.new(rec.x, rec.y, rec.width, rec.height)
      vp.z = d_item.z
      d_item.change_viewport(vp)
      #@items[d_item.j*@gw+d_item.i] = d_item.item.to_array
    end
    return result
  end
  
  def items
    it = []
    for j in 0...@m_j
      for i in 0...@gw
        if @tiles[j][i].d_item
          it.push(@tiles[j][i].d_item.item.to_array)
        else
          it.push([0,0,0])
        end
      end
    end
    return it
  end
  
  def dispose
    @background.dispose
    if @scroller then @scroller.dispose end
    for row in @tiles
      for box in row
        if box.d_item
          box.d_item.dispose
        end
        box.dispose
      end
    end
    for button in @buttons
      button.dispose
    end
  end
  
  def sort(method)
    set_contents(items.sort_by(method))
  end
  
  def compare(recipeItem, item, exact=false)
    #same item type
    if recipeItem[0] == item[0]
      #quantity is greater than or equal to required, unless exact match specified
      if (exact && (recipeItem[1] == item[1])) or (!exact && (recipeItem[1] <= item[1]))
        #quality is greater than or equal to required, unless exact match specified
        if (exact &&(recipeItem[2] == item[2])) or (!exact && (recipeItem[2] <= item[2]))
          return true
        end
      end
    end
    return false
  end
  def condense_list(list)
    c_list = []
    for component in list
      updated = false
      for item in c_list
        #condense items of the same type
        if component[0] == item[0] && component[1] == item[1]
          item[2] += component[2]
          updated = true
          break
        end
      end
      if !updated then c_list.push(component) end
    end
    return c_list
  end
  def match_recipe(exact=false)
    list = items
    verify = $game_temp.recipe_trees[([@gw, @gh])]
    #prioritize precise match:
    matches = match_precise(list, verify, exact)
    list = condense_list(list)
    #imprecise/quantity match:
    matches.concat(match_quantity(list,$game_temp.recipe_pools,exact))
  end
  #depth first search of recipe tree
  def match_precise(list, lookup, exact=false)
    #reached the end of a tree?
    if !lookup.is_a?(SmallMap)
      return [lookup]
    end
    clist = list.clone
    item = clist.shift
    results = []
    for key in lookup.keys
      #if we have a match
      if compare(key,item,exact)
        #check deeper
        results.concat(match_precise(clist, lookup[key], exact))
      end
    end
    return results
  end
  def match_quantity(list, lookup, exact=false)
    matches = []
    #sort inputs to try to use lowest-quality items first
    list.sort! { |a, b| b[2] <=> a[2] }
    for recipe in lookup
      full_match = true
      input, output = recipe[0], recipe[1]
      clist = list.clone
      #recall that inputs in the lookup are sorted with highest-quality first
      for item in input
        #check to see if the source/ingredient list has something that fits for this recipe ingredient
        found_match = false
        for i in 0...clist.length
          if compare(clist[i],item,exact)
            #remove element at i so it cannot be matched again with a different component
            clist = clist[0,i].concat(clist[i+1..-1])
            found_match = true
            break
          end
        end
        #if there is no match, stop looking at this recipe
        if !found_match
          full_match = false
          break
        end
      end
      #did we successfully match all input ingredients with a source ingredient?
      if full_match
        matches.push(output)
      end
    end
    return matches
  end
  
end
