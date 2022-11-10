local basic_mob = {
	_attack_distance = 20,
	_notice_distance = 20,
	_punch_interval = 2,
	_walk_speed = 0,
	_attack_type = "guided", -- options will be: melee, ballistic, straight_shot, guided_missile
	_attack_strength = 1,

	_persistent_properties = {
		time_since_last_attack = 0,
	},

	max_hp = 20,
	physical = true,
	visual = "cube", --Temporary visual
	textures = {}, --Temporary texture
	stepheight = 1.1,
	automatic_face_movement_dir = 0.0,
	automatic_face_movement_max_rotation_per_sec = 90,

	on_activate = function(self, sd, dtime)
		self.object:set_acceleration(vector.new(0, -9.8, 0)) --Set Gravity
	end,

	on_step = function(self, dtime, moveresult)
		self._persistent_properties.time_since_last_attack = self._persistent_properties.time_since_last_attack + dtime
		--Assuming only singleplayer
		for _, player in pairs(minetest.get_connected_players()) do
			--Move towards player if close enough
			local dir = self.object:get_pos():direction(player:get_pos())
			if player:get_pos():distance(self.object:get_pos()) < self._notice_distance then
				local oldvel = self.object:get_velocity()
				self.object:set_velocity(vector.new(dir.x * self._walk_speed, oldvel.y, dir.z * self._walk_speed))
			end
			--Attack if player is close enough
			if player:get_pos():distance(self.object:get_pos()) < self._attack_distance then
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
							self.object:get_pos() + vector.new(0, 1.5, 0),
							"sd_mobs:basic_projectile",
							minetest.serialize({
								offset = player:get_pos() - self.object:get_pos(),
								explode_strength = self._attack_strength,
								type = "ballistic",
							})
						)
					elseif self._attack_type == "guided" then
						minetest.add_entity(
							self.object:get_pos() + vector.new(0, 1.5, 0),
							"sd_mobs:basic_projectile",
							minetest.serialize({
								offset = player:get_pos() - self.object:get_pos(),
								explode_strength = self._attack_strength,
								type = "guided",
								target_player_name = player:get_player_name(), --minetest cannot serialize userdata, so send name instead
							})
						)
					end
					self._persistent_properties.time_since_last_attack = 0
				end
				--Do an attack animation
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
	visual = "sprite", --Temporary visual
	textures = {}, --Temporary texture

	on_activate = function(self, staticdata, dtime)
		self._particlespawner_id = minetest.add_particlespawner({
			amount = 10,
			time = 1,
			collisiondetection = true,
			collision_removal = false,
			object_collision = true,
			attached = self.object,
			texpool = {
				"sd_tools_acid_sprayer_droplet_1.png",
				"sd_tools_acid_sprayer_droplet_2.png",
				"sd_tools_acid_sprayer_droplet_3.png",
				"sd_tools_acid_sprayer_droplet_4.png",
			},
		})
		--start flying in launch direction (plus an upward boost)
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
				minetest.chat_send_all("guided")
			end
		end
	end,

	on_step = function(self, dtime, moveresult)
		if self._type == "guided" then
			self.object:set_velocity((self.object:get_pos():direction(self._target_player:get_pos())) * self._speed)
		end
		if moveresult.collides then
			--Explode, and damage all objects around
			for _, object in pairs(minetest.get_objects_inside_radius(self.object:get_pos(), self._explode_radius)) do
				--if object ~= self.object then
				object:punch(
					self.object,
					nil,
					{
						full_punch_interval = 1.0,
						max_drop_level = 0,
						damage_groups = { fleshy = self._explode_strength },
					}, --temporary damage groups
					vector.normalize(self.object:get_velocity())
				)
				--end
			end
			self.object:remove()
		end
	end,
}

minetest.register_entity("sd_mobs:basic_projectile", basic_projectile)
minetest.register_entity("sd_mobs:basic_mob", basic_mob)

--Only for testing purposes
minetest.register_chatcommand("mob", {
	description = "",
	func = function(name, params)
		minetest.add_entity(minetest.get_player_by_name(name):get_pos(), "sd_mobs:basic_mob")
	end,
})
