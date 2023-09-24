#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "Sever step info",
	author = "Miuwiki",
	description = "Hook sever when it call some func like OnMapSter/End etc...",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnPluginStart()
{
    PrintToServer("[server_info_hook]: OnPluginStart() Gametime:%f==========",GetGameTime());
    HookEvent("round_start",Event_RoundStartInfo);
    HookEvent("round_end",Event_RoundEndInfo);
   
    HookEvent("map_transition",Event_MapTransitionInfo);
    HookEvent("finale_start",Event_FinalStartInfo);
    HookEvent("finale_win",Event_FinalWinInfo);
    HookEvent("finale_vehicle_leaving",Event_FinalVehicleLeavingInfo);

    HookEvent("player_team",Event_PlayerTeamInfo);
    HookEvent("player_spawn",Event_PlayerSpawnInfo);
    HookEvent("player_bot_replace",Event_PlayerBotReplaceInfo);
    HookEvent("bot_player_replace",Event_BotPlayerReplaceInfo);
    HookEvent("player_disconnect",Event_PlayerDisconnectInfo);

}
// public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
// {
//     // if( GetEngineVersion() != Engine_Left4Dead2 ) // only support left4dead2, sorry for l4d1 player.
//     //     return APLRes_SilentFailure;

//     // RegPluginLibrary("");
//     // return APLRes_Success;
// }
public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    if( IsFakeClient(client) )
        return true;
        
    PrintToServer("[server_info_hook]: OnClientConnect() client %d, Gametime:%f==========", client, GetGameTime());
    return true;
}
public void OnClientConnected(int client)
{
    if( IsFakeClient(client) )
        return;
        
    PrintToServer("[server_info_hook]: OnClientConnected() client %d, Gametime:%f==========", client, GetGameTime());
}
public void OnClientDisconnect(int client)
{
    if( IsFakeClient(client) )
        return;

    PrintToServer("[server_info_hook]: OnClientDisconnect() client %d, Gametime:%f==========", client, GetGameTime());
}
public void OnClientDisconnect_Post(int client)
{
    PrintToServer("[server_info_hook]: OnClientDisconnect_Post() client %d, Gametime:%f==========", client, GetGameTime());
}
public void OnClientPutInServer(int client)
{
    if( IsFakeClient(client) )
        return;
        
    PrintToServer("[server_info_hook]: OnClientPutInServer() client %d, Gametime:%f==========", client, GetGameTime());
}
public void OnClientPostAdminCheck(int client)
{
    if( IsFakeClient(client) )
        return;
        
    PrintToServer("[server_info_hook]: OnClientPostAdminCheck() client %d, Gametime:%f==========", client, GetGameTime());
}

public void OnConfigsExecuted()
{
    PrintToServer("[server_info_hook]: OnConfigsExecuted() Gametime:%f==========", GetGameTime());
}
public void OnMapStart()
{
    PrintToServer("[server_info_hook]: OnMapStart() Gametime:%f==========", GetGameTime());
}

void Event_RoundStartInfo(Event event,const char[] name,bool dontbroadcast)
{
    PrintToServer("[server_info_hook]: round_start Gametime:%f==========",GetGameTime());
}

void Event_RoundEndInfo(Event event,const char[] name,bool dontbroadcast)
{
    PrintToServer("[server_info_hook]: round_end Gametime:%f==========",GetGameTime());
}

void Event_MapTransitionInfo(Event event,const char[] name,bool dontbroadcast)
{
    PrintToServer("[server_info_hook]: map_transition Gametime:%f==========",GetGameTime());
}

public void OnMapEnd()
{
    PrintToServer("[server_info_hook]: OnMapEnd() Gametime:%f==========",GetGameTime());
}

void Event_FinalVehicleLeavingInfo(Event event,const char[] name,bool dontbroadcast)
{
    PrintToServer("[server_info_hook]: finale_vehicle_leaving Gametime:%f==========",GetGameTime());
}

void Event_FinalStartInfo(Event event,const char[] name,bool dontbroadcast)
{
    PrintToServer("[server_info_hook]: final_start Gametime:%f==========",GetGameTime());
}

void Event_FinalWinInfo(Event event,const char[] name,bool dontbroadcast)
{
    PrintToServer("[server_info_hook]: final_win Gametime:%f==========",GetGameTime());
}

void Event_PlayerSpawnInfo(Event event,const char[] name,bool dontbroadcast)
{
    int client = GetClientOfUserId( event.GetInt("userid") );
    if( !IsClientInGame(client) || IsFakeClient(client) )
        return;

    PrintToServer("[server_info_hook]: player_spawn client: %d, Gametime:%f==========",client,GetGameTime());
}

void Event_PlayerTeamInfo(Event event,const char[] name,bool dontbroadcast)
{
    int client = GetClientOfUserId( event.GetInt("userid") );
    if( !IsClientInGame(client) || IsFakeClient(client) )
        return;

    int newteam = GetEventInt(event,"team");
    int oldteam = GetEventInt(event,"oldteam");
    PrintToServer("[server_info_hook]: player_team client: %d, old_team: %d, new_team: %d, Gametime:%f==========",client,oldteam,newteam,GetGameTime());
}

void Event_PlayerBotReplaceInfo(Event event,const char[] name,bool dontbroadcast)
{
    int bot = GetClientOfUserId( event.GetInt("bot") );
    int client = GetClientOfUserId( event.GetInt("player") );
    if( !IsClientInGame(client) || IsFakeClient(client) )
        return;

    PrintToServer("[server_info_hook]: player_bot_replace client: %d, bot: %d, Gametime:%f==========",client,bot,GetGameTime());
}
void Event_BotPlayerReplaceInfo(Event event,const char[] name,bool dontbroadcast)
{
    int bot = GetClientOfUserId( event.GetInt("bot") );
    int client = GetClientOfUserId( event.GetInt("player") );
    if( !IsClientInGame(client) || IsFakeClient(client) )
        return;
    
    PrintToServer("[server_info_hook]: bot_player_replace client: %d, bot: %d, Gametime:%f==========",client,bot,GetGameTime());
}
void Event_PlayerDisconnectInfo(Event event,const char[] name,bool dontbroadcast)
{
    static char reason[128];
    static char clientname[128];
    static char networkid[128];
    event.GetString("name",clientname,sizeof(clientname),"name not found");
    event.GetString("reason",reason,sizeof(reason),"reason not found");
    event.GetString("networkid",networkid,sizeof(networkid),"networkid not found");
    PrintToServer("[server_info_hook]: player_disconnect \
                    userid:%d, client:%d \
                    %s----%s, networkid: %s \
                    Gametime:%f================",event.GetInt("userid"),GetClientOfUserId(event.GetInt("userid")),
                    clientname,reason,networkid,
                    GetGameTime());
}