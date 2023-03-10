#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

#define MODE_CLOSED 0
#define MODE_SMART 2
#define MODE_MAX 1

#define SPAWN_MODE 1
#define KICK_MODE 0

#define CLASS_SMOKER	1
#define CLASS_BOOMER	2
#define CLASS_HUNTER	3
#define CLASS_SPITTER	4
#define CLASS_JOCKEY	5
#define CLASS_CHARGER	6
#define CLASS_TANK	    8

#define TEAM_INFECTED   3
#define TEAM_SURVIVOR   2

ConVar cvar_gamemode;
ConVar cvar_max_player_zombie;

ConVar cvar_infectedbot_mode    ;int g_infectedbot_mode;
ConVar cvar_smartmode_defaultcount;int g_smartmode_defaultcount;
ConVar cvar_smartmode_addcount; int g_smartmode_addcount;
ConVar cvar_smartmode_addfrom; int g_smartmode_addfrom;
ConVar cvar_maxmode_each_count;

ConVar cvar_time_min_spawn      ;float g_time_min_spawn;
ConVar cvar_time_min_kick       ;float g_time_min_kick;

enum struct infected_info
{
    int charger;
    int hunter;
    int jockey;
    int smoker;
    int boomer;
    int spitter;
    int currentcount; 
    int GetMax() 
    {
        return this.charger + this.hunter + this.jockey + this.smoker + this.boomer + this.spitter;
    }
    
}
infected_info g_infected_info;

int g_current_player;
bool g_has_player_left_startarea;
bool g_round_start;

Handle g_timer_infectedbot_roundstart;
Handle g_timer_infectedbot_force_roundstart;
Handle g_timer_infectedbot_spawn_queue;
ArrayList g_infectedbot_spawn_queue;
ArrayList g_infectedbot_spawn_failed_queue;
ArrayList g_infectedbot_kick_queue;

