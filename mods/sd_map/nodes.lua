modlib.mod.require("crumbling")

local modname = minetest.get_current_modname()

local nodes = {
	basalt = {
		_ = 4,
		cracked = 2,
		crumbling = 2,
		granite = 4,
		lava = 4,
	},
	carbon = 4,
	granite = {
		_ = 4,
		cracked = 2,
		crumbling = 2,
		basalt = 4,
		dark = 4,
		semifrozen = {
			_ = 4,
			cracked = 2,
			crumbling = 2,
		},
		frozen = {
			_ = 4,
			cracked = 2,
			crumbling = 2,
			subdued = 4,
		},
	},
	lava = {
		_ = 4,
		basalt = 4,
	},
	limestone = {
		_ = 4,
		cracked = 2,
		crumbling = 2,
	},
	obsidian = {
		_ = 4,
		cracked = 2,
		crumbling = 2,
	},
	sand = {
		_ = 4,
		basalt = 4,
		frozen = 4,
		granite = 4,
		red = 4,
	},
}

-- Recursively register the tree of nodes; each node gets all its attributes as groups
local groups = {}
local function register_nodes(basename, variants)
	if type(variants) == "table" then
		for variant, subvariants in pairs(variants) do
			groups[variant] = 1
			local name = basename
			if variant ~= "_" then
				name = name .. variant .. "_"
			end
			register_nodes(name, subvariants)
			groups[variant] = nil
		end
		return
	end
	for variant = 1, variants do
		minetest.register_node(("%s:%s%d"):format(modname, basename, variant), {
			tiles = { ("%s_%s%d.png"):format(modname, basename, variant) },
			groups = table.copy(groups),
		})
	end
end

register_nodes("", nodes)

return nodes
