/**
* The original Half-Life version of the mp5
* Modified by for the Crack-Life Sven Co-op conversion
*
* Original Crack-Life mod by: Siemka321
* Sven Co-op Re-conversion: Rafael "R4to0" Alves
 */

namespace CLMP5
{

enum Mp5Animation
{
	MP5_LONGIDLE = 0,
	MP5_IDLE1,
	MP5_LAUNCH,
	MP5_RELOAD,
	MP5_DEPLOY,
	MP5_FIRE1,
	MP5_FIRE2,
	MP5_FIRE3
};

// Let's Crack-Life this
// Confirmed IDA - 12 Feb 2019 -R4to0
const uint g_DefGivePri 		= 999;
const uint g_MaxAmmoPri			= 999;
const uint g_MaxAmmoSec 		= 999;
const uint g_MaxClip			= 999;
const uint g_Weight				= 15;
const uint g_PrimaryDmg			= int( g_EngineFuncs.CVarGetFloat( "sk_plr_9mmAR_bullet" ) );
const uint g_SecondaryDmg		= int( g_EngineFuncs.CVarGetFloat( "sk_plr_9mmAR_grenade" ) );
const uint g_DefGiveSec			= 999;
const float g_PriFireDelay		= 0.001f;
const float g_SecFireDelay		= 0.1f;

// Weapon Info
uint g_Slot						= 2;
uint g_Position					= 4;
const string g_PriAmmoType		= "cl_9mm"; //Default: 9mm
const string g_SecAmmoType		= "cl_ARgrenades"; //Default: ARgrenades
const string g_AmmoName 		= "ammo_clmp5";
const string g_SecAmmoName		= "ammo_clmp5grenades";
const string g_WeaponName		= "weapon_clmp5";
const string g_ProjName			= "proj_clgrenade";

// Models
const string g_PeeMdl			= "models/hlclassic/p_9mmAR.mdl"; // SC HL1 "classic mode" model
const string g_VeeMdl			= "models/cracklife/v_9mmar.mdl"; // v2: Edited reload events
const string g_WeeMdl			= "models/hlclassic/w_9mmAR.mdl"; // SC HL1 "classic mode" model
const string g_ShellMdl			= "models/hlclassic/shell.mdl"; // Shell
const string g_GrenadeMdl		= "models/hlclassic/grenade.mdl"; // Grenade
const string g_WeeGrenadeMdl	= "models/hlclassic/w_ARgrenade.mdl"; // Grenade
const string g_WeeAmmoMdl		= "models/hlclassic/w_9mmARclip.mdl"; // Ammo

// Sounds
const string g_ClipInsSnd		= "hlclassic/items/clipinsert1.wav"; // Played by v2 model
const string g_ClipRelSnd		= "hlclassic/items/cliprelease1.wav"; // Played by v2 model
const string g_Fire1Snd			= "hlclassic/weapons/hks1.wav";
const string g_Fire2Snd			= "hlclassic/weapons/hks2.wav";
const string g_Fire3Snd			= "hlclassic/weapons/hks3.wav";
const string g_GL1Snd			= "hlclassic/weapons/glauncher.wav";
const string g_GL2Snd			= "hlclassic/weapons/glauncher2.wav";
const string g_EmptySnd			= "cracklife/weapons/357_cock1.wav";
const string g_AmmoPickSnd		= "hlclassic/items/9mmclip1.wav";
const string g_Debris1Snd		= "hlclassic/weapons/debris1.wav";
const string g_Debris2Snd		= "hlclassic/weapons/debris2.wav";
const string g_Debris3Snd		= "hlclassic/weapons/debris3.wav";

// Sprites
const string g_FireballSpr		= "sprites/zerogxplode.spr";
const string g_ExplosionSpr		= "sprites/WXplo1.spr";
const string g_SmokeSpr			= "sprites/steam1.spr";

class weapon_clmp5 : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	int m_iShell;
	int m_iSecondaryAmmo;

