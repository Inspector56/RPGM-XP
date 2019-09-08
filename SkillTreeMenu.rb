#Skill Tree Menu by NanaBan

#When used, it appears as "Skill Tree" in the menu, near "Skills" and "Status".
#Like those two, it will allow you to select a party member. Once an actor has been
#selected, however, it will try to change the scene to the corresponding skill tree for
#the selected actor.

#The Skill Tree Scene should attempt to use their Database actor name (so it is not
#sensitive to any renaming commands you might use in your game) to index into the skill
#tree dictionary. If no entry for that actor exists, it will not try to load the Skill Tree
#Scene, but rather just play a buzzer noise.

#This script does not implement ANY skills, it merely provies a framework for making interesting,
#unique skill tree menus for each character and storing/accessing their perks.

# HOW TO USE

# A lot of the burden of work is on the user; really it is best if you have at least a basic knowledge
# of scripting, it's mostly a framework to make implementing this faster but still customizeable

# There are some things - like the size of the rectangular bitmaps lighting up the nodes behind the background
# image, the colors of certain text/nodes, the way that the number of skill points available (currently equal
# to the actor's level minus the total number of points they have invested in skills) is computed, and where
# skills get stored/how they are accessed - that you might disagree with or otherwise want to modify.
# You might even want to change it fundamentally from storing a skill name and level to simply switching
# a game switch or game variable when a player puts a point in. The bottom line is that this script is geared
# towards coders - this is just a menu, after all, so you're probably going to have to do some scripting to
# have your skills do what you want them to once they're unlocked.

#For each actor, you must fill in the following:
# - 'background' => a string that represents the image filename of the background image for
#    the scene. The way the scene is drawn is that the image is drawn in front, with text
#    rendered over it, and a bunch of colored rectangles drawn behind it. The idea is to create
#    small holes in the image representing each node in the tree. There are different colors for
#    unlocked, unlockable (neighbor of unlocked), and locked, and the node that the user is on
#    will flash white. Design the background accordingly. Note that due to this backlit nature,
#    you can do some slightly more ambitious node design - ie, have the circle cutout, but then
#    put an icon or symbol in the middle.
#    Note that later on, you will have to input specific information based on what your background
#    actually looks like and where the holes are.
# - 'start' => the name of the node that the user starts on in the scene, presumably the root
# - 'skills' => this is the meat. It is a dictionary of the nodes; name them whatever you want,
#    the user will never see the node names, but you will probably want to make them related to
#    the skill/upgrade that they represent.
#     - 'name' : the name of the skill/upgrade that the user WILL see when on this node
#     - 'UP','DOWN','LEFT','RIGHT' : for each direction, put the node (your behind-the-scenes
#        node name, not the 'name' property above) that pressing that direction will take you to
#        from this node; you will just have to play with this and see what feels right/intuitive for
#        your background image/hole positions
#     - 'children' : list of nodes that are directly "downstream" of this node - ie, which nodes will
#        be added to the "unlockable" category once this node is unlocked
#     - 'level' : starting level for the skill; probably 0 or 1
#     - 'max_level' : the cap; maximum level the actor can have invested in this skill.
#     - 'costs' : list, in order, of the skill-point cost of each "level up" of this ability/skill
#     - 'stats' : info to give the user about the skill they are considering getting/upgrading; cost to use
#        in combat, avg damage and hit chance, etc.
#     - 'position' : (x, y) position of the tree node in the background image
#     - 'description' : a list of brief overviews of the skill, at each level that can be attained (should be
#        the same length as 'costs'); you are responsible for manually inserting and proper spacing of linebreaks

#Everything depends on filling out the "skill_tree" object below; 

#Game_Switch number to turn this menu option on/off in the game menu
SKILL_TREES_ENABLED = 11

