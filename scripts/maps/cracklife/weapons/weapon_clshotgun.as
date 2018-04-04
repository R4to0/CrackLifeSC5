/* 
* The original Half-Life version of the shotgun
* Modified for the Crack-Life shotgun weapon
*/

enum ShotgunAnimation
{
	SHOTGUN_IDLE = 0,
	SHOTGUN_FIRE,
	SHOTGUN_FIRE2,
	SHOTGUN_RELOAD,
	SHOTGUN_PUMP,
	SHOTGUN_START_RELOAD,
	SHOTGUN_DRAW,
	SHOTGUN_HOLSTER,
	SHOTGUN_IDLE4,
	SHOTGUN_IDLE_DEEP
};


namespace CLSHOTGUN
{

	// special deathmatch shotgun spreads
	const Vector VECTOR_CONE_DM_SHOTGUN( 0.08716, 0.04362, 0.00  );		// 10 degrees by 5 degrees
	const Vector VECTOR_CONE_DM_DOUBLESHOTGUN( 0.17365, 0.04362, 0.00 ); 	// 20 degrees by 5 degrees

	// Models
	const string P_MDL = "models/hldm-br/cracklife/p_shotgun_cl1.mdl"; // Thanks Tayklor <3
	const string V_MDL = "models/hldm-br/cracklife/v_shotgun_cl1.mdl";
	const string W_MDL = "models/hldm-br/cracklife/w_shotgun_cl1.mdl"; // Thanks Tayklor <3
	const string S_MDL = "models/shotgunshell.mdl"; // shotgun shell
	
	// Sounds
	const string S_SBA = "hldm-br/cracklife/weapons/sbarrel1_cl1.wav"; // Single shot
	const string S_DBA = "hldm-br/cracklife/weapons/dbarrel1_cl1.wav"; // Double shot
	const string S_COCK = "hldm-br/cracklife/weapons/scock1_cl1.wav"; // cock gun
	const string S_RE1 = "hldm-br/cracklife/weapons/reload1.wav";
	const string S_RE3 = "hldm-br/cracklife/weapons/reload1.wav";
	const string S_EMPTY = "hldm-br/cracklife/weapons/357_cock1.wav"; // gun empty sound

	// Weapon Info
	const uint DEFAULT_AMMO	= 12;
	const uint MAX_CARRY	= 125;
	const uint MAX_CLIP	= 8;
	const uint WEIGHT	= 15;

	// Weapon HUD
	const uint SLOT = 2;
	const uint POSITION = 5;

	const uint SHOTGUN_SINGLE_PELLETCOUNT = 4;
	const uint SHOTGUN_DOUBLE_PELLETCOUNT = SHOTGUN_SINGLE_PELLETCOUNT * 2;

	class weapon_clshotgun : ScriptBasePlayerWeaponEntity
	{
		private CBasePlayer@ m_pPlayer
		{
			get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
			set       	{ self.m_hPlayer = EHandle( @value ); }
		}

		float m_flNextReload;
		int m_iShell;
		float m_flPumpTime;
		bool m_fPlayPumpSound;
		bool m_fShotgunReload;

		void Spawn()
		{
			Precache();
			g_EntityFuncs.SetModel( self, W_MDL );

			self.m_iDefaultAmmo = DEFAULT_AMMO;

			self.FallInit();// get ready to fall
		}

		void Precache()
		{
			// Models
			self.PrecacheCustomModels();
			g_Game.PrecacheModel( V_MDL );
			g_Game.PrecacheModel( W_MDL );
			g_Game.PrecacheModel( P_MDL );
			m_iShell = g_Game.PrecacheModel( S_MDL );

			// Sounds     
			g_SoundSystem.PrecacheSound( S_DBA );	//shotgun
			g_SoundSystem.PrecacheSound( S_SBA );	//shotgun
			g_SoundSystem.PrecacheSound( S_RE1 );	// shotgun reload
			g_SoundSystem.PrecacheSound( S_RE3 );	// shotgun reload
			g_SoundSystem.PrecacheSound( S_EMPTY ); // gun empty sound
			g_SoundSystem.PrecacheSound( S_COCK );	// cock gun
		}

