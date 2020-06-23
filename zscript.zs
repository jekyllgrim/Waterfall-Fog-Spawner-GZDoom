version "4.2.4"

Class WaterfallFogSpawner : Actor {
	private int wwidth;
	private int trans;
	private double wscale;
	static const name WFSWaterTranslations[] = {
		"", "RedWater", "GreenWater", "GoldWater", "PurpleWater", "OrangeWater", "WhiteWater"
	};
	override void PostBeginPlay() {
		super.PostBeginPlay();		
		wwidth = Clamp(args[0],0,1024) / 16;
		trans = Clamp(args[1],0,5);
		wscale = Clamp(args[2],1,7);
	}
	override void Tick() {
		if (isFrozen())
			return;
		for (int steps = wwidth; steps >= 0; steps--) {
			let fog = Spawn("WaterfallFog",pos);
			if (fog) {
				fog.A_SetTranslation(WFSWaterTranslations[trans]);
				fog.scale = (0.15,0.15) * wscale;
				fog.Warp(self,16 * steps);
				fog.SetOrigin(fog.pos + (frandom[fog](-8,8)*wscale,frandom[fog](-8,8),frandom[fog](-8,8)),false);
				fog.vel = (frandom[fog](-0.8,0.8),frandom[fog](-0.8,0.8),frandom[fog](0.6,1.4));					
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