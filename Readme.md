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

## License

* Code: [MIT](https://opensource.org/licenses/MIT)
  * Written by [regulus](https://github.com/regulus79) and [LMD](https://github.com/appgurueu)
* Media: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/legalcode)
  * Slides (`sd_story_slide_%d.png`) by [Dragoni](https://github.com/DragoniEU/) and edited by [temhotaokeaha](https://github.com/temhotaokeaha)
  * All other textures by [temhotaokeaha](https://github.com/temhotaokeaha)
  * Sounds:
    * CC0 1.0 Universal:
      * [`sd_player_hurt.ogg`](https://freesound.org/people/Rickplayer/sounds/530486/)
      * `sd_map_ambient_intro.1.ogg`: ["Things Change" by HoliznaCC0](https://freemusicarchive.org/music/holiznacc0/forager-pt-2/things-change/)
      * `sd_map_ambient_intro.2.ogg`: ["Eat" by HoliznaCC0](https://freemusicarchive.org/music/holiznacc0/bassic/eatmp3/)
      * `sd_map_ambient_basalt_caves.1.ogg`: ["Halloween Soundscape" by HoliznaCC0](https://freemusicarchive.org/music/holiznacc0/horseless-headman-halloween-beats/halloween-soundscape/)
      * `sd_map_ambient_basalt_caves.2.ogg`: ["Under The Floor Boards" by HoliznaCC0](https://freemusicarchive.org/music/holiznacc0/beats-from-the-crypt/under-the-floor-boards/)
      * `sd_map_ambient_ending.ogg`: ["Light At The End Of The Tunnel" by "HoliznaCC0"](https://freemusicarchive.org/music/holiznacc0/forager-pt-2/light-at-the-end-of-the-tunnel/)
      * `sd_map_ambient_icy.ogg`: ["Burning In The Atmosphere" by HoliznaCC0](https://freemusicarchive.org/music/holiznacc0/stranger-than-fiction-halloween-sci-fi/burning-in-the-atmosphere/)
    * CC-BY 4.0: `sd_map_ambient_red_granite.ogg`: ["Birth Of The Sun" (Drone) by Daniel Birch](https://freemusicarchive.org/music/Daniel_Birch/through-the-looking-glass-original-score/birth-of-the-sun-drone/)