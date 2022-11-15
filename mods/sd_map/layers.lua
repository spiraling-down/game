-- NOTE: `transition = n` is supported but currently unused
-- TODO: Use `weather`, `inclusions` and `decorations`
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
				"glowing_mushrooms_frozen",
				"debris_frozen",
				"pile_snow",
				"icicle_floor",
			},
			ceiling = {
				"vines_glowing_frozen",
				"icicle_ceiling",
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
				"glowing_mushrooms_frozen",
				"debris_frozen",
				"pile_snow",
				"icicle_floor",
			},
			ceiling = {
				"vines_glowing_frozen",
				"icicle_ceiling",
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
				"stalagmite_granite",
				"grass_dry",
				"debris_dry",
			},
			ceiling = {
				"stalactite_granite",
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
				"blue_flowers",
				"red_flowers",
				"stalagmite_granite",
				"grass",
				"glowing_mushrooms_green",
			},
			ceiling = {
				"stalactite_granite",
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
				"blue_flowers",
				"red_flowers",
				"stalagmite_basalt",
				"grass",
				"glowing_mushrooms_green",
			},
			ceiling = {
				"stalactite_basalt",
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
				"blue_flowers",
				"red_flowers",
				"stalagmite_basalt",
				"grass",
				"glowing_mushrooms_green",
				"grass_magmatic",
			},
			ceiling = {
				"stalactite_basalt",
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
