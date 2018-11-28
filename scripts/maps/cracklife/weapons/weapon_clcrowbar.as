/* 
* The original Half-Life version of the Crowbar
* Modified for the Crack-Life Sven Co-op conversion
*
* Original Crack-Life mod by: Siemka321
* Sven Co-op Re-conversion: Rafael "R4to0" Alves
*/

enum crowbar_e
{
	CROWBAR_IDLE = 0,
	CROWBAR_DRAW,
	CROWBAR_HOLSTER,
	CROWBAR_ATTACK1HIT,
	CROWBAR_ATTACK1MISS,
	CROWBAR_ATTACK2MISS,
	CROWBAR_ATTACK2HIT,
	CROWBAR_ATTACK3MISS,
	CROWBAR_ATTACK3HIT,
	CROWBAR_TAUNT,
	CROWBAR_IDLE2,
	CROWBAR_IDLE3
};

namespace CLCROWBAR
{

const string strPeeMdl		= "models/cracklife/p_crowbar.mdl"; // rng p_fists.mdl
const string strVeeMdl		= "models/cracklife/v_crowbar.mdl"; // Tayklor fix <3
const string strWeeMdl		= "models/cracklife/w_crowbar.mdl";

const string strHit1Snd		= "cracklife/weapons/cbar_hit1.wav";
const string strHit2Snd		= "cracklife/weapons/cbar_hit2.wav";
const string strMiss1Snd	= "weapons/cbar_miss1.wav";
const string strHitBod1Snd	= "weapons/cbar_hitbod1.wav";
const string strHitBod2Snd	= "weapons/cbar_hitbod2.wav";
const string strHitBod3Snd	= "weapons/cbar_hitbod3.wav";
const string strTaunt1Snd	= "cracklife/taunts/taunt1.wav";
const string strTaunt2Snd	= "cracklife/taunts/taunt2.wav";
const string strTaunt3Snd	= "cracklife/taunts/taunt3.wav";
const string strTaunt4Snd	= "cracklife/taunts/taunt4.wav";

const float flDamage = g_EngineFuncs.CVarGetFloat( "sk_plr_crowbar" );

class weapon_clcrowbar : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	uint m_iSwing;
	TraceResult m_trHit;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( strWeeMdl ) );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();// get ready to fall down.
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( strVeeMdl );
		g_Game.PrecacheModel( strWeeMdl );
		g_Game.PrecacheModel( strPeeMdl );

		g_SoundSystem.PrecacheSound( strHit1Snd );
		g_SoundSystem.PrecacheSound( strHit2Snd );
		g_SoundSystem.PrecacheSound( strHitBod1Snd );
		g_SoundSystem.PrecacheSound( strHitBod2Snd );
		g_SoundSystem.PrecacheSound( strHitBod3Snd );
		g_SoundSystem.PrecacheSound( strMiss1Snd );

		g_SoundSystem.PrecacheSound( strTaunt1Snd );
		g_SoundSystem.PrecacheSound( strTaunt2Snd );
		g_SoundSystem.PrecacheSound( strTaunt3Snd );
		g_SoundSystem.PrecacheSound( strTaunt4Snd );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 5;
		info.iWeight		= 0;
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;

		return true;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( strVeeMdl ), self.GetP_Model( strPeeMdl ), CROWBAR_DRAW, "crowbar" );
	}

	void Holster( int skiplocal )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		SetThink( null );
		BaseClass.Holster( skiplocal );
	}
	
	void PrimaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SecondaryAttack()
	{
		// The "taunt" animation
		float flTauntDelay;
		self.SendWeaponAnim( CROWBAR_TAUNT, 0, 0 );
		switch( Math.RandomLong( 0,3 ) ) {
			case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strTaunt1Snd, 1, ATTN_NORM, 0, PITCH_NORM ); flTauntDelay = 1.985f; break;
			case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strTaunt2Snd, 1, ATTN_NORM, 0, PITCH_NORM ); flTauntDelay = 1.512f; break;
			case 2: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strTaunt3Snd, 1, ATTN_NORM, 0, PITCH_NORM ); flTauntDelay = 1.512f; break;
			case 3: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strTaunt4Snd, 1, ATTN_NORM, 0, PITCH_NORM ); flTauntDelay = 1.512f; break;
		}
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + flTauntDelay;
		self.m_flNextPrimaryAttack = g_Engine.time + flTauntDelay;
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}


	void SwingAgain()
	{
		Swing( 0 );
	}

	bool Swing( int fFirst )
	{
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				// miss
				switch( ( m_iSwing++ ) % 3 )
				{
					case 0:
						self.SendWeaponAnim( CROWBAR_ATTACK1MISS ); break;
					case 1:
						self.SendWeaponAnim( CROWBAR_ATTACK2MISS ); break;
					case 2:
						self.SendWeaponAnim( CROWBAR_ATTACK3MISS ); break;
				}
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strMiss1Snd, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );

				// player "shoot" animation
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			}
		}
		else
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( ( ( m_iSwing++ ) % 2 ) + 1 )
			{
				case 0:
					self.SendWeaponAnim( CROWBAR_ATTACK1HIT ); break;
				case 1:
					self.SendWeaponAnim( CROWBAR_ATTACK2HIT ); break;
				case 2:
					self.SendWeaponAnim( CROWBAR_ATTACK3HIT ); break;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			// AdamR: Custom damage option
			//float flDamage = 10;
			//if ( self.m_flCustomDmg > 0 )
				//flDamage = self.m_flCustomDmg;
			// AdamR: End

			g_WeaponFuncs.ClearMultiDamage();
			if ( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
			{
				// first swing does full damage
				pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
			}
			else
			{
				// subsequent swings do 50% (Changed -Sniper) (Half)
				pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.5, g_Engine.v_forward, tr, DMG_CLUB );  
			}	
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = g_Engine.time + 0.30; //0.25

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
	// aone
					if( pEntity.IsPlayer() )		// lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
	// end aone
					// play thwack or smack sound
					switch( Math.RandomLong( 0, 2 ) )
					{
					case 0:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, strHitBod1Snd, 1, ATTN_NORM ); break;
					case 1:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, strHitBod2Snd, 1, ATTN_NORM ); break;
					case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, strHitBod3Snd, 1, ATTN_NORM ); break;
					}
					m_pPlayer.m_iWeaponVolume = 128; 
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				self.m_flNextPrimaryAttack = g_Engine.time + 0.25; //0.25
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				switch( Math.RandomLong( 0, 1 ) )
				{
				case 0:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strHit1Snd, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strHit2Snd, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				}
			}

			// delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.2;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}
}

string GetName()
{
	return "weapon_clcrowbar";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CLCROWBAR::weapon_clcrowbar", GetName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "cracklife" );
}

} // End of namespace