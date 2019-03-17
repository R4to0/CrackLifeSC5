/* 
* The original Half-Life version of the shotgun
* Modified by for the Crack-Life Sven Co-op conversion
*
* Original Crack-Life mod by: Siemka321
* Sven Co-op Re-conversion: Rafael "R4to0" Alves
*/

namespace CLSHOTGUN
{

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

// special deathmatch shotgun spreads
const Vector VECTOR_CONE_DM_SHOTGUN( 0.08716, 0.04362, 0.00  );		// 10 degrees by 5 degrees
const Vector VECTOR_CONE_DM_DOUBLESHOTGUN( 0.17365, 0.04362, 0.00 ); 	// 20 degrees by 5 degrees

// Models
const string g_PeeMdl = g_bCrackLifeMode ? "models/cracklife/p_shotgun.mdl" : "models/hlclassic/p_shotgun.mdl";
const string g_VeeMdl = g_bCrackLifeMode ? "models/cracklife/v_shotgun.mdl" : "models/clcampaign/v_shotgun.mdl";
const string g_WeeMdl = g_bCrackLifeMode ? "models/cracklife/w_shotgun.mdl" : "models/hlclassic/w_shotgun.mdl";
const string g_SShellMdl = "models/shotgunshell.mdl"; // shotgun shell
	
// Sounds
const string g_SngShotSnd = g_bCrackLifeMode ? "cracklife/weapons/sbarrel1.wav" : "clcampaign/weapons/sbarrel1.wav"; // Single shot
const string g_DblShotSnd = g_bCrackLifeMode ? "cracklife/weapons/dbarrel1.wav" : "clcampaign/weapons/dbarrel1.wav"; // Double shot
const string g_CockSnd = g_bCrackLifeMode ? "cracklife/weapons/scock1.wav" : "clcampaign/weapons/scock1.wav"; // cock gun
const string g_Rel1Snd = "cracklife/weapons/reload1.wav";
const string g_Rel2Snd = "cracklife/weapons/reload1.wav";
const string g_EmptySnd = "cracklife/weapons/357_cock1.wav"; // gun empty sound

// Sprites
const string g_ExploSpr = "sprites/zerogxplode.spr";

// Weapon Info
const uint g_DefGivePri		= 12;
const uint g_MaxAmmoPri		= g_bCrackLifeMode ? 125 : 200;
const uint g_MaxClip		= 8;
const uint g_Weight			= 15;
const string g_WeaponName	= "weapon_clshotgun";

// Weapon HUD
uint g_Slot			= 2;
uint g_Position		= 5;

const uint g_ShotPelDmg = int( g_EngineFuncs.CVarGetFloat( "sk_plr_buckshot" ) );

const uint SHOTGUN_SINGLE_PELLETCOUNT = 4;
const uint SHOTGUN_DOUBLE_PELLETCOUNT = SHOTGUN_SINGLE_PELLETCOUNT * 2;

class weapon_clshotgun : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	private float m_flNextReload;
	private uint m_iShell;
	private float m_flPumpTime;
	private bool m_bPlayPumpSound;
	private bool m_bShotgunReload;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, g_WeeMdl );

		self.m_iDefaultAmmo = g_DefGivePri;

		self.FallInit();// get ready to fall
	}

	void Precache()
	{
		// Models
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( g_VeeMdl );
		g_Game.PrecacheModel( g_WeeMdl );
		g_Game.PrecacheModel( g_PeeMdl );
		m_iShell = g_Game.PrecacheModel( g_SShellMdl );

		// Sounds     
		g_SoundSystem.PrecacheSound( g_DblShotSnd );	//shotgun
		g_SoundSystem.PrecacheSound( g_SngShotSnd );	//shotgun
		g_SoundSystem.PrecacheSound( g_Rel1Snd );	// shotgun reload
		g_SoundSystem.PrecacheSound( g_Rel2Snd );	// shotgun reload
		g_SoundSystem.PrecacheSound( g_EmptySnd ); // gun empty sound
		g_SoundSystem.PrecacheSound( g_CockSnd );	// cock gun

		// Sprites
		if( g_bCrackLifeMode )
			g_Game.PrecacheModel( g_ExploSpr );
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

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_EmptySnd, 0.8f, ATTN_NORM, 0, PITCH_NORM );
		}

		return false;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= g_MaxAmmoPri;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= g_MaxClip;
		info.iSlot 		= g_Slot;
		info.iPosition 	= g_Position;
		info.iId		= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight 	= g_Weight;

		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( g_VeeMdl ), self.GetP_Model( g_PeeMdl ), SHOTGUN_DRAW, "shotgun" );
	}

	void Holster( int skipLocal = 0 )
	{
		m_bShotgunReload = false;
		SetThink( null );
		BaseClass.Holster( skipLocal );
	}

	void ItemPostFrame()
	{
		if( m_flPumpTime != 0 && m_flPumpTime < g_Engine.time && m_bPlayPumpSound )
		{
			// play pumping sound
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, g_CockSnd, 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0,0x1f ) );

			m_bPlayPumpSound = false;
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

			if( tr.flFraction < 1.0f )
			{
				if( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

					if( pHit is null || pHit.IsBSPModel() )
					{
						// Decal
						g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );
					}

					if( g_bCrackLifeMode )
					{
							// Explosion
							NetworkMessage decexpl( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
								decexpl.WriteByte( TE_EXPLOSION );
								decexpl.WriteCoord( tr.vecEndPos.x );
								decexpl.WriteCoord( tr.vecEndPos.y );
								decexpl.WriteCoord( tr.vecEndPos.z );
								decexpl.WriteShort( g_EngineFuncs.ModelIndex( g_ExploSpr ) );
								decexpl.WriteByte( 5 ); // scale * 10
								decexpl.WriteByte( 15 ); // framerate
								decexpl.WriteByte( TE_EXPLFLAG_NOSOUND );
							decexpl.End();
					}
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
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75f;
			self.Reload();
			self.PlayEmptySound();
			return;
		}

		self.SendWeaponAnim( SHOTGUN_FIRE, 0, 0 );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_SngShotSnd, Math.RandomFloat( 0.95f, 1.0f ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0x1f ) );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		m_pPlayer.FireBullets( ( g_WeaponMode ? 4 : 6 ), vecSrc, vecAiming, ( g_WeaponMode ? VECTOR_CONE_DM_SHOTGUN : VECTOR_CONE_10DEGREES ), 2048, BULLET_PLAYER_BUCKSHOT, 0, g_ShotPelDmg );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		if( self.m_iClip != 0 )
			m_flPumpTime = g_Engine.time + 0.5f;

		m_pPlayer.pev.punchangle.x = -5.0f;

		self.m_flNextPrimaryAttack = g_Engine.time + 0.85f;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.85f;

		if( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;
		else
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75f;

		m_bShotgunReload = false;
		m_bPlayPumpSound = true;

		CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_DM_SHOTGUN, SHOTGUN_SINGLE_PELLETCOUNT );

	}

	void SecondaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			return;
		}

		if( self.m_iClip <= 1 )
		{
			self.Reload();
			self.PlayEmptySound();
			return;
		}
	
		self.SendWeaponAnim( SHOTGUN_FIRE2, 0, 0 );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_DblShotSnd, Math.RandomFloat( 0.98f, 1.0f ), ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		self.m_iClip -= 2;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		m_pPlayer.FireBullets( ( g_WeaponMode ? 8 : 12 ), vecSrc, vecAiming, ( g_WeaponMode ? VECTOR_CONE_DM_DOUBLESHOTGUN : VECTOR_CONE_10DEGREES ), 2048, BULLET_PLAYER_BUCKSHOT, 0, g_ShotPelDmg );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		if (self.m_iClip != 0)
			m_flPumpTime = g_Engine.time + 0.95f;

		self.m_flNextPrimaryAttack = g_Engine.time + 1.5f;
		self.m_flNextSecondaryAttack = g_Engine.time + 1.5f;
	
		if( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 6.0f;
		else
			self.m_flTimeWeaponIdle = g_Engine.time + 1.5f;
		
		m_pPlayer.pev.punchangle.x = -10.0f;

		m_bShotgunReload = false;
		m_bPlayPumpSound = true;
	
		CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_DM_DOUBLESHOTGUN, SHOTGUN_DOUBLE_PELLETCOUNT );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == g_MaxClip )
			return;

		if( m_flNextReload > g_Engine.time )
			return;

		// don't reload until recoil is done
		if( self.m_flNextPrimaryAttack > g_Engine.time && !m_bShotgunReload )
			return;

		// check to see if we're ready to reload
		if( !m_bShotgunReload )
		{
			self.SendWeaponAnim( SHOTGUN_START_RELOAD, 0, 0 );
			m_pPlayer.m_flNextAttack 		= 0.6f;	//Always uses a relative time due to prediction
			self.m_flTimeWeaponIdle			= g_Engine.time + 0.6f;
			self.m_flNextPrimaryAttack 		= g_Engine.time + 1.0f;
			self.m_flNextSecondaryAttack	= g_Engine.time + 1.0f;
			m_bShotgunReload = true;
			return;
		}
		else if( m_bShotgunReload )
		{
			if( self.m_flTimeWeaponIdle > g_Engine.time )
				return;

			if( self.m_iClip == g_MaxClip )
			{
				m_bShotgunReload = false;
				return;
			}

			self.SendWeaponAnim( SHOTGUN_RELOAD, 0 );
			m_flNextReload 					= g_Engine.time + 0.5f;
			self.m_flNextPrimaryAttack 		= g_Engine.time + 0.5f;
			self.m_flNextSecondaryAttack 	= g_Engine.time + 0.5f;
			self.m_flTimeWeaponIdle 		= g_Engine.time + 0.5f;
			
			// Add them to the clip
			self.m_iClip += 1;
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		
			switch( Math.RandomLong( 0, 1 ) )
			{
				case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, g_Rel1Snd, 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) ); break;
				case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, g_Rel2Snd, 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) ); break;
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
			if( self.m_iClip == 0 && !m_bShotgunReload && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )
			{
				self.Reload();
			}
			else if( m_bShotgunReload )
			{
				if( self.m_iClip != g_MaxClip && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
				{
					self.Reload();
				}
				else
				{
					// reload debounce has timed out
					self.SendWeaponAnim( SHOTGUN_PUMP, 0, 0 );

					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, g_CockSnd, 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0,0x1f ) );
					m_bShotgunReload = false;
					self.m_flTimeWeaponIdle = g_Engine.time + 1.5f;
				}
			}
			else
			{
				int iAnim;
				switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
				{
					case 0:
						iAnim = SHOTGUN_IDLE_DEEP;
						self.m_flTimeWeaponIdle = g_Engine.time + (60.0f/12.0f);
						break;

					case 1:
						iAnim = SHOTGUN_IDLE;
						self.m_flTimeWeaponIdle = g_Engine.time + (20.0f/9.0f);
						break;

					case 2:
						iAnim = SHOTGUN_IDLE4;
						self.m_flTimeWeaponIdle = g_Engine.time + (20.0f/9.0f);
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

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CLSHOTGUN::weapon_clshotgun", g_WeaponName );
	g_ItemRegistry.RegisterWeapon( g_WeaponName, "cracklife", "buckshot" );
}

} // End of namespace