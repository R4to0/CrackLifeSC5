// Crack-Life Stuff
#include "weapons/weapon_clmp5"
#include "weapons/weapon_clcrowbar"
#include "weapons/weapon_clglock"
#include "weapons/weapon_clshotgun"
#include "weapons/weapon_clpython"
#include "weapons/weapon_clhornetgun"

// HLSP Stuff
#include "hlsp/trigger_suitcheck"

// inb4 mapping for unused weapons
array<ItemMapping@> g_ItemMappings =
{
	ItemMapping( "weapon_357",		CLPYTHON::GetName() ),
	ItemMapping( "weapon_9mmAR",		CLMP5::GetName() ),
	ItemMapping( "weapon_9mmhandgun",	CLGLOCK::GetName() ),
	ItemMapping( "weapon_crowbar",		GetCLCrowbarName() ),
	ItemMapping( "weapon_displacer",	"weapon_rpg" ),
	ItemMapping( "weapon_eagle",		CLPYTHON::GetName() ),
	//ItemMapping( "weapon_gauss",		CLGAUSS::GetName() ),
	ItemMapping( "weapon_glock",		CLGLOCK::GetName() ),
	ItemMapping( "weapon_grapple",		GetCLCrowbarName() ),
	ItemMapping( "weapon_hornetgun",	CLHORNETGUN::GetName() ),
	ItemMapping( "weapon_m16",		CLMP5::GetName() ),
	ItemMapping( "weapon_m249",		CLMP5::GetName() ),
	ItemMapping( "weapon_minigun",		CLMP5::GetName() ),
	ItemMapping( "weapon_pipewrench",	GetCLCrowbarName() ),
	ItemMapping( "weapon_python",		CLPYTHON::GetName() ),
	ItemMapping( "weapon_shockrifle",	CLMP5::GetName() ),
	ItemMapping( "weapon_shotgun",		CLSHOTGUN::GetName() ),
	ItemMapping( "weapon_sniperrifle",	"weapon_crossbow" ),
	ItemMapping( "weapon_sporelauncher",	"weapon_rpg" ),
	ItemMapping( "weapon_uzi",		CLMP5::GetName() ),
	ItemMapping( "weapon_uziakimbo",	CLMP5::GetName() )
};

void MapInit() {

	// HLSP Stuff
	RegisterTriggerSuitcheckEntity();
	g_EngineFuncs.CVarSetFloat( "mp_hevsuit_voice", 1 );

	//Crack-Life
	CLMP5::Register(); // Crack Life MP5
	RegisterCLCrowbar(); // Crack Life punchs
	CLGLOCK::Register(); // Penis gun
	CLSHOTGUN::Register(); // shotgun
	CLPYTHON::Register(); // POW! 357
	CLHORNETGUN::Register(); // JOJ

	// Initialize classic mode (item mapping only)
	g_ClassicMode.SetItemMappings( @g_ItemMappings );
	g_ClassicMode.ForceItemRemap( true );

}
