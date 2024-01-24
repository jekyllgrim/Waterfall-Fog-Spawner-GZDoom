version "4.10"

Class WaterfallFogSpawner : Actor
{
	const PARTSPAWNFREQ = 6;
	const VISCHECKTICS = 8;
	int user_rendermode;
	string user_color;
	enum ERenderMode
	{
		RM_Particles,
		RM_Actors,
	}

	double visDist;
	private int wwidth;
	private int trans;
	private color wcolor;
	private int wscale;
	private int wdensity;
	private int waterfallBits;
	private int partSpawnOfs;
	bool alwaysAnimate;
	array<TextureID> cachedFogTextures;

	static const name WFSWaterTranslations[] =
	{
		"", "RedWater", "GreenWater", "GoldWater", "PurpleWater", "OrangeWater", "WhiteWater", "BrownWater"
	};	

	static const name FogTextures[] = { "WFSPA0", "WFSPB0", "WFSPC0", "WFSPD0", "WFSPE0" };

	static const color FogColors[] = 
	{ 
		"1010FF", //blue
		"FF2020", //red
		"AAFF00", //green
		"ffc320", //gold
		"FF20FF", //purple
		"FFCC00", //orange
		"FFFFFF", //white
		"422214"  //brown
	};

	Default
	{
		//$Title "Watefall fog spawner"
		//$Angled
		//$Category "Decoration"
		
		//$Arg0 "Length"
		//$Arg0Tooltip "Make this equal to the length of the linedef next to which the spawner is placed"
		
		//$Arg1 "Color"
		//$Arg1Type 11
		//$Arg1Enum { 0 = "Blue"; 1 = "Red"; 2 = "Green"; 3 = "Yellow"; 4 = "Purple"; 5 = "Dark orange"; 6 = "White"; 7 = "Brown"; }
		
		//$Arg2 "Scale"
		//$Arg2Type 11
		//$Arg2Enum { 1 = "x1"; 2 = "x2"; 3 = "x3"; 4 = "x4"; 5 = "x5"; 6 = "x6"; 7 = "x7"; 8 = "x8"; }
		
		//$Arg3 "Density"
		//$Arg3Tooltip "Determines the gap between water splash emitters.\nThe higher the number, the LESS dense the waterfall is.\nUsually 1 is OK, but you may use higher numbers if you use large scale.\n(0 is interpreted as 1.)"
		
		//$Arg4 "Ignore distance/visibility checks"
		//$Arg4Type 11
		//$Arg4Tooltip "If true, will animate regardless of visibility or distance to the player.\nUse with caution! May cause performance issues with many waterfalls."
		//$Arg4Enum { 0 = "False"; 2 = "True"; }
		
		+NOINTERACTION
		+NOBLOCKMAP
		+MOVEWITHSECTOR
		+SYNCHRONIZED
		+DONTBLAST
		FloatBobPhase 0;
		radius 8;
		height 16;
	}

	static clearscope double LinearMap(double val, double source_min, double source_max, double out_min, double out_max, bool clampit = false) 
	{
		double d = (val - source_min) * (out_max - out_min) / (source_max - source_min) + out_min;
		if (clampit)
		{
			double truemax = out_max > out_min ? out_max : out_min;
			double truemin = out_max > out_min ? out_min : out_max;
			d = Clamp(d, truemin, truemax);
		}
		return d;
	}

	/*	Built-in CheckSight() has an RNG call if the
		dest actor has 0 alpha of bINVISIBLE, which can 
		potentially desync. Boondorl helped me to make
		this simplified version without RNG:
	*/
	bool SimpleCheckSight(PlayerPawn who)
	{
		if (!who)
			return false;
		//Get a vector from the *top* of the waterfall to player eye level:
		Vector3 delta = Vec3To(who) + (0,0,who.player.viewz - who.pos.z - height);
		vector2 aim = (VectorAngle(delta.x, delta.y), -VectorAngle(delta.xy.Length(), delta.z) );
		return !LineTrace(aim.x,delta.Length(),aim.y,TRF_THRUBLOCK|TRF_THRUHITSCAN|TRF_THRUACTORS, offsetz:height);
	}
	
	
	/* 	This checks for distance to consoleplayer;
		should be safe for MP since the actor is 
		completely non-interactive.
		Returns 0 if sight check fails.
	*/
	double CheckPlayerVisibility()
	{
		// If this is true, ignore sight check and always return
		// the smallest sensible value
		if (alwaysAnimate)
		{
			return 256;
		}
		PlayerInfo player = players[consoleplayer];
		if (player && player.mo && SimpleCheckSight(player.mo))
		{
			return Distance3D(player.mo);
		}
		return 0;
	}

	override void PostBeginPlay()
	{
		super.PostBeginPlay();

		//preserve flags set in the map editor:
		bDORMANT = (SpawnFlags & MTF_DORMANT);
		//since NOGRAVITY can't be set from the editor, we'll use the standstill flag instead:
		bNOGRAVITY = (SpawnFlags & MTF_STANDSTILL);
		//argument #1: waterfall width (length):
		wwidth = Clamp(args[0], 1, 1024); 
		//argument #2: waterfall color (blue by default):
		trans = Clamp(args[1], 0, min(WFSWaterTranslations.Size()-1, FogColors.Size()-1));
		//argument #3: scale of waterfall particles:
		wscale = Clamp(args[2], 1, 7);
		//argument #4: density of particles:
		wdensity = Clamp(args[3], 1, wwidth);
		//argument #5: skip distance check if not 0:
		alwaysAnimate = Clamp(args[4], 0, 1);

		if (user_color)
		{
			wcolor = color(user_color);
		}
		
		//get total number of particles by dividing width by density:
		waterfallBits = wwidth / wdensity;
		double startOfs = -(wwidth / 2);

		for (int i = 0; i < FogTextures.Size() - 1; i++)
		{
			cachedFogTextures.Push(int(TexMan.CheckForTexture(FogTextures[i])));
		}

		if (user_rendermode != RM_Actors)
		{
			return;
		}
		
		for (int steps = waterfallBits; steps >= 0; steps--)
		{
			let fog = WaterfallFog(Spawn("WaterfallFog",pos));
			if (!fog)
				continue;
			
			fog.A_SetTranslation(WFSWaterTranslations[trans]);
			vector2 sscale = 0.15 * (wscale,wscale);
			fog.scale = sscale;
			fog.wscale = sscale;
			vector3 fogvel = (frandom[fog](-0.8,0.8),frandom[fog](-0.8,0.8),frandom[fog](0.6,1.4));
			fog.vel = fogvel;
			fog.spawnVel = fogvel;
			fog.Warp(self, yofs: startOfs + (steps * wdensity));
			fog.spawnPos = fog.pos;
			fog.wspawner = WaterfallFogSpawner(self);
			if (wcolor != 0)
			{
				fog.A_SetRenderstyle(fog.alpha, STYLE_Shaded);
				fog.SetShade(wcolor);
			}
			
			//	Forcefully make the particles "tick" a few times
			//	so that they don't appear/reappear at the same time.
			//	(In a way this is a fancier version of +RANDOMIZE.)
			for (int fogtics = random[fogtics](0,32); fogtics > 0; fogtics--)
			{
				fog.AnimateFog();
			}
		}
	}

	override void Activate(Actor activator)
	{
		Super.Activate(activator);
		bDORMANT = false;
	}

	override void Deactivate(Actor activator)
	{
		Super.Deactivate(activator);
		bDORMANT = true;
	}

	override void Tick()
	{
		if (bDORMANT)
			return;
		
		if (!bNOGRAVITY)
		{
			SetOrigin((pos.xy, floorz), true);
		}
		
		/*	Re-checking visibility/distance every tic is 
			excessive, so we only do it every VISCHECKTICS tics.
		*/
		if (GetAge() % VISCHECKTICS == 0)
		{
			visDist = CheckPlayerVisibility();
		}

		if (user_rendermode != RM_Particles || visDist <= 0)
		{
			return;
		}

		FSpawnParticleParams fog;
		fog.lifetime = 40;
		let def = GetDefaultByType('WaterfallFog');
		fog.startalpha = def.alpha;
		fog.fadestep = -1;
		fog.accel.z = -(def.gravity);
		double fogScale = wscale * 0.15;
		if (wcolor != 0)
		{
			fog.color1 = wcolor;
			fog.style = STYLE_Shaded;
		}
		else
		{
			fog.color1 = FogColors[trans];
		}
		fog.flags = SPF_ROLL|SPF_REPLACE;

		double startOfs = -(wwidth / 2);
		for (int steps = partSpawnOfs; steps <= waterfallBits; steps += PARTSPAWNFREQ)
		{
			fog.texture = cachedFogTextures[random[fog](0, cachedFogTextures.Size()-1)];
			fog.size = TexMan.GetSize(fog.texture) * fogScale * frandom[fog](0.8, 1.2);
			fog.sizestep = fog.size * 0.03;
			fog.vel = (frandom[fog](-0.8,0.8),frandom[fog](-0.8,0.8),frandom[fog](0.6,1.4));
			
			fog.pos.xy = (0, startOfs + (steps * wdensity));
			fog.pos.xy = self.pos.xy + Actor.RotateVector(fog.pos.xy, angle);
			fog.pos.z = self.pos.z;

			double ofs = fog.size * fogScale;
			fog.pos += (frandom[fog](-ofs, ofs), frandom[fog](-ofs, ofs), frandom[fog](0, ofs));

			fog.startroll = frandom[fog](-40,40);
			fog.rollvel = frandom[fog](-2.4,2.4);
			
			Level.SpawnParticle(fog);
		}
		partSpawnOfs++;
		if (partSpawnOfs >= PARTSPAWNFREQ)
		{
			partSpawnOfs = 0;
		}
	}
}

