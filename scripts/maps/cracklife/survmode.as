// Stolen from HLSPClassicMode.as
bool ShouldRunSurvivalMode( const string& in szMapName )
{
	return szMapName != "cracklife_c00"
		&& szMapName != "cracklife_c01_a1"
		&& szMapName != "cracklife_c01_a2"
		&& szMapName != "cracklife_c18";
}