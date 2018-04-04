/* 
* The original Half-Life version of the Hornet Gun
* https://github.com/ValveSoftware/halflife/blob/master/dlls/hornetgun.cpp
* Modified for the Crack-Life mod
*
* Author: Rafael "R4to0" Alves
*/

// Hornet projectile
#include "proj_hornet"

enum hgun_e {
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
	const string P_MDL = "models/hldm-br/cracklife/p_hgun_cl1.mdl";
	const string V_MDL = "models/hldm-br/cracklife/v_hgun_cl1.mdl";
	const string W_MDL = "models/hldm-br/cracklife/w_hgun_cl1.mdl";

	// Sounds
	const string S_FIRE1 = "hldm-br/cracklife/agrunt/ag_fire1.wav";
	const string S_FIRE2 = "hldm-br/cracklife/agrunt/ag_fire1.wav"; //ag_fire2.wav
	const string S_FIRE3 = "hldm-br/cracklife/agrunt/ag_fire1.wav"; //ag_fire3.wav

	// Weapon Info
	const uint DEFAULT_AMMO	= 8;
	const uint MAX_CARRY = 8;
	const uint WEIGHT = 10;

	// HUD Position
	const uint SLOT = 3;
	const uint POSITION = 4;

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
			g_EntityFuncs.SetModel( self, W_MDL );

			self.m_iDefaultAmmo = DEFAULT_AMMO;

			m_iFirePhase = 0;

			self.FallInit();
		}

		void Precache()
		{
			// Models
			self.PrecacheCustomModels();
			g_Game.PrecacheModel( V_MDL );
			g_Game.PrecacheModel( W_MDL );
			g_Game.PrecacheModel( P_MDL );

			// Sounds
			g_SoundSystem.PrecacheSound( S_FIRE1 );
			g_SoundSystem.PrecacheSound( S_FIRE2 );
			g_SoundSystem.PrecacheSound( S_FIRE3 );

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
			info.iMaxAmmo1 	= MAX_CARRY;
			info.iMaxAmmo2	= -1;
			info.iMaxClip 	= -1;
			info.iSlot 	= SLOT;
			info.iPosition 	= POSITION;
			info.iFlags	= ITEM_FLAG_SELECTONEMPTY; // select even if is empty
			info.iId	= g_ItemRegistry.GetIdForName( self.pev.classname );
			info.iWeight 	= WEIGHT;

			return true;
		}

		float WeaponTimeBase()
		{
			return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
		}

		bool Deploy()
		{
			return self.DefaultDeploy( V_MDL, P_MDL, HGUN_UP, "hive" );
		}

		void Holster( int skipLocal = 0 )
		{
			m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.5;

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
				case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, S_FIRE1, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
				case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, S_FIRE2, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
				case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, S_FIRE3, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
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
				case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, S_FIRE1, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
				case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, S_FIRE2, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
				case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, S_FIRE3, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.1;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
		}

		void Reload()
		{
			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType )>= MAX_CARRY )
			return;

			while( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < MAX_CARRY && m_flRechargeTime < g_Engine.time )
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
}