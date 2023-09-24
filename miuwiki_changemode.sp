#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define LINUX "@_ZN9CDirector11GetGameModeEv"
#define GAME_DATA "l4d2_gamemode"
#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "[L4D2] Modify The Game Mode",
	author = "Miuwiki",
	description = "Modify the game mode",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnPluginStart()
{
    LoadGameData();
}

public void OnMapStart()
{

}

void LoadGameData()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAME_DATA);
    if(FileExists(sPath) == false)
        SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

    GameData hGameData = new GameData(GAME_DATA);
    if(hGameData == null) 
        SetFailState("Failed to load \"%s.txt\" gamedata.", GAME_DATA);
        
    Handle hDetour_ChangeGamemode;
    hDetour_ChangeGamemode = DHookCreateFromConf(hGameData, "CDirector::GetGameMode");
    if(!hDetour_ChangeGamemode)
        SetFailState("Failed to find 'CDirector::GetGameMode' signature");

    if(!DHookEnableDetour(hDetour_ChangeGamemode, false, OnGetGameModeHook))
        SetFailState("Failed to detour 'CDirector::GetGameMode'");
}

public MRESReturn OnGetGameModeHook(DHookReturn hReturn)
{
    static char temp[64];
    hReturn.GetString(temp,sizeof(temp));
    PrintToServer("fire GetGameMode(), %s, time = %f", temp, GetGameTime());
    // hReturn.SetString("my gamemode");
    return MRES_Ignored;
}
