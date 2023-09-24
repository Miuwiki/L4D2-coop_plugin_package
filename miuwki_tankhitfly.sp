#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <miuwiki_serverapi>

#define PLUGIN_VERSION "1.0"
ConVar
    cvar_tank_hit_upspeed;

float 
    g_up_speed;

bool
    g_can_show_info;

public Plugin myinfo =
{
	name = "[L4D2] Tank Hit Fly",
	author = "Miuwiki",
	description = "Tank will hit and make survivor fly.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnPluginStart()
{
    HookEvent("player_hurt",Event_PlayerHurt);
    HookEvent("tank_spawn",Event_TankSpawn);
    cvar_tank_hit_upspeed = CreateConVar("miuwiki_tank_hit_up_speed","500.0","how much force tank can hit survivor fly.",0);
    cvar_tank_hit_upspeed.AddChangeHook(Cvar_HookCallBack);
}
public void OnConfigsExecuted()
{
    g_up_speed = cvar_tank_hit_upspeed.FloatValue;
    g_can_show_info = true;
}
void Cvar_HookCallBack(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_up_speed = cvar_tank_hit_upspeed.FloatValue;
}
void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId( event.GetInt( "userid" ) );
    if( client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED )
        return;
    if( !g_can_show_info )
        return;

    PrintToChatAll("\x04[服务器]\x03 Tank \x05会将你打飞到空中,请务必远离空旷地带!");
    CreateTimer(60.0, Timer_InfoCanShowAgin,_,TIMER_FLAG_NO_MAPCHANGE);
}
Action Timer_InfoCanShowAgin(Handle timer)
{
    g_can_show_info = true;
    return Plugin_Handled;
}
void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId( event.GetInt( "userid" ) );
    if( client < 1 || client > MaxClients || !IsClientInGame(client) )
        return;

    if( GetClientTeam(client) != TEAM_INFECTED )
        return;

    //DMG_CLUB = 128(坦克拍掌跟吃饼都是)
    //tank_claw=巴掌，tank_rock是饼
    char weaponname[16];
    event.GetString("weapon", weaponname, sizeof(weaponname));
    if( client && strcmp("tank_claw", weaponname) == 0 )
    {
        float speed[3];
        speed[0] =GetEntPropFloat(client,Prop_Send,"m_vecVelocity[0]");
        speed[1] =GetEntPropFloat(client,Prop_Send,"m_vecVelocity[1]");
        speed[2] =GetEntPropFloat(client,Prop_Send,"m_vecVelocity[2]");
        speed[2] += g_up_speed;
        TeleportEntity(client,NULL_VECTOR,NULL_VECTOR,speed);
    }
}
