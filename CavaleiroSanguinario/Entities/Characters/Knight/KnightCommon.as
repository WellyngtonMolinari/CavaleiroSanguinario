//common knight header
#include "RunnerCommon.as";

namespace KnightStates
{
	enum States
	{
		normal = 0,
		shielding,
		shielddropping,
		shieldgliding,
		sword_drawn,
		sword_cut_mid,
		sword_cut_mid_down,
		sword_cut_up,
		sword_cut_down,
		sword_power,
		sword_power_super,
		resheathing_cut,
		resheathing_slash
	}
}

namespace KnightVars
{
	const ::s32 resheath_cut_time = 1; // Reduced for quicker recovery
	const ::s32 resheath_slash_time = 1; // Reduced for quicker recovery

	const ::s32 slash_charge = 5; // Reduced for faster attack
	const ::s32 slash_charge_level2 = 10; // Reduced for faster powerful attack
	const ::s32 slash_charge_limit = slash_charge_level2 + slash_charge + 5; // Adjusted to match faster charge

	const ::s32 slash_move_time = 2; // Reduced to allow quicker movement during slash
	const ::s32 slash_time = 7; // Reduced for quicker slash execution
	const ::s32 double_slash_time = 4; // Reduced for faster double slash

	const ::f32 slash_move_max_speed = 7.0f; // Increased speed during slash

	const u32 glide_down_time = 25; // Reduced to extend the gliding time

	//// OLD MOD COMPATIBILITY ////
	const f32 resheath_time = 1.0f; // Reduced for quicker resheathing
}

shared class KnightInfo
{
	u8 swordTimer;
	bool doubleslash;
	u8 tileDestructionLimiter;
	u32 slideTime;

	u8 state;
	Vec2f slash_direction;
	s32 shield_down;

	//// OLD MOD COMPATIBILITY ////
	u8 shieldTimer;
};

shared class KnightState
{
	u32 stateEnteredTime = 0;

	KnightState() {}
	u8 getStateValue() { return 0; }
	void StateEntered(CBlob@ this, KnightInfo@ knight, u8 previous_state) {}
	// set knight.state to change states
	// return true if we should tick the next state right away
	bool TickState(CBlob@ this, KnightInfo@ knight, RunnerMoveVars@ moveVars) { return false; }
	void StateExited(CBlob@ this, KnightInfo@ knight, u8 next_state) {}
}

namespace BombType
{
	enum type
	{
		bomb = 0,
		water,
		count
	};
}

const string[] bombNames = { "Bomb",
                             "Water Bomb"
                           };

const string[] bombIcons = { "$Bomb$",
                             "$WaterBomb$"
                           };

const string[] bombTypeNames = { "mat_bombs",
                                 "mat_waterbombs"
                               };

bool hasBombs(CBlob@ this, u8 bombType)
{
	return bombType < BombType::count && this.getBlobCount(bombTypeNames[bombType]) > 0;
}

//checking state stuff

bool isShieldState(u8 state)
{
	return (state >= KnightStates::shielding && state <= KnightStates::shieldgliding);
}

bool isSpecialShieldState(u8 state)
{
	return (state > KnightStates::shielding && state <= KnightStates::shieldgliding);
}

bool isSwordState(u8 state)
{
	return (state >= KnightStates::sword_drawn && state <= KnightStates::resheathing_slash);
}

bool inMiddleOfAttack(u8 state)
{
	return ((state > KnightStates::sword_drawn && state <= KnightStates::sword_power_super));
}

//checking angle stuff

f32 getCutAngle(CBlob@ this, u8 state)
{
	f32 attackAngle = (this.isFacingLeft() ? 180.0f : 0.0f);

	if (state == KnightStates::sword_cut_mid)
	{
		attackAngle += (this.isFacingLeft() ? 30.0f : -30.0f);
	}
	else if (state == KnightStates::sword_cut_mid_down)
	{
		attackAngle -= (this.isFacingLeft() ? 30.0f : -30.0f);
	}
	else if (state == KnightStates::sword_cut_up)
	{
		attackAngle += (this.isFacingLeft() ? 80.0f : -80.0f);
	}
	else if (state == KnightStates::sword_cut_down)
	{
		attackAngle -= (this.isFacingLeft() ? 80.0f : -80.0f);
	}

	return attackAngle;
}

f32 getCutAngle(CBlob@ this)
{
	Vec2f aimpos = this.getMovement().getVars().aimpos;
	int tempState;
	Vec2f vec;
	int direction = this.getAimDirection(vec);

	if (direction == -1)
	{
		tempState = KnightStates::sword_cut_up;
	}
	else if (direction == 0)
	{
		if (aimpos.y < this.getPosition().y)
		{
			tempState = KnightStates::sword_cut_mid;
		}
		else
		{
			tempState = KnightStates::sword_cut_mid_down;
		}
	}
	else
	{
		tempState = KnightStates::sword_cut_down;
	}

	return getCutAngle(this, tempState);
}

//shared attacking/bashing constants (should be in KnightVars but used all over)

const int DELTA_BEGIN_ATTACK = 1; // Reduced for faster attack initiation
const int DELTA_END_ATTACK = 3; // Reduced for quicker recovery post-attack
const f32 DEFAULT_ATTACK_DISTANCE = 24.0f; // Increased attack range
const f32 MAX_ATTACK_DISTANCE = 30.0f; // Increased maximum attack range
const f32 SHIELD_KNOCK_VELOCITY = 5.0f; // Increased knockback force

const f32 SHIELD_BLOCK_ANGLE = 180.0f; // Increased block angle for full front protection
const f32 SHIELD_BLOCK_ANGLE_GLIDING = 160.0f; // Increased block angle during gliding
const f32 SHIELD_BLOCK_ANGLE_SLIDING = 170.0f; // Increased block angle during sliding
