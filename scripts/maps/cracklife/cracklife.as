// Crack-Life Stuff
#include "weapons/weapons"
#include "weapons/mappings"
#include "utils/adjhealth"
#include "logo"

// HLSP Stuff
#include "hlsp/trigger_suitcheck"

void MapInit()
{
	// HLSP Stuff
	RegisterTriggerSuitcheckEntity();
	g_EngineFuncs.CVarSetFloat( "mp_hevsuit_voice", 1 );

	//Crack-Life
	RegisterCrackLifeWeapons();

	// Initialize classic mode (item mapping only)
	g_ClassicMode.SetItemMappings( @g_ItemMappings );
	g_ClassicMode.ForceItemRemap( true );
}
