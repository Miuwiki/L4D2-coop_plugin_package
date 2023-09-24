#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =    
{
    name = "[L4D2] Test Team",   
	author = "Miuwiki",   
	description = "Test Team",   
	version = PLUGIN_VERSION,   
	url = "https://miuwiki.site"  
}

public void OnPluginStart()
{
    AddCommandListener(CMDLienter_Callback,"jointeam");
}

Action CMDLienter_Callback(int client, const char[] command, int argc)
{
    if( !IsValidClient(client) || IsFakeClient(client) )
        return Plugin_Continue;
    PrintToServer("%N is changing to %d",client, GetCmdArgInt(1));
    return Plugin_Continue;
}


bool IsValidClient(int client)
{
    if( client < 1 || client > MaxClients || !IsClientInGame(client) )
        return false;
    
    return true;
}