QA Block to run checking scripts for beter quality assurance of code
=======

License GPL-V3: https://www.gnu.org/licenses/gpl-3.0.html

This is a developer helper mod, allow run any lua code for testing reason. The mod can list and run lua-scripts placed in checks subfolder. some check scrips provided.

# Features
  list files on DOS and *NIX OS
  redirection of print() output to minetest chat. (can be disabled by changing code line "print_to_chat"
  robust call of the scripts trough "pcall" does not crash the game in case of syntax- or runtime errors
  run scripts using chat command or the QA-Block node

#Dependencies
  default - some default tiles and sounds used on block from default
  smartfs - optional, enable GUI for check selection (latest version from my fork https://github.com/bell07/minetest-smartfs till the push request is accepted)

#Available check modules
  same_recipe - check installed items for similar recipe
  list_spawning_mobs - just list mobs.spawning_mobs variable
  own modules can be placed

#How to use:
add the mod to the game you like to test

## Using chat command /qa_block
  qa_block ls - list all available check modules
  qa_block sel - display and run check using the selection dialog (smartfs only)
  qa_block checkname - run check

## Using the block
1. get the QA-Block from creative inventory
2. place the block somewhere
3a - without smartfs - wait till the block disappears
3b - with smartfs - start the check using selection dialog

In all cases - check the debug.txt for test results