public Plugin myinfo =
{
	name = "Infected bot management",
	author = "Miuwiki",
	description = "manage the count, respawn time, class of the infected bot.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
    if( GetEngineVersion() != Engine_Left4Dead2 )
    {
        LogError("Pluging only work in left4dead2");
        return APLRes_Failure;
    }

    // if( late )
    // {
    //     LogError("Plugin can't load after the plugins has been loaded.");
    //     return APLRes_Failure;
    // }
    return APLRes_Success; 
}
public void OnPluginStart()
{   
    cvar_gamemode = FindConVar("mp_gamemode");
    cvar_infectedbot_mode = CreateConVar("miuwiki_infectedbot_mode","1","模式选择(1=根据最大值刷特(固定模式),2=根据人数刷特(智能模式))",0,true,1.0,true,2.0);
    cvar_maxmode_each_count = CreateConVar("miuwiki_maxmode_each_count","6-5-4-3-2-1","(固定模式才生效)按照charger-hunter-jockey-smoker-boomer-spitter顺序依次设置最大值",0,true,0.0,true,31.0);
    cvar_smartmode_defaultcount = CreateConVar("miuwiki_smartmode_default_count","4","(智能模式才生效)初始多少个特感");
    cvar_smartmode_addcount = CreateConVar("miuwiki_smartmode_addcount","1","(智能模式才生效)每个玩家增加多少个特感",0,true,0.0);
    cvar_smartmode_addfrom = CreateConVar("miuwiki_smartmode_addfrom","1","(智能模式才生效)多少个玩家之后开始增加特感",0,true,0.0);
    cvar_time_min_spawn = CreateConVar("miuwiki_infectedbot_respawntime","3.0","特感死亡后几秒复活(每个特感单独计算)",0,true,1.0);
    cvar_time_min_kick = CreateConVar("miuwiki_infectedbot_kicktime","15.0","多少秒后踢出不攻击的特感(防止无限增多)",0,true,10.0);

    HookEvent("round_start",Event_RoundStartInfo);
    HookEvent("round_end",Event_RoundEndInfo);
    HookEvent("player_death",Event_PlayerDeathInfo);
    HookEvent("player_team",Event_PlayerTeamInfo);
    // AutoExecConfig(true);

    g_infectedbot_spawn_queue = new ArrayList();
    g_infectedbot_spawn_failed_queue = new ArrayList();
    g_infectedbot_kick_queue = new ArrayList();

    // Removes the boundaries for z_max_player_zombies and notify flag
    cvar_max_player_zombie = FindConVar("z_max_player_zombies");
    int flags = cvar_max_player_zombie.Flags;
    SetConVarBounds(cvar_max_player_zombie, ConVarBound_Upper, false);
    SetConVarFlags(cvar_max_player_zombie, flags & ~FCVAR_NOTIFY);
}
public void OnConfigsExecuted()
{
    g_infectedbot_mode = cvar_infectedbot_mode.IntValue;
    char current_mode[16];
    cvar_gamemode.GetString(current_mode,sizeof(current_mode));
    if( strcmp(current_mode,"coop",false) == 0 || strcmp(current_mode,"realism",false) == 0 )
    {
        g_time_min_spawn = cvar_time_min_spawn.FloatValue;
        g_time_min_kick = cvar_time_min_kick.FloatValue;
        g_smartmode_defaultcount = cvar_smartmode_defaultcount.IntValue;
        g_smartmode_addfrom = cvar_smartmode_addfrom.IntValue;
        g_smartmode_addcount = cvar_smartmode_addcount.IntValue;
        
        char part[6][4],temp[32];
        cvar_maxmode_each_count.GetString(temp,sizeof(temp));
        ExplodeString(temp,"-",part,6,4);
        g_infected_info.charger = StringToInt(part[0]);
        g_infected_info.hunter = StringToInt(part[1]);
        g_infected_info.jockey = StringToInt(part[2]);
        g_infected_info.smoker = StringToInt(part[3]);
        g_infected_info.boomer = StringToInt(part[4]);
        g_infected_info.spitter = StringToInt(part[5]);
        
        SetServerConvar();
    }
    else
    {
        ResetServerConvar();
    }
}
void Event_RoundStartInfo(Event event, const char[] name, bool dontBroadcast)
{
    g_infected_info.currentcount = 0;
    g_has_player_left_startarea = false;
    g_round_start = true;

    //开始第一波刷特计时
    delete g_timer_infectedbot_roundstart;
    g_timer_infectedbot_roundstart = CreateTimer(g_time_min_spawn,Timer_RoundSpawn,_,TIMER_REPEAT);
    //避免卡特，即便没出门，1分钟之后强制刷特
    delete g_timer_infectedbot_force_roundstart;
    g_timer_infectedbot_force_roundstart = CreateTimer(60.0,Timer_ForceRoundSpawn,_);
    //每1秒检查在生成队列的特感(包含生成失败,智能模式新增的特感)重新生成
    delete g_timer_infectedbot_spawn_queue;
    g_timer_infectedbot_spawn_queue = CreateTimer(1.0,Timer_SpawnInfectedInQueue,_,TIMER_REPEAT);

    g_infectedbot_spawn_queue.Clear();
    g_infectedbot_spawn_failed_queue.Clear();
    g_infectedbot_kick_queue.Clear();
}
void Event_RoundEndInfo(Event event, const char[] name, bool dontBroadcast)
{
    g_round_start = false;
}
/* begin~ */
public void OnClientPutInServer(int client)
{
    if( IsFakeClient(client) )
        return;

    g_current_player++;

    if( g_infectedbot_mode == MODE_MAX && g_has_player_left_startarea)
    {
        PrintToChatAll("\x04[多特控制]\x05当前玩家\x03%d\x05人, \x04%d\x05特, \x05刷新间隔 \x03%.0f \x05秒",g_current_player,g_infected_info.currentcount,g_time_min_spawn);
    }
        
    if( g_infectedbot_mode == MODE_SMART && g_current_player > g_smartmode_addfrom )
    {
        for(int i = 1; i <= g_smartmode_addcount; i++)
        { 
            g_infectedbot_spawn_queue.Push( GetRandomInt(1,6) );
            g_infected_info.currentcount += 1;
        }
        
        if( g_has_player_left_startarea )
        {
            PrintToChatAll("\x04[多特控制]\x05当前玩家\x03%d\x05人, \x04%d\x05特, \x05刷新间隔 \x03%.0f \x05秒",g_current_player,g_infected_info.currentcount,g_time_min_spawn);
        }
    }
    
}
public void OnClientDisconnect(int client)
{
    if( IsFakeClient(client) )
        return;

    g_current_player--;

    if( g_infectedbot_mode == 1 && g_has_player_left_startarea)
    {
        PrintToChatAll("\x04[多特控制]\x05当前玩家\x03%d\x05人, \x04%d\x05特, \x05刷新间隔 \x03%.0f \x05秒",g_current_player,g_infected_info.currentcount,g_time_min_spawn);
    }

    if( g_infectedbot_mode == MODE_SMART && g_current_player > g_smartmode_addfrom )
    {
        for(int i = 1; i <= g_smartmode_addcount; i++)
        {
            g_infectedbot_kick_queue.Push( GetRandomInt(1,6) );
            g_infected_info.currentcount -= 1;
        }

        if( g_has_player_left_startarea )
        {
            PrintToChatAll("\x04[多特控制]\x05当前玩家\x03%d\x05人, \x04%d\x05特, \x05刷新间隔 \x03%.0f \x05秒",g_current_player,g_infected_info.currentcount,g_time_min_spawn);
        }
    }
}

