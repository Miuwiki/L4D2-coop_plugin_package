#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <miuwiki_serverapi>

#define PLUGIN_VERSION "1.0.0"
#define TEAM_NONE 0
#define TEAM_SPEACTOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

ConVar L4DToolZ;
ConVar AllBotGame; int g_is_all_bot_game;
ConVar cvar_default_survivorbot; int g_default_survivorbot;
ConVar cvar_max_away_time; int g_max_away_time;
ConVar cvar_max_away_count; int g_max_away_count;
ConVar cvar_max_player; int g_max_player;
ConVar cvar_max_join_count; int g_max_join_count;

ConVar 
cvar_default_solt0,
cvar_default_solt1,
cvar_default_solt2,
cvar_default_solt3,
cvar_default_solt4;

int 
g_default_slot0,
g_default_slot1,
g_default_slot2,
g_default_slot3,
g_default_slot4;

enum struct PlayerInfo
{
	char steamid[MAX_AUTHID_LENGTH];
	float away_time;
	int away_count;
	int join_count;

	bool get_weapon;
}
PlayerInfo player[MAXPLAYERS + 1];

bool g_round_start;
bool g_bot_is_in_takingover[MAXPLAYERS + 1];

StringMap g_player_weaponinfo;
StringMap g_player_weaponinfo_clone;
StringMap g_player_serverinfo;

