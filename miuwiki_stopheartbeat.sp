#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <miuwiki_serverapi>

#define PLUGIN_VERSION "1.0.0"

ConVar
    cvar_max_incappted_count;

int
    g_max_incappted_count;

#define HEART_BEAT "player/heartbeatloop.wav"

public Plugin myinfo =
{
	name = "[L4D2] Stop Heart Beat",
	author = "Miuwiki",
	description = "Stop heart beat in death door",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnMapStart()
{
    // stop heartbeat.
    HookEvent("bot_player_replace",Event_PlayerReplaceBot);

    cvar_max_incappted_count = FindConVar("survivor_max_incapacitated_count");
    cvar_max_incappted_count.AddChangeHook(Cvar_HookCallBack);
    PrecacheSound(HEART_BEAT);
}

public void OnConfigsExecuted()
{
    g_max_incappted_count = cvar_max_incappted_count.IntValue;
}
void Cvar_HookCallBack(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_max_incappted_count = cvar_max_incappted_count.IntValue;
}

void Event_PlayerReplaceBot(Event event,const char[] name,bool dontbroadcast)
{
    int client = GetClientOfUserId( event.GetInt("player") );
    if( client < 1 || client > MaxClients || !IsClientInGame(client) )
        return;

    if( g_max_incappted_count != 0 )
        return;
        
    // stop heartbeat.
    StopSound(client, SNDCHAN_STATIC, HEART_BEAT);
    StopSound(client, SNDCHAN_STATIC, HEART_BEAT);
    StopSound(client, SNDCHAN_STATIC, HEART_BEAT);
    StopSound(client, SNDCHAN_STATIC, HEART_BEAT);
}

