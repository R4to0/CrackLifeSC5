/*
This disables the map restart caused by the tripmine explosions. As requested by Blizzard Fox, it also modifies the tripmines so that they don't explode and instead respawn players who touch the beams.

If you want the tripmines to explode normally but still not restart the level, set the cvar in hl_c11_a3.cfg:

"as_command tmantitroll_respawn_mode 1"

You can increase this value to override the player respawn delay.

In an effort to preserve the puzzle aspect of the map, the tripmines will respawn after exploding so that it's slightly harder to cheese your way through.

The included .cfg will override (not overwrite) the default one if you place it in svencoop_addon, so just extract the contents there and you're good to go.
*/
namespace TRIPMINE_ANTI_TROLL
{

CCVar cvarTMAntiTrollRespawnMode( "tmantitroll_respawn_mode", 0, "Tripmine respawn mode", ConCommandFlag::AdminOnly );
CCVar cvarTMAntiTrollRemoveEnts( "tmantitroll_ents", "leveldead_mm", "List of entity names to remove", ConCommandFlag::AdminOnly );

CScheduledFunction@ fnMineThink, fnStartTripmineAntiTroll = g_Scheduler.SetTimeout( "StartTripmineAntiTroll", 0.01f );

bool respawnMode;
const float flRespawnDelayDefault = g_EngineFuncs.CVarGetFloat( "mp_respawndelay" );

array<TripmineData> mines;

class TripmineData
{
	Vector pos;
	Vector angles;
	EHandle ent;
	bool respawning; // tripmine is scheduled to respawn
	// custom mode
	Vector dir; // look direction
	Vector endPos; // trace end position
	EHandle beam;
}

void StartTripmineAntiTroll()
{
	respawnMode = cvarTMAntiTrollRespawnMode.GetInt() > 0;
	disableRestart();
	findTripmines();
	@fnMineThink = g_Scheduler.SetInterval( "mineThink", 0.0, g_Scheduler.REPEAT_INFINITE_TIMES );

	if( respawnMode && flRespawnDelayDefault < cvarTMAntiTrollRespawnMode.GetFloat() )
		g_EngineFuncs.CVarSetFloat( "mp_respawndelay", cvarTMAntiTrollRespawnMode.GetInt() );
}

void disableRestart()
{	
	const string strRemoveEntName = cvarTMAntiTrollRemoveEnts.GetString() != "" ? cvarTMAntiTrollRemoveEnts.GetString() : "leveldead_mm";
	const array<string> STR_REMOVE_ENTS = strRemoveEntName.Split( ";" );
	
	for( int i = g_Engine.maxClients + 1; i <= g_EngineFuncs.NumberOfEntities(); i++ )
	{
	  	CBaseEntity@ ent = g_EntityFuncs.Instance( i );
	  
	  	if( ent is null )
	    	continue;
	  
     	if (ent.pev.classname == "func_breakable" and STR_REMOVE_ENTS.find( ent.pev.target ) >= 0 or
			    STR_REMOVE_ENTS.find( ent.GetTargetname() ) >= 0 )
		{
			g_EntityFuncs.Remove(ent);
		}
	}
}

void mineRespawn(TripmineData@ dat)
{
	// check to make sure mine will attach to something
	g_EngineFuncs.MakeVectors(dat.angles);
	TraceResult tr;
	g_Utility.TraceLine( dat.pos, dat.pos - g_Engine.v_forward*16, ignore_monsters, null, tr );
	if (tr.flFraction >= 1.0)
	{
		// can't spawn in air
		return;
	}

	dat.ent = EHandle( g_EntityFuncs.Create("monster_tripmine", dat.pos, dat.angles, false) );
	dat.respawning = false;
}

void mineThink()
{
	for (uint i = 0; i < mines.length(); i++)
	{
		if (respawnMode)
		{
			// mine respawn mode
			if (!mines[i].ent and !mines[i].respawning) 
			{
				mines[i].respawning = true;
				g_Scheduler.SetTimeout("mineRespawn", 0.5, @mines[i]);
			}
		}
		else // teleport mode
		{
			if (mines[i].ent and !mines[i].respawning)
			{
				TraceResult tr;
				g_Utility.TraceLine( mines[i].pos, mines[i].pos + mines[i].dir*4096, dont_ignore_monsters, null, tr );
				if ((tr.vecEndPos - mines[i].endPos).Length() > 0.001)
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					if (pHit !is null and pHit.IsPlayer())
					{
						CBasePlayer@ plr = cast<CBasePlayer@>(pHit);
						te_explosion2(plr.pev.origin);
						g_PlayerFuncs.RespawnPlayer(plr);
					}
					
					mines[i].endPos = tr.vecEndPos;
					CBeam@ beam = cast<CBeam@>( mines[i].beam.GetEntity() );
					beam.SetEndPos(mines[i].endPos);
				}
				
				TraceResult tr2;
				g_Utility.TraceLine( mines[i].pos, mines[i].pos - mines[i].dir*16, ignore_monsters, null, tr2 );
				if (tr2.flFraction >= 1.0)
				{
					g_EntityFuncs.CreateExplosion(mines[i].pos, Vector(0,0,0), null, 150, true);
					g_EntityFuncs.Remove(mines[i].ent);
					g_EntityFuncs.Remove(mines[i].beam);
					mines[i].respawning = true; // actually not but i don't want to make another flag
				}
			}
		}
	}
}

void findTripmines()
{
	CBaseEntity@ ent = null;
	do {
		@ent = g_EntityFuncs.FindEntityByClassname(ent, "monster_tripmine"); 
		if (ent !is null)
		{
			TripmineData dat;
			dat.pos = ent.pev.origin;
			dat.angles = ent.pev.angles;
			dat.respawning = false;
			
			if (respawnMode)
				dat.ent = ent;
			else
			{
        		CSprite@ mine = g_EntityFuncs.CreateSprite( "models/v_tripmine.mdl", ent.pev.origin, false);
				mine.pev.angles = ent.pev.angles;
				mine.pev.body = 3;
				mine.pev.sequence = 7;
				dat.ent = mine;
				
				g_EngineFuncs.MakeVectors(mine.pev.angles);
				dat.dir = g_Engine.v_forward;
				
				TraceResult tr;
				g_Utility.TraceLine( mine.pev.origin, mine.pev.origin + g_Engine.v_forward*4096, ignore_monsters, null, tr );
				
				CBeam@ beam = g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 10 );
				beam.PointsInit( mine.pev.origin, tr.vecEndPos );
				beam.SetColor(0, 214, 198);
				beam.SetScrollRate(255);
				beam.SetBrightness(64);
				
				dat.beam = beam;
				dat.endPos = tr.vecEndPos;
				
				g_EntityFuncs.Remove(ent);
			}
			
			mines.insertLast(dat);
		}
	} while (ent !is null);
}
// trigger_script to disable tripmine respawns when the level is complete
void disableMineRespawn(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if( fnMineThink !is null )
    {
        g_Scheduler.RemoveTimer( fnMineThink );
        @fnMineThink = null;
    }

	respawnMode = false;

	if( flRespawnDelayDefault < cvarTMAntiTrollRespawnMode.GetFloat() )
		g_EngineFuncs.CVarSetFloat( "mp_respawndelay", flRespawnDelayDefault );
}

void te_explosion2(Vector pos, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null) { NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest); m.WriteByte(TE_EXPLOSION2); m.WriteCoord(pos.x); m.WriteCoord(pos.y); m.WriteCoord(pos.z); m.WriteByte(0); m.WriteByte(127); m.End();}

}
