-- *Invasive* extensions of Minetest's builtin vectors. We are allowed to do this as we are a game.

do
	local ceil = math.ceil
	function vector:ceil()
		return self:apply(ceil)
	end
end

do
	local abs = math.abs
	-- Lookup tables for other components given a least significant component
	local c1 = { x = "y", y = "z", z = "x" }
	local c2 = { x = "z", y = "x", z = "y" }
	-- Constructs an orthonormal base given a normal vector of a 2d plane
	function vector.construct_orthonormal_base(normal)
		normal = normal:normalize() -- safety net
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
