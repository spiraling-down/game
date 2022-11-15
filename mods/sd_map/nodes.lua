local require = modlib.mod.require

require("crumbling")

local generate_extrusion_mesh = require("generate_extrusion_mesh")

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
			cracked = { _variants = 4 },
			crumbling = { _variants = 4 },
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
			cracked = { _variants = 4 },
			crumbling = { _variants = 4 },
			basalt = { _variants = 4 },
			dark = { _variants = 4 },
			semifrozen = {
				_variants = 4,
				_children = {
					cracked = { _variants = 4 },
					crumbling = { _variants = 4 },
				},
			},
			frozen = {
				_variants = 4,
				_children = {
					cracked = { _variants = 4 },
					crumbling = { _variants = 4 },
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
			cracked = { _variants = 4 },
			crumbling = { _variants = 4 },
		},
	},
	obsidian = {
		groups = { drillable = 3 },
		drop = {},
		_variants = 4,
		_children = {
			cracked = { _variants = 4 },
			crumbling = { _variants = 4 },
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
	deco = {
		sunlight_propagates = true,
		paramtype = "light",
		paramtype2 = "facedir", -- allow randomizing rotations
		_children = {
			flower = plant({
				_children = {
					blue = {
						_variants = 4,
					},
					red = {
						_variants = 4,
					},
					white = {
						_variants = 4,
					},
					saturnium = {
						_children = {
							small = { _variants = 1 },
							medium = { _variants = 1 },
							large = { _variants = 1 },
						},
					},
				},
			}),
			grass = plant({
				_variants = 4,
				_children = {
					dry = {
						_variants = 4,
					},
					glowing_green = {
						_variants = 4,
					},
				},
			}),
			mushroom = plant({
				_children = {
					glowing_green = {
						_variants = 4,
					},
					glowing_blue = {
						_variants = 4,
					},
				},
			}),
			pebbles = {
				groups = { drillable = 1 },
				drop = {},
				paramtype2 = "facedir",
				_drawtype = "plate",
				_children = {
					basalt = { _variants = 4 },
					granite = { _variants = 4 },
					limestone = { _variants = 4 },
				},
			},
			pile = {
				groups = { drillable = 1 },
				drop = {},
				paramtype2 = "facedir",
				_drawtype = "plate",
				_children = {
					ash = { _variants = 4 },
					snow = { _variants = 4 },
					sand = {
						_variants = 4,
						_children = {
							red = { _variants = 4 },
						},
					},
				},
			},
			rubble = {
				paramtype2 = "facedir",
				_drawtype = "plate",
				_children = {
					organics = {
						_variants = 4,
						_children = {
							dry = { _variants = 4 },
							frozen = { _variants = 4 },
						},
					},
				},
			},
			shell = {
				groups = { drillable = 1 },
				drop = {},
				paramtype2 = "facedir",
				_drawtype = "plate",
				_variants = 8,
			},
			-- TODO vines, multi-node decorations (stalactites, stalagmites, icicles), complete decorations
		},
	},
}

local defs_by_path = {}

local function register_nodes(pathname, name, def)
	if def._variants then
		defs_by_path[pathname] = def
		for variant = 1, def._variants do
			local medianame = ("%s_%s_%d"):format(modname, pathname, variant)
			local completions = {
				tiles = { medianame .. ".png" },
				groups = { [name] = 1 }, -- add node name as group
			}
			if def._drawtype == "plate" then
				local res = generate_extrusion_mesh(medianame .. ".png", medianame .. ".obj")
				completions.drawtype = "mesh"
				completions.mesh = medianame .. ".obj"
				local box = {
					type = "fixed",
					fixed = { -0.5, -0.5, -0.5, 0.5, 1 / res - 0.5, 0.5 },
				}
				completions.selection_box = box
				completions.collision_box = box
			end
			minetest.register_node(
				("%s:%s_%d"):format(modname, pathname, variant),
				modlib.table.deepcomplete(table.copy(def), completions)
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

return defs_by_path
