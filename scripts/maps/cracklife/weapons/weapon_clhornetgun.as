/* 
* The original Half-Life version of the Hornet Gun
* Modified for the Crack-Life Sven Co-op conversion
*
* Original Crack-Life mod by: Siemka321
* Sven Co-op Re-conversion: Rafael "R4to0" Alves
*/

// Hornet projectile
#include "proj_hornet"

namespace CLHORNETGUN
{

enum hgun_e
{
	HGUN_IDLE1 = 0,
	HGUN_FIDGETSWAY,
	HGUN_FIDGETSHAKE,
	HGUN_DOWN,
	HGUN_UP,
	HGUN_SHOOT
};

// Models
const string g_PeeMdl		=  g_bCrackLifeMode ? "models/cracklife/p_hgun.mdl" : "models/clcampaign/p_hgun.mdl";
const string g_VeeMdl		=  g_bCrackLifeMode ? "models/cracklife/v_hgun.mdl" : "models/clcampaign/v_hgun.mdl";
const string g_WeeMdl		=  g_bCrackLifeMode ? "models/cracklife/w_hgun.mdl" : "models/clcampaign/w_hgun.mdl";

// Sounds
const string g_Fire1Snd		= "cracklife/agrunt/ag_fire1.wav";
const string g_Fire2Snd		= "cracklife/agrunt/ag_fire1.wav"; //ag_fire2.wav
const string g_Fire3Snd		= "cracklife/agrunt/ag_fire1.wav"; //ag_fire3.wav

// Weapon Info
const uint g_DefGivePri		= 8;
const uint g_MaxAmmoPri		= 8;
const uint g_Weight			= 10;
const string g_WeaponName	= "weapon_clhornetgun";

// Weapon HUD
uint g_Slot					= 3;
uint g_Position				= 4;

// Fire rate delay
const float g_FRDelay = g_bCrackLifeMode ? 0.25f : 0.1f;
const float g_RLDelay = g_bCrackLifeMode ? 0.5f : 0.15f;

class weapon_clhornetgun : ScriptBasePlayerWeaponEntity
{
	int m_iFirePhase;
	float m_flRechargeTime;
	float m_flTimeWeaponIdle;

	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	bool IsUseable()
	{
		return true;
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, g_WeeMdl );

		self.m_iDefaultAmmo = g_DefGivePri;

		m_iFirePhase = 0;

		self.FallInit();
	}

