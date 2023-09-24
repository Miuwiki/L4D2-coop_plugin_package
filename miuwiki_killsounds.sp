#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

#define KILL_SOUND "buttons/bell1.wav"
#define SURVIVOR_TEAM 2
#define INFECTED_TEAM 3

public Plugin myinfo =
{
	name = "[L4D2] Kill Sounds",
	author = "Miuwiki",
	description = "Play a sound to survivor when they kill a special infected.",
	version = PLUGIN_VERSION,
	url = "http://miuwiki.site"
}

public void OnPluginStart()
{
	PrecacheSound(KILL_SOUND);

	HookEvent("player_death", Event_PlayerDeath);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId( event.GetInt("userid") );
	if( client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != INFECTED_TEAM )
		return;
	
	int attacker = GetClientOfUserId( event.GetInt("attacker") );
	if( attacker < 1 || attacker > MaxClients || !IsClientInGame(attacker) || IsFakeClient(attacker) || GetClientTeam(attacker) != SURVIVOR_TEAM)
		return;
	
	EmitSoundToClient(attacker, KILL_SOUND);

}