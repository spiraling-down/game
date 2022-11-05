---
---Simple perlin noise mapgen with caverns and customizable layers of stone as you go deeper
---

--
--Ores and lava are TODO
--

local transition_size = 30

local surface_node = "default:dirt" --obviously replace with correct node

--IMPORTANT!!!
--Stone layers MUST be given in order of deepest to shallowest
local stone_layers = {
	{
		height = -1000000, --basically -inf
		name = "default:gravel",
	},
	{
		height = -200,
		name = "default:tree",
	},
	{
		height = -150,
		name = "default:steelblock",
	},
	{
		height = -100,
		name = "default:goldblock",
	},
	{
		height = -50,
		name = "default:stone",
	},
}

local lavas = {}

local ores = {}
minetest.register_on_mods_loaded(function()
	for i, v in pairs(stone_layers) do
		v.content_id = minetest.get_content_id(v.name)
	end
end)

minetest.register_on_generated(function(min, max, seed)
	local surface_id = minetest.get_content_id(surface_node)

	local surface_scalar = 10 --how tall the hills are
	local surface_noise = minetest.get_perlin({
		offset = 0,
		scale = 1,
		spread = { x = 50, y = 50, z = 50 },
		seed = 1,
		octaves = 5,
		persistence = 0.5,
		lacunarity = 2.0,
	})

	local cavern_scalar = 10
	local cavern_rare = 1 --The lua api said that noise ranges from -2 to 2, so setting this to 0 means the map is 50% cavern, 1 means that map is 25% cavern, 2 means that map is 0% cavern
	local cavern_noise = minetest.get_perlin({
		offset = 0,
		scale = 1,
		spread = { x = 50, y = 50, z = 50 },
		seed = 2,
		octaves = 5,
		persistence = 0.5,
		lacunarity = 2.0,
	})

	local ore_scalar = 10
	local ore_rare = 1

	local ore_noise = minetest.get_perlin({
		offset = 0,
		scale = 1,
		spread = { x = 50, y = 50, z = 50 },
		seed = 2,
		octaves = 5,
		persistence = 0.5,
		lacunarity = 2.0,
	})

	local vm = minetest.get_mapgen_object("voxelmanip")
	local emin, emax = vm:read_from_map(min, max)
	local va = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
	local data = vm:get_data()
	for z = min.z, max.z do
		for y = min.y, max.y do
			for x = min.x, max.x do
				local idx = va:index(x, y, z)
				--Is this pos underground?
				if y < surface_noise:get_2d({ x = x, y = z }) * surface_scalar then
					--Wait! only add a block if you are not in a cavern
					if cavern_noise:get_3d({ x = x, y = y, z = z }) * cavern_scalar < cavern_rare * cavern_scalar then
						--find out what layer we are in
						for i, stone in ipairs(stone_layers) do
							if y - stone.height > surface_noise:get_3d({ x = x, y = y, z = z }) * transition_size then
								data[idx] = stone.content_id
							end
						end
					end
				elseif y - surface_noise:get_2d({ x = x, y = z }) * surface_scalar < 1 then --If we are one block above the surface, then add the surface node
					data[idx] = surface_id
				end
			end
		end
	end
	vm:set_data(data)
	vm:write_to_map()
end)
