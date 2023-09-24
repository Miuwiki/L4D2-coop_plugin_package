#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <miuwiki_serverapi>

#define PLUGIN_VERSION "1.0.0"

#define STORE_AFK 0
#define STORE_DISCONNECT 1

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
	bool auth;
	bool is_autojoin;
	char steamid[MAX_AUTHID_LENGTH];
	char afk_weapon[128];
	float away_time;
	int away_count;
	int join_count;
}

PlayerInfo player[MAXPLAYERS + 1];
Server server;

bool g_bot_is_in_takingover[MAXPLAYERS + 1];

// store player weapon in this round
StringMap g_player_weaponinfo; 
StringMap g_player_serverinfo;

public Plugin myinfo =
{
	name = "[L4D2] Multislots & AFK control in coop",
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

	// look miuwiki_serverapi.sp to find the index.
	cvar_default_solt0 = CreateConVar("l4d2_default_weapon1","0","[-1 = 关闭,0 = 随机,其余主武器请看说明]",0,true,-1.0,true,17.0);
	cvar_default_solt1 = CreateConVar("l4d2_default_weapon2","0","[-1 = 关闭,0 = 随机,手枪和近战请看说明].",0,true,-1.0,true,17.0);
	cvar_default_solt2 = CreateConVar("l4d2_default_weapon3","0","[-1 = 关闭,0 = 随机,1 = 胆汁,2 = 火瓶,3 = 拍棒].",0,true,-1.0,true,3.0);
	cvar_default_solt3 = CreateConVar("l4d2_default_weapon4","0","[-1 = 关闭,0 = 随机,1 = 包,2 = 电击器,3 = 燃烧弹药包,4 = 高爆弹药包].",0,true,-1.0,true,4.0);
	cvar_default_solt4 = CreateConVar("l4d2_default_weapon5","0","[-1 = 关闭,0 = 随机,1 = 药,2 = 针].",0,true,-1.0,true,2.0);
	cvar_default_solt0.AddChangeHook(Cvar_HookCallback);
	cvar_default_solt1.AddChangeHook(Cvar_HookCallback);
	cvar_default_solt2.AddChangeHook(Cvar_HookCallback);
	cvar_default_solt3.AddChangeHook(Cvar_HookCallback);
	cvar_default_solt4.AddChangeHook(Cvar_HookCallback);

	HookEvent("player_death",Event_PlayerDeathInfo);
	HookEvent("round_start",Event_RoundStartInfo);
	// join control
	RegConsoleCmd("sm_join",Cmd_PlayerJoin);

	// afk control
	RegConsoleCmd("sm_away",Cmd_PlayerAfk);

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
// public void OnClientConnected(int client)
// {
// 	if( IsFakeClient(client) )
// 		return;

	
// }
public void OnClientDisconnect(int client) // looks like the data still in server. we can still get the entity info of player.
{
	if( IsFakeClient(client) ) 
		return;

	StorePlayerWeapon(client,STORE_DISCONNECT);
	StorePlayerServerinfo(client);

	player[client].steamid = "";
	player[client].afk_weapon = "";
	player[client].auth = false;
	player[client].is_autojoin = false;
	player[client].away_time = 0.0;
	player[client].away_count = 0;
	player[client].join_count = 0;

	RequestFrame(NextFrame_CheckBotState);
}

public void OnClientPostAdminCheck(int client)
{
	if( IsFakeClient(client) )
		return;
	
	GetClientAuthId(client,AuthId_SteamID64,player[client].steamid,MAX_AUTHID_LENGTH);
	player[client].auth = true;

	char temp[8],info[2][4];
	g_player_serverinfo.GetString(player[client].steamid,temp,sizeof(temp));
	player[client].away_time = 0.0;
	if( strcmp(temp,"") == 0 ) // new player.
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
	int count_join = g_max_join_count > player[client].join_count ? g_max_join_count - player[client].join_count : 0;
	int count_away = g_max_away_count > player[client].away_count ? g_max_away_count - player[client].away_count : 0;
	PrintToChat(client,"\x04[服务器]\x05本局剩余重进次数为 \x04%d \x05次, 剩余闲置次数为 \x04%d \x05次",count_join,count_away);
}
void Event_RoundStartInfo(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 0; i <= MAXPLAYERS; i++)
	{
		player[i].away_time = 0.0;
		player[i].away_count = 0;
		player[i].join_count = 0;
	}
	g_player_serverinfo.Clear();
	
	RequestFrame(NextFrame_SecondRoundGive);
}
public void OnMapStart()
{
	CreateTimer(60.0, Timer_ClearOldWeaponInfo,_,TIMER_FLAG_NO_MAPCHANGE);
}
public void M_OnPlayerFirstSpawn()
{
	RequestFrame(NextFrame_SetDefaultBot);
}
void Event_PlayerDeathInfo(Event event, const char[] name, bool dontBroadcast) // kick dead bot.
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !IsValidClient(client) || !IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR )
		return;

	if( !IsPlayerAlive(client) && server.All > g_default_survivorbot )
	{
		KickClient(client);
	}
}
public int M_OnClientChangeTeam(int client, int new_team)
{
	if( !IsValidClient(client) || IsFakeClient(client) )
		return 0;

	if( GetClientTeam(client) == TEAM_NONE && new_team == TEAM_SURVIVOR )
	{
		PrintToServer("[miuwiki_multislot]: Hook %N change team. old team = %d, new team = %d",client,GetClientTeam(client),new_team);
		CreateTimer(0.2,Timer_SpawnPlayer,GetClientUserId(client),TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		return TEAM_SPEACTOR;
	}

	if( GetClientTeam(client) == TEAM_NONE && new_team == TEAM_SPEACTOR )
	{
		PrintToServer("[miuwiki_multislot]: Hook %N change team. old team = %d, new team = %d",client,GetClientTeam(client),new_team);
		CreateTimer(0.2,Timer_SpawnPlayer,GetClientUserId(client),TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		player[client].is_autojoin = true;
		return 0;
	}

	if( GetClientTeam(client) == TEAM_SPEACTOR && new_team == TEAM_SURVIVOR )
	{
		PrintToServer("[miuwiki_multislot]: Hook %N change team. old team = %d, new team = %d",client,GetClientTeam(client),new_team);
		if( player[client].is_autojoin )
			return TEAM_SPEACTOR;

		return 0;
	}

	return 0;
}

/**
 * join control
 */
Action Cmd_PlayerJoin(int client, int args)
{
	if(args > 1)
		return Plugin_Handled;

	if( !server.IsRoundStart )
		return Plugin_Handled;

	if( !IsValidClient(client)  )
		return Plugin_Handled;
	
	
	if( !IsClientObserver(client) || GetClientTeam(client) != TEAM_SPEACTOR )
	{
		PrintToChat(client,"\x04[服务器]\x05非旁观玩家无法使用该指令!");
		return Plugin_Handled;
	}
		
	if( player[client].auth == false ) // not auth stop.
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
	if( !IsValidClient(client) || IsFakeClient(client) || GetClientTeam(client) > TEAM_SPEACTOR)
		return Plugin_Stop;

	if( !server.IsRoundStart )
	{
		for(int i = 1; i <= MAXPLAYERS; i++)
		{
			hasshow[client] = false;
		}
		return Plugin_Stop;
	}
	
	if( !player[client].auth ) // not auth stop.
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
		if( !IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i) ) // we get a valid survivor bot to takeover here.
			continue;

		if( g_bot_is_in_takingover[i] || M_IsSurvivorBotused(i) )
			continue;
		
		player[client].is_autojoin = false;

		g_bot_is_in_takingover[i] = true;
		M_TakeOverBot(client,i);
		g_bot_is_in_takingover[i] = false;
		
		PrintToServer("[miuwiki_multislot]: Getting server info %N ( join_count = %d, away_count = %d )",client, player[client].join_count,player[client].away_count);
		if( player[client].join_count > g_max_join_count )
		{
			if( IsPlayerAlive(client) )
				ForcePlayerSuicide(client);
			PrintToChat(client,"\x04[服务器]\x05您因超出加入次数变为死亡状态!");
		}
		else
		{
			if( !IsPlayerAlive(client) )
				M_RespawnSurvivor(client);	

			TeleportToSurvivor(client);
			RemovePlayerWeapons(client);
			GiveWeapon(client); // this will check give default weapon or store weapon.
		}
		PrintToServer("[miuwiki_multislot]: %N has takeover a exits bot %N successfully!",client,i);
		
		// we need kick a died survivor bot. don't worry we do this in a loop because we will return after that.
		RequestFrame(NextFrame_CheckBotState);
		return true;
	}

	int bot = M_CreateSurvivorBot(); 
	if( bot != -1 )
	{
		player[client].is_autojoin = false; // set this before takeover, we need identify player join is by console or by my function.

		g_bot_is_in_takingover[bot] = true;
		M_TakeOverBot(client,bot);
		g_bot_is_in_takingover[bot] = false;

		PrintToServer("[miuwiki_multislot]: %N server info ( join_count = %d, away_count = %d )",client, player[client].join_count,player[client].away_count);
		if( player[client].join_count > g_max_join_count )
		{
			if( IsPlayerAlive(client) )
				ForcePlayerSuicide(client);

			PrintToChat(client,"\x04[服务器]\x05您因超出加入次数变为死亡状态!");
		}
		else
		{
			if( !IsPlayerAlive(client) )
				M_RespawnSurvivor(client);
				
			TeleportToSurvivor(client);
			RemovePlayerWeapons(client);
			GiveWeapon(client); // this will check give default weapon or store weapon.
		}
		PrintToServer("[miuwiki_multislot]: %N has takeover a created bot %N successfully!",client,bot);

		// we need kick a died survivor bot. don't worry we do this in a loop because we will return after that.
		RequestFrame(NextFrame_CheckBotState);
		return true;
	}

	
		
	return false;
}

