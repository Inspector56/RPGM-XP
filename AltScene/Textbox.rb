#REQUIRES NEW SCENE DEFINITION/FRAMEWORK, or else remove lines 77 and 231
# ("$scene.register(self)" in initialize and "$scene.unregister(self)" in dispose)
# if you remove these, you will have to invoke update on the textbox every frame yourself

#I'm sorry, I only started to understand what I really wanted to do well after
#starting to code, so the framework/design is kind of a mess

#==============================================================================
# ** Text_Box
#------------------------------------------------------------------------------
#  A visual text box for the user to enter/type strings into
# ----------------
# Attributes:
#   - x, y, z
#   - width, height
#   - active, visible
# Methods:
#   - get_message : retrieve the current contents
#   - moveto(x, y) : move the textbox to (x, y) (upper-left corner)
#   - moveby(dx, dy) : move the textbox by <dx, dy>
#==============================================================================

class Text_Box
  
  MARGINS = 6
  FONT = "Verdana"
  FSIZE = 16
  FCOLOR = Color.new(0,0,0)
  CHAT_WIDTH, CHAT_HEIGHT = 240, 24
  
  attr_accessor   :x
  attr_accessor   :y
  attr_accessor   :visible
  attr_reader     :active
  attr_reader     :width
  attr_reader     :height
  attr_reader     :disposed
  
  def initialize(specs)
    #x, y, and z coords of grid component
    if specs.has_key?("x") then @x = specs['x'] else @x=0 end
    if specs.has_key?("y") then @y = specs['y'] else @y=0 end
    if specs.has_key?("z") then z = specs['z'] else z = 10000 end
    #width and height of text box
    if specs.has_key?("width") then @x = specs['width'] else @width=CHAT_WIDTH end
    if specs.has_key?("height") then @height = specs['height'] else @height=CHAT_HEIGHT end  
    #size of margins on either side
    if specs.has_key?("margins") then @margins = specs['margins'] else @margins = MARGINS end
    #font type, size, and color
    if specs.has_key?("font_size") then @f_size = specs['font_size'] else @f_size=FSIZE end
    if specs.has_key?("font") then @f_name = specs['font'] else @f_name=FONT end
    if specs.has_key?("font_color") then @f_color = specs['font_color'] else @f_color=FCOLOR end
    
    @x, @y, @width, @height = x, y, width, height
    @lastx, @lasty = x, y
    @contents = ""
    @text_widths = []
    
    @viewport = Viewport.new(0,0,$SCREEN_WIDTH,$SCREEN_HEIGHT)
    @viewport.z = z
    @background = Sprite.new(@viewport)
    @background.x, @background.y = x, y
    @background.bitmap = Bitmap.new(width, height)
    @background.bitmap.fill_rect(0,0,width,height,Color.new(40,40,40,80))
    
    @temp_text = Sprite.new(@viewport)
    @temp_text.bitmap = Bitmap.new(width,height)
    @temp_text.y = y
    @temp_text.x = x
    
    @cursor = Sprite.new(@viewport)
    @cursor.bitmap = Bitmap.new(width,height)
    @cursor.bitmap.fill_rect(0,1,3,height-2,Color.new(240,240,240))
    @cursor.x = x+@margins
    @cursor.y = y
    @cursor.visible = false
    
    $keyboard.connect_textbox(self)
    $scene.register(self)
    
    @visible = true
    @active = false
    @disposed = false
    @scroll_index_x = 0
    @restore_cursor = 0
    refresh
  end
  
  def z
    @viewport.z
  end
  
  def moveto(x, y)
    x, y = Math::max(0, Math::min($SCREEN_WIDTH, x)), Math::max(0, Math::min($SCREEN_HEIGHT, y))
    delx = x - @x
    @x, @y, @lastx, @lasty = x, y, x, y
    @background.x, @background.y = x, y
    @temp_text.x, @temp_text.y = x, y
    @cursor.y = y
    @cursor.x += delx 
  end
  
  def moveby(dx, dy)
    moveto(@x+dx, @y+dy)
  end
  
  def get_message
    message = @contents ? @contents : ""
    message.clone
  end
  
  def needs_shift?
    if @scroll_index_x > $keyboard.cursor_pos
      @scroll_index_x = $keyboard.cursor_pos
      return true
    end
    if @cursor.x > (@x+@width-2*@margins)
      @scroll_index_x += 1
      return true
    end
    return false
  end
  
  def partial_message
    mes = @contents[@scroll_index_x...$keyboard.cursor_pos]
    mes = mes ? mes : ""
    return mes
  end
  
  def find_appropriate_string
    mes = ""
    i, length = @scroll_index_x, 0
    while true
      #stop if we hit end of message, or end of text box
      if i == $keyboard.message.length or ((length + @text_widths[i]) >= @width+2*MARGINS)
        return mes
      else #incrementally generate message, keep track of total width of text/message
        mes += $keyboard.message[i, 1]
        length += @text_widths[i]
        i += 1
      end
    end
    #this message represents the finalized message to be displayed; use the
    #previously totaled width to set final cursor position
    @cursor.x = sum_widths(@scroll_index_x, $keyboard.cursor_pos)
    return mes
  end
  
  #excludes finish
  def sum_widths(start, finish)
    sum = 0
    while finish > start
      sum += @text_widths[start]
      start += 1
    end
    return sum
  end
  
  def refresh
    if !@active then return end
    if @contents.length > $keyboard.message.length
      #DELETE occurred
      if $keyboard.cursor_pos == $keyboard.message.length
        @text_widths.pop
      else
        @text_widths = @text_widths[0...($keyboard.cursor_pos)].concat(@text_widths[($keyboard.cursor_pos+1)..-1])
      end
    elsif @contents.length < $keyboard.message.length
      #character was added
      @text_widths.insert($keyboard.cursor_pos - 1, @temp_text.bitmap.text_size($keyboard.message).width-@temp_text.bitmap.text_size(@contents).width)
    end
    @contents = $keyboard.message.clone
    @restore_cursor = $keyboard.cursor_pos
    @temp_text.bitmap.font.size = @f_size
    @temp_text.bitmap.font.name = @f_name
    @temp_text.bitmap.font.color = @f_color
    @temp_text.bitmap.clear
    
    @cursor.x = @margins+@x+sum_widths(@scroll_index_x, $keyboard.cursor_pos)
    while needs_shift?
      @cursor.x = @margins+@x+sum_widths(@scroll_index_x, $keyboard.cursor_pos)
    end
    if @contents == nil then @contents = "" end
    @temp_text.bitmap.draw_text(@margins, 0,@width,@height, find_appropriate_string)
  end
  
  def move_cursor_to_mouse
    i, length = @scroll_index_x, @x+@margins
    while true
      #stop if we hit end of message, or end of text box
      if i == $keyboard.message.length or ((length + @text_widths[i]) > $mouse.x)
        break
      else #incrementally generate message, keep track of total width of text/message
        length += @text_widths[i]
        i += 1
      end
    end
    @cursor.x = length
  end
  
  def update
    #if someone used x or y attributes to move the textbox
    if @x != @lastx or @y != @lasty
      moveto(@x, @y)
    end
    #if not visible, cannot activate/click into it
    if Input::trigger?(Input::Key['Mouse Left'])
      if ($mouse.x >= @temp_text.x) && ($mouse.x <= (@temp_text.x+@width))\
        && ($mouse.y >= @temp_text.y) && ($mouse.y <= (@temp_text.y+@height))
        @active = true
        $keyboard.active = true
        $keyboard.message = @contents.clone
        $keyboard.cursor_pos = @restore_cursor
        if @contents != ""
          move_cursor_to_mouse
        end
      else
        @active = false
      end
      if !@visible then @active = false end
      refresh
    end
    @cursor.visible = @visible && @active
    @background.visible = @visible
    @temp_text.visible = @visible
  end
  
  def dispose
    @cursor.dispose
    @background.dispose
    @temp_text.dispose
    @disposed = true
    $scene.unregister(self)
  end
  
