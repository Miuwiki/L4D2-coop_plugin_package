#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"

ConVar cvar_vomitjar_on;    bool g_vomitjar_on;
ConVar cvar_vomitjar_range; float g_vomitjar_range;
ConVar cvar_vomitjar_time;  float g_vomitjar_time;

ArrayList swam_count;

public Plugin myinfo =
{
    name = "[L4D2] Vomitjar Extinguish Swam & Fire",
    author = "Miuwiki",
    description = "Fire and Sawm will be extinguish when vomitjar hit them and keep this effect for a second.",
    version = PLUGIN_VERSION,
    url = "http://miuwiki.site"
}
public void OnPluginStart()
{
    cvar_vomitjar_on = CreateConVar("l4d2_vomitjar_extinguish_enable","1.0","Enable vomitjar extinguish fire and swam.",0,true,0.0,true,1.0);
    cvar_vomitjar_range = CreateConVar("l4d2_vomitjar_extinguish_range","200.0","Range of vomitjar to extinguish.",0,true,20.0,true,5000.0);
    cvar_vomitjar_time = CreateConVar("l4d2_vomitjar_extinguish_time","5.0","Time of vomitjar to extinguish.",0,true,1.0,true,20.0);

    cvar_vomitjar_on.AddChangeHook(Cvar_HookChangeCallback);
    cvar_vomitjar_range.AddChangeHook(Cvar_HookChangeCallback);
    cvar_vomitjar_time.AddChangeHook(Cvar_HookChangeCallback);

    swam_count = new ArrayList();
    HookEvent("round_start",Event_RoundStartInfo);
}
public void OnConfigsExecuted()
{
    GetCvars();
}
public void Cvar_HookChangeCallback(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}
void GetCvars()
{
    g_vomitjar_on = cvar_vomitjar_on.BoolValue;
    g_vomitjar_range = cvar_vomitjar_range.FloatValue;
    g_vomitjar_time = cvar_vomitjar_time.FloatValue;
}

Action Event_RoundStartInfo(Event event,const char []name,bool dontBroadcast)
{
    swam_count.Clear();
    return Plugin_Continue;
}
public void OnEntityCreated(int entity,const char[] classname)
{
    if( g_vomitjar_on == false )
        return;
    //insect_swarm是口水滩实体
    //entity_flame跟inferno两个不知道哪个是实体火焰。有一种是特感身上的火焰。
    // == 0代替strequal 判断是否相等,性能要好
    if( strcmp("insect_swarm",classname) == 0 || strcmp("inferno",classname) == 0 ) 
    {
        SDKHook(entity,SDKHook_SpawnPost,SDKHook_SpawnPostCallback);
    }
}
Action SDKHook_SpawnPostCallback(int entity)
{
    if( IsValidEntity(entity) )
    {
        int ref = EntIndexToEntRef(entity);
        RequestFrame(NextFrame_SpawnCallback,ref);
    }
    return Plugin_Continue;
}
void NextFrame_SpawnCallback(int ref)
{
    swam_count.Push(ref);
}

public void OnEntityDestroyed(int entity)
{
    if( !IsValidEntity(entity) || g_vomitjar_on == false )
        return;

    //胆汁实体销毁时获取实体的位置。
    static char classname[64];
    GetEntityClassname(entity,classname,sizeof(classname));
    if( strcmp(classname, "vomitjar_projectile") == 0 )
    {
        //获取胆汁位置
        float f_FirstLocation[3],f_SecondLocation[3];
        GetEntPropVector(entity,Prop_Data,"m_vecOrigin",f_FirstLocation);

        int i;//for循环 在swam_count.Length = 0 的时候报错
        int width = swam_count.Length;
        while( i < width )
        {
            int ent = EntRefToEntIndex( swam_count.Get(i) );
            if( IsValidEntity(ent) )
            {
                GetEntPropVector(ent,Prop_Data,"m_vecOrigin",f_SecondLocation);
                //判断距离
                if( GetVectorDistance(f_FirstLocation, f_SecondLocation) <= g_vomitjar_range)
                {
                    RemoveEntity(ent);
                    swam_count.Erase(i);// = remove.
                    //因为Erase 会导致索引前置，如果触发删除的话，这个索引还需要继续排查，continue跳过++，长度-1
                    width--;
                    continue;
                }
            }
            i++;
        }
        DataPack pack = new DataPack();
        WritePackFloat(pack,f_FirstLocation[0]);
        WritePackFloat(pack,f_FirstLocation[1]);
        WritePackFloat(pack,f_FirstLocation[2]);
        CreateTimer(1.0,RemoveinsectAndinferno,pack,TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
    }
}
//接受数据包跟计时器函数
Action RemoveinsectAndinferno(Handle timer,DataPack pack)
{
    static int num_parity = 0;
    if( num_parity >= g_vomitjar_time ) 
    {
        num_parity = 0;
        return Plugin_Stop;
    }
    float f_FirstLocation[3],f_SecondLocation[3];
    //读取数据包，必须按照写入顺序读取，而且得先ResetPack
    ResetPack(pack);
    f_FirstLocation[0] = ReadPackFloat(pack);
    f_FirstLocation[1] = ReadPackFloat(pack);
    f_FirstLocation[2] = ReadPackFloat(pack);
    
    int i;//for循环 在swam_count.Length = 0 的时候报错
    int width = swam_count.Length;
    while( i < width )
    {
        int ent = EntRefToEntIndex( swam_count.Get(i) );
        if( IsValidEntity(ent) )
        {
            GetEntPropVector(ent,Prop_Data,"m_vecOrigin",f_SecondLocation);
            //判断距离
            if( GetVectorDistance(f_FirstLocation, f_SecondLocation) <= g_vomitjar_range)
            {
                RemoveEntity(ent);
                swam_count.Erase(i);// = remove.
                //因为Erase 会导致索引前置，如果触发删除的话，这个索引还需要继续排查.
                width--;
                continue;
            }
        }
        i++;
    }
    num_parity++;
    return Plugin_Continue;
}
