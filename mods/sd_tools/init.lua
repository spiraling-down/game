local require = modlib.mod.require
-- Common tool functionality
require("step_effects")
-- Tools
-- TODO all of these tools need something
require("give")(
	require("acid_sprayer"),
	require("manipulator"),
	require("drill"),
	require("light") -- TBD: craftitems vs. tool?
)
