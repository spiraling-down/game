-- NOTE: `transition = n` is supported but currently unused;
-- problematic groups have been outcommented
-- TODO: Use `weather`, `inclusions`
layers = {
	{
		name = "Near Absolute Zero",
		weather = "blizzard",
		height = 20,
		node = "mantle",
		inclusions = {},
		decorations = {},
	},
	{
		name = "Glacial Howl",
		weather = "blizzard",
		height = 100,
		node = "granite_frozen",
		inclusions = { "sand_frozen", "granite_frozen_subdued" },
		decorations = {
			floor = {
				"mushrooms_glowing_frozen",
				"debris_frozen",
				"pile_snow",
				-- "icicle_floor",
			},
			ceiling = {
				"vines_glowing_frozen",
				-- "icicle_ceiling",
			},
		},
	},
	{
		name = "Defrosting",
		weather = "blizzard",
		height = 50,
		node = "granite_semifrozen",
		inclusions = { "limestone", "sand_red" },
		decorations = {
			floor = {
				"mushrooms_glowing_frozen",
				"debris_frozen",
				"pile_snow",
				-- "icicle_floor",
			},
			ceiling = {
				"vines_glowing_frozen",
				-- "icicle_ceiling",
			},
		},
	},
	{
		name = "Room Temperature",
		weather = "sandstorm",
		height = 50,
		node = "granite",
		inclusions = { "limestone", "basalt", "sand_red" },
		decorations = {
			floor = {
				-- "stalagmite_granite",
				"grass_dry",
				"debris_dry",
			},
			ceiling = {
				-- "stalactite_granite",
				"vines_dry",
			},
		},
	},
	{
		name = "Getting Hotter",
		weather = "sandstorm",
		height = 50,
		node = "granite",
		inclusions = { "limestone", "basalt", "sand_red" },
		decorations = {
			floor = {
				"flowers_blue",
				"flowers_red",
				-- "stalagmite_granite",
				"grass",
				"mushrooms_glowing_green",
			},
			ceiling = {
				-- "stalactite_granite",
				"vines",
				"vines_glowing_green",
			},
		},
	},
	{
		name = "Getting (even) Hotter",
		weather = "fallout",
		height = 50,
		node = "basalt",
		inclusions = {
			"limestone",
			"basalt",
			"sand_red",
		},
		decorations = {
			floor = {
				"flowers_blue",
				"flowers_red",
				-- "stalagmite_basalt",
				"grass",
				"mushrooms_glowing_green",
			},
			ceiling = {
				-- "stalactite_basalt",
				"vines_glowing_magmatic",
				"vines",
			},
		},
	},
	{
		name = "Volcanic Roar",
		weather = "fallout",
		height = 50,
		node = "basalt",
		inclusions = {
			"obsidian",
			"sand",
		},
		decorations = {
			floor = {
				"flowers_blue",
				"flowers_red",
				-- "stalagmite_basalt",
				"grass",
				"mushrooms_glowing_green",
				"grass_glowing_magmatic",
			},
			ceiling = {
				-- "stalactite_basalt",
				"vines_glowing_magmatic",
				"vines",
			},
		},
	},
	{
		name = "Ominous Murals",
		weather = "trianglestorm",
		height = 500,
		node = "carbon",
		inclusions = {},
		decorations = {},
	},
	{
		name = "Kernel",
		weather = "trianglestorm",
		height = 20,
		node = "carbon",
		inclusions = {},
		decorations = {},
	},
}

return layers