void TeleportToSurvivor(int client)
{
	if( !IsValidClient(client) )
		return;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if( !IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i) )
			continue;
		
		if( GetEntProp(i, Prop_Send, "m_isIncapacitated") && GetEntProp(i, Prop_Send, "m_isHangingFromLedge") ) // handing.
			continue;
		
		float pos[3];
		GetClientAbsOrigin(i,pos);
		TeleportEntity(client,pos,NULL_VECTOR,NULL_VECTOR);
		return;
	}
	
	PrintToServer("[miuwiki_multislot]: No Valid Player To teleport, teleport to the first player.");
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) )
		{
			float pos[3];
			GetClientAbsOrigin(i,pos);
			TeleportEntity(client,pos,NULL_VECTOR,NULL_VECTOR);
			break;
		}
	}
}
/**
 * afk control
 */
public Action M_OnClientAFK(int client)
{
	PrintToServer("[miuwiki_multislot]: %N trying to afk by server, doing it to spector team.", client);
	if( player[client].away_count >= g_max_away_count )
	{
		ForcePlayerSuicide(client);
		PrintToChat(client,"\x04[服务器]\x05您因闲置次数用尽并再次自动闲置而被处死.");
		return Plugin_Handled;
	}

	// we don't need to check 
	SetPlayerWholSpec(client);
	return Plugin_Handled;
}

