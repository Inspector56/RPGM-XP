# RPGM-XP
Compilation of scripts for RPGM XP

Compilation of Scripts/Plugins written for RPGM MV

All listed plugins should be assumed unrelated. All are only tested in a Windows environment, and have not been rigorously tested in a large-scale, sophisticated game. Some features may not be fully implemented; to the best of my knowledge, all such cases are documented.

AltScene
--------
This is a set of scripts aimed at eventually being a sort of alternate engine that provides some of the features and options that the default engine lacks. Textboxes, Buttons, Dragable items, Inventories/Dropboxes, Minigames, and more.
The framework requires a lot of assets on the user's part. I have included some basic samples.
Furthermore, it is intended to make it easier to define new scenes; rather than a complex cascade of functions between interconnected objects, this design is much more hierarchical; a scene is defined - the appropriate Buttons and Textboxes put in place, and then it runs itself.

LevelStats
----------
A modified version of the status screen; not only have the stats shown/available been changed, but for each actor, leveling up will earn level points, that can be spent to increase one stat. These stats are used instead of the level curves in combat. Downsides: it is not particularly easy or intuitive to change the list of stats, if you disagree with my list, and while you can choose different base stats/starting allocations, there is not currently any way to make characters level uniquely - they all scale identically, and the level caps are not unique.

SkillTreeMenu
-------------
Designed to be used with LevelStats (not using LevelStats will require changing some Menu code), this allows for creating unique (per-actor) skill-tree Scenes. It requires the user to make a unique background and type a lot of information, but it is a framework that still makes the process more streamlined and convenient.
