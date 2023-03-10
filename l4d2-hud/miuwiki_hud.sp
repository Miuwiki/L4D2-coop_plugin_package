#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <l4d2_ems_hud>

#define PLUGIN_VERSION "1.0.2"
#define PLAYER_LIST 1 << 0
#define KILL_LIST 1 << 1
#define HOST_LIST 1 << 2
#define MAXPLAYER_LIST 1 << 3

static StringMap g_weapon_name;
ArrayList g_hud_killinfo;
Handle g_timer_player_list;

ConVar L4D_TOOL;
ConVar cvar_max_num_playerlist; int g_max_show_count;
ConVar cvar_show_list; int g_show_list;

int g_player_num;
int g_player_killspecial[MAXPLAYERS];
int g_player_headshot[MAXPLAYERS];

static const char g_event_weapon_string[][] = 
{
	"melee",

	"pistol",
	"pistol_magnum",
	"dual_pistols",

	"smg",
	"smg_silenced",
	"smg_mp5",

	"rifle",
	"rifle_ak47",
	"rifle_sg552",
	"rifle_desert",

	"pumpshotgun",
	"shotgun_chrome",
	"autoshotgun",
	"shotgun_spas",

	"hunting_rifle",
	"sniper_military",
	"sniper_scout",
	"sniper_awp",

	"pipe_bomb",

	"inferno",
	"entityflame",

	"rifle_m60",

	"grenade_launcher_projectile",

	"boomer",
	"player",

	"world",
	"worldspawn",
	"trigger_hurt"
};

static const char g_kill_type[][] =
{
	"■■‖═════>",     //0 melee
	"//^ˉˉˉ",        //1 pistol
	"Tˉˉ══",         //2 smg
	"■︻TT^ˉˉ^══",   //3 rifle
	"■︻/══^^",      //4 shotgun
	"■︻T^ˉ════",    //5 sniper
	"●ˉˉˉ",          //6 pipe bomb
	"__∫∫∫∫__",      //7 inferno, entityflame
	"■︻T^ˉ****",	//8 M60
	"︻T■■■■■",	    //9 grenade_launcher_projectile

	"/*/*/",	     //10 killed by push
	"*X*",           //11 killed by world
	"*=*彡",         //12 killed by special infected,
	"→‖→",           //13 kill behind wall
	"→⊙",           //14 headshot
};

// follow the inc to set the pos.
static const float g_HUDpos[][] =
{
    // hostname
    {0.00,0.00,1.00,0.04}, // HUD_LEFT_TOP
    // info
    {0.00,0.00,0.30,0.06},
    // player list
    {0.00,0.06,0.23,0.04},
    {0.00,0.09,0.23,0.04},
    {0.00,0.12,0.23,0.04},
    {0.00,0.15,0.23,0.04},
    {0.00,0.18,0.23,0.04},
    {0.00,0.21,0.23,0.04},
    {0.00,0.24,0.23,0.04},
    {0.00,0.27,0.23,0.04},
    // kill list
    {0.00,0.00,1.00,0.04},
    {0.00,0.04,1.00,0.04},
    {0.00,0.08,1.00,0.04},
    {0.00,0.12,1.00,0.04},
    {0.00,0.16,1.00,0.04},
};

enum struct HUD
{
	int slot;
	int flag;
	float pos[4];
	char info[128];
	void Place()
	{
		HUDSetLayout(this.slot, HUD_FLAG_TEXT|this.flag, this.info);
		HUDPlace(this.slot, this.pos[0], this.pos[1], this.pos[2], this.pos[3]);
	}
}

