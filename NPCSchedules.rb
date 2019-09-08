#Scheduled NPCs by NanaBan

#REQUIRES a path finding script and a day/night/time-passage script
# This implementation uses Heretic's Revision of ForeverZer0's Pathfind
# This implementation uses Heretic's Dynamic Lights for day/night
#If you want to use different pathfinders or time/weather systems, you will have to modify
#either this script or the scripts you chose so that:
# 1) the Game_Character class has a method pathfind(X, Y, CHARACTER, RANGE, SUCCESS_PROC, FAIL_PROC)
#    that causes it to move to (or close to) (X, Y)
# 2) the world time at any given moment is stored, in seconds, in a $game_variable

#COMPATIBILITY
#If you are using Heretic's Modular Passable/Heretic's Modular Collision Optimizer,
#this script will cause your game to crash if you do not replace the following definition:
#   def []=(key, event)
#      @data[key] = (@data[key]) ? @data[key] << event : [event]
#   end
# with:
#   def []=(key, event)
#     if !(event.is_shadow) and (!event.is_a?(Game_NPC) or (event.current_map == $game_map.map_id))
#        @data[key] = (@data[key]) ? @data[key] << event : [event]
#      end
#   end
#It is adviseable to place this script below other scripts that heavily affect Game_Character,
#Game_Event, and/or Game_Map behavior
#Obviously, I only detected compatibility issues with scripts that I happened to be using in the same project;
#there are probably a great many scripts that are incompatible, and perhaps a great many such cases would be
#as easily solved had I looked into it.

#Purpose/Summary:
#  I want to start by clarifying that in no way does this mod change or hamper how standard
#game events are/can be used. The NPC behavior I am about to describe is an option available to
#you after following a strict format in accordance with this script.
#  The goal of this mod is to allow you to create Stardew-Valley-esque NPCs - that is,
#instead of defining NPCs whereever it is that they appear, you can specify, from a single
#event, daily behaviors and routines. HOWEVER, this is very different from how RPG Maker is
#built/designed to work, so this "final" result is what I came up with after spending a lot
#of time thinking about how best to encapsulate this kind of functionality in an easy-to-use
#and intuitive API. If you can think of a better system, I would be delighted to hear about it;
#while what I have works as an API, it requires the user to be conscious of it and work around
#it perhaps more than any other script I have seen.
#  That is the scheduling portion. The "AI" portion of the name refers to something else; in truth,
#the game I wanted to make, and made this script for, is actually Stardew Valley meets Hitman; or
#perhaps, Thief Simulator, but you can also talk to, get to know, (get to learn the schedules of), and
#befriend the townspeople. The bottom line is, I want some spontaneous, unpredictable input from the
#player - like being caught trying to pick a lock or knocking someone out, etc, to be able to dynamically
#break the NPCs' schedules, execute another behavior, and eventually be able to return to their schedule.
#
#HOW TO USE:

#Creating NPCs:
#  The first important notion is "NPC Set" map. Whenever you create a city or town or some
#logical group of maps, you must make these maps be children (or children of children, etc.)
#a map that, by default, should be named (or contain the substring) "NPC Set". This map should not
#ever be used in game/be accessed by the player. Nothing totally catastrophic would come of trying
#to use it, but the NPCs would be loaded as standard game events by that map, which is probably not
#the desired behavior. All NPCs for the region should be in that map. One immediately obvious downside
#is that you have to memorize/abstractly visualize their positions throughout the day, but if you
#think about the problem - where should an NPC "start"? If they can start on different maps, how do
#we group the maps, because we probably should track all NPCs in the game at all times - you will find
#that this makes things a lot easier.
#  You create an NPC by creating an event on the NPC Set map, naming it a particular way (we'll get to
#that later as well, for now "NPC Bob" is an option), and then creating a schedule page. A schedule page
#is any page with one of the switch conditions set to a very particular game switch that you designate
#(change the macro value below). I named this switch "Schedule"; it will not be used for logic, I have mine
#never be true.

#Creating Schedules:
#  To begin making the schedule, the most basic step is to add a label to the schedule page. Yes, I could have
#made it a comment, but I chose to make it a label - just seemed fitting at the time, but it leads to a nifty
#trick you can do, more on that later. The label should have the following information (must fit this format):
#"HR:MIN MAPID X Y" or "HR:MIN MAPID". The hour and minutes should be in military time (as there is no AM/PM field);
#a bad time label will simply never be used/executed. The MapID and optionally X-Y coordinates indicate where the
#NPC is supposed to be or wants to be for that portion of the schedule. You can have the MapID be a map that is not
#a descendent of the NPC Set the NPC belongs to, but if you then travel to that map, the game will not know to try
#to load that NPC. There is a workaround for this - again, this will be explored in more depth later.
#  Returning to the labels - during

#Doors and Transition Points:
#  Doubtless your game will have doors and map edges that transport the player to a new location either by contact
#or when they approach and press the input (action) button. To make the NPCs seem like people in their own right
#that can transition between maps freely as needed, my code has to know where the doors and transition points are.
#Searching through events to see if they have Transfer Player commands would already be inefficient and annoying, but
#it would be nearly impossible to determine the correct conditions under which transferal is supposed to occur and
#what is a door versus a simple map boundary. Thus, I'll ask a little more of the user - that you stick to a simple
#rule of only having very simple, contact-based player teleportation, and that you name the events in an intuitive,
#useful way - doors are "DOOR MAPID X Y", transfer points are "TP MAPID X Y". The bright side is that you can start
#copy pasting these events and then just make small edits. Doors have an additional optional parameter, "DOOR MAPID X Y DIR"
#where DIR is a number in [0, 1, 2, 3, 4] that represents the direction to the door so that the code can know when the npc
#qualifies as being "in front of the door". 0, the default value, means that the door is facing down (the player can clearly see
#the door sprite and must be BELOW it to activate it. 1 means that the NPC would have to be ABOVE the door to open it, 2 means
#they should be to the LEFT of the door, and 3 means to the RIGHT. Use 4 when you want the DOOR event position and the position
#that the NPC needs to be in to open the door to be the same, such as if the door WOULD be below the player but the tile is at
#the bottom of the map.
#  Obviously, MAPID, X, Y tells the script that upon reaching that point, the NPC will be transported to the X, Y
#coordinates of the map with that map_id. There are two main differences between how the two are treated - TPs instantly
#teleport all NPCs that touch them. Doors, however, run the event in the Door's event page as they would for the player,
#omitting ONLY transfer player commands. The idea here is to let it play any door-opening sound effects or animations you
#have in place. The other different feature of doors is that you can bar certain characters from using them. Make sure,
#however, that any such control labels are at the top/above the animations and sounds, because even in cases of the door
#being "locked" for an NPC, it runs the door's event page until it hits a label telling it that the door is locked (for this
#NPC); this design decision was to make it easy for the user to put in conditionals, both in terms of when NPCs are denied
#access and in case you wanted to set special control variables when an NPC is denied access, etc. The format is as follows:
#  The format of these labels is "DOOR LOCK npc_name"
#EDIT: If you simply name the doors "DOOR MAPID DIR" or "DOOR MAPID" (default direction), the door will use the mapid and x and
#y values of the Transfer Player command to transfer the NPC (yes, you can lie and make MAPID different from the actual map that
#it leads to, if you want things to work incorrectly). Unfortunately, the MAPID cannot be easily removed, for the reasons described
#earlier - the NPC has to know which map the door would send it to BEFORE picking a door to try to find, so this could not be done
#nearly as efficiently or even correctly by scanning through for Transfer Player mapids.

