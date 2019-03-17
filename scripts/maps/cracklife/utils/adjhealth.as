// Simple script to adjust monster health based on player count.

const bool g_BossHlthMultpEnabled = true; // Enable or disable

// Called by trigger_script
void SetBossHealth( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	// Get current player count
	uint iCurrPlrs = g_PlayerFuncs.GetNumPlayers();

	// If disabled or 1 player or less, don't do anything
	if( !g_BossHlthMultpEnabled || iCurrPlrs <= 1 )
		return;

	string szTargetName;

	// Set monster classname depending on map name
	if( g_Engine.mapname == "cracklife_c17" )
	{
		szTargetName = "spawn_nihilanth";
	}
	/*else if( g_Engine.mapname == "cracklife_c15" )
	{
		szTargetName = "monster_bigmomma";
	}*/

	EHandle hTarget = EHandle( GetEntityPointer( szTargetName ) ); // Get monster pointer

	// Trashed pointer, shutting down!
	if ( !hTarget.IsValid() )
		return;

	uint iSkill = Math.clamp( 1, 3, int( g_EngineFuncs.CVarGetFloat( "skill" ) ) ); // Get current skill level and ensure this is between 1 and 3

	//uint iCurNpcHlth = int( hTarget.GetEntity().pev.health ); // Get monster health
	uint iCurNpcHlth = int( g_EngineFuncs.CVarGetFloat( "sk_nihilanth_health" ) );

	// NewHealth = CurrentNPCHealth x ( Current player count x Server skill level )
	uint iNewHealth = iCurNpcHlth * ( iCurrPlrs * iSkill );

	//hTarget.GetEntity().pev.max_health = iNewHealth; 
	hTarget.GetEntity().pev.health = iNewHealth;

	//g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "DEBUG: " + szTargetName + " health has been set to " + iNewHealth + " for " + iCurrPlrs + " players.\n" );
}

CBaseEntity@ GetEntityPointer( string szTargetname )
{
	CBaseEntity@ pEntity = null;

	while( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, szTargetname ) ) !is null )
	{
		if ( pEntity is null )
			continue;

		return pEntity;
	}

	//g_Game.AlertMessage( at_console, "DEBUG: targetname not found \n" );

	return pEntity;
}
