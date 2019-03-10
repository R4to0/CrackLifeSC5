/*  
* The original Half-Life version of the Glock
* Modified for the Crack-Life Sven Co-op conversion
*
* Original Crack-Life mod by: Siemka321
* Sven Co-op Re-conversion: Rafael "R4to0" Alves
*/

namespace CLGLOCK
{

enum CLGlock_e
{
	CLGLRELOAD,
	CLGLDRAW,
	CLGLIDLE = 2,
	CLGLFIRE,
	CLGLHOLSTER
};

// Models
const string g_PeeMdl		= "models/cracklife/p_9mmhandgun.mdl"; //Thanks Tayklor
const string g_VeeMdl		= "models/cracklife/v_9mmhandgun.mdl";
const string g_WeeMdl		= "models/cracklife/w_9mmhandgun.mdl";

// Sounds
const string g_FireSnd		= "cracklife/debris/beamstart1.wav"; //PINGLES!
const string g_EmptySnd		= "cracklife/weapons/357_cock1.wav"; //NO!

// Weapon Info
const uint g_MaxAmmoPri		= 999;
const uint g_MaxClip		= 17;
const uint g_Weight			= 10;
const uint g_PrimaryDmg 	= int( g_EngineFuncs.CVarGetFloat( "sk_plr_9mm_bullet" ) );
const string g_PriAmmoType	= "cl_9mm"; //Default: 9mm
const string g_WeaponName	= "weapon_clglock";

// Weapon HUD
uint g_Slot			= 1;
uint g_Position		= 4;

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
		g_EntityFuncs.SetModel( self, g_WeeMdl );
		self.m_iDefaultAmmo = g_MaxClip;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( g_PeeMdl );
		g_Game.PrecacheModel( g_VeeMdl );
		g_Game.PrecacheModel( g_WeeMdl );

		g_SoundSystem.PrecacheSound( g_FireSnd );
		g_SoundSystem.PrecacheSound( g_EmptySnd );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= g_MaxAmmoPri;
		info.iMaxAmmo2	= -1;
		info.iMaxClip 	= g_MaxClip;
		info.iSlot 		= g_Slot;
		info.iPosition 	= g_Position;
		info.iId		= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight 	= g_Weight;

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

	bool Deploy()
	{
		return self.DefaultDeploy( g_VeeMdl, g_PeeMdl, CLGLDRAW, "onehanded" );
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false; // cancel any reload in progress.
		SetThink( null );
		BaseClass.Holster( skipLocal );
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}

	void SecondaryAttack()
	{
		GlockFire( 0.1f, 0.2f );
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;
	}

	void PrimaryAttack()
	{
		GlockFire( 0.01f, 0.3f );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.3f;
	}

	void GlockFire( float flSpread , float flCycleTime)
	{
		if( self.m_iClip <= 0 )
		{
			//self.PlayEmptySound();
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_EmptySnd, Math.RandomFloat( 0.92f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;

			return;
		}

		--self.m_iClip;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( CLGLFIRE, 0, 0 );

		// Fire sound
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_FireSnd, Math.RandomFloat( 0.92f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, Vector( flSpread, flSpread, flSpread ), 8192, BULLET_PLAYER_9MM, 0, g_PrimaryDmg );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
	
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

		// Decal shit
		TraceResult tr;
		float x, y;
		g_Utility.GetCircularGaussianSpread( x, y );
		Vector vecDir = vecAiming + x * flSpread * g_Engine.v_right + y * flSpread  * g_Engine.v_up;
		Vector vecEnd = vecSrc + vecDir * 4096;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction < 1.0f )
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
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == g_MaxClip )
			return;

		self.DefaultReload( g_MaxClip, CLGLRELOAD, 2.75f, 0 );
		BaseClass.Reload();
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int iAnim = CLGLIDLE;

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 60, 16 );
		self.SendWeaponAnim( iAnim );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CLGLOCK::weapon_clglock", g_WeaponName );
	g_ItemRegistry.RegisterWeapon( g_WeaponName, "cracklife", g_PriAmmoType );
}

} // End of namespace