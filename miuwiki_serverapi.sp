#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <sourcescramble>
#include <left4dhooks>

#define GAME_DATA "miuwiki_serverapi"
#define PLUGIN_VERSION "1.0.0"
#define TEAM_NONE 0
#define TEAM_SPEACTOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
/**
 * from rygive nextbot
 */
#define CLASS_SMOKER	1
#define CLASS_BOOMER	2
#define CLASS_HUNTER	3
#define CLASS_SPITTER	4
#define CLASS_JOCKEY	5
#define CLASS_CHARGER	6
#define CLASS_TANK	    8

#define NAME_CreateSmoker	"NextBotCreatePlayerBot<Smoker>"
#define NAME_CreateBoomer	"NextBotCreatePlayerBot<Boomer>"
#define NAME_CreateHunter	"NextBotCreatePlayerBot<Hunter>"
#define NAME_CreateSpitter	"NextBotCreatePlayerBot<Spitter>"
#define NAME_CreateJockey	"NextBotCreatePlayerBot<Jockey>"
#define NAME_CreateCharger	"NextBotCreatePlayerBot<Charger>"
#define NAME_CreateTank		"NextBotCreatePlayerBot<Tank>"

Handle
	g_hSDK_NextBotCreatePlayerBot_Smoker,
	g_hSDK_NextBotCreatePlayerBot_Boomer,
	g_hSDK_NextBotCreatePlayerBot_Hunter,
	g_hSDK_NextBotCreatePlayerBot_Spitter,
	g_hSDK_NextBotCreatePlayerBot_Jockey,
	g_hSDK_NextBotCreatePlayerBot_Charger,
	g_hSDK_NextBotCreatePlayerBot_Tank;

/**
 * from rygive respawn 
 */
Handle  g_hSDK_Call_RoundRespawn;
Address g_pRespawn;
Address g_pResetStatCondition;

/**
 * from bot by soralll
 */
Handle g_hSDK_SurvivorBot_SetHumanSpectator;
Handle g_hSDK_CTerrorPlayer_TakeOverBot;
Handle g_hSDK_NextBotCreatePlayerBot_SurvivorBot;

/**
 * from BHaType ragdoll
 */
Handle g_hSDK_CreateRagdoll;
MemoryBlock memory;

/**
 * melee unlocked
 */
ArrayList g_melee_script_name;

/**
 * from survivor_identiy_fix.
 */
DynamicDetour g_Dtour_SetModel;

/**
 * from survivor_afk_fix.
 */
GlobalForward g_hGF_GoAwayFromKeyBroad;

/**
 * first player spawn to do someting.
 */
GlobalForward g_hGF_PlayerFirstSpawn;
/**
 * client take over hook.
 */
GlobalForward g_hGF_ClientChangeTeam;

/**
 * my server info.
 */
#define Z_EASY 0
#define Z_NORMAL 1
#define Z_HARD 2
#define Z_IMPOSSIBLE 3
ConVar 
	cvar_difficult;

