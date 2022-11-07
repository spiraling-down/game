local modname = minetest.get_current_modname()
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
	tiles = { modname .. "_manipulator_scaffolding.png" },
	use_texture_alpha = "clip",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
})