Action Cmd_PlayerAfk(int client, int args)
{
	if(args > 1)
		return Plugin_Handled;

	SetPlayerWholSpec(client);
	return Plugin_Handled;
}
void SetPlayerWholSpec(int client)
{
	if( !server.IsRoundStart )
		return;

	if( g_is_all_bot_game == 0 )
	{
		if( server.Human <= 1 )
		{
			PrintToChat(client,"\x04[服务器]\x05最后一名幸存者无法闲置!");
			return;
		}
	}
	
	if( M_IsSurvivorBeHold(client) || M_IsSurvivorGetup(client) )
	{
		PrintToChat(client,"\x04[服务器]\x05被控制或起身阶段无法闲置!");
	}

	if( !IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR )
		return;

	if( !IsPlayerAlive(client) )
	{
		PrintToChat(client,"\x04[服务器]\x05死亡期间无法使用指令闲置!");
		return;
	}

	if( player[client].away_count >= g_max_away_count )
	{
		PrintToChat(client,"\x04[服务器]\x05您已用完本局可用的闲置次数!");
		return;
	}
	
	StorePlayerWeapon(client,STORE_AFK);
	ChangeClientTeam(client,TEAM_SPEACTOR);
	player[client].away_count += 1;
	player[client].away_time = GetGameTime();
	int count_away = g_max_away_count > player[client].away_count ? g_max_away_count - player[client].away_count : 0;
	PrintToChat(client,"\x04[服务器]\x05本局剩余闲置次数为 \x04%d \x05次",count_away);
	CreateTimer(1.0,Timer_CheckPlayerAfkTime,GetClientUserId(client),TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	// kick bot if remain bot count is larger than cvar setting.
	RequestFrame(NextFrame_CheckBotState);
}

Action Timer_CheckPlayerAfkTime(Handle timer, int userid)
{
	if( !server.IsRoundStart )
		return Plugin_Stop;

	int client = GetClientOfUserId(userid);
	if( !IsValidClient(client) )
		return Plugin_Stop;

	if( GetClientTeam(client) != TEAM_SPEACTOR )
		return Plugin_Stop;

	int time = RoundToFloor( g_max_away_time - (GetGameTime() - player[client].away_time) );
	PrintHintText(client,"服务器将会在 %d 秒后将您移出服务器\n 输入 !join 加入游戏",time);
	if( time <= 0 )
	{
		KickClientEx(client,"您因闲置超时被服务器移出.");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

/**
 * set bot when each map first.
 */
void NextFrame_SetDefaultBot()
{
	int count;
	int bot_count = server.Bot;

	if( g_default_survivorbot > bot_count )
	{
		count = g_default_survivorbot - bot_count;
		PrintToServer("[miuwiki_multislot]: bot count: %d, cvar count: %d, need create: %d",bot_count,g_default_survivorbot,count);
		for(int i = 1; i <= count; i++)
		{
			if( M_CreateSurvivorBot() == -1 )
			{
				PrintToServer("[miuwiki_multislot]: Failed create survivor bot on round.");
			}
		}
	}
	else if( g_default_survivorbot < bot_count )
	{
		count = bot_count - g_default_survivorbot;
		PrintToServer("[miuwiki_multislot]: bot count: %d, cvar count: %d, need kick:%d",bot_count,g_default_survivorbot,count);
		for(int i = 1; i <= MaxClients; i++)
		{
			if( !IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR )
				continue;

			if( count == 0 )
				break;
			
			KickClient(i);
			count--;
		}
	}
	return;
}
/**
 * set bot when player count change by away or join or exit.
 */
void NextFrame_CheckBotState()
{
	// we kick death bot at first.
	int death_bot[MAXPLAYERS + 1];int index;
	int total = server.All - g_default_survivorbot;
	for(int i = 1; i <= MaxClients; i++)
	{
		if( !IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR )
			continue;

		if( IsPlayerAlive(i) )
			continue;

		death_bot[index] = i;
		index++;
	}
	if( total > 0 )
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if( total == 0 )
				break;
			
			if( !IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR )
				continue;

			if( M_IsSurvivorBotused(i) || g_bot_is_in_takingover[i] )
				continue;

			if( index == 0 )
				KickClient(i);
			else
			{
				KickClient(death_bot[index - 1]);// kick from upper, like kick death_bot[2] after that we kick death_bot[1].
				index--;
			}
			total--;
		}
	}
}
/**
 * give player weapon in second+ round and reset there health.
 */
void NextFrame_SecondRoundGive()
{
	if( server.RoundCount >= 2 )
	{
		// we don't need check every second because it is second+ round.
		// all player have already join game.
		for(int i = 1; i <= MaxClients; i++) 
		{
			if( IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR )
			{
				RemovePlayerWeapons(i);
				GiveDefaultWeapon(i);
				SetEntityHealth(i,100);
			}
		}
	}
}

/**
 * store player join count and away count and health.
 */
void StorePlayerServerinfo(int client)
{
	if( player[client].auth == false )
		return;

	char info[8];
	player[client].join_count += 1;
	FormatEx(info,sizeof(info),"%d.%d",player[client].join_count,player[client].away_count);
	g_player_serverinfo.SetString(player[client].steamid,info);
	PrintToServer("[miuwiki_multislot]: Storing player info %N ( %s )",client,info);
}
/**
 * Store player weapon info.
 * mode means who call the store, 0 = afk, 1 = disconnect
 */
void StorePlayerWeapon(int client, int mode)
{
	if( player[client].auth == false )
		return;

	// since client is not in game but still in connected, IsPlayerAlive and GetClientTeam can't work.
	static char weapon_name[64];
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

	int state;
	for(int i = 0; i < 5; i++)
	{
		ent = GetPlayerWeaponSlot(client, i);
		if( ent == -1 )
		{
			FormatEx(info,sizeof(info),"%s.null",info);
			state++;
			continue;
		}
			
		if( i == 1 ) // pistol or melee
		{
			weapon_name = "null";
			M_GetPlayerMeleeName(client, weapon_name, sizeof(weapon_name));
		}
		else
			GetEntityClassname(ent,weapon_name,sizeof(weapon_name));

		FormatEx(info,sizeof(info),"%s.%s",info,weapon_name);
	}

	if( state == 5 ) // no weapon info, we don't write it in stringmap.
	{
		PrintToServer("[miuwiki_multislot]: Since %N all the weapon info is null, we don't store it. ( %s )",client,info);
		return;
	}

	if( mode == STORE_DISCONNECT )
		g_player_weaponinfo.SetString(player[client].steamid,info);
	else
		FormatEx(player[client].afk_weapon,sizeof(player[].afk_weapon),"%s",info);
	
	PrintToServer("[miuwiki_multislot]: Storing weapon info %N ( %s )",client,info);
}


/**
 * This func will check auth to give store weapon or default weapon.
 */
void GiveWeapon(int client)
{
	if( !IsValidClient(client) )
		return;

	if( IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR || !IsPlayerAlive(client) )
		return;

	if( player[client].auth == false )
	{
		PrintToServer("[miuwiki_multislot]: %N no auth steamid64.",client);
		GiveDefaultWeapon(client);
		return;
	}

	if( player[client].join_count > 0 )
	{
		PrintToServer("[miuwiki_multislot]: %N join game second time, give him default weapon.",client);
		GiveDefaultWeapon(client);
		return;
	}

	static char info[128];
	if( strcmp(player[client].afk_weapon,"") != 0 ) // use afk weapon info at first.
	{
		FormatEx(info,sizeof(info),"%s",player[client].afk_weapon);
	}
	else if( !g_player_weaponinfo.GetString(player[client].steamid,info,sizeof(info)) ) // get weapon info.
	{
		PrintToServer("[miuwiki_multislot]: %N is new player, give him default weapon.",client);
		GiveDefaultWeapon(client);
		return;
	}

	

	PrintToServer("[miuwiki_multislot]: Getting weapon info %N ( %s )",client,info);
	char weapon[7][32];
	ExplodeString(info,".",weapon,7,32);
	for(int i = 2; i < 7; i++)
	{
		switch(i)
		{
			case 2:
			{
				if( strcmp(weapon[i],"null") == 0 )
					continue;

				int weapon_ent = GivePlayerItem(client,weapon[i]);
				if( weapon_ent == -1)
				{
					PrintToServer("[miuwiki_multislot]: client %d spawn weapon slot %d failed.",client,i);
					continue;
				}
				int type = GetEntProp(weapon_ent, Prop_Send, "m_iPrimaryAmmoType");
				SetEntProp(client,Prop_Send,"m_iAmmo",StringToInt(weapon[1]),_,type);
				SetEntProp(weapon_ent,Prop_Send,"m_iClip1",StringToInt(weapon[0]));
			}
			case 3:
			{
				if( strcmp(weapon[i],"null") == 0 )
					GivePlayerItem(client,"weapon_pistol");
				else
					GivePlayerItem(client,weapon[i]);
			}
			case 4,5,6:
			{
				if( strcmp(weapon[i],"null") == 0 )
					continue;

				int weapon_ent = GivePlayerItem(client,weapon[i]);
				if( weapon_ent == -1)
				{
					PrintToServer("[miuwiki_multislot]: client %d spawn weapon slot %d failed.",client,i);
					continue;
				}
			}
		}
	}
}
void GiveDefaultWeapon(int client)
{
	if( !IsValidClient(client) )
		return;

	if( !IsPlayerAlive(client) )
		return;
	
	if( g_default_slot0 != -1 )
		M_GivePlayerWeapon(client, 0, g_default_slot0 - 1);
	if( g_default_slot1 != -1 )
		M_GivePlayerWeapon(client, 1, g_default_slot1 - 1);
	if( g_default_slot2 != -1 )
		M_GivePlayerWeapon(client, 2, g_default_slot2 - 1);
	if( g_default_slot3 != -1 )
		M_GivePlayerWeapon(client, 3, g_default_slot3 - 1);
	if( g_default_slot4 != -1 )
		M_GivePlayerWeapon(client, 4, g_default_slot4 - 1);
}

void RemovePlayerWeapons(int client)
{
	if( !IsValidClient(client) )
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
/**
 * we clear the old weapon info after 60s in new map.
 */
Action Timer_ClearOldWeaponInfo(Handle timer)
{
	g_player_weaponinfo.Clear();
	PrintToServer("[miuwiki_multislot]: 60s clear old weapon info.");
	return Plugin_Handled;
}

bool IsValidClient(int client)
{
	if( client < 1 || client > MaxClients || !IsClientInGame(client) )
		return false;
	
	return true;
}