public Plugin myinfo =
{
	name = "Multislots in coop",
	author = "Miuwiki",
	description = "More slot in coop | Melee weapon unlock | AFK control",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnAllPluginsLoaded() // check base plugin.
{
    if( !LibraryExists("miuwiki_serverapi") )
        SetFailState("Missing or failed to load [miuwiki_serverapi.smx], try again.");
}

public void OnPluginStart()
{
	L4DToolZ = FindConVar("sv_maxplayers");
	AllBotGame = FindConVar("sb_all_bot_game");

	cvar_default_survivorbot = CreateConVar("l4d2_default_survivorbot","1","初始bot数量",0,true,1.0,true,31.0);
	cvar_max_away_time = CreateConVar("l4d2_max_away_time","300","闲置时间, 超时将被踢出(秒).",0,true,1.0);
 	cvar_max_away_count = CreateConVar("l4d2_max_away_count","2","每局最大闲置次数.",0,true,0.0,true,30.0);
	cvar_max_join_count = CreateConVar("l4d2_max_join_count","1","退出重进最大次数, 超过次数将不能接管存活bot.",0,true,0.0,true,30.0);
	cvar_max_player = CreateConVar("l4d2_max_player","12","服务器人数.",0,true,1.0,true,30.0);

	cvar_default_solt0 = CreateConVar("l4d2_default_weapon1","0","[-1 = 关闭,0 = 随机,其余主武器请看说明]",0);
	cvar_default_solt1 = CreateConVar("l4d2_default_weapon2","0","[-1 = 关闭,0 = 随机,1 = 小手枪,2 = 马格南, 3 = 随机近战].",0);
	cvar_default_solt2 = CreateConVar("l4d2_default_weapon3","0","[-1 = 关闭,0 = 随机,1 = 胆汁,2 = 火瓶,3 = 拍棒].",0);
	cvar_default_solt3 = CreateConVar("l4d2_default_weapon4","0","[-1 = 关闭,0 = 随机,1 = 包,2 = 电击器,3 = 燃烧弹药包,4 = 高爆弹药包].",0);
	cvar_default_solt4 = CreateConVar("l4d2_default_weapon5","0","[-1 = 关闭,0 = 随机,1 = 药,2 = 针 ].",0);
	cvar_default_solt0.AddChangeHook(Cvar_HookCallback);
	cvar_default_solt1.AddChangeHook(Cvar_HookCallback);
	cvar_default_solt2.AddChangeHook(Cvar_HookCallback);
	cvar_default_solt3.AddChangeHook(Cvar_HookCallback);
	cvar_default_solt4.AddChangeHook(Cvar_HookCallback);

	HookEvent("player_team",Event_PlayerTeamInfo);
	HookEvent("player_death",Event_PlayerDeathInfo);
	HookEvent("round_start",Event_RoundStartInfo);
	HookEvent("round_end",Event_RoundEndInfo);
	HookEvent("player_spawn",Event_PlayerSpawnInfo);
	// join control
	RegConsoleCmd("sm_join",Cmd_PlayerJoin);

	// afk control
	RegConsoleCmd("sm_away",Cmd_PlayerAfk);
	AddCommandListener(SetPlayerSpec, "go_away_from_keyboard");

	// AddCommandListener(Listener_spec_next, "spec_next"); no afk so don't need consider that, and join the game also don't fire this command in my plugin.

	g_player_weaponinfo = new StringMap();
	g_player_serverinfo = new StringMap();


	if( !IsModelPrecached("models/infected/witch.mdl") ) 			PrecacheModel("models/infected/witch.mdl", false);
	if( !IsModelPrecached("models/infected/witch_bride.mdl") ) 		PrecacheModel("models/infected/witch_bride.mdl", false);
}


public void OnConfigsExecuted() // every map only work once.
{
	g_default_survivorbot =  cvar_default_survivorbot.IntValue;
	g_is_all_bot_game = AllBotGame.IntValue;

	g_max_away_time = cvar_max_away_time.IntValue;
	g_max_away_count = cvar_max_away_count.IntValue;
	g_max_join_count = cvar_max_join_count.IntValue;
	g_max_player = cvar_max_player.IntValue;
	
	L4DToolZ.IntValue = g_max_player;
	GetCvar();
}
void Cvar_HookCallback(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvar();
}
void GetCvar()
{
	g_default_slot0 = cvar_default_solt0.IntValue;
	g_default_slot1 = cvar_default_solt1.IntValue;
	g_default_slot2 = cvar_default_solt2.IntValue;
	g_default_slot3 = cvar_default_solt3.IntValue;
	g_default_slot4 = cvar_default_solt4.IntValue;
}



/**
 * start 
 */
public void OnClientConnected(int client)
{
	if( IsFakeClient(client) )
		return;

	FormatEx(player[client].steamid, sizeof(player[].steamid),"");
	player[client].away_time = 0.0;
	player[client].away_count = 0;
	player[client].join_count = 0;
	player[client].get_weapon = false;
}

public void OnClientDisconnect(int client) // looks like the data still in server. we can still get the entity info of player.
{
	if( IsFakeClient(client) || GetClientTeam(client) != 2 )
		return;

	StorePlayerWeapon(client);
	StorePlayerServerinfo(client);
	g_player_weaponinfo_clone.Remove(player[client].steamid); // this remove the weapon info store in this round.
}

public void OnClientPostAdminCheck(int client)
{
	if( IsFakeClient(client) )
		return;
	
	GetClientAuthId(client,AuthId_SteamID64,player[client].steamid,MAX_AUTHID_LENGTH);

	char temp[8],info[2][4];
	g_player_serverinfo.GetString(player[client].steamid,temp,sizeof(temp));
	player[client].away_time = 0.0;
	if( strcmp(temp,"") == 0 )
	{
		player[client].join_count = 0;
		player[client].away_count = 0;
	}
	else
	{
		ExplodeString(temp,".",info,2,4);
		player[client].join_count = StringToInt(info[0]);
		player[client].away_count = StringToInt(info[1]);
	}
	PrintToChat(client,"\x04[服务器]\x05 STEAMID 验证成功!");
	PrintToChat(client,"\x04[服务器]\x05您本局可用的重进次数为 \x04%d \x05次",g_max_join_count - player[client].join_count);
	PrintToChat(client,"\x04[服务器]\x05您本局可用的闲置次数为 \x04%d \x05次",g_max_away_count - player[client].away_count);
}
void Event_RoundStartInfo(Event event, const char[] name, bool dontBroadcast)
{
	g_round_start = true;
	for(int i = 0; i <= MAXPLAYERS; i++)
	{
		player[i].away_time = 0.0;
		player[i].away_count = 0;
		player[i].join_count = 0;
		player[i].get_weapon = false;
	}
	delete g_player_weaponinfo_clone;
	g_player_weaponinfo_clone = g_player_weaponinfo.Clone();
	g_player_weaponinfo.Clear();
	g_player_serverinfo.Clear();
	CreateTimer(60.0,Timer_ClearOldWeaponInfo,_,TIMER_FLAG_NO_MAPCHANGE);
	// CreateTimer(1.0,Timer_GiveAllPlayerWeapon,_,TIMER_FLAG_NO_MAPCHANGE);
}
void Event_RoundEndInfo(Event event, const char[] name, bool dontBroadcast)
{
	g_round_start = false;
	for(int i = 0; i <= MAXPLAYERS; i++)
	{
		player[i].get_weapon = false;
	}
}
public void OnMapEnd()
{
	g_round_start = false;
}

void Event_PlayerDeathInfo(Event event, const char[] name, bool dontBroadcast) // kick bot when dead but the count need to larger than default bot.
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client == 0 || !IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != 2)
		return;
	
	if( !IsPlayerAlive(client) && M_SurvivorCount(COUNT_BOT) > g_default_survivorbot )
	{
		KickClient(client);
	}
}
void Event_PlayerSpawnInfo(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client == 0 || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR )
		return;

	CreateTimer(0.1,Timer_SetDefaultBot,_,TIMER_FLAG_NO_MAPCHANGE);
	if( !player[client].get_weapon )
	{
		RemovePlayerWeapons(client);
		GiveWeapon(client); // this will check give default weapon or store weapon.
		player[client].get_weapon = true;
	}
}

