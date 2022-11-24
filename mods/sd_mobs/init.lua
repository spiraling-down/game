local max_count_by_chunk = modlib.mod.require("max_count_by_chunk")

local basic_mob = {
	_attack_distance = 10,
	_notice_distance = 20,
	_punch_interval = 4,
	_walk_speed = 3,
	_attack_type = "straight",
	_attack_strength = 1,
	_movement_type = "bat",

	_persistent_properties = {
		time_since_last_attack = 0,
		age = 0,
		attacking = true,
	},

	max_hp = 5,
	physical = true,
	collisionbox = { 0.5, 0.5, 0.5, -0.5, -0.5, -0.5 },
	visual_size = vector.new(1.5, 1.5, 1.5),
	visual = "sprite", --Temporary visual
	textures = { "sd_mobs_bat.png" }, --Temporary texture
	stepheight = 1.1,
	automatic_face_movement_dir = 0.0,
	automatic_face_movement_max_rotation_per_sec = 90,

	on_activate = function(self, staticdata)
		-- Population control
		max_count_by_chunk.increment(self.object:get_pos())
		self._prev_pos = self.object:get_pos()
		-- Initialization
		self.object:set_armor_groups({ acid = 100 })
		local data = minetest.deserialize(staticdata)
		if data ~= nil then
			if data.mob_type == "mantis" then
				self._attack_type = "melee"
				self._movement_type = "walk"
				self._notice_distance = 10
				self._attack_distance = 4
				self.object:set_acceleration(vector.new(0, -9.8, 0)) --Set Gravity
				local prop = self.object:get_properties()
				prop.collisionbox = { 1, 1, 1, -1, -1, -1 }
				prop.visual_size = vector.new(2, 2, 2)
				self.object:set_properties(prop)
			end
			-- HACK bat uses defaults
		end
	end,

	on_deactivate = function(self)
		max_count_by_chunk.decrement(self.object:get_pos())
	end,

	on_step = function(self, dtime)
		local pos = self.object:get_pos()
		-- Population control
		max_count_by_chunk.move(self._prev_pos, pos)
		self._prev_pos = pos
		-- Actual mob logic
		self._persistent_properties.time_since_last_attack = self._persistent_properties.time_since_last_attack
			+ dtime / 100
		self._persistent_properties.age = self._persistent_properties.age + dtime / 100
		--Assuming only singleplayer
		for _, player in pairs(minetest.get_connected_players()) do
			--Move towards player if close enough
			local dir = pos:direction(player:get_pos())
			if player:get_pos():distance(pos) < self._notice_distance then
				local oldvel = self.object:get_velocity()
				self.object:set_velocity(vector.new(dir.x * self._walk_speed, oldvel.y, dir.z * self._walk_speed))
			end
			if self._movement_type == "bat" then
				self.object:add_velocity(vector.new(0, (pos:direction(player:get_pos() + vector.new(0, 2, 0))).y, 0))
			elseif self._movement_type == "walk" then
				local prop = self.object:get_properties()
				if dir:dot(self.object:get_velocity()) > 0.7 then
					if self._persistent_properties.attacking then
						if math.fmod(self._persistent_properties.age, 1) > 0.2 then
							prop.textures = { "sd_mobs_mantis_front.png" }
						else
							prop.textures = { "sd_mobs_mantis_attack.png" }
						end
					else
						prop.textures = { "sd_mobs_mantis_front.png" }
					end
				else
					if dir:dot(self.object:get_velocity():cross(vector.new(0, 1, 0))) > 0 then
						prop.textures = { "sd_mobs_mantis_left.png" }
					else
						prop.textures = { "sd_mobs_mantis_right.png" }
					end
				end
				self.object:set_properties(prop)
			end
			--Attack if player is close enough
			if player:get_pos():distance(self.object:get_pos()) < self._attack_distance then
				self._persistent_properties.attacking = true
				if self._persistent_properties.time_since_last_attack > self._punch_interval then
					if self._attack_type == "melee" then
						player:punch(
							self.object,
							self._persistent_properties.time_since_last_attack,
							{
								full_punch_interval = 1.0,
								max_drop_level = 0,
								damage_groups = { fleshy = self._attack_strength },
							}, --temporary damage groups
							dir
						)
					elseif self._attack_type == "ballistic" then
						minetest.add_entity(
							pos,
							"sd_mobs:basic_projectile",
							minetest.serialize({
								offset = player:get_pos() - pos,
								explode_strength = self._attack_strength,
								type = "ballistic",
							})
						)
					elseif self._attack_type == "guided" then
						minetest.add_entity(
							pos,
							"sd_mobs:basic_projectile",
							minetest.serialize({
								offset = player:get_pos() - pos,
								explode_strength = self._attack_strength,
								type = "guided",
								target_player_name = player:get_player_name(), --minetest cannot serialize userdata, so send name instead
							})
						)
					elseif self._attack_type == "straight" then
						minetest.add_entity(
							pos,
							"sd_mobs:basic_projectile",
							minetest.serialize({
								offset = player:get_pos() - pos,
								explode_strength = self._attack_strength,
								type = "straight",
								target_player_name = player:get_player_name(), --minetest cannot serialize userdata, so send name instead
							})
						)
					end
					self._persistent_properties.time_since_last_attack = 0
				end
			end
		end
	end,
}

