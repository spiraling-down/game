local basic_melee_mob = {
	attack_distance = 5,
	notice_distance = 10,
	time_since_last_attack = 0,
	punch_interval = 0.5,

	max_hp = 20,
	physical = true,
	visual = "mesh",
	textures = { "basic_melee_mob.b3d" }, --Temporary model file

	on_activate = function(self, sd, dtime)
		self.object:set_acceleration(vector.new(0, -9.8, 0)) --Set Gravity
	end,
	on_deactivate = function(self, removal) end,
	on_step = function(self, dtime, moveresult)
		self.time_since_last_attack = self.time_since_last_attack + dtime
		--Assuming only singleplayer
		for _, player in pairs(minetest.get_connected_players()) do
			--Move towards player if close enough
			local dir = vector.direction(self.object:get_pos(), player:get_pos())
			if vector.distance(player:get_pos(), self.object:get_pos()) < self.notice_distance then
				local oldvel = self.object:get_velocity()
				self.object:set_velocity(vector.new(dir.x, oldvel.y, dir.z))
			end
			--Attack if player is close enough
			if vector.distance(player:get_pos(), self.object:get_pos()) < self.attack_distance then
				if self.time_since_last_attack > self.punch_interval then
					player:punch(
						self.object,
						self.time_since_last_attack,
						{ full_punch_interval = 1.0, max_drop_level = 0, damage_groups = { fleshy = 10 } }, --temporary damage groups
						dir
					)
					self.time_since_last_attack = 0
				end
				--Do an attack animation
			end
		end
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, images) end,
	on_death = function(self, killer) end,
}

--Basic ballistic projectile which explodes on impact
basic_ballistic_projectile = {
	explode_radius = 3,

	max_hp = 20,
	physical = true,
	visual = "mesh",
	textures = { "basic_projectil.b3d" },

	on_activate = function(self, staticdata, dtime)
		self.object:set_acceleration(vector.new(0, -9.8, 0))
		--start flying in launch direction (plus an upward boost)
		if minetest.deserialize(staticdata) ~= nil then
			self.object:set_velocity((minetest.deserialize(staticdata).dir + vector.new(0, 1, 0)) * 10)
		end
	end,

	on_step = function(self, dtime, moveresult)
		if moveresult.collides then
			--Explode, and damage all objects around
			for _, object in pairs(minetest.get_objects_inside_radius(self.object:get_pos(), self.explode_radius)) do
				if object ~= self.object then
					object:punch(
						self.object,
						nil,
						{ full_punch_interval = 1.0, max_drop_level = 0, damage_groups = { fleshy = 10 } }, --temporary damage groups
						vector.normalize(self.object:get_velocity())
					)
				end
			end
			self.object:remove()
		end
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, images) end,
	on_death = function(self, killer) end,
	on_rightclick = function(self, clicker) end,
}
