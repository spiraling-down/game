# Spiraling Down

A Minetest Game for the 2022 Minetest Game Jam.

## Playing

### [Get it on ContentDB](https://content.minetest.net/packages/sdd/spiraling_down)

### Recommended Specs

* CPU with a PassMark Single Thread Rating of approximately 2000 or more (e.g. [AMD Ryzen 5 3500U](https://www.cpubenchmark.net/cpu.php?cpu=AMD+Ryzen+5+3500U&id=3421))
* At least 2 GB of free RAM
* About 1 GB of free disk

## Developing

### Installation

1. Enter your `games` folder
   * Standard Linux installation: `cd ~/.minetest/games`
2. Clone the game & enter the folder:
   1. `git clone https://github.com/spiraling-down/game spiraling_down`
   2. `cd spiraling_down`
3. Initialize submodules: `git submodule update --init --recursive`

### Requirements

* [StyLua](https://github.com/JohnnyMorganz/StyLua)
* [luacheck](https://github.com/mpeterv/luacheck)

Each mod needs to have its own `.luacheckrc` to be linted;
all mods (except for submodules / 3rd party mods, which are explicitly ignored using `.styluaignore`)
are checked for proper formatting using `stylua --check .`;
to format your mods, you can use `stylua <mod folder>`
or [the Visual Studio Code extension](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.stylua).

You can run `./utils/code_checks.sh` to apply the same checks locally (and more efficiently)
without needing [a GitHub CI runner](https://github.com/nektos/act).

## [License](License.md)