char 
	g_player_model[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

bool 
	g_first_player_spawn,
	g_round_start;
int 
	g_round_count = 1;



public Plugin myinfo =
{
	name = "[L4D2] Server Info Native API",
	author = "Miuwiki",
	description = "Useful native for coop server info.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

static const char g_slot0_name[][] = 
{
	"weapon_smg",						// UZI微冲
	"weapon_smg_mp5",					// MP5
	"weapon_smg_silenced",				// MAC微冲
	"weapon_pumpshotgun",				// 木喷
	"weapon_shotgun_chrome",			// 铁喷
	"weapon_rifle",						// M16步枪
	"weapon_rifle_desert",				// 三连步枪
	"weapon_rifle_ak47",				// AK47
	"weapon_rifle_sg552",				// SG552
	"weapon_autoshotgun",				// 一代连喷
	"weapon_shotgun_spas",				// 二代连喷
	"weapon_hunting_rifle",				// 木狙
	"weapon_sniper_military",			// 军狙
	"weapon_sniper_scout",				// 鸟狙
	"weapon_sniper_awp",				// AWP
	"weapon_rifle_m60",					// M60
	"weapon_grenade_launcher"			// 榴弹发射器
};
static const char g_slot1_name[][] = 
{
	"weapon_pistol",					// 小手枪
	"weapon_pistol_magnum",				// 马格南
	"weapon_chainsaw",					// 电锯
	"fireaxe",							// 斧头
	"frying_pan",						// 平底锅
	"machete",							// 砍刀
	"baseball_bat",						// 棒球棒
	"crowbar",							// 撬棍
	"cricket_bat",						// 球拍
	"tonfa",							// 警棍
	"katana",							// 武士刀
	"electric_guitar",					// 电吉他
	"knife",							// 小刀
	"golfclub",							// 高尔夫球棍
	"shovel",							// 铁铲
	"pitchfork",						// 草叉
	"riotshield",						// 盾牌
};
static const char g_slot2_name[][] = 
{
	"weapon_vomitjar",					// 胆汁瓶
	"weapon_molotov",					// 燃烧瓶
	"weapon_pipe_bomb",					// 管制炸弹
};
static const char g_slot3_name[][] = 
{
	"weapon_first_aid_kit",				// 医疗包
	"weapon_defibrillator",				// 电击器
	"weapon_upgradepack_incendiary",	// 燃烧弹药包
	"weapon_upgradepack_explosive",		// 高爆弹药包
};
static const char g_slot4_name[][] = 
{
	"weapon_pain_pills",				// 止痛药
	"weapon_adrenaline",				// 肾上腺素
};

static const char g_slot0_model[][] =
{
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_smg_mp5.mdl",
	"models/w_models/weapons/w_smg_a.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	"models/w_models/weapons/w_shotgun.mdl",
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_desert_rifle.mdl",
	"models/w_models/weapons/w_rifle_ak47.mdl",
	"models/w_models/weapons/w_rifle_sg552.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_shotgun_spas.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_sniper_military.mdl",
	"models/w_models/weapons/w_sniper_scout.mdl",
	"models/w_models/weapons/w_sniper_awp.mdl",
	"models/w_models/weapons/w_m60.mdl",
	"models/w_models/weapons/w_grenade_launcher.mdl",
};
static const char g_slot1_model[][] =
{
	"models/w_models/weapons/w_pistol_a.mdl",
	"models/w_models/weapons/w_desert_eagle.mdl",
	"models/weapons/melee/w_chainsaw.mdl",
	"models/weapons/melee/w_fireaxe.mdl",
	"models/weapons/melee/w_frying_pan.mdl",
	"models/weapons/melee/w_machete.mdl",
	"models/weapons/melee/w_bat.mdl",
	"models/weapons/melee/w_crowbar.mdl",
	"models/weapons/melee/w_cricket_bat.mdl",
	"models/weapons/melee/w_tonfa.mdl",
	"models/weapons/melee/w_katana.mdl",
	"models/weapons/melee/w_electric_guitar.mdl",
	"models/w_models/weapons/w_knife_t.mdl",
	"models/weapons/melee/w_golfclub.mdl",
	"models/weapons/melee/w_shovel.mdl",
	"models/weapons/melee/w_pitchfork.mdl",
	"models/weapons/melee/w_riotshield.mdl",
};
static const char g_slot1_vmodel[][] = 
{
	"models/v_models/weapons/v_pistol_a.mdl",
	"models/v_models/weapons/v_desert_eagle.mdl",
    "models/weapons/melee/v_fireaxe.mdl",
    "models/weapons/melee/v_frying_pan.mdl",
    "models/weapons/melee/v_machete.mdl",
    "models/weapons/melee/v_bat.mdl",
    "models/weapons/melee/v_crowbar.mdl",
    "models/weapons/melee/v_cricket_bat.mdl",
    "models/weapons/melee/v_tonfa.mdl",
    "models/weapons/melee/v_katana.mdl",
    "models/weapons/melee/v_electric_guitar.mdl",
    "models/v_models/v_knife_t.mdl",
    "models/weapons/melee/v_golfclub.mdl",
    "models/weapons/melee/v_shovel.mdl",
    "models/weapons/melee/v_pitchfork.mdl",
    "models/weapons/melee/v_riotshield.mdl",
};
static const char g_slot2_model[][] =
{
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/w_models/weapons/w_eq_pipebomb.mdl",
	"models/w_models/weapons/w_eq_bile_flask.mdl",
};
static const char g_slot3_model[][] =
{
	"models/w_models/weapons/w_eq_medkit.mdl",
	"models/w_models/weapons/w_eq_defibrillator.mdl",
	"models/w_models/weapons/w_eq_incendiary_ammopack.mdl",
	"models/w_models/weapons/w_eq_explosive_ammopack.mdl",
};
static const char g_slot4_model[][] =
{
	"models/w_models/weapons/w_eq_adrenaline.mdl",
	"models/w_models/weapons/w_eq_painpills.mdl"
};
static const char g_survivor_model[][] =
{
	"models/survivors/survivor_teenangst.mdl",
	"models/survivors/survivor_biker.mdl",
	"models/survivors/survivor_manager.mdl",
	"models/survivors/survivor_namvet.mdl",
	"models/survivors/survivor_gambler.mdl",
	"models/survivors/survivor_coach.mdl",
	"models/survivors/survivor_mechanic.mdl",
	"models/survivors/survivor_producer.mdl",
};

int g_slot0_wmodel_index[sizeof(g_slot0_model)];
int g_slot1_wmodel_index[sizeof(g_slot1_model)];
int g_slot1_vmodel_index[sizeof(g_slot1_vmodel)];
int g_slot2_wmodel_index[sizeof(g_slot2_model)];
int g_slot3_wmodel_index[sizeof(g_slot3_model)];
int g_slot4_wmodel_index[sizeof(g_slot4_model)];
int g_survivor_model_index[sizeof(g_survivor_model)];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if( GetEngineVersion() != Engine_Left4Dead2 ) // only support left4dead2
		return APLRes_SilentFailure;

	RegPluginLibrary("miuwiki_serverapi");
	/**
	 * These for methodmap server
	 */
	CreateNative("Server.Human.get", Native_Miuwiki_HumanCount);
	CreateNative("Server.Bot.get", Native_Miuwiki_BotCount);
	CreateNative("Server.All.get", Native_Miuwiki_AllCount);
	CreateNative("Server.RoundCount.get", Native_Miuwiki_RoundCount);
	CreateNative("Server.Difficulty.get", Native_Miuwiki_DifficultyGet);
	CreateNative("Server.Difficulty.set", Native_Miuwiki_DifficultySet);
	CreateNative("Server.IsRoundStart.get", Native_Miuwiki_IsRoundStart);
	
	/**
	 * These for native
	 */
	CreateNative("M_IsSurvivorBotused",Native_Miuwiki_IsSurvivorBotused);
	CreateNative("M_IsSurvivorBeHold",Native_Miuwiki_IsSurvivorBeHold);
	CreateNative("M_IsSurvivorGetup",Native_Miuwiki_IsSurvivorGetup);
	
	CreateNative("M_TakeOverBot",Native_Miuwiki_TakeOverBot);
	CreateNative("M_RespawnSurvivor",Native_Miuwiki_RespawnSurvivor);

	CreateNative("M_GivePlayerWeapon",Native_Miuwiki_GivePlayerWeapon);
	CreateNative("M_GetPlayerMeleeName",Native_Miuwiki_GetPlayerMeleeName);

	CreateNative("M_CreateRagdoll",Native_Miuwiki_CreateRagdoll);
	CreateNative("M_CreateSurvivorBot",Native_Miuwiki_CreateSurvivorBot);
	CreateNative("M_CreateInfectedBot",Native_Miuwiki_CreateInfectedBot);
	return APLRes_Success;
}
public void OnPluginStart()
{
	LoadGameData();
	HookEvent("round_start",Event_RoundStartInfo);
	HookEvent("round_end",Evnet_RoundEndInfo);
	HookEvent("player_bot_replace",Event_PlayerBotReplaceInfo);
	HookEvent("bot_player_replace",Event_BotPlayerReplaceInfo);
	HookEvent("player_spawn",Event_PlayerSpawnInfo);
	g_melee_script_name = new ArrayList(ByteCountToCells(64));
	g_hGF_GoAwayFromKeyBroad = new GlobalForward("M_OnClientAFK",ET_Event,Param_Cell);
	g_hGF_PlayerFirstSpawn = new GlobalForward("M_OnPlayerFirstSpawn",ET_Ignore);
	g_hGF_ClientChangeTeam = new GlobalForward("M_OnClientChangeTeam",ET_Single,Param_Cell,Param_Cell);

	cvar_difficult = FindConVar("z_difficulty");
}
public void OnConfigsExecuted()
{

}
void Event_RoundStartInfo(Event event, const char[] name, bool dontBroadcast)
{
	g_round_start = true;
}
void Evnet_RoundEndInfo(Event event, const char[] name, bool dontBroadcast)
{
	g_round_count += 1;
	g_round_start = false;
}
public void OnMapEnd()
{
	g_round_count = 1;
	g_round_start = false;
}
/** 
 * methodmap native start 
 */
any Native_Miuwiki_IsRoundStart(Handle plugin, int arg_num)
{
	return g_round_start;
}
any Native_Miuwiki_DifficultySet(Handle plugin, int arg_num)
{
	int temp = GetNativeCell(2);
	switch(temp)
	{
		case Z_EASY:
			cvar_difficult.SetString("Easy");
		case Z_NORMAL:
			cvar_difficult.SetString("Normal");
		case Z_HARD:
			cvar_difficult.SetString("Hard");
		case Z_IMPOSSIBLE:
			cvar_difficult.SetString("Impossible");
	}
	return 0;
}
any Native_Miuwiki_DifficultyGet(Handle plugin, int arg_num)
{
	char temp[1];
	cvar_difficult.GetString(temp,sizeof(temp));
	if( strcmp(temp,"E") )
		return Z_EASY;
	else if( strcmp(temp,"N") )
		return Z_NORMAL;
	else if( strcmp(temp,"H") )
		return Z_HARD;
	else
		return Z_IMPOSSIBLE;
}
any Native_Miuwiki_RoundCount(Handle plugin, int arg_num)
{
	return g_round_count;
}
any Native_Miuwiki_AllCount(Handle plugin, int arg_num)
{
	int total;
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR )
			total++;
	}

	return total;
}
any Native_Miuwiki_BotCount(Handle plugin, int arg_num)
{
	int total;
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR )
			total++;
	}

	return total;
}
any Native_Miuwiki_HumanCount(Handle plugin, int arg_num)
{
	int total;
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR )
			total++;
	}

	return total;
}