#Comment Commands:
#-daily-reset:
#-daily-reset-commands:
#  By default, the daily reset only sets the number of times the player has interacted with an NPC that day to zero.
#You can change this fairly easily by adding to the function in the script, "reset" under the Game_NPC class. However,
#if you don't feel like a scripter or don't like messing with other peoples' code, you can also set event commands to
#run upon daily resets much the same way you would set a schedule item; you create a label with the text, "DAILY RESET"
#(by default) and the commands listed beneath will be run at the reset time. Use this to, for example, maintain your own
#NPC variables, like a switch for a cutscene once a the player's friendship level reaches a certain point with that NPC.
#page-redirects (discussed below) work here as well.
#-schedule-conditions: Multiple Schedules per NPC
#  Vital to NPCs with multiple schedules are schedule conditions. These are comments with special formats that must be at
#the very top of the schedule page (for efficiency and laziness reasons). You may, however, have as many of these conditions
#as you like. Amongst schedule pages, selection is handled the same way normal event pages are - the page furthest to the right
#that satisfies the conditions will be used.
#-trigger-types:
#-page-reroute:

#BELOW ARE SOME PERTINENT IMPLEMENTATION DETAILS REGARDING DOORS. IT IS VERY IMPORTANT that
#anyone planning to use the DOOR features has at least a basic understanding of the following:
#I said earlier that when an NPC reaches a DOOR and tries to use it to, it results in the event
#at the door being run. The primary intention behind this is to play door-opening sounds and animations,
#and have some more flexible logic capabilites in terms of who can use the door and when it can be used.
#The severe downside of this is that there are a LOT of potential commands that you would not want to be
#run. The door-opening sound and animation should not occur if an NPC is traveling between maps that the
#player is not actually on. Maybe the door triggers cutscenes, dialogue, or images; we would not want the
#player to be exploring, and suddenly be interrupted by text because Joe is going into the bar.
#Thus, there are three cases/classes of command - commands that we only want to actually execute if the player
#is the one using the door ("player_only"), commands that will run if anyone uses the door but ONLY if it is
#done on the same map as the player ("on_map"), and commands that should ALWAYS be run ("none"). In the function
#below, you can see which types I have assigned to be the default mode for each type of event command.

#In-game, you can change the mode of any event command type with a line of the following form:
#skm = $game_system.skip_modes
#skm[250] = 'player_only'
#note: the dictionary index/key should be the code of the event command type. 250 is Play SE.
#The mode that you set it to should be one of 'player_only', 'on_map', or 'none'
#That mode will persist until you change it back, or reset the defaults with the script call:
# npc_skip_mode_reset

#player_only
#Anything that seemed like it would be used for cutscenes - showing text or pictures, setting move routes,
#anything that requires or checks for input, changing text or windows, etc - these were all set to be player_only
#by default. IMPORTANTLY, changing variables - self-switches, control switches, control variables - I set all of
#these to be player_only by default as well, as I would imagine that anything that changes the state of the game
#should be usually be based on player agency (like, more obviously, Battle Processing)

#none
#Things with the "none" skip mode (commands that are never skipped) are basic logic - loops, conditionals, labels
#and label jumps - and wait commands. These do not modify the game state or have any visual or auditory side effects.

#Note that this script already overwrites Label, Exit Event Processing, and Transfer Player to handle
#various bits of functionality correctly, so changing the modes of these will probably either have no effect
#or be detrimental to the functionality of this script.