public Plugin myinfo =
{
	name = "HUD on L4D2",
	author = "Miuwiki & special thanks \"sorall\" provide the inc.",
	description = "HUD with player list & cs kill info list.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnPluginStart()
{
	HookEvent("player_death",Event_PlayerDeathInfo,EventHookMode_Pre);
	HookEvent("round_start",Event_RoundStartInfo);

	g_weapon_name = new StringMap();
	g_hud_killinfo = new ArrayList(128);
	LoadEventWeaponName();

	cvar_max_num_playerlist = CreateConVar("l4d2_max_player_list","8","Max count of the player list display",0,true,0.0,true,8.0);
	cvar_show_list = CreateConVar("l4d2_show_which_list","15","Display which list on screen.0 = off, 1 = show hostname, 2 = show player list, 4 = show kill list 8 = Current player/Max PLAYER. Add the count to show both of them. ",0,true,0.0,true,15.0);
	cvar_max_num_playerlist.AddChangeHook(Cvar_ChangeHookCallback);
	cvar_show_list.AddChangeHook(Cvar_ChangeHookCallback);
	L4D_TOOL = FindConVar("sv_maxplayers");
	//AutoExecConfig();
}
public void OnConfigsExecuted()
{
	g_max_show_count = cvar_max_num_playerlist.IntValue;
	g_show_list = cvar_show_list.IntValue;
}
void Cvar_ChangeHookCallback(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_max_show_count = cvar_max_num_playerlist.IntValue;
	g_show_list = cvar_show_list.IntValue;
}
//地图开始的时候重置人数，因为connected必定只会在mapstart的时候触发。round_start玩家已经在游戏了，不会触发人数加减。
public void OnMapStart()
{
	EnableHUD();
}
void Event_RoundStartInfo(Event event,const char[] name,bool dontboradcast)
{
    for(int i = 0; i < MAXPLAYERS; i++)
	{
		g_player_killspecial[i] = 0;
		g_player_headshot[i] = 0;
	}
    g_hud_killinfo.Clear();
    g_player_num = 0;
    delete g_timer_player_list;
    g_timer_player_list = CreateTimer(1.0,Timer_DisplayHUDInfo,_,TIMER_REPEAT);
}
//玩家连接以及离开。
public void OnClientConnected(int client)
{   
	if(!IsFakeClient(client))
	{
		g_player_num += 1;			        //玩家数量
		g_player_killspecial[client] = 0;	//新进玩家属性：killspecial
		g_player_headshot[client] = 0;		//新进玩家属性，爆头
	}
}
public void OnClientDisconnect(int client)
{
    if(!IsFakeClient(client))
    {
        g_player_num -= 1;
        g_player_killspecial[client] = 0;
        g_player_headshot[client] = 0;
    }
}
Action Timer_DisplayHUDInfo(Handle timer)
{
	if( g_show_list == 0 )
		return Plugin_Continue;
	
	HUD show_hud;
	// HOST_LIST
	if( g_show_list & HOST_LIST )
	{
		GetConVarString(FindConVar("hostname"), show_hud.info, sizeof(show_hud.info));
		show_hud.slot = 0;
		show_hud.flag = HUD_FLAG_ALIGN_CENTER|HUD_FLAG_NOBG;
		show_hud.pos  = g_HUDpos[0];
		show_hud.Place();
	}

	// MAXPLAYER_LIST
	if( g_show_list & MAXPLAYER_LIST )
	{
		int maxplayers = L4D_TOOL == null ? MaxClients : L4D_TOOL.IntValue;
		FormatEx(show_hud.info,sizeof(show_hud.info),"===================\n\
													  ★击杀/爆头  当前玩家: [%d/%d]★\n\
													  ==================="
													  ,g_player_num,maxplayers);
		show_hud.slot = 1;
		show_hud.flag = HUD_FLAG_ALIGN_CENTER|HUD_FLAG_NOBG;
		show_hud.pos  = g_HUDpos[1];
		show_hud.Place();
	}
	
	// PLAYER_LIST
	if( g_show_list & PLAYER_LIST )
		DisplayPlayerList();

	return Plugin_Continue;
}

void DisplayPlayerList()
{
	if( g_max_show_count == 0 )
		return;
		
	//循环出有效玩家，并写入编号。
	//survivor用于更好排序，不用在排序函数判断玩家合法性。
	int total=0;
	int survivor[MAXPLAYERS];
	for(int client = 1; client <= MaxClients; client++)
	{
		if( IsClientInGame(client) && !IsFakeClient(client) &&GetClientTeam(client) == 2 )
		{
			if( IsPlayerAlive(client) && IsClientObserver(client) )//排除旁观者.
				continue;
			
			survivor[total++] = client;
		}
	}
	//survivor[players]数组,通过击杀数量函数killinfo进行排序
	SortCustom1D(survivor,sizeof(survivor),SortKillInfo);
	HUD hud_playerlist;
	for(int i = 0; i < total; i++)
	{
		// 最多只能8个了，没插槽了。
		FormatEx(hud_playerlist.info,sizeof(hud_playerlist.info),"★%d：%d/%d→%N",
				i+1,
				g_player_killspecial[survivor[i]],
				g_player_headshot[survivor[i]],survivor[i]);

		hud_playerlist.slot = i+2;
		hud_playerlist.flag = IsPlayerAlive(survivor[i]) ? HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG : HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_BLINK;
		hud_playerlist.pos  = g_HUDpos[i+2];
		hud_playerlist.Place();
	}
}
//通过playerdeath事件对击杀进行统计
void Event_PlayerDeathInfo(Event event, const char[] name, bool dontBroadcast)
{
    

    int victim = GetClientOfUserId( event.GetInt("userid") );
    if( victim < 1 || victim > MaxClients || !IsClientInGame(victim) )
        return;

    int attacker = GetClientOfUserId( event.GetInt("attacker") );
    if( attacker < 0 || attacker > MaxClients || !IsClientInGame(victim) ) // because attacker = 0 mean it is world.
        return;

    event.BroadcastDisabled = true; // by prehook, set this to prevent the red font of kill info.

    if( !(g_show_list & KILL_LIST) )
        return;
    
    static char killinfo[128];
    if( attacker == 0 ) // kill by world of fall 
    {
        FormatEx(killinfo,sizeof(killinfo),"    %s  %N",g_kill_type[11],victim);
        DisplayKillList(killinfo);
        return;
    }

    if( GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2 ) // kill by specials.
    {
        FormatEx(killinfo,sizeof(killinfo),"%N  %s  %N",attacker,g_kill_type[12],victim);
        DisplayKillList(killinfo);
        return;
    }

    if( GetClientTeam(victim) == 3 ) 
    {
        g_player_killspecial[attacker] += 1; // attacker kill +1
    }

    char weapon_type[64];
    event.GetString("weapon",weapon_type,sizeof(weapon_type));
    // add kill type
    if( strcmp("world",weapon_type) == 0 || strcmp(weapon_type,"worldspawn") == 0 || strcmp(weapon_type,"trigger_hurt") == 0 )
    {
        FormatEx(killinfo,sizeof(killinfo),"    %s  %N",g_kill_type[11],victim);
        DisplayKillList(killinfo);
        return;
    }

    if( !g_weapon_name.ContainsKey(weapon_type) )
        return;
        
    g_weapon_name.GetString(weapon_type,weapon_type,sizeof(weapon_type));
    if( event.GetBool("headshot") )
    {
        g_player_headshot[attacker] += 1;

        if( IsKilledBehindWall(attacker,victim) )
            FormatEx(killinfo,sizeof(killinfo),"%N  %s %s %s  %N",attacker,g_kill_type[13],g_kill_type[14],weapon_type,victim);
        else
            FormatEx(killinfo,sizeof(killinfo),"%N  %s %s  %N",attacker,g_kill_type[14],weapon_type,victim);
    }
    else
    {
        if( IsKilledBehindWall(attacker,victim) )
            FormatEx(killinfo,sizeof(killinfo),"%N  %s %s  %N",attacker,g_kill_type[13],weapon_type,victim);
        else
            FormatEx(killinfo,sizeof(killinfo),"%N  %s  %N",attacker,weapon_type,victim);
    }

    DisplayKillList(killinfo);
}
void DisplayKillList(const char[] info)
{
	HUD kill_list;
	FormatEx(kill_list.info, sizeof(kill_list.info), "%s", info);
	g_hud_killinfo.PushString(info);

	if( g_hud_killinfo.Length < 6 )
	{
		kill_list.slot = g_hud_killinfo.Length + 9;
		kill_list.flag = HUD_FLAG_ALIGN_RIGHT|HUD_FLAG_NOBG;
		kill_list.pos  = g_HUDpos[kill_list.slot];
		kill_list.Place();
	}
	else
	{
		g_hud_killinfo.Erase(0);
		for(int i = 10; i <= 14; i++)
		{
			g_hud_killinfo.GetString(i-10,kill_list.info,sizeof(kill_list.info));
			kill_list.slot = i;
			kill_list.flag = HUD_FLAG_ALIGN_RIGHT|HUD_FLAG_NOBG;
			kill_list.pos  = g_HUDpos[i];
			kill_list.Place();
		}
	}
}

bool IsKilledBehindWall(int attacker,int client)
{
	float vPos_a[3],vPos_c[3];
	GetClientEyePosition(attacker, vPos_a);
	GetClientEyePosition(client,vPos_c);
	Handle hTrace = TR_TraceRayFilterEx(vPos_a, vPos_c,MASK_PLAYERSOLID, RayType_EndPoint,TraceRayNoPlayers,client);
	if( hTrace != null )
	{
		if( TR_DidHit(hTrace) )
		{
			delete hTrace;
			return true;
		}
		delete hTrace;
	}
	delete hTrace;
	return false;
}
bool TraceRayNoPlayers(int entity, int mask, any data)
{
    if( entity == data || (entity >= 1 && entity <= MaxClients) )
    {
        return false;
    }
    return true;
}
// sort the kill 
int SortKillInfo(int elem1, int elem2, const int[] array, Handle hndl)
{
	if (g_player_killspecial[elem1] > g_player_killspecial[elem2]) return -1;
	else if (g_player_killspecial[elem2] > g_player_killspecial[elem1]) return 1;
	else if (elem1 > elem2) return -1;
	else if (elem2 > elem1) return 1;
	return 0;
}
void LoadEventWeaponName()
{
	for(int i = 0; i < sizeof(g_event_weapon_string); i++)
	{
		switch(i)
		{
			case 0: // melee
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[0]);

			case 1,2,3: // pistol,pistol_magnum,dual_pistols
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[1]);

			case 4,5,6: // smg,smg_silenced,smg_mp5
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[2]);

			case 7,8,9,10: // rifle,rifle_ak47,rifle_sg552,rifle_desert
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[3]);

			case 11,12,13,14: // pumpshotgun,shotgun_chrome,autoshotgun,shotgun_spas
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[4]);

			case 15,16,17,18: // hunting_rifle,sniper_military,sniper_scout,sniper_awp
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[5]);

			case 19: // pipe boomb
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[6]);

			case 20,21: // inferno,entityflame
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[7]);
			
			case 22: // rifle_m60,
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[9]);

			case 23: // grenade_launcher_projectile
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[9]);
			
			case 24,25: // boomer,player killed by push
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[10]);
			
			case 26,27,28:
				g_weapon_name.SetString(g_event_weapon_string[i],g_kill_type[11]);
		}
	}
}