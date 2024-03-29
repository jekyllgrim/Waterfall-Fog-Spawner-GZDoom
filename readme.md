## Waterfall Fog Spawner for GZDoom by Agent_Ash (aka Jekyll Grim Payne)

This asset contains ZScript code for waterfall fog spawner, meant to be placed at the bottom of waterfalls.

Feel free to use this in your maps. Credits are appreciated but not required.

Sprites are made from free resources available online. Feel free to replace them if you like.

## How to use in your map

- Place thing 20100 `WaterfallFogSpawner` at the *center* of your waterfall linedef
- Make sure `WaterfallFogSpawner` thing is facing towards or away from the waterfall (not alongside it; that was used in older versions)
- Open `WaterfallFogSpawner`'s properties in Doom Builder, navigate to **Action / Tag/ Misc.** tab to access arguments. Changing the arguments will affect the fog's appearance in the following ways:

### Arguments

**Argument 1**: Determines the length of the line along which the effects will spawn. Use the same value as your waterfall's linedef length. 0 (default) will make it spawn over a small area (useful for small water pillars and such).

**Argument 2**: Determines the color of the splashes:

0. regular blue
1. red
2. green
3. yellow
4. purple
5. dark-orange
6. white

**Argument 3**: Scales the size of the splashes from x1 to x8 (higher values will look the same as x8). `0` (default) is interpreted as `1`. Note that scale will affect visible size, so at high values you might want to reduce the value of Argument #1.

**Argument #4**: Density. Determines how many particles will be spawned along the waterfall's length. For example, if your waterfall is 128 units long and argument 4 is `8`, a waterfall fog particle will be spawned every 8 units along its length, meaning 16 in total. The default value is `1` and it usually works, but if you use higher scale values (argument #3), then you might want to reduce the density. **Remember**: higher values = *less* dense waterfall.

**Arguemtn #5**: *Force animation*. If this is any number other than 0, the waterfall will ignore distance checks and will always animate. **Use with caution!** This is meant for waterfalls that can't be directly visible, such as placed inside skyboxes. Manual activation/deactivation is recommended for this use case.

### User fields
These can be set up in the Custom tab of the properties of the Waterfall Fog Spawner:
1. `user_rendermode` — determines if this spawner will use textured particles (low performance impact) or actors. The default value of 0 is textured particles, other values are actors.
2. `user_color` — lets you specify an RRGGBB color (for example "FF0000"). If set, this overrides argument #2 and instead gives the particles a custom color.

See demonstration map (attached in the releases tab) to see some examples.

## Credits and permissions
Waterfall Fog Spawner by Agent_Ash aka Jekyll Grim Payne
Free to use with credit.
