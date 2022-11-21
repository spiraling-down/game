local modname = minetest.get_current_modname()

local inv = modlib.mod.require("inv")

local function tex(texname)
	return ("%s_%s.png"):format(modname, texname)
end

local w, h = 240, 224
local btn_w, btn_h = 16, 13

local fs_units = 10
local factor = fs_units / w

local function s(vec2)
	vec2[1] = vec2[1] * factor
	vec2[2] = vec2[2] * factor
	return vec2
end

local function image_button(x, y, name, texname, disabled)
	texname = texname or name
	local btn_tex = tex("button_" .. texname .. (disabled and "_disabled" or ""))
	if disabled then
		return {
			"image",
			s({ x, y }),
			s({ btn_w, btn_h }),
			btn_tex,
		}
	end
	return {
		"image_button" .. (name == "exit" and "_exit" or ""),
		s({ x, y }),
		s({ btn_w, btn_h }),
		btn_tex,
		name,
		"",
		false,
		false,
		btn_tex,
	}
end

local crafts = {
	{
		inputs = { "iron_ore", "carbon" },
		output = "steel",
	},
	{
		inputs = { "sand", "carbon" },
		output = "glass",
	},
	{
		inputs = { "organics", "carbon" },
		output = "acid",
	},
	{
		inputs = { "glass", "steel" },
		output = "lamp",
	},
}

local digit_width = 5
local max_count_width = digit_width * math.floor(math.log10(inv.max_count + 1)) -- digits in the number
local function count_to_texmod(count)
	local count_str = ("%d"):format(count)
	local x, texmod = 0, { ("[combine:%dx9"):format(digit_width * #count_str) }
	for digit in count_str:gmatch(".") do
		-- NOTE: `:` and `^` are escaped because this is used as an argument for [combine
		table.insert(texmod, ([[%d,0=sd_inv_digits.png\^[sheet\:10x1\:%s,0]]):format(x, digit))
		x = x + digit_width
	end
	return x, table.concat(texmod, ":") -- width, texmod
end

local function can_craft_hp(player, hp)
	return (hp or player:get_hp()) < player:get_properties().hp_max
		and inv.has(player, "saturnium")
		and inv.has(player, "steel")
end

local function update_inventory_formspec(player, hp)
	local fs = {
		{ "formspec_version", 3 },
		{ "size", s({ w, h }) },
		{ "background", s({ 0, 0 }), s({ w, h }), tex("bg") },
		image_button(w - btn_w - 5, 6, "exit"),
		image_button(125, 34, "craft_hp", "craft_1", not can_craft_hp(player, hp)),
	}

	for item, pos in pairs({
		saturnium = { 14, 31 },
		iron_ore = { 14, 31 + 32 },
		sand = { 14, 31 + 2 * 32 },
		organics = { 14, 31 + 3 * 32 },
		carbon = { 14, 191 },
		steel = { 206, 63 },
		glass = { 206, 63 + 32 },
		acid = { 206, 63 + 2 * 32 },
		lamp = { 206, 63 + 3 * 32 },
	}) do
		local cnt_w, cnt_tex_mod = count_to_texmod(inv.get_count(player, item))
		table.insert(
			fs,
			-- NOTE: Bias of 0.5 to stop Minetest from fucking up
			{ "image", s({ pos[1] + (max_count_width - cnt_w) / 2, pos[2] + 0.5 }), s({ cnt_w, 9 }), cnt_tex_mod }
		)
	end

	for index, craft in ipairs(crafts) do
		local y = 66 + 32 * (index - 1)
		local function add_btn(x, cnt)
			table.insert(
				fs,
				image_button(
					x,
					y,
					("craft_%d_%s"):format(cnt, craft.output),
					("craft_%d"):format(cnt),
					not inv.has_all(player, craft.inputs, cnt)
				)
			)
		end
		add_btn(115, --[[craft count]] 1)
		add_btn(136, --[[craft count]] 5)
	end

	player:set_inventory_formspec(fslib.build_formspec(fs))
end

minetest.register_on_joinplayer(update_inventory_formspec)

inv.register_on_change(update_inventory_formspec)

minetest.register_on_player_hpchange(function(player, hp_change)
	update_inventory_formspec(player, player:get_hp() + hp_change)
end)

-- TODO crafts should ideally be decoupled from this

local inv_fs_name = modname .. ":inventory"

local function on_inventory_receive_fields(player, fields)
	if fields.craft_hp then -- craft a heart from saturnium
		if can_craft_hp(player) then
			inv.decrement_count(player, "saturnium")
			player:set_hp(player:get_hp() + 1)
		end
	else
		for _, craft in pairs(crafts) do
			local output = craft.output
			local count = (fields["craft_1_" .. output] and 1) or (fields["craft_5_" .. output] and 5)
			if count then
				if not (inv.has_capacity(player, output, count) and inv.has_all(player, craft.inputs, count)) then
					return -- can't craft
				end
				inv.decrement_all(player, craft.inputs, count)
				inv.increment_count(player, output, count)
				break
			end
		end
	end
	local old_fs = player:get_inventory_formspec()
	update_inventory_formspec(player)
	local new_fs = player:get_inventory_formspec()
	if old_fs ~= new_fs then
		-- HACK show the inventory formspec as a normal formspec to update it
		minetest.show_formspec(player:get_player_name(), inv_fs_name, new_fs)
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "" or formname == inv_fs_name then
		on_inventory_receive_fields(player, fields)
		return true
	end
end)
