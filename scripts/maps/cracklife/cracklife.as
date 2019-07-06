// Crack-Life Stuff
#include "weapons/weapons"
#include "weapons/mappings"

// HLSP Stuff
#include "../hlsp/trigger_suitcheck"
#include "../point_checkpoint"

// Stolen from HLSPClassicMode.as
bool ShouldRunSurvivalMode( const string& in szMapName )
{
	return szMapName != "cracklife_c00"
		&& szMapName != "cracklife_c01_a1"
		&& szMapName != "cracklife_c01_a2"
		&& szMapName != "cracklife_c18";
}

void MapInit()
{
	// HLSP Stuff
	RegisterTriggerSuitcheckEntity();
	RegisterPointCheckPointEntity();
	g_EngineFuncs.CVarSetFloat( "mp_hevsuit_voice", 1 );

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
