modlib.mod.require("crumbling")

local modname = minetest.get_current_modname()

local function dig_and_give(name)
	return function(_, _, digger)
		inv.try_increment_count(digger, name) -- discard items silently if at max
		return true
	end
end

local nodes = {
	mantle = {
		groups = { drillable = 1 },
		drop = {},
		_variants = 4,
	},
	basalt = {
		groups = { drillable = 2 },
		drop = {},
		_variants = 4,
		_children = {
			cracked = { _variants = 2 },
			crumbling = { _variants = 2 },
			granite = { _variants = 2 },
			lava = { _variants = 4 },
		},
	},
	carbon = {
		groups = { drillable = 1 },
		on_dig = dig_and_give("carbon"),
		_variants = 4,
	},
	granite = {
		groups = { drillable = 2 },
		drop = {},
		_variants = 4,
		_children = {
			cracked = { _variants = 2 },
			crumbling = { _variants = 2 },
			basalt = { _variants = 4 },
			dark = { _variants = 4 },
			semifrozen = {
				_variants = 4,
				_children = {
					cracked = { _variants = 2 },
					crumbling = { _variants = 2 },
				},
			},
			frozen = {
				_variants = 4,
				_children = {
					cracked = { _variants = 2 },
					crumbling = { _variants = 2 },
					subdued = { _variants = 4 },
				},
			},
		},
	},
	lava = {
		_variants = 4,
		_children = {
			basalt = { _variants = 4 },
		},
	},
	limestone = {
		groups = { drillable = 2 },
		drop = {},
		_variants = 4,
		_children = {
			cracked = { _variants = 2 },
			crumbling = { _variants = 2 },
		},
	},
	obsidian = {
		groups = { drillable = 3 },
		drop = {},
		_variants = 2,
		_children = {
			cracked = { _variants = 2 },
			crumbling = { _variants = 2 },
		},
	},
	sand = {
		groups = { drillable = 1 },
		on_dig = dig_and_give("sand"),
		_variants = 4,
		_children = {
			basalt = { _variants = 4 },
			frozen = { _variants = 4 },
			granite = { _variants = 4 },
			red = { _variants = 4 },
		},
	},
}

local function register_nodes(pathname, name, def)
	if def._variants then
		for variant = 1, def._variants do
			minetest.register_node(
				("%s:%s_%d"):format(modname, pathname, variant),
				modlib.table.deepcomplete(table.copy(def), {
					tiles = { ("%s_%s_%d.png"):format(modname, pathname, variant) },
					groups = { [name] = 1 }, -- add node name as group
				})
			)
		end
	end
	-- Recursively register "child" nodes
	if def._children then
		for child_name, child_def in pairs(def._children) do
			local parent_def = table.copy(def)
			parent_def._children = nil
			modlib.table.deep_add_all(parent_def, { groups = { [name] = 1 } })
			modlib.table.deep_add_all(parent_def, child_def)
			register_nodes(pathname .. "_" .. child_name, child_name, parent_def)
		end
	end
end

for name, def in pairs(nodes) do
	register_nodes(name, name, def)
end

return nodes