class Game_System
  attr_accessor   :skip_modes
  
  alias create_npc_skip_mode_hash initialize
  def initialize
    create_npc_skip_mode_hash
    initialize_npc_event_skip_modes
  end
  
  def initialize_npc_event_skip_modes
    @skip_modes = {
      101 => 'player_only',  # Show Text
      102 => 'player_only',  # Show Choices
      402 => 'player_only',  # When [**]
      403 => 'player_only',  # When Cancel
      103 => 'player_only',  # Input Number
      104 => 'player_only',  # Change Text Options
      105 => 'player_only',  # Button Input Processing
      106 => 'none',  # Wait
      111 => 'none',  # Conditional Branch
      411 => 'none',  # Else
      112 => 'none',  # Loop
      413 => 'none',  # Repeat Above
      113 => 'none',  # Break Loop
      115 => 'none',  # Exit Event Processing
      116 => 'player_only',  # Erase Event
      117 => 'none',  # Call Common Event
      118 => 'none',  # Label
      119 => 'none',  # Jump to Label
      121 => 'player_only',  # Control Switches
      122 => 'player_only',  # Control Variables
      123 => 'player_only',  # Control Self Switch
      124 => 'player_only',  # Control Timer
      125 => 'player_only',  # Change Gold
      126 => 'player_only',  # Change Items
      127 => 'player_only',  # Change Weapons
      128 => 'player_only',  # Change Armor
      129 => 'player_only',  # Change Party Member
      131 => 'player_only',  # Change Windowskin
      132 => 'player_only',  # Change Battle BGM
      133 => 'player_only',  # Change Battle End ME
      134 => 'player_only',  # Change Save Access
      135 => 'player_only',  # Change Menu Access
      136 => 'player_only',  # Change Encounter
      201 => 'none',  # Transfer Player
      202 => 'player_only',  # Set Event Location
      203 => 'player_only',  # Scroll Map
      204 => 'player_only',  # Change Map Settings
      205 => 'player_only',  # Change Fog Color Tone
      206 => 'player_only',  # Change Fog Opacity
      207 => 'on_map',  # Show Animation  #YOU MAY WANT TO CHANGE THIS
      208 => 'player_only',  # Change Transparent Flag
      209 => 'player_only',  # Set Move Route
      210 => 'player_only',  # Wait for Move's Completion
      221 => 'player_only',  # Prepare for Transition
      222 => 'player_only',  # Execute Transition
      223 => 'player_only',  # Change Screen Color Tone
      224 => 'player_only',  # Screen Flash
      225 => 'player_only',  # Screen Shake
      231 => 'player_only',  # Show Picture
      232 => 'player_only',  # Move Picture
      233 => 'player_only',  # Rotate Picture
      234 => 'player_only',  # Change Picture Color Tone
      235 => 'player_only',  # Erase Picture
      236 => 'player_only',  # Set Weather Effects
      241 => 'player_only',  # Play BGM
      242 => 'player_only',  # Fade Out BGM
      245 => 'player_only',  # Play BGS
      246 => 'player_only',  # Fade Out BGS
      247 => 'player_only',  # Memorize BGM/BGS
      248 => 'player_only',  # Restore BGM/BGS
      249 => 'on_map',  # Play ME
      250 => 'on_map',  # Play SE
      251 => 'player_only',  # Stop SE
      301 => 'player_only',  # Battle Processing
      601 => 'player_only',  # If Win
      602 => 'player_only',  # If Escape
      603 => 'player_only',  # If Lose
      302 => 'player_only',  # Shop Processing
      303 => 'player_only',  # Name Input Processing
      311 => 'player_only',  # Change HP
      312 => 'player_only',  # Change SP
      313 => 'player_only',  # Change State
      314 => 'player_only',  # Recover All
      315 => 'player_only',  # Change EXP
      316 => 'player_only',  # Change Level
      317 => 'player_only',  # Change Parameters
      318 => 'player_only',  # Change Skills
      319 => 'player_only',  # Change Equipment
      320 => 'player_only',  # Change Actor Name
      321 => 'player_only',  # Change Actor Class
      322 => 'player_only',  # Change Actor Graphic
      331 => 'player_only',  # Change Enemy HP
      332 => 'player_only',  # Change Enemy SP
      333 => 'player_only',  # Change Enemy State
      334 => 'player_only',  # Enemy Recover All
      335 => 'player_only',  # Enemy Appearance
      336 => 'player_only',  # Enemy Transform
      337 => 'player_only',  # Show Battle Animation
      338 => 'player_only',  # Deal Damage
      339 => 'player_only',  # Force Action
      340 => 'player_only',  # Abort Battle
      351 => 'player_only',  # Call Menu Screen
      352 => 'player_only',  # Call Save Screen
      353 => 'player_only',  # Game Over
      354 => 'player_only',  # Return to Title Screen
      355 => 'none'  # Script
    }
  end
end

# $npc_reachability[[A,B]] = C
#If you're on map A, trying to get to map B, then the best next map is C
$npc_reachability = {
} 
#maps are small enough that this is maintainable, don't need to make another graph-solving algorithm
#Optional; if you want NPC's to seek refuge from whether or threats you create (monsters, player crime sprees, etc),
#then you must register the map ids of maps that are considered to be indoors.

$register_indoor_maps = [
]

#TEXT MACROS
RESET_TEXT = "DAILY RESET"

#SWITCH/VARIABLE MACROS
SCHEDULE = 599 #a game switch of your choosing; usage will be explained elsewhere
TIME_SECONDS = 775 #set this to match the seconds variable from Heretic's Dynamic Lighting

#May have to freeze time or schedule or something if NPC's event is running while a
#key time change occurs

#used only for collision detection of offscreen NPCs; don't have to worry about
#Game_Map aliases

def dist(a,b)
  if a - b < 0
    return b - a
  else
    return a - b
  end
end

def npc_skip_mode_reset
  $game_system.initialize_npc_event_skip_modes
end

class Game_Event < Game_Character
  attr_accessor   :is_shadow
  #"is_shadow" refers to, "is this a fake event used in a skeleton map for collision only"
  alias npc_event_init initialize
  def initialize(map_id, event, is_shadow=false)
    npc_event_init(map_id, event)
    @is_shadow = is_shadow
    @run_once_toggle = 0
  end
  
  alias primary_map_update update
  def update
    if @is_shadow
      super
      # Automatic event starting determinant
      check_event_trigger_auto
      # If parallel process is valid
      if @interpreter != nil
        # If not running
        unless @interpreter.running?
          # Set up event
          @interpreter.setup(@list, @event.id)
        end
        # Update interpreter
        @interpreter.update
      end
    else
      primary_map_update
    end
  end
  
  def run_as_parallel(user, callback_params)
    @run_once_toggle = 2 #annoying but easy;
    @interpreter = Interpreter.new
    @interpreter.door_user = user
    @interpreter.user_dest = callback_params
  end
  
  alias kill_run_once_threads update
  def update
    if @run_once_toggle > 0
      @run_once_toggle -= 1
      if @run_once_toggle == 0
        @interpreter = nil
      end
    end
    kill_run_once_threads
  end
end

#==============================================================================
# ** Interpreter
#------------------------------------------------------------------------------
#==============================================================================
class Interpreter
  attr_accessor   :door_user
  attr_accessor   :user_dest
  
  def send_home
    $game_map.npcs[@event_id].send_home
  end
  def on_map?
    return ($game_map.npcs[@event_id].current_map == @map_id)
  end
  def is_npc?(name) #
    return ($game_map.npcs[@event_id].current_map == name)
  end
  
  alias npc_inter_setup setup
  def setup(list, event_id, is_npc=false)
    npc_inter_setup(list, event_id)
    @is_npc = is_npc
  end
  
  alias npc_inter_cmd_end command_end
  def command_end
    if @is_npc
      @list = nil
      if @main and @event_id > 0
        npc = $game_map.npcs[@event_id]
        npc.unlock
        npc.running = false
      end
    else
      npc_inter_cmd_end
    end
  end
  
  alias npc_start_events setup_starting_event
  def setup_starting_event
    npc_start_events
    for event in $game_map.npcs.values
      # If running event is found
      if event.starting
        # If not auto run
        if event.trigger < 3
          # Clear starting flag
          event.clear_starting
          # Lock
          event.lock
        end
        # Set up event
        setup(event.list, event.id, true)
        return
      end
    end
  end
end