$skill_tree = {
  "Harold" => {
    'background' => 'HaroldTreeBack.png',
    'start' => 'bully',
    'skills' => {
      'bully' => {
          'name' => 'Tunnel Vision',
          'UP' => 'combos', 'DOWN' => 'bully', 'LEFT' => 'bully', 'RIGHT' => 'combos',
          'children' => [ 'combos' ],
          'level' => 1,
          'max_level' => 3,
          'costs' => [1, 1, 1],
          'stats' => 'SP cost: 10, CP cost: 0',
          'position' => [200, 270],
          'description' => ['Commit to attacking one enemy for 3 turns to deal 10% bonus damage.',
                            'Commit to attacking one enemy for 3 turns to deal 20% bonus damage.',
                            'Commit to attacking one enemy for 2 turns to deal 25% bonus damage.']
        },
      'combos' => {
          'name' => 'Combos',
          'UP' => 'reach', 'DOWN' => 'bully', 'LEFT' => 'bully', 'RIGHT' => 'step_combos',
          'children' => [ 'reach', 'step_combos' ],
          'level' => 0,
          'max_level' => 3,
          'costs' => [1, 1, 1],
          'position' => [260, 210],
          'description' => ['Harold can learn up to 3 combos, each up to 4 moves long.',
                            'Harold can learn up to 5 combos, each up to 4 moves long.',
                            'Harold can learn up to 6 combos, each up to 5 moves long.']
        },
      'reach' => {
          'name' => 'Reach',
          'UP' => 'stance', 'DOWN' => 'combos', 'LEFT' => 'combos', 'RIGHT' => 'charge',
          'children' => [ 'stance', 'charge' ],
          'level' => 0,
          'max_level' => 2,
          'costs' => [1, 1],
          'position' => [275, 140],
          'description' => ['Reduces the effect of distance on Harold\'s melee attacks by 1 step.',
                            'Reduces the effect of distance on Harold\'s melee attacks by 2 steps.']
        },
      'step_combos' => {
          'name' => 'Step Combos',
          'UP' => 'risky_combos', 'DOWN' => 'step_combos', 'LEFT' => 'combos', 'RIGHT' => 'adv_combos',
          'children' => [ 'risky_combos', 'adv_combos' ],
          'level' => 0,
          'max_level' => 2,
          'costs' => [1, 2],
          'position' => [350, 170],
          'description' => ['Adds 10% damage to 2nd move, 20% to 3rd, etc; max length 3.',
                            'Adds 10% damage to 2nd move, 20% to 3rd, etc; max length 4.']
        },
      'charge' => {
          'name' => 'Charge',
          'UP' => 'beatdown', 'DOWN' => 'reach', 'LEFT' => 'stance', 'RIGHT' => 'rage',
          'children' => [ 'rage', 'beatdown' ],
          'level' => 0,
          'max_level' => 1,
          'costs' => [1],
          'stats' => 'SP cost: 20, CP cost: 10',
          'position' => [310, 70],
          'description' => ['Ready a charge before performing a melee attack to charge to the frontline,\ndealing an addition 15% damage for each step taken.']
        },
      'stance' => {
          'name' => 'Stance',
          'UP' => 'stance', 'DOWN' => 'reach', 'LEFT' => 'reach', 'RIGHT' => 'charge',
          'children' => [ ],
          'level' => 0,
          'max_level' => 2,
          'costs' => [1, 1],
          'stats' => 'SP cost: 30, CP cost: 80',
          'position' => [250, 50],
          'description' => ['Become immune to knockback effects for 3 turns.',
                            'Become immune to knockback and pull effects for 3 turns.']
        },
      'risky_combos' => {
          'name' => 'Risky Combos',
          'UP' => 'defensive', 'DOWN' => 'step_combos', 'LEFT' => 'step_combos', 'RIGHT' => 'defensive',
          'children' => ['defensive'],
          'level' => 0,
          'max_level' => 1,
          'costs' => [2],
          'position' => [400, 110],
          'description' => ['Harold can learn high-risk, high-reward combos (inflict penalties if broken).']
        },
      'adv_combos' => {
          'name' => 'Adv. Combos',
          'UP' => 'risky_combos', 'DOWN' => 'adv_combos', 'LEFT' => 'step_combos', 'RIGHT' => 'adv_grapple',
          'children' => ['adv_grapple'],
          'level' => 0,
          'max_level' => 1,
          'costs' => [2],
          'position' => [440, 180],
          'description' => ['Harold can learn combos with special bonuses, like gaining buffs or inflicting debuffs.']
        },
      'beatdown' => {
          'name' => 'Beatdown',
          'UP' => 'beatdown', 'DOWN' => 'charge', 'LEFT' => 'charge', 'RIGHT' => 'rage',
          'children' => [],
          'level' => 0,
          'max_level' => 1,
          'costs' => [1],
          'position' => [360, 20],
          'description' => ['When bullying a target, basic attacks double-hit.']
        },
      'rage' => {
          'name' => 'Rage',
          'UP' => 'rage', 'DOWN' => 'charge', 'LEFT' => 'charge', 'RIGHT' => 'defensive',
          'children' => [ ],
          'level' => 0,
          'max_level' => 1,
          'costs' => [2],
          'stats' => 'SP cost: 20, CP cost: 0, FP cost (after): 20',
          'position' => [400, 40],
          'description' => ['Gain 20% agility, and 30% damage, and 3 resist for 3 turns, but after those \n3 turns, lose 20 FP and lose 20% agility and 1 resist for two turns.']
        },
      'defensive' => {
          'name' => 'Defensive',
          'UP' => 'defensive', 'DOWN' => 'risky_combos', 'LEFT' => 'risky_combos', 'RIGHT' => 'defensive',
          'children' => [ ],
          'level' => 0,
          'max_level' => 1,
          'costs' => [1],
          'position' => [470, 60],
          'description' => ['Use Item, Move, and Guard/Defend no longer break combos.']
        },
      'adv_grapple' => {
          'name' => 'Adv. Grapple',
          'UP' => 'defensive', 'DOWN' => 'adv_grapple', 'LEFT' => 'adv_combos', 'RIGHT' => 'adv_grapple',
          'children' => [ ],
          'level' => 0,
          'max_level' => 1,
          'costs' => [2],
          'position' => [500, 180],
          'description' => ['Harold can grapple while affected by Stunned, Dazed, and Confused, and cannot be grappled while grappling.']
        }
      }
  },
  "Actor2" => {
    #etc
  },
};

