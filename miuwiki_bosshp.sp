#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <miuwiki_serverapi>

#define PLUGIN_VERSION "1.0.0"

ConVar
    cvar_witchhp_levelmultiple,
    cvar_witchhp_addcount,
    cvar_witchhp_base,
    cvar_tankhp_levelmultiple,
    cvar_tankhp_addcount,
    cvar_tankhp_base;

int
    g_witchhp_addcount,
    g_witchhp_base,
    g_tankhp_addcount,
    g_tankhp_base;

float
    g_witchhp_levelmultiple[4],
    g_tankhp_levelmultiple[4];

Server server;

public Plugin myinfo =
{
	name = "[L4D2] Boss Hp Setting",
	author = "Miuwiki",
	description = "Set tank and witch hp base on human or level.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnPluginStart()
{
    HookEvent("tank_spawn",Event_TankSpawn);
    HookEvent("witch_spawn",Event_WitchSpawn);

    cvar_witchhp_base = CreateConVar("miuwiki_witchhp_base","8000","witch hp base.",0,true,1000.0);
    cvar_witchhp_addcount = CreateConVar("miuwiki_witchhp_addcount","0","witch hp add base on human count.",0);
    cvar_witchhp_levelmultiple = CreateConVar("miuwiki_witchhp_levelmultiple","1.0-1.0-1.0-1.0","witch hp add base on difficult. \
    start from easy, use \"-\" to separate each difficult",0);
    
    cvar_tankhp_base = CreateConVar("miuwiki_tankhp_base","20000","tank hp base.",0);
    cvar_tankhp_addcount = CreateConVar("miuwiki_tankhp_addcount","5000","tank hp add base on human count.",0);
    cvar_tankhp_levelmultiple = CreateConVar("miuwiki_tankhp_levelmultiple","1.0-1.0-1.0-1.0","tank hp add base on difficult. \
    start from easy, use \"-\" to separate each difficult",0);

    cvar_witchhp_base.AddChangeHook(Cvar_HookCallBack);
    cvar_witchhp_addcount.AddChangeHook(Cvar_HookCallBack);
    cvar_witchhp_levelmultiple.AddChangeHook(Cvar_HookCallBack);
    cvar_tankhp_levelmultiple.AddChangeHook(Cvar_HookCallBack);
    cvar_tankhp_addcount.AddChangeHook(Cvar_HookCallBack);
    cvar_tankhp_base.AddChangeHook(Cvar_HookCallBack);
}
public void OnConfigsExecuted()
{
    GetCvar();
}
void Cvar_HookCallBack(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvar();
}
void GetCvar()
{
    static char temp1[4][4],temp2[4][4],temp_witch[16],temp_tank[16];
    g_witchhp_base = cvar_witchhp_base.IntValue;
    g_witchhp_addcount = cvar_witchhp_addcount.IntValue;
    cvar_witchhp_levelmultiple.GetString(temp_witch, sizeof(temp_witch));
    
    g_tankhp_base = cvar_tankhp_base.IntValue;
    g_tankhp_addcount = cvar_tankhp_addcount.IntValue;
    cvar_tankhp_levelmultiple.GetString(temp_tank, sizeof(temp_tank));

    ExplodeString(temp_witch,"-",temp1,4,4);
    ExplodeString(temp_tank,"-",temp2,4,4);
    for(int i = 0; i < 4; i++)
    {
        g_witchhp_levelmultiple[0] = StringToFloat(temp1[0]);
        g_tankhp_levelmultiple[0] = StringToFloat(temp2[0]);
    }
}
void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId( event.GetInt( "userid" ) );
    if( client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED )
        return;
    
    int health = RoundToCeil( (g_tankhp_base + (g_tankhp_addcount * server.Human)) * g_tankhp_levelmultiple[server.Difficulty] );
    SetEntProp(client, Prop_Data, "m_iHealth", health);
    SetEntProp(client, Prop_Data, "m_iMaxHealth", health);
    PrintToChatAll("\x04[服务器]\x03 Tank \x05出现, 血量: \x04%d",health);
}
void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt( "witchid" );
    if( entity <= 0 || !IsValidEntity(entity) )
        return;

    int health = RoundToCeil( (g_witchhp_base + (g_witchhp_addcount * server.Human)) * g_witchhp_levelmultiple[server.Difficulty] );
    SetEntProp(entity, Prop_Data, "m_iHealth", health);
    SetEntProp(entity, Prop_Data, "m_iMaxHealth", health);
    PrintToChatAll("\x04[服务器]\x01Witch \x05出现, 血量: \x04%d",health);
}