end

#==============================================================================
# ** Keyboard
#------------------------------------------------------------------------------
#  A helper (singleton) class to handle user input and message creation/editing
# ----------------
# Attributes:
#   - message : current string
#   - cursor_pos : position of cursor in string/message
#   - send_ready : flag that message is "done"
#   - active
# Methods:
#   - send_message : set send flag
#   - receive_message : unset send flag, get message value, and reset message to empty
#   - max? : returns true if message is max length/full
#   - cursor_left : tries to decrement the cursor position
#   - cursor_right : tries to increment the cursor position
#==============================================================================

class Keyboard
  
  MAX_MESSAGE_LEN = 200
  attr_accessor   :active
  attr_accessor   :message
  attr_accessor   :cursor_pos
  attr_reader     :send_ready
  
  def initialize
    @message = ""
    @active, @needs_refresh = false, false
    @cursor_pos = 0
    @text_boxes = []
    @old_scene = $scene
  end
  
  def send_message
    @send_ready = true
  end
  
  def receive_message
    msg = @message
    @message = ""
    @send_ready = false
    return msg
  end
  
  def connect_textbox(tb)
    #reset connections on scene change
    if @old_scene != $scene
      @text_boxes = []
      @old_scene = $scene
    end
    @text_boxes.push(tb)
  end
  
  def update
    #if any text box is active, keyboard is active
    @active = false
    @text_boxes.each do |box|
      if box.active
        @active = true
        break
      end
    end
  end
  
  def refresh_text_boxes
    @text_boxes.each do |box|
      box.refresh
    end
  end
  
  def try_type_letter(letter)
    #if the textbox has more room for another character
    if !max?
      #add the character to the right of the cursor's location
      @message = @message.insert(cursor_pos, letter)
      #move the cursor past the newly-inserted letter
      cursor_right
    else
      #fail to type, full
      $game_system.se_play($data_system.buzzer_se)
    end
  end
  
  def try_delete_at_cursor
    #cannot delete if nothing to the left of the cursor
    if @cursor_pos == 0 then return end
    #otherwise, cursor will move left
    @cursor_pos -= 1
    if @cursor_pos == @message.length
      #delete the end
      @message.chop!
    else
      #delete the character just right of the new cursor position (left of old)
      @message = @message[0...@cursor_pos]+@message[(@cursor_pos+1)..-1]
    end
  end
  
  def max?
    return (@message.length >= MAX_MESSAGE_LEN)
  end
  
  def cursor_right
    #increment the cursor position by 1 if it is not at the end
    @cursor_pos = Math::min(Math::min(@cursor_pos+1, @message.length),MAX_MESSAGE_LEN)
  end

  def cursor_left
    #decrement the cursor position by 1 if not at the beginning
    @cursor_pos = Math::max(@cursor_pos-1, 0)
  end
  
