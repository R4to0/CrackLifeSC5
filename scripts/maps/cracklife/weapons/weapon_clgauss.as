/*
* The original Half-Life version of the Gauss gun
* Author: Rafael "R4to0" Alves
*
* Modified for Crack-Life
*/

enum gauss_e {
	GAUSS_IDLE = 0,
	GAUSS_IDLE2,
	GAUSS_FIDGET,
	GAUSS_SPINUP,
	GAUSS_SPIN,
	GAUSS_FIRE,
	GAUSS_FIRE2,
	GAUSS_HOLSTER,
	GAUSS_DRAW
};

namespace CLGAUSS
{
// Models
const string P_MDL = "models/hldm-br/cracklife/p_gauss.mdl";
const string V_MDL = "models/hldm-br/cracklife/v_gauss.mdl";
const string W_MDL = "models/hldm-br/cracklife/w_gauss.mdl";

// Sounds
const string S_DIS1 = "weapons/electro4.wav";
const string S_DIS2 = "weapons/electro5.wav";
const string S_DIS3 = "weapons/electro6.wav";
const string S_SPIN = "hldm-br/cracklife/ambience/pulsemachine.wav";
const string S_SHOOT  = "hldm-br/cracklife/weapons/gauss2.wav";

// Sprites
const string strGlowSpr = "sprites/hotglow.spr";
const string strBallSpr = "sprites/hotglow.spr";
const string strBeamSpr = "sprites/smoke.spr";

// Weapon info
const uint URANIUM_MAX_CARRY = 100;
const uint GAUSS_WEIGHT = 20;
const uint GAUSS_DEFAULT_GIVE = 20;

// HUD Position
const uint SLOT = 3;
const uint POSITION = 5;

// Vars
const uint GAUSS_PRIMARY_CHARGE_VOLUME = 256;	// how loud gauss is while charging
const uint GAUSS_PRIMARY_FIRE_VOLUME = 450;	// how loud gauss is when discharged
const bool bIsMultiplayer = false;
const float flSkPlrGauss = g_EngineFuncs.CVarGetFloat( "sk_plr_gauss" ); // 20 vanilla HL, 19 SC(???)

// Attack State
const uint NOT_ATTACKING = 0;
const uint CHARGING_START = 1;
const uint CHARGING = 2;

class weapon_clgauss : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set			{ self.m_hPlayer = EHandle( @value ); }
	}

	private float m_flPlayAftershock;
	private bool m_bPrimaryFire;
	private uint m_iInAttack;
	private float m_flNextAmmoBurn;
	private float m_flAmmoStartCharge;
	private uint m_iSoundState;
	private float m_flStartCharge;
	private CSprite@ m_pGlow;
	private uint m_iGlowBr;

	float GetFullChargeTime()
	{
		return ( ( bIsMultiplayer ) ? 1.5f : 4.0f );
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, W_MDL );
		self.m_iDefaultAmmo = GAUSS_DEFAULT_GIVE;
		self.FallInit(); // get ready to fall down.
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( P_MDL );
		g_Game.PrecacheModel( V_MDL );
		g_Game.PrecacheModel( W_MDL );
		g_Game.PrecacheModel( strGlowSpr );
		g_Game.PrecacheModel( strBallSpr );
		g_Game.PrecacheModel( strBeamSpr );
		g_SoundSystem.PrecacheSound( S_DIS1 );
		g_SoundSystem.PrecacheSound( S_DIS2 );
		g_SoundSystem.PrecacheSound( S_DIS3 );
		g_SoundSystem.PrecacheSound( S_SPIN );
		g_SoundSystem.PrecacheSound( S_SHOOT );
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) )
		{
			@m_pPlayer = pPlayer;
			NetworkMessage clgauss( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				clgauss.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
			clgauss.End();
			return true;
		}
		return false;
	}

	bool IsUseable()
	{
		//Currently charging, allow the player to fire it first. - Solokiller
		return BaseClass.IsUseable() || m_iInAttack != NOT_ATTACKING;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= URANIUM_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip 	= -1;
		info.iSlot 	= SLOT;
		info.iPosition 	= POSITION;
		info.iId	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight 	= GAUSS_WEIGHT;
		return true;
	}

	bool Deploy()
	{
		m_flPlayAftershock = 0.0f;
		return self.DefaultDeploy( V_MDL, P_MDL, GAUSS_DRAW, "gauss" );
	}

	void Holster( int skipLocal = 0 )
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, S_SPIN );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
		self.SendWeaponAnim( GAUSS_HOLSTER );
		m_iInAttack = NOT_ATTACKING;
	}

	void PrimaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			return;
		}

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < 2 )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = GAUSS_PRIMARY_FIRE_VOLUME;
		m_bPrimaryFire = true;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 2 );

		StartFire();
		m_iInAttack = NOT_ATTACKING;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.2f; // m_pPlayer.m_flNextAttack = g_Engine.time + 0.2f;
	}

	void SecondaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			if( m_iInAttack != NOT_ATTACKING )
			{
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_DIS1, 1.0f, ATTN_NORM, 0, 80 + Math.RandomLong( 0,0x3f ) );
				self.SendWeaponAnim( GAUSS_IDLE );
				m_iInAttack = NOT_ATTACKING;
			}
			else
			{
				self.PlayEmptySound();
			}
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;
			return;
		}
		
		if( m_iInAttack == NOT_ATTACKING )
		{
			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			{
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8f, ATTN_NORM );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f; // m_pPlayer.m_flNextAttack = g_Engine.time + 0.5f;
				return;
			}

			m_bPrimaryFire = false;

			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );	// take one ammo just to start the spin
			m_flNextAmmoBurn = g_Engine.time;

			// spin up
			m_pPlayer.m_iWeaponVolume = GAUSS_PRIMARY_CHARGE_VOLUME;
	
			self.SendWeaponAnim( GAUSS_SPINUP );
			m_iInAttack = CHARGING_START;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.5f;
			m_flStartCharge = g_Engine.time;
			m_flAmmoStartCharge = g_Engine.time + GetFullChargeTime();
			m_iSoundState = SND_CHANGE_PITCH;
		}
		else if( m_iInAttack == CHARGING_START )
		{
			if( self.m_flTimeWeaponIdle < g_Engine.time )
			{
				self.SendWeaponAnim( GAUSS_SPIN );
				m_iInAttack = CHARGING;
			}
		}
		else
		{
			//Moved to before the ammo burn.
			//Because we drained 1 in AttackState NOT_ATTACKING, then 1 again now before checking if we're out of ammo,
			//this resuled in the player having -1 ammo, which in turn caused CanDeploy to think it could be deployed.
			//This will need to be fixed further down the line by preventing negative ammo unless explicitly required (infinite ammo?),
			//But this check will prevent the problem for now. - Solokiller
			//TODO: investigate further.
			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			{
				// out of ammo! force the gun to fire
				StartFire();
				m_iInAttack = NOT_ATTACKING;
				//Need to set m_flNextPrimaryAttack so the weapon gets a chance to complete its secondary fire animation. - Solokiller
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
				return;
			}

			// during the charging process, eat one bit of ammo every once in a while
			if( g_Engine.time >= m_flNextAmmoBurn && m_flNextAmmoBurn != 1000 )
			{
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
				m_flNextAmmoBurn = g_Engine.time + ( ( bIsMultiplayer ) ? 0.1f : 0.3f ); // 0.1 for HLDM
			}

			if( g_Engine.time >= m_flAmmoStartCharge )
			{
				// don't eat any more ammo after gun is fully charged.
				m_flNextAmmoBurn = 1000;
			}

			float pitch = ( g_Engine.time - m_flStartCharge ) * ( 150 / GetFullChargeTime() ) + 100;

			if( pitch > 250 ) 
				pitch = 250;

			// g_Game.AlertMessage( at_console, "%1 %2 %3\n", m_iInAttack, m_iSoundState, pitch );

			// if( m_iSoundState == 0 )
				// g_Game.AlertMessage( at_console, "sound state %1\n", m_iSoundState );

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_SPIN, 1.0f, ATTN_NORM, m_iSoundState, int( pitch ) );

			m_iSoundState = SND_CHANGE_PITCH;	// hack for going through level transitions

			m_pPlayer.m_iWeaponVolume = GAUSS_PRIMARY_CHARGE_VOLUME;

			// self.m_flTimeWeaponIdle = g_Engine.time + 0.1;
			if( m_flStartCharge < g_Engine.time - 10 )
			{
				// Player charged up too long. Zap him.
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, S_DIS1, 1.0f, ATTN_NORM, 0, 80 + Math.RandomLong( 0,0x3f ) );
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM,   S_DIS3, 1.0f, ATTN_NORM, 0, 75 + Math.RandomLong( 0,0x3f ) );
		
				m_iInAttack = NOT_ATTACKING;
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;

				m_pPlayer.TakeDamage( g_EntityFuncs.Instance( 0 ).pev, g_EntityFuncs.Instance( 0 ).pev, 50, DMG_SHOCK );
				g_PlayerFuncs.ScreenFade( m_pPlayer, Vector( 255,128,0 ), 2, 0.5, 128, FFADE_IN );

				self.SendWeaponAnim( GAUSS_IDLE );
		
				// Player may have been killed and this weapon dropped, don't execute any more code after this!
				return;
			}
		}
	}
	//=========================================================
	// StartFire- since all of this code has to run and then 
	// call Fire(), it was easier at this point to rip it out 
	// of weaponidle() and make its own function then to try to
	// merge this into Fire(), which has some identical variable names 
	//=========================================================
	void StartFire()
	{
		float flDamage;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecAiming = g_Engine.v_forward;
		Vector vecSrc = m_pPlayer.GetGunPosition(); // + gpGlobals->v_up * -8 + gpGlobals->v_right * 8;

		if( g_Engine.time - m_flStartCharge > GetFullChargeTime() )
		{
			flDamage = flSkPlrGauss * 10; //200
		}
		else
		{
			flDamage = ( flSkPlrGauss * 10 ) * ( ( g_Engine.time - m_flStartCharge ) / GetFullChargeTime() ); //200
		}

		if( m_bPrimaryFire )
		{
			// fixed damage on primary attack
			//flDamage = 20;
			flDamage = flSkPlrGauss;
		}

		// m_iInAttack is never 3, so this check is always true. - Solokiller
		//if( m_iInAttack != 3 )
		//{
			//g_Game.AlertMessage( at_console, "Time:%1 Damage:%2\n", g_Engine.time - m_flStartCharge, flDamage );

			float flZVel = m_pPlayer.pev.velocity.z;

			if( !m_bPrimaryFire )
			{
				m_pPlayer.pev.velocity = m_pPlayer.pev.velocity - g_Engine.v_forward * flDamage * 5;
			}

			if( !bIsMultiplayer )
			{
				// in deathmatch, gauss can pop you up into the air. Not in single play.
				m_pPlayer.pev.velocity.z = flZVel;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		//}

		// time until aftershock 'static discharge' sound
		m_flPlayAftershock = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.3f, 0.8f );

		Fire( vecSrc, vecAiming, flDamage );
	}

	void Fire( Vector vecOrigSrc, Vector vecDir, float flDamage )
	{
		m_pPlayer.m_iWeaponVolume = GAUSS_PRIMARY_FIRE_VOLUME;

		// if( !m_bPrimaryFire )
			// g_irunninggausspred = true;

		// This reliable event is used to stop the spinning sound
		// It's delayed by a fraction of second to make sure it is delayed by 1 frame on the client
		// It's sent reliably anyway, which could lead to other delays
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, S_SPIN );

		// The main firing event is sent unreliably so it won't be delayed.
		m_pPlayer.pev.punchangle.x = -2.0f;
		g_SoundSystem.PlaySound( m_pPlayer.edict(), CHAN_WEAPON, S_SHOOT, 0.5f + flDamage * ( 0.40 / 400.0f ), ATTN_NORM, 0, 85 - Math.RandomLong( 0, 0x1f ) );
		self.SendWeaponAnim( GAUSS_FIRE2 );

		/*g_Game.AlertMessage( at_console, "%1 %2 %3\n%4 %5 %6\n", 
		vecSrc.x, vecSrc.y, vecSrc.z, 
		vecDest.x, vecDest.y, vecDest.z );*/
	

		//	g_Game.AlertMessage( at_console, "%1 %2\n", tr.flFraction, flMaxFrac );

		Vector vecSrc = vecOrigSrc;
		Vector vecDest = vecSrc + vecDir * 8192;

		TraceResult tr, beam_tr;

		edict_t@ pentIgnore = m_pPlayer.edict();

		float flMaxFrac = 1.0f;

		int	nTotal = 0;
		bool fHasPunched = false;
		bool fFirstBeam = true;
		int	nMaxHits = 10;

		while( flDamage > 10 && nMaxHits > 0 )
		{
			nMaxHits--;

			// g_Game.AlertMessage( at_console, "." );
			g_Utility.TraceLine( vecSrc, vecDest, dont_ignore_monsters, pentIgnore, tr );

			if( tr.fAllSolid != 0 )
				break;

			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			if( pEntity is null )
				break;

			if( fFirstBeam )
			{
				// Add muzzle flash to current weapon model
				m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
				fFirstBeam = false;

				// https://github.com/SamVanheer/HLEnhanced/blob/master/game/client/ev_hldm.cpp#L816
				// https://github.com/SamVanheer/HLEnhanced/blob/09e3f1db51abcfebf43eac5d5fb3ccb7d3809196/shared/engine/client/r_efx.h#L804
				NetworkMessage beampoint( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
					beampoint.WriteByte( TE_BEAMENTPOINT );
					beampoint.WriteShort( m_pPlayer.entindex() + 0x1000 ); // Entity target for the beam to follow
					beampoint.WriteCoord( tr.vecEndPos.x ); // End position of the beam X
					beampoint.WriteCoord( tr.vecEndPos.y ); // End position of the beam Y
					beampoint.WriteCoord( tr.vecEndPos.z ); // End position of the beam Z
					beampoint.WriteShort( g_EngineFuncs.ModelIndex( strBeamSpr ) ); // Index of the sprite to use
					beampoint.WriteByte( 0 ); // Starting frame for the beam sprite
					beampoint.WriteByte( 0 ); // Frame rate of the beam sprite
					beampoint.WriteByte( 1 ); // How long to display the beam (0.1)  *10
					beampoint.WriteByte( m_bPrimaryFire ? 10 : 25 ); // Width of the beam (1.0, 2.5) * 100
					beampoint.WriteByte( 0 ); // Noise amplitude. (SC's is 0.1) * 100
					beampoint.WriteByte( 255 ); // Red color
					beampoint.WriteByte( m_bPrimaryFire ? 128 : 255 ); // Green color
					beampoint.WriteByte( m_bPrimaryFire ? 0 : 255 ); // Blue color
					beampoint.WriteByte( m_bPrimaryFire ? 128 : int( flDamage ) ); // Brightness
					beampoint.WriteByte( 0 ); // Scroll rate of the beam sprite
				beampoint.End();

				nTotal += 26;
			}
			else // Beam reflection -R4to0
			{
				// https://github.com/SamVanheer/HLEnhanced/blob/master/game/client/ev_hldm.cpp#L834
				NetworkMessage beampoints( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
					beampoints.WriteByte( TE_BEAMPOINTS );
					beampoints.WriteCoord( vecSrc.x ); // Starting position of the beam X
					beampoints.WriteCoord( vecSrc.y ); // Starting position of the beam Y
					beampoints.WriteCoord( vecSrc.z ); // Starting position of the beam Z
					beampoints.WriteCoord( tr.vecEndPos.x ); // End position of the beam X
					beampoints.WriteCoord( tr.vecEndPos.y ); // End position of the beam Y
					beampoints.WriteCoord( tr.vecEndPos.z ); // End position of the beam Z
					beampoints.WriteShort( g_EngineFuncs.ModelIndex( strBeamSpr ) ); // Index of the sprite to use
					beampoints.WriteByte( 0 ); // Starting frame for the beam sprite
					beampoints.WriteByte( 0 ); // Frame rate of the beam sprite
					beampoints.WriteByte( 1 ); // How long to display the beam (0.1) *10
					beampoints.WriteByte( m_bPrimaryFire ? 10 : 25 ); // Width of the beam (1.0, 2.5) * 100
					beampoints.WriteByte( 0 ); // Noise amplitude. (SC's is 0.1) * 10
					beampoints.WriteByte( 255 ); // Red color
					beampoints.WriteByte( m_bPrimaryFire ? 128 : 255 ); // Green color
					beampoints.WriteByte( m_bPrimaryFire ? 0 : 255 ); // Blue color
					beampoints.WriteByte( m_bPrimaryFire ? 128 : int( flDamage ) ); // Brightness
					beampoints.WriteByte( 0 ); // Scroll rate of the beam sprite
				beampoints.End();
			}

			if( pEntity.pev.takedamage != DAMAGE_NO )
			{
				g_WeaponFuncs.ClearMultiDamage();
				pEntity.TraceAttack( m_pPlayer.pev, flDamage, vecDir, tr, DMG_BULLET );
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
			}

			// https://github.com/SamVanheer/HLEnhanced/blob/master/game/client/ev_hldm.cpp#L854
			if( pEntity.ReflectGauss() || pEntity.pev.solid == SOLID_BSP )
			{
				@pentIgnore = null;

				float n = -DotProduct( tr.vecPlaneNormal, vecDir );

				// Reflect point -R4to0
				if( n < 0.5 ) // 60 degrees
				{
					// g_Game.AlertMessage( at_console, "reflect %1\n", n );
					// reflect
					Vector r;

					r = 2.0 * tr.vecPlaneNormal * n + vecDir;
					flMaxFrac = flMaxFrac - tr.flFraction;
					vecDir = r;
					vecSrc = tr.vecEndPos + vecDir * 8;
					vecDest = vecSrc + vecDir * 8192;

					//g_Game.AlertMessage( at_console, "reflectgauss() solidbsp\n");

					GaussGlow( tr, 0.2f, flDamage * n, flDamage * n * 0.5f * 0.1f ); // scale, alpha, life

					// explode a bit
					g_WeaponFuncs.RadiusDamage( tr.vecEndPos, self.pev, m_pPlayer.pev, flDamage * n, (flDamage * n) * 2.5f, CLASS_NONE, DMG_BLAST );

					//Vector fwd = tr.vecEndPos + tr.vecPlaneNormal);

					GaussBall( tr, ( tr.vecEndPos + tr.vecPlaneNormal ), 3, 0.1, 100, 100 ); // quantity, life, amplitude, speed

					nTotal += 34;

					// lose energy
					if( n == 0 ) n = 0.1f;
					flDamage = flDamage * ( 1 - n );
				}
				else
				{
					// Final point -R4to0
					// tunnel
					g_WeaponFuncs.DecalGunshot( tr, BULLET_MONSTER_12MM );
					GaussGlow( tr, 1.0f, flDamage, 6.0f ); // scale, alpha, life

					//g_Game.AlertMessage( at_console, "NOT reflectgauss() solidbsp\n");

					nTotal += 13;

					// limit it to one hole punch
					if( fHasPunched )
						break;
					fHasPunched = true;

					// try punching through wall if secondary attack (primary is incapable of breaking through)
					if( !m_bPrimaryFire )
					{
						g_Utility.TraceLine( tr.vecEndPos + vecDir * 8, vecDest, dont_ignore_monsters, pentIgnore, beam_tr);
						if( beam_tr.fAllSolid == 0 )
						{
							// trace backwards to find exit point
							g_Utility.TraceLine( beam_tr.vecEndPos, tr.vecEndPos, dont_ignore_monsters, pentIgnore, beam_tr);

							n = ( beam_tr.vecEndPos - tr.vecEndPos ).Length();

							if( n < flDamage )
							{
								if( n == 0 ) n = 1;
								flDamage -= n;

								//absorption balls
								GaussBall( tr, ( tr.vecEndPos - vecDir ), 3, 0.1f, 100, 100 ); // quantity, life, amplitude, speed.

								//g_Game.AlertMessage( at_console, "punch %1\n", n );
								nTotal += 21;

								// exit blast damage
								//g_WeaponFuncs.RadiusDamage( beam_tr.vecEndPos + vecDir * 8, self.pev, m_pPlayer.pev, flDamage, CLASS_NONE, DMG_BLAST );
								float damage_radius = flDamage * ( ( bIsMultiplayer ) ? 1.75f : 2.5f );
							

								/*if( bIsMultiplayer )
								{
									damage_radius = flDamage * 1.75f;  // Old code == 2.5
								}
								else
								{
									damage_radius = flDamage * 2.5f;
								}*/

								g_WeaponFuncs.RadiusDamage( beam_tr.vecEndPos + vecDir * 8, self.pev, m_pPlayer.pev, flDamage, damage_radius, CLASS_NONE, DMG_BLAST );

								//g_SoundSystem.InsertSound( bits_SOUND_COMBAT, self.pev.origin, NORMAL_EXPLOSION_VOLUME, 3.0f );

								GaussGlow( tr, 0.1f, flDamage, 6.0f ); // scale, alpha, life
								GaussBall( beam_tr, ( beam_tr.vecEndPos - vecDir ), int( flDamage * 0.02f ), 0.1f, 200, 40 ); // quantity, life, amplitude, speed. Needs better calculator for quantity -R4to0

								nTotal += 53;

								vecSrc = beam_tr.vecEndPos + vecDir;
							}
						}
						else
						{
							// g_Game.AlertMessage( at_console, "blocked %1\n", n );
							flDamage = 0;
						}
					}
					else
					{
						// g_Game.AlertMessage( at_console, "blocked solid\n" );

						if( m_bPrimaryFire )
						{
							// slug doesn't punch through ever with primary 
							// fire, so leave a little glowy bit and make some balls
							GaussGlow( tr, 0.2f, 200.0f, 0.3f ); // scale, alpha, life
							GaussBall( tr, ( tr.vecEndPos + tr.vecPlaneNormal ), 8, 0.6f, 100, 200 ); // quantity, life, amplitude, speed
						}

						flDamage = 0;
					}
				}
			}
			else
			{
				vecSrc = tr.vecEndPos + vecDir;
				@pentIgnore = pEntity.edict();
			}
		}

		//g_Game.AlertMessage( at_console, "%1 bytes\n", nTotal );
	}

	// https://github.com/SamVanheer/HLEnhanced/blob/master/game/client/ev_hldm.cpp#L873
	void GaussGlow( TraceResult &in tr, float flScale, float flDamage, float flLife )
	{
		NetworkMessage glow( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
			glow.WriteByte( TE_GLOWSPRITE );
			glow.WriteCoord( tr.vecEndPos.x );
			glow.WriteCoord( tr.vecEndPos.y );
			glow.WriteCoord( tr.vecEndPos.z );
			glow.WriteShort( g_EngineFuncs.ModelIndex( strGlowSpr ) );
			glow.WriteByte( int( flLife * 10 ) ); // Time to wait before fading out
			glow.WriteByte( int( flScale ) ); // scale (0.2)
			glow.WriteByte( int( flDamage ) ); //alpha
		glow.End();
	}

	// https://github.com/SamVanheer/HLEnhanced/blob/master/game/client/ev_hldm.cpp#L877
	// https://github.com/SamVanheer/HLEnhanced/blob/master/shared/engine/client/r_efx.h#L642
	void GaussBall( TraceResult &in tr, Vector vecEnd, uint iCount, float flLife, uint iAmplitude, uint iSpeed )
	{
		NetworkMessage gaussball( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			gaussball.WriteByte( TE_SPRITETRAIL );
			gaussball.WriteCoord( tr.vecEndPos.x ); // start position
			gaussball.WriteCoord( tr.vecEndPos.y );
			gaussball.WriteCoord( tr.vecEndPos.z );
			gaussball.WriteCoord( vecEnd.x ); // end position
			gaussball.WriteCoord( vecEnd.y );
			gaussball.WriteCoord( vecEnd.z );
			gaussball.WriteShort( g_EngineFuncs.ModelIndex( strBallSpr ) ); // sprite index
			gaussball.WriteByte( iCount ); // count
			gaussball.WriteByte( int( flLife * 100 ) ); // life in 0.1's
			gaussball.WriteByte( Math.RandomLong( 1, 2 ) ); // scale in 0.1's
			gaussball.WriteByte( iSpeed/10 ); // velocity along vector in 10's
			gaussball.WriteByte( iAmplitude/10 ); // randomness of velocity in 10's
		gaussball.End();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		// play aftershock static discharge
		if(  m_flPlayAftershock > 0 && m_flPlayAftershock < g_Engine.time  )
		{
			switch( Math.RandomLong( 0,3 ) )
			{
			case 0:	g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, S_DIS1, Math.RandomFloat( 0.7f, 0.8f ), ATTN_NORM ); break;
			case 1:	g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, S_DIS2, Math.RandomFloat( 0.7f, 0.8f ), ATTN_NORM ); break;
			case 2:	g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, S_DIS3, Math.RandomFloat( 0.7f, 0.8f ), ATTN_NORM ); break;
			case 3:	break; // no sound
			}
			m_flPlayAftershock = 0.0f;
		}

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iInAttack != 0 )
		{
			StartFire();
			m_iInAttack = 0;
			self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

			//Need to set m_flNextPrimaryAttack so the weapon gets a chance to complete its secondary fire animation. - Solokiller
			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
		}
		else
		{
			int iAnim;
			float flRand = Math.RandomFloat( 0, 1 );
			if( flRand <= 0.5f )
			{
				iAnim = GAUSS_IDLE;
				self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
			}
			else if( flRand <= 0.75f )
			{
				iAnim = GAUSS_IDLE2;
				self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
			}
			else
			{
				iAnim = GAUSS_FIDGET;
				self.m_flTimeWeaponIdle = g_Engine.time + 3;
			}

			self.SendWeaponAnim( iAnim );
			return;
		}
	}
}

string GetName()
{
	return "weapon_clgauss";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CLGAUSS::weapon_clgauss", GetName() );
	g_ItemRegistry.RegisterWeapon( "weapon_clgauss", "hldm-br/cracklife", "uranium" );
}

}