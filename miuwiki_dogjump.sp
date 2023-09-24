#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0.0"
#define DOG_JUMP_VEL -20.0
#define AUTO_JUMP_TIME 0.05

bool g_player_jumping[MAXPLAYERS + 1];
bool g_player_autojump[MAXPLAYERS + 1];
float g_player_jumptime[MAXPLAYERS + 1];


public Plugin myinfo =    
{
    name = "[L4D2] Dog Jump Like cs1.6",   
	author = "Miuwiki",   
	description = "Make survivor can dog jump",   
	version = PLUGIN_VERSION,   
	url = "https://miuwiki.site"  
}

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
    RegConsoleCmd("sm_dj",Cmd_DogJumpCallBack);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for(int i = 0; i <= MAXPLAYERS; i++)
    {
        g_player_jumping[i] = false;
        g_player_autojump[i] = false;
        g_player_jumptime[i] = 0.0;
    }
}

public void OnClientPutInServer(int client)
{
    if( IsFakeClient(client) )
        return;
    
    PrintToChat(client, "\x04[Dog Jump]\x05跳跃中按下蹲键即可狗跳, 使用 \x04!dj \x05开启或关闭自动狗跳");
    SDKHook(client, SDKHook_PostThink, SDK_PTCallback);
    SDKHook(client, SDKHook_PostThinkPost, SDK_PTPCallback);
}

void SDK_PTCallback(int client)
{
    static int jump[MAXPLAYERS + 1];
    if( !IsValidClient(client) || IsFakeClient(client) )
        return;
    
    int temp = GetEntProp(client, Prop_Send, "m_duckUntilOnGround");
    if( jump[client] == temp )
        return;
    
    jump[client] = temp;
    if( temp == 1 )
    {
        g_player_jumping[client] = true;
        g_player_jumptime[client] = GetEngineTime();
    }
        
    else if( IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity")) )
        g_player_jumping[client] = false;
}
void SDK_PTPCallback(int client)
{
    if( !IsValidClient(client) || IsFakeClient(client) )
        return;
    
    if( !g_player_jumping[client] )
        return;

    if( g_player_autojump[client] && GetEngineTime() - g_player_jumptime[client] >= AUTO_JUMP_TIME )
    {
        float vel[3];
        vel[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
        vel[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
        vel[2] = DOG_JUMP_VEL;
        TeleportEntity(client, NULL_VECTOR,NULL_VECTOR,vel);
        g_player_jumping[client] = false;
        return;
    }

    if( GetClientButtons(client) & IN_DUCK )
    {
        float vel[3];
        vel[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
        vel[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
        vel[2] = DOG_JUMP_VEL;
        TeleportEntity(client, NULL_VECTOR,NULL_VECTOR,vel);
        g_player_jumping[client] = false;
    }
}

Action Cmd_DogJumpCallBack(int client, int args)
{
    if( !IsValidClient(client) || IsFakeClient(client) || GetClientTeam(client) != 2 )
        return Plugin_Handled;
    
    if( g_player_autojump[client] )
    {
        g_player_autojump[client] = false;
        PrintToChat(client, "\x03你关闭了自动狗跳");
    }
    else
    {
        g_player_autojump[client] = true;
        PrintToChat(client, "\x03你开启了自动狗跳");
    }
    return Plugin_Handled;
}

bool IsValidClient(int client)
{
    if( client < 1 || client > MaxClients || !IsClientInGame(client) )
        return false;
    
    return true;
}