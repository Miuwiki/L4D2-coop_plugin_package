#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <sourcescramble>

#define GAME_DATA "miuwiki_serverapi"
#define PLUGIN_VERSION "1.0.0"
#define TEAM_NONE 0
#define TEAM_SPEACTOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

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

bool g_chapter_work;
char g_player_model[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
enum
{
    BOT_CMD_ATTACK = 0,
    BOT_CMD_MOVE = 1,
    BOT_CMD_RETREAT = 2,
    BOT_CMD_RESET = 3
}

public Plugin myinfo =
{
	name = "Server Info Native API",
	author = "Miuwiki",
	description = "Useful native for server info.",
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
	if( GetEngineVersion() != Engine_Left4Dead2 ) // only support left4dead2, sorry for l4d1 player.
		return APLRes_SilentFailure;

	RegPluginLibrary("miuwiki_serverapi");
	/**
	 * These for methodmap server
	 */
	CreateNative("M_IsChapterStart",Native_Miuwiki_GetChapterStart);
	CreateNative("M_CreateSurvivorBot",Native_Miuwiki_CreateSurvivorBot);
	CreateNative("M_IsSurvivorBotused",Native_Miuwiki_IsSurvivorBotused);
	CreateNative("M_TakeOverBot",Native_Miuwiki_TakeOverBot);
	CreateNative("M_RespawnSurvivor",Native_Miuwiki_RespawnSurvivor);
	CreateNative("M_CreateRagdoll",Native_Miuwiki_CreateRagdoll);
	CreateNative("M_CommandBot",Native_Miuwiki_CommandBot);
	CreateNative("M_SurvivorCount",Native_Miuwiki_SurvivorCount);
	CreateNative("M_IsSurvivorBeHold",Native_Miuwiki_IsSurvivorBeHold);
	CreateNative("M_IsSurvivorGetup",Native_Miuwiki_IsSurvivorGetup);
	CreateNative("M_GivePlayerWeapon",Native_Miuwiki_GivePlayerWeapon);
	return APLRes_Success;
}
public void OnPluginStart()
{
	LoadGameData();
	HookEvent("round_end",Evnet_RoundEndInfo);
	HookEvent("player_bot_replace",Evnet_PlayerBotReplaceInfo);
	HookEvent("bot_player_replace",Evnet_BotPlayerReplaceInfo);
	g_melee_script_name = new ArrayList(ByteCountToCells(64));
}
public void OnConfigsExecuted()
{
    g_chapter_work = true;
}

void Evnet_RoundEndInfo(Event event, const char[] name, bool dontBroadcast)
{
	g_chapter_work = false;
}
public void OnMapEnd()
{
	g_chapter_work = false;
}
/** 
 * native start 
 */
any Native_Miuwiki_GivePlayerWeapon(Handle plugin, int arg_num)
{
	int client = GetNativeCell(1);
	int slot = GetNativeCell(2);
	int index = GetNativeCell(3);
	int ent = -1;
		
	switch(slot)
	{
		case 4:
		{
			if( index == -1 )
				ent = GivePlayerItem(client,g_slot4_name[GetRandomInt(0, sizeof(g_slot4_name) - 1)]) ;
			else
				ent = GivePlayerItem(client,g_slot4_name[index]);
		}
		case 3:
		{
			if( index == -1 )
				ent = GivePlayerItem(client,g_slot3_name[GetRandomInt(0, sizeof(g_slot3_name) - 1)]) ;
			else
				ent = GivePlayerItem(client,g_slot3_name[index]);
		}
		case 2:
		{
			if( index == -1 )
				ent = GivePlayerItem(client,g_slot2_name[GetRandomInt(0, sizeof(g_slot2_name) - 1)]) ;
			else
				ent = GivePlayerItem(client,g_slot2_name[index]);
		}
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
			if( 0 <= index <= 1 )
				FormatEx(temp,sizeof(temp),"%s",g_slot1_name[index]);
			else
				g_melee_script_name.GetString( GetRandomInt(0, g_melee_script_name.Length - 1), temp, sizeof(temp));

			ent = GivePlayerItem(client,temp);
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
any Native_Miuwiki_SurvivorCount(Handle plugin, int arg_num)
{
    int type = GetNativeCell(1);
    int total;
    switch(type)
    {
        case 0 :
        {
            for(int i = 1; i <= MaxClients; i++)
            {
                if( !IsClientInGame(i) || GetClientTeam(i) != 2 )
                    continue;

                if( !IsFakeClient(i) )
                    total++;
            }
        }
        case 1 :
        {
            for(int i = 1; i <= MaxClients; i++)
            {
                if( !IsClientInGame(i) || GetClientTeam(i) != 2 )
                    continue;
                if( IsFakeClient(i) )
                    total++;
            }
        }
        case 2 :
        {
            for(int i = 1; i <= MaxClients; i++)
            {
                if( !IsClientInGame(i) || GetClientTeam(i) != 2 )
                    continue;
					
                total++;
            }
        }
    }
    return total;
}
any Native_Miuwiki_CommandBot(Handle plugin, int arg_num)
{
    int bot = GetNativeCell(1);
    int cmd = GetNativeCell(2);
    int target = GetNativeCell(3);
    float pos[4];
    GetNativeArray(5,pos,sizeof(pos));
    static char scommand[128];
    switch( cmd )
    {
        case BOT_CMD_ATTACK:
        {
            FormatEx(scommand, sizeof(scommand), "CommandABot({cmd = 0, bot = GetPlayerFromUserID(%i), target = %d})",GetClientUserId(bot),target);
        }
        case BOT_CMD_MOVE:
        {
            FormatEx(scommand, sizeof(scommand), "CommandABot({cmd = 1, bot = GetPlayerFromUserID(%i), pos = Vector(%f,%f,%f)})",GetClientUserId(bot),pos[0],pos[1],pos[2]);
        }
        case BOT_CMD_RETREAT:
        {
            FormatEx(scommand, sizeof(scommand), "CommandABot({cmd = 2, bot = GetPlayerFromUserID(%i), target = %d})",GetClientUserId(bot),target);
        }
        case BOT_CMD_RESET:
        {
            FormatEx(scommand, sizeof(scommand), "CommandABot({cmd = 3, bot = GetPlayerFromUserID(%i)})",GetClientUserId(bot));
        }
    }
    SetVariantString(scommand);
    AcceptEntityInput(bot, "RunScriptCode");
    return 1;
}
any Native_Miuwiki_GetChapterStart(Handle plugin, int arg_num)
{
    return g_chapter_work;
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
// --------------------------------------
// Bot replaced by player
// --------------------------------------
void Evnet_PlayerBotReplaceInfo(Event event, char[] name, bool dontBroadcast) {
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

void Evnet_BotPlayerReplaceInfo(Event event, const char[] name, bool dontBroadcast) {
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
	//======================= from sorall bot.sp =======================//
	// 死亡复活
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "RoundRespawn"))
		SetFailState("Failed to find signature: RoundRespawn");
	if(!(g_hSDK_Call_RoundRespawn = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: RoundRespawn");
	RoundRespawnPatch(hGameData);
	// 多人加入bot管理 以及 闲置管理
	StartPrepSDKCall(SDKCall_Static); // 创建bot
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
	
	StartPrepSDKCall(SDKCall_Player); // 观察某个bot
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::SetHumanSpectator"))
		SetFailState("Failed to find signature: \"SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	if(!(g_hSDK_SurvivorBot_SetHumanSpectator = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);

	StartPrepSDKCall(SDKCall_Player);// 替换这个bot
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TakeOverBot"))
		SetFailState("Failed to find signature: \"CTerrorPlayer::TakeOverBot\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	if(!(g_hSDK_CTerrorPlayer_TakeOverBot = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CTerrorPlayer::TakeOverBot\" (%s)", PLUGIN_VERSION);
	
	// 服务器端 ragdoll 
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
	delete hGameData;
}
// ========= From rygive. https://forums.alliedmods.net/showthread.php?t=323220
void PatchAddress(bool bPatch) // Prevents respawn command from reset the player's statistics
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
void SetupDetours(GameData hGameData = null)
{
	DynamicDetour dDetour = DynamicDetour.FromConf(hGameData, "DD::CBasePlayer::SetModel");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::CBasePlayer::SetModel\" (%s)", PLUGIN_VERSION);
		
	if (!dDetour.Enable(Hook_Post, DD_CBasePlayer_SetModel_Post))
		SetFailState("Failed to detour post: \"DD::CBasePlayer::SetModel\" (%s)", PLUGIN_VERSION);
}
// [L4D(2)] Survivor Identity Fix for 5+ Survivors (https://forums.alliedmods.net/showpost.php?p=2718792&postcount=36)
MRESReturn DD_CBasePlayer_SetModel_Post(int pThis, DHookParam hParams) {
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
