#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <miuwiki_serverapi>
#define PLUGIN_VERSION "1.0.0"

#define PIPE_BOMB_VIEW_MODEL "models/v_models/v_pipebomb.mdl"

#define FLASH 0
#define HE    1

int 
    g_player_state[MAXPLAYERS + 1],
    g_precache_pipebomb_index;

enum struct Grenade
{
    float explsoinTime;

    bool  AlwaysKill;
    float DamageRange;
    float DamageSurvivor;
    float DamageSpecials;
    float DamageTank;
    float DamageWitch;
    
    float FlashRange;
    int   FlashTime;     // time that player maintain the max effect of white.
    int   FlashFadeTime; // time that player getting normal
}
Grenade bomb;

ConVar
    cvar_pipebomb_alwayskill,
    cvar_pipebomb_damagerange,
    cvar_pipebomb_damagesurvivor,
    cvar_pipebomb_damagespecial,
    cvar_pipebomb_damagetank,
    cvar_pipebomb_damagewitch,
    
    cvar_flashbomb_flashrange,
    cvar_flashbomb_flashtime,
    cvar_flashbomb_flashfadetime;

UserMsg 
    g_FadeUserMsgId;

public Plugin myinfo =
{
	name = "[L4D2] Pipe Bomb & Gascan Damage Setting",
	author = "Miuwiki",
	description = "Setting damage and ability to pipebomb & gascan.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}
public void OnPluginStart()
{
    g_FadeUserMsgId = GetUserMessageId("Fade");
    cvar_pipebomb_alwayskill = CreateConVar("miuwiki_pipebomb_alwayskill","0","HE pipe bomb always kill the specials but not include tank.",0,true,0.0,true,1.0);
    cvar_pipebomb_damagerange = CreateConVar("miuwiki_pipebomb_range","750","HE pipe bomb range, this will change the cvar [pipe_bomb_shake_radius]. ",0,true,100.0,true,2000.0);
    cvar_pipebomb_damagesurvivor = CreateConVar("miuwiki_pipebomb_damageTohuman","100","HE pipe bomb damage to human.",0,true,0.0);
    cvar_pipebomb_damagespecial = CreateConVar("miuwiki_pipebomb_damageTospecial","500","HE pipe bomb damage to specials.",0,true,0.0);
    cvar_pipebomb_damagetank = CreateConVar("miuwiki_pipebomb_damageTospecial","3000","HE pipe bomb damage to tank.",0,true,0.0);
    cvar_pipebomb_damagewitch = CreateConVar("miuwiki_pipebomb_damageTotank","2000","HE pipe bomb damage to witch.",0,true,0.0);

    cvar_flashbomb_flashrange = CreateConVar("miuwiki_flashbomb_maxrange","1600","Flash bomb max effect range.",0,true,0.0,true,5000.0);
    cvar_flashbomb_flashtime = CreateConVar("miuwiki_flashbomb_drutime","2000","Flash bomb hold the max effect time, millisecond unit.",0,true,1.0);
    cvar_flashbomb_flashfadetime = CreateConVar("miuwiki_flashbomb_time","1000","Flash bomb fade out time, millisecond unit.",0,true,1.0);
    
    cvar_pipebomb_alwayskill.AddChangeHook(CVAR_HookCallback);
    cvar_pipebomb_damagesurvivor.AddChangeHook(CVAR_HookCallback);
    cvar_pipebomb_damagespecial.AddChangeHook(CVAR_HookCallback);
    cvar_pipebomb_damagetank.AddChangeHook(CVAR_HookCallback);
    cvar_pipebomb_damagewitch.AddChangeHook(CVAR_HookCallback);

    cvar_flashbomb_flashrange.AddChangeHook(CVAR_HookCallback);
    cvar_flashbomb_flashtime.AddChangeHook(CVAR_HookCallback);
    cvar_flashbomb_flashfadetime.AddChangeHook(CVAR_HookCallback);

    HookEvent("player_death",Event_PlayerDeathInfo);
    // AutoExecConfig(true);
}
public void OnConfigsExecuted()
{
    GetCvar();
}
void CVAR_HookCallback(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvar();
}
void GetCvar()
{
    bomb.DamageRange = FindConVar("pipe_bomb_shake_radius").FloatValue = cvar_pipebomb_damagerange.FloatValue;
    bomb.AlwaysKill = cvar_pipebomb_alwayskill.BoolValue;
    bomb.DamageSurvivor = cvar_pipebomb_damagesurvivor.FloatValue;
    bomb.DamageSpecials = cvar_pipebomb_damagespecial.FloatValue;
    bomb.DamageTank = cvar_pipebomb_damagetank.FloatValue;
    bomb.DamageWitch = cvar_pipebomb_damagewitch.FloatValue;

    bomb.FlashRange = cvar_flashbomb_flashrange.FloatValue;
    bomb.FlashTime = cvar_flashbomb_flashtime.IntValue;
    bomb.FlashFadeTime = cvar_flashbomb_flashfadetime.IntValue;

    FindConVar("pipe_bomb_timer_duration").FloatValue = 2.0;
    FindConVar("pipe_bomb_initial_beep_interval").FloatValue = 10.0;
    FindConVar("pipe_bomb_beep_interval_delta").FloatValue = 0.0;
}

public void OnMapStart()
{
    g_precache_pipebomb_index = PrecacheModel(PIPE_BOMB_VIEW_MODEL);
}

public void OnClientConnected(int client)
{
    g_player_state[client] = 0;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client,SDKHook_OnTakeDamage,SDK_OTDcallback);
    SDKHook(client,SDKHook_WeaponSwitchPost,SDK_WSPcallback);
}

