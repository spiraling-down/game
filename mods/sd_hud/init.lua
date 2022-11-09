-- NOTE: Manual health bar control as might be needed later on,
-- see https://github.com/MT-CTF/capturetheflag/commit/2be697e3f69afbf80784ddb74b8c48ddb48f999b

local w, h = 24, 24
minetest.hud_replace_builtin("health", {
	hud_elem_type = "statbar",
	position = { x = 0.5, y = 1 },
	text = "heart.png",
	text2 = "heart_gone.png",
	number = minetest.PLAYER_MAX_HP_DEFAULT,
	item = minetest.PLAYER_MAX_HP_DEFAULT,
	direction = 0,
	size = { x = w, y = h },
	offset = { x = -5 * w, y = -48 - h - 16 },
})
