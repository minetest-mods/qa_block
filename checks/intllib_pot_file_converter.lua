-- Text tables conversion to gettext po/pot format

-- Expamle is smart_inventory groups texts the script was developed for
-- But you can use it as template for any conversions if the texts already exists in an global accessable lua table

-- initial conversion and check report po file of current logged on language
local filename_po = minetest.get_worldpath().."/converter_out.po"
local file_po = io.open(filename_po, "w")

for key, text in pairs(smart_inventory.txt) do
	file_po:write('msgid "'..key..'"\n')
	file_po:write('msgstr "'..text..'"\n')
	file_po:write('\n')
end
file_po:close()

local filename_pot = minetest.get_worldpath().."/converter_out.pot"
local file_pot = io.open(filename_pot, "w")

local sorted = {}
for key, _ in pairs(smart_inventory.cache.cgroups) do
	if tonumber(key:sub(-1)) == nil and -- only without numeric suffix,
			key:sub(-1) ~= "%"          -- percent values are numeric too
			and key:sub(1,11) ~= 'ingredient:'  -- exclude technical groups
			and key:sub(1,4) ~= 'mod:' then
		table.insert(sorted, key)
	end
end
table.sort(sorted)

for _, key in ipairs(sorted) do
	file_pot:write('msgid "'..key..'"\n')
	file_pot:write('msgstr ""\n')
	file_pot:write('\n')
end
file_pot:close()

print("look to your world dir for out.pot and out.po files")
