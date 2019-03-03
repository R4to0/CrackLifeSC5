/*
* Hornet projectile
* https://github.com/ValveSoftware/halflife/blob/master/dlls/hornet.cpp
*
* Based on GeckonCZ's Cyberfranklin hornet code, derivated from hornet.cpp
*/

namespace CLHORNET
{

// Models
const string HORNET_MDL	= "models/cracklife/hornet.mdl";
const string S_BUZZ1	= "hornet/ag_buzz1.wav";
const string S_BUZZ2	= "hornet/ag_buzz2.wav";
const string S_BUZZ3	= "hornet/ag_buzz3.wav";
const string S_HHIT1	= "hornet/ag_hornethit1.wav";
const string S_HHIT2	= "hornet/ag_hornethit2.wav";
const string S_HHIT3	= "hornet/ag_hornethit3.wav";

// from hornet.h
const uint HORNET_TYPE_RED		= 0;
const uint HORNET_TYPE_ORANGE	= 1;
const float HORNET_RED_SPEED	= 600.0f;
const float HORNET_ORANGE_SPEED	= 800.0f;
const float HORNET_BUZZ_VOLUME	= 0.8f;
const uint DAMAGE = 10;

class clhornet : ScriptBaseMonsterEntity
{

	private int m_iHornetTrail;
	private int m_iHornetPuff;
	private float m_flStopAttack;
	private int m_iHornetType;
	private float m_flFlySpeed;

	clhornet()
	{
	}

	// don't let hornets gib, ever.
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		// filter these bits a little.
		bitsDamageType &= ~ ( DMG_ALWAYSGIB );
		bitsDamageType |= DMG_NEVERGIB;

		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void Spawn()
	{
		Precache();

		pev.movetype	= MOVETYPE_FLY;
		pev.solid		= SOLID_BBOX;
		pev.takedamage	= DAMAGE_YES;
		pev.flags		|= FL_MONSTER;
		pev.health		= 1;// weak!

		// hornets don't live as long in multiplayer
		m_flStopAttack = g_Engine.time + ( g_WeaponMode ? 3.5f : 5.0f ); // 5.0 for SP

		self.m_flFieldOfView = 0.9; // +- 25 degrees

		if ( Math.RandomLong( 1, 5 ) <= 2 )
		{
			m_iHornetType = HORNET_TYPE_RED;
			m_flFlySpeed = HORNET_RED_SPEED;
		}
		else
		{
			m_iHornetType = HORNET_TYPE_ORANGE;
			m_flFlySpeed = HORNET_ORANGE_SPEED;
		}

		g_EntityFuncs.SetModel( self, HORNET_MDL );
		g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, -4 ), Vector( 4, 4, 4 ) );

		SetTouch( TouchFunction( DieTouch ) );
		SetThink( ThinkFunction( StartTrack ) );

		edict_t@ pSoundEnt = pev.owner;
		if ( pSoundEnt is null )
			@pSoundEnt = self.edict();

		pev.dmg = DAMAGE;

