SKILL_TREES_ENABLED = 10
#Note: for balance, try to make all of the base stats add to 12
#FP cannot be upgraded. ATK, PDEF, and MDEF come solely from equipment and cannot
#be upgraded.
#HP: Constitution. Max_hp = step[HP_LVL]
$HP_STEP = { 0 => 100, 1 => 150, 2 => 200, 3 => 250, 4 => 300, 5 => 400,
  6 => 500, 7 => 600, 8 => 700, 9 => 800, 10 => 900, 11 => 1050,
  12 => 1200, 13 => 1350, 14 => 1500, 15 => 1650, 16 => 1800, 17 => 1950,
  18 => 2100, 19 => 2250, 20 => 2400
};
def sum(array)
  sum = 0
  for item in array
    sum += item
  end
  return sum
end
#SP: Mana. Max_sp = 50*SP
#STR: Strength. Increases damage of melee attacks and improves grappling.
#DEX: Dexterity/Finesse. Diminishes effects of distance/range and scales damage on certain weapons/skills.
#AGI: Agility. Increases CP generation rate (ie, actions per second) and reduces CP cost of using Move.
#INT: Intelligence. Boosts healing/damage effects of spells.
#CHR: Charisma. Unlocks dialogue options/persuasions.
#SNK: Sneak/Scoundrel. Make less sound
$base_stats = {
    #Actor => [HP, SP, STR, DEX, AGI, INT, CHR, SNK]
    'Harold' => [3, 2, 4, 1, 2, 0, 0, 0]
    #etc
};

#TODO: rewrite display hp, sp, and fp so that 1) they turn green when upgrading
# and 2) the numbers actually change when upgrading and 3) the x lines up
#ALSO: display number of points available
#ALSO: play with x spacing... reduce on the left, increase on right?

class Game_System
  attr_accessor   :stats
  
  alias lstat_gs_init initialize
  def initialize
	lstat_gs_init
	for actor in $base_stats.keys
		init_stats(actor)
	end
  end
  
  def init_stats(s_actor)
    if @stats == nil
      @stats = Marshal.load(Marshal.dump($base_stats))
    else
      for actor in $game_party.actors()
        if $data_actors[actor.actor_id].name == s_actor
          @stats[s_actor] = Marshal.load(Marshal.dump($base_stats[s_actor]))
        end
      end
    end
  end
end

class Game_Party
  
  alias lvlstat_add_actor add_actor
  def add_actor(actor_id)
    name = $data_actors[actor_id].name
    if $game_switches[SKILL_TREES_ENABLED]
      if !$game_system.stats or !$game_system.stats.has_key?(name)
        $game_system.init_stats(name)
      end
    end
    lvlstat_add_actor(actor_id)
  end
end

class Game_Battler
  
  def libname
    if self.is_a?(Game_Actor)
      return $data_actors[self.actor_id].name
    else
      return $data_enemies[self.enemy_id].name
    end
  end
  def use_level_stats
    return (self.is_a?(Game_Actor) and $game_switches and $game_switches[SKILL_TREES_ENABLED] and $game_system and $game_system.stats and $game_system.stats.has_key?(libname))
  end
  
end
class Game_Actor
  
  def maxhp!
    return $game_system.stats[libname][0]
  end
  alias old_base_maxhp base_maxhp
  def base_maxhp
    if !use_level_stats
      return old_base_maxhp
    end
    n = $HP_STEP[maxhp!]
    return n
  end
  
  def maxsp!
    return $game_system.stats[libname][1]
  end
  alias old_base_maxsp base_maxsp
  def base_maxsp
    if !use_level_stats
      return old_base_maxsp
    end
    n = maxsp! * 50
    return n
  end
  
  def str!
    return $game_system.stats[libname][2]
  end
  alias old_base_str base_str
  def base_str
    if !use_level_stats
      return old_base_str
    end
    n = str! * 45 + 50
    return n
  end

  def dex!
    return $game_system.stats[libname][3]
  end
  alias old_base_dex base_dex
  def base_dex
    if !use_level_stats
      return old_base_dex
    end
    n = dex! * 45 + 50
    return n
  end
  
  def agi!
    return $game_system.stats[libname][4]
  end
  alias old_base_agi base_agi
  def base_agi
    if !use_level_stats
      return old_base_agi
    end
    n = agi! * 45 + 50
    return n
  end
  
  def int!
    return $game_system.stats[libname][5]
  end
  alias old_base_int base_int
  def base_int
    if !use_level_stats
      return old_base_int
    end
    n = int! * 45 + 50 #might actually not want to add the 50 for INT
    return n
  end
  
  def chr!
    return $game_system.stats[libname][6]
  end
  def chr
    if use_level_stats
      n = chr!
      for i in @states
        if $state_properties.has_key?($data_states[i].name) && $state_properties[$data_states[i].name].has_key?("chr_mod")
          n += $state_properties[$data_states[i].name]["chr_mod"]
        end
      end
      return n
    end
    return 0
  end
  
  def snk!
    $game_system.stats[libname][7]
  end
  def snk
    if use_level_stats
      for i in @states
        if $state_properties.has_key?($data_states[i].name) && $state_properties[$data_states[i].name].has_key?("snk_mod")
          n += $state_properties[$data_states[i].name]["snk_mod"]
        end
      end
      n = snk!
      return n
    end
    return 0
  end
  