#==============================================================================
# ** Game_Character
#------------------------------------------------------------------------------
#==============================================================================
class Game_Character
  alias npc_habits_passable passable?
  def passable?(x, y, d)
    bool = false
    temp_map = $game_map
    if self.is_a?(Game_NPC) && @current_map != $game_map.map_id
      if @other_map != nil
        $game_map = @other_map
      end
      #$game_map = new_map
    end
    if npc_habits_passable(x, y, d)
      # Get new coordinates
      bool = true
      new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
      new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
      for npc in temp_map.npcs.values
        # If event coordinates are consistent with move destination
        if ((self.is_a?(Game_Event) && (npc.current_map == @map_id)) or (self.is_a?(Game_Player) && (npc.current_map == $game_map.map_id))) \
          and npc.x == new_x and npc.y == new_y
          # If through is OFF
          if !npc.through
            bool = false
          end
        end
      end
    else
      bool = false
    end
    $game_map = temp_map
    return bool
  end
end

#==============================================================================
# ** Game_NPC
#------------------------------------------------------------------------------
#==============================================================================
class Game_NPC < Game_Event
  attr_accessor   :current_map
  attr_accessor   :p_id
  attr_accessor   :name
  attr_accessor   :running
  #attr_accessor   :event_base
  
  def initialize(map_id, p_id, event_base)
    @p_id = p_id #map id of NPC Set map
    @daily_reset = 0
    @total_interactions = 0 #TODO - store this somewhere more permanent, perhaps
        #in map setup function when about to switch out NPCs
    @today_interactions = 0
    @at_dest = true #going to have to think about how to handle first-time-setup
    @current_time = $game_variables[TIME_SECONDS]
    @name = event_base.name
    @schedule = []
    @known_locked = []
    @arrived = true
    super(map_id, event_base)
    @schedule = scrape_schedule
    start = pick_from_schedule()[1]['desired']
    @current_map = start[0]
    #if start[1] != -1 && start[2] != -1 #TODO: find good spot for them
    #  @x, @y = start[1], start[2]
    #end
    #@event_base = event_base
    self.update()
  end
  
  def interrupted?
    bool = @afraid_1 #small altercation or bad weather => head indoors
    bool = bool or @afraid_2 #move away from/avoid player
    bool = bool or @afraid_3 #big altercation => lock themselves inside home
    bool = bool or @investigating #guard confronting or hitman distraction
    bool = bool or @defeated
    return bool
  end
  
  def total_interactions
    return @total_interactions + @today_interactions
  end
  def today_interactions
    return @today_interactions
  end
  
  def reset #daily reset
    @total_interactions += @today_interactions #shouldn't do it like this - total should increase when interactions occur
    @today_interactions = 0
    @known_locked = []
  end
  
  def start
    super
    @running = true
  end
  
  def pick_from_schedule
    if @schedule == []
      return nil
    end
    time = $game_variables[TIME_SECONDS]
    if ((@current_time < @daily_reset) && (@daily_reset < time)) or \
      ((@current_time > time) && (time > @daily_reset))
      reset
    end
    i = 0
    while i < (@schedule.length - 1)
      if (time >= @schedule[i][0]) && (time < @schedule[i+1][0])
        break
      end
      i = i+1
    end
    return @schedule[i]
  end
  
  def check_arrived
    if @desired[0] == @current_map
      if @desired[1] == -1 or @desired[2] == -1
        @arrived = true
      else
        if @x == @desired[1] and @y == @desired[2]
          @arrived = true
        else
          @arrived = false
        end
      end
    else
      @arrived = false
    end
    return @arrived
  end
  
  #Note that this is NOT deterministic, necessarily;
  #you can put in multiple routes into $npc_reachability, to
  #inject some variety/life into things
  def get_next_map
    map = nil
    if $game_map.map_id == @current_map
      map = $game_map
    else
      map = @other_map
    end
    if @current_map == @desired[0]
      return 0
    else
      #if destination map is an option
      if (map.get_tps(@desired[0]) != [[]])
        return @desired[0]
      end
      #if there is a door to the destination and we know it isn't locked
      if (map.get_doors(@desired[0]) != [[]])
        for coord in map.get_doors(@desired[0])
          if !@known_locked.include?([coord[0],coord[1]])
            return @desired[0]
          end
        end
      end
      #$npc_reachability should be filled out; if you get a Key Error, that's on you
      options = $npc_reachability[[@current_map,@desired[0]]]
      return options.kind_of?(Array) ? options[rand(options.size)] : options
    end
  end
  
  def set_path
    if @desired[0] == @current_map
      if @desired[1] >= 0 && @desired[2] >= 0
        self.pathfind(@desired[1], @desired[2], self)
      end
    else
      mapId = get_next_map
      map = (@current_map == $game_map.map_id) ? $game_map : @other_map
      #to get to desired map...
      #if multiple tps/doors, assume the closer one is actually closer
      #because reworking the pathfinder to find the actual closer exit is really
      #not worth the coding hassle, the execution time, and the loss of user flexibility with pathfinding scripts
      if map.get_tps(mapId) != [[]]
        min, min_dist = [], 9999
        for coords in map.get_tps(mapId)
          dist_total = dist(@x, coords[0]) + dist(@y, coords[1])
          if dist_total < min_dist
            min = coords
            min_dist = dist_total
          end
        end
        @searching_tp = mapId
        self.pathfind(min[0], min[1], self)
      elsif map.get_doors(mapId) != [[]]
        min, min_dist = [], 9999
        for coords in map.get_doors(mapId)
          if @known_locked.include?([coords[0],coords[1]])
            next
          end
          dist_total = dist(@x, coords[0]) + dist(@y, coords[1])
          if dist_total < min_dist
            min = coords
            min_dist = dist_total
          end
        end
        @searching_door = mapId
        self.pathfind(min[0], min[1], self)
      end
    end
    @needs_path = false
  end
  
  def check_tps
    set = []
    to = @searching_tp
    tmap = nil
    if $game_map.map_id == @current_map
      tmap = $game_map
    else
      if @other_map == nil
        if $game_map.skeleton_maps.has_key?(@current_map)
          @other_map = $game_map.skeleton_maps[@current_map]
        else
          @other_map = Skeleton_Map.new()
          @other_map.setup(@current_map)
          $game_map.skeleton_maps[@current_map] = @other_map
        end
      end
      tmap = @other_map
    end
    set = tmap.get_tps(to)
    for location in set
      if @x == location[0] && @y == location[1]
        @current_map = to
        moveto(location[2], location[3])
        @needs_path = true
        @searching_tp = 0
      else
        return
      end
    end
  end
  
  def check_doors
    set = []
    to = @searching_door
    tmap = nil
    if $game_map.map_id == @current_map
      tmap = $game_map
    else
      if @other_map == nil
        if $game_map.skeleton_maps.has_key?(@current_map)
          @other_map = $game_map.skeleton_maps[@current_map]
        else
          @other_map = Skeleton_Map.new()
          @other_map.setup(@current_map)
          $game_map.skeleton_maps[@current_map] = @other_map
        end
      end
      tmap = @other_map
    end
    set = tmap.get_doors(to)
    for location in set
      if @x == location[0] && @y == location[1] && !@known_locked.include?([location[0],location[1]])
        case location[5]
        when 0
          @direction = 8
        when 1
          @direction = 2
        when 2
          @direction = 4
        when 3
          @direction = 6
        end
        tmap.events[location[4]].run_as_parallel(self, [to,location[2],location[3]])
        @searching_door = 0
      else
        return
      end
    end
  end
  
  def transfer(mapId, x, y)
    @current_map = mapId
    moveto(x, y)
    @needs_path = true
  end
  
  def update
    super
    if @schedule != [] && !self.interrupted? && !@captured
      if !moving?
        if @searching_tp
          check_tps
        end
        if @searching_door
          check_doors
        end
      end
      if @current_map == $game_map.map_id
        @other_map = nil
      else
        if @other_map == nil
          if $game_map.skeleton_maps.has_key?(@current_map)
            @other_map = $game_map.skeleton_maps[@current_map]
          else
            @other_map = Skeleton_Map.new()
            @other_map.setup(@current_map)
            $game_map.skeleton_maps[@current_map] = @other_map
          end
        end
      end
      last = @current_time
      behavior = pick_from_schedule()
      @current_time = behavior[0]
      if @current_time != last
        if !@running #can't change command list while in the middle of a process
          @list = behavior[1]['list']
          @list = [] if @list.nil?
          @list = @list.concat([RPG::EventCommand.new(115,0,[])])
        end
        #@at_dest = false
        
        #@current_map = behavior[1]['desired'][0] #change later
        #if @current_map == -1
        #  @current_map = $game_map.map_id
        #end
        @needs_path = true
        @desired = behavior[1]['desired']#[1..2] #x, y
      end
    end
    
    if @name == "Julie" && @current_map == 582 && @x = 6
      puts "looking for"
      puts @desired
      puts @needs_path
      puts check_arrived
    end
    
    if @needs_path && !check_arrived
      set_path
    end
    if @subdued
      #deal with later...
    elsif @afraid_1
      if self.indoors?
        if @current_map == $game_map.map_id
          #fled indoors, but player is also there
        else
          #do nothing? remove afraid?
        end
      else
        #go indoors
      end
    elsif @afraid_2
    elsif @afraid_3
    elsif @investigating
    elsif @defeated
    end
  end
  
  def send_home
    home = has_home?
    if home != []
      pathfind(home[0], home[1], self, 1000, nil, nil)
    end
  end
  
  def scrape_schedule
    schedule = []
    for page in @event.pages.reverse
      # Make possible referrence for event condition with c
      c = page.condition
      if ((c.switch1_id == SCHEDULE) or (c.switch2_id == SCHEDULE))
        #list times
        list = page.list
        current_time, schedule_list = @daily_reset, {}#{-1 => {'desired' => [-1,-1,-1], 'list' => []}}
        for line in list
          if line.code == 118 #is a label:
            #Time start [HR:MIN], Desired MapID, Desired X, Desired Y
            match = /(\d+):(\d+) (\d+) (\d+) (\d+)/.match(line.parameters[0])
            x, y = -1, -1
            if match == nil
              #Time start [HR:MIN], Desired MapID
              match = /(\d+):(\d+) (\d+)/.match(line.parameters[0])
            else
              x, y = match[4].to_i, match[5].to_i
            end
            hr = match[1].to_i
            min = match[2].to_i
            map_id = match[3].to_i
            
            current_time = hr*60*60 + min*60 #in seconds... because
            schedule_list[current_time] = {}
            schedule_list[current_time]['desired'] = [map_id, x, y]
          # If Command Code is a Comment (Code 108, 408 is Next Line Code)
          elsif line.code == 108
            #condition met
            match = /\\condition switch (\d+)/.match(line.parameters[0])
            if match
            else
              match = /\\condition variable [.+] (\d+)/.match(line.parameters[0])
              if match
                case match[1]
                when '<'
                when '<'
                when '<=','=<' #I know what you meant ;)
                when '=','=='
                when '>=','=>'
                when '!='
                end
              else
              end
            end
            #TODO
            #check for things like:
            #move type
            #trigger type
            #page index reroute
            #character image?
          else
            if !schedule_list.has_key?(current_time)
              schedule_list[current_time] = {}
            end
            if !schedule_list[current_time].has_key?("list")
              schedule_list[current_time]["list"] = []
            end
            schedule_list[current_time]["list"].push(line)
          end
        end
        times = schedule_list.keys.sort
        for time in times
          schedule.push([time, schedule_list[time]])
        end
        break #assume only 1 schedule page
      end
    end
    return schedule
  end
  
