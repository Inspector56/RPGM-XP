
class Button
end
class Dragable < Button
end

#IMPORTANT: Replace line 261 in Interpreter 3 (under "when 11 #button") with the text inside the angle brackets:
#  <result = (Input.press?(edit_extended_keys_conversion(@parameters[1])))>

#Key changes:
# - there is a key to toggle-disable the mouse, Backspace by default
# - the cursor fades and becomes disabled when invisible after a certain period of inactivity
# - most importantly, the cursor is set up to work with the "Button" class and trigger
#   on_click events and keep track of whether mouse input is being held (dragging) or not for
#   drag/release callbacks

#Note: there is still a strange bug when displaying choices sometimes

#:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=
# Mouse Controller by Blizzard
# Version: 2.2b
# Type: Custom Input System
# Date: 9.10.2009
# Date v2.0b: 22.7.2010
# Date v2.1b: 8.1.2014
# Date v2.2b: 11.1.2014
#:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=
#   
#  This work is protected by the following license:
# #----------------------------------------------------------------------------
# #  
# #  Creative Commons - Attribution-NonCommercial-ShareAlike 3.0 Unported
# #  ( http://creativecommons.org/licenses/by-nc-sa/3.0/ )
# #  
# #  You are free:
# #  
# #  to Share - to copy, distribute and transmit the work
# #  to Remix - to adapt the work
# #  
# #  Under the following conditions:
# #  
# #  Attribution. You must attribute the work in the manner specified by the
# #  author or licensor (but not in any way that suggests that they endorse you
# #  or your use of the work).
# #  
# #  Noncommercial. You may not use this work for commercial purposes.
# #  
# #  Share alike. If you alter, transform, or build upon this work, you may
# #  distribute the resulting work only under the same or similar license to
# #  this one.
# #  
# #  - For any reuse or distribution, you must make clear to others the license
# #    terms of this work. The best way to do this is with a link to this web
# #    page.
# #  
# #  - Any of the above conditions can be waived if you get permission from the
# #    copyright holder.
# #  
# #  - Nothing in this license impairs or restricts the author's moral rights.
# #  
# #----------------------------------------------------------------------------
# 
#:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=
# 
# Compatibility:
# 
#   90% compatible with SDK v1.x. 80% compatible with SDK v2.x. May cause
#   incompatibility issues with other custom input Systems. Works with "Custom
#   Game Controls" from Tons of Add-ons and Blizz-ABS's custom controls.
#   This script is not meant to be used as a standalone but rather in
#   combination with special menus that are properly adapted to support a mouse
#   controller system.
#   
#   
# Features:
# 
#   - fully automated mouse control in game
#   - can be enhanced with "Custom Game Controls" from Tons of Add-ons
#   - can be enhanced with "Blizz-ABS Controls"
#   - can be enhanced with "RMX-OS"
# 
# new in 2.0b:
# 
#   - added option to hide Windows' cursor
#   - added possibility to hide and show the ingame cursor during the game
#   - added possibility to change the cursor icon
#   - added several new options
#   - optimized
# 
# new in 2.1b:
# 
#   - added support for .cur and .ani cursor files instead of sprites
#   - changed code to use system cursor rather than a sprite to greatly
#     increase performance
# 
# new in 2.2b:
# 
#   - removed hardware cursor support due to problems with display in
#     fullscreen (which cannot be fixed)
#   - added option to specify a custom game name if Game.ini is not present
# 
# 
# Instructions:
# 
# - Explanation:
# 
#   This script can work as a stand-alone for window option selections. To be
#   able to use the mouse buttons, you need a custom Input module. The
#   supported systems are "Custom Game Controls" from Tons of Add-ons,
#   Blizz-ABS Custom Controls and RMX-OS Custom Controls. This script will
#   automatically detect and apply the custom input modules' configuration
#   which is optional.
#   
# - Configuration:
# 
#   MOUSE_ICON          - the default filename of the icon located in the
#                         Graphics/Pictures folder
#   APPLY_BORDERS       - defines whether the ingame cursor can go beyond the
#                         game window borders
#   WINDOW_WIDTH        - defines the window width, required only when using
#                         APPLY_BORDER
#   WINDOW_HEIGHT       - defines the window height, required only when using
#                         APPLY_BORDER
#   HIDE_WINDOWS_CURSOR - hides the Windows Cursor on the window by default
#   AUTO_CONFIGURE      - when using "Custom Game Controls" from Tons of
#                         Add-ons, Blizz-ABS or RMX-OS, this option will
#                         automatically add the left mouse button as
#                         confirmation button
#   CUSTOM_GAME_NAME    - specify a custom game name here if Game.ini is not
#                         present (simply use the name from the original
#                         Game.ini)
#   
# - Script Calls:
#   
#   You can use a few script calls to manipulate the cursor. Keep in mind that
#   these changes are not being saved with the save file.
#   
#   To hide the ingame Mouse Cursor, use following call.
#   
#     $mouse.hide
#   
#   To show the ingame Mouse Cursor, use following call.
#   
#     $mouse.show
#   
#   To change the cursor image, use following call. Make sure your image is in
#   the Graphics/Pictures folder.
#   
#     $mouse.set_cursor('IMAGE_NAME')
#   
#   
# Additional Information:
#   
#   Even though there is an API call to determine the size of the window, API
#   calls are CPU expensive so the values for the window size need to be
#   configured manually in this script.
#   
# 
# If you find any bugs, please report them here:
# http://forum.chaos-project.com
#:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=:=