/** 
 * other native start 
 */
any Native_Miuwiki_GetPlayerMeleeName(Handle plugin, int arg_num)
{
	int client = GetNativeCell(1);
	// 2 is the char.
	int size = GetNativeCell(3);

	if( client < 1 || client > MaxClients || !IsClientInGame(client) )
		return 0;
	
	int weapon = GetPlayerWeaponSlot(client,1);
	if( weapon == -1 )
		return 0;
	
	if( !HasEntProp(weapon, Prop_Send, "m_iWorldModelIndex") )
		return 0;
	
	int worldmodel_index = GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex");
	for(int i = 0; i < sizeof(g_slot1_wmodel_index); i++)
	{
		if( g_slot1_wmodel_index[i] == worldmodel_index )
		{
			SetNativeString(2,g_slot1_name[i],size);
			return 1;
		}
	}
	return -1;
}
any Native_Miuwiki_CreateInfectedBot(Handle plugin, int arg_num)
{
	int class = GetNativeCell(1);
	int index;
	float pos[3];
	if( L4D_GetRandomPZSpawnPosition(0,class,5,pos) )
	{
		switch(class)
		{
			case CLASS_CHARGER:
				index = SDKCall(g_hSDK_NextBotCreatePlayerBot_Charger,"Charger");
			case CLASS_HUNTER:
				index = SDKCall(g_hSDK_NextBotCreatePlayerBot_Hunter,"Hunter");
			case CLASS_JOCKEY:
				index = SDKCall(g_hSDK_NextBotCreatePlayerBot_Jockey,"Jockey");
			case CLASS_SMOKER:
				index = SDKCall(g_hSDK_NextBotCreatePlayerBot_Smoker,"Smoker");
			case CLASS_BOOMER:
				index = SDKCall(g_hSDK_NextBotCreatePlayerBot_Boomer,"Boomer");
			case CLASS_SPITTER:
				index = SDKCall(g_hSDK_NextBotCreatePlayerBot_Spitter,"Spitter");
			case CLASS_TANK:
				index = SDKCall(g_hSDK_NextBotCreatePlayerBot_Tank,"Tank");		
		}
		if( index != -1 )
		{
			ChangeClientTeam(index, 3);
			SetEntProp(index, Prop_Send, "m_usSolidFlags", 16);
			SetEntProp(index, Prop_Send, "movetype", 2);
			SetEntProp(index, Prop_Send, "deadflag", 0);
			SetEntProp(index, Prop_Send, "m_lifeState", 0);
			SetEntProp(index, Prop_Send, "m_iObserverMode", 0);
			SetEntProp(index, Prop_Send, "m_iPlayerState", 0);
			SetEntProp(index, Prop_Send, "m_zombieState", 0);
			DispatchSpawn(index);
			TeleportEntity(index,pos,NULL_VECTOR,NULL_VECTOR);
			return index;
		}
	}

	return -1;
}
any Native_Miuwiki_GivePlayerWeapon(Handle plugin, int arg_num)
{
	int client = GetNativeCell(1);
	int slot = GetNativeCell(2);
	int index = GetNativeCell(3);
	int ent = -1;
		
	switch(slot)
	{
		case 0:
		{
			if( index == -1 )
				ent = GivePlayerItem(client,g_slot0_name[GetRandomInt(0, sizeof(g_slot0_name) - 1)]) ;
			else
				ent = GivePlayerItem(client,g_slot0_name[index]);
		}
		case 1:
		{
			char temp[64];
			if( index == -1 )
			{
				int chance = GetRandomInt(0,sizeof(g_slot1_name) - 1);
				FormatEx(temp,sizeof(temp),"%s",g_slot1_name[chance]);
			}
			else if( 0 <= index <= 1 )
			{
				FormatEx(temp,sizeof(temp),"%s",g_slot1_name[index]);
			}	
			else
			{
				FormatEx(temp,sizeof(temp),"%s",g_slot1_name[index]);

				int arr_index = g_melee_script_name.FindString(temp);
				if( arr_index == -1 )
				{
					g_melee_script_name.GetString( GetRandomInt(0, g_melee_script_name.Length - 1), temp, sizeof(temp));
					PrintToServer("[miuwiki_serverapi]: The meleeweapons stringtable in this map doesn't have this weapon %s, change to random melee",g_slot1_name[index]);
				}
				else
					g_melee_script_name.GetString(arr_index, temp, sizeof(temp));
			}
			ent = GivePlayerItem(client,temp);
		}
		case 2:
		{
			if( index == -1 )
				ent = GivePlayerItem(client,g_slot2_name[GetRandomInt(0, sizeof(g_slot2_name) - 1)]) ;
			else
				ent = GivePlayerItem(client,g_slot2_name[index]);
		}
		case 3:
		{
			if( index == -1 )
				ent = GivePlayerItem(client,g_slot3_name[GetRandomInt(0, sizeof(g_slot3_name) - 1)]) ;
			else
				ent = GivePlayerItem(client,g_slot3_name[index]);
		}
		case 4:
		{
			if( index == -1 )
				ent = GivePlayerItem(client,g_slot4_name[GetRandomInt(0, sizeof(g_slot4_name) - 1)]) ;
			else
				ent = GivePlayerItem(client,g_slot4_name[index]);
		}
	}
	return ent;
}
any Native_Miuwiki_IsSurvivorBeHold(Handle plugin, int arg_num)
{
	int client = GetNativeCell(1);
	if( GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 )
		return true;
	if( GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 )
		return true;
	if( GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 )
		return true;
	if( GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 )
		return true;
	if( GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 )
		return true;
	return false;
}
any Native_Miuwiki_IsSurvivorGetup(Handle plugin, int arg_num)
{
	int client = GetNativeCell(1);
	static char sModel[31];
	GetClientModel(client, sModel, sizeof sModel);
	switch (sModel[29]) {
		case 'b': {	//nick
			switch (GetEntProp(client, Prop_Send, "m_nSequence")) {
				case 680, 667, 671, 672, 630, 620, 627:
					return true;
			}
		}

		case 'd': {	//rochelle
			switch (GetEntProp(client, Prop_Send, "m_nSequence")) {
				case 687, 679, 678, 674, 638, 635, 629:
					return true;
			}
		}

		case 'c': {	//coach
			switch (GetEntProp(client, Prop_Send, "m_nSequence")) {
				case 669, 661, 660, 656, 630, 627, 621:
					return true;
			}
		}

		case 'h': {	//ellis
			switch (GetEntProp(client, Prop_Send, "m_nSequence")) {
				case 684, 676, 675, 671, 625, 635, 632:
					return true;
			}
		}

		case 'v': {	//bill
			switch (GetEntProp(client, Prop_Send, "m_nSequence")) {
				case 772, 764, 763, 759, 538, 535, 528:
					return true;
			}
		}

		case 'n': {	//zoey
			switch (GetEntProp(client, Prop_Send, "m_nSequence")) {
				case 824, 823, 819, 809, 547, 544, 537:
					return true;
			}
		}

		case 'e': {	//francis
			switch (GetEntProp(client, Prop_Send, "m_nSequence")) {
				case 775, 767, 766, 762, 541, 539, 531:
					return true;
			}
		}

		case 'a': {	//louis
			switch (GetEntProp(client, Prop_Send, "m_nSequence")) {
				case 772, 764, 763, 759, 538, 535, 528:
					return true;
			}
		}

		case 'w': {	//adawong
			switch (GetEntProp(client, Prop_Send, "m_nSequence")) {
				case 687, 679, 678, 674, 638, 635, 629:
					return true;
			}
		}
	}

	return false;
}
any Native_Miuwiki_RespawnSurvivor(Handle plugin, int arg_num)
{
	int survivor = GetNativeCell(1);

	PatchAddress(true);
	SDKCall(g_hSDK_Call_RoundRespawn, survivor);
	PatchAddress(false);
	return 1;
}
any Native_Miuwiki_CreateSurvivorBot(Handle plugin, int arg_num)
{
	int bot = SDKCall(g_hSDK_NextBotCreatePlayerBot_SurvivorBot, NULL_STRING);
	if(bot != -1)
		ChangeClientTeam(bot, TEAM_SURVIVOR);

	return bot;
}
any Native_Miuwiki_IsSurvivorBotused(Handle plugin, int arg_num)
{
	int bot = GetNativeCell(1);
	return ( HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID") && GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID")) );
}
any Native_Miuwiki_TakeOverBot(Handle plugin, int arg_num)
{
	int client = GetNativeCell(1);
	int bot = GetNativeCell(2);

	SDKCall(g_hSDK_SurvivorBot_SetHumanSpectator, bot, client);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
	SDKCall(g_hSDK_CTerrorPlayer_TakeOverBot, client, true);
	return 1;
}
any Native_Miuwiki_CreateRagdoll(Handle plugin, int arg_num)
{
	int client = GetNativeCell(1);
	memory = new MemoryBlock(0x4C);
	return SDKCall(g_hSDK_CreateRagdoll,client,GetEntProp(client, Prop_Send, "m_nForceBone"),memory.Address,3,true);
}

