#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"
#define KICK_MESSAGE_SERVER_IN_TRANSITION "请等待上一局玩家全部加入后再尝试进服."

ConVar
    cvar_jointimeout,
    cvar_joincontrol,
    cvar_l4dtoolz;

ArrayList 
    g_player_not_transition;

enum struct Server
{
    float jointimeout;
    bool joincontrol;
    bool alljoin;
    bool hastrainsitioner;
    char prefix[3];
    char identify[128];
    
    int PlayerCount()
    {
        int count;
        for(int i = 1; i <= MaxClients; i++)
        {
            if( IsClientInGame(i) && !IsFakeClient(i) )
                count++;
        }

        return count;
    }
    
    bool CheckAllPlayerJoin()
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if( IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i) ) // somebody joining in game.
                return false;
                
        }

        LogMessage("<<========== All old player has joined, allow new player join.");
        this.alljoin = true;
        return true;
    }

    void ChangeIdentify()
    {
        static char mapname[64];
        GetCurrentMap(mapname, sizeof(mapname));
        FormatEx(this.identify, sizeof(this.identify), "%s%s", this.prefix, mapname);

        // set new prefix to mix the user info.
        static char string[] = "miuwiki";
        for(int i = 0; i < sizeof(this.prefix); i++)
        {
            this.prefix[i] = string[GetRandomInt(0, sizeof(string) - 2)];
        }
    }

    void SetIdentify(int client)
    {
        static char mapname[128];
        GetCurrentMap(mapname, sizeof(mapname));
        Format(mapname, sizeof(mapname), "%s%s", this.prefix, mapname);
        SetClientInfo(client, mapname, "1");
    }
}

Server server;

public Plugin myinfo =
{
	name = "[L4D2] Changing Level Join Control",
	author = "Miuwiki",
	description = "Prohibit new player join before all old player join.",
	version = PLUGIN_VERSION,
	url = "http://miuwiki.site"
}

public void OnPluginStart()
{
    cvar_l4dtoolz = FindConVar("sv_maxplayers");
    if( !cvar_l4dtoolz )
        SetFailState("This plugins need L4DToolZ.ext.");
    
    cvar_joincontrol = CreateConVar("l4d2_join_control", "1", "Prohibit new player join before old player when changing level", 0, true, 0.0, true, 1.0);
    cvar_jointimeout = CreateConVar("l4d2_join_timeout", "30.0", "How much time old player seem as time out", 0, true, 1.0);
    g_player_not_transition = new ArrayList();

    HookEvent("player_disconnect", Event_PlayerDisconcet);
    HookEvent("map_transition", Event_MapTransition);
}

public void OnConfigsExecuted()
{
    server.jointimeout = cvar_jointimeout.FloatValue;
    server.joincontrol = cvar_joincontrol.BoolValue;

    if( server.joincontrol )
        CreateTimer(server.jointimeout, Timer_JoinControlTimeOut, _, TIMER_FLAG_NO_MAPCHANGE);

}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
    server.alljoin = false;
    LogMessage(" <<========== Map Transition start prevent join.");
}

void Event_PlayerDisconcet(Event event, const char[] name, bool dontBroadcast)
{
    /**
     * Player disconnected caused by map_transition or map change would not fire this event.
     * This event is faster than OnClientDisconnect.
     * Base on that, player who called this event show him exit the server and will not reconnected automatically like map change.
     */
    int client = GetClientOfUserId( event.GetInt("userid") );
    if( client < 1 || client > MaxClients || IsFakeClient(client) )
        return;
    
    g_player_not_transition.Push( event.GetInt("userid") );
    // PrintToServer("[miuwiki_reservedslots]: %N disconnect not in map transition.", client);
}
public void OnClientDisconnect(int client)
{
    if( IsFakeClient(client) )
        return;

    int userid = GetClientUserId(client);
    int index;
    if( (index = g_player_not_transition.FindValue(userid)) != -1 ) // this client is exit not by the map transition.
    {
        // PrintToServer("[miuwiki_reservedslots]: %N disconnect not in map transition. index = %d", client, index);
        g_player_not_transition.Erase(index);
        return;
    }

    // now player is disconnect by map transition, set client info to identify.
    server.SetIdentify(client);
    server.hastrainsitioner = true;
    // PrintToServer("[miuwiki_reservedslots]: %N disconnect by map transition.", client);
}

public void OnClientConnected(int client)
{

}


public void OnMapStart()
{
    if( !server.hastrainsitioner ) // no transitioner, which means server just start or empty server changelevel.
    {
        // PrintToServer("[miuwiki_reservedslots]: server start first time or empty server changelevel.");
        server.alljoin = true;
        return;
    }
    else
    {
        CreateTimer(1.0, Timer_CheckAllJoin, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
    }

    server.hastrainsitioner = false;
}

public void OnMapEnd()
{
    g_player_not_transition.Clear();
    server.ChangeIdentify();

    server.alljoin = false;
    LogMessage(" <<========== MapEnd start prevent new player join, waitting old player.");
}


public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    if( IsFakeClient(client) )
        return true;

    if( !server.joincontrol )
        return true;
    
    if( server.alljoin ) // all player has joined in the game.
        return true;
    
    static char info[4];
    GetClientInfo(client, server.identify, info, sizeof(info));
    if( strcmp(info , "1") == 0 )
        return true;
    
    static char time[32];
    FormatTime(time, sizeof(time), "%F %X", GetTime());
    FormatEx(rejectmsg, maxlen, "%s 加入时间: %s", KICK_MESSAGE_SERVER_IN_TRANSITION, time);
    return false;
}

Action Timer_JoinControlTimeOut(Handle timer)
{
    if( !server.alljoin )
    {
        server.alljoin = true;
        LogMessage("<<========== Time out wait old player, allow new player join.");
    }
        
    return Plugin_Stop;
}

Action Timer_CheckAllJoin(Handle timer)
{
    if( server.CheckAllPlayerJoin() )
        return Plugin_Stop;
    
    return Plugin_Continue;
}
