local require = modlib.mod.require

require("crumbling")
require("support")

local generate_extrusion_mesh = require("generate_extrusion_mesh")

local modname = minetest.get_current_modname()

local function dig_and_give(name, count)
	return function(pos, _, digger)
		inv.try_increment_count(digger, name, count or 1) -- discard items silently if at max
		minetest.remove_node(pos) -- HACK this should not be necessary
		return true
	end
end

local function plant(def)
	return modlib.table.deepcomplete(def, {
		drawtype = "plantlike",
		paramtype2 = "none", -- "facedir" is not supported
		groups = { organics = 1 },
		drop = {},
		on_dig = dig_and_give("organics", 1),
		walkable = false,
		_support = "floor",
	})
end

local function glowing_dust_particlespawner_adder(name)
	return function(pos)
		return minetest.add_particlespawner({
			amount = 2,
			time = 0,
			pos = {
				min = pos:subtract(0.5),
				max = pos:add(0.5),
			},
			vel = {
				min = vector.new(-1, 0.5, -1),
				max = vector.new(1, 2, 1),
			},
			drag = 0.75,
			acc = vector.new(0, -2, 0),
			size = {},
			exptime = {
				min = 1,
				max = 3,
			},
			texpool = {
				{
					name = ("%s_particle_glowing_dust_%s_%d.png"):format(modname, name, 1),
					alpha = 0.3,
					scale = 1.5,
					animation = {
						type = "vertical_frames",
						aspect_w = 16,
						aspect_h = 16,
						length = 3,
					},
				},
			},
			collisiondetection = true,
			collision_removal = true,
		})
	end
end

local glowing_variants = {
	frozen = { _variants = 4, _add_particlespawner = glowing_dust_particlespawner_adder("frozen") },
	green = { _variants = 4, _add_particlespawner = glowing_dust_particlespawner_adder("magmatic") },
	magmatic = { _variants = 4, _add_particlespawner = glowing_dust_particlespawner_adder("magmatic") },
}

local saturnium_chance = 0.5 -- TODO tweak
local saturnium_variants = {
	_variants = 4,
	on_dig = function(pos, _, digger)
		if math.random() < saturnium_chance then
			inv.try_increment_count(digger, "saturnium", 1) -- discard items silently if at max
		end
		minetest.remove_node(pos) -- HACK this should not be necessary
		return true
	end,
}

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
		_ore_bearing = true,
		_children = {
			cracked = { _variants = 4 },
			crumbling = { _variants = 4 },
			granite = { _variants = 2 },
			lava = { _variants = 4 },
		},
	},
	carbon = {
		groups = { drillable = 1 },
		on_dig = dig_and_give("carbon", 10),
		_variants = 4,
	},
	granite = {
		groups = { drillable = 2 },
		drop = {},
		_variants = 4,
		_ore_bearing = true,
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
				_ore_bearing = true,
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
		use_texture_alpha = "clip",
		_children = {
			flower = plant({
				_children = {
					blue = { _variants = 4 },
					red = { _variants = 4 },
					white = { _variants = 4 },
					saturnium = saturnium_variants,
				},
			}),
			grass = plant({
				_variants = 4,
				_children = {
					saturnium = saturnium_variants,
					dry = { _variants = 4 },
					glowing = {
						_children = glowing_variants,
					},
				},
			}),
			mushroom = plant({
				_children = {
					glowing = {
						_children = glowing_variants,
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
						drop = {},
						on_dig = dig_and_give("organics", 1),
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
			vines = plant({
				_variants = 4,
				_children = {
					saturnium = saturnium_variants,
					dry = { _variants = 4 },
					glowing = {
						_children = glowing_variants,
					},
				},
			}),
			-- TODO multi-node decorations (stalactites, stalagmites, icicles), complete decorations
		},
	},
}

-- Ores

local function ore_texture(name, tier_name, variant)
	return ("%s_ore_%s_%s_%d.png"):format(modname, name, tier_name, variant)
end

local ore_tiers = {
	{
		name = "poor",
		groups = { drillable = 1 },
		_drop_count = 1,
		_variants = 4,
	},
	{
		name = "medium",
		groups = { drillable = 1 },
		_drop_count = 3,
		_variants = 4,
	},
	{
		name = "rich",
		groups = { drillable = 2 },
		_drop_count = 6,
		_variants = 4,
	},
	{
		name = "abundant",
		groups = { drillable = 3 },
		_drop_count = 9,
		_variants = 1,
	},
}

local ores = {
	coal = "carbon",
	iron = "iron_ore",
}

local defs_by_path = {}
local ore_cids = { coal = {}, iron = {} } -- nested table structure: [ore name][bearing node cid][tier idx] = ore cids

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
			local nodename = ("%s:%s_%d"):format(modname, pathname, variant)
			local node_def = modlib.table.deepcomplete(table.copy(def), completions)
			minetest.register_node(nodename, node_def)
			local cid = minetest.get_content_id(nodename)
			if def._ore_bearing then
				for ore_name, drop_name in pairs(ores) do
					ore_cids[ore_name][cid] = {}
					for tier_idx, tier_def in ipairs(ore_tiers) do
						ore_cids[ore_name][cid][tier_idx] = {}
						local tier_name = tier_def.name
						for ore_variant = 1, tier_def._variants do
							local ore_node_name = ("%s_ore_%s_%s_%d"):format(nodename, ore_name, tier_name, ore_variant)
							minetest.register_node(
								ore_node_name,
								modlib.table.deep_add_all(modlib.table.deep_add_all(table.copy(node_def), tier_def), {
									tiles = {
										node_def.tiles[1] .. "^" .. ore_texture(ore_name, tier_name, ore_variant),
									},
									on_dig = dig_and_give(drop_name, tier_def._drop_count),
								})
							)
							table.insert(ore_cids[ore_name][cid][tier_idx], minetest.get_content_id(ore_node_name))
						end
					end
				end
			end
		end
	end
	-- Recursively register "child" nodes
	if def._children then
		for child_name, child_def in pairs(def._children) do
			local parent_def = table.copy(def)
			-- Do not inherit these properties
			parent_def._children, parent_def._variants, parent_def._ore_bearing = nil, nil, nil
			modlib.table.deep_add_all(parent_def, { groups = { [name] = 1 } })
			modlib.table.deep_add_all(parent_def, child_def)
			register_nodes(pathname .. "_" .. child_name, child_name, parent_def)
		end
	end
end

for name, def in pairs(nodes) do
	register_nodes(name, name, def)
end

require("node_particles") -- NOTE: This needs to run *after* node registrations.

return { nodes = defs_by_path, ore_cids = ore_cids }
