Waterfall Fog Spawner for GZDoom by Agent_Ash (aka Jekyll Grim Payne)

This asset contains ZScript code for waterfall fog spawner, meant to be placed at the bottom of waterfalls.

Feel free to use this in your maps. Credits are appreciated but not required.

Sprites are made from free resources available online. Feel free to replace them if you like.

How to use in your map:

- Place thing 20100 "WaterfallFogSpawner" at the edge of your waterfall (where the fall connects with the body of water underneath)

- Make sure WaterfallFogSpawner angle is set so that it's facing ALONGSIDE the waterfall line

- Open WaterfallFogSpawner's properties in Doom Builder, navigate to 'Action / Tag/ Misc.' tab to access arguments. Changing the arguments will affect the fog's appearance in the following way:

	Argument 1:	Determines the length of the line along which the effects will spawn. Use the same value as your waterfall's linedef length. 0 (default) will make it spawn over a small area (useful for small water pillars and such).
	Argument 2: Determines the color of the splashes:
				0: regular blue
				1: red
				2: green
				3: yellow
				4: purple
				5: dark-orange
				6: white
	Argument 3: Scales the size of the splashes from x1 to x8 (higher values will look the same as x8). 0 (default) is interpreted as 1. Note that scale will affect visible size, so at high values you might want to reduce the value of Argument #1.