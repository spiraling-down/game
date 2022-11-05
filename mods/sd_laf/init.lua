minetest.register_on_joinplayer(function(player)
	player:hud_set_flags({
		breathbar = false,
		minimap = false,
		minimap_radar = false,
		basic_debug = false,
	})
	-- Hotbar
	player:hud_set_hotbar_itemcount(4)
	player:hud_set_hotbar_image("sd_laf_hotbar.png")
	player:hud_set_hotbar_selected_image("sd_laf_hotbar_selected_slot.png")
	-- TODO sky
end)