$mouse_controller = 2.2

#just to get Mouse_Controller to work, not what this is supposed to be:
$BlizzABS_INPUT_loaded = true


module Input
  
  #----------------------------------------------------------------------------
  # Simple ASCII table
  #----------------------------------------------------------------------------
  Key = {'A' => 65, 'B' => 66, 'C' => 67, 'D' => 68, 'E' => 69, 'F' => 70, 
         'G' => 71, 'H' => 72, 'I' => 73, 'J' => 74, 'K' => 75, 'L' => 76, 
         'M' => 77, 'N' => 78, 'O' => 79, 'P' => 80, 'Q' => 81, 'R' => 82, 
         'S' => 83, 'T' => 84, 'U' => 85, 'V' => 86, 'W' => 87, 'X' => 88, 
         'Y' => 89, 'Z' => 90,
         '0' => 48, '1' => 49, '2' => 50, '3' => 51, '4' => 52, '5' => 53,
         '6' => 54, '7' => 55, '8' => 56, '9' => 57,
         'NumberPad 0' => 45, 'NumberPad 1' => 35, 'NumberPad 2' => 40,
         'NumberPad 3' => 34, 'NumberPad 4' => 37, 'NumberPad 5' => 12,
         'NumberPad 6' => 39, 'NumberPad 7' => 36, 'NumberPad 8' => 38,
         'NumberPad 9' => 33,
         'F1' => 112, 'F2' => 113, 'F3' => 114, 'F4' => 115, 'F5' => 116,
         'F6' => 117, 'F7' => 118, 'F8' => 119, 'F9' => 120, 'F10' => 121,
         'F11' => 122, 'F12' => 123,
         ';' => 186, '=' => 187, ',' => 188, '-' => 189, '.' => 190, '/' => 220,
         '\\' => 191, '\'' => 222, '[' => 219, ']' => 221, '`' => 192,
         'Backspace' => 8, 'Tab' => 9, 'Enter' => 13, 'Shift' => 16,
         'Left Shift' => 160, 'Right Shift' => 161, 'Left Ctrl' => 162,
         'Right Ctrl' => 163, 'Left Alt' => 164, 'Right Alt' => 165, 
         'Ctrl' => 17, 'Alt' => 18, 'Esc' => 27, 'Space' => 32, 'Page Up' => 33,
         'Page Down' => 34, 'End' => 35, 'Home' => 36, 'Insert' => 45,
         'Delete' => 46, 'Arrow Left' => 37, 'Arrow Up' => 38,
         'Arrow Right' => 39, 'Arrow Down' => 40,
         'Mouse Left' => 1, 'Mouse Right' => 2, 'Mouse Middle' => 4,
         'Mouse 4' => 5, 'Mouse 5' => 6}
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# START Configuration
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  UP = [Key['Arrow Up']]
  LEFT = [Key['Arrow Left']]
  DOWN = [Key['Arrow Down']]
  RIGHT = [Key['Arrow Right']]
  A = [Key['Shift']]
  B = [Key['Esc'], Key['NumberPad 0'], Key['X']]
  C = [Key['Space'], Key['Enter'], Key['C']]
  X = [Key['A']]
  Y = [Key['S']]
  Z = [Key['D']]
  L = [Key['Q'], Key['Page Down']]
  R = [Key['W'], Key['Page Up']]
  F5 = [Key['F5']]
  F6 = [Key['F6']]
  F7 = [Key['F7']]
  F8 = [Key['F8']]
  F9 = [Key['F9']]
  SHIFT = [Key['Shift']]
  CTRL = [Key['Ctrl']]
  ALT = [Key['Alt']]
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# END Configuration
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  # All keys
  ALL_KEYS = (0...256).to_a
  # Win32 API calls
  GetKeyboardState = Win32API.new('user32','GetKeyboardState', 'P', 'I')
  GetKeyboardLayout = Win32API.new('user32', 'GetKeyboardLayout','L', 'L')
  MapVirtualKeyEx = Win32API.new('user32', 'MapVirtualKeyEx', 'IIL', 'I')
  ToUnicodeEx = Win32API.new('user32', 'ToUnicodeEx', 'LLPPILL', 'L')
  # some other constants
  DOWN_STATE_MASK = 0x80
  DEAD_KEY_MASK = 0x80000000
  # data
  @state = "\0" * 256
  @triggered = Array.new(256, false)
  @pressed = Array.new(256, false)
  @released = Array.new(256, false)
  @repeated = Array.new(256, 0)
  #----------------------------------------------------------------------------
  # update
  #  Updates input.
  #----------------------------------------------------------------------------
  def self.update
    # prevents usage with Blizz-ABS
    if $BlizzABS
      # error message
      raise 'Blizz-ABS was detected! Please turn off Custom Controls in Tons of Add-ons!'
    end
    # get current language layout
    @language_layout = GetKeyboardLayout.call(0)
    # get new keyboard state
    GetKeyboardState.call(@state)
    # for each key
    ALL_KEYS.each {|key|
        # if pressed state
        if @state[key] & DOWN_STATE_MASK == DOWN_STATE_MASK
          # not released anymore
          @released[key] = false
          # if not pressed yet
          if !@pressed[key]
            # pressed and triggered
            @pressed[key] = true
            @triggered[key] = true
          else
            # not triggered anymore
            @triggered[key] = false
          end
          # update of repeat counter
          @repeated[key] < 17 ? @repeated[key] += 1 : @repeated[key] = 15
        # not released yet
        elsif !@released[key]
          # if still pressed
          if @pressed[key]
            # not triggered, pressed or repeated, but released
            @triggered[key] = false
            @pressed[key] = false
            @repeated[key] = 0
            @released[key] = true
          end
        else
          # not released anymore
          @released[key] = false
        end}
  end
  #----------------------------------------------------------------------------
  # dir4
  #  4 direction check.
  #----------------------------------------------------------------------------
  def Input.dir4
    return 2 if Input.press?(DOWN)
    return 4 if Input.press?(LEFT)
    return 6 if Input.press?(RIGHT)
    return 8 if Input.press?(UP)
    return 0
  end
  #----------------------------------------------------------------------------
  # dir8
  #  8 direction check.
  #----------------------------------------------------------------------------
  def Input.dir8
    down = Input.press?(DOWN)
    left = Input.press?(LEFT)
    return 1 if down && left
    right = Input.press?(RIGHT)
    return 3 if down && right
    up = Input.press?(UP)
    return 7 if up && left
    return 9 if up && right
    return 2 if down
    return 4 if left
    return 6 if right
    return 8 if up
    return 0
  end
  #----------------------------------------------------------------------------
  # trigger?
  #  Test if key was triggered once.
  #----------------------------------------------------------------------------
  def Input.trigger?(keys)
    keys = [keys] unless keys.is_a?(Array)
    return keys.any? {|key| @triggered[key]}
  end
  #----------------------------------------------------------------------------
  # press?
  #  Test if key is being pressed.
  #----------------------------------------------------------------------------
  def Input.press?(keys)
    keys = [keys] unless keys.is_a?(Array)
    return keys.any? {|key| @pressed[key]}
  end
  #----------------------------------------------------------------------------
  # repeat?
  #  Test if key is being pressed for repeating.
  #----------------------------------------------------------------------------
  def Input.repeat?(keys)
    keys = [keys] unless keys.is_a?(Array)
    return keys.any? {|key| @repeated[key] == 1 || @repeated[key] == 16}
  end
  #----------------------------------------------------------------------------
  # release?
  #  Test if key was released.
  #----------------------------------------------------------------------------
  def Input.release?(keys)
    keys = [keys] unless keys.is_a?(Array)
    return keys.any? {|key| @released[key]}
  end
  #----------------------------------------------------------------------------
  # get_character
  #  vk - virtual key
  #  Gets the character from keyboard input using the input locale identifier
  #  (formerly called keyboard layout handles).
  #----------------------------------------------------------------------------
  def self.get_character(vk)
    # get corresponding character from virtual key
    c = MapVirtualKeyEx.call(vk, 2, @language_layout)
    # stop if character is non-printable and not a dead key
    return '' if c < 32 && (c & DEAD_KEY_MASK != DEAD_KEY_MASK)
    # get scan code
    vsc = MapVirtualKeyEx.call(vk, 0, @language_layout)
    # result string is never longer than 2 bytes (Unicode)
    result = "\0" * 2
    # get input string from Win32 API
    length = ToUnicodeEx.call(vk, vsc, @state, result, 2, 0, @language_layout)
    return (length == 0 ? '' : result)
  end
  #----------------------------------------------------------------------------
  # get_input_string
  #  Gets the string that was entered using the keyboard over the input locale
  #  identifier (formerly called keyboard layout handles).
  #----------------------------------------------------------------------------
  def self.get_input_string
    result = ''
    # check every key
    ALL_KEYS.each {|key|
        # if repeated
        if self.repeat?(key)
          # get character from keyboard state
          c = self.get_character(key)
          # add character if there is a character
          result += c if c != ''
        end}
    # empty if result is empty
    return '' if result == ''
    # convert string from Unicode to UTF-8
    return self.unicode_to_utf8(result)
  end
  #----------------------------------------------------------------------------
  # get_input_string
  #  string - string in Unicode format
  #  Converts a string from Unicode format to UTF-8 format as RGSS does not
  #  support Unicode.
  #----------------------------------------------------------------------------
  def self.unicode_to_utf8(string)
    result = ''
    string.unpack('S*').each {|c|
        # characters under 0x80 are 1 byte characters
        if c < 0x0080
          result += c.chr
        # other characters under 0x800 are 2 byte characters
        elsif c < 0x0800
          result += (0xC0 | (c >> 6)).chr
          result += (0x80 | (c & 0x3F)).chr
        # the rest are 3 byte characters
        else
          result += (0xE0 | (c >> 12)).chr
          result += (0x80 | ((c >> 12) & 0x3F)).chr
          result += (0x80 | (c & 0x3F)).chr
        end}
    return result
  end