class Game_System
  attr_accessor   :skill_tree
  
  def init_skills(s_actor)
    if @skill_tree == nil
      @skill_tree = Marshal.load(Marshal.dump($skill_tree))
    else
      for actor in $game_party.actors()
        if $data_actors[actor.actor_id].name == s_actor
          @skill_tree[s_actor] = Marshal.load(Marshal.dump($skill_tree[s_actor]))
        end
      end
    end
  end
end

class Game_Party
  
  alias skill_tree_add_actor add_actor
  def add_actor(actor_id)
    name = $data_actors[actor_id].name
    if $game_switches[SKILL_TREES_ENABLED]
      if !$game_system.skill_tree or !$game_system.skill_tree.has_key?(name)
        $game_system.init_skills(name)
      end
    end
    skill_tree_add_actor(actor_id)
  end
end

class Game_Actor < Game_Battler
  attr_reader   :perks
  attr_reader   :actor_id
  
  def get_stats_from_level_tree
    if $game_system.skill_tree == nil or !$game_system.skill_tree.has_key?(self.name)
      $game_system.init_skills(self.name)
    end
    @perks = {}
    $game_system.skill_tree[self.name]['skills'].each do |name, value|
      @perks[name] = value['level']
    end
  end
end

class Scene_SkillTree
  
  def locked_color
    if @rules.has_key?('locked_color')
      _color = @rules['locked_color']
      return Color.new(_color[0],_color[1],_color[2])
    end
    return Color.new(77, 77, 77)
  end
  def unlocked_color
    if @rules.has_key?('unlocked_color')
      _color = @rules['unlocked_color']
      return Color.new(_color[0],_color[1],_color[2])
    end
    return Color.new(251, 255, 203)
  end
  def unlockable_color
    if @rules.has_key?('unlockable_color')
      _color = @rules['unlockable_color']
      return Color.new(_color[0],_color[1],_color[2])
    end
    return Color.new(169, 172, 142)
  end
  def max_level_color
    if @rules.has_key?('max_level_color')
      _color = @rules['max_level_color']
      return Color.new(_color[0],_color[1],_color[2])
    end
    return Color.new(251, 255, 203)
  end

  def set_color(name, color=nil)
    pos = @rules['skills'][name]['position']
    _x, _y = pos[0], pos[1]
    if !color
      if @unlocked.include?(name)
        if @rules['skills'][name].has_key?('level') and (@rules['skills'][name]['level'] == @rules['skills'][name]['max_level'])
          color = max_level_color
        else
          color = unlocked_color
        end
      elsif @unlockable.include?(name)
        color = unlockable_color
      else
        color = locked_color
      end
    end
    @boxes[name].bitmap.fill_rect(_x, _y, 40, 40, color)
  end
  
  def initialize(actor)
    @actor = actor
  end
  
  def main
    used = 0
    @rules = $game_system.skill_tree[@actor.name]
    @back_viewport = Viewport.new(0, 0, 640, 480)
    @back_viewport.z = 100
    @background = RPG::Sprite.new(@back_viewport)
    @box_viewport = Viewport.new(0, 0, 640, 480)
    @box_viewport.z = 1
    @win_viewport = Viewport.new(0, 0, 640, 480)
    @win_viewport.z = 200
    @boxes, @unlocked, @unlockable = {}, [], []
    @curr_box = @rules['start']
    #create color boxes
    @rules['skills'].each do |name, value|
      used += @rules['skills'][name]['level']
      @boxes[name] = RPG::Sprite.new(@box_viewport)
    end
    #determine reachability
    _boxes = [@curr_box]
    while _boxes.length() > 0
      _box = _boxes.shift()
      if @rules['skills'][_box].has_key?('level') and (@rules['skills'][_box]['level'] > 0)
        @unlocked.push(_box)
        if @rules['skills'][_box].has_key?('children') #it's a tree, don't have to worry about adding twice
          _boxes.concat(@rules['skills'][_box]['children'])
        end
      else #got here from an unlocked trait
        @unlockable.push(_box)
      end
    end
    @boxes.each do |name, value|
      value.bitmap = Bitmap.new(640, 480)
      set_color(name)#value.bitmap.fill_rect(_x, _y, 40, 40, get_color(name))
    end
    @points = @actor.level - used
    @inputing = false
    @choice = Window_Command.new(70, ["Yes", "No"])
    @choice.visible = false
    @choice.active = false
    @choice.x = 280
    @choice.y = 192
    @choice.z = 300
    @choice.back_opacity = 160
    @background.bitmap = RPG::Cache.picture(@rules['background'])
    @descr = RPG::Sprite.new(@win_viewport)#Window_Base.new(0, 480, 640, 160)
    @title = RPG::Sprite.new(@win_viewport)#Window_Base.new(0, 450, 640, 15)
    @costs = RPG::Sprite.new(@win_viewport)#Window_Base.new(0, 465, 640, 15)
    update_help
    
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
        break
      end
    end
    # Prepare for transition
    Graphics.freeze
    # Dispose of windows
    @descr.dispose
    @title.dispose
    @costs.dispose
    @choice.dispose
    dispense
  end
  
  def update
    if not @inputing
      if Input.trigger?(Input::B)
        $game_system.se_play($data_system.cancel_se)
        # Exit to menu
        $scene = Scene_Menu.new(-1)
        return
      end
      if Input.trigger?(Input::C) 
        if !(@unlockable.include?(@curr_box) or @unlocked.include?(@curr_box)) or (@rules['skills'][@curr_box]['level'] >= @rules['skills'][@curr_box]['max_level']) or (@points < @rules['skills'][@curr_box]['costs'][@rules['skills'][@curr_box]['level']])
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        @inputing = true
        $game_system.se_play($data_system.decision_se)
        confirm_level_up
        return
      end
      up, down, left, right = Input.trigger?(Input::UP), Input.trigger?(Input::DOWN), Input.trigger?(Input::LEFT), Input.trigger?(Input::RIGHT)
      if (up or down or left or right)
        $game_system.se_play($data_system.decision_se)
        @boxes[@curr_box].blink_off
        if up
          @curr_box = @rules['skills'][@curr_box]['UP']
        elsif down
          @curr_box = @rules['skills'][@curr_box]['DOWN']
        elsif left
          @curr_box = @rules['skills'][@curr_box]['LEFT']
        else
          @curr_box = @rules['skills'][@curr_box]['RIGHT']
        end
        @boxes[@curr_box].blink_on
        update_help
      end
    else
      if Input.trigger?(Input::C)
        if @choice.index == 0
          $game_system.se_play($data_system.decision_se)
          @points -= @rules['skills'][@curr_box]['costs'][@rules['skills'][@curr_box]['level']]
          @rules['skills'][@curr_box]['level'] += 1
          @rules['skills'][@curr_box]['children'].each do |name|
            if (!@unlockable.include?(name))
              @unlockable.push(name)
              set_color(name)
            end
          end
          if (!@unlocked.include?(@curr_box))
            @unlocked.push(@curr_box)
            set_color(@curr_box)
          end
          update_help
        else
          $game_system.se_play($data_system.cancel_se)
        end
        @choice.active = false
        @choice.visible = false
        @top.dispose
        @inputing = false
      elsif Input.trigger?(Input::B)
        @choice.active = false
        @choice.visible = false
        $game_system.se_play($data_system.cancel_se)
        @top.dispose
        @inputing = false
      end
    end
    @boxes.each do |name, value|
      value.update
    end
    @choice.update
    @title.update
    @costs.update
    @descr.update
  end
  
  def update_help
    yellow = Color.new(255, 255, 204)
    white = Color.new(255, 255, 255)
    blue = Color.new(92, 139, 201)
    gold = Color.new(240, 230, 79)
    red = Color.new(235, 59, 5)
    #self.contents.font.color = normal_color
    #self.contents.draw_text(x, y, 120, 32, actor.name)
    if (@title.bitmap != nil) and (!@title.bitmap.disposed?)
      @title.bitmap.clear
    else
      @title.bitmap = Bitmap.new(640, 480)
    end
    #Skill name
    @title.bitmap.font.name = 'Papyrus'
    @title.bitmap.font.bold = true
    @title.bitmap.font.size = 40
    @title.bitmap.font.color = Color.new(240, 240, 240)
    @title.bitmap.draw_text(40, 340, 640, 50, @rules['skills'][@curr_box]['name'])
    #points available, in corner
    @title.bitmap.font.name = 'Papyrus'
    @title.bitmap.font.size = 80
    @title.bitmap.draw_text(540, 30, 640, 80, @points.to_s)
    @title.bitmap.font.name = 'Verdana'
    @title.bitmap.font.size = 12
    @title.bitmap.font.bold = false
    @title.bitmap.draw_text(580, 40, 640, 50, 'points')
    
    if (@costs.bitmap != nil) and (!@costs.bitmap.disposed?)
      @costs.bitmap.clear
    else
      @costs.bitmap = Bitmap.new(640, 480)
    end
    @costs.bitmap.font.name = 'Verdana'
    @costs.bitmap.font.size = 14
    x = 40
    @costs.bitmap.font.color = yellow
    @costs.bitmap.draw_text(x, 378, 640, 28, 'Level: ')
    x += 42
    @costs.bitmap.font.bold = true
    @costs.bitmap.font.color = white
    @costs.bitmap.draw_text(x, 378, 640, 28, @rules['skills'][@curr_box]['level'].to_s)
    x += 10
    @costs.bitmap.font.color = blue
    @costs.bitmap.draw_text(x, 378, 640, 28, '/')
    x += 10
    @costs.bitmap.font.color = white
    @costs.bitmap.draw_text(x, 378, 640, 28, @rules['skills'][@curr_box]['max_level'].to_s)
    x += 12
    @costs.bitmap.font.bold = false
    if @rules['skills'][@curr_box]['level'] < @rules['skills'][@curr_box]['max_level']
      @costs.bitmap.font.color = yellow
      @costs.bitmap.draw_text(x, 378, 640, 28, ', ')
      x += 10
      req = @rules['skills'][@curr_box]['costs'][@rules['skills'][@curr_box]['level']]
      if @points >= req
        @costs.bitmap.font.color = gold
      else
        @costs.bitmap.font.color = red
      end
      @costs.bitmap.draw_text(x, 378, 640, 28, req.to_s)
      x += 10
      @costs.bitmap.font.color = yellow
      @costs.bitmap.draw_text(x, 378, 640, 28,' point')
      x += 36
      if req > 1
        @costs.bitmap.draw_text(x, 378, 640, 28,'s')
        x += 8
      end
      @costs.bitmap.draw_text(x, 378, 640, 28,' required for next level.')
    end
    if @rules['skills'][@curr_box].has_key?('stats')
      @costs.bitmap.draw_text(40, 396, 640, 28, @rules['skills'][@curr_box]['stats'])
    end
    if (@descr.bitmap != nil) and (!@descr.bitmap.disposed?)
      @descr.bitmap.clear
    else
      @descr.bitmap = Bitmap.new(640, 480)
    end
    @costs.bitmap.font.name = 'Arial'
    @costs.bitmap.font.size = 20
    @costs.bitmap.font.color = Color.new(250, 250, 250)
    index = @rules['skills'][@curr_box]['level']
    if index != 0
      index -= 1
    end
    text = @rules['skills'][@curr_box]['description'][index]
    lines = text.split('\n')
    for i in 0...lines.length
      @descr.bitmap.draw_text(40, 390 + 20*i, 640, 80, lines[i])
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
    if @unlocked.include?(@curr_box)
      text = "Level up "
    else
      text = "Unlock "
    end
    text += @rules['skills'][@curr_box]['name'] + '?'
    @top.bitmap.draw_text(222, 130, 200, 40, text, 1)
    text = "(Spend "+ @rules['skills'][@curr_box]['costs'][@rules['skills'][@curr_box]['level']].to_s + " skill points)"
    @top.bitmap.font.size = 16
    @top.bitmap.draw_text(222, 150, 200, 40, text, 1)
    index = @rules['skills'][@curr_box]['level']
    if index != 0
      @top.bitmap.fill_rect(0, 330, 640, 150, Color.new(0,0,0,250))
      @top.bitmap.font.size = 26
      @top.bitmap.font.bold = true
      @top.bitmap.font.color = unlockable_color
      @top.bitmap.draw_text(30, 338, 200, 40, "Next level:")
      @top.bitmap.font.color = Color.new(250, 250, 250)
      @top.bitmap.font.bold = false
      @top.bitmap.font.size = 20
      index -= 1
      text = @rules['skills'][@curr_box]['description'][index]
      lines = text.split('\n')
      for i in 0...lines.length
        @top.bitmap.draw_text(0, 350 + 20*i, 640, 80, lines[i], 1)
      end
    end
    @choice.active = true
    @choice.visible = true
  end
  
  def dispense
    @background.dispose
    @boxes.each do |name, value|
      value.dispose
    end
    scene = Scene_Menu.new()
  end
  
