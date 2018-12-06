/*  
* The original Half-Life version of the Python/357
* Modified by for the Crack-Life Sven Co-op conversion
*
* Original Crack-Life mod by: Siemka321
* Sven Co-op Re-conversion: Rafael "R4to0" Alves
*/

enum CLPYTHON_e
{
	CLPYTHON_IDLE1 = 0,
	CLPYTHON_DRAW,
	CLPYTHON_FIRE1,
	CLPYTHON_RELOAD
};

namespace CLPYTHON
{

// Models
const string strPeeMdl		= "models/cracklife/null.mdl"; // Tayklor fix <3
const string strVeeMdl		= "models/cracklife/v_357.mdl";
const string strWeeMdl		= "models/w_357.mdl";

// Sounds
const string strFire1Snd	= "cracklife/weapons/357_shot1.wav"; //POW
//const string strFire2Snd		= "cracklife/weapons/357_shot2.wav";
const string strEmptySnd	= "cracklife/weapons/357_cock1.wav"; //NO!

// Weapon Info
const uint iMaxCarry		= 36;
const uint iMaxClip			= 6;
const uint iWeight			= 15;
const uint iDamage			= int( g_EngineFuncs.CVarGetFloat( "sk_plr_357_bullet" ) ); // 0 = default
const uint iFov				= 20; // 40 HL default (fov 90)

// Weapon HUD
const uint iSlot			= 1;
const uint iPosition		= 5;

class weapon_clpython : ScriptBasePlayerWeaponEntity
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

		g_SoundSystem.PrecacheSound( strFire1Snd );
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
			NetworkMessage clpython( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			clpython.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
			clpython.End();
			return true;
		}

		return false;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
		
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strEmptySnd, 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
	
	return false;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	bool Deploy()
	{
		return self.DefaultDeploy( strVeeMdl, strPeeMdl, CLPYTHON_DRAW, "python" );
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false; // cancel any reload in progress.

		if( self.m_fInZoom == true )
		{
			self.m_fInZoom = false;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
		}

		SetThink( null );
		BaseClass.Holster( skipLocal );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}

	void SecondaryAttack()
	{
		if( self.m_fInZoom == true ) // m_pPlayer.pev.fov != 0
		{
			self.m_fInZoom = false;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0; // 0 means reset to default fov
		}
		else if( self.m_fInZoom == false ) // m_pPlayer.pev.fov != iFov
		{
			self.m_fInZoom = true;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = iFov;
		}

		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5;
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

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		--self.m_iClip;

		// POW! HAHA
		self.SendWeaponAnim( CLPYTHON_FIRE1, 0, 0 );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strFire1Snd, Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		// Create the bullet
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_1DEGREES, 8192, BULLET_PLAYER_357, 0, iDamage, m_pPlayer.pev );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

		//TODO: Change to the correct values
		m_pPlayer.pev.punchangle.x = Math.RandomLong( -3, -3 );

		// Decal shit
		TraceResult tr;
		float x, y;
		g_Utility.GetCircularGaussianSpread( x, y );
		Vector vecDir = vecAiming + x * VECTOR_CONE_1DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_1DEGREES.y * g_Engine.v_up;
		Vector vecEnd = vecSrc + vecDir * 4096;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
				if( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_357 );
			}
		}

		// Delay next attack
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.75;
	}

	void Reload()
	{
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == iMaxClip )
			return;

		// Undo zoom before reloading
		if( self.m_fInZoom == true )
		{
			self.m_fInZoom = false;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
		}

		self.DefaultReload( iMaxClip, CLPYTHON_RELOAD, 2.0, 0 );
		BaseClass.Reload();
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim = CLPYTHON_IDLE1	;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  70, 30 );
		self.SendWeaponAnim( iAnim );
	}
}

string GetName()
{
	return "weapon_clpython";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CLPYTHON::weapon_clpython", GetName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "cracklife", "357" );
}

} // End of namespace