end

module Input
  Key = Key.merge({'Mouse Left' => 1, 'Mouse Right' => 2, 'Mouse Middle' => 4,
         'Mouse 4' => 5, 'Mouse 5' => 6})
end

#===============================================================================
# Mouse
#===============================================================================

class Mouse
  
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# START Configuration
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  MOUSE_ICON = 'cursor'
  MOUSE_DRAG = 'cursor_held' #edit
  APPLY_BORDERS = true
  WINDOW_WIDTH = $SCREEN_WIDTH
  WINDOW_HEIGHT = $SCREEN_HEIGHT
  HIDE_WINDOWS_CURSOR = true
  AUTO_CONFIGURE = true
  CUSTOM_GAME_NAME = ''
  
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# END Configuration
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  
  if HIDE_WINDOWS_CURSOR
    Win32API.new('user32', 'ShowCursor', 'i', 'i').call(0)
  end
  
  #finally found Win32API for ref:
  #http://www.jasinskionline.com/windowsapi/ref/funca.html
  #and key codes:
  #http://cherrytree.at/misc/vk.htm
  
  FADE_TIME = 360
  
  SCREEN_TO_CLIENT = Win32API.new('user32', 'ScreenToClient', %w(l p), 'i')
  READ_INI = Win32API.new('kernel32', 'GetPrivateProfileStringA', %w(p p p p l p), 'l')
  FIND_WINDOW = Win32API.new('user32', 'FindWindowA', %w(p p), 'l')
  CURSOR_POSITION = Win32API.new('user32', 'GetCursorPos', 'p', 'i')
  
  def initialize
    @cursor = Sprite.new
    @cursor.z = 1000000
    self.set_cursor(MOUSE_ICON)
    hide #edited
    @active = false #edited
    @hidden = HIDE_WINDOWS_CURSOR #edited
    @disabled = false #edited
    @dragging = false #edited
    @restore = false
    update
  end
  
  def update
    @cursor.x, @cursor.y = self.position
    holding = false
    #check if we are dragging anything
    if $mouse_held && $moused_over
      for button in $moused_over
        if button.is_a?(Dragable)
          holding = true
        end
      end
    end
    #if we were dragging and now aren't, or weren't and now are, change the sprite
    if holding
      if !@dragging
        self.set_cursor(MOUSE_DRAG)
        @dragging = true
      end
    else
      if @dragging
        self.set_cursor(MOUSE_ICON)
        @dragging = false
      end
    end
    #check for cursor movement
    if ((@last_x != @cursor.x) or (@last_y != @cursor.y)) && (!@disabled)
      @last_x, @last_y = @cursor.x, @cursor.y
      @timer = FADE_TIME
      @active = true
    else
      if @timer == 0 or @disabled
        @cursor.opacity = [@cursor.opacity - 20, 0].max
        @active = false
      elsif @timer > 0
        @cursor.opacity = [@cursor.opacity + 80, 255].min
        @timer -= 1
      end
    end
  end
  
  def x
    return @cursor.x   + @x_offset#edited
  end
  
  def y
    return @cursor.y
  end
  
  #added x-offset
  def position
    x_offset = @x_offset ? @x_offset : 0
    x, y = self.get_client_position
    if APPLY_BORDERS
      if x < 0   - x_offset
        x = 0    - x_offset
      elsif x >= WINDOW_WIDTH     - x_offset
        x = WINDOW_WIDTH - 1     - x_offset
      end
      if y < 0
        y = 0
      elsif y >= WINDOW_HEIGHT
        y = WINDOW_HEIGHT - 1
      end
    end
    return x, y
  end
  
  def get_client_position
    pos = [0, 0].pack('ll')
    CURSOR_POSITION.call(pos)
    SCREEN_TO_CLIENT.call(WINDOW, pos)
    return pos.unpack('ll')
  end
  
  def set_cursor(filename)
    @cursor.bitmap = RPG::Cache.picture(filename)
    @x_offset = 0#(@cursor.bitmap.width / 2) #edit: uncomment if you want the cursor centered horizontally
  end
  
  def show
    @cursor.visible = true
    if !@hidden #edit
      Win32API.new('user32', 'ShowCursor', 'i', 'i').call(0)
    end
  end
  
  def hide
    @cursor.visible = false
    if @hidden #edit
      Win32API.new('user32', 'ShowCursor', 'i', 'i').call(1)
    end
  end
  
  def self.find_window
    if CUSTOM_GAME_NAME == ''
      game_name = "\0" * 256
      READ_INI.call('Game', 'Title', '', game_name, 255, '.\\Game.ini')
      game_name.delete!("\0")
    else
      game_name = CUSTOM_GAME_NAME
    end
    return FIND_WINDOW.call('RGSS Player', game_name)
  end
  
  WINDOW = self.find_window
  
  #edit
  def active
    return @active
  end
  def set_active
    @active = true
    show
  end
  def deactivate
    @active = false
    hide
  end
  def toggle_disable(restore = false)
    @disabled = !@disabled
    @restore = restore
    if !@disabled
      @restore = false
    end
  end
  def disabled?
    return @disabled
  end
  def restore?
    return @restore
  end
  