public void OnMapStart()
{

	g_first_player_spawn = true;

	char temp[64];
	for( int i = 2; i < sizeof(g_slot1_name); i++)
	{
		FormatEx(temp, sizeof(temp), "scripts/melee/%s.txt", g_slot1_name[i]);
		if( !IsModelPrecached(temp) )
			PrecacheModel(temp, true);
	}

	g_melee_script_name.Clear();
	int table = FindStringTable("meleeweapons");
	if( table != INVALID_STRING_TABLE )
	{
		int num = GetStringTableNumStrings(table);
		
		for(int i = 0; i < num; i++) 
		{
			ReadStringTable(table, i, temp, sizeof(temp));
			g_melee_script_name.PushString(temp);
		}
	}
	
	for(int i = 0; i < sizeof(g_survivor_model_index); i++)
	{
		g_survivor_model_index[i] = PrecacheModel(g_survivor_model[i]);
	}
	for(int i = 0; i < sizeof(g_slot0_wmodel_index); i++)
	{
		g_slot0_wmodel_index[i] = PrecacheModel(g_slot0_model[i]);
	}
	for(int i = 0; i < sizeof(g_slot1_wmodel_index); i++)
	{
		g_slot1_wmodel_index[i] = PrecacheModel(g_slot1_model[i]);
	}
	for(int i = 0; i < sizeof(g_slot1_vmodel_index); i++)
	{
		g_slot1_vmodel_index[i] = PrecacheModel(g_slot1_vmodel[i]);
	}
	for(int i = 0; i < sizeof(g_slot2_wmodel_index); i++)
	{
		g_slot2_wmodel_index[i] = PrecacheModel(g_slot2_model[i]);
	}
	for(int i = 0; i < sizeof(g_slot3_wmodel_index); i++)
	{
		g_slot3_wmodel_index[i] = PrecacheModel(g_slot3_model[i]);
	}
	for(int i = 0; i < sizeof(g_slot4_wmodel_index); i++)
	{
		g_slot4_wmodel_index[i] = PrecacheModel(g_slot4_model[i]);
	}
	
}
/**
 * First player spawn 
 */