--Math makes a perfect ballistic shot when you are standing below the mob, otherwise it makes a horrible shot
local find_vel_needed = function(offset)
	local yoffset = offset.y
	local horizontal_offset = (offset - vector.new(0, offset.y, 0))
	local horizontal_dist = (offset - vector.new(0, offset.y, 0)):length()
	if yoffset < 0 then
		return horizontal_offset / (math.sqrt(2 * yoffset * -9.8)) * 9.8
	else
		local vy = horizontal_dist + yoffset
		yoffset = yoffset + 3
		local t = (vy + math.sqrt(vy * vy + 4 * yoffset * 9.8 / 2)) / (2 * yoffset)
		return vector.new(0, vy, 0) + (horizontal_offset / t) * 3
	end
end

--Basic projectile which explodes on impact
local basic_projectile = {
	_explode_radius = 3,
	_explode_strength = 1,
	_type = "",
	_target_player = nil,
	_speed = 10,
	_particlespawner_id = nil,

	max_hp = 20,
	physical = true,
	visual_size = vector.new(0.8, 0.8, 0.8),
	visual = "sprite", --Temporary visual
	textures = { "sd_tools_acid_sprayer_droplet_1.png" }, --Temporary texture

	on_activate = function(self, staticdata)
		self._particlespawner_id = minetest.add_particlespawner({
			amount = 10,
			time = 1,
			collisiondetection = true,
			collision_removal = false,
			object_collision = true,
			attached = self.object,
			scale = vector.new(2, 2, 2),
			texpool = {
				"sd_tools_acid_sprayer_droplet_1.png",
				"sd_tools_acid_sprayer_droplet_2.png",
				"sd_tools_acid_sprayer_droplet_3.png",
				"sd_tools_acid_sprayer_droplet_4.png",
			},
		})
		if minetest.deserialize(staticdata) ~= nil then
			local data = minetest.deserialize(staticdata)
			self._explode_strength = data.explode_strength
			self._type = data.type
			if self._type == "ballistic" then
				self.object:set_acceleration(vector.new(0, -9.8, 0))
				self.object:set_velocity(find_vel_needed(data.offset - vector.new(0, 1.5, 0)))
			elseif self._type == "guided" then
				self._target_player = minetest.get_player_by_name(data.target_player_name)
				self.object:set_velocity((self.object:get_pos():direction(self._target_player:get_pos())) * self._speed)
			elseif self._type == "straight" then
				self._target_player = minetest.get_player_by_name(data.target_player_name)
				self.object:set_velocity((self.object:get_pos():direction(self._target_player:get_pos())) * self._speed)
			end
		end
	end,

	on_step = function(self, _, moveresult)
		local pos = self.object:get_pos()
		if self._type == "guided" then
			self.object:set_velocity((pos:direction(self._target_player:get_pos())) * self._speed)
		end
		if moveresult.collides then
			--Explode, and damage all objects around
			for _, object in pairs(minetest.get_objects_inside_radius(pos, self._explode_radius)) do
				if minetest.is_player(object) then
					object:punch(
						self.object,
						1,
						{
							full_punch_interval = 1.0,
							max_drop_level = 0,
							damage_groups = { fleshy = self._explode_strength },
						}, --temporary damage groups
						vector.normalize(self.object:get_velocity())
					)
					self.object:remove()
				end
			end
		end
	end,
}

minetest.register_entity("sd_mobs:basic_projectile", basic_projectile)
minetest.register_entity("sd_mobs:basic_mob", basic_mob)

--Only for testing purposes
minetest.register_chatcommand("mob", {
	description = "",
	func = function(name)
		minetest.add_entity(
			minetest.get_player_by_name(name):get_pos(),
			"sd_mobs:basic_mob",
			minetest.serialize({ mob_type = "bat" })
		)
	end,
})

minetest.register_chatcommand("mob2", {
	description = "",
	func = function(name)
		minetest.add_entity(
			minetest.get_player_by_name(name):get_pos(),
			"sd_mobs:basic_mob",
			minetest.serialize({ mob_type = "mantis" })
		)
	end,
})

minetest.register_lbm({
	label = "spawn mobs",
	name = "sd_mobs:spawn_mobs",
	-- TODO use groups instead
	nodenames = {
		"sd_map:granite_frozen_1",
		"sd_map:granite_frozen_2",
		"sd_map:granite_frozen_3",
		"sd_map:granite_frozen_4",
		"sd_map:granite_semifrozen_1",
		"sd_map:granite_semifrozen_2",
		"sd_map:granite_semifrozen_3",
		"sd_map:granite_semifrozen_4",
		"sd_map:granite_1",
		"sd_map:granite_2",
		"sd_map:granite_3",
		"sd_map:granite_4",
		"sd_map:basalt_1",
		"sd_map:basalt_2",
		"sd_map:basalt_3",
		"sd_map:basalt_4",
		"sd_map:carbon_1",
		"sd_map:carbon_2",
		"sd_map:carbon_3",
		"sd_map:carbon_4",
	},
	run_at_every_load = true,
	action = function(pos)
		if pos.y >= -100 or math.random() > 2e-3 then
			return
		end
		local pos_above = pos:offset(0, 1, 0)
		if minetest.get_node(pos_above).name == "air" and max_count_by_chunk.can_increment(pos_above) then
			minetest.add_entity(
				pos_above,
				"sd_mobs:basic_mob",
				minetest.serialize({ mob_type = math.random() < 0.5 and "bat" or "mantis" })
			)
		end
	end,
})