Class WaterfallFog : Actor
{
	const FOGFADEFAC = 0.013;

	vector3 spawnPos;
	vector3 spawnVel;
	vector2 wscale;
	double wroll;
	int doTic;
	WaterfallFogSpawner wspawner;

	Default
	{
		radius 1;
		height 1;
		renderstyle 'Translucent';
		alpha 0.32;
		gravity 0.15;
		FloatBobPhase 0;
		+ROLLSPRITE
		+FORCEXYBILLBOARD
		+NOINTERACTION
		+NOBLOCKMAP
		+SYNCHRONIZED
		+DONTBLAST
	}

	void AnimateFog()
	{
		vel.z -= gravity;
		SetOrigin(pos+vel,true);
		scale *= 1.03;
		A_FadeOut(FOGFADEFAC, 0);
		roll += wroll;
		if (alpha <= 0) {
			SetOrigin(spawnPos,false);
			vel = spawnVel;
			vel.x *= randompick[fog](-1,1);
			vel.y *= randompick[fog](-1,1);
			scale = wscale;
			alpha = default.alpha;
			roll = default.roll;
		}
	}

	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		roll = frandom[fog](-40,40);
		frame = random[fog](0,4);
		wroll = frandom[fog](-2.4,2.4);
		doTic = 1;
	}	

	override void Tick()
	{
		if (!wspawner)
		{
			Destroy();
			return;
		}
		if (wspawner.bDORMANT || (!wspawner.alwaysAnimate && wspawner.visDist <= 0))
		{
			return;
		}
		if (!wspawner.bNOGRAVITY)
		{
			spawnPos.z = wspawner.pos.z;
		}
		//the animation will be executed less often for every 256 units the player is away from the waterfall:
		doTic = Clamp(wspawner.visDist / 256, 1, 80);
		//console.printf ("age %d | dotic: %d | Distance %d",GetAge(),dotic,wspawner.visDist);
		if (GetAge() % doTic == 0)
		{
			AnimateFog();
		}
	}

	States {
	Spawn:
		WFSP # -1;
		stop;
	}
}