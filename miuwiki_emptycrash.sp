#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "[L4D2] Empty Crash",
	author = "Miuwiki",
	description = "Let server crash to reboot when empty.",
	version = PLUGIN_VERSION,
	url = "http://miuwiki.site"
}

public void OnPluginStart()
{
    HookEvent("player_disconnect", Event_PlayerDisconcet);
}

void Event_PlayerDisconcet(Event event, const char[] name, bool dontBroadcast)
{
    /**
     * Player disconnected caused by map_transition or map change fire this event.
     * This event is faster than OnClientDisconnect.
     * Base on that, player who called this event show him exit the server and will not reconnected automatically like map change.
     */
    int client = GetClientOfUserId( event.GetInt("userid") );
    if( client < 1 || client > MaxClients || IsFakeClient(client) )
        return;
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if( i == client )
            continue;

        if( IsClientConnected(i)  && !IsFakeClient(i) )
            return;
    }

    CrashSever();
}

void CrashSever()
{
    char message[128];
    FormatTime(message, sizeof(message), "%F %X - Empry Crash Server", GetTime());
    LogMessage(message);
    SetCommandFlags("crash", GetCommandFlags("crash") &~ FCVAR_CHEAT);
    ServerCommand("crash");
    SetCommandFlags("sv_crash", GetCommandFlags("sv_crash") &~ FCVAR_CHEAT);
    ServerCommand("sv_crash");
}