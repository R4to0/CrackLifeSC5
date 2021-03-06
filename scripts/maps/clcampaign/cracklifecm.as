// Crack-Life Stuff
#include "../cracklife/weapons/weapon_clmp5"
#include "../cracklife/weapons/weapon_clcrowbar"
#include "../cracklife/weapons/weapon_clglock"
#include "../cracklife/weapons/weapon_clshotgun"
#include "../cracklife/weapons/weapon_clpython"
#include "../cracklife/weapons/weapon_clhornetgun"
#include "../cracklife/weapons/weapon_clgauss"

// Crack-Life mode.
// True: Original
// False: Campaign Mode
const bool g_bCrackLifeMode = false;

// inb4 mapping for unused weapons
array<ItemMapping@> g_ItemMappings =
{
	ItemMapping( "weapon_357",              CLPYTHON::GetName() ),
	ItemMapping( "weapon_9mmAR",            CLMP5::GetName() ),
	ItemMapping( "weapon_9mmhandgun",       CLGLOCK::GetName() ),
	ItemMapping( "weapon_crowbar",          CLCROWBAR::GetName() ),
	ItemMapping( "weapon_displacer",        "weapon_rpg" ),
	ItemMapping( "weapon_eagle",            CLPYTHON::GetName() ),
	ItemMapping( "weapon_gauss",            CLGAUSS::GetName() ),
	ItemMapping( "weapon_glock",            CLGLOCK::GetName() ),
	ItemMapping( "weapon_grapple",          CLCROWBAR::GetName() ),
	ItemMapping( "weapon_hornetgun",        CLHORNETGUN::GetName() ),
	ItemMapping( "weapon_m16",              CLMP5::GetName() ),
	ItemMapping( "weapon_m249",             CLMP5::GetName() ),
	ItemMapping( "weapon_minigun",          CLMP5::GetName() ),
	ItemMapping( "weapon_pipewrench",       CLCROWBAR::GetName() ),
	ItemMapping( "weapon_python",           CLPYTHON::GetName() ),
	ItemMapping( "weapon_shockrifle",       CLMP5::GetName() ),
	ItemMapping( "weapon_shotgun",          CLSHOTGUN::GetName() ),
	ItemMapping( "weapon_sniperrifle",      "weapon_crossbow" ),
	ItemMapping( "weapon_sporelauncher",    "weapon_rpg" ),
	ItemMapping( "weapon_uzi",              CLMP5::GetName() ),
	ItemMapping( "weapon_uziakimbo",        CLMP5::GetName() )
};

void MapInit() {

	//Crack-Life
	CLMP5::Register();          // Crack Life MP5
	CLCROWBAR::Register();      // Crack Life punchs
	CLGLOCK::Register();        // Penis gun
	CLSHOTGUN::Register();      // centered shotgun
	CLPYTHON::Register();       // POW! 357
	CLHORNETGUN::Register();    // SPONSORED BY DORITOS
    CLGAUSS::Register();		// walk in the dinosaur

	// Initialize classic mode (item mapping only)
	g_ClassicMode.SetItemMappings( @g_ItemMappings );
	g_ClassicMode.ForceItemRemap( true );

}
