/*
* This file replaces all map scripts for hl_c11_a3.
* It's a combination of HLSP.as and hl_c11_a3.as
* that also includes a rework of the tripmines to prevent trolling
*  -w00tguy
*/

// HLSP Stuff
#include "../point_checkpoint"

// Crack-Life Stuff
#include "weapons/weapons"
#include "weapons/mappings"

// Survival
#include "survmode"

void MapEnded( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	if ( g_SurvivalMode.IsEnabled() )
	{
		g_SurvivalMode.EndRound();
	}
	else
	{
		g_EntityFuncs.FireTargets( "leveldead_loadsaved", pActivator, pCaller, USE_TOGGLE );
	}
}

void MapInit()
{
	g_EngineFuncs.CVarSetFloat( "mp_hevsuit_voice", 1 );
	RegisterPointCheckPointEntity();

	//Crack-Life
	RegisterCrackLifeWeapons();

	// Initialize classic mode (item mapping only)
	g_ClassicMode.SetItemMappings( @g_ItemMappings );
	g_ClassicMode.ForceItemRemap( true );

	// Map support is enabled here by default.
	// So you don't have to add "mp_survival_supported 1" to the map config
	if( ShouldRunSurvivalMode( g_Engine.mapname ) )
		g_SurvivalMode.EnableMapSupport();
}


// Everything below here is for fixing the tripmine level

void MapActivate()
{
	disableRestart();
	findTripmines();
	g_Scheduler.SetInterval("mineThink", 0.0);
}

bool respawnMode = false;

void print(string text) { g_Game.AlertMessage( at_console, text); }
void println(string text) { print(text + "\n"); }

void te_explosion2(Vector pos, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null) { NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest); m.WriteByte(TE_EXPLOSION2); m.WriteCoord(pos.x); m.WriteCoord(pos.y); m.WriteCoord(pos.z); m.WriteByte(0); m.WriteByte(127); m.End();}
void te_beampoints(Vector start, Vector end, string sprite="sprites/laserbeam.spr", uint8 frameStart=0, uint8 frameRate=100, uint8 life=1, uint8 width=2, uint8 noise=0, Color c=GREEN, uint8 scroll=32, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null) { NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);m.WriteByte(TE_BEAMPOINTS);m.WriteCoord(start.x);m.WriteCoord(start.y);m.WriteCoord(start.z);m.WriteCoord(end.x);m.WriteCoord(end.y);m.WriteCoord(end.z);m.WriteShort(g_EngineFuncs.ModelIndex(sprite));m.WriteByte(frameStart);m.WriteByte(frameRate);m.WriteByte(life);m.WriteByte(width);m.WriteByte(noise);m.WriteByte(c.r);m.WriteByte(c.g);m.WriteByte(c.b);m.WriteByte(c.a);m.WriteByte(scroll);m.End(); }

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

void disableRestart()
{	
	CBaseEntity@ent = null;
	do {
		@ent = g_EntityFuncs.FindEntityByClassname(ent, "*"); 
		if (ent !is null)
		{
			if (ent.pev.classname == "func_breakable" and ent.pev.target == "leveldead_mm" or
			    ent.pev.targetname == "leveldead_mm")
			{
				g_EntityFuncs.Remove(ent);
			}
		}
	} while (ent !is null);
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
	
	CBaseEntity@ ent = g_EntityFuncs.Create("monster_tripmine", dat.pos, dat.angles, false);
	dat.ent = ent;
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
				//te_beampoints(mines[i].pos, mines[i].endPos);
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
					CBaseEntity@ beamEnt = mines[i].beam;
					CBeam@ beam = cast<CBeam@>(beamEnt);
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
				dictionary keys;
				keys["origin"] = ent.pev.origin.ToString();
				keys["model"] = "models/v_tripmine.mdl";
					
				CBaseEntity@ mine = g_EntityFuncs.CreateEntity("env_sprite", keys, true);
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

class Color
{ 
	uint8 r, g, b, a;
	Color() { r = g = b = a = 0; }
	Color(uint8 r, uint8 g, uint8 b) { this.r = r; this.g = g; this.b = b; this.a = 255; }
	Color(uint8 r, uint8 g, uint8 b, uint8 a) { this.r = r; this.g = g; this.b = b; this.a = a; }
	Color(float r, float g, float b, float a) { this.r = uint8(r); this.g = uint8(g); this.b = uint8(b); this.a = uint8(a); }
	Color (Vector v) { this.r = uint8(v.x); this.g = uint8(v.y); this.b = uint8(v.z); this.a = 255; }
	string ToString() { return "" + r + " " + g + " " + b + " " + a; }
	Vector getRGB() { return Vector(r, g, b); }
}

Color RED    = Color(255,0,0);
Color GREEN  = Color(0,255,0);
Color BLUE   = Color(0,0,255);
Color YELLOW = Color(255,255,0);
Color ORANGE = Color(255,127,0);
Color PURPLE = Color(127,0,255);
Color PINK   = Color(255,0,127);
Color TEAL   = Color(0,255,255);
Color WHITE  = Color(255,255,255);
Color BLACK  = Color(0,0,0);
Color GRAY  = Color(127,127,127);