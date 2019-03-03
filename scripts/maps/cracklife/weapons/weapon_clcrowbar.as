/* 
* The original Half-Life version of the Crowbar
* Modified for the Crack-Life Sven Co-op conversion
*
* Original Crack-Life mod by: Siemka321
* Sven Co-op Re-conversion: Rafael "R4to0" Alves
*/

namespace CLCROWBAR
{

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

const string g_VeeMdl			= "models/cracklife/v_crowbar.mdl"; // Tayklor fix <3
const string g_WeeMdl			= "models/cracklife/w_crowbar.mdl";

const string g_Hit1Snd			= "cracklife/weapons/cbar_hit1.wav";
const string g_Hit2Snd			= "cracklife/weapons/cbar_hit2.wav";
const string g_Miss1Snd			= "weapons/cbar_miss1.wav";
const string g_HitBod1Snd		= "weapons/cbar_hitbod1.wav";
const string g_HitBod2Snd		= "weapons/cbar_hitbod2.wav";
const string g_HitBod3Snd		= "weapons/cbar_hitbod3.wav";
const array<array<string>> g_TauntSnd =
{	// sound name
	{ "cracklife/taunts/taunt1.wav", "1.985f" },
	{ "cracklife/taunts/taunt2.wav", "1.512f" },
	{ "cracklife/taunts/taunt3.wav", "1.512f" },
	{ "cracklife/taunts/taunt4.wav", "1.512f" }
};

const float g_Damage			= g_EngineFuncs.CVarGetFloat( "sk_plr_crowbar" );

uint g_Slot						= 0;
uint g_Position					= 5;

const string g_WeaponName		= "weapon_clcrowbar";

class weapon_clcrowbar : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	private uint m_iSwing;
	private uint m_rndtaunt;
	TraceResult m_trHit;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( g_WeeMdl ) );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();// get ready to fall down.
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( g_VeeMdl );
		g_Game.PrecacheModel( g_WeeMdl );

		g_SoundSystem.PrecacheSound( g_Hit1Snd );
		g_SoundSystem.PrecacheSound( g_Hit2Snd );
		g_SoundSystem.PrecacheSound( g_HitBod1Snd );
		g_SoundSystem.PrecacheSound( g_HitBod2Snd );
		g_SoundSystem.PrecacheSound( g_HitBod3Snd );
		g_SoundSystem.PrecacheSound( g_Miss1Snd );

		for( uint i = 0; i < g_TauntSnd.length(); i++ )
			g_SoundSystem.PrecacheSound( g_TauntSnd[ i ][ 0 ] );

	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= g_Slot;
		info.iPosition		= g_Position;
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

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( g_VeeMdl ), self.GetP_Model( string_t() ), CROWBAR_DRAW, "crowbar" );
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
		self.SendWeaponAnim( CROWBAR_TAUNT, 0, 0 );
		m_rndtaunt = Math.RandomLong( 1, 4 ) - 1;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_TauntSnd[ m_rndtaunt ][ 0 ], 1, ATTN_NORM, 0, PITCH_NORM );
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + atof( g_TauntSnd[ m_rndtaunt ][ 1 ] );
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
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack =  g_Engine.time + 0.5;
				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Miss1Snd, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );

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
				pEntity.TraceAttack( m_pPlayer.pev, g_Damage, g_Engine.v_forward, tr, DMG_CLUB );  
			}
			else
			{
				// subsequent swings do 50% (Changed -Sniper) (Half)
				pEntity.TraceAttack( m_pPlayer.pev, g_Damage * 0.5, g_Engine.v_forward, tr, DMG_CLUB );  
			}	
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack =  g_Engine.time + 0.30; //0.25

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
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, g_HitBod1Snd, 1, ATTN_NORM ); break;
					case 1:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, g_HitBod2Snd, 1, ATTN_NORM ); break;
					case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, g_HitBod3Snd, 1, ATTN_NORM ); break;
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
				
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack =  g_Engine.time + 0.25; //0.25
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				switch( Math.RandomLong( 0, 1 ) )
				{
				case 0:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Hit1Snd, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, g_Hit2Snd, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
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

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CLCROWBAR::weapon_clcrowbar", g_WeaponName );
	g_ItemRegistry.RegisterWeapon( g_WeaponName, "cracklife" );
}

} // End of namespace