end

#==============================================================================
# ** Game_Map
#------------------------------------------------------------------------------
#==============================================================================
class Game_Map
  attr_accessor   :npcs
  attr_accessor   :skeleton_maps
  #attr_reader     :tps
  #attr_reader     :doors
  
  alias npc_habits_map_passable passable?
  def passable?(x, y, d, self_event = nil)
    if npc_habits_map_passable(x, y, d, self_event)
      # Change direction (0,2,4,6,8,10) to obstacle bit (0,1,2,4,8,0)
      bit = (1 << (d / 2 - 1)) & 0x0f
      # Loop in all npcs
      for event in npcs.values
        # If tiles other than self are consistent with coordinates
        if event.tile_id >= 0 and event != self_event and event.current_map == $game_map.map_id and
           event.x == x and event.y == y and not event.through
          # If obstacle bit is set
          if @passages[event.tile_id] & bit != 0
            # impassable
            return false
          # If obstacle bit is set in all directions
          elsif @passages[event.tile_id] & 0x0f == 0x0f
            # impassable
            return false
          # If priorities other than that are 0
          elsif @priorities[event.tile_id] == 0
            # passable
            return true
          end
        end
      end
    else
      return false
    end
    return true
  end
  
  def get_doors(dest_map)
    #doors: array:
    if @doors.has_key?(dest_map)
      return @doors[dest_map]
    else
      return [[]]
    end
    #[toMap, toX, toY, [list of authorized users]]
  end
  
  def get_tps(dest_map)
    #seam between two maps/edges:
    #[toMap, toX, toY]
    if @tps.has_key?(dest_map)
      return @tps[dest_map]
    else
      return [[]]
    end
  end
  
  alias npc_habits_gm_setup setup
  def setup(map_id)
    if @npcs == nil then @npcs = {} end
    if @skeleton_maps == nil then @skeleton_maps = {} end
    npc_habits_gm_setup(map_id)
    p_id = $map_info[map_id].parent_id
    _skeleton_keys = {}
    while p_id > 0
      if p_id == @npc_umbrella
        #same NPC set, don't need to update/change
        break
      end
      if $map_names[p_id].include?("NPC Set")
        @npcs = {}
        _map = load_data(sprintf("Data/Map%03d.rxdata", p_id))
        for i in _map.events.keys
           npc = Game_NPC.new(map_id, p_id, _map.events[i])
           @npcs[i] = npc
           _skeleton_keys[npc.current_map] = 0;
        end
        break
      end
      p_id = $map_info[p_id].parent_id
    end
    #delete unused skeleton maps
    @skeleton_maps.delete_if {|key, value| (!_skeleton_keys.keys.include?(key) or (key == $game_map.map_id)) }
    @doors = {}
    @tps = {}
    for event in @map.events.values
      #The MapId and destination X and Y, plus the direction
      match = /DOOR (\d+) (\d+) (\d+) (\d+)/i.match(event.name)
      if match
        dir = match[4].to_i;
        if dir < 0 or dir > 4
          dir = 0
        end
        _x = event.x + ((dir == 2) ? -1 : ((dir == 3) ? 1 : 0))
        _y = event.y + ((dir == 1) ? -1 : ((dir == 0) ? 1 : 0))
        if @doors.has_key?(match[1].to_i)
          @doors[match[1].to_i].push([_x, _y, match[2].to_i, match[3].to_i,event.id,dir]);
        else
          @doors[match[1].to_i] = [[_x, _y, match[2].to_i,match[3].to_i,event.id,dir]]
        end
      else
        #The MapId and destination X and Y; default direction of 0
        match = /DOOR (\d+) (\d+) (\d+)/i.match(event.name)
        if match
          _x = event.x
          _y = event.y + 1 #npc has "reached" the door-opening position when at the space below it
          if @doors.has_key?(match[1].to_i)
            @doors[match[1].to_i].push([_x, _y, match[2].to_i, match[3].to_i,event.id,0]);
          else
            @doors[match[1].to_i] = [[_x, _y, match[2].to_i,match[3].to_i,event.id,0]]
          end
        else
          #Just the MapId and direction; trust Transfer Player to handle X and Y
          match = /DOOR (\d+) (\d+)/i.match(event.name)
          if match
            dir = match[4].to_i;
            if dir < 0 or dir > 4
              dir = 0
            end
            _x = event.x + ((dir == 2) ? -1 : ((dir == 3) ? 1 : 0))
            _y = event.y + ((dir == 1) ? -1 : ((dir == 0) ? 1 : 0))
            if @doors.has_key?(match[1].to_i)
              @doors[match[1].to_i].push([_x, _y, -1,-1,event.id,match[2].to_i]);
            else
              @doors[match[1].to_i] = [[_x, _y, -1,-1,event.id,match[2].to_i]]
            end
          else
            #Just the MapId; trust Transfer Player to handle X and Y, default direction of 0
            match = /DOOR (\d+)/i.match(event.name)
            _x = event.x
            _y = event.y + 1
            if match
              if @doors.has_key?(match[1].to_i)
                @doors[match[1].to_i].push([_x, _y, -1,-1,event.id,0]);
              else
                @doors[match[1].to_i] = [[_x, _y, -1,-1,event.id,0]]
              end
            else
              match = /TP (\d+) (\d+) (\d+)/i.match(event.name)
              if match
                if @tps.has_key?(match[1].to_i)
                  @tps[match[1].to_i].push([event.x, event.y, match[2].to_i, match[3].to_i]);
                else
                  @tps[match[1].to_i] = [[event.x, event.y, match[2].to_i,match[3].to_i]]
                end
              end
            end
          end
        end
      end
    end
    @npc_umbrella = p_id
  end
  
  alias npc_habits_gm_update update
  def update
    npc_habits_gm_update
    for event in @npcs.values
      event.update
    end
    for map in @skeleton_maps.values
      map.update
    end
  end
  
  alias npc_habits_gm_refresh refresh
  def refresh
    npc_habits_gm_refresh
    for event in @npcs.values
      event.refresh
    end
    for map in @skeleton_maps.values
      map.refresh
    end
  end
