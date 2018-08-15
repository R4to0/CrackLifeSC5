/* 
* The original Half-Life version of the Hornet Gun
* Modified for the Crack-Life Sven Co-op conversion
*
* Original Crack-Life mod by: Siemka321
* Sven Co-op Re-conversion: Rafael "R4to0" Alves
*/

// Hornet projectile
#include "proj_hornet"

enum hgun_e
{
	HGUN_IDLE1 = 0,
	HGUN_FIDGETSWAY,
	HGUN_FIDGETSHAKE,
	HGUN_DOWN,
	HGUN_UP,
	HGUN_SHOOT
};

namespace CLHORNETGUN
{

// Models
const string strPeeMdl		= "models/hldm-br/cracklife/p_hgun_cl1.mdl";
const string strVeeMdl		= "models/hldm-br/cracklife/v_hgun_cl1.mdl";
const string strWeeMdl		= "models/hldm-br/cracklife/w_hgun_cl1.mdl";

// Sounds
const string strFire1Snd	= "hldm-br/cracklife/agrunt/ag_fire1.wav";
const string strFire2Snd	= "hldm-br/cracklife/agrunt/ag_fire1.wav"; //ag_fire2.wav
const string strFire3Snd	= "hldm-br/cracklife/agrunt/ag_fire1.wav"; //ag_fire3.wav

// Weapon Info
const uint iDefaultGive		= 8;
const uint iMaxCarry		= 8;
const uint iWeight			= 10;

// Weapon HUD
const uint iSlot			= 3;
const uint iPosition		= 4;

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
		g_EntityFuncs.SetModel( self, strWeeMdl );

		self.m_iDefaultAmmo = iDefaultGive;

		m_iFirePhase = 0;

		self.FallInit();
	}

	void Precache()
	{
		// Models
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( strVeeMdl );
		g_Game.PrecacheModel( strWeeMdl );
		g_Game.PrecacheModel( strPeeMdl );

		// Sounds
		g_SoundSystem.PrecacheSound( strFire1Snd );
		g_SoundSystem.PrecacheSound( strFire2Snd );
		g_SoundSystem.PrecacheSound( strFire3Snd );

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
		info.iMaxAmmo1 	= iMaxCarry;
		info.iMaxAmmo2	= -1;
		info.iMaxClip 	= -1;
		info.iSlot 		= iSlot;
		info.iPosition 	= iPosition;
		info.iFlags		= ITEM_FLAG_SELECTONEMPTY; // select even if is empty
		info.iId		= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight 	= iWeight;

		return true;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	bool Deploy()
	{
		return self.DefaultDeploy( strVeeMdl, strPeeMdl, HGUN_UP, "hive" );
	}

	void Holster( int skipLocal = 0 )
	{
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

		m_flRechargeTime = g_Engine.time + 0.5;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

		// Fire sound
		switch ( Math.RandomLong ( 0 , 2 ) )
		{
			case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, strFire1Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
			case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, strFire2Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
			case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, strFire3Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
		}

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.m_flNextPrimaryAttack = g_Engine.time + 0.25;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
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

		CBaseEntity@ pHornet = g_EntityFuncs.Create( "clhornet", vecSrc, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );
		pHornet.pev.velocity = g_Engine.v_forward * 1200;
		pHornet.pev.angles = Math.VecToAngles( pHornet.pev.velocity );

		//pHornet.SetThink( ThinkFunction( StartDart ) );
		//SetThink( ThinkFunction( pHornet.StartDart ) );

		m_flRechargeTime = g_Engine.time + 0.5;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

		// Fire sound
		switch ( Math.RandomLong ( 0 , 2 ) )
		{
			case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, strFire1Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
			case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, strFire2Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
			case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, strFire3Snd, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
		}

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.1;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType )>= iMaxCarry )
		return;

		while( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < iMaxCarry && m_flRechargeTime < g_Engine.time )
		{
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + 1 );
			m_flRechargeTime += 0.5;
		}
	}

	void WeaponIdle()
	{
		self.Reload();

		if( m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;
		float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
		if (flRand <= 0.75)
		{
			iAnim = HGUN_IDLE1;
			m_flTimeWeaponIdle = WeaponTimeBase() + 30.0 / 16 * (2);
		}
		else if (flRand <= 0.875)
		{
			iAnim = HGUN_FIDGETSWAY;
			m_flTimeWeaponIdle = WeaponTimeBase() + 40.0 / 16.0;
		}
		else
		{
			iAnim = HGUN_FIDGETSHAKE;
			m_flTimeWeaponIdle = WeaponTimeBase() + 35.0 / 16.0;
		}

		self.SendWeaponAnim( iAnim );
	}
}

string GetName()
{
	return "weapon_clhornetgun";
}

void Register()
{
	CLHORNET::Register();
	g_CustomEntityFuncs.RegisterCustomEntity( "CLHORNETGUN::weapon_clhornetgun", GetName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "hldm-br/cracklife", "Hornet" );
}

} // End of namespace