local require = modlib.mod.require
local nodedata = require("nodes")
local layers = require("layers")
local deco_groups = require("gen_deco_groups")
local mapgen_data = {
	nodes = nodedata.nodes,
	ore_cids = nodedata.ore_cids,
	layers = layers,
	deco_groups = deco_groups,
}
-- This is the cleanest and simplest solution and works on 5.10+
-- A slightly hackier solution could also work on 5.9
minetest.ipc_set("mapgen_data", mapgen_data)
minetest.register_mapgen_script(modlib.mod.get_resource("gen.lua"))
require("spawn")
require("ambience")