//pre 事件可以防止别的插件将事件部分信息更改了. 其实大部分情况也不会更改.
void Event_PlayerDeathInfo(Event event, const char[] name, bool dontBroadcast)
{
    if( !g_round_start )
        return;
    
    int client = GetClientOfUserId( event.GetInt("userid") );
    if( client < 1 || client > MaxClients )
        return;
    
    if( !IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != TEAM_INFECTED )
        return;

    int type = GetEntProp(client,Prop_Send,"m_zombieClass");
    CreateTimer(g_time_min_spawn,Timer_SpawnInfectedInDeath,type,TIMER_FLAG_NO_MAPCHANGE);

    //spitter 不踢出/系统自己会踢出
    if( type != CLASS_SPITTER )
    {
        CreateTimer(1.0,Timer_InfectedKickLate,GetClientUserId(client),TIMER_FLAG_NO_MAPCHANGE);
    }
}
void Event_PlayerTeamInfo(Event event, const char[] name, bool dontBroadcast)
{
    if( !g_round_start )
        return;

    int client = GetClientOfUserId( event.GetInt("userid") );
    if( client == 0 || !IsClientInGame(client) )
        return;
    
    if( !IsFakeClient(client) || GetClientTeam(client) != TEAM_INFECTED )
        return;

    int type = GetEntProp(client,Prop_Send,"m_zombieClass"); 
    if( type == CLASS_TANK)
        return;

    //z_xxx_limit那个已经关闭导演刷特了，不知道原来那个为什么还要判断是不是导演刷特然后踢出
    int userid = GetClientUserId( client );
    CreateTimer(g_time_min_kick,Timer_KickOutTimeBot,userid,TIMER_FLAG_NO_MAPCHANGE); // 存活超时踢出
    
    //返回第一个值，因此不会删到后面的同类型特感 
    //player_team也会触发一次 player_spawn, 很坑. 因此不能用player_spawn 获取userid.
    int index = g_infectedbot_spawn_queue.FindValue(type);
    if( index != -1 )
    {
        g_infectedbot_spawn_queue.Erase(index);
    }
}
Action Timer_RoundSpawn(Handle timer)
{
    if( !g_has_player_left_startarea )
    {
        CheckSurvivorLeftStartArea();
        return Plugin_Continue;
    }
        
    if( g_infectedbot_mode == MODE_MAX )
    {
        int charger,hunter,jockey,smoker,boomer,spitter;
        //按顺序依次写入
        int amount = g_infected_info.GetMax();
        for(int i = 1; i <= g_infected_info.GetMax(); i++)
        {
            if( charger < g_infected_info.charger )
            {
                if( amount == 0 )  break;
                g_infectedbot_spawn_queue.Push(CLASS_CHARGER);
                charger++;amount--;
            }
            if( hunter < g_infected_info.hunter )
            {
                if( amount == 0 )  break;
                g_infectedbot_spawn_queue.Push(CLASS_HUNTER);
                hunter++;amount--;
            }
            if( jockey < g_infected_info.jockey )
            {
                if( amount == 0 )  break;
                g_infectedbot_spawn_queue.Push(CLASS_JOCKEY);
                jockey++;amount--;
            }
            if( smoker < g_infected_info.smoker )
            {
                if( amount == 0 )  break;
                g_infectedbot_spawn_queue.Push(CLASS_SMOKER);
                smoker++;amount--;
            }
            if( boomer < g_infected_info.boomer )
            {
                if( amount == 0 )  break;
                g_infectedbot_spawn_queue.Push(CLASS_BOOMER);
                boomer++;amount--;
            }
            if( spitter < g_infected_info.spitter )
            {
                if( amount == 0 )  break;
                g_infectedbot_spawn_queue.Push(CLASS_SPITTER);
                spitter++;amount--;
            }
        }
        g_infected_info.currentcount = g_infected_info.GetMax();
    }
    else
    {
        for(int i = 1; i <= g_smartmode_defaultcount; i++)
        {
            g_infectedbot_spawn_queue.Push( GetRandomInt(1,6) );
        }
        g_infected_info.currentcount += g_smartmode_defaultcount;
    }

    PrintToChatAll("\x04[多特控制]\x05当前玩家\x03%d\x05人, \x04%d\x05特, \x05刷新间隔 \x03%.0f \x05秒",g_current_player,g_infected_info.currentcount,g_time_min_spawn);
    //因为计时器返回stop，直接delete会报错，因此在返回stop的地方先设置null避免报错
    g_timer_infectedbot_roundstart = null;
    return Plugin_Stop;
}
Action Timer_ForceRoundSpawn(Handle timer)
{
    if( !g_has_player_left_startarea )
    {
        g_has_player_left_startarea = true;
        PrintToChatAll("\x04[多特控制]\x05检测到没有玩家出门或卡特感, 插件自动刷特~");        
    }
    //因为计时器返回stop，直接delete会报错，因此在返回stop的地方先设置null避免报错
    g_timer_infectedbot_force_roundstart = null;
    return Plugin_Stop;
}
Action Timer_SpawnInfectedInQueue(Handle timer)
{
    if( !g_round_start )
    {
        g_timer_infectedbot_spawn_queue = null;
        return Plugin_Stop;
    }
    
    if( g_infectedbot_spawn_queue.Length == 0 )
        return Plugin_Continue;
    
    //生成查询队列里生成的特感.
    int class = g_infectedbot_spawn_queue.Get(0);
    g_infectedbot_spawn_queue.Erase(0);
    SpawnInfected(class);
    return Plugin_Continue;
}
Action Timer_SpawnInfectedInDeath(Handle timer,int class)
{
    if( !g_round_start )
        return Plugin_Continue;

    SpawnInfected(class);
    return Plugin_Stop;
}
Action Timer_InfectedKickLate(Handle timer,int userid)
{
    int client = GetClientOfUserId(userid);
    if(client && IsClientInGame(client) && IsFakeClient(client) && !IsClientInKickQueue(client) )
    {
        KickClient(client);
    }
    return Plugin_Continue;
}
Action Timer_KickOutTimeBot(Handle timer,int infectedbot_userid)
{
    int infectedbot = GetClientOfUserId( infectedbot_userid );
    if( infectedbot == 0 )
        return Plugin_Continue;

    //特感死了复活由 player_death 事件接管，踢出之后复活由这里接管。
    if( IsClientInGame(infectedbot) && IsFakeClient(infectedbot) && GetClientTeam(infectedbot) == TEAM_INFECTED && IsPlayerAlive(infectedbot))
    {
        //避免打架的时候踢掉，不够准确
        if( GetEntProp(infectedbot, Prop_Send, "m_hasVisibleThreats") && L4D_GetSurvivorVictim(infectedbot) > 0 )
        {
           CreateTimer(g_time_min_kick,Timer_KickOutTimeBot,GetClientUserId(infectedbot),TIMER_FLAG_NO_MAPCHANGE);
        }
        else
        {
            int type = GetEntProp(infectedbot,Prop_Send,"m_zombieClass");
            KickClient(infectedbot);
            g_infectedbot_spawn_queue.Push(type);
        }
    }
    return Plugin_Continue;
}

