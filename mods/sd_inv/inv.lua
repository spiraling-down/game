inv = {}

inv.max_count = 9999
inv.registered_on_changes = {}

function inv.register_on_change(callback)
	table.insert(inv.registered_on_changes, callback)
end

local item_count_prefix = "sd_inv_item_count_"

function inv.clear(player)
	local meta = player:get_meta()
	for k in pairs(meta:to_table().fields) do
		if modlib.text.starts_with(k, "sd_inv_item_count_") then
			meta:set_int(k, 0)
		end
	end
	modlib.table.icall(inv.registered_on_changes, player)
end

minetest.register_on_dieplayer(inv.clear)

function inv.get_count(player, itemname)
	return player:get_meta():get_int(item_count_prefix .. itemname)
end

function inv.has(player, itemname, min_count)
	return inv.get_count(player, itemname) >= (min_count or 1)
end

function inv.has_all(player, itemnames, min_count)
	for _, itemname in ipairs(itemnames) do
		if not inv.has(player, itemname, min_count) then
			return false
		end
	end
	return true
end

function inv.has_capacity(player, itemname, increment)
	return inv.get_count(player, itemname) + (increment or 1) <= inv.max_count
end

function inv.set_count(player, itemname, count)
	assert(count >= 0 and count <= inv.max_count)
	player:get_meta():set_int(item_count_prefix .. itemname, count)
	modlib.table.icall(inv.registered_on_changes, player)
end

function inv.try_increment_count(player, itemname, increment)
	increment = increment or 1
	local count = inv.get_count(player, itemname)
	if count + increment > inv.max_count then
		return false
	end
	inv.set_count(player, itemname, inv.get_count(player, itemname) + increment)
	return true
end

function inv.increment_count(player, itemname, increment)
	return assert(inv.try_increment_count(player, itemname, increment))
end

function inv.try_decrement_count(player, itemname, decrement)
	decrement = decrement or 1
	local count = inv.get_count(player, itemname)
	if count < decrement then
		return false
	end
	inv.set_count(player, itemname, count - decrement)
	return true
end

function inv.decrement_count(player, itemname, decrement)
	assert(inv.try_decrement_count(player, itemname, decrement))
end

function inv.decrement_all(player, itemnames, decrement)
	for _, itemname in ipairs(itemnames) do
		inv.decrement_count(player, itemname, decrement)
	end
end

return inv
