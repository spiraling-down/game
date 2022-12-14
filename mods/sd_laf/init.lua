laf = {
	colors = {
		text = modlib.minetest.colorspec.from_string("#DFE6D4"),
	},
	fontsize = 1.25,
}

-- Build the formspec prepend

local formspec_prepend
do
	local sliced_bg = "sd_laf_bg.png"
	local slice_size = 6 -- all 9 slices, including the middle slice, have this size

	-- HACK: Manually apply 9-slice scaling to built-in buttons with a known fixed 6:1 ratio
	-- as the bgimg_middle property doesn't work for builtin formspecs forcing a version of 1
	local btn_names = "btn_continue,btn_change_password,btn_sound,btn_key_config,btn_exit_menu,btn_exit_os,btn_respawn"

	local function vertical_slice(x_offset)
		return ("[combine:%dx%d:%d,0=%s"):format(slice_size, 3 * slice_size, x_offset * slice_size, sliced_bg)
	end

	local left, middle, right = vertical_slice(0), vertical_slice(-1), vertical_slice(-2)
	middle = middle .. ("^[resize:%dx%d"):format((6 * 3 - 2) * slice_size, 3 * slice_size)

	local function esc_arg(texture_modifier)
		return texture_modifier:gsub(".", { ["\\"] = "\\\\", ["^"] = "\\^", [":"] = "\\:" })
	end

	local btn_bg_scaled = ("[combine:%dx%d:0,0=%s:%d,0=%s:%d,0=%s"):format(
		6 * 3 * slice_size,
		3 * slice_size,
		esc_arg(left),
		slice_size,
		esc_arg(middle),
		(6 * 3 - 2) * slice_size,
		esc_arg(right)
	)

	formspec_prepend = ("background9[[0,0;8,4;%s;true;%d]"):format(sliced_bg, slice_size)
		.. ("style_type[*;font=mono;fontsize=*%f;textcolor=%s]"):format(laf.fontsize, laf.colors.text:to_string())
		.. ("style_type[button;border=false;bgimg=%s;bgimg_middle=%d]"):format(sliced_bg, slice_size)
		.. ("style[%s;border=false;bgimg=%s]"):format(btn_names, minetest.formspec_escape(btn_bg_scaled))
end

minetest.register_on_joinplayer(function(player)
	player:set_formspec_prepend(formspec_prepend)

	player:hud_set_flags({
		healthbar = false, -- reimplemented in sd_hud
		breathbar = false,
		minimap = false,
		minimap_radar = false,
		basic_debug = false,
	})
	player:hud_set_hotbar_itemcount(4)
	player:hud_set_hotbar_image("sd_laf_hotbar.png")
	player:hud_set_hotbar_selected_image("sd_laf_hotbar_selected_slot.png")
	local base_color = "#000821"
	player:set_sky({
		type = "plain",
		base_color = base_color,
		clouds = false,
	})
	player:set_stars({
		count = 250,
		day_opacity = 1,
		star_color = "#FFFFFF33",
		scale = 2,
	})
	player:set_sun({
		-- Set to false because the sunrise horizon texture seems buggy with the type="plain" sky
		sunrise_visible = false,
		texture = "sd_laf_sun.png",
	})
	player:set_moon({
		texture = "sd_laf_saturn.png",
	})
end)
