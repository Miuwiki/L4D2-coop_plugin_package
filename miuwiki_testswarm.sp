#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#define PLUGIN_VERSION "1.0.0"
#define GAME_INFO "swarm"

public Plugin myinfo =
{
	name = "[L4D2] Test swarm",
	author = "Miuwiki",
	description = "Test sawrm.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnPluginStart()
{
    LoadGameData();
}

void LoadGameData()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAME_INFO);

    if(FileExists(sPath) == false) 
        SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

    GameData hGameData = new GameData(GAME_INFO);
    if(hGameData == null) 
        SetFailState("Failed to load \"%s.txt\" gamedata.", GAME_INFO);


    Handle hDetour_Swarm = DHookCreateFromConf(hGameData, "CInsectSwarm::CanHarm");

    if(!hDetour_Swarm)
        SetFailState("Failed to find 'CInsectSwarm::CanHarm' signature");

    if(!DHookEnableDetour(hDetour_Swarm, true, OnWitchHitByVomitjar))
        SetFailState("Failed to detour 'CInsectSwarm::CanHarm'");
}
MRESReturn OnWitchHitByVomitjar(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    int client = hParams.Get(1);
    if( client < 31 )
        PrintToChatAll(" %d in swarm.", client);
    return MRES_Ignored;
}