local modname = minetest.get_current_modname()
local manipulator = {
	itemname = modname .. ":manipulator",
	uses = 50,
	recharge_time = 60,
}
local scaffolding_nodename = modname .. ":scaffolding"
local frame_width = 1 / 8

local nodeboxes = {}
do
	-- Build nodeboxes for scaffolding
	local function push(box)
		table.insert(nodeboxes, box)
	end
	local nmn, nmx = -0.5, 0.5
	local cmn, cmx = nmn + frame_width, nmx - frame_width
	do
		local mdn, mdx = (nmn + cmn) / 2, (nmx + cmx) / 2
		push({ mdn, mdn, mdn, mdx, mdx, mdx })
	end
	local function push_xz_frame(ymn, ymx)
		-- X
		push({ nmn, ymn, nmn, nmx, ymx, cmn })
		push({ nmn, ymn, cmx, nmx, ymx, nmx })
		-- Z
		push({ nmn, ymn, cmn, cmn, ymx, cmx })
		push({ cmx, ymn, cmn, nmx, ymx, cmx })
	end
	push_xz_frame(cmx, nmx) -- top
	push_xz_frame(nmn, cmn) -- bottom
	-- 4 vertical frame boxes to connect top & bottom
	local function push_vert_frame(xmn, xmx, zmx, zmn)
		push({ xmn, cmn, zmn, xmx, cmx, zmx })
	end
	push_vert_frame(nmn, cmn, nmn, cmn)
	push_vert_frame(nmx, cmx, nmn, cmn)
	push_vert_frame(nmn, cmn, nmx, cmx)
	push_vert_frame(nmx, cmx, nmx, cmx)
end

minetest.register_node(scaffolding_nodename, {
	description = "Scaffolding",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = nodeboxes,
	},
	tiles = { { name = modname .. "_manipulator_scaffolding.png", backface_culling = false } },
	use_texture_alpha = "clip",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
})

local max_wear = 65535
local wear_per_use = math.floor(max_wear / manipulator.uses)
minetest.register_tool(manipulator.itemname, {
	description = "Manipulator",
	on_place = function(itemstack, placer, pointed_thing)
		if itemstack:get_wear() + wear_per_use > max_wear then
			return
		end
		itemstack:add_wear(wear_per_use)
		minetest.item_place(ItemStack(scaffolding_nodename), placer, pointed_thing)
		return itemstack
	end,
})

-- Recharge if the player is holding the manipulator
local recharge_catchup = {} -- catchup for fractional wear which adds up
minetest.register_globalstep(function(dtime)
	for player in modlib.minetest.connected_players() do
		local name = player:get_player_name()
		local wielded_item = player:get_wielded_item()
		if wielded_item:get_name() == manipulator.itemname then
			local recharge = dtime / manipulator.recharge_time * max_wear + (recharge_catchup[name] or 0)
			wielded_item:add_wear(-recharge)
			assert(player:set_wielded_item(wielded_item))
			recharge_catchup[name] = recharge % 1
		else
			recharge_catchup[name] = nil
		end
	end
end)