void Event_PlayerDeathInfo(Event event,const char[] name,bool dontbroadcast)
{
    int client = GetClientOfUserId( event.GetInt("userid") );
    if( client < 1 || client > MaxClients || !IsClientInGame(client) )
        return;

    if( GetClientTeam(client) == TEAM_INFECTED && GetEntProp(client,Prop_Send,"m_iGlowType") == 3 )
        SetEntProp(client, Prop_Send, "m_iGlowType", 0);
}
public Action OnPlayerRunCmd(int client,int &buttons,int &impulse, float vel[3], float angles[3],int &weapon)
{
    static float presstime[MAXPLAYERS + 1];
    
    if( buttons & IN_RELOAD )
    {
        if( !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TEAM_SURVIVOR )
            return Plugin_Continue;

        int active_weapon = GetEntPropEnt(client,Prop_Send,"m_hActiveWeapon");

        if( HasEntProp(active_weapon,Prop_Send,"m_iViewModelIndex") &&
            GetEntProp(active_weapon,Prop_Send,"m_iViewModelIndex") != g_precache_pipebomb_index )
            return Plugin_Continue;
        
        float time = GetEngineTime(); // prevent quickly switch mode.
        if( time - presstime[client] > 1.0 )
        {                                                                                                                           
            presstime[client] = time;
            switch(g_player_state[client])
            {
                case HE:
                {
                    g_player_state[client] = FLASH;
                    PrintToChat(client,"\x04[投掷物]\x05切换到 \x04闪光弹");
                }
                case FLASH:
                {
                    g_player_state[client] = HE;
                    PrintToChat(client,"\x04[投掷物]\x05切换到 \x04高爆弹");
                }
            }
        }
    }
    return Plugin_Continue;     
}
public void OnEntityCreated(int entity, const char[] classname )
{
    // only "pipe_bomb_projectile" start with "pipe_bomb";
    if( strncmp(classname,"pipe_bomb",9) == 0 )
    {
        SDKHook(entity, SDKHook_SpawnPost, SDK_SPcallback);
        // PrintToServer("[miuwiki_pipebomb]: hook pipe_bomb projectile success.");
    }
}
void SDK_SPcallback(int entity)
{
    if( !IsValidEntity(entity) )
        return;

    RequestFrame(NextFrame_PrintThrowInfo, EntIndexToEntRef(entity) );
}
void NextFrame_PrintThrowInfo(int ref)
{
    int entity = EntRefToEntIndex(ref);
    if( entity == -1 || !IsValidEntity(entity) )
        return;

    int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    if( owner < 1 || owner > MaxClients || !IsClientInGame(owner) || GetClientTeam(owner) != TEAM_SURVIVOR )
        return;

    static char state[16];
    switch(g_player_state[owner])
    {
        case HE:
        {
            FormatEx(state,sizeof(state),"HE_BOMB");
            DispatchKeyValue(entity,"targetname",state);
            PrintToChatAll("\x04[警告] \x01%N \x05投掷了高爆手雷!", owner);
        }
        case FLASH:
        {
            FormatEx(state,sizeof(state),"%s","FLASH_BOMB");
            DispatchKeyValue(entity,"targetname",state);
            PrintToChatAll("\x04[警告] \x01%N \x05投掷了闪光弹!", owner);
        }
    }
}
Action SDK_OTDcallback(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if( damagetype & DMG_BLAST_SURFACE )
    {
        char state[16];
        GetEntPropString(inflictor, Prop_Data, "m_iName", state, sizeof(state));

        if( strcmp(state, "FLASH_BOMB") == 0 )
        {
            damage = 0.0;
            return Plugin_Changed;
        }
            

        float distance,victim_pos[3];
        GetClientAbsOrigin(victim,victim_pos);
        distance = GetVectorDistance(damagePosition,victim_pos);

        switch( GetClientTeam(victim) )
        {
            case TEAM_SPEACTOR,TEAM_SURVIVOR: // human or survivor bot or spec human.
            {
                damage = bomb.DamageSurvivor * (1 - distance / bomb.DamageRange);
            }
            case TEAM_INFECTED:
            {
                int class = GetEntProp(victim,Prop_Send,"m_zombieClass" );
                if( class == CLASS_TANK ) // only left4dead2
                    damage = bomb.DamageTank;
                else
                    damage = bomb.AlwaysKill ? GetClientHealth(victim) + 0.0 : bomb.DamageSpecials;
            }
        }

        ScaleVector(damageForce,5.0); // look more terrible?
        return Plugin_Changed;
    }
    return Plugin_Continue;
}
void SDK_WSPcallback(int client,int weapon)
{
    if( client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR )
        return;

    char classname[32];
    GetEntityClassname(weapon,classname,sizeof(classname));

    if( strcmp(classname,"weapon_pipe_bomb") == 0)
    {
        if( g_player_state[client] == HE )
        {
            PrintToChat(client,"\x04[投掷物]\x05按 \x03[R]\x05 键切换模式. 目前是: \x04高爆弹");
        }
        else if(  g_player_state[client] == FLASH )
        {
            PrintToChat(client,"\x04[投掷物]\x05按 \x03[R]\x05 键切换模式. 目前是: \x04闪光弹");
        }
    }  
}
public void OnEntityDestroyed(int entity)
{
    if( entity <= 0 || !IsValidEntity(entity) )
        return;

    char classname[32],state[16];
    GetEntityClassname(entity,classname,sizeof(classname));
    if( strncmp(classname,"pipe_bomb",9) != 0 )
        return;

    GetEntPropString(entity, Prop_Data, "m_iName", state, sizeof(state));

    if( strcmp(state,"HE_BOMB") == 0 )
    {
        int particle = CreateEntityByName("info_particle_system");
        if( particle != -1 )
        {
            float pos[3];
            GetEntPropVector(entity,Prop_Send,"m_vecOrigin",pos);
            TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
            DispatchKeyValue(particle, "effect_name", "gas_explosion_pump");
            DispatchKeyValue(particle, "targetname", "particle");
            DispatchSpawn(particle);
            ActivateEntity(particle);
            AcceptEntityInput(particle, "start");

            SetVariantString("OnUser1 !self:Kill::3.0:-1"); // This is what we add in AddOutput.
            /**
             * Adds an entity I/O connection to this entity. 
             * Format: <output name> <targetname>:<inputname>:<parameter>:<delay>:<max times to fire (-1 == infinite)>. 
             * Very dangerous, use with care.
             */
            AcceptEntityInput(particle, "AddOutput");// add an output base on the variant string.
            AcceptEntityInput(particle, "FireUser1");// fire an entity output, which is OnUser1.
        }
    }
    else if( strcmp(state,"FLASH_BOMB") == 0 )
    {
        float ent_pos[3],player_pos[3],distance;
        int amount;

        GetEntPropVector(entity,Prop_Data,"m_vecOrigin",ent_pos);

        for(int i = 1; i <= MaxClients; i++)
        {
            if( !IsClientInGame(i) || !IsPlayerAlive(i) )
                continue;

            if( IsBehindWall(i,ent_pos) || !IsInClientView(entity,i))
                continue;

            GetClientEyePosition(i,player_pos);
            distance = GetVectorDistance(ent_pos,player_pos);
            if( distance <= 400.0 )  // min range that player will get full flash.
                amount = 255;

            else if( 400.0 < distance <= bomb.FlashRange )
                amount = RoundToFloor(255 * (1 - distance / bomb.FlashRange));

            SetPlayerEffect(i, amount);
        }
        
    }
}
void SetPlayerEffect(int client,int amount = 0)
{
    if( GetClientTeam(client) == 3 )
    {
        SetEntProp(client, Prop_Send, "m_iGlowType", 3);
        SetEntProp(client, Prop_Send, "m_glowColorOverride", 0xFFFFFF);
        SetEntProp(client, Prop_Send, "m_nGlowRange", 1600);
    }
    else // human
    {
        if( amount == 0 )
            return;
            
        PerformBlind(client, amount);
    }
}
void PerformBlind(int client, int amount)
{
	int targets[1];
	targets[0] = client;

	int color[4] = { 255, 255, 255, 0 };
	color[3] = amount;

	int flags = (0x0001 | 0x0010); // this flags cause white immedately, and then slowly reduce the effect.
	
	Handle message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	if(GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", bomb.FlashTime);
		pb.SetInt("hold_time", bomb.FlashFadeTime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWrite bf = UserMessageToBfWrite(message);
		bf.WriteShort(bomb.FlashTime);
		bf.WriteShort(bomb.FlashFadeTime);
		bf.WriteShort(flags);		
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
	}
	EndMessage();
}
bool IsInClientView(int entity, int client)
{
    float ent_pos[3],player_pos[3],player_ang[3];
    float eye2ent_vector[3];
    float eye2fwd_vector[3];
    char temp[16];
    GetClientInfo(client, "fov_desired", temp, sizeof(temp));
    int fov = StringToInt(temp);

    GetClientEyePosition(client,player_pos);
    GetEntPropVector(entity,Prop_Data,"m_vecOrigin",ent_pos);
    MakeVectorFromPoints(player_pos,ent_pos,eye2ent_vector);

    GetClientEyeAngles(client,player_ang);
    GetAngleVectors(player_ang,eye2fwd_vector,NULL_VECTOR,NULL_VECTOR);

    NormalizeVector(eye2ent_vector, eye2ent_vector);
    NormalizeVector(eye2fwd_vector, eye2fwd_vector);

    float radian = ArcCosine( GetVectorDotProduct(eye2ent_vector, eye2fwd_vector) );
    /**
     * let me explain how this degree radian.
     * 
     * DotProduct = |a||b|cosθ, this is the vector theorem.
     * we have normalize the vector so |a| = |b| = 1.
     * in this case DotProduct = cosθ.
     * ArcCosine() let us get the radian of θ.
     * FOV is a degree, we need make it become radian.
     */
    return radian <= DegToRad(fov + 0.0) / 2;
}
bool IsBehindWall(int client,float pos_end[3])
{
    float pos_client[3];
    GetClientEyePosition(client,pos_client);
    Handle hTrace = TR_TraceHullFilterEx(pos_client,pos_end,{2.0,2.0,2.0},{2.0,2.0,2.0},MASK_VISIBLE_AND_NPCS,Filter_IsWall,client);
    if( hTrace != null )
    {
        if( TR_DidHit(hTrace) )
        {
            delete hTrace;
            return true;
        }
    }
    delete hTrace;
    return false;
}
bool Filter_IsWall(int entity,int mask, int client)
{
	if( entity == client )
    {
        return false;
    }
	return true;
}
