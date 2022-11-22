local modname = minetest.get_current_modname()
local require = modlib.mod.require
local register = require("register")

local droplets = {}

-- TODO drag
-- HACK reduce gravity to account for air friction
local gravity = vector.new(0, -9.81 / 4, 0)
local max_step = 1 / 20

local function globalstep(dtime)
	for droplet in pairs(droplets) do
		-- Apply physics
		local prev_pos, prev_vel = droplet.pos, droplet.vel
		local next_vel = prev_vel + dtime * droplet.acc
		local avg_vel = 0.5 * (prev_vel + next_vel)
		local next_pos = prev_pos + dtime * avg_vel

		-- Raycast; note that liquids (lava) also block droplets
		local remove = false
		for pt in modlib.minetest.raycast(prev_pos, next_pos, true, true) do
			if pt.type == "object" then
				-- The player is immune (also because spawning the droplets in a sufficient distance is error-prone)
				if pt.ref:get_player_name() ~= droplet.player:get_player_name() then
					pt.ref:punch(droplet.player, 1, {
						full_punch_interval = 1,
						damage_groups = { acid = 1 },
					}, prev_vel:normalize())
				end
			else
				remove = true
				break
			end
		end

		-- Remove or update
		droplet.lifetime = droplet.lifetime - dtime
		remove = remove or droplet.lifetime <= 0
		if remove then
			droplets[droplet] = nil
		else
			droplet.pos, droplet.vel = next_pos, next_vel
		end
	end
end

-- Break up globalsteps into smaller steps if needed
minetest.register_globalstep(function(dtime)
	local steps = math.ceil(dtime / max_step)
	for step = 1, steps do
		globalstep((dtime / steps) * (step - 1))
	end
end)

local function random_droplet_texture()
	return ("%s_acid_sprayer_droplet_%d.png^[opacity:%d"):format(modname, math.random(1, 4), math.random(100, 200))
end

local function add_droplet(player, pos, velocity, lifetime)
	-- Virtual representation
	local droplet = {
		pos = pos,
		vel = velocity,
		acc = gravity,
		lifetime = lifetime,
		player = player,
	}
	droplets[droplet] = droplet

	-- Visual representation: Particle effect
	minetest.add_particle({
		pos = pos,
		velocity = velocity,
		acceleration = gravity,
		expirationtime = lifetime,
		size = 1 + 2 * math.random(),
		collisiondetection = true,
		collision_removal = true,
		-- We don't want collisions with the player to kill the particles;
		-- downside: particles will "pass through" enemies
		-- TBD: true (risk of killing particles) or false (passing through)
		object_collision = false,
		texture = random_droplet_texture(),
		-- TODO consider animation
		glow = 3,
		drag = 0, -- TODO
	})
end

local barrel_length = 1
local barrel_radius = 0.1
local max_spread_radius = 0.2 -- relative to one
local min_speed, max_speed = 5, 10
local min_lifetime, max_lifetime = 2, 3
local min_droplets_per_sec, max_droplets_per_sec = 10, 30
local function spray_droplets(player, dtime)
	local eye_pos = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
	local dir = player:get_look_dir()
	local barrel_end_pos = eye_pos:add(dir:multiply(barrel_length))
	local b1, b2 = dir:construct_orthonormal_base()
	local function offset_from_ray(radius)
		local angle = math.random() * 2 * math.pi
		local x, y = math.cos(angle), math.sin(angle) -- in 2d plane space, not in world space
		return radius * (x * b1 + y * b2)
	end
	for _ = 1, math.ceil(dtime * math.random(min_droplets_per_sec, max_droplets_per_sec)) do
		local droplet_pos = barrel_end_pos + offset_from_ray(barrel_radius)
		local droplet_dir = dir + offset_from_ray(math.random() * max_spread_radius)
		local droplet_speed = modlib.math.random(min_speed, max_speed)
		local droplet_vel = droplet_speed * droplet_dir:normalize()
		add_droplet(player, droplet_pos, droplet_vel, modlib.math.random(min_lifetime, max_lifetime))
	end
end

local max_wear = 65535
local use_duration = 2

local function is_recharging(stack)
	return stack:get_meta():get_int(modname .. "_recharging") ~= 0
end

local function set_recharging(stack, bool)
	return stack:get_meta():set_int(modname .. "_recharging", bool and 1 or 0)
end

local function on_secondary_use(itemstack, user)
	if is_recharging(itemstack) then
		return
	end
	if inv.try_decrement_count(user, "acid") then
		set_recharging(itemstack, true)
		return itemstack
	else
		hud.show_error_message(user, "no acid")
	end
end

local handle = {}

local name = register("acid_sprayer", {
	description = "Acid Sprayer",
	range = 0,
	on_secondary_use = on_secondary_use,
	on_place = on_secondary_use,
	-- TODO consider only "enabling" `_on_hold` in `on_use`
	_on_hold = function(itemstack, user, dtime)
		if itemstack:get_wear() == 0 then
			set_recharging(itemstack, false)
		elseif is_recharging(itemstack) then
			return
		end
		local wear_required = math.floor(max_wear * (dtime / use_duration))
		local wear_left = max_wear - itemstack:get_wear()
		local name = user:get_player_name()
		if wear_required < wear_left then
			handle[name] = handle[name]
				or minetest.sound_play(
					"sd_tools_acid_sprayer",
					{ to_player = user:get_player_name(), gain = 0.5 },
					false
				)
			spray_droplets(user, dtime)
			itemstack:add_wear(wear_required)
		elseif handle[name] then
			minetest.sound_fade(handle[name], 10, 0)
			handle[name] = nil
		end
		return itemstack
	end,
	_can_recharge = is_recharging,
	_recharge_time = use_duration * 2,
})

minetest.register_globalstep(function()
	for player in modlib.minetest.connected_players() do
		if player:get_wielded_item():get_name() ~= name or not player:get_player_control().dig then
			local pname = player:get_player_name()
			if handle[pname] then
				minetest.sound_fade(handle[pname], 10, 0)
				handle[pname] = nil
			end
		end
	end
end)

local stack = ItemStack(name)
stack:set_wear(max_wear)
return stack