void Event_PlayerTeamInfo(Event event, const char[] name, bool dontBroadcast) // this event due the sutation of join.
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client == 0 || !IsClientInGame(client) || IsFakeClient(client))
		return;

	int newteam = GetEventInt(event,"team");
	int oldteam = GetEventInt(event,"oldteam");
	// new player 0=>1 mean come to spec, 0=>2 mean become survivor already.
	switch(oldteam)
	{
		case TEAM_NONE: // 0=>1, 0=>2
		{
			if( newteam == TEAM_SPEACTOR ) // make player join automatically by my function.
				CreateTimer(0.2,Timer_SpawnPlayer,GetClientUserId(client),TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

			else if( newteam == TEAM_SURVIVOR ) // change it to be a spector and then do auth.
				RequestFrame(ChangeAutoSpawnTeam,GetClientUserId(client));
		}
		case TEAM_SURVIVOR: // 2=>1
		{
			if( newteam == TEAM_SPEACTOR )
				player[client].get_weapon = false;
		}
	}
}
void ChangeAutoSpawnTeam(int userid)
{
	if( !g_round_start )
		return;

	int client = GetClientOfUserId(userid);
	if( client == 0 || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR)
		return;

	ChangeClientTeam(client,TEAM_SPEACTOR);
	CreateTimer(0.2,Timer_SpawnPlayer,GetClientUserId(client),TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return;
}
Action Timer_ClearOldWeaponInfo(Handle timer)
{
	if( !g_round_start )
		return Plugin_Stop;

	// all player auth, we clear the clone weapon info to prevent player get it after all player auth.
	g_player_weaponinfo_clone.Clear();
	return Plugin_Stop;
}
/**
 * join control
 */
Action Cmd_PlayerJoin(int client, int args)
{
	if(args > 1)
		return Plugin_Handled;

	if( !g_round_start )
		return Plugin_Handled;

	if( !IsClientInGame(client)  )
		return Plugin_Handled;
	
	
	if( !IsClientObserver(client) || GetClientTeam(client) != TEAM_SPEACTOR )
	{
		PrintToChat(client,"\x04[服务器]\x05非旁观玩家无法使用该指令!");
		return Plugin_Handled;
	}
		
	if( strcmp(player[client].steamid,"") == 0 ) // not auth stop.
	{
		PrintToChat(client,"\x04[服务器]\x05验证steam中, 请稍后加入!");
		return Plugin_Handled;
	}
		

	CreateTimer(0.2,Timer_SpawnPlayer,GetClientUserId(client),TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}
Action Timer_SpawnPlayer(Handle timer, int userid)
{
	static bool hasshow[MAXPLAYERS + 1];

	int client = GetClientOfUserId(userid);
	if( client == 0 || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) > TEAM_SPEACTOR)
		return Plugin_Stop;

	if( !g_round_start )
	{
		hasshow[client] = false;
		return Plugin_Stop;
	}
	
	if( strcmp(player[client].steamid,"") == 0 ) // not auth stop.
	{
		if( !hasshow )
		{
			PrintToChat(client,"\x04[服务器]\x05认证steam中, 即将自动加入.");
			hasshow[client] = true;
		}
		return Plugin_Continue;
	}
	
	if( SetPlayerJoinGame(client) )
	{
		hasshow[client] = false;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
bool SetPlayerJoinGame(int client)// let a player join in game. true mean success, false otherwise.
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if( !IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR )
			continue;

		if( g_bot_is_in_takingover[i] || M_IsSurvivorBotused(i) )
			continue;
		
		g_bot_is_in_takingover[i] = true;
		M_TakeOverBot(client,i);
		g_bot_is_in_takingover[i] = false;

		LogMessage("Player info: join_count:%d, away_count:%d", player[client].join_count,player[client].away_count);
		if( player[client].join_count > g_max_join_count )
		{
			if( IsPlayerAlive(client) )
			{
				ForcePlayerSuicide(client);
				PrintToChat(client,"\x04[服务器]\x05您因超出加入次数变为死亡状态!");
			}
		}
		else
		{
			if( !IsPlayerAlive(client) )
				M_RespawnSurvivor(client);
		}
		LogMessage("Player %N has takeover a exits bot %N successfully!",client,i);
		return true;
	}

	int bot = M_CreateSurvivorBot(); 
	if( bot != -1 )
	{
		g_bot_is_in_takingover[bot] = true;
		M_TakeOverBot(client,bot);
		g_bot_is_in_takingover[bot] = false;

		LogMessage("Player info: join_count:%d, away_count:%d", player[client].join_count,player[client].away_count);
		if( player[client].join_count > g_max_join_count )
		{
			if( IsPlayerAlive(client) )
			{
				ForcePlayerSuicide(client);
				PrintToChat(client,"\x04[服务器]\x05您因超出加入次数变为死亡状态!");
			}
		}
		else
		{
			if( !IsPlayerAlive(client) )
				M_RespawnSurvivor(client);
		}
		LogMessage("Player %N has takeover a created bot %N successfully!",client,bot);
		return true;
	}
	return false;
}

/**
 * afk control
 */
Action Cmd_PlayerAfk(int client, int args)
{
	if(args > 1)
		return Plugin_Handled;

	SetPlayerWholSpec(client);
	return Plugin_Handled;
}
Action SetPlayerSpec(int client, const char[] command, int argc)
{
	SetPlayerWholSpec(client);
	return Plugin_Handled;
}
void SetPlayerWholSpec(int client)
{
	if( !g_round_start )
		return;

	if( g_is_all_bot_game == 0 )
	{
		int total;
		for(int i = 1; i <= MaxClients; i++)
		{
			if( IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 )
				total++;
		}
		if( total <= 1 )
		{
			PrintToChat(client,"\x04[服务器]\x05最后一名幸存者无法闲置!");
			return;
		}
		
	}
	
	if( M_IsSurvivorBeHold(client) || M_IsSurvivorGetup(client) )
	{
		PrintToChat(client,"\x04[服务器]\x05被控制或起身阶段无法闲置!");
	}

	if( !IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR || !IsPlayerAlive(client))
		return;

	if( player[client].away_count >= g_max_away_count )
	{
		PrintToChat(client,"\x04[服务器]\x05您已用完本局可用的闲置次数!");
		return;
	}

	StorePlayerWeapon(client);
	ChangeClientTeam(client,TEAM_SPEACTOR);
	player[client].away_count += 1;
	player[client].away_time = GetGameTime();
	CreateTimer(1.0,Timer_CheckPlayerAfkTime,GetClientUserId(client),TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	// kick bot.
	int count = M_SurvivorCount(COUNT_BOT) - g_default_survivorbot;
	if( count > 0 )
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if( !IsClientInGame(i) || GetClientTeam(i) != 2 || !IsFakeClient(i))
				continue;
			
			if( count == 0 )
				break;
			
			KickClient(i);
			count--;
		}
	}
	
	return;
}
Action Timer_CheckPlayerAfkTime(Handle timer, int userid)
{
	if( !g_round_start )
		return Plugin_Stop;

	int client = GetClientOfUserId(userid);
	if( client < 1 || client > MaxClients || !IsClientInGame(client) )
		return Plugin_Stop;

	if( GetClientTeam(client) != TEAM_SPEACTOR )
		return Plugin_Stop;

	int time = RoundToFloor( g_max_away_time - (GetGameTime() - player[client].away_time) );
	PrintHintText(client,"服务器将会在 %d 秒后将您移出服务器.",time);
	if( time <= 0 )
	{
		KickClientEx(client,"您因闲置超时被服务器移出.");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

/**
 * bot control.
 */
Action Timer_SetDefaultBot(Handle timer)
{
	int count;
	int bot_count = M_SurvivorCount(COUNT_BOT);

	if( g_default_survivorbot > bot_count )
	{
		count = g_default_survivorbot - bot_count;
		LogMessage("Bot count: %d, cvar count: %d, need create: %d",bot_count,g_default_survivorbot,count);
		for(int i = 1; i <= count; i++)
		{
			if( M_CreateSurvivorBot() == -1 )
			{
				LogMessage("Failed create survivor bot on round.");
			}
		}
	}
	else if( g_default_survivorbot < bot_count )
	{
		count = bot_count - g_default_survivorbot;
		LogMessage("Bot count: %d, cvar count: %d, need kick:%d",bot_count,g_default_survivorbot,count);
		for(int i = 1; i <= MaxClients; i++)
		{
			if( !IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != 2 )
				continue;

			if( count == 0 )
				break;
			
			KickClient(i);
			count--;
		}
	}
	return Plugin_Handled;
}

/**
 * server info
 */
void StorePlayerServerinfo(int client)
{
	if( strcmp(player[client].steamid,"") == 0 )
		return;

	char info[8];
	player[client].join_count += 1;
	FormatEx(info,sizeof(info),"%d.%d",player[client].join_count,player[client].away_count);
	g_player_serverinfo.SetString(player[client].steamid,info);
	LogMessage("Store player_info: %s",info);
}

/**
 * weapon control.
 */
void StorePlayerWeapon(int client)
{
	if( strcmp(player[client].steamid,"") == 0 )
		return;

	static char weapon_name[32];
	static char info[128];
	int ent = GetPlayerWeaponSlot(client, 0);
	if( ent == -1 )
	{
		FormatEx(info,sizeof(info),"0.0");
	}
	else
	{
		int clip = GetEntProp(ent, Prop_Send, "m_iClip1");
		int type = GetEntProp(ent, Prop_Send, "m_iPrimaryAmmoType");
		int bullet = GetEntProp(client, Prop_Send, "m_iAmmo", _, type);
		FormatEx(info,sizeof(info),"%d.%d",clip,bullet);
	}

	for(int i = 0; i < 5; i++)
	{
		ent = GetPlayerWeaponSlot(client, i);
		if( ent == -1 )
		{
			FormatEx(info,sizeof(info),"%s.null",info);
			continue;
		}
			
		GetEntityClassname(ent,weapon_name,sizeof(weapon_name));
		FormatEx(info,sizeof(info),"%s.%s",info,weapon_name);
	}
	g_player_weaponinfo.SetString(player[client].steamid,info);
	g_player_weaponinfo_clone.SetString(player[client].steamid,info);
	LogMessage("store weapon_info: %s",info);
}

/**
 * This func will check auth to give store weapon or default weapon.
 */
void GiveWeapon(int client)
{
	if( client == 0 || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2 )
		return;
	if( !IsPlayerAlive(client) )
		return;

	static char info[128];
	
	if( strcmp(player[client].steamid,"") == 0 )
	{
		LogMessage("client %d no auth steamid64.",client);
		GiveDefaultWeapon(client);
		return;
	}

	if( !g_player_weaponinfo_clone.GetString(player[client].steamid,info,sizeof(info)) )
	{
		LogMessage("New player join game: %N, give default weapon .",client);
		GiveDefaultWeapon(client);
		return;
	}

	LogMessage("Get weapon_info: %s",info);
	char weapon[7][32];
	ExplodeString(info,".",weapon,7,32);
	for(int i = 2; i < 7; i++)
	{
		if( strcmp(weapon[i],"null") == 0 )
			continue;

		if( i == 2 )
		{
			int weapon_ent = GivePlayerItem(client,weapon[i]);
			if( weapon_ent == -1)
			{
				LogMessage("client %d spawn weapon slot %d failed.",client,i);
				continue;
			}
			int type = GetEntProp(weapon_ent, Prop_Send, "m_iPrimaryAmmoType");
			SetEntProp(client,Prop_Send,"m_iAmmo",StringToInt(weapon[1]),_,type);
			SetEntProp(weapon_ent,Prop_Send,"m_iClip1",StringToInt(weapon[0]));
		}
		else if( i == 3 )
		{
			if( strcmp(weapon[i],"weapon_melee") == 0 )
				M_GivePlayerWeapon(client,1,-1);
		}
		else
		{
			int weapon_ent = GivePlayerItem(client,weapon[i]);
			if( weapon_ent == -1)
			{
				LogMessage("client %d spawn weapon slot %d failed.",client,i);
				continue;
			}
		}
	}
}
void GiveDefaultWeapon(int client)
{
	if( client < 0 || client > MaxClients || !IsClientInGame(client) )
		return;
	if( !IsPlayerAlive(client) )
		return;
	
	if( g_default_slot4 != -1 )
		M_GivePlayerWeapon(client, 4, g_default_slot4 - 1);
	if( g_default_slot3 != -1 )
		M_GivePlayerWeapon(client, 3, g_default_slot3 - 1);
	if( g_default_slot2 != -1 )
		M_GivePlayerWeapon(client, 2, g_default_slot2 - 1);
	if( g_default_slot1 != -1 )
	{
		if( g_default_slot1 == 3 )
			M_GivePlayerWeapon(client, 1, -1);
		else
			M_GivePlayerWeapon(client, 1, g_default_slot1 - 1);
	}
	if( g_default_slot0 != -1 )
		M_GivePlayerWeapon(client, 0, g_default_slot0 - 1);
}
void RemovePlayerWeapons(int client)
{
	if( client < 0 || client > MaxClients || !IsClientInGame(client) )
		return;
	if( !IsPlayerAlive(client) )
		return;

	int weapon;
	for(int i = 0; i < 5; i++)
    {
        weapon = GetPlayerWeaponSlot(client, i);
        if( weapon <= 31 )
			continue;

        RemovePlayerItem(client, weapon);
        RemoveEntity(weapon);
	}
}