	/*int SecondaryAmmoIndex()
	{
		return self.m_iSecondaryAmmoType;
	}*/

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, g_WeeMdl );

		self.m_iDefaultAmmo = g_DefGivePri;

		self.m_iSecondaryAmmoType = 0;
		self.FallInit();
	}

	void Precache()
	{
		// Models
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( g_VeeMdl );
		g_Game.PrecacheModel( g_WeeMdl );
		g_Game.PrecacheModel( g_PeeMdl );
		m_iShell = g_Game.PrecacheModel( g_ShellMdl );
		g_Game.PrecacheModel( g_GrenadeMdl );

		// Sounds
		g_SoundSystem.PrecacheSound( g_ClipInsSnd );
		g_SoundSystem.PrecacheSound( g_ClipRelSnd );
		g_SoundSystem.PrecacheSound( g_Fire1Snd );
		g_SoundSystem.PrecacheSound( g_Fire2Snd );
		g_SoundSystem.PrecacheSound( g_Fire3Snd );
		g_SoundSystem.PrecacheSound( g_GL1Snd );
		g_SoundSystem.PrecacheSound( g_GL2Snd );
		g_SoundSystem.PrecacheSound( g_EmptySnd );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= g_MaxAmmoPri;
		info.iMaxAmmo2 	= g_MaxAmmoSec;
		info.iMaxClip 	= g_MaxClip;
		info.iSlot		= g_Slot;
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
			NetworkMessage clmp5( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			clmp5.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
			clmp5.End();

			return true;
		}

		return false;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( g_VeeMdl ), self.GetP_Model( g_PeeMdl ), MP5_DEPLOY, "mp5" );
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

	void GetDefaultShellInfo( CBasePlayer@ pPlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale )
	{
		Vector vecForward, vecRight, vecUp;
		
		g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
		
		const float fR = Math.RandomFloat( 50, 70 );
		const float fU = Math.RandomFloat( 100, 150 );
	 
		for( int i = 0; i < 3; ++i )
		{
			ShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * 25;
			ShellOrigin[i]   = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
		}
	}

	void PrimaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.15f;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
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
		
		// Eject brass
		Vector vecShellOrigin, vecShellVelocity;
		GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 22, 6, -9 );
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHELL ); 

		// Fire sound
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
			case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Fire1Snd, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) ); break;
			case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Fire2Snd, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) ); break;
			case 2: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Fire3Snd, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) ); break;
		}

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		// VECTOR_CONE_6DEGREES = optimized multiplayer. Widened to make it easier to hit a moving player
		// VECTOR_CONE_3DEGREES = single player spread
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, ( g_WeaponMode ? VECTOR_CONE_6DEGREES : VECTOR_CONE_3DEGREES ), 8192, BULLET_PLAYER_MP5, 2, g_PrimaryDmg );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		m_pPlayer.pev.punchangle.x = Math.RandomLong( -2, 2 );

		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + g_PriFireDelay; // changed here
		if( self.m_flNextPrimaryAttack < g_Engine.time )
			self.m_flNextPrimaryAttack = g_Engine.time + g_PriFireDelay; // changed here

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

		TraceResult tr;
		float x, y;
		g_Utility.GetCircularGaussianSpread( x, y );
		Vector vecDir = vecAiming + x * ( g_WeaponMode ? VECTOR_CONE_6DEGREES : VECTOR_CONE_3DEGREES ).x * g_Engine.v_right + y * ( g_WeaponMode ? VECTOR_CONE_6DEGREES : VECTOR_CONE_3DEGREES ).y * g_Engine.v_up;
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
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
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
		m_pPlayer.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

		m_pPlayer.pev.punchangle.x = -10.0f; // Is this right? -R4to0; It is https://github.com/ValveSoftware/halflife/blob/master/cl_dll/ev_hldm.cpp#L731 -R4to0

		self.SendWeaponAnim( MP5_LAUNCH );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		if ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) != 0 )
		{
			// play this sound through BODY channel so we can hear it if player didn't stop firing MP5
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_GL1Snd, 0.8f, ATTN_NORM, 0, PITCH_NORM );
		}
		else
		{
			// play this sound through BODY channel so we can hear it if player didn't stop firing MP5
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_GL2Snd, 0.8f, ATTN_NORM, 0, PITCH_NORM );
		}

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		// we don't add in player velocity anymore.
		if( ( m_pPlayer.pev.button & IN_DUCK ) != 0 )
			ShootContact( m_pPlayer.pev, m_pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_right * 6, g_Engine.v_forward * 800 );
		else
			ShootContact( m_pPlayer.pev, m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs * 0.5f + g_Engine.v_forward * 16 + g_Engine.v_right * 6, g_Engine.v_forward * 800 );

		self.m_flNextPrimaryAttack = g_Engine.time + g_SecFireDelay; // changed here
		self.m_flNextSecondaryAttack = g_Engine.time + g_SecFireDelay; // changed here
		self.m_flTimeWeaponIdle = g_Engine.time + 5;// idle pretty soon after shooting.

		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
	}

	void Reload()
	{
        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == g_MaxClip )
            return;

		self.DefaultReload( g_MaxClip, MP5_RELOAD, 1.5f, 0 );

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) )
		{
			case 0:	iAnim = MP5_LONGIDLE; break;
			case 1: iAnim = MP5_IDLE1; break;
			default: iAnim = MP5_IDLE1; break;
		}

		self.SendWeaponAnim( iAnim );

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );// how long till we do this again.
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
		g_EntityFuncs.SetModel( self, g_WeeAmmoMdl );
		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( g_WeeAmmoMdl );
		g_SoundSystem.PrecacheSound( g_AmmoPickSnd );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		if( pOther.GiveAmmo( g_MaxClip, g_PriAmmoType, g_MaxClip ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, g_AmmoPickSnd, 1, ATTN_NORM );
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
		g_EntityFuncs.SetModel( self, g_WeeGrenadeMdl );
		BaseClass.Spawn();
	}
	void Precache()
	{
		g_Game.PrecacheModel( g_WeeGrenadeMdl );
		g_SoundSystem.PrecacheSound( g_AmmoPickSnd );
	}
	bool AddAmmo( CBaseEntity@ pOther ) 
	{
		if( pOther.GiveAmmo( g_DefGiveSec, g_SecAmmoType, g_MaxAmmoSec ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, g_AmmoPickSnd, 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}

/**
 * Custom grenade projectile
 */

class CCLGrenade : ScriptBaseMonsterEntity
{
	int m_iModelIndexFireball;
	int m_iModelIndexWExplosion;
	int m_iModelIndexSmoke;

	void Spawn()
	{
		Precache();
		
		self.pev.movetype = MOVETYPE_BOUNCE;
		
		self.pev.solid = SOLID_BBOX;
		
		g_EntityFuncs.SetModel( self, g_GrenadeMdl );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		
		self.pev.dmg = g_SecondaryDmg; // 100
	}
	
	void Precache()
	{
		g_SoundSystem.PrecacheSound( g_Debris1Snd );
		g_SoundSystem.PrecacheSound( g_Debris2Snd );
		g_SoundSystem.PrecacheSound( g_Debris3Snd );
	
		m_iModelIndexFireball = g_Game.PrecacheModel( g_FireballSpr );
		m_iModelIndexWExplosion = g_Game.PrecacheModel( g_ExplosionSpr );
		m_iModelIndexSmoke = g_Game.PrecacheModel( g_SmokeSpr );
	}

	void Explode( TraceResult pTrace, int bitsDamageType )
	{
		self.pev.model = string_t(); //invisible
		self.pev.solid = SOLID_NOT;// intangible

		self.pev.takedamage = DAMAGE_NO;

		// Pull out of the wall a bit
		if( pTrace.flFraction != 1.0f )
		{
			self.pev.origin = pTrace.vecEndPos + ( pTrace.vecPlaneNormal * ( self.pev.dmg - 24 ) * 0.6f );
		}

		int iContents = g_EngineFuncs.PointContents( self.pev.origin );
	
		NetworkMessage expl( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, self.pev.origin );
			expl.WriteByte( TE_EXPLOSION );		// This makes a dynamic light and the explosion sprites/sound
			expl.WriteCoord( self.pev.origin.x );	// Send to PAS because of the sound
			expl.WriteCoord( self.pev.origin.y );
			expl.WriteCoord( self.pev.origin.z );
			if( iContents != CONTENTS_WATER )
				expl.WriteShort( m_iModelIndexFireball );
			else
				expl.WriteShort( m_iModelIndexWExplosion );
			expl.WriteByte( int( ( self.pev.dmg - 50 ) * 0.6f ) ); // scale * 10
			expl.WriteByte( 15 ); // framerate
			expl.WriteByte( TE_EXPLFLAG_NONE );
		expl.End();

		GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, self.pev.origin, NORMAL_EXPLOSION_VOLUME, 3.0f, self );
		entvars_t@ pevOwner;
		if( self.pev.owner !is null )
			@pevOwner = self.pev.owner.vars;
		else
			@pevOwner = null;

		@self.pev.owner = null; // can't traceline attack owner if this is set

		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, self.pev.dmg, self.pev.dmg * 2.5f, CLASS_NONE, bitsDamageType );

		if( Math.RandomFloat( 0, 1 ) < 0.5f )
			g_Utility.DecalTrace( pTrace, DECAL_SCORCH1 );
		else
			g_Utility.DecalTrace( pTrace, DECAL_SCORCH2 );

		switch( Math.RandomLong( 0, 2 ) )
		{
			case 0:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, g_Debris1Snd, 0.55f, ATTN_NORM ); break;
			case 1:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, g_Debris2Snd, 0.55f, ATTN_NORM ); break;
			case 2:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, g_Debris3Snd, 0.55f, ATTN_NORM ); break;
		}

		self.pev.effects |= EF_NODRAW;
		SetThink( ThinkFunction( this.Smoke ) );
		self.pev.velocity = g_vecZero;
		self.pev.nextthink = g_Engine.time + 0.3f;

		if( iContents != CONTENTS_WATER )
		{
			int sparkCount = Math.RandomLong( 0, 3 );
			for( int i = 0; i < sparkCount; i++ )
				g_EntityFuncs.Create( "spark_shower", self.pev.origin, pTrace.vecPlaneNormal, false );
		}
	}
	
	void Smoke()
	{
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_WATER )
		{
			g_Utility.Bubbles( self.pev.origin - Vector( 64, 64, 64 ), self.pev.origin + Vector( 64, 64, 64 ), 100 );
		}
		else
		{
			NetworkMessage smoke( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, self.pev.origin );
				smoke.WriteByte( TE_SMOKE );
				smoke.WriteCoord( self.pev.origin.x );
				smoke.WriteCoord( self.pev.origin.y );
				smoke.WriteCoord( self.pev.origin.z );
				smoke.WriteShort( m_iModelIndexSmoke );
				smoke.WriteByte( int( ( self.pev.dmg - 50 ) * 0.80f ) ); // scale * 10
				smoke.WriteByte( 12 ); // framerate
			smoke.End();
	}
	g_EntityFuncs.Remove( self );
}

	void ExplodeTouch( CBaseEntity@ pOther )
	{
		TraceResult tr;
		Vector		vecSpot;// trace starts here!

		@self.pev.enemy = @pOther.edict();

		vecSpot = self.pev.origin - self.pev.velocity.Normalize() * 32;
		g_Utility.TraceLine( vecSpot, vecSpot + self.pev.velocity.Normalize() * 64, ignore_monsters, self.edict(), tr );

		Explode( tr, DMG_BLAST );
	}

	void DangerSoundThink()
	{
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		GetSoundEntInstance().InsertSound( bits_SOUND_DANGER, ( self.pev.origin + self.pev.velocity ) * 0.5f, int ( self.pev.velocity.Length() ), 0.2f, self );
		self.pev.nextthink = g_Engine.time + 0.2f;

		if( self.pev.waterlevel != WATERLEVEL_DRY )
		{
			self.pev.velocity = self.pev.velocity * 0.5f;
		}

	}
}