end

#==============================================================================
# ** Scene_Status
#------------------------------------------------------------------------------
#  This class performs status screen processing.
#==============================================================================

class Scene_Status

  #--------------------------------------------------------------------------
  # * Object Initialization
  #     actor_index : actor index
  #--------------------------------------------------------------------------
  def initialize(actor_index = 0, equip_index = 0)
    @actor_index = actor_index
    @inputing = false
  end
  #--------------------------------------------------------------------------
  # * Main Processing
  #--------------------------------------------------------------------------
  alias lvlstat_main main
  def main
    if !$game_switches[SKILL_TREES_ENABLED]
      lvlstat_main
    else
      # Get actor
      @actor = $game_party.actors[@actor_index]
      name = @actor.libname
      if ($game_system.stats == nil) or (!$game_system.stats.has_key?(name))
        $game_system.init_stats(name)
      end
      @stats = $game_system.stats[name]
      @index = 0
      #start at level one, get one point; sum of current - initial = used
      @points = (@actor.level - 1) - (sum(@stats) - sum($base_stats[name]))
      @tmp_points = [0,0,0,0,0,0,0,0]
      # Make status window
      @status_window = Window_Status.new(@actor)
      @choice = Window_Command.new(70, ["Yes", "No"])
      @choice.visible = false
      @choice.active = false
      @choice.x = 280
      @choice.y = 192
      @choice.z = 300
      @choice.back_opacity = 160
      # Execute transition
      Graphics.transition
      # Main loop
      loop do
        # Update game screen
        Graphics.update
        # Update input information
        Input.update
        # Frame update
        update
        # Abort loop if screen is changed
        if $scene != self
          #when we leave, don't let them keep unspent points ;P
          for i in 0...@stats.length
            @stats[i] -= @tmp_points[i]
          end
          break
        end
      end
      # Prepare for transition
      Graphics.freeze
      # Dispose of windows
      @status_window.dispose
      @choice.dispose
    end
  end
  
  alias lvlstat_update update
  def update
    if !$game_switches[SKILL_TREES_ENABLED]
      lvlstat_update
    else
      # If B button was pressed
      if Input.trigger?(Input::B)
        # Play cancel SE
        $game_system.se_play($data_system.cancel_se)
        # Switch to menu screen
        $scene = Scene_Menu.new(3)
        return
      end
      
      if @inputing
        if Input.trigger?(Input::C)
          if @confirming #confirm input points
            @confirming = false
            @choice.active = false
            @choice.visible = false
            @top.dispose
            if @choice.index == 0
              $game_system.se_play($data_system.decision_se)
              @inputing = false
              @tmp_points = [0,0,0,0,0,0,0,0]
              @index = -1
              @status_window.update_cursor(@index)
              @status_window.lvl_up
              @status_window.refresh
            else
              $game_system.se_play($data_system.cancel_se)
            end
          else
            if sum(@tmp_points) == 0
              $game_system.se_play($data_system.cancel_se)
              @inputing = false
              @index = -1
              @status_window.update_cursor(@index)
              @status_window.refresh
              return
            end
            $game_system.se_play($data_system.decision_se)
            @choice.active = true
            @choice.visible = true
            confirm_level_up
            @confirming = true
          end
          return
        end
        if Input.trigger?(Input::RIGHT)
          if (@points == 0) or (@stats[@index] >= 20)
            $game_system.se_play($data_system.buzzer_se)
          else
            $game_system.se_play($data_system.decision_se)
            @points -= 1
            @stats[@index] += 1
            @tmp_points[@index] += 1
            @status_window.update_cursor(@index)
            @status_window.refresh
          end
          return
        end
        if Input.trigger?(Input::LEFT)
          if (@tmp_points[@index] == 0)
            $game_system.se_play($data_system.buzzer_se)
          else
            $game_system.se_play($data_system.decision_se)
            @points += 1
            @stats[@index] -= 1
            @tmp_points[@index] -= 1
            @status_window.update_cursor(@index)
            @status_window.refresh
          end
          return
        end
        if Input.trigger?(Input::DOWN)
          $game_system.se_play($data_system.decision_se)
          if @index == 7
            @index = 0
          else
            @index += 1
          end
          @status_window.update_cursor(@index)
          @status_window.refresh
          return
        end
        if Input.trigger?(Input::UP)
          $game_system.se_play($data_system.decision_se)
          if @index == 0
            @index = 7
          else
            @index -= 1
          end
          @status_window.update_cursor(@index)
          @status_window.refresh
          return
        end
      else
        if Input.trigger?(Input::C)
          $game_system.se_play($data_system.decision_se)
          @inputing = true
          @index = 0
          @status_window.update_cursor(@index)
          @status_window.refresh
        end
      end
      # If R button was pressed
      if Input.trigger?(Input::R) and !@inputing
        @index = -1
        # Play cursor SE
        $game_system.se_play($data_system.cursor_se)
        # To next actor
        @actor_index += 1
        @actor_index %= $game_party.actors.size
        # Switch to different status screen
        $scene = Scene_Status.new(@actor_index)
        return
      end
      # If L button was pressed
      if Input.trigger?(Input::L) and !@inputing
        @index = -1
        # Play cursor SE
        $game_system.se_play($data_system.cursor_se)
        # To previous actor
        @actor_index += $game_party.actors.size - 1
        @actor_index %= $game_party.actors.size
        # Switch to different status screen
        $scene = Scene_Status.new(@actor_index)
        return
      end
    end
  end
  
  def confirm_level_up
    view = Viewport.new(0, 0, 640, 480)
    view.z = 250
    @top = RPG::Sprite.new(view)
    @top.bitmap = Bitmap.new(640, 480)
    @top.bitmap.fill_rect(0, 0, 640, 480, Color.new(0,0,0,180))
    @top.bitmap.font.name = 'Arial'
    @top.bitmap.font.size = 24
    @top.bitmap.font.color = Color.new(250, 250, 250)
    @top.bitmap.draw_text(222, 130, 200, 40, "Confirm level up?", 1)
    @choice.active = true
    @choice.visible = true
  end
