#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"

static const char g_survivor_model[][] =
{
	// "models/survivors/survivor_teenangst.mdl",
	// "models/survivors/survivor_biker.mdl",
	// "models/survivors/survivor_manager.mdl",
	// "models/survivors/survivor_namvet.mdl",
	"models/survivors/survivor_gambler.mdl",
	// "models/survivors/survivor_coach.mdl",
	// "models/survivors/survivor_mechanic.mdl",
	// "models/survivors/survivor_producer.mdl",
};

public Plugin myinfo =
{
	name = "[L4D2] Random Survivor Special Infected",
	author = "Miuwiki",
	description = "Set a special infected a random survivor model",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnPluginStart()
{

}

public void OnEntityCreated(int entity, const char []classname)
{
    if( 1 <= entity <= 32 )
    {
        SDKHook(entity,SDKHook_SpawnPost,SDKCallback_SP);
    }
}

void SDKCallback_SP(int entity)
{
    if( !IsValidEntity(entity) )
        return;
    
    if( GetClientTeam(entity) == 3 )
        RequestFrame(ChangeModel, EntIndexToEntRef(entity));
}

void ChangeModel(int ref)
{
    int client = EntRefToEntIndex(ref);
    if( client < 1 || client > MaxClients || !IsClientInGame(client) )
        return;
    
    int ornament = CreateEntityByName("prop_dynamic_ornament");
    if( ornament == -1 )
    {
        PrintToServer("为 %N 修改外观失败!", client);
        return;
    }

    // char 
    int chance = GetRandomInt(0, sizeof(g_survivor_model) - 1);
    DispatchKeyValue(ornament,"model",g_survivor_model[chance]);
    DispatchSpawn(ornament);
    ActivateEntity(ornament);
    SetVariantString("!activator");
    AcceptEntityInput(ornament, "SetParent", client);
    SetVariantString("!activator");
    AcceptEntityInput(ornament, "SetAttached", client);
    SetEntityRenderMode(client, RENDER_NONE);
    // SetEntityRenderColor(client, 0,0,0,0);
    // AcceptEntityInput(ornament, "TurnOff"); 
}