	void Precache()
	{
		// Models
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( g_VeeMdl );
		g_Game.PrecacheModel( g_WeeMdl );
		g_Game.PrecacheModel( g_PeeMdl );

		// Sounds
		g_SoundSystem.PrecacheSound( g_Fire1Snd );
		g_SoundSystem.PrecacheSound( g_Fire2Snd );
		g_SoundSystem.PrecacheSound( g_Fire3Snd );

		// Precache hornet projectile
		g_Game.PrecacheOther( "clhornet" );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) == true )
		{
			@m_pPlayer = pPlayer;

			NetworkMessage clhornetgun( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			clhornetgun.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
			clhornetgun.End();
			return true;
		}

		return false;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= g_MaxAmmoPri;
		info.iMaxAmmo2	= -1;
		info.iMaxClip 	= -1;
		info.iSlot 		= g_Slot;
		info.iPosition 	= g_Position;
		info.iFlags		= ITEM_FLAG_SELECTONEMPTY; // select even if is empty
		info.iId		= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight 	= g_Weight;

		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( g_VeeMdl, g_PeeMdl, HGUN_UP, "hive" );
	}

	void Holster( int skipLocal = 0 )
	{
        //m_pPlayer.m_flNextAttack = g_Engine.time + g_RLDelay; // 0.5
		SetThink( null );
		BaseClass.Holster( skipLocal );

		self.SendWeaponAnim( HGUN_DOWN );

		// !!!HACKHACK - can't select hornetgun if it's empty! no way to get ammo for it, either.
		//if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
		//	m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
	}

	void PrimaryAttack()
	{
		self.Reload();

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		//Math.MakeAngles( m_pPlayer.pev.v_angle );

		// Shoot the hornet
		CBaseEntity@ pHornet = g_EntityFuncs.Create( "clhornet", m_pPlayer.GetGunPosition() + g_Engine.v_forward * 16 + g_Engine.v_right * 8 + g_Engine.v_up * -12, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );
		pHornet.pev.velocity = g_Engine.v_forward * 300;

		m_flRechargeTime = g_Engine.time + g_RLDelay; // 0.5

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

		// Fire sound
		switch ( Math.RandomLong ( 0 , 2 ) )
		{
			case 0:	g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Fire1Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
			case 1:	g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Fire2Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
			case 2:	g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Fire3Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
		}

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.m_flNextPrimaryAttack = g_Engine.time + g_FRDelay; // 0.25
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}
	
	void SecondaryAttack()
	{
		self.Reload();

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;


		//Wouldn't be a bad idea to completely predict these, since they fly so fast...
		//CBaseEntity@ pHornet;
		Vector vecSrc;

		//Math.MakeAngles( m_pPlayer.pev.v_angle );

		vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 16 + g_Engine.v_right * 8 + g_Engine.v_up * -12;

		m_iFirePhase++;
		switch ( m_iFirePhase )
		{
		case 1:
			vecSrc = vecSrc + g_Engine.v_up * 8;
			break;
		case 2:
			vecSrc = vecSrc + g_Engine.v_up * 8;
			vecSrc = vecSrc + g_Engine.v_right * 8;
			break;
		case 3:
			vecSrc = vecSrc + g_Engine.v_right * 8;
			break;
		case 4:
			vecSrc = vecSrc + g_Engine.v_up * -8;
			vecSrc = vecSrc + g_Engine.v_right * 8;
			break;
		case 5:
			vecSrc = vecSrc + g_Engine.v_up * -8;
			break;
		case 6:
			vecSrc = vecSrc + g_Engine.v_up * -8;
			vecSrc = vecSrc + g_Engine.v_right * -8;
			break;
		case 7:
			vecSrc = vecSrc + g_Engine.v_right * -8;
			break;
		case 8:
			vecSrc = vecSrc + g_Engine.v_up * 8;
			vecSrc = vecSrc + g_Engine.v_right * -8;
			m_iFirePhase = 0;
			break;
		}

		CBaseEntity@ cbeclhornet = g_EntityFuncs.Create( "clhornet", vecSrc, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );
		CLHORNET::clhornet@ pHornet = cast<CLHORNET::clhornet@>( CastToScriptClass( cbeclhornet ) );
		g_EntityFuncs.DispatchSpawn( pHornet.self.edict() );

		pHornet.pev.velocity = g_Engine.v_forward * 1200;
		pHornet.pev.angles = Math.VecToAngles( pHornet.pev.velocity );

		pHornet.SetThink( ThinkFunction( pHornet.StartDart ) );

		m_flRechargeTime = g_Engine.time + g_RLDelay; // 0.5

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

		// Fire sound
		switch ( Math.RandomLong ( 0 , 2 ) )
		{
			case 0:	g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Fire1Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
			case 1:	g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Fire2Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
			case 2:	g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Fire3Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
		}

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.1;
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType )>= g_MaxAmmoPri )
		return;

		while( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < g_MaxAmmoPri && m_flRechargeTime < g_Engine.time )
		{
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + 1 );
			m_flRechargeTime += 0.5;
		}
	}

	void WeaponIdle()
	{
		self.Reload();

		if( m_flTimeWeaponIdle > g_Engine.time )
			return;

		int iAnim;
		float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
		if (flRand <= 0.75)
		{
			iAnim = HGUN_IDLE1;
			m_flTimeWeaponIdle = g_Engine.time + 30.0 / 16 * (2);
		}
		else if (flRand <= 0.875)
		{
			iAnim = HGUN_FIDGETSWAY;
			m_flTimeWeaponIdle = g_Engine.time + 40.0 / 16.0;
		}
		else
		{
			iAnim = HGUN_FIDGETSHAKE;
			m_flTimeWeaponIdle = g_Engine.time + 35.0 / 16.0;
		}

		self.SendWeaponAnim( iAnim );
	}
}

void Register()
{
	CLHORNET::Register();
	g_CustomEntityFuncs.RegisterCustomEntity( "CLHORNETGUN::weapon_clhornetgun", g_WeaponName );
	g_ItemRegistry.RegisterWeapon( g_WeaponName, "cracklife", "Hornet" );
}

} // End of namespace