void Event_PlayerSpawnInfo(Event event, char[] name, bool dontBroadcast)
{
	if( g_first_player_spawn )
	{
		Call_StartForward(g_hGF_PlayerFirstSpawn);
		/* Finish the call */
		Call_Finish();
		g_first_player_spawn = false;
	}
}
/**
 * Fix player model change when someone disconnect or afk.
 */
void Event_PlayerBotReplaceInfo(Event event, char[] name, bool dontBroadcast) {
	int playerId = event.GetInt("player");
	int player = GetClientOfUserId(playerId);
	if (!player || !IsClientInGame(player) || IsFakeClient(player) || GetClientTeam(player) != TEAM_SURVIVOR)
		return;

	int botId = event.GetInt("bot");
	int bot = GetClientOfUserId(botId);

	if( !g_player_model[player][0] )
		return;

	SetEntProp(bot, Prop_Send, "m_survivorCharacter", GetEntProp(player, Prop_Send, "m_survivorCharacter"));
	SetEntityModel(bot, g_player_model[player]);
}

void Event_BotPlayerReplaceInfo(Event event, const char[] name, bool dontBroadcast) {
	int player = GetClientOfUserId(event.GetInt("player"));
	if (!player || !IsClientInGame(player) || IsFakeClient(player) || GetClientTeam(player) != TEAM_SURVIVOR)
		return;

	int bot = GetClientOfUserId(event.GetInt("bot"));
	SetEntProp(player, Prop_Send, "m_survivorCharacter", GetEntProp(bot, Prop_Send, "m_survivorCharacter"));

	char sModel[PLATFORM_MAX_PATH];
	GetClientModel(bot, sModel, sizeof sModel);
	SetEntityModel(player, sModel);
}