end

#==============================================================================
# ** Spriteset_Map
#------------------------------------------------------------------------------
#==============================================================================
class Spriteset_Map
  
  alias npc_habits_sm_init initialize
  def initialize
    #@viewport1 = Viewport.new(0, 0, 640, 480)
    @npc_sprites = []
    npc_habits_sm_init
    for i in $game_map.npcs.keys.sort
      sprite = Sprite_NPC.new(@viewport1, $game_map.npcs[i])
      @npc_sprites.push(sprite)
    end
    update
  end
  
  alias npc_habits_sm_update update
  def update
    npc_habits_sm_update
    for sprite in @npc_sprites
      sprite.update
    end
  end
  
  alias npc_habits_sm_dispose dispose
  def dispose
    for sprite in @npc_sprites
      sprite.dispose
    end
    npc_habits_sm_dispose
  end
end

#==============================================================================
# ** Spriteset_NPC
#------------------------------------------------------------------------------
#==============================================================================
class Sprite_NPC < Sprite_Character
  
  def initialize(viewport, character = nil)
    @npc = character
    #if character != nil
    #  character = Game_Event.new(character.p_id, character.event_base)
    #end
    super(viewport, character)
  end
  
  def update
    super()
    self.visible = (@npc.current_map == $game_map.map_id)
  end
end

