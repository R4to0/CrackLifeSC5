/**
 * The original Half-Life version of the mp5
 * Modified for the Crack-Life MP5 fast gun
 */

enum Mp5Animation
{
	MP5_LONGIDLE = 0,
	MP5_IDLE1,
	MP5_LAUNCH,
	MP5_RELOAD,
	MP5_DEPLOY,
	MP5_FIRE1,
	MP5_FIRE2,
	MP5_FIRE3,
};

namespace CLMP5
{
	// Let's Crack-Life this -R4to0
	const uint DEFAULT_GIVE 	= 999; // not
	const uint MAX_AMMO		= 999; // sure
	const uint MAX_AMMO2 		= 999; // about
	const uint MAX_CLIP 		= 999; // this
	const uint WEIGHT 		= 5;
	const uint DAMAGE		= 2; // default: 2
	const uint AMMO_M203BOX_GIVE	= 200; // default: 2

	// Weapon Info
	const uint SLOT			= 2;
	const uint POSITION		= 4;
	const string AMMO_TYPE		= "cl_9mm"; //Default: 9mm
	const string SEC_AMMO_TYPE	= "cl_ARgrenades"; //Default: ARgrenades

	// Models
	const string P_MDL = "models/hlclassic/p_9mmAR.mdl"; // SC HL1 "classic mode" model
	const string V_MDL = "models/hldm-br/cracklife/v_9mmar_v2.mdl"; // v2: Edited reload events
        const string W_MDL = "models/hlclassic/w_9mmAR.mdl"; // SC HL1 "classic mode" model
	const string S_MDL = "models/shell.mdl"; // Shell
	const string G_MDL = "models/grenade.mdl"; // Grenade
	const string R_MDL = "models/w_ARgrenade.mdl"; // Grenade
	const string C_MDL = "models/w_9mmARclip.mdl"; // Ammo

	// Sounds
	const string S_CINS = "hlclassic/items/clipinsert1.wav"; // Played by v2 model
	const string S_CREL = "hlclassic/items/cliprelease1.wav"; // Played by v2 model
	const string S_FIRE1 = "hlclassic/weapons/hks1.wav";
	const string S_FIRE2 = "hlclassic/weapons/hks2.wav";
	const string S_FIRE3 = "hlclassic/weapons/hks3.wav";
	const string S_GL1 = "hlclassic/weapons/glauncher.wav";
	const string S_GL2 = "hlclassic/weapons/glauncher2.wav";
	const string S_EMPTY = "hldm-br/cracklife/weapons/357_cock1.wav";
	const string S_AMMO = "items/9mmclip1.wav";

	class weapon_clmp5 : ScriptBasePlayerWeaponEntity
	{
		private CBasePlayer@ m_pPlayer
		{
			get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
			set       	{ self.m_hPlayer = EHandle( @value ); }
		}
	
		int m_iShell;
		int m_iSecondaryAmmo;
	
		void Spawn()
		{
			Precache();
			g_EntityFuncs.SetModel( self, W_MDL );

			self.m_iDefaultAmmo = DEFAULT_GIVE;

			self.m_iSecondaryAmmoType = 0;
			self.FallInit();
		}

		void Precache()
		{
			// Models
			self.PrecacheCustomModels();
			g_Game.PrecacheModel( V_MDL );
			g_Game.PrecacheModel( W_MDL );
			g_Game.PrecacheModel( P_MDL );
			m_iShell = g_Game.PrecacheModel( S_MDL );
			g_Game.PrecacheModel( G_MDL );

			// Sounds
			g_SoundSystem.PrecacheSound( S_CINS );
			g_SoundSystem.PrecacheSound( S_CREL );
			g_SoundSystem.PrecacheSound( S_FIRE1 );
			g_SoundSystem.PrecacheSound( S_FIRE2 );
			g_SoundSystem.PrecacheSound( S_FIRE3 );
			g_SoundSystem.PrecacheSound( S_GL1 );
			g_SoundSystem.PrecacheSound( S_GL2 );
			g_SoundSystem.PrecacheSound( S_EMPTY );
		}

		bool GetItemInfo( ItemInfo& out info )
		{
			info.iMaxAmmo1 	= MAX_AMMO;
			info.iMaxAmmo2 	= MAX_AMMO2;
			info.iMaxClip 	= MAX_CLIP;
			info.iSlot	= SLOT;
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
				NetworkMessage clmp5( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				clmp5.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
				clmp5.End();

			return true;
			}

			return false;
		}
	
		bool PlayEmptySound()
		{
			if( self.m_bPlayEmptySound )
			{
				self.m_bPlayEmptySound = false;
			
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_EMPTY, 0.8, ATTN_NORM, 0, PITCH_NORM );
			}
		
		return false;
		}

		bool Deploy()
		{
			return self.DefaultDeploy( self.GetV_Model( V_MDL ), self.GetP_Model( P_MDL ), MP5_DEPLOY, "mp5" );
		}
	
		float WeaponTimeBase()
		{
			return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
		}

