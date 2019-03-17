/*  
* The original Half-Life version of the Python/357
* Modified by for the Crack-Life Sven Co-op conversion
*
* Original Crack-Life mod by: Siemka321
* Sven Co-op Re-conversion: Rafael "R4to0" Alves
*/

namespace CLPYTHON
{

enum CLPYTHON_e
{
	CLPYTHON_IDLE1 = 0,
	CLPYTHON_DRAW,
	CLPYTHON_FIRE1,
	CLPYTHON_RELOAD
};

// Models
const string g_PeeMdl		= "models/cracklife/null.mdl"; // Tayklor fix <3
const string g_VeeMdl		= "models/cracklife/v_357.mdl";
const string g_WeeMdl		= "models/w_357.mdl";

// Sounds
const string g_Fire1Snd		= "cracklife/weapons/357_shot1.wav"; //POW
//const string g_Fire2Snd		= "cracklife/weapons/357_shot2.wav";
const string g_EmptySnd		= "cracklife/weapons/357_cock1.wav"; //NO!

// Weapon Info
const uint g_MaxAmmoPri		= 36;
const uint g_MaxClip		= 6;
const uint g_Weight			= 15;
const uint g_PrimaryDmg		= int( g_EngineFuncs.CVarGetFloat( "sk_plr_357_bullet" ) ); // 0 = default
const uint g_Fov			= 20; // 40 HL default (fov 90)
const string g_WeaponName	= "weapon_clpython";

// Weapon HUD
uint g_Slot			= 1;
uint g_Position		= 5;

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

		g_SoundSystem.PrecacheSound( g_Fire1Snd );
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
		
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_EmptySnd, 0.8f, ATTN_NORM, 0, PITCH_NORM );
		}
	
	return false;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( g_VeeMdl, g_PeeMdl, CLPYTHON_DRAW, "python" );
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
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}

	void SecondaryAttack()
	{
		if( self.m_fInZoom == true ) // m_pPlayer.pev.fov != 0
		{
			self.m_fInZoom = false;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0; // 0 means reset to default fov
		}
		else if( self.m_fInZoom == false ) // m_pPlayer.pev.fov != g_Fov
		{
			self.m_fInZoom = true;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = g_Fov;
		}

		self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
	}

	void PrimaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.15f;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		--self.m_iClip;

		// POW! HAHA
		self.SendWeaponAnim( CLPYTHON_FIRE1, 0, 0 );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Fire1Snd, Math.RandomFloat( 0.92f, 1.0f ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		// Create the bullet
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_1DEGREES, 8192, BULLET_PLAYER_357, 0, g_PrimaryDmg, m_pPlayer.pev );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

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
		self.m_flNextPrimaryAttack = g_Engine.time + 0.75f;
	}

	void Reload()
	{
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == g_MaxClip )
			return;

		// Undo zoom before reloading
		if( self.m_fInZoom == true )
		{
			self.m_fInZoom = false;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
		}

		self.DefaultReload( g_MaxClip, CLPYTHON_RELOAD, 2.0f, 0 );
		BaseClass.Reload();
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int iAnim = CLPYTHON_IDLE1	;

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  70, 30 );
		self.SendWeaponAnim( iAnim );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CLPYTHON::weapon_clpython", g_WeaponName );
	g_ItemRegistry.RegisterWeapon( g_WeaponName, "cracklife", "357" );
}

} // End of namespace