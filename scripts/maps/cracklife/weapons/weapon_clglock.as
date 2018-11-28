/*  
* The original Half-Life version of the Glock
* Modified for the Crack-Life Sven Co-op conversion
*
* Original Crack-Life mod by: Siemka321
* Sven Co-op Re-conversion: Rafael "R4to0" Alves
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
const string strPeeMdl		= "models/cracklife/p_9mmhandgun.mdl"; //Thanks Tayklor
const string strVeeMdl		= "models/cracklife/v_9mmhandgun.mdl";
const string strWeeMdl		= "models/cracklife/w_9mmhandgun.mdl";

// Sounds
const string strFireSnd		= "cracklife/debris/beamstart1.wav"; //PINGLES!
const string strEmptySnd	= "cracklife/weapons/357_cock1.wav"; //NO!

// Weapon Info
const uint iMaxCarry		= 999;
const uint iMaxClip			= 17;
const uint iWeight			= 10;

// Weapon HUD
const uint iSlot			= 1;
const uint iPosition		= 4;

const uint iDamage = int( g_EngineFuncs.CVarGetFloat( "sk_plr_9mm_bullet" ) );


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
		g_EntityFuncs.SetModel( self, strWeeMdl );
		self.m_iDefaultAmmo = iMaxClip;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( strPeeMdl );
		g_Game.PrecacheModel( strVeeMdl );
		g_Game.PrecacheModel( strWeeMdl );

		g_SoundSystem.PrecacheSound( strFireSnd );
		g_SoundSystem.PrecacheSound( strEmptySnd );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= iMaxCarry;
		info.iMaxAmmo2	= -1;
		info.iMaxClip 	= iMaxClip;
		info.iSlot 		= iSlot;
		info.iPosition 	= iPosition;
		info.iId		= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight 	= iWeight;

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
		return self.DefaultDeploy( strVeeMdl, strPeeMdl, CLGLDRAW, "onehanded" );
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false; // cancel any reload in progress.
		SetThink( null );
		BaseClass.Holster( skipLocal );
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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strEmptySnd, Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.2f;

			return;
		}

		--self.m_iClip;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( CLGLFIRE, 0, 0 );

		// Fire sound
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strFireSnd, Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, Vector( flSpread, flSpread, flSpread ), 8192, BULLET_PLAYER_9MM, 0, iDamage );

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
		self.DefaultReload( iMaxClip, CLGLRELOAD, 2.6, 0 );
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
	g_ItemRegistry.RegisterWeapon( GetName(), "cracklife", "9mm" );
}

} // End of namespace