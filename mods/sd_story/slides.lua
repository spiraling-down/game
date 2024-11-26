local modname = minetest.get_current_modname()

local function tex(texname)
	return ("%s_%s.png"):format(modname, texname)
end

local w, h = 288, 288

local fs_units = 10
local factor = fs_units / w

local function s(vec2)
	vec2[1] = vec2[1] * factor
	vec2[2] = vec2[2] * factor
	return vec2
end

local function letter(char)
	if char == " " then
		return "blank.png"
	end
	local index = ({
		["."] = 31,
		[","] = 32,
		["'"] = 33,
		["-"] = 34,
	})[char] or char:upper():byte() - ("A"):byte()
	return tex("alphabet") .. ("^[sheet:35x1:%d,0"):format(index)
end

local slide_lines = {
	{
		"Several years ago radio",
		"observatories around the world",
		"started picking up increasingly",
		"strong non-natural signal from",
		"Enceladus, one of Saturn's Moons.",
	},
	{
		"Although many astronauts were sent",
		"there to figure out the source of",
		"the signal, in the process",
		"discovering advanced, earth-like",
		"forms of life...",
	},
	{
		"... the contact with each and",
		"every one of them was rapidly lost",
		"as they started descending towards",
		"that Moon's core from where the",
		"signal was coming.",
	},
	{
		"You're Vasiliy Orlov, drilling",
		"engineer convicted for excess",
		"self-defence. Not wanting to send",
		"more fine men to death, government",
		"gave you an out by sending you to",
		"Enceladus in a mining mech.",
	},
	{
		"After a long flight, you finally",
		"arrived on Enceladus' surface.",
		"Command Center starts broad-",
		"casting its briefing as you're",
		"heading towards a cave entrance.",
	},
}

-- Check that everything fits on screen.
for _, lines in ipairs(slide_lines) do
	assert(#lines <= 6)
	for _, line in ipairs(lines) do
		assert(#line <= math.floor((w - 11) / 8), line)
	end
end

local function show_slide(player, i, on_complete)
	if i > 5 then
		on_complete()
		return
	end
	local fs = {
		{ "formspec_version", 3 },
		{ "size", s({ w, h }) },
		{ "background", s({ 0, 0 }), s({ w, h }), tex("bg") },
		{ "image", s({ 11, 33 }), s({ 266, 140 }), tex(("slide_%d"):format(i)) },
	}

	local chars = 0
	for row, line in ipairs(slide_lines[i]) do
		chars = chars + #line -- HACK: This also counts spaces.
		for col, char in line:gmatch("()(.)") do
			table.insert(
				fs,
				{ "image", s({ 11 + (col - 1) * 8, 33 + 140 + 10 + 13 * (row - 1) }), s({ 8, 12 }), letter(char) }
			)
		end
	end

	local slide_duration = 10 + 0.1 * chars -- 0.5 sec per char
	local show_next_job = minetest.after(slide_duration, show_slide, player, i + 1, on_complete)
	local callback = function(fields)
		if fields.quit then -- skip to next slide
			show_next_job:cancel()
			show_slide(player, i + 1, on_complete)
		end
	end
	fslib.show_formspec(player, fs, callback)
	minetest.after(0.1, fslib.show_formspec, player, fs, callback) -- HACK stupid Minetest bugses
end

return function(player, on_complete)
	return show_slide(player, 1, on_complete)
end