#==============================================================================
# ** Game_Player
#------------------------------------------------------------------------------
#==============================================================================
class Game_Player < Game_Character
  alias npc_player_cet_here check_event_trigger_here
  def check_event_trigger_here(triggers)
    result = false
    if !npc_player_cet_here(triggers)
      if $game_system.map_interpreter.running?
        return result
      end
      for event in $game_map.npcs.values
        # If event coordinates and triggers are consistent
        if event.current_map == $game_map.map_id and event.x == @x and event.y == @y and triggers.include?(event.trigger)
          # If starting determinant is same position event (other than jumping)
          if not event.jumping? and event.over_trigger?
            event.start
            result = true
          end
        end
      end
    else
      result = true
    end
    return result
  end

  alias npc_player_cet_there check_event_trigger_there
  def check_event_trigger_there(triggers)
    result = false
    if !npc_player_cet_there(triggers)
      if $game_system.map_interpreter.running?
        return result
      end
      new_x = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
      new_y = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
      # All event loops
      for event in $game_map.npcs.values
        # If event coordinates and triggers are consistent
        if event.current_map == $game_map.map_id and event.x == new_x and event.y == new_y and
           triggers.include?(event.trigger)
          # If starting determinant is front event (other than jumping)
          if not event.jumping? and not event.over_trigger?
            event.start
            result = true
          end
        end
      end
      # If fitting event is not found
      if result == false
        # If front tile is a counter
        if $game_map.counter?(new_x, new_y)
          # Calculate 1 tile inside coordinates
          new_x += (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
          new_y += (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
          # All event loops
          for event in $game_map.npcs.values
            # If event coordinates and triggers are consistent
            if event.current_map == $game_map.map_id and event.x == new_x and event.y == new_y and
               triggers.include?(event.trigger)
              # If starting determinant is front event (other than jumping)
              if not event.jumping? and not event.over_trigger?
                event.start
                result = true
              end
            end
          end
        end
      end
    else
      result = true
    end
    return result
  end
  
  alias npc_player_cet_touch check_event_trigger_touch
  def check_event_trigger_touch(x, y)
    result = false
    if !npc_player_cet_touch(x, y)
      if $game_system.map_interpreter.running?
        return result
      end
      # All event loops
      for event in $game_map.npcs.values
        # If event coordinates and triggers are consistent
        if event.current_map == $game_map.map_id and event.x == x and event.y == y and [1,2].include?(event.trigger)
          # If starting determinant is front event (other than jumping)
          if not event.jumping? and not event.over_trigger?
            event.start
            result = true
          end
        end
      end
    else
      result = true
    end
    return result
  end
end

#==============================================================================
# ** Interpreter (Commands)
#------------------------------------------------------------------------------
#==============================================================================
class Interpreter
  alias npc_conditional_branch command_111
  def command_111
    if @is_npc && @parameters[0] == 2
      result = false
      if @event_id > 0
        key = [$game_map.npcs[@event_id].p_id, @event_id, @parameters[1]]
        if @parameters[2] == 0
          result = ($game_self_switches[key] == true)
        else
          result = ($game_self_switches[key] != true)
        end
      end
      @branch[@list[@index].indent] = result
      if @branch[@list[@index].indent] == true
        @branch.delete(@list[@index].indent)
        return true
      end
      return command_skip
    end
    return npc_conditional_branch
  end
  
  #I don't ever want to use this, but I guess I should allow it
  alias npc_erase command_116
  def command_116
    if @is_npc
      if @event_id > 0
        # Erase event
        $game_map.npcs[@event_id].erase
      end
      @index += 1
    else
      npc_erase
    end
    return false
  end
  
  #this tells it to look for an NPC's self-switches as those of the events
  #on the NPC map; probably need to change Conditionl Branch code to seek there for NPCs
  alias npc_control_self command_123
  def command_123
    if @is_npc
      if @event_id > 0
        key = [$game_map.npcs[@event_id].p_id, @event_id, @parameters[0]]
        $game_self_switches[key] = (@parameters[1] == 0)
      end
      $game_map.need_refresh = true
    else
      npc_control_self
    end
    return true
  end
end

#==============================================================================
# ** Skeleton_Map - used for offscreen collision, pathing, etc
#------------------------------------------------------------------------------
#==============================================================================

class Skeleton_Map < Game_Map
  
  def initialize
    @map_id = 0
    @display_x = 0
    @display_y = 0
  end
  
  def setup(map_id)
    # Put map ID in @map_id memory
    @map_id = map_id
    # Load map from file and set @map
    @map = load_data(sprintf("Data/Map%03d.rxdata", @map_id))
    # set tile set information in opening instance variables
    tileset = $data_tilesets[@map.tileset_id]
    @tileset_name = tileset.tileset_name
    @autotile_names = tileset.autotile_names
    @panorama_name = tileset.panorama_name
    @panorama_hue = tileset.panorama_hue
    @fog_name = tileset.fog_name
    @fog_hue = tileset.fog_hue
    @fog_opacity = tileset.fog_opacity
    @fog_blend_type = tileset.fog_blend_type
    @fog_zoom = tileset.fog_zoom
    @fog_sx = tileset.fog_sx
    @fog_sy = tileset.fog_sy
    @battleback_name = tileset.battleback_name
    @passages = tileset.passages
    @priorities = tileset.priorities
    @terrain_tags = tileset.terrain_tags
    # Initialize displayed coordinates
    @display_x = 0
    @display_y = 0
    # Clear refresh request flag
    @need_refresh = false
    # Set map event data
    @events = {}
    for i in @map.events.keys
      @events[i] = Game_Event.new(@map_id, @map.events[i],true) #make them shadow events
    end
    # Set common event data
    @common_events = {}
    for i in 1...$data_common_events.size
      @common_events[i] = Game_CommonEvent.new(i)
    end
    @doors = {}
    @tps = {}
    for event in @map.events.values
      #The MapId and destination X and Y, plus the direction
      match = /DOOR (\d+) (\d+) (\d+) (\d+)/i.match(event.name)
      if match
        dir = match[4].to_i;
        if dir < 0 or dir > 4
          dir = 0
        end
        _x = event.x + ((dir == 2) ? -1 : ((dir == 3) ? 1 : 0))
        _y = event.y + ((dir == 1) ? -1 : ((dir == 0) ? 1 : 0))
        if @doors.has_key?(match[1].to_i)
          @doors[match[1].to_i].push([_x, _y, match[2].to_i, match[3].to_i,event.id,dir]);
        else
          @doors[match[1].to_i] = [[_x, _y, match[2].to_i,match[3].to_i,event.id,dir]]
        end
      else
        #The MapId and destination X and Y; default direction of 0
        match = /DOOR (\d+) (\d+) (\d+)/i.match(event.name)
        if match
          _x = event.x
          _y = event.y + 1 #npc has "reached" the door-opening position when at the space below it
          if @doors.has_key?(match[1].to_i)
            @doors[match[1].to_i].push([_x, _y, match[2].to_i, match[3].to_i,event.id,0]);
          else
            @doors[match[1].to_i] = [[_x, _y, match[2].to_i,match[3].to_i,event.id,0]]
          end
        else
          #Just the MapId and direction; trust Transfer Player to handle X and Y
          match = /DOOR (\d+) (\d+)/i.match(event.name)
          if match
            dir = match[4].to_i;
            if dir < 0 or dir > 4
              dir = 0
            end
            _x = event.x + ((dir == 2) ? -1 : ((dir == 3) ? 1 : 0))
            _y = event.y + ((dir == 1) ? -1 : ((dir == 0) ? 1 : 0))
            if @doors.has_key?(match[1].to_i)
              @doors[match[1].to_i].push([_x, _y, -1,-1,event.id,match[2].to_i]);
            else
              @doors[match[1].to_i] = [[_x, _y, -1,-1,event.id,match[2].to_i]]
            end
          else
            #Just the MapId; trust Transfer Player to handle X and Y, default direction of 0
            match = /DOOR (\d+)/i.match(event.name)
            _x = event.x
            _y = event.y + 1
            if match
              if @doors.has_key?(match[1].to_i)
                @doors[match[1].to_i].push([_x, _y, -1,-1,event.id,0]);
              else
                @doors[match[1].to_i] = [[_x, _y, -1,-1,event.id,0]]
              end
            else
              match = /TP (\d+) (\d+) (\d+)/i.match(event.name)
              if match
                if @tps.has_key?(match[1].to_i)
                  @tps[match[1].to_i].push([event.x, event.y, match[2].to_i, match[3].to_i]);
                else
                  @tps[match[1].to_i] = [[event.x, event.y, match[2].to_i,match[3].to_i]]
                end
              end
            end
          end
        end
      end
    end
    # Initialize all fog information
    @fog_ox = 0
    @fog_oy = 0
    @fog_tone = Tone.new(0, 0, 0, 0)
    @fog_tone_target = Tone.new(0, 0, 0, 0)
    @fog_tone_duration = 0
    @fog_opacity_duration = 0
    @fog_opacity_target = 0
    # Initialize scroll information
    @scroll_direction = 2
    @scroll_rest = 0
    @scroll_speed = 4
  end
  
  def refresh
    # If map ID is effective
    if @map_id > 0
      # Refresh all map events
      for event in @events.values
        event.refresh
      end
      # Refresh all common events
      #for common_event in @common_events.values
      #  common_event.refresh
      #end
    end
    # Clear refresh request flag
    @need_refresh = false
  end

  def passable?(x, y, d, self_event = nil)
    # If coordinates given are outside of the map
    unless valid?(x, y)
      # impassable
      return false
    end
    # Change direction (0,2,4,6,8,10) to obstacle bit (0,1,2,4,8,0)
    bit = (1 << (d / 2 - 1)) & 0x0f
    # Loop in all events
    for event in events.values
      # If tiles other than self are consistent with coordinates
      if event.tile_id >= 0 and event != self_event and
         event.x == x and event.y == y and not event.through
        # If obstacle bit is set
        if @passages[event.tile_id] & bit != 0
          # impassable
          return false
        # If obstacle bit is set in all directions
        elsif @passages[event.tile_id] & 0x0f == 0x0f
          # impassable
          return false
        # If priorities other than that are 0
        elsif @priorities[event.tile_id] == 0
          # passable
          return true
        end
      end
    end
    # Loop searches in order from top of layer
    for i in [2, 1, 0]
      # Get tile ID
      tile_id = data[x, y, i]
      # Tile ID acquistion failure
      if tile_id == nil
        # impassable
        return false
      # If obstacle bit is set
      elsif @passages[tile_id] & bit != 0
        # impassable
        return false
      # If obstacle bit is set in all directions
      elsif @passages[tile_id] & 0x0f == 0x0f
        # impassable
        return false
      # If priorities other than that are 0
      elsif @priorities[tile_id] == 0
        # passable
        return true
      end
    end
    # passable
    return true
  end

  def terrain_tag(x, y)
    if @map_id != 0
      for i in [2, 1, 0]
        tile_id = data[x, y, i]
        if tile_id == nil
          return 0
        elsif @terrain_tags[tile_id] > 0
          return @terrain_tags[tile_id]
        end
      end
    end
    return 0
  end

  #check_npc version?
  #def check_event(x, y)
  #  for event in $game_map.events.values
  #    if event.x == x and event.y == y
  #      return event.id
  #    end
  #  end
  #end

  def update
    # Refresh map if necessary
    if $game_map.need_refresh
      refresh
    end
    # If scrolling
    if @scroll_rest > 0
      # Change from scroll speed to distance in map coordinates
      distance = 2 ** @scroll_speed
      # Execute scrolling
      case @scroll_direction
      when 2  # Down
        scroll_down(distance)
      when 4  # Left
        scroll_left(distance)
      when 6  # Right
        scroll_right(distance)
      when 8  # Up
        scroll_up(distance)
      end
      # Subtract distance scrolled
      @scroll_rest -= distance
    end
    # Update map event
    for event in @events.values
      event.update
    end
    # Update common event
    #for common_event in @common_events.values
    #  common_event.update
    #end
  end
  
  #leave passable? as is? No - since this is a different object, have to
  #detect potential NPC-on-NPC collisions via the $game_map? OR, is that
  #handled already in the character passable alias, where they just directly
  #compare map ids?
  
end

#==============================================================================
# ** Interpreter (Door Opening Protocol)
#------------------------------------------------------------------------------
#==============================================================================

class Interpreter
  #Look out for important labels
  alias door_handle_labels command_118
  def command_118
    labelname = @parameters[0]
    match = /DOOR LOCK (.+)/i.match(labelname)
    if match
      if @door_user != nil && match[1] == @door_user.name
        #door is locked, abort
        #PUT SOMETHING HERE TO NOTIFY THE NPC THEY DIDN'T GO THROUGH
        #exit event processing
        return command_115
      end
    end
    return door_handle_labels
  end
  
  alias end_door_handling command_115
  def command_115
    if @door_user != nil
      #if they are still on this map, make sure they're visible and figure out what to do next
      
    end
    @door_user = nil
    @user_dest = nil
    return end_door_handling
  end
  
  alias player_unaffected command_201
  def command_201
    if @door_user != nil
      puts @door_user.name
      if @user_dest.include?(-1)
        @door_user.transfer(@parameters[1],@parameters[2],@parameters[3])
      else
        @door_user.transfer(@user_dest[0],@user_dest[1],@user_dest[2])
      end
      return true
    end
    return player_unaffected
  end
  
  alias npc_skip_ex_com execute_command
  def execute_command
    if @door_user != nil
      if ![115, 118, 201].include?(@list[@index].code)
        if $game_system.skip_modes.has_key?(@list[@index].code)
          case $game_system.skip_modes[@list[@index].code]
          when 'player_only'
            return true #if door user not nil, this is an NPC, not player
          when 'on_map'
            if @door_user.current_map == $game_map.map_id
              puts "on_map playing"
              puts @list[@index]
              #pass
            else
              return true
            end
          when 'none'
            #pass
          else
            #pass
          end
        end
      end
    end
    return npc_skip_ex_com
  end
end
