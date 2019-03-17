#include "weapon_clmp5"
#include "weapon_clcrowbar"
#include "weapon_clglock"
#include "weapon_clshotgun"
#include "weapon_clpython"
#include "weapon_clhornetgun"
#include "weapon_clgauss"

// Crack-Life mode.
// True: Original
// False: Campaign Mode
const bool g_bCrackLifeMode = true;

// Weapon behaviour/mode (bIsMultiplayer function)
// Like the singleplayer/multiplayer differences in vanilla HL
// True: Multiplayer
// False: Singleplayer
const bool g_WeaponMode = false;

void RegisterCrackLifeWeapons()
{
	// Weapon slots ans positions
	CLMP5::g_Slot				= 2;
	CLMP5::g_Position			= 4;

	CLCROWBAR::g_Slot			= 0;
	CLCROWBAR::g_Position		= 5;

	CLGLOCK::g_Slot				= 1;
	CLGLOCK::g_Position			= 4;

	CLSHOTGUN::g_Slot			= 2;
	CLSHOTGUN::g_Position		= 5;

	CLPYTHON::g_Slot			= 1;
	CLPYTHON::g_Position		= 5;

	CLHORNETGUN::g_Slot			= 3;
	CLHORNETGUN::g_Position		= 4;

	CLGAUSS::g_Slot				= 3;
	CLGAUSS::g_Position			= 5;

	CLMP5::Register();			// Crack Life MP5
	CLCROWBAR::Register();		// Crack Life punchs
	CLGLOCK::Register();		// Penis gun
	CLSHOTGUN::Register();		// shotgun
	CLPYTHON::Register();		// POW! 357
	CLHORNETGUN::Register();	// JOJ
	CLGAUSS::Register();		// walk in the dinosaur
}