end

$mouse = Mouse.new

#edit
class Game_System
  alias show_mouse_on_title_load initialize
  def initialize
    show_mouse_on_title_load
    $mouse.show
    $mouse.set_active
  end
end
module Input
  class << self
    alias mouse_hide_unhide_update update
  end
  def self.update
    if Input.trigger?(Input::Key['Backspace']) #Pick mouse toggle key
      $mouse.toggle_disable if $mouse
    end
    mouse_hide_unhide_update
  end
end
class Game_Map
  alias make_mouse_reappear_setup setup
  def setup(map_id)
    make_mouse_reappear_setup(map_id)
    if $mouse && $mouse.disabled? && $mouse.restore? && !self.is_a?(Skeleton_Map)
      $mouse.toggle_disable
    end
  end
end

#==============================================================================
# module Input
#==============================================================================

module Input
  
  class << Input
    alias update_mousecontroller_later update
  end
  
  def self.update
    $mouse.update
    if Input::trigger?(Input::Key['Mouse Left'])
      $moused_over.each {|button| button.on_click }
    end
    if Input::press?(Input::Key['Mouse Left']) or Input::repeat?(Input::Key['Mouse Left'])
      $mouse_held = true
    else
      $mouse_held = false
    end
    update_mousecontroller_later
  end
  
  if Mouse::AUTO_CONFIGURE
    if $BlizzABS_INPUT_loaded
      #You may want to mess around with or change this
      C.push(Input::Key['Mouse Left']) if !C.include?(Input::Key['Mouse Left'])
      if !Attack.include?(Input::Key['Mouse Right'])
        Attack.push(Input::Key['Mouse Right'])
      end
    elsif $tons_version != nil && $tons_version >= 6.4 &&
        TONS_OF_ADDONS::CUSTOM_CONTROLS || defined?(RMXOS)
      C.push(Input::Key['Mouse Left']) if !C.include?(Input::Key['Mouse Left'])
    end
  end
  
  LEFT_CLICK = [Key['Mouse Left']]
  