//From HarryPotter//
int L4D_GetSurvivorVictim(int client)
{
    int victim;
    /* Charger */
    victim = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
    if (victim > 0)
    {
        return victim;
    }
    victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
    if (victim > 0)
    {
        return victim;
    }
    /* Jockey */
    victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
    if (victim > 0)
    {
        return victim;
    }
    /* Hunter */
    victim = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
    if (victim > 0)
    {
        return victim;
    }
    /* Smoker */
    victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
    if (victim > 0)
    {
        return victim;
    }
    return -1;
}
void SpawnInfected(int class)
{
    if( !g_round_start )
        return;
        
    if( g_infectedbot_mode == MODE_SMART )
    {
        if( g_infectedbot_kick_queue.Length > 0 )
        {
            g_infectedbot_kick_queue.Erase(0);
            return;
        }
        else
        {
            class = GetRandomInt(1,6);
        }
    }

    //写入生成队列中
    g_infectedbot_spawn_queue.Push(class);
    /**
     * 生成 fakeclient 实体
     * 转换队伍变为感染者队伍中的一个待定bot
     * 踢出 fakeclient , 因为 fakeclient 不会攻击, 需要一个bot去接管才行
     * 通过 player_team 去获取到对应的 userid.
     */
    int cheat_client = -1;
    for(int i = 1; i <= MaxClients; i++) 
	{ 
		if(IsClientInGame(i))
        {
            cheat_client = i;
            break;
        }
	}
    if( cheat_client == -1 )
        return;
    
    int bot = CreateFakeClient("Infected Bot");
    if( bot != 0 )
    {
        ChangeClientTeam(bot,TEAM_INFECTED);
        KickClient(bot);
        switch(class)
        {
            case CLASS_CHARGER: 
            CheatCommand(cheat_client, "z_spawn_old", "charger auto");
            case CLASS_HUNTER: 
            CheatCommand(cheat_client, "z_spawn_old", "hunter auto");
            case CLASS_JOCKEY: 
            CheatCommand(cheat_client, "z_spawn_old", "jockey auto");
            case CLASS_SMOKER: 
            CheatCommand(cheat_client, "z_spawn_old", "smoker auto");
            case CLASS_BOOMER: 
            CheatCommand(cheat_client, "z_spawn_old", "boomer auto");
            case CLASS_SPITTER: 
            CheatCommand(cheat_client, "z_spawn_old", "spitter auto");
        }
    }
}
void CheatCommand(int client, char[] command, char[] arguments = "")
{
    int userFlags = GetUserFlagBits(client);
    int flags = GetCommandFlags(command);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);

    FakeClientCommand(client, "%s %s", command, arguments);

    SetCommandFlags(command, flags);
    SetUserFlagBits(client, userFlags);
}
void CheckSurvivorLeftStartArea()
{
    int ent = FindEntityByClassname(-1,"terror_player_manager");

    if( ent != -1 && GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea") )
    {
        g_has_player_left_startarea = true;
        return;
    }

    g_has_player_left_startarea = false;
}
void SetServerConvar()
{
    //关闭导演刷特，只允许导演刷 tank 和 witch
    SetConVarInt(FindConVar("z_smoker_limit"),  0);
    SetConVarInt(FindConVar("z_boomer_limit"),  0);
    SetConVarInt(FindConVar("z_hunter_limit"),  0);
    SetConVarInt(FindConVar("z_spitter_limit"), 0);
    SetConVarInt(FindConVar("z_jockey_limit"),  0);
    SetConVarInt(FindConVar("z_charger_limit"), 0);
    SetConVarInt(FindConVar("z_max_player_zombies"),30);
    //距离，感染团队观察者，生成安全距离，
    SetConVarInt(FindConVar("z_attack_flow_range"), 50000);
    SetConVarInt(FindConVar("z_spawn_safety_range"), 0);
    SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000);

    //重置部分convar
    ResetConVar(FindConVar("director_no_specials"), true, true);
    ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
    ResetConVar(FindConVar("boomer_exposed_time_tolerance"), true, true);
    ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
    ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
    ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
    ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
    ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
    ResetConVar(FindConVar("z_hunter_lunge_stagger_time"), true, true);
    ResetConVar(FindConVar("z_jockey_leap_time"), true, true);
    ResetConVar(FindConVar("z_spitter_max_wait_time"), true, true);
}
void ResetServerConvar()
{
    ResetConVar(FindConVar("z_smoker_limit"),  true, true);
    ResetConVar(FindConVar("z_boomer_limit"),  true, true);
    ResetConVar(FindConVar("z_hunter_limit"),  true, true);
    ResetConVar(FindConVar("z_spitter_limit"), true, true);
    ResetConVar(FindConVar("z_jockey_limit"),  true, true);
    ResetConVar(FindConVar("z_charger_limit"), true, true);

    ResetConVar(FindConVar("director_spectate_specials"), true, true);
    ResetConVar(FindConVar("z_attack_flow_range"), true, true);
    ResetConVar(FindConVar("z_spawn_safety_range"), true, true);
    ResetConVar(FindConVar("z_spawn_flow_limit"), true, true);

    //重置部分convar
    ResetConVar(FindConVar("director_no_specials"), true, true);
    ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
    ResetConVar(FindConVar("boomer_exposed_time_tolerance"), true, true);
    ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
    ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
    ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
    ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
    ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
    ResetConVar(FindConVar("z_hunter_lunge_stagger_time"), true, true);
    ResetConVar(FindConVar("z_jockey_leap_time"), true, true);
    ResetConVar(FindConVar("z_spitter_max_wait_time"), true, true);
}

