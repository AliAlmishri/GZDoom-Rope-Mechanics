class geezer : HellKnight {
	int counter;

	States {
		Missile:
			BOSS EF 8 A_FaceTarget;
			BOSS G 8 A_BruisAttack;
			BOSS G 0 {
				counter += 1;
			}
			BOSS G 0 A_JumpIf(counter >= 3,"HeartAttack");
			goto See;
		HeartAttack: //old fart freaking dies lmao
			BOSS G 0 A_Die();
	}
}

class HookThing : Actor { //that thing in the game you can swing on in the air on
	Default{
		+NOGRAVITY;
		+SHOOTABLE;
		Radius 14;
		Height 14;
	}
	
	States{
		Spawn:
			GRAP ABCDEFG 1 Bright;
			Loop;
	}
	
}