local require = modlib.mod.require
-- Common tool functionality
require("step_effects")
-- Tools
require("give")(
	require("acid_sprayer"),
	require("manipulator"),
	require("drill"),
	require("light") -- TBD: craftitems vs. tool?
)
