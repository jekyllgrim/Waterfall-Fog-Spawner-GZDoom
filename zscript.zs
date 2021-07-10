version "4.2.4"

Class WaterfallFogSpawner : Actor {
	int visDist;
	private int wwidth;
	private int trans;
	private int wscale;
	private int wdensity;
	const visCheckTics = 8;
	static const name WFSWaterTranslations[] = {
		"", "RedWater", "GreenWater", "GoldWater", "PurpleWater", "OrangeWater", "WhiteWater"
	};	
	Default {
		+NOINTERACTION
		+SYNCHRONIZED
		+DONTBLAST
		radius 8;
		height 16;
	}
	/*	Built-in CheckSight() has an RNG call if the
		dest actor has 0 alpha of bINVISIBLE, which can 
		potentially desync. Boondorl helped me to make
		this simplified version without RNG:
	*/
	bool SimpleCheckSight(PlayerPawn who) {
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
	int CheckPlayerVisibility() {
		PlayerInfo player = players[consoleplayer];
		if (player && player.mo && SimpleCheckSight(player.mo))
			return Distance3D(player.mo);
		return 0;
	}	
	override void PostBeginPlay() {
		super.PostBeginPlay();		
        bDORMANT = (SpawnFlags & MTF_DORMANT); //preserve DORMANT as set in the map editor
		wwidth = Clamp(args[0],1,1024); //argument #1: waterfall width (length)
		trans = Clamp(args[1],0,5); //argument #2: waterfall color (blue by default)
		wscale = Clamp(args[2],1,7); //argument #3: scale of waterfall particles
		wdensity = Clamp(args[3], 1, wwidth); //argument #4: density of particles
		
		int steps = wwidth / wdensity; //get total number of particles by dividing width by density
		double startOfs = -(wwidth / 2);
		for (steps; steps >= 0; steps--) {
			let fog = WaterfallFog(Spawn("WaterfallFog",pos));
			if (fog) {
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
				/*	Forcefully make the particles "tick" a few times
					so that they don't appear/reappear at the same time.
					(In a way this is a fancier version of +RANDOMIZE.)
				*/
				for (int fogtics = random[fogtics](0,32); fogtics > 0; fogtics--)
					fog.AnimateFog();
			}
		}
	}	
    override void Activate(Actor activator) {
        Super.Activate(activator);
        bDORMANT = !bDORMANT;
    }
    override void Deactivate(Actor activator) {
        Super.Deactivate(activator);
        bDORMANT = !bDORMANT;
    }
	override void Tick() {
		if (bDORMANT)
			return;
		/*	Re-checking visibility/distance every tic is 
			excessive, so we only do it every visCheckTics tics.
		*/
		if (GetAge() % visCheckTics == 0) {
			visDist = CheckPlayerVisibility();
		}
	}
}

Class WaterfallFog : Actor {
	vector3 spawnPos;
	vector3 spawnVel;
	vector2 wscale;
	double wroll;
	int doTic;
	WaterfallFogSpawner wspawner;
	Default {
		radius 1;
		height 1;
		renderstyle 'Translucent';
		alpha 0.32;
		gravity 0.15;
		+ROLLSPRITE
		+FORCEXYBILLBOARD
		+NOINTERACTION
		+SYNCHRONIZED
		+DONTBLAST
	}
	void AnimateFog() {
		vel.z -= gravity;
		SetOrigin(pos+vel,true);
		scale *= 1.03;
		A_FadeOut(0.013, 0);
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
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll = frandom[fog](-40,40);
		frame = random[fog](0,3);
		wroll = frandom[fog](-2.4,2.4);
		doTic = 1;
	}	
	override void Tick() {
		if (!wspawner) {
			Destroy();
			return;
		}
		if (wspawner.bDORMANT || wspawner.visDist <= 0)
			return;
		//the animation will be executed less often for every 256 units the player is away from the waterfall:
		doTic = Clamp(wspawner.visDist / 256, 1, 80);
		//console.printf ("age %d | dotic: %d | Distance %d",GetAge(),dotic,wspawner.visDist);
		if (GetAge() % doTic == 0) {
			AnimateFog();
		}
	}
	states {
	Spawn:
		WFSP # -1;
		stop;
	Cache:
		WFSP ABCD 0;
	}
}