// Generic Subtitle System
// Author: Rafael "R4to0" Alves

// Map: Crack-Life
// Language: ENGLISH
// Subtitle Author(s):
// R4to0
// DNIO071
// KernCore

namespace SUBTITLES
{

array<array<string>> SubtitleData =
{
	{ // c0a0_tr_gmorn.wav
		"Good morning fagget and welcome to Black Mesa,\na place in the middle of fucking nowhere",
		"and nobody in here is a normal person\n except me."
	},

	{ // c0a0_tr_time.wav
		"Seriously, everybody is a fucking retard and a freak.",
		"I can't believe you want to work here,\nyou really are a suicidal faggot, are you?"
	},

	{ // c0a0_tr_dest.wav
		"Most people here have a thing called Clearance Level.",
		"If you do not have one, the security guards\nwill have the right to shoot you",
		"and dump your body into someone's closet.",
		"So I hope you have one, because I don't want\nmy facility smelling like rotting shit."
	},

	{ // c0a0_tr_noeat.wav
		"Since barfing in the train causes people to yell\nat you and get mad, we have made a strict rule:",
		"No eating.",
		"And don't even think about smoking, or drinking.",
	},

	{ // c0a0_tr_emerg.wav
		"Anyway, since people working here are a bunch of\nretarded niggers, we had to make a rule stating:",
		"No peeking out of the window.",
		"Nineteen people a year die by doing that,\nand we're still counting."
	},

	{ // c0a0_tr_tourn.wav
		"So anyway, you all suck a huge dick, and I am the boss.",
		"I don't fucking know what to say now since I gave out a\nabunch of shitty information that nobody cares about."
	},

	{ // c0a0_tr_jobs.wav
		"Here at Black Mesa we make sure all employees\nget the same treatment as others,",
		"which means they can go fuck themselves.",
		"If you have any friends, relatives or sexy sisters,",
		"please bring them over so we can slowly burn them\nin acid to test our new hazard suits.",
		"Yes, the one you're going to wear.",
		"[Laughing]"
	},

	{ // c0a0_tr_haz.wav
		"Oh I have an idea.",
		"Why not having fun by jumping into thatgreen strange goo,\nit's not radioactive and dangerous to your health at all.",
		"I am serious,",
		"we have parties in there and we drink it all day,\nsince it's clean and healthy for human life,",
		"if, however, something makes you feel sick,",
		"you are handled with this gun and only one bullet,\nnot even a disabled faggot will miss it.",
		"Yes, I am talking about becoming a hero."
	},

	{ // c0a0_tr_arrive.wav
		"Next stop: Faggot Land.",
		"soi soi",
		"Or, as the faggots at the HQ call it:\nSector C.",
		"The C stands for cancer."
	},

	{ // c0a0_tr_exit.wav
		"Now wait a few hours for that fat spetsnaz soldier to arrive.",
		"Just keep in mind that he doesn't speak English,\nso avoid any contact with him.",
		"Ah. Fucking finally.",
		"Now I don't have to look at your ugly face."
	}
	
};

// Timers for each line

array<array<float>> StartAt =
{
	{ 0.0f, 5.767f }, // c0a0_tr_gmorn.wav
	{ 0.0f, 4.014f }, // c0a0_tr_time.wav
	{ 0.0f, 3.065f, 7.277f, 9.888f }, // c0a0_tr_dest.wav
	{ 0.0f, 5.670f, 6.678f }, // c0a0_tr_noeat.wav
	{ 0.189f, 5.781f, 7.595f }, // c0a0_tr_emerg.wav
	{ 0.0f, 4.733f }, // c0a0_tr_tourn.wav
	{ 0.0f, 4.870, 7.539f, 10.834f, 16.301f, 18.610f }, // c0a0_tr_jobs.wav
	{ 0.0f, 1.764f, 9.112f, 10.424f, 15.828f, 18.667f, 24.081f }, // c0a0_tr_haz.wav
	{ 0.0f, 1.909f, 2.879f, 7.303f }, // c0a0_tr_arrive.wav
	{ 0.0f, 4.148f, 9.545f, 11.619f } // c0a0_tr_exit.wav
};

array<array<float>> Duration =
{
	{ 5.720f, 3.720f }, // c0a0_tr_gmorn.wav
	{ 3.951f, 5.512f }, // c0a0_tr_time.wav
	{ 2.926f, 4.162f, 2.384f, 4.906f }, // c0a0_tr_dest.wav
	{ 5.567f, 0.959f, 3.038f }, // c0a0_tr_noeat.wav
	{ 5.562f, 1.764f, 4.326f }, // c0a0_tr_emerg.wav
	{ 4.645f, 6.735f }, // c0a0_tr_tourn.wav
	{ 4.820f, 2.489f, 3.208f, 5.302f, 2.173f, 3.086f }, // c0a0_tr_jobs.wav
	{ 1.538f, 7.258f, 1.198f, 5.336f, 2.759f, 5.223f , 3.075f }, // c0a0_tr_haz.wav
	{ 1.855f, 0.900f, 4.292f, 1.979f }, // c0a0_tr_arrive.wav
	{ 4.039f, 5.264f, 1.916f, 2.887f } // c0a0_tr_exit.wav
};

void ShowSubtitle( string strText, float flHoldTime )
{
	HUDTextParams txtParam;

	txtParam.x = -1;
	txtParam.y = 0.8;
	txtParam.effect = 0;

	// Text colour
	txtParam.r1 = 255;
	txtParam.g1 = 255;
	txtParam.b1 = 255;
	txtParam.a1 = 255;

	// Fade-in colour
	txtParam.r2 = 255;
	txtParam.g2 = 255;
	txtParam.b2 = 255;
	txtParam.a2 = 255;
	
	txtParam.fadeinTime = 0.0f;
	txtParam.fadeoutTime = 0.0f;
	txtParam.holdTime = flHoldTime;
	txtParam.fxTime = 0.0f;
	txtParam.channel = 0;
	
	g_PlayerFuncs.HudMessageAll( txtParam, strText );
}

void SelMessages( uint iPosition )
{
	if( g_bSubtitles )
	{
		for( uint i = 0; i < SubtitleData[iPosition].length; i++ )
		{
			g_Scheduler.SetTimeout( "ShowSubtitle", StartAt[iPosition][i], SubtitleData[iPosition][i], Duration[iPosition][i]  );
		}
	}
}

// Called by trigger_script

void c0a0_tr_gmorn( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	SelMessages( 0 );
}

void c0a0_tr_time( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	SelMessages( 1 );
}

void c0a0_tr_dest( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	SelMessages( 2 );
}

void c0a0_tr_noeat( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	SelMessages( 3 );
}

void c0a0_tr_emerg( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	SelMessages( 4 );
}

void c0a0_tr_tourn( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	SelMessages( 5 );
}

void c0a0_tr_jobs( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	SelMessages( 6 );
}

void c0a0_tr_haz( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	SelMessages( 7 );
}

void c0a0_tr_arrive( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	SelMessages( 8 );
}

void c0a0_tr_exit( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	SelMessages( 9 );
}

} // End of namespace