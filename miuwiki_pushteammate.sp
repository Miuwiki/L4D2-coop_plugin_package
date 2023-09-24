#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <miuwiki_serverapi>

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "[L4D2] Push Survivor Team Mate",
	author = "Miuwiki",
	description = "Survivor can push there team mate.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnPluginStart()
{
    HookEvent("player_shoved", Event_PlayerShove);
}

void Event_PlayerShove(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId( event.GetInt("userid") );
    int attacker = GetClientOfUserId( event.GetInt("attacker") );

    if( victim < 1 || !IsClientInGame(victim) || GetClientTeam(victim) != 2 )
        return;
    
    if( attacker < 1 || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2 )
        return;

    if( !IsBehindPlayer(victim,attacker) )
        return;

    L4D_StaggerPlayer(victim,attacker,NULL_VECTOR);
    PrintToChat(victim,"\x04[服务器]\x05玩家 \x01%N \x05从背后推了你一下!",attacker);
    PrintToChat(attacker,"\x04[服务器]\x05你推了 \x01%N \x05一下!",victim);
}

bool IsBehindPlayer(int victim,int attacker)
{
    float v_ang[3],a_ang[3];
    GetClientAbsAngles(victim,v_ang); // victim use abs.
    GetClientEyeAngles(attacker,a_ang);  // attacker use eye.

    // ang[0] means up and down, ang[1] means right and left.
    // usually up and down don't effect the body deeply, so we can check ang[1] to confirm someone is behind the other one or not.
    if( FloatAbs(a_ang[1] - v_ang[1]) <= 75.0 ) // 60 is too narrow and 90 is too width.
        return true;

    return false;
}
