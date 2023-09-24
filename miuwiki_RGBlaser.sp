#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"

ConVar
    cvar_default_color;

int
    g_default_color;

public Plugin myinfo =
{
	name = "[L4D2] RGB Laser",
	author = "Miuwiki",
	description = "RGB weapon laser",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

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
int g_slot0_wmodel_index[sizeof(g_slot0_model)];

enum struct player_laser
{
    int light_entity;
    int light_reference;
    int width;
    int length;
    int color;
    int transparency;

    float HDR;
    bool show;
}
player_laser g_player[MAXPLAYERS + 1];


public void OnPluginStart()
{
    RegConsoleCmd("sm_togglelight", Cmd_ToggleLight);
}

Action Cmd_ToggleLight(int client, int args)
{
    if( client < 1 || client > MaxClients || !IsClientInGame(i) )
        return Plugin_Handled;
    
    if( args > 1 )
    {
        ReplyToCommand(client, "sm_togglelight 不能添加参数!");
        return Plugin_Handled;
    }

    if( g_player[client].show )
        AcceptEntityInput()


    g_player[client].show = !g_player[client].show
}

public void OnMapStart()
{
    for(int i = 0; i < sizeof(g_slot0_model); i++)
    {
       g_slot0_wmodel_index[i] = PrecacheModel(g_slot0_model[i]);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponSwitchPost, SDKCallback_WSP);
}

void SDKCallback_WSP(int client, int weapon)
{
    if( !IsClientInGame(client) && GetClientTeam(client) != 2 )
        return;
    
    int current = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if( weapon == current ) // when player switch a weapon it fire twice.
        return;
    
    if( g_player[client].light_entity == -1 )
    {
        int light = CreateBeam(client);
        if( light == -1 )
            return;
        
        g_player[client].light_entity = light;
        g_player[client].light_reference = EntIndexToEntRef(light);
    }

    if( )
    char classname[128];
    GetEntityClassname(weapon, classname, sizeof(classname));
    PrintToChat(client, "你换上了 %s", classname);
}
int CreateBeam(int target)
{
    // char rendercolor[12];
    // FormatEx(rendercolor, sizeof(rendercolor), "%i %i %i", config[CONFIG_R], config[CONFIG_G], config[CONFIG_B]);

    // float vPos[3];
    // GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPos);
    // vPos[2] += g_fExtraPosZ;

    // int entity = CreateEntityByName("beam_spotlight");
    // DispatchKeyValue(entity, "targetname", "l4d_random_beam_item");
    // DispatchKeyValue(entity, "spawnflags", "3");
    // DispatchKeyValue(entity, "rendercolor", rendercolor);
    // DispatchKeyValueFloat(entity, "SpotlightLength", float(config[CONFIG_LENGTH]));
    // DispatchKeyValueFloat(entity, "SpotlightWidth", float(config[CONFIG_WIDTH]));
    // DispatchKeyValueFloat(entity, "HDRColorScale", config[CONFIG_HDR]/10.0);
    // DispatchKeyValueVector(entity, "origin", vPos);
    // DispatchKeyValueVector(entity, "angles", g_vAngles);
    // DispatchSpawn(entity);

    // g_alPluginEntities.Push(EntIndexToEntRef(entity));

    // SetEntProp(entity, Prop_Send, "m_nHaloIndex", config[CONFIG_HALO] == 1 ? g_iHalo : -1); // After dispatch spawn otherwise won't work

    // ge_bTurnOn[entity] = true;
    // ge_iParentEntRef[entity] = EntIndexToEntRef(target);
    // ge_iChildEntRef[target] = EntIndexToEntRef(entity);

    // if (!ge_bVPhysicsUpdatePostHooked[target])
    // {
    //     ge_bVPhysicsUpdatePostHooked[target] = true;
    //     SDKHook(target, SDKHook_VPhysicsUpdatePost, OnVPhysicsUpdatePost);
    // }
}

