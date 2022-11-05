# Spiraling Down

A Minetest Game for the 2022 Minetest Game Jam.

## Developing

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

## License

* Code: [MIT](https://opensource.org/licenses/MIT)
* Media: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/legalcode)