end

class Window_Status < Window_Base
  
  def update_cursor(index)
    if index < 0
      self.cursor_rect.empty
      return
    end
    # Calculate cursor width
    cursor_width = 212
    # Calculate cursor coordinates
    x = 90
    y = 0
    case index
    when 0
      y = 112
    when 1
      y = 136
    when 2
      y = 270
    when 3
      y = 296
    when 4
      y = 320
    when 5
      y = 344
    when 6
      y = 368
      cursor_width = 152
    when 7
      y = 392
      cursor_width = 152
    end
    # Update cursor rectangle
    self.cursor_rect.set(x, y, cursor_width, 32)
  end
  
  def draw_actor_stat(actor, x, y, type)
    libname = actor.libname
    case type
    when "hp"
      old = @initial[0]
      parameter_name = "HP"
      parameter_stat = actor.hp
      parameter_value = actor.base_maxhp
    when "sp"
      old = @initial[1]
      parameter_name = "SP"
      parameter_stat = actor.sp
      parameter_value = actor.base_maxsp
    when "fp"
      parameter_name = "FP"
      parameter_stat = actor.fp
      parameter_value = actor.maxfp
      old = parameter_value #can't affect fp
    when "atk"
      old = @initial[2]
      parameter_name = "ATK"
      parameter_stat = actor.atk
      parameter_value = actor.atk
    when "pdef" 
      old = @initial[3]
      parameter_name = "PDEF"
      parameter_stat = actor.pdef
      parameter_value = actor.pdef
    when "mdef" 
      old = @initial[4]
      parameter_name = "MDEF"
      parameter_stat = actor.mdef
      parameter_value = actor.mdef
    when "str"
      old = @initial[5]
      parameter_name = "STR" #$data_system.words.str
      parameter_stat = actor.str!
      parameter_value = actor.base_str
    when "dex"
      old = @initial[6]
      parameter_name = "DEX" #$data_system.words.dex
      parameter_stat = actor.dex!
      parameter_value = actor.base_dex
    when "agi"
      old = @initial[7]
      parameter_name = "AGI"
      parameter_stat = actor.agi!
      parameter_value = actor.base_agi
    when "int"
      old = @initial[8]
      parameter_name = "INT"
      parameter_stat = actor.int!
      parameter_value = actor.base_int
    when "chr"
      old = @initial[9]
      parameter_name = "CHR"
      parameter_stat = actor.chr!
      parameter_value = actor.chr
    when "snk"
      old = @initial[10]
      parameter_name = "SNK"
      parameter_stat = actor.snk!
      parameter_value = actor.snk
    end
    if !(["fp","atk","pdef","mdef"].include?(type))
      self.contents.font.color = system_color
    else
      self.contents.font.color = disabled_color
    end
    self.contents.draw_text(x, y, 100, 32, parameter_name)
    if parameter_value != old
      self.contents.font.color = Color.new(46, 228, 18)
    else
      self.contents.font.color = normal_color
    end
    self.contents.draw_text(x + 100, y, 36, 32, parameter_stat.to_s, 2)
    if !(["atk","pdef","mdef","chr","snk"].include?(type))
      if (["hp", "sp", "fp"].include?(type))
        self.contents.draw_text(x + 155, y, 10, 32, '/', 2)
      end
      self.contents.draw_text(x + 150, y, 50, 32, parameter_value.to_s, 2)
    end
  end
  
  def lvl_up
    @initial = [@actor.maxhp, @actor.maxsp, @actor.atk, @actor.pdef, @actor.mdef,
        @actor.str, @actor.dex, @actor.agi, @actor.int, @actor.chr, @actor.snk]
  end
  
  alias lvlstat_win_status_init initialize
  def initialize(actor)
    if $game_switches[SKILL_TREES_ENABLED]
      name = actor.libname
      if ($game_system.stats == nil) or (!$game_system.stats.has_key?(name))
        $game_system.init_stats(name)
      end
      @initial = [actor.maxhp, actor.maxsp, actor.atk, actor.pdef, actor.mdef,
        actor.str, actor.dex, actor.agi, actor.int, actor.chr, actor.snk]
    end
    lvlstat_win_status_init(actor)
  end
  
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  alias lvlstat_win_status_refresh refresh
  def refresh
    name = @actor.libname
    points = (@actor.level - 1) - (sum($game_system.stats[name]) - sum($base_stats[name]))
    if !$game_switches[SKILL_TREES_ENABLED]
      lvlstat_win_status_refresh
    else
      self.contents.clear
      draw_actor_graphic(@actor, 40, 112)
      draw_actor_name(@actor, 4, 0)
      draw_actor_class(@actor, 4 + 144, 0)
      draw_actor_level(@actor, 96, 32)
      draw_actor_state(@actor, 96, 64)
      self.contents.draw_text(180, 32, 100, 32, "Points: "+points.to_s)
      #draw_actor_hp(@actor, 96, 112, 172)
      #draw_actor_sp(@actor, 96, 136, 172)
      #draw_actor_fp(@actor, 96, 160, 172)
      draw_actor_stat(@actor, 96, 112, "hp")
      draw_actor_stat(@actor, 96, 136, "sp")
      draw_actor_stat(@actor, 96, 160, "fp")
      draw_actor_stat(@actor, 96, 192, "atk")
      draw_actor_stat(@actor, 96, 214, "pdef")
      draw_actor_stat(@actor, 96, 238, "mdef")
      draw_actor_stat(@actor, 96, 270, "str")
      draw_actor_stat(@actor, 96, 296, "dex")
      draw_actor_stat(@actor, 96, 320, "agi")
      draw_actor_stat(@actor, 96, 344, "int")
      draw_actor_stat(@actor, 96, 368, "chr")
      draw_actor_stat(@actor, 96, 392, "snk")
      self.contents.font.color = system_color
      self.contents.draw_text(320, 48, 80, 32, "EXP")
      self.contents.draw_text(320, 80, 80, 32, "NEXT")
      self.contents.font.color = normal_color
      self.contents.draw_text(320 + 80, 48, 84, 32, @actor.exp_s, 2)
      self.contents.draw_text(320 + 80, 80, 84, 32, @actor.next_rest_exp_s, 2)
      self.contents.font.color = system_color
      self.contents.draw_text(320, 160, 96, 32, "Equipment")
      draw_item_name($data_weapons[@actor.weapon_id], 320 + 16, 208)
      draw_item_name($data_armors[@actor.armor1_id], 320 + 16, 256)
      draw_item_name($data_armors[@actor.armor2_id], 320 + 16, 304)
      draw_item_name($data_armors[@actor.armor3_id], 320 + 16, 352)
      draw_item_name($data_armors[@actor.armor4_id], 320 + 16, 400)
    end
  end
