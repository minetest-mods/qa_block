QA Block to run checking scripts for better quality assurance of code
=======

License GPL-V3: https://www.gnu.org/licenses/gpl-3.0.html

This is a developer helper mod. It allows to run any lua code for testing reason. The mod can list and run lua-scripts placed in `checks` subfolder. Some check scripts are provided with the mod.
The second part allows to display global lua-tables variables tree for debugging.

## Features
- redirection of print() output to minetest chat
- redirection of print() output to a log file in the world directory. The output is sorted so that it can be compared to find regressions
- robust call of the scripts trough "pcall" does not crash the game in case of syntax- or runtime errors
- all functionality available through chat commands and the QA-Block node
- refresh and list the checks script list at runtime
- edit the code before calling them
- type code and run it
- explore global variables/lua tables

![Screenshot](screenshot_20170121_012152.png)
![Screenshot](screenshot_20170121_011613.png)

https://forum.minetest.net/viewtopic.php?f=11&t=15759

## Dependencies
- none
  - smartfs(provided) - GUI for check selection and manipulation. Optional, but without smartfs there is limited functionality 


## Provided check modules
- broken_recipe - Find crafting recipes which require unknown items
- empty - Empty file for your own checks
- get_item_csv - Export all registered items in a .CSV file
- global_variables - Browse all global variables and see their content
- graphviz_recipes_all - Make a graphviz .dot file of all items in a recipe dependency tree
- is_ground_content - This checker lists all nodes for which is_ground_content == true
- list_entities - Lists all the registered entities (except builtin)
- list_spawning_mobs - List entities that are mobs from mobs_redo or compatible framework
- no_doc_items_help - Lists all items without item usage help or long description
- no_item_description - Lists all items without description
- no_sounds - Find nodes that don't have any sounds associated when dug, walked on, etc.
- redundant_items - Lists items which seem redundant
- same_recipe - Find duplicate crafting recipes
- unobtainable_items - Lists items which seem to be unobtainable
- useless_items - Lists all items which are probably useless

## How to use:
add the mod to the game you like to test

### Using chat command /qa
- /qa help - print available chat commands
- /qa ls - list all available check modules
- /qa set checkname - set default check
- /qa ui - display and run check using the selection dialog. Browse trough globals (smartfs only)
- /qa checkname - run check
- /qa - run default check

### Using the block
1. get the QA-Block from creative inventory
2. place the block somewhere
3a - without smartfs - wait till the default check is finished and the block disappears
3b - with smartfs - start the check using selection dialog

In all cases - check the debug.txt for test results

### Minetest Configuration Parameters
- print_to_chat:bool Output QA check messages to chat
- log_to_file:bool Output QA check messages to a file
- overwrite_log:bool Overwrite the file at every game launch
- log_date_time:bool Prepend a date and time stamp to log messages
- date_and_time_format:string Date and time stamp format

## Credits
- [Wuzzy2](https://codeberg.org/Wuzzy) - thanks for ideas, code optimizations and most check scripts
- [dacmot](https://www.github.com/dacmot) - for adding output to log file and configuration parameters
