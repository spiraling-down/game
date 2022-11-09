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

-- Constructs an orthonormal base given a normal vector of a 2d plane
local construct_orthonormal_base
do
	-- Lookup tables for other components given a least significant component
	local abs = math.abs
	local c1 = { x = "y", y = "z", z = "x" }
	local c2 = { x = "z", y = "x", z = "y" }
	function construct_orthonormal_base(normal)
		local lsc = "x" -- least significant component
		for c, val in next, normal, lsc do
			if abs(val) < abs(normal[lsc]) then
				lsc = c
			end
		end
		local msc1, msc2 = c1[lsc], c2[lsc]
		local b1 = normal:copy()
		b1[lsc] = 0 -- zero the least significant component
		-- Swap most significant components & flip one.
		-- Assuming z is the lsc: n * b1 = nx * ny + ny * -nx = 0
		b1[msc1], b1[msc2] = b1[msc2], -b1[msc1]
		b1:normalize()
		-- Now we may find a second orthogonal vector using the cross product.
		local b2 = b1:cross(normal)
		return b1, b2
	end
end

local barrel_length = 1
local barrel_radius = 0.1
local spread_radius = 0.2 -- relative to one
local min_speed, max_speed = 5, 10
local min_lifetime, max_lifetime = 2, 3
local min_droplets_per_sec, max_droplets_per_sec = 10, 30
local function spray_droplets(player, dtime)
	local eye_pos = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
	local dir = player:get_look_dir()
	local barrel_end_pos = eye_pos:add(dir:multiply(barrel_length))
	local b1, b2 = construct_orthonormal_base(dir)
	local function offset_from_ray(radius)
		local angle = math.random() * 2 * math.pi
		local x, y = math.cos(angle), math.sin(angle) -- in 2d plane space, not in world space
		return radius * (x * b1 + y * b2)
	end
	for _ = 1, math.ceil(dtime * math.random(min_droplets_per_sec, max_droplets_per_sec)) do
		local droplet_pos = barrel_end_pos + offset_from_ray(barrel_radius)
		local droplet_dir = dir + offset_from_ray(spread_radius)
		local droplet_speed = modlib.math.random(min_speed, max_speed)
		local droplet_vel = droplet_speed * droplet_dir:normalize()
		add_droplet(player, droplet_pos, droplet_vel, modlib.math.random(min_lifetime, max_lifetime))
	end
end

return register("acid_sprayer", {
	description = "Acid Sprayer",
	-- TODO consider only "enabling" `_on_hold` in `on_use`
	_on_hold = function(_, user, dtime)
		spray_droplets(user, dtime)
	end,
	_recharge_time = 20,
})
