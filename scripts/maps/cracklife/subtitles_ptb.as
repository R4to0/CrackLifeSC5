// Generic Subtitle System
// Author: Rafael "R4to0" Alves

// Map: Crack-Life
// Language: PORTUGUESE BRAZIL
// Subtitle Author(s):
// Akira

// Revision:
// R4to0
// Tayklor

namespace SUBTITLES
{

array<array<string>> SubtitleData =
{
	{ // c0a0_tr_gmorn.wav
		"Bom dia bichinha e bem-vindo a Black Mesa,\num lugar que fica na puta que pariu",
		"e ninguem aqui e uma pessoa normal, exceto eu."
	},

	{ // c0a0_tr_time.wav
		"Serio, todo mundo e um retardado mental\ne come a propria bunda.",
		"Eu nao acredito que quer trabalhar aqui,\nvoce realmente e uma bichinha suicida, ne?"
	},

	{ // c0a0_tr_dest.wav
		"A maioria do pessoal aqui tem algo chamado Nivel de Liberacao.",
		"se voce nao tem um, os segurancas\nirao ter o direito de atirar em voce",
		"e jogar seu corpo no armario de alguem.",
		"Entao espero que tenha um, porque eu nao quero\nminha instalacao fedendo a bosta encardida."
	},

	{ // c0a0_tr_noeat.wav
		"Ja que vomitar no trem faz as pessoas gritarem\nem voce e ficarem bravas, nos criamos uma regra rigorosa:",
		"Sem comer.",
		"E nem pense em fumar, ou beber."
	},

	{ // c0a0_tr_emerg.wav
		"De qualquer forma, ja que quem trabalha aqui e um\nbando debando de pretos retardados, nos fizemos uma regra que diz:",
		"Nao va para fora da janela.",
		"Dezenove pessoas por ano morrem fazendo isso,\ne ainda estamos contando."
	},

	{ // c0a0_tr_tourn.wav
		"Mas de qualquer forma, voces todos\nchupam uma rola grande, e eu sou o chefe.",
		"Eu nao sei mais o que dizer ja que eu falei\num monte de informacao bosta que ninguem se importa."
	},

	{ // c0a0_tr_jobs.wav
		"Aqui na Black Mesa nos fazemos certeza que tratamos\ntodos os empregados da mesma forma que outros,",
		"o que significa que podem ir tomar no meio do cu.",
		"Se voce tem amigos, parentes ou irmas gostosas,",
		"por favor traga eles aqui para que possamos lentamente\nqueima-los no acido para testar nossos trajes de protecao.",
		"Sim, o mesmo que voce ira vestir.",
		"[Risos]"
	},

	{ // c0a0_tr_haz.wav
		"Ah eu tenho uma ideia.",
		"Por que nao vai se divertir pulando naquela gosma verde estranha,\nela claramente nao e radioativa e perigosa para a sua saude.",
		"E serio,",
		"nos fazemos festas la e bebemos aquilo todo dia,\nja que e limpo e saudavel para a vida humana,",
		"se, por acaso, algo lhe faca se sentir doente,",
		"lhe daremos essa arma com apenas uma bala,\nnem mesmo um viado com deficiencia vai errar.",
		"Sim, estou falando sobre tornar-se um heroi."
	},

	{ // c0a0_tr_arrive.wav
		"Proxima parada: Terra dos Viadinhos.",
		"soi soi",
		"Ou, como os idiotas no QG chamam:\nSetor C.",
		"O C significa cancer."
	},

	{ // c0a0_tr_exit.wav
		"Agora espere algumas horas ate esse\nsoldado russo gordo chegar.",
		"Apenas tome em mente que ele nao fala Ingles,\nentao nao faca contato com ele.",
		"Ah. Caralho, finalmente.",
		"Agora eu nao tenho que olhar pra essa sua cara feia."
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

/**
*	Purpose: Display messages with a determined parameters.
*	@param strText Text to display
*	@param flHoldTime Time to hold the message on screen
*/
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

/**
*	Purpose: Select messages and timers from array.
*	It does nothing if g_bSubtitles is false.
*	@param iPosition Array index
*/
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