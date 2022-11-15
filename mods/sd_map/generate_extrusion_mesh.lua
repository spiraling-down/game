-- TODO refactor
return function(texname, meshname)
	local texfile = assert(io.open(assert(modlib.minetest.media.paths[texname], texname), "r"))
	local png = modlib.minetest.decode_png(texfile)
	texfile:close()
	modlib.minetest.convert_png_to_argb8(png)
	assert(png.width == png.height)
	local res = png.width

	local function is_transparent(x, y)
		-- x, y = y, res - x - 1 -- res - x - 1
		if x < 0 or x > res - 1 or y < 0 or y > res - 1 then
			return true -- out of bounds pixels are considered transparent
		end
		local argb8 = png.data[y * res + x + 1]
		local alpha = math.floor(argb8 / 0x1000000)
		return alpha == 0
	end

	local f = assert(io.open(modlib.mod.get_resource(minetest.get_current_modname(), "models", meshname), "w"))

	-- Write vertices

	local function vidx(x, y, z)
		return y * (res + 1) ^ 2 + x * (res + 1) + z + 1
	end

	for y = 0, 1 do
		for x = 0, res do
			for z = 0, res do
				-- NOTE: x is flipped due to handedness
				f:write(("v %f %f %f\n"):format(-(x / res - 0.5), y * (1 / res) - 0.5, z / res - 0.5))
			end
		end
	end

	-- Write texcoords

	local function vtidx(x, z)
		return x * (res + 1) + z + 1
	end

	for x = 0, res do
		for z = 0, res do
			-- NOTE: y (z) is flipped due to handedness
			f:write(("vt %f %f\n"):format(x / res, -z / res))
		end
	end

	-- TODO optimize vertex & texcoord writing by dropping unused vertices / texcoords

	-- Write normals
	-- TODO get rid of this by getting winding order right
	f:write([[
	vn -1 0 0
	vn 1 0 0
	vn 0 -1 0
	vn 0 1 0
	vn 0 0 -1
	vn 0 0 1
	]])

	-- Write faces

	-- Bottom & top ("sandwich")

	local function add_quad(v, uv, n)
		uv = uv or v
		-- TODO (?) write 2 tris rather than 1 quad for normalization purposes
		f:write(
			("f %d/%d/%d %d/%d/%d %d/%d/%d %d/%d/%d\n"):format(
				v[3],
				uv[3],
				n,
				v[4],
				uv[4],
				n,
				v[2],
				uv[2],
				n,
				v[1],
				uv[1],
				n
			)
		)
	end

	for y = 0, 1 do
		add_quad(
			{ vidx(0, y, 0), vidx(0, y, 16), vidx(16, y, 0), vidx(16, y, 16) },
			{ vtidx(0, 0), vtidx(0, 16), vtidx(16, 0), vtidx(16, 16) },
			y + 1
		)
	end

	for x = 0, res - 1 do
		for z = 0, res - 1 do
			if not is_transparent(x, z) then
				local uv = { vtidx(x, z), vtidx(x, z + 1), vtidx(x + 1, z), vtidx(x + 1, z + 1) }
				if is_transparent(x, z + 1) then
					add_quad(
						{ vidx(x, 0, z + 1), vidx(x + 1, 0, z + 1), vidx(x, 1, z + 1), vidx(x + 1, 1, z + 1) },
						uv,
						6
					)
				end
				if is_transparent(x, z - 1) then
					add_quad({ vidx(x, 0, z), vidx(x, 1, z), vidx(x + 1, 0, z), vidx(x + 1, 1, z) }, uv, 5)
				end
				if is_transparent(x + 1, z) then
					add_quad(
						{ vidx(x + 1, 0, z), vidx(x + 1, 1, z), vidx(x + 1, 0, z + 1), vidx(x + 1, 1, z + 1) },
						uv,
						4
					)
				end
				if is_transparent(x - 1, z) then
					add_quad({ vidx(x, 0, z), vidx(x, 1, z), vidx(x, 0, z + 1), vidx(x, 1, z + 1) }, uv, 3)
				end
			end
		end
	end
	f:close()

	for y = 0, res - 1 do
		for x = 0, res - 1 do
			io.write(is_transparent(x, y) and "X" or " ")
		end
		io.write("\n")
	end

	return res
end