end

#==============================================================================
# ** Scene_Menu
#------------------------------------------------------------------------------
#  This class performs menu screen processing.
#==============================================================================

class Scene_Menu

  def initialize(menu_index = 0)
    if $game_switches[SKILL_TREES_ENABLED]
      if (menu_index >= 2)
        menu_index += 1
      elsif menu_index == -1
        menu_index = 2
      end
    end
    @menu_index = menu_index
  end
  
  alias skill_tree_scene_menu_main main
  def main
    if !$game_switches[SKILL_TREES_ENABLED]
      skill_tree_scene_menu_main
    else
      # Make command window
      s1 = $data_system.words.item
      s2 = 'Skills' #$data_system.words.skill
      s2_5 = 'Skill Tree'
      s3 = $data_system.words.equip
      s4 = "Status"
      s5 = "Save"
      s6 = "Settings"
      s7 = "End Game"
      @command_window = Window_Command.new(160, [s1, s2, s2_5, s3, s4, s5, s6, s7]) #160 by default
      @command_window.index = @menu_index
      # If number of party members is 0
      if $game_party.actors.size == 0
        # Disable items, skills, equipment, and status
        for index in 0...@command_window.commands.length()
          @command_window.disable_item(index)
        end
      end
      # If save is forbidden
      if $game_system.save_disabled
        # Disable save
        @command_window.disable_item(4)
      end
      # Make play time window
      @playtime_window = Window_PlayTime.new
      @playtime_window.x = 0
      @playtime_window.y = 320 #prev: 224
      # Make steps window
      #@steps_window = Window_Steps.new
      #@steps_window.x = 0
      #@steps_window.y = 320
      # Make gold window
      @gold_window = Window_Gold.new
      @gold_window.x = 0
      @gold_window.y = 416
      # Make status window
      @status_window = Window_MenuStatus.new
      @status_window.x = 160
      @status_window.y = 0
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
          break
        end
      end
      # Prepare for transition
      Graphics.freeze
      # Dispose of windows
      @command_window.dispose
      @playtime_window.dispose
      #@steps_window.dispose
      @gold_window.dispose
      @status_window.dispose
    end
  end

  alias skill_tree_scene_menu_update_command update_command
  def update_command
    if !$game_switches[SKILL_TREES_ENABLED]
      skill_tree_scene_menu_update_command
    else
      # If B button was pressed
      if Input.trigger?(Input::B)
        # Play cancel SE
        $game_system.se_play($data_system.cancel_se)
        # Switch to map screen
        $scene = Scene_Map.new
        return
      end
      # If C button was pressed
      if Input.trigger?(Input::C)
        # If command other than save or end game, and party members = 0
        if $game_party.actors.size == 0 and @command_window.index < 4
          # Play buzzer SE
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        # Branch by command window cursor position
        case @command_window.index
        when 0  # item
          # Play decision SE
          $game_system.se_play($data_system.decision_se)
          # Switch to item screen
          $scene = Scene_Item.new
        when 1  # skill
          # Play decision SE
          $game_system.se_play($data_system.decision_se)
          # Make status window active
          @command_window.active = false
          @status_window.active = true
          @status_window.index = 0
        when 2 # skill tree
          if ($skill_tree.has_key?($data_actors[$game_party.actors()[@status_window.index].actor_id].name))
            # Play decision SE
            $game_system.se_play($data_system.decision_se)
            # Make status window active
            @command_window.active = false
            @status_window.active = true
            @status_window.index = 0
          else
            return
          end
        when 3  # equipment
          # Play decision SE
          $game_system.se_play($data_system.decision_se)
          # Make status window active
          @command_window.active = false
          @status_window.active = true
          @status_window.index = 0
        when 4  # status
          # Play decision SE
          $game_system.se_play($data_system.decision_se)
          # Make status window active
          @command_window.active = false
          @status_window.active = true
          @status_window.index = 0
        when 5  # save
          # If saving is forbidden
          if $game_system.save_disabled
            # Play buzzer SE
            $game_system.se_play($data_system.buzzer_se)
            return
          end
          # Play decision SE
          $game_system.se_play($data_system.decision_se)
          # Switch to save screen
          $scene = Scene_Save.new
        when 7  # end game
          # Play decision SE
          $game_system.se_play($data_system.decision_se)
          # Switch to end game screen
          $scene = Scene_End.new
        when 6  # Settings
          # Play decision SE
          $game_system.se_play($data_system.decision_se)
          # Switch to Settings screen
          $scene = Scene_Settings.new
        end
        return
      end
    end
  end

  alias skill_tree_scene_menu_update_status update_status
  def update_status
    if !$game_switches[SKILL_TREES_ENABLED]
      skill_tree_scene_menu_update_status
    else
      # If B button was pressed
      if Input.trigger?(Input::B)
        # Play cancel SE
        $game_system.se_play($data_system.cancel_se)
        # Make command window active
        @command_window.active = true
        @status_window.active = false
        @status_window.index = -1
        return
      end
      # If C button was pressed
      if Input.trigger?(Input::C)
        # Branch by command window cursor position
        case @command_window.index
        when 1  # skill
          # If this actor's action limit is 2 or more
          if $game_party.actors[@status_window.index].restriction >= 2
            # Play buzzer SE
            $game_system.se_play($data_system.buzzer_se)
            return
          end
          # Play decision SE
          $game_system.se_play($data_system.decision_se)
          # Switch to skill screen
          $scene = Scene_Skill.new(@status_window.index)
        when 2
          if ($skill_tree.has_key?($data_actors[$game_party.actors()[@status_window.index].actor_id].name))
            $game_system.se_play($data_system.decision_se)
            # Switch to skill screen
            $scene = Scene_SkillTree.new($game_party.actors()[@status_window.index])
          else
            $game_system.se_play($data_system.buzzer_se)
          end
        when 3  # equipment
          # Play decision SE
          $game_system.se_play($data_system.decision_se)
          # Switch to equipment screen
          $scene = Scene_Equip.new(@status_window.index)
        when 4  # status
          # Play decision SE
          $game_system.se_play($data_system.decision_se)
          # Switch to status screen
          $scene = Scene_Status.new(@status_window.index)
        end
        return
      end
    end
  end
end