end


#===============================================================================
# Rect
#===============================================================================

  def covers?(obj, x, y)
    return !(x < obj.x || x >= obj.x + obj.width ||
        y < obj.y || y >= obj.y + obj.height)
  end

class Rect
  
  def covers?(x, y)
    return !(x < self.x || x >= self.x + self.width ||
        y < self.y || y >= self.y + self.height)
  end
  
end

#===============================================================================
# Sprite
#===============================================================================

class Sprite
  
  def mouse_in_area?
    return false if !$mouse.active #edit
    return false if self.bitmap == nil
    return ($mouse.x >= self.x && $mouse.x < self.x + self.src_rect.width &&
        $mouse.y >= self.y && $mouse.y < self.y + self.src_rect.height)
  end
  
  def covers?
    if mouse_in_area?
      if self.bitmap.get_pixel($mouse.x, $mouse.y).alpha > 0
        return true
      end
    end
    return false
  end
  
end

class Scene_Map
  def mouse_over_pic(pic_num)
    if @spriteset
      return @spriteset.mouse_over_pic(pic_num)
    end
    return false
  end
end

class Spriteset_Map
  def mouse_over_pic(pic_num)
    if @picture_sprites
      return @picture_sprites[pic_num].covers?
    end
    return false
  end
end

#===============================================================================
# Window_Base
#===============================================================================

