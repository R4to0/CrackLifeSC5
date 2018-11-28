void ShowCrackLogo( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	HUDSpriteParams params;
	
	params.channel = 4;
	params.flags = HUD_ELEM_SCR_CENTER_X;
	params.spritename = "cracklife/logo.spr";
	params.x = 0;
	params.y = 0.48;
	params.frame = 0;
	params.numframes = 1;
	params.framerate = 0.0;
	params.fadeinTime = 0.3;
	params.holdTime = 3.0;
	params.fadeoutTime = 1.5;
	//params.color1 = RGBA( 255, 255, 255, 255 );
	params.color1 = RGBA_WHITE;
	
	g_PlayerFuncs.HudCustomSprite( null, params );
}