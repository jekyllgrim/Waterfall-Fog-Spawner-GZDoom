version "4.2.4"

Class WaterfallFogSpawner : Actor {
	bool visible;
	private int wwidth;
	private int trans;
	private double wscale;
	static const name WFSWaterTranslations[] = {
		"", "RedWater", "GreenWater", "GoldWater", "PurpleWater", "OrangeWater", "WhiteWater"
	};
	private vector3 FogVel[64];
	private vector3 FogPos[32];
	private int FogVelSeed;
	private int FogPosSeed;
	const maxFogVelSeed = 63;
	const maxFogPosSeed = 31;
	bool CanSeePlayer() {
		for ( int i=0; i<MAXPLAYERS; i++ ) 	{
			if ( playeringame[i] && CheckSight(players[i].mo) )
				return true;
		}
		return false;
	}	
	override void PostBeginPlay() {
		super.PostBeginPlay();		
        bDORMANT = (SpawnFlags & MTF_DORMANT);
		wwidth = Clamp(args[0],0,1024) / 16;
		trans = Clamp(args[1],0,5);
		wscale = Clamp(args[2],1,7);
		for (int i = 0; i < maxFogVelSeed; i++)
			FogVel[i] = (frandom[fog](-0.8,0.8),frandom[fog](-0.8,0.8),frandom[fog](0.6,1.4));
		for (int i = 0; i < maxFogPosSeed; i++)
			FogPos[i] = (frandom[fog](-8,8)*wscale,frandom[fog](-8,8),frandom[fog](-8,8));
		//fogVelSeed = random[fog](0,maxFogVelSeed);
		//fogPosSeed = random[fog](0,maxFogPosSeed);
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
		if (isFrozen() || bDORMANT)
			return;		
		if (GetAge() % 10 == 0)
			visible = CanSeePlayer();
		if (!visible)
			return;
		for (int steps = wwidth; steps >= 0; steps--) {
			let fog = Spawn("WaterfallFog",pos);
			if (fog) {
				fog.A_SetTranslation(WFSWaterTranslations[trans]);
				fog.scale = (0.15,0.15) * wscale;
				fog.Warp(self,16 * steps);
				//fogVelSeed = (fogVelSeed > maxFogVelSeed) ? 0 : fogVelSeed++;
				//fogPosSeed = (fogPosSeed > maxFogPosSeed) ? 0 : fogPosSeed++;
				fog.vel = FogVel[random[fog](0,fogVelSeed)];
				fog.SetOrigin(fog.pos + FogPos[random[fog](0,fogPosSeed)],false);	
			}
		}
	}
}

Class WaterfallFog : Actor {
	Default {
		renderstyle 'Translucent';
		alpha 0.4;
		scale 0.2;
		gravity 0.2;
		+ROLLSPRITE
		+FORCEXYBILLBOARD
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll = frandom[fog](-40,40);
		frame = random[fog](0,2);
	}
	override void Tick() {
		if (isFrozen())
			return;
		vel.z -= gravity;
		SetOrigin(pos+vel,true);
		scale *= 1.03;
		A_FadeOut(0.02);
	}
	states {
	Spawn:
		WFSP # 1;
		loop;
	}
}