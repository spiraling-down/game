-- Keep track of mob counts per chunk to avoid overpopulation
local count_by_chunk = {}

local chunksize = 40 -- NOTE: Chunks are not Minetest chunks
count_by_chunk.chunksize = chunksize

local max_density = 1e-4 -- mobs per node
local max_per_chunk = math.ceil(max_density * count_by_chunk.chunksize ^ 3)

local counts = {}

local function pos_to_chunk_hash(pos)
	return minetest.hash_node_position(pos:divide(chunksize):floor())
end

function count_by_chunk.get(pos)
	return counts[pos_to_chunk_hash(pos)] or 0
end

function count_by_chunk.change(pos, delta)
	local hash = pos_to_chunk_hash(pos)
	counts[hash] = (counts[hash] or 0) + delta
	assert(counts[hash] >= 0)
	if counts[hash] == 0 then
		counts[hash] = nil
	end
end

function count_by_chunk.move(from_pos, to_pos, delta)
	delta = delta or 1
	count_by_chunk.change(from_pos, -delta)
	count_by_chunk.change(to_pos, delta)
end

function count_by_chunk.decrement(pos)
	return count_by_chunk.change(pos, -1)
end

function count_by_chunk.increment(pos)
	return count_by_chunk.change(pos, 1)
end

function count_by_chunk.can_increment(pos)
	return count_by_chunk.get(pos) < max_per_chunk
end

return count_by_chunk