		bool AddToPlayer( CBasePlayer@ pPlayer )
		{
			if( BaseClass.AddToPlayer( pPlayer ) == true )
			{
				@m_pPlayer = pPlayer;
				NetworkMessage clshotgun( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				clshotgun.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
				clshotgun.End();
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

		bool GetItemInfo( ItemInfo& out info )
		{
			info.iMaxAmmo1 	= MAX_CARRY;
			info.iMaxAmmo2 	= -1;
			info.iMaxClip 	= MAX_CLIP;
			info.iSlot 	= SLOT;
			info.iPosition 	= POSITION;
			info.iId	= g_ItemRegistry.GetIdForName( self.pev.classname );
			info.iWeight 	= WEIGHT;

			return true;
		}

		bool Deploy()
		{
			return self.DefaultDeploy( self.GetV_Model( V_MDL ), self.GetP_Model( P_MDL ), SHOTGUN_DRAW, "shotgun" );
		}

		float WeaponTimeBase()
		{
			return g_Engine.time;
		}

		void Holster( int skipLocal = 0 )
		{
			m_fShotgunReload = false;

			BaseClass.Holster( skipLocal );
		}

		void ItemPostFrame()
		{
			if( m_flPumpTime != 0 && m_flPumpTime < g_Engine.time && m_fPlayPumpSound )
			{
				// play pumping sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, S_COCK, 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0,0x1f ) );

				m_fPlayPumpSound = false;
			}

		BaseClass.ItemPostFrame();
		}

		void CreatePelletDecals( const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount )
		{
			TraceResult tr;
		
			float x, y;
		
			for( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )
			{
				g_Utility.GetCircularGaussianSpread( x, y );

				Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;

				Vector vecEnd	= vecSrc + vecDir * 2048;

				g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

				if( tr.flFraction < 1.0 )
				{
					if( tr.pHit !is null )
					{
						CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

						if( pHit is null || pHit.IsBSPModel() )
							g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );
					}
				}
			}
		}

		void PrimaryAttack()
		{
			// don't fire underwater
			if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			{
				self.PlayEmptySound();
				self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
				return;
			}

			if( self.m_iClip <= 0 )
			{
				self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
				self.Reload();
				self.PlayEmptySound();
				return;
			}

			self.SendWeaponAnim( SHOTGUN_FIRE, 0, 0 );

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_SBA, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0x1f ) );

			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

			--self.m_iClip;

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			Vector vecSrc	 = m_pPlayer.GetGunPosition();
			Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

			m_pPlayer.FireBullets( 4, vecSrc, vecAiming, VECTOR_CONE_DM_SHOTGUN, 2048, BULLET_PLAYER_BUCKSHOT, 0 );

			if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
				// HEV suit - indicate out of ammo condition
				m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

			if( self.m_iClip != 0 )
				m_flPumpTime = g_Engine.time + 0.5;

			m_pPlayer.pev.punchangle.x = -5.0;

			self.m_flNextPrimaryAttack = g_Engine.time + 0.85;
			self.m_flNextSecondaryAttack = g_Engine.time + 0.85;

			if( self.m_iClip != 0 )
				self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
			else
				self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;

			m_fShotgunReload = false;
			m_fPlayPumpSound = true;

			CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_DM_SHOTGUN, SHOTGUN_SINGLE_PELLETCOUNT );

		}

		void SecondaryAttack()
		{
			// don't fire underwater
			if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			{
				self.PlayEmptySound();
				self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
				return;
			}

			if( self.m_iClip <= 1 )
			{
				self.Reload();
				self.PlayEmptySound();
				return;
			}
		
			self.SendWeaponAnim( SHOTGUN_FIRE2, 0, 0 );

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_DBA, Math.RandomFloat( 0.98, 1.0 ), ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );

			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

			self.m_iClip -= 2;

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			Vector vecSrc	 = m_pPlayer.GetGunPosition();
			Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

			m_pPlayer.FireBullets( 8, vecSrc, vecAiming, VECTOR_CONE_DM_DOUBLESHOTGUN, 2048, BULLET_PLAYER_BUCKSHOT, 0 );

			if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
				// HEV suit - indicate out of ammo condition
				m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

			if (self.m_iClip != 0)
				m_flPumpTime = g_Engine.time + 0.95;

			self.m_flNextPrimaryAttack = g_Engine.time + 1.5;
			self.m_flNextSecondaryAttack = g_Engine.time + 1.5;
		
			if( self.m_iClip != 0 )
				self.m_flTimeWeaponIdle = g_Engine.time + 6.0;
			else
				self.m_flTimeWeaponIdle = g_Engine.time + 1.5;
			
			m_pPlayer.pev.punchangle.x = -10.0;

			m_fShotgunReload = false;
			m_fPlayPumpSound = true;
		
			CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_DM_DOUBLESHOTGUN, SHOTGUN_DOUBLE_PELLETCOUNT );
		}

		// TODO
		/*void ExplodeThink()
		{
			TraceResult tr;
			float x, y;
			g_Utility.GetCircularGaussianSpread( x, y );
			Vector vecDir = vecAiming + x * VECTOR_CONE_DM_SHOTGUN.x * g_Engine.v_right + y * VECTOR_CONE_DM_SHOTGUN.y * g_Engine.v_up;
			Vector vecEnd	= vecSrc + vecDir * 4096;
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
			NetworkMessage exp_msg( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, null );
			exp_msg.WriteByte( TE_EXPLOSION ); //MSG type enum
			exp_msg.WriteCoord( tr.vecEndPos.x ); //pos
			exp_msg.WriteCoord( tr.vecEndPos.y ); //pos
			exp_msg.WriteCoord( tr.vecEndPos.z ); //pos
			exp_msg.WriteShort( g_EngineFuncs.ModelIndex( "sprites/zerogxplode.spr" ) );
			exp_msg.WriteByte( 5 ); //scale
			exp_msg.WriteByte( 15 ); //framerate
			exp_msg.WriteByte( TE_EXPLFLAG_NOSOUND ); //flag
			exp_msg.End();
		}*/

		void Reload()
		{
			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == MAX_CLIP )
				return;

			if( m_flNextReload > g_Engine.time )
				return;

			// don't reload until recoil is done
			if( self.m_flNextPrimaryAttack > g_Engine.time && !m_fShotgunReload )
				return;

			// check to see if we're ready to reload
			if( !m_fShotgunReload )
			{
				self.SendWeaponAnim( SHOTGUN_START_RELOAD, 0, 0 );
				m_pPlayer.m_flNextAttack 	= 0.6;	//Always uses a relative time due to prediction
				self.m_flTimeWeaponIdle			= g_Engine.time + 0.6;
				self.m_flNextPrimaryAttack 		= g_Engine.time + 1.0;
				self.m_flNextSecondaryAttack	= g_Engine.time + 1.0;
				m_fShotgunReload = true;
				return;
			}
			else if( m_fShotgunReload )
			{
				if( self.m_flTimeWeaponIdle > g_Engine.time )
					return;

				if( self.m_iClip == MAX_CLIP )
				{
					m_fShotgunReload = false;
					return;
				}

				self.SendWeaponAnim( SHOTGUN_RELOAD, 0 );
				m_flNextReload 					= g_Engine.time + 0.5;
				self.m_flNextPrimaryAttack 		= g_Engine.time + 0.5;
				self.m_flNextSecondaryAttack 	= g_Engine.time + 0.5;
				self.m_flTimeWeaponIdle 		= g_Engine.time + 0.5;
				
				// Add them to the clip
				self.m_iClip += 1;
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
			
				switch( Math.RandomLong( 0, 1 ) )
				{
					case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, S_RE1, 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) ); break;
					case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, S_RE3, 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) ); break;
				}
			}

			BaseClass.Reload();
		}

		void WeaponIdle()
		{
		
			self.ResetEmptySound();

			m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

			if( self.m_flTimeWeaponIdle < g_Engine.time )
			{
				if( self.m_iClip == 0 && !m_fShotgunReload && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )
				{
					self.Reload();
				}
				else if( m_fShotgunReload )
				{
					if( self.m_iClip != MAX_CLIP && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
					{
						self.Reload();
					}
					else
					{
						// reload debounce has timed out
						self.SendWeaponAnim( SHOTGUN_PUMP, 0, 0 );

						g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, S_COCK, 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0,0x1f ) );
						m_fShotgunReload = false;
						self.m_flTimeWeaponIdle = g_Engine.time + 1.5;
					}
				}
				else
				{
					int iAnim;
					switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
					{
						case 0:
							iAnim = SHOTGUN_IDLE_DEEP;
							self.m_flTimeWeaponIdle = WeaponTimeBase() + (60.0/12.0);
							break;

						case 1:
							iAnim = SHOTGUN_IDLE;
							self.m_flTimeWeaponIdle = WeaponTimeBase() + (20.0/9.0);
							break;

						case 2:
							iAnim = SHOTGUN_IDLE4;
							self.m_flTimeWeaponIdle = WeaponTimeBase() + (20.0/9.0);
							break;
					}
					/*float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
					if( flRand <= 0.8 )
					{
						iAnim = SHOTGUN_IDLE_DEEP;
						self.m_flTimeWeaponIdle = g_Engine.time + (60.0/12.0); // * RANDOM_LONG(2, 5);
					}
					else if( flRand <= 0.95 )
					{
						iAnim = SHOTGUN_IDLE;
						self.m_flTimeWeaponIdle = g_Engine.time + (20.0/9.0);
					}
					else
					{
						iAnim = SHOTGUN_IDLE4;
						self.m_flTimeWeaponIdle = g_Engine.time + (20.0/9.0);
					}*/
					self.SendWeaponAnim( iAnim, 0, 0 );
				}
			}
		}
	}

	string GetName()
	{
	return "weapon_clshotgun";
	}

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity( "CLSHOTGUN::weapon_clshotgun", GetName() );
		g_ItemRegistry.RegisterWeapon( GetName(), "hldm-br/cracklife", "buckshot" );
	}
}

