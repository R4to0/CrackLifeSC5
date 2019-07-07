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

	array<string> TargetNames;
	array<uint> BaseHealths;

	// Set monster classname depending on map name
	if( g_Engine.mapname == "cracklife_c17" ) // Nihilanth boss
	{
		TargetNames = { "spawn_nihilanth", "crystal1", "crystal2", "crystal3" };
		BaseHealths = { int(g_EngineFuncs.CVarGetFloat( "sk_nihilanth_health" )), 1000, 1000, 1000 };
		
	}
	else if( g_Engine.mapname == "cracklife_c15" ) // Gonarch
	{
		TargetNames = { "big_momma", "goose3", "goose2", "goose1c", "goose7", "goose6", "goose7b", "goose11", "goose11b", "goose13" };
		BaseHealths = { 300, 200, 200, 200, 300, 300, 300, 250, 250, 100 };
	}
	
	// Do nothing if theres no targetname
	if( TargetNames.length() < 1 || TargetNames.length() != BaseHealths.length() ) return;
	
	for( uint i = 0; i < TargetNames.length(); i++ )
	{

		EHandle hTarget = EHandle( GetEntityPointer( TargetNames[i] ) ); // Get monster pointer

		// Trashed pointer, shutting down!
		if ( !hTarget.IsValid() )
			continue;

		// No health key, ignore
		/*if( int( hTarget.GetEntity().pev.health ) < 1 )
			continue;*/

		uint iSkill = Math.clamp( 1, 3, int( g_EngineFuncs.CVarGetFloat( "skill" ) ) ); // Get current skill level and ensure this is between 1 and 3

		uint iCurNpcHlth = BaseHealths[i];

		// NewHealth = CurrentNPCHealth x ( ( Current player count / 2 ) x Server skill level )
		uint iNewHealth = iCurNpcHlth * ( int( Math.Floor( iCurrPlrs / 2 ) ) * iSkill );

		hTarget.GetEntity().pev.health = iNewHealth;
		if( int( hTarget.GetEntity().pev.max_health ) > 1 )
			hTarget.GetEntity().pev.max_health = iNewHealth;

		//g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "DEBUG: " + TargetNames[i] + " health has been set to " + iNewHealth + " for " + iCurrPlrs + " players.\n" );
	
	}
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