		pev.nextthink = g_Engine.time + 0.1;
		self.ResetSequenceInfo();
	}

	void Precache()
	{
		// Models
		g_Game.PrecacheModel( HORNET_MDL );

		// Sounds
		g_SoundSystem.PrecacheSound( S_BUZZ1 );
		g_SoundSystem.PrecacheSound( S_BUZZ2 );
		g_SoundSystem.PrecacheSound( S_BUZZ3 );
		g_SoundSystem.PrecacheSound( S_HHIT1 );
		g_SoundSystem.PrecacheSound( S_HHIT2 );
		g_SoundSystem.PrecacheSound( S_HHIT3 );

		// Sprites
		m_iHornetPuff	= g_Game.PrecacheModel( "sprites/muz1.spr" );
		m_iHornetTrail	= g_Game.PrecacheModel( "sprites/laserbeam.spr" );
	}

	// hornets will never get mad at each other, no matter who the owner is.
	int IRelationship( CBaseEntity@ pTarget )
	{
		if ( pTarget.pev.modelindex == pev.modelindex )
			return R_NO;

		return self.IRelationship( pTarget );
	}

	// ID's Hornet as their owner
	int Classify()
	{
		//if ( pev.owner && pev.owner.vars.flags & FL_CLIENT )
		//{
		//	return CLASS_PLAYER_BIOWEAPON;
		//}

		//return CLASS_ALIEN_BIOWEAPON;
		return CLASS_PLAYER_BIOWEAPON;
	}

	// Find the closest enemy (alternative to native BestVisibleEnemy) - GeckonCZ's code
	CBaseEntity@ FindClosestEnemy( float fRadius )
	{
		CBaseEntity@ ent = null;
		CBaseEntity@ enemy = null;
		float iNearest = fRadius;

		do
		{
			@ent = g_EntityFuncs.FindEntityInSphere( ent, self.pev.origin,
				fRadius, "*", "classname" ); 
		
			if ( ent is null || !ent.IsAlive() )
				continue;

			if ( ent.pev.classname == "squadmaker" )
				continue;

			if ( ent.entindex() == self.entindex() )
				continue;
			
			if ( ent.edict() is pev.owner )
				continue;
			
			int rel = self.IRelationship(ent);
			if ( rel == R_AL || rel == R_NO )
				continue;

			float iDist = ( ent.pev.origin - self.pev.origin ).Length();
			if ( iDist < iNearest )
			{
				iNearest = iDist;
				@enemy = ent;
			}
		}
		while ( ent !is null );
	
		if ( enemy !is null )	
			g_Game.AlertMessage( at_console, "new enemy %1, relationship %2\n", enemy.GetClassname(), self.IRelationship(enemy) );

		return enemy;
	}

	void StopTrack()
	{
		self.SUB_Remove();
	}

	// StartTrack - starts a hornet out tracking its target
	void StartTrack()
	{
		IgniteTrail();

		SetTouch( TouchFunction( TrackTouch ) );
		SetThink( ThinkFunction( TrackTarget ) );

		pev.nextthink = g_Engine.time + 0.1;
	}

	// StartDart - starts a hornet out just flying straight.
	void StartDart()
	{
		IgniteTrail();

		SetTouch( TouchFunction( DartTouch ) );
		SetThink( ThinkFunction( StopTrack ) );

		pev.nextthink = g_Engine.time + 4;
	}

	void IgniteTrail()
	{
		// trail
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			message.WriteByte( TE_BEAMFOLLOW );
			message.WriteShort( self.entindex() ); // entity
			message.WriteShort( m_iHornetTrail ); // model
			message.WriteByte( 10 ); // life
			message.WriteByte( 2 ); // width

			switch ( m_iHornetType )
			{
			case HORNET_TYPE_RED:
				message.WriteByte( 179 ); // r
				message.WriteByte( 39 ); // g
				message.WriteByte( 14 ); // b
				break;
			case HORNET_TYPE_ORANGE:
				message.WriteByte( 255 ); // r
				message.WriteByte( 128 ); // g
				message.WriteByte( 0 ); // b
				break;
			}
		
			message.WriteByte( 128 ); // brightness
		message.End();
	}

	// Hornet is flying, gently tracking target
	void TrackTarget()
	{
		Vector	vecFlightDir;
		Vector	vecDirToEnemy;
		float	flDelta;

		self.StudioFrameAdvance();

		if (g_Engine.time > m_flStopAttack)
		{
			SetTouch( null );
			SetThink( ThinkFunction( StopTrack ) );
			pev.nextthink = g_Engine.time + 0.1;
			return;
		}

		if ( !self.m_hEnemy.IsValid() )
		{
			self.m_hEnemy = FindClosestEnemy( 512 );
		}

		/*if ( !self.m_hEnemy.IsValid() )
		{
			self.Look( 512 );
			self.m_hEnemy = self.BestVisibleEnemy();
		}*/

		if ( self.m_hEnemy.IsValid() && self.FVisible( self.m_hEnemy.GetEntity(), true ))
		{
			self.m_vecEnemyLKP = self.m_hEnemy.GetEntity().BodyTarget( pev.origin );
		}
		else
		{
			self.m_vecEnemyLKP = self.m_vecEnemyLKP + pev.velocity * m_flFlySpeed * 0.1;
		}

		vecDirToEnemy = ( self.m_vecEnemyLKP - pev.origin ).Normalize();

		if (pev.velocity.Length() < 0.1)
			vecFlightDir = vecDirToEnemy;
		else 
			vecFlightDir = pev.velocity.Normalize();

		// measure how far the turn is, the wider the turn, the slow we'll go this time.
		flDelta = DotProduct ( vecFlightDir, vecDirToEnemy );
	
		if ( flDelta < 0.5 )
		{
			// hafta turn wide again. play sound
			switch ( Math.RandomLong( 0, 2 ) )
			{
				case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, S_BUZZ1, HORNET_BUZZ_VOLUME, ATTN_NORM); break;
				case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, S_BUZZ2, HORNET_BUZZ_VOLUME, ATTN_NORM); break;
				case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, S_BUZZ3, HORNET_BUZZ_VOLUME, ATTN_NORM); break;
			}
		}

		if ( flDelta <= 0 && m_iHornetType == HORNET_TYPE_RED )
		{
			// no flying backwards, but we don't want to invert this, cause we'd go fast when we have to turn REAL far.
			flDelta = 0.25;
		}

		pev.velocity = ( vecFlightDir + vecDirToEnemy ).Normalize();

		if ( pev.owner !is null && (pev.owner.vars.flags & FL_MONSTER) != 0 )
		{
			// random pattern applies to hornets fired by monsters
			pev.velocity.x += Math.RandomFloat( -0.10, 0.10 ); // scramble the flight dir a bit.
			pev.velocity.y += Math.RandomFloat( -0.10, 0.10 );
			pev.velocity.z += Math.RandomFloat( -0.10, 0.10 );
		}

		switch ( m_iHornetType )
		{
			case HORNET_TYPE_RED:
				pev.velocity = pev.velocity * ( m_flFlySpeed * flDelta );// scale the dir by the ( speed * width of turn )
				pev.nextthink = g_Engine.time + Math.RandomFloat( 0.1, 0.3 );
				break;
			case HORNET_TYPE_ORANGE:
				pev.velocity = pev.velocity * m_flFlySpeed;// do not have to slow down to turn.
				pev.nextthink = g_Engine.time + 0.1;// fixed think time
				break;
		}

		pev.angles = Math.VecToAngles( pev.velocity );

		pev.solid = SOLID_BBOX;
		
		// if hornet is close to the enemy, jet in a straight line for a half second.
		// (only in the single player game)
		if ( self.m_hEnemy.IsValid() && !g_WeaponMode )
		{
			if ( flDelta >= 0.4f && ( pev.origin - self.m_vecEnemyLKP ).Length() <= 300.0f )
			{
				NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, pev.origin ); // MSG_PVS gives svc_bad!!! -R4to0
					message.WriteByte( TE_SPRITE );
					message.WriteCoord( pev.origin.x );	// pos
					message.WriteCoord( pev.origin.y );
					message.WriteCoord( pev.origin.z );
					message.WriteShort( m_iHornetPuff );	// model
					//message.WriteByte( 0 );			// life * 10
					message.WriteByte( 2 );				// size * 10
					message.WriteByte( 128 );			// brightness
				message.End();

				switch ( Math.RandomLong( 0, 2 ) )
				{
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, S_BUZZ1, HORNET_BUZZ_VOLUME, ATTN_NORM); break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, S_BUZZ2, HORNET_BUZZ_VOLUME, ATTN_NORM); break;
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, S_BUZZ3, HORNET_BUZZ_VOLUME, ATTN_NORM); break;
				}

				pev.velocity = pev.velocity * 2;
				pev.nextthink = g_Engine.time + 1.0f;
				// don't attack again
				m_flStopAttack = g_Engine.time;
			}
		}
	}

	// Tracking Hornet hit something
	void TrackTouch( CBaseEntity@ pOther )
	{
		if ( pOther.edict() is pev.owner || pOther.pev.modelindex == pev.modelindex )
		{
			// bumped into the guy that shot it.
			pev.solid = SOLID_NOT;
			return;
		}

		if ( IRelationship( pOther ) <= R_NO )
		{
			// hit something we don't want to hurt, so turn around.

			pev.velocity = pev.velocity.Normalize();

			pev.velocity.x *= -1;
			pev.velocity.y *= -1;

			pev.origin = pev.origin + pev.velocity * 4; // bounce the hornet off a bit.
			pev.velocity = pev.velocity * m_flFlySpeed;

			return;
		}

		DieTouch( pOther );
	}

	void DartTouch( CBaseEntity@ pOther )
	{
		DieTouch( pOther );
	}

	void DieTouch( CBaseEntity@ pOther )
	{
		if ( pOther !is null && pOther.pev.takedamage != 0.0f )
		{
			// buzz when you plug someone
			switch( Math.RandomLong ( 0,2 ) )
			{
				case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, S_HHIT1, 1, ATTN_NORM);	break;
				case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, S_HHIT2, 1, ATTN_NORM);	break;
				case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, S_HHIT3, 1, ATTN_NORM);	break;
			}
			
			// do the damage
			pOther.TakeDamage( pev, pev.owner.vars, pev.dmg, DMG_BULLET );
		}

		// GeckoN: modelindex is const, let's apply EF_NODRAW instead
		//pev.modelindex = 0;// so will disappear for the 0.1 secs we wait until NEXTTHINK gets rid
		pev.effects |= EF_NODRAW;
		pev.solid = SOLID_NOT;

		SetThink( ThinkFunction( StopTrack ) );
		pev.nextthink = g_Engine.time + 1; // stick around long enough for the sound to finish!
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CLHORNET::clhornet", "clhornet" );
}

}