		void PrimaryAttack()
		{
			// don't fire underwater
			if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			{
				self.PlayEmptySound( );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.15;
				return;
			}

			if( self.m_iClip <= 0 )
			{
				self.PlayEmptySound();
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
				return;
			}

			m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

			--self.m_iClip;

			// Fire anim
			switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
			{
				case 0: self.SendWeaponAnim( MP5_FIRE1, 0, 0 ); break;
				case 1: self.SendWeaponAnim( MP5_FIRE2, 0, 0 ); break;
				case 2: self.SendWeaponAnim( MP5_FIRE3, 0, 0 ); break;
			}

			// Fire sound
			switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
			{
				case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_FIRE1, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) ); break;
				case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_FIRE2, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) ); break;
				case 2: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_FIRE3, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) ); break;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			Vector vecSrc	 = m_pPlayer.GetGunPosition();
			Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
			// optimized multiplayer. Widened to make it easier to hit a moving player
			m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_MP5, 2, DAMAGE );

			if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
				// HEV suit - indicate out of ammo condition
				m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

			m_pPlayer.pev.punchangle.x = Math.RandomLong( -2, 2 );

			self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.01; // changed here
			if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.01; // changed here

			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

			TraceResult tr;
			float x, y;
			g_Utility.GetCircularGaussianSpread( x, y );
			Vector vecDir = vecAiming + x * VECTOR_CONE_6DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_6DEGREES.y * g_Engine.v_up;
			Vector vecEnd	= vecSrc + vecDir * 4096;
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

			if( tr.flFraction < 1.0 )
			{
				if( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
					if( pHit is null || pHit.IsBSPModel() )
						g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
				}
			}
		}

		void SecondaryAttack()
		{
			// don't fire underwater
			if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			{
				self.PlayEmptySound();
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
				return;
			}

			if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
			{
				self.PlayEmptySound();
				return;
			}

			m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

			m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
			m_pPlayer.m_flStopExtraSoundTime = WeaponTimeBase() + 0.2;

			m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

			m_pPlayer.pev.punchangle.x = -10.0;

			self.SendWeaponAnim( MP5_LAUNCH );

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			if ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) != 0 )
			{
			// play this sound through BODY channel so we can hear it if player didn't stop firing MP5
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_GL1, 0.8, ATTN_NORM, 0, PITCH_NORM );
			}
			else
			{
				// play this sound through BODY channel so we can hear it if player didn't stop firing MP5
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_GL2, 0.8, ATTN_NORM, 0, PITCH_NORM );
			}

			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

			// we don't add in player velocity anymore.
			if( ( m_pPlayer.pev.button & IN_DUCK ) != 0 )
			{
				g_EntityFuncs.ShootContact( m_pPlayer.pev, m_pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_right * 6, g_Engine.v_forward * 900 ); //800
			}
			else
			{
				g_EntityFuncs.ShootContact( m_pPlayer.pev, m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs * 0.5 + g_Engine.v_forward * 16 + g_Engine.v_right * 6, g_Engine.v_forward * 900 ); //800
			}

			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.1; // changed here
			self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.1; // changed here
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 5;// idle pretty soon after shooting.

			if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
				// HEV suit - indicate out of ammo condition
				m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
		}

		void Reload()
		{
			self.DefaultReload( MAX_CLIP, MP5_RELOAD, 1.5, 0 );

			//Set 3rd person reloading animation -Sniper
			BaseClass.Reload();
		}

		void WeaponIdle()
		{
			self.ResetEmptySound();

			m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

			if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
				return;

			int iAnim;
			switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) )
			{
				case 0:	iAnim = MP5_LONGIDLE; break;
				case 1: iAnim = MP5_IDLE1; break;
				default: iAnim = MP5_IDLE1; break;
			}

			self.SendWeaponAnim( iAnim );

			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );// how long till we do this again.
		}
	}

	/**
	 * Custom 9mm ammo entity
	 */
	class AmmoClip : ScriptBasePlayerAmmoEntity
	{
		void Spawn()
		{ 
			Precache();
			g_EntityFuncs.SetModel( self, C_MDL );
			BaseClass.Spawn();
		}

		void Precache()
		{
			g_Game.PrecacheModel( C_MDL );
			g_SoundSystem.PrecacheSound( S_AMMO );
		}

		bool AddAmmo( CBaseEntity@ pOther )
		{ 
			if( pOther.GiveAmmo( MAX_CLIP, AMMO_TYPE, MAX_CLIP ) != -1 )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, S_AMMO, 1, ATTN_NORM );
				return true;
			}
			return false;
		}
	}

	/**
	 * Custom grenade ammo entity
	 */
	class AmmoGrenade : ScriptBasePlayerAmmoEntity
	{
		void Spawn()
		{
			Precache();
			g_EntityFuncs.SetModel( self, R_MDL );
			BaseClass.Spawn();
		}
		void Precache()
		{
			g_Game.PrecacheModel( R_MDL );
			g_SoundSystem.PrecacheSound( S_AMMO );
		}
		bool AddAmmo( CBaseEntity@ pOther ) 
		{
			if( pOther.GiveAmmo( AMMO_M203BOX_GIVE, SEC_AMMO_TYPE, MAX_AMMO2 ) != -1 )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, S_AMMO, 1, ATTN_NORM );
				return true;
			}
			return false;
		}
	}

	string GetAmmoName()
	{
		return "ammo_clmp5";
	}

	string GetSecAmmoName()
	{
		return "ammo_clmp5grenades";
	}

	string GetName()
	{
		return "weapon_clmp5";
	}

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity( "CLMP5::weapon_clmp5", GetName() );
		g_ItemRegistry.RegisterWeapon( GetName(), "hldm-br/cracklife", AMMO_TYPE, SEC_AMMO_TYPE );
		g_CustomEntityFuncs.RegisterCustomEntity( "CLMP5::AmmoClip", GetAmmoName() );
		g_CustomEntityFuncs.RegisterCustomEntity( "CLMP5::AmmoGrenade", GetSecAmmoName() );
	}
}