/**
 * AFK Control.
 */
public MRESReturn OnClientAfkPre(int pThis)
{
	int client = pThis;
	Action result = Plugin_Continue;
	/* Start function call */
	Call_StartForward(g_hGF_GoAwayFromKeyBroad);
	Call_PushCell(client);
	/* Finish the call */
	Call_Finish(result);

	if( result == Plugin_Handled )
	{
		return MRES_Supercede;
	}
	return MRES_Ignored;
}
public MRESReturn OnClientChangeTeam(int pThis, DHookParam hParams)
{
	// ptr = client, int bot.
	int client = pThis;
	int new_team = hParams.Get(1);

	int result;
	/* Start function call */
	Call_StartForward(g_hGF_ClientChangeTeam);
	Call_PushCell(client);
	Call_PushCell(new_team);
	/* Finish the call */
	Call_Finish(result);

	if( result <= 0 || result >= 4)
		return MRES_Ignored;
	
	else
	{
		hParams.Set(1,result);
		return MRES_ChangedOverride;
	}
	
}

/**
 * GaemData init.
 */
void LoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAME_DATA);
	if(FileExists(sPath) == false) 
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAME_DATA);
	if(hGameData == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAME_DATA);
	/**
	 * AFK hook
	 */
	Handle hDetour;
	hDetour = DHookCreateFromConf(hGameData, "CTerrorPlayer::GoAwayFromKeyboard");
	if(!hDetour)
		SetFailState("Failed to find 'CTerrorPlayer::GoAwayFromKeyboard' signature");
	
	if(!DHookEnableDetour(hDetour, false, OnClientAfkPre))
		SetFailState("Failed to detour 'CTerrorPlayer::GoAwayFromKeyboard'");

	/**
	 * change team hook
	 */
	Handle hDetour_ChangeTeam;
	hDetour_ChangeTeam = DHookCreateFromConf(hGameData, "CCSPlayer::ChangeTeam");
	if(!hDetour_ChangeTeam)
		SetFailState("Failed to find 'CCSPlayer::ChangeTeam' signature");
	
	if(!DHookEnableDetour(hDetour_ChangeTeam, false, OnClientChangeTeam))
		SetFailState("Failed to detour 'CCSPlayer::ChangeTeam'");

	/**
	 * Respawn SDK call.
	 */
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "RoundRespawn"))
		SetFailState("Failed to find signature: RoundRespawn");
	if(!(g_hSDK_Call_RoundRespawn = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: RoundRespawn");
	RoundRespawnPatch(hGameData);
	/**
	 * Survivor bot create SDK call.
	 */
	StartPrepSDKCall(SDKCall_Static); 
	Address addr = hGameData.GetMemSig("NextBotCreatePlayerBot<SurvivorBot>");
	if(!addr)
		SetFailState("Failed to find address: \"NextBotCreatePlayerBot<SurvivorBot>\" in \"CDirector::AddSurvivorBot\" (%s)", PLUGIN_VERSION);
	if(!hGameData.GetOffset("OS"))
    {
		Address offset = view_as<Address>(LoadFromAddress(addr + view_as<Address>(1), NumberType_Int32));	// (addr+5) + *(addr+1) = call function addr
		if(!offset)
			SetFailState("Failed to find address: \"NextBotCreatePlayerBot<SurvivorBot>\" (%s)", PLUGIN_VERSION);
		addr += offset + view_as<Address>(5); // sizeof(instruction)
	}
	if(!PrepSDKCall_SetAddress(addr))
		SetFailState("Failed to find address: \"NextBotCreatePlayerBot<SurvivorBot>\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	if(!(g_hSDK_NextBotCreatePlayerBot_SurvivorBot = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"NextBotCreatePlayerBot<SurvivorBot>\" (%s)", PLUGIN_VERSION);
	/**
	 * Spec a bot.
	 */
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::SetHumanSpectator"))
		SetFailState("Failed to find signature: \"SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	if(!(g_hSDK_SurvivorBot_SetHumanSpectator = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);
	/**
	 * Take over a bot.
	 */
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TakeOverBot"))
		SetFailState("Failed to find signature: \"CTerrorPlayer::TakeOverBot\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	if(!(g_hSDK_CTerrorPlayer_TakeOverBot = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CTerrorPlayer::TakeOverBot\" (%s)", PLUGIN_VERSION);
	
	
	/**
	 * Create ragdoll.
	 */
	StartPrepSDKCall(SDKCall_Static);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CreateServerRagdoll"))
		SetFailState("Failed to find signature: \"CreateServerRagdoll\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	if(!(g_hSDK_CreateRagdoll = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CreateServerRagdoll\" (%s)", PLUGIN_VERSION);


	SetupDetours(hGameData);
	SetUpLinuxCreateBotCalls(hGameData);
	delete hGameData;
}
/**
 * rygive patch.
 */
void PatchAddress(bool bPatch)
{
	static bool bPatched;
	if(!bPatched && bPatch)
	{
		bPatched = true;
		StoreToAddress(g_pResetStatCondition, 0x79, NumberType_Int8); // if (!bool) - 0x75 JNZ => 0x78 JNS (jump short if not sign) - always not jump
	}
	else if(bPatched && !bPatch)
	{
		bPatched = false;
		StoreToAddress(g_pResetStatCondition, 0x75, NumberType_Int8);
	}
}
void RoundRespawnPatch(GameData hGameData = null)
{
	int iOffset = hGameData.GetOffset("RoundRespawn_Offset");
	if(iOffset == -1)
		SetFailState("Failed to find offset: RoundRespawn_Offset");

	int iByteMatch = hGameData.GetOffset("RoundRespawn_Byte");
	if(iByteMatch == -1)
		SetFailState("Failed to find byte: RoundRespawn_Byte");

	g_pRespawn = hGameData.GetAddress("RoundRespawn");
	if(!g_pRespawn)
		SetFailState("Failed to find address: RoundRespawn");
	
	g_pResetStatCondition = g_pRespawn + view_as<Address>(iOffset);
	
	int iByteOrigin = LoadFromAddress(g_pResetStatCondition, NumberType_Int8);
	if(iByteOrigin != iByteMatch)
		SetFailState("Failed to load, byte mis-match @ %d (0x%02X != 0x%02X)", iOffset, iByteOrigin, iByteMatch);
}

/**
 * create infected bot.
 */
void SetUpLinuxCreateBotCalls(GameData hGameData = null) {
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateSmoker))
		SetFailState("Failed to find signature: %s", NAME_CreateSmoker);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Smoker = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Smoker)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateSmoker);
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateBoomer))
		SetFailState("Failed to find signature: %s", NAME_CreateBoomer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Boomer = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Boomer)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateBoomer);
		
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateHunter))
		SetFailState("Failed to find signature: %s", NAME_CreateHunter);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Hunter = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Hunter)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateHunter);
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateSpitter))
		SetFailState("Failed to find signature: %s", NAME_CreateSpitter);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Spitter = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Spitter)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateSpitter);
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateJockey))
		SetFailState("Failed to find signature: %s", NAME_CreateJockey);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Jockey = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Jockey)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateJockey);
		
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateCharger))
		SetFailState("Failed to find signature: %s", NAME_CreateCharger);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Charger = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Charger)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateCharger);
		
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateTank))
		SetFailState("Failed to find signature: %s", NAME_CreateTank);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Tank = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Tank)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateTank);
}