class Window_Base
  
  def mouse_in_area?
    return false if !$mouse.active #edit
    return ($mouse.x >= self.x && $mouse.x < self.x + self.width &&
        $mouse.y >= self.y && $mouse.y < self.y + self.height)
  end
  
  def mouse_in_inner_area?
    return false if !$mouse.active #edit
    return ($mouse.x >= self.x + 16 && $mouse.x < self.x + self.width - 16 &&
        $mouse.y >= self.y + 16 && $mouse.y < self.y + self.height - 16)
  end
  
end

#===============================================================================
# Window_Selectable
#===============================================================================

class Window_Selectable
  
  alias contents_is_mousecontroller_later contents=
  def contents=(bitmap)
    contents_is_mousecontroller_later(bitmap)
    begin
      update_selections
      update_mouse if (self.active && $mouse.active)
    rescue
    end
  end
  
  alias index_is_mousecontroller_later index=
  def index=(value)
    index_is_mousecontroller_later(value)
    update_selections
  end
  
  alias active_is_mousecontroller_later active=
  def active=(value)
    active_is_mousecontroller_later(value)
    if !self.is_a?(Window_Message) then update_cursor_rect end
    #if !self.is_a?(Window_Message) && !self.is_a?(Window_Choice) then update_cursor_rect end #update_cursor_rect
    #if self.is_a?(Window_Choice) && has_choices? then refresh end
  end
  
  def update_selections
    @selections = []
    index, ox, oy = self.index, self.ox, self.oy
    (0...@item_max).each {|i|
        @index = i
        if !self.is_a?(Window_Message) then update_cursor_rect end
        #if !self.is_a?(Window_Message) && !self.is_a?(Window_Choice) then update_cursor_rect end #update_cursor_rect
        #if self.is_a?(Window_Choice) && has_choices? then refresh end
          rect = self.cursor_rect.clone
        rect.x += self.ox
        rect.y += self.oy
        @selections.push(rect)}
    @index, self.ox, self.oy = index, ox, oy
    self.cursor_rect.empty
  end
  
  alias update_mousecontroller_later update
  def update
    update_mouse if self.active
    update_mousecontroller_later
  end
  
  def update_mouse
    if self.mouse_in_inner_area?
      update_mouse_selection
      return
    end
    #self.index = -1
    if self.contents != nil && @selections.size > 0 && self.mouse_in_area?
      update_mouse_scrolling
    end
  end
  
  def update_mouse_selection
    update_selections if @selections.size != @item_max
    @selections.each_index {|i|
        #if @selections[i].covers?($mouse.x - self.x - 16 + self.ox,
        #    $mouse.y - self.y - 16 + self.oy)
            
        if covers?(@selections[i], $mouse.x - self.x - 16 + self.ox,
            $mouse.y - self.y - 16 + self.oy)
            if self.index != i
              self.index = i
              $game_system.se_play($data_system.cursor_se)
            end
          return
        end}
    #self.index = -1
  end
  
  def update_mouse_scrolling
    if Input.repeat?(Input::C)
      if $mouse.x < self.x + 16
        if self.ox > 0
          $game_system.se_play($data_system.cursor_se)
          self.ox -= @selections[0].width
          self.ox = 0 if self.ox < 0
        end
      elsif $mouse.x >= self.x + self.width - 16
        max_ox = self.contents.width - self.width + 32
        if self.ox <= max_ox
          $game_system.se_play($data_system.cursor_se)
          self.ox += @selections[0].width
          self.ox = max_ox if self.ox >= max_ox
        end
      elsif $mouse.y < self.y + 16
        if self.oy > 0
          $game_system.se_play($data_system.cursor_se)
          self.oy -= @selections[0].height
          self.oy = 0 if self.oy < 0
        end
      elsif $mouse.y >= self.y + self.height - 16
        max_oy = self.contents.height - self.height + 32
        if self.oy <= max_oy
          $game_system.se_play($data_system.cursor_se)
          self.oy += @selections[0].height
          self.oy = max_oy if self.oy >= max_oy
        end
      end
    end
  end
  
end

class Window_Choice
  def has_choices?
    return @choices && (@choices != [])
  end
end

def edit_extended_keys_conversion(base_game_key_code)
  case base_game_key_code
  when 2 #DOWN
    return Input::DOWN
  when 4 #LEFT
    return Input::LEFT
  when 6 #RIGHT
    return Input::RIGHT
  when 8 #UP
    return Input::UP
  when 11 #A
    return Input::A
  when 12 #B
    return Input::B
  when 13 #C
    return Input::C
  when 14 #X
    return Input::X
  when 15 #Y
    return Input::Y
  when 16 #Z
    return Input::Z
  when 17 #L
    return Input::L
  when 18 #R
    return Input::R
  else #???
    return 0
  end
end