end

class Game_Enemy < Game_Battler
  def maxhp!
    if $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return $enemy_list[@enemy_id]['stats'][0]
    else
      return maxhp
    end
  end
  alias old_base_maxhp_enemy base_maxhp
  def base_maxhp
    if !use_level_stats && $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return $HP_STEP[maxhp!]
    else
      return old_base_maxhp_enemy
    end
  end
  
  def maxsp!
    if $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return $enemy_list[@enemy_id]['stats'][1]
    else
      return maxsp
    end
  end
  alias old_base_maxsp_enemy base_maxsp
  def base_maxsp
    if !use_level_stats && $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return maxsp! * 50
    else
      return old_base_maxsp_enemy
    end
  end
  
  def str!
    if $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return $enemy_list[@enemy_id]['stats'][2]
    else
      return str
    end
  end
  alias old_base_str_enemy base_str
  def base_str
    if !use_level_stats && $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return str! * 45 + 50
    else
      return old_base_str_enemy
    end
  end

  def dex!
    if $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return $enemy_list[@enemy_id]['stats'][3]
    else
      return dex
    end
  end
  alias old_base_dex_enemy base_dex
  def base_dex
    if !use_level_stats && $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return dex! * 45 + 50
    else
      return old_base_dex_enemy
    end
  end
  
  def agi!
    if $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return $enemy_list[@enemy_id]['stats'][4]
    else
      return agi
    end
  end
  alias old_base_agi_enemy base_agi
  def base_agi
    if !use_level_stats && $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return agi! * 45 + 50
    else
      return old_base_agi_enemy
    end
  end
  
  def int!
    if $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return $enemy_list[@enemy_id]['stats'][5]
    else
      return int
    end
  end
  alias old_base_int_enemy base_int
  def base_int
    if !use_level_stats && $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return int! * 45 + 50 #maybe no +50 initially for int?
    else
      return old_base_int_enemy
    end
  end
  
  def chr!
    if $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return $enemy_list[@enemy_id]['stats'][6]
    else
      return 0
    end
  end
  def chr
    if use_level_stats
      n = chr!
      for i in @states
        if $state_properties.has_key?($data_states[i].name) && $state_properties[$data_states[i].name].has_key?("chr_mod")
          n += $state_properties[$data_states[i].name]["chr_mod"]
        end
      end
      return n
    end
    return 0
  end
  
  def snk!
    if $enemy_list.has_key?(@enemy_id) && $enemy_list[@enemy_id].has_key?('stats')
      return $enemy_list[@enemy_id]['stats'][7]
    else
      return 0
    end
  end
  def snk
    if use_level_stats
      for i in @states
        if $state_properties.has_key?($data_states[i].name) && $state_properties[$data_states[i].name].has_key?("snk_mod")
          n += $state_properties[$data_states[i].name]["snk_mod"]
        end
      end
      n = snk!
      return n
    end
    return 0
  end
  
end

class Scene_Load < Scene_File
  alias lstat_read_save_data read_save_data
  def read_save_data(file)
    lstat_read_save_data(file)
    if $game_system.stats == nil
      $game_system.stats = {}
    end
    for actor in $game_party.actors()
      aname = $data_actors[actor.actor_id].name
      if !$game_system.stats.has_key?(aname)
        $game_system.init_stats(aname)
      end
    end
  end
end