end
#Create singleton object
$keyboard = Keyboard.new


#this change to Input is where a lot of the code that makes "keyboard" work actually lies
module Input
  class << self
    
    alias feed_keypresses_into_keyboard update
    def update
      feed_keypresses_into_keyboard
      $keyboard.update
      if $keyboard.active
        @keyboard_lock = true
        Key.each do |key, id|
          if Input::trigger?(id) or Input::repeat?(id) && (id != Key["Shift"])
            if key.match(/NumberPad /)
              next #collision with NumberPad and arrows, apparently not
                #actually meant to be numbers
              #key = key[10..key.length]
            end
            if key.length == 1
              if Input::press?(Key["Shift"]) or Input::repeat?(Key["Shift"])\
                or Input::press?(Key["Left Shift"]) or Input::repeat?(Key["Left Shift"])\
                or Input::press?(Key["Right Shift"]) or Input::repeat?(Key["Right Shift"])
                #upper case
                case key
                when '.'
                  letter = '>'
                when ','
                  letter = '<'
                when '/'
                  $letter = '?'
                when '1'
                  letter = '!'
                when '2'
                  letter = '@'
                when '3'
                  letter = '#'
                when '4'
                  letter = '$'
                when '5'
                  letter = '%'
                when '6'
                  letter = '^'
                when '7'
                  letter = '&'
                when '8'
                  letter = '*'
                when '9'
                  letter = '('
                when '0'
                  letter = ')'
                when '-'
                  letter = '_'
                when '='
                  letter = '+'
                when '\\'
                  letter = '|'
                when "'"
                  letter = '"'
                when ';'
                  letter = ':'
                when '['
                  letter = '{'
                when ']'
                  letter = '}'
                when '`'
                  letter = '~'
                else
                  letter = key.upcase #check how this handles non alphabetic
                end
              else
                #lowercase verison
                letter = key.downcase
              end
              $keyboard.try_type_letter(letter)
            else #non single letter; delete, numpad, arrows
              case key
              when "Delete", "Backspace"
                if $keyboard.message != ""
                  $keyboard.try_delete_at_cursor
                end
              when "Space"
                $keyboard.try_type_letter(" ")
              when "Tab"
                for i in 0...4
                  $keyboard.try_type_letter(" ")
                end
              when "Enter"
                $keyboard.send_message
              when "Arrow Right"
                $keyboard.cursor_right
              when "Arrow Left"
                $keyboard.cursor_left
              when "Esc"
                $keyboard.active = false
              end
            end
            $keyboard.refresh_text_boxes
            break #only add one letter
          end
        end
        @keyboard_lock = false
      end
    end
  
    alias eat_press press?
    def press?(keys)
      if !$keyboard.active or @keyboard_lock
        return eat_press(keys)
      end
      return false
    end
    alias eat_trigger trigger?
    def trigger?(keys)
      if keys == Input::Key['Mouse Left'] or (keys.is_a?(Array) && keys.include?(Input::Key['Mouse Left']))
        return eat_trigger(keys)
      end
      if !$keyboard.active or @keyboard_lock
        return eat_trigger(keys)
      end
      return false
    end
    alias eat_repeat repeat?
    def repeat?(keys)
      if !$keyboard.active or @keyboard_lock
        return eat_repeat(keys)
      end
      return false
    end
    alias eat_release release?
    def release?(keys)
      if !$keyboard.active or @keyboard_lock
        return eat_release(keys)
      end
      return false
    end
    
  end #class << self END
  
end