CCLGrenade@ ShootContact( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ cbeCLGrenade = g_EntityFuncs.CreateEntity( g_ProjName );
	CCLGrenade@ pGrenade = cast<CCLGrenade@>( CastToScriptClass( cbeCLGrenade ) );
	g_EntityFuncs.DispatchSpawn( pGrenade.self.edict() );

	// contact grenades arc lower
	pGrenade.pev.gravity = 0.5f;// lower gravity since grenade is aerodynamic and engine doesn't know it.
	g_EntityFuncs.SetOrigin( pGrenade.self, vecStart );
	pGrenade.pev.velocity = vecVelocity;
	pGrenade.pev.angles = Math.VecToAngles( pGrenade.pev.velocity );
	@pGrenade.pev.owner = pevOwner.get_pContainingEntity();

	// make monsters afaid of it while in the air
	pGrenade.SetThink( ThinkFunction( pGrenade.DangerSoundThink ) );
	pGrenade.pev.nextthink = g_Engine.time;

	// Tumble in air
	pGrenade.pev.avelocity.x = Math.RandomFloat( -100, -500 );

	// Explode on contact
	pGrenade.SetTouch( TouchFunction( pGrenade.ExplodeTouch ) );

	pGrenade.pev.dmg = g_SecondaryDmg;

	return pGrenade;
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CLMP5::weapon_clmp5", g_WeaponName );
	g_ItemRegistry.RegisterWeapon( g_WeaponName, "cracklife", g_PriAmmoType, g_SecAmmoType );
	g_CustomEntityFuncs.RegisterCustomEntity( "CLMP5::AmmoClip", g_AmmoName );
	g_CustomEntityFuncs.RegisterCustomEntity( "CLMP5::AmmoGrenade", g_SecAmmoName );
	g_CustomEntityFuncs.RegisterCustomEntity( "CLMP5::CCLGrenade", g_ProjName );
	g_Game.PrecacheOther( g_ProjName );
	g_Game.PrecacheOther( g_AmmoName );
	g_Game.PrecacheOther( g_SecAmmoName );
}

} // End of namespace