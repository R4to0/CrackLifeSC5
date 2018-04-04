/*  
* The original Half-Life version of the Glock
* https://github.com/ValveSoftware/halflife/blob/master/dlls/glock.cpp
*
* Modified for the Crack-Life "Penis" Gun
*
* Author: Rafael "R4to0" Alves
*/

enum CLGlock_e
{
	CLGLRELOAD,
	CLGLDRAW,
	CLGLIDLE = 2,
	CLGLFIRE,
	CLGLHOLSTER
};

namespace CLGLOCK
{
	// Models
	const string P_MDL = "models/hldm-br/cracklife/p_9mmhandgun_v2.mdl"; //Thanks Tayklor
	const string V_MDL = "models/hldm-br/cracklife/v_9mmhandgun.mdl";
	const string W_MDL = "models/hldm-br/cracklife/w_9mmhandgun.mdl";

	// Sounds
	const string S_FIRE = "hldm-br/cracklife/debris/beamstart1.wav"; //PINGLES!
	const string S_EMPTY = "hldm-br/cracklife/weapons/357_cock1.wav"; //NO!

	// Weapon Info
	const uint MAX_AMMO = 999;
	const uint MAX_CLIP = 17;
	const uint WEIGHT = 10;

	// HUD Position
	const uint SLOT = 1;
	const uint POSITION = 4;


	class weapon_clglock : ScriptBasePlayerWeaponEntity
	{
		private CBasePlayer@ m_pPlayer
		{
			get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
			set       	{ self.m_hPlayer = EHandle( @value ); }
		}

		void Spawn()
		{
			Precache();
			g_EntityFuncs.SetModel( self, W_MDL );
			self.m_iDefaultAmmo = MAX_CLIP;
			self.FallInit();
		}

		void Precache()
		{
			self.PrecacheCustomModels();

			g_Game.PrecacheModel( P_MDL );
			g_Game.PrecacheModel( V_MDL );
			g_Game.PrecacheModel( W_MDL );

			g_SoundSystem.PrecacheSound( S_FIRE );
			g_SoundSystem.PrecacheSound( S_EMPTY );
		}

		bool GetItemInfo( ItemInfo& out info )
		{
			info.iMaxAmmo1 	= MAX_AMMO;
			info.iMaxAmmo2	= -1;
			info.iMaxClip 	= MAX_CLIP;
			info.iSlot 	= SLOT;
			info.iPosition 	= POSITION;
			info.iId	= g_ItemRegistry.GetIdForName( self.pev.classname );
			info.iWeight 	= WEIGHT;

			return true;
		}

		bool AddToPlayer( CBasePlayer@ pPlayer )
		{
			if( BaseClass.AddToPlayer( pPlayer ) == true )
			{
				@m_pPlayer = pPlayer;
				NetworkMessage clglock( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				clglock.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
				clglock.End();
				return true;
			}

			return false;
		}

		float WeaponTimeBase()
		{
			return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
		}

		bool Deploy()
		{
			return self.DefaultDeploy( V_MDL, P_MDL, CLGLDRAW, "onehanded" );
		}

		void Holster( int skipLocal = 0 )
		{
			self.m_fInReload = false; // cancel any reload in progress.
			m_pPlayer.m_flNextAttack = 1.0;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
		}

		void SecondaryAttack()
		{
			GlockFire( 0.1, 0.2 );
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.2;
		}

		void PrimaryAttack()
		{
			GlockFire( 0.01, 0.3 );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.3;
		}

		void GlockFire( float flSpread , float flCycleTime)
		{
			if( self.m_iClip <= 0 )
			{
				//self.PlayEmptySound();
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_EMPTY, Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.2f;

				return;
			}

			--self.m_iClip;

			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			self.SendWeaponAnim( CLGLFIRE, 0, 0 );

			// Fire sound
			m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_FIRE, Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

			Vector vecSrc	 = m_pPlayer.GetGunPosition();
			Vector vecAiming = g_Engine.v_forward;

			m_pPlayer.FireBullets( 1, vecSrc, vecAiming, Vector( flSpread, flSpread, flSpread ), 8192, BULLET_PLAYER_9MM, 0 );

			if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
				// HEV suit - indicate out of ammo condition
				m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
		
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

			// Decal shit
			TraceResult tr;
			float x, y;
			g_Utility.GetCircularGaussianSpread( x, y );
			Vector vecDir = vecAiming + x * flSpread * g_Engine.v_right + y * flSpread  * g_Engine.v_up;
			Vector vecEnd = vecSrc + vecDir * 4096;
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

			if( tr.flFraction < 1.0 )
			{
				if( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
					if( pHit is null || pHit.IsBSPModel() )
						g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_9MM );
				}
			}
		}

		void Reload()
		{
			self.DefaultReload( MAX_CLIP, CLGLRELOAD, 2.6, 0 );
			BaseClass.Reload();
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
		}

		void WeaponIdle()
		{
			self.ResetEmptySound();

			if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
				return;

			int iAnim = CLGLIDLE;

			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 60, 16 );
			self.SendWeaponAnim( iAnim );
		}
	}

	string GetName()
	{
		return "weapon_clglock";
	}

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity( "CLGLOCK::weapon_clglock", GetName() );
		g_ItemRegistry.RegisterWeapon( GetName(), "hldm-br/cracklife", "9mm" );
	}
}

