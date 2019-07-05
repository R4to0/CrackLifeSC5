// Crack-Life Stuff
#include "weapons/weapons"
#include "weapons/mappings"
#include "utils/adjhealth"

// HLSP Stuff
#include "../hlsp/trigger_suitcheck"
#include "../point_checkpoint"

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
	g_SurvivalMode.EnableMapSupport();
}