/**
 * survivor identity fix.
 */
void SetupDetours(GameData hGameData = null)
{
	g_Dtour_SetModel = DynamicDetour.FromConf(hGameData, "DD::CBasePlayer::SetModel");
	if (!g_Dtour_SetModel)
		SetFailState("Failed to create DynamicDetour: \"DD::CBasePlayer::SetModel\" (%s)", PLUGIN_VERSION);
		
	if (!g_Dtour_SetModel.Enable(Hook_Post, DD_CBasePlayer_SetModel_Post))
		SetFailState("Failed to detour post: \"DD::CBasePlayer::SetModel\" (%s)", PLUGIN_VERSION);
}
MRESReturn DD_CBasePlayer_SetModel_Post(int pThis, DHookParam hParams)
{
	if (pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis) || IsFakeClient(pThis))
		return MRES_Ignored;

	if (GetClientTeam(pThis) != TEAM_SURVIVOR)
	{
		g_player_model[pThis][0] = '\0';
		return MRES_Ignored;
	}
	
	char temp[PLATFORM_MAX_PATH];
	hParams.GetString(1, temp, sizeof temp);
	if( StrContains(temp, "models/survivors/survivor_", false) == 0 )
		strcopy(g_player_model[pThis], sizeof(g_player_model[]), temp);

	return MRES_Ignored;
}
