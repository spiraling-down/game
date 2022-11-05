local modname = minetest.get_current_modname()

local nodes = {
	basalt = {
		regular = 4,
		cracked = 2,
		crumbling = 2,
		granite = {
			regular = 4,
		},
		lava = {
			regular = 4,
		},
	},
	carbon = {
		regular = 4,
	},
	granite = {
		regular = 4,
		cracked = 2,
		crumbling = 2,
		basalt = {
			regular = 4,
		},
		dark = {
			regular = 4,
		},
		frozen = {
			regular = 4,
			cracked = 2,
			crumbling = 2,
			subdued = {
				regular = 4,
			},
		},
	},
	lava = {
		regular = 4,
		basalt = {
			regular = 4,
		},
	},
	limestone = {
		regular = 4,
		cracked = 2,
		crumbling = 2,
	},
	obsidian = {
		regular = 4,
		cracked = 2,
		crumbling = 2,
	},
	sand = {
		regular = 4,
		basalt = {
			regular = 4,
		},
		frozen = {
			regular = 4,
		},
		granite = {
			regular = 4,
		},
		red = {
			regular = 4,
		},
	},
}

local function register_nodes(basename, variants)
	if type(variants) == "table" then
		for variant, subvariants in pairs(variants) do
			register_nodes(basename .. variant .. "_", subvariants)
		end
		return
	end
	for variant = 1, variants do
		minetest.register_node(("%s:%s%d"):format(modname, basename, variant), {
			tiles = { ("%s_%s%d.png"):format(modname, basename, variant) },
		})
	end
end

register_nodes("", nodes)