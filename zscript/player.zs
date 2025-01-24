class GrapplePlayer : DoomPlayer {
	const MAX_GRAPPLE_DIST = 600;
	const TRAIL_AMMOUNT = 10;
	
	//important grappling stuff
	bool GrappledToSomething; //whether im grappled to something
	bool GrappleReady; //pressing "Fire Grapple" will grab the Thing;
	actor ThingIJustFound;
	vector3 GrappledSpot;
	vector3 PlayerToSpot;
	double AbsDistFromSpot;
	double CurrentMaxDist;
	
	//important swinging stuff
	bool shouldSwingForward;
	bool shouldSwingBackward;
	
	//Info on that actor the Player grapples onto
	vector3 ThingVecOnPlane;
	double angleToThing;
	
	Default{
		Player.DisplayName "Greg";
		Mass 10;
		//Speed 1.4;
	}
	override void PostBeginPlay(){
		Super.PostBeginPlay();
		JumpZ = 12;
		
		//you just spawned bro who do you think you are
		shouldSwingForward = false;
		shouldSwingBackward = false;
	}
	
	
	void FireGrapple() {
		//only try to fire grapple when you are not grappled already
		if(GrappledToSomething){
			//by pressing the grapple button again you will let go.
			UnGrapple();
			return;
		}
		
		if(GrappleReady && ThingIJustFound){
			Grapple();
		}
		
	}
	
	void DrawTrail(){
		//this is to draw the rope
		if(GrappledToSomething){
			//segment the vector into 10, then spawn a trail on each segment.
			for(int i = 0; i < TRAIL_AMMOUNT; i+= 1) {
			
				vector3 offsetPTS = PlayerToSpot/TRAIL_AMMOUNT*i; //offset Player To Spot
				double xofset = offsetPTS.x;
				double yofset = offsetPTS.y;
				double zofset = offsetPTS.z;
				/*  
					ok so for whatever reason, the y and x offsets are fliped in the spawn function.
					or more likely, i cant read documentation.
				*/
				A_SpawnItemEx("GrappleTrail",xofs: yofset,yofs: xofset,zofs: zofset + height/2, tid:(91021 + i));//you stupid
			}
		}
	}
	void UpdateTrail(){
		if(!GrappledToSomething){
			return;
		}
		/*
			find all 10 trails and move them so they are "back in line"
			This implimentation was inspired by the HookTrails from Ivory Duke's ZMovement project.
		*/
		for(int i = 0; i < TRAIL_AMMOUNT; i+= 1) {
			ActorIterator WhereAreTrails = Level.CreateActorIterator(91021+i);
			Actor Trail = WhereAreTrails.Next();//im only ever expecting one item to be here.
			if(Trail != null) {
				Trail.SetOrigin(pos+(0,0,height/3)+(PlayerToSpot/TRAIL_AMMOUNT*i),false);
			}
			
		}
	}
	void KillTrail(){
		for(int i = 0; i < TRAIL_AMMOUNT; i+= 1) {
			ActorIterator WhereAreTrails = Level.CreateActorIterator(91021+i);
			Actor Trail = WhereAreTrails.Next();//im only ever expecting one item to be here.
			if(Trail != null) {
				Trail.SetState(FindState("UnGrapple"));
			}
			
		}
	}
	
	void UnGrapple(){
		//cowabummer, dude
		GrappledToSomething = false;
		ThingIJustFound = null;
		PlayerToSpot = (0,0,0);
		CurrentMaxDist = double.NaN;
		KillTrail();
		//speed = 1;
		vel += (0,0,5);
	}
	void Grapple(){
		//we caught something! Big Fish!!
		A_StartSound("weapons/plasmaf");
		GrappledToSomething = true;
		PlayerToSpot = Vec3To(ThingIJustFound);
		CurrentMaxDist = Distance3D(ThingIJustFound);
		GrappledSpot = ThingIJustFound.pos;
		DrawTrail();
		//speed = 2;	
	}
	
	vector3 StayInTheRing(actor ThingRing){
		//go from the origin (0,0,0) to the thing, then from the thing x units towards the player
		return ThingRing.pos - Vec3To(ThingRing).Unit()*CurrentMaxDist;
	}
	
	void MoveAlongTheRing(actor Thing1) {
		
		vector3 Vec3AwayFromThing = -1*Vec3To(Thing1);
		
		/* player's velocity vector, projected on the vector facing away from the Thing. 
		perpendicular movement will result in a 0 vector, which is fine because I want to move perpendicular anyways  
		*/
		vector3 VelAwayFromThing = project(vel, Vec3AwayFromThing);
		//stop going away from meeeeee :(((
		vel -= VelAwayFromThing;
		
		/*this code didn't work the way i wanted it to, but it was really funny so i kept it here in case you wanted to uncomment it*/
		//vel += vel.Unit() * VelAwayFromThing.Length(); 
		
		
	}
	
	
	//this is where the magic happens
	override void Tick(){
		Super.Tick();
		
		if(GrappledToSomething) { //already grapplin
			if(shouldSwingForward){
				ForwInAir();
			}
			if(shouldSwingBackward){
				BackInAir();
			}
			
			
			//speed = 2;
			//control player movement if they "stretch" the rope
			if(ThingIJustFound) {
				if(ThingIJustFound.health <= 0 ){ //i dont think health can be less than zero but just to be safe
					UnGrapple();
					return;
				}
				//CurrentMaxDist -= 0.8;
				/*hold still while i grapple you*/
				ThingIJustFound.vel = (0,0,0);
				ThingIJustFound.SetOrigin(GrappledSpot,false);
				
				PlayerToSpot = Vec3To(ThingIJustFound);
				AbsDistFromSpot = Distance3D(ThingIJustFound);
				
				/*enforce the fact that you are bound by a rope*/
				if(AbsDistFromSpot > CurrentMaxDist) {
					
					SetOrigin(StayInTheRing(ThingIJustFound),true);
					
					//i dont want no clipping shenanigains. shenenigans? Shananagans? 
					if(!(self.player.OnGround)) {						
						//vector3 DesiredMovement = MoveAlongTheRing(ThingIJustFound);
						//A_ChangeVelocity(DesiredMovement.x,DesiredMovement.y,DesiredMovement.z,CVF_REPLACE);
						
						/*woah there buddy you gotta slow down there a bit*/
						//vel += (GrappledSpot-pos).Unit() * CurrentMaxDist/64;
						MoveAlongTheRing(ThingIJustFound);
					}
					
				}
				
				UpdateTrail();
				
			}
			// if no Thing you probably grappled to a surface then. which by the way, is so much more fun to program the behaviour for! 
			// i love not being able to point to the "Thing" I grappled at. That would be too easy!!! :D
			/* else {
				AbsDistFromSpot = (GrappledSpot - pos).Length();
				if(AbsDistFromSpot > CurrentMaxDist){
				
					//get back in your maximum radius, loser
					SetOrigin(StayInTheRing_Sector(),false);
					
					if(!(self.player.OnGround)) {
						//ok so that wasn't actually that bad i may have been overexagerating that bit earlier.
						MoveAlongTheRing_Sector();
					}
				}
			} */
			//2024-08-23 sectors are causing a big a problems rn so i'll just focus on actors for now
		}
		else{ //not grapplin
	
			GrappleReady=false;
			//make a bunch of lines going around the player's cursor
			FLineTraceData WhoDidIShoot;
			bool didIhitSomething;
			for (int i = 0; (i<=24) && !GrappleReady; i+=1) {
				
				for(int j = 0; (j <=24) && !GrappleReady; j+=1){
					//this is basically a big ol square instead of the dot crosshair
					didIhitSomething = LineTrace(angle+j, MAX_GRAPPLE_DIST, pitch+i, 0, viewheight, data: WhoDidIShoot);
					GrappleReady = (didIhitSomething) && (WhoDidIShoot.HitType==TRACE_HitActor);
					if(!GrappleReady){
						didIhitSomething = LineTrace(angle-j, MAX_GRAPPLE_DIST, pitch-i, 0, viewheight, data: WhoDidIShoot);
						GrappleReady = (didIhitSomething) && (WhoDidIShoot.HitType==TRACE_HitActor);
					}
				}
				
			}
			
			if(GrappleReady){
				//console.printf("you should grapple this guy: %s", WhoDidIShoot.HitActor.GetClassName());
				ThingIJustFound = WhoDidIShoot.HitActor;
				DrawPlane();
				
			}
			
			
		}
	}
	
	//2024-12-09 : remind me why i need this???
	//2024-12-09 : nvm i remember now lol
	void ForwInAir(){
		if(!(self.player.OnGround)){
			/*
				variation of NeuralStunner's recoil method: https://forum.zdoom.org/viewtopic.php?t=32535 
			*/
			A_ChangeVelocity(cos(pitch), sin(pitch), 0, CVF_Relative);
		}
		
	}
	void BackInAir(){
		if(!(self.player.OnGround)){
			/*
				variation of NeuralStunner's recoil method: https://forum.zdoom.org/viewtopic.php?t=32535 
			*/
			A_ChangeVelocity(-cos(pitch), -sin(pitch), 0, CVF_Relative);
		}
	}

	//helpers for the eventhandler
	void toggleForwardSwing(){
		shouldSwingForward = !shouldSwingForward;
	}
	void toggleBackwardSwing(){
		shouldSwingBackward =!shouldSwingBackward;
	}


	// draws a small plane in front of the player
	void DrawPlane(){
		//the second half of this code is in the render event handler
		FLineTraceData LTData;
		LineTrace(angle, 0.1, pitch, offsetz: viewheight, data : LTData);
		
		//plane consists of a point and a normal vector
		vector3 playerPlanePoint = pos + (0,0,viewheight);	
		vector3 playerPlaneNorm = LTData.HitLocation - playerPlanePoint;

		
		//vector from Thing to the player's plane
		vector3 ThingVecProj = project(  -(Vec3To(ThingIJustFound)) , playerPlaneNorm ) ;
		//thing's position, relative to the player's plane.
		vector3 ThingPointOnPLane = playerPlanePoint + Vec3To(ThingIJustFound) + ThingVecProj;
		
		ThingVecOnPlane = ThingPointOnPLane - playerPlanePoint;
	}
	
	//for projecting a vector u onto another vector v
	vector3 project(vector3 u, vector3 v){
		//this comes up more often than you think
		if(v.LengthSquared() == 0){
			return (0,0,0);
		}
	
		return (u dot v)/(v.LengthSquared())*(v);
	}
	
}

class GrappleTrail : Actor {
	/* 
	int heirarchy;//idk if i need this 
	 */
	//2024-12-09 : yeah i dont need that
	Default{
		+NOGRAVITY;
		Radius 13;
		Height 8;
		Scale 0.5;
	}
	
	States{
		Spawn:
			Spawn:
			PLSS A 6 Bright;
			Loop;
		UnGrapple:
			Stop;
	}
		
}
