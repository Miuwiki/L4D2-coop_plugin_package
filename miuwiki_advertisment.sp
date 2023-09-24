#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <miuwiki_serverapi>

#define CFG_NAME "l4d2_advertisment.txt"
#define PLUGIN_VERSION "1.0.0"

float 
    g_advertisment_time;

ConVar
    cvar_advertisment_time;

Server server;
StringMap g_advertisment_info;

public Plugin myinfo =    
{
    name = "[L4D2] WelCome & Adevertisment",   
	author = "Miuwiki",   
	description = "Infomation of welcome and advertisment",   
	version = PLUGIN_VERSION,   
	url = "https://miuwiki.site"  
}
public void OnPluginStart()   
{   
    g_advertisment_info = new StringMap();
    RegAdminCmd("sm_mreloadadv",Cmd_ReloadAdvertisment,ADMFLAG_ROOT,"重新加载公告插件");

    HookEvent("round_start",Event_RoundStart);
    cvar_advertisment_time = CreateConVar("l4d2_advertisment_time","20.0","公告间隔时间",0);
    cvar_advertisment_time.AddChangeHook(Cvar_HookCallback);
}

public void OnConfigsExecuted()
{
    g_advertisment_time = cvar_advertisment_time.FloatValue;
}
void Cvar_HookCallback(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_advertisment_time = cvar_advertisment_time.FloatValue;
}

void Event_RoundStart(Event event, const char[] name, bool dontBoradcast)
{
    LoadAdvertisment();
}
public void M_OnPlayerFirstSpawn()
{
    CreateTimer(1.0,Timer_ShowAdvertisment,_,TIMER_REPEAT);
}

Action Timer_ShowAdvertisment(Handle timer)
{
    static int time;
    static int index = 1;
    if( !server.IsRoundStart )// no need for no map change flag.
    {
        time = 0;
        index = 1;
        return Plugin_Stop;
    } 

    if( g_advertisment_info.Size == 0 )
        return Plugin_Continue;
    
    int current = GetTime();
    if( current - time >= g_advertisment_time )
    {
        time = current;
        // show advertisment.
        char text[1024], temp[4];
        IntToString(index,temp,sizeof(temp));
        g_advertisment_info.GetString(temp,text,sizeof(text));
        PrintToChatAll("%s",text);
        index++;

        if( index >= g_advertisment_info.Size )
            index = 1;
    }
    return Plugin_Continue;
}
Action Cmd_ReloadAdvertisment(int client, int args)
{
    if( client < 1 || client > MaxClients || !IsClientInGame(client) )
        return Plugin_Handled;
    
    LoadAdvertisment();
    PrintToChat(client,"\x05已刷新公告信息.");
    return Plugin_Handled;
}
public void OnClientPutInServer(int client)
{
    if( IsFakeClient(client) )
        return;

    char text[1024];
    g_advertisment_info.GetString("Welcome",text,sizeof(text));
    PrintToChat(client,"%s",text);
    for(int i = 1; i <= MaxClients; i++)
    {
        if( !IsClientInGame(i) || IsFakeClient(i) )
            return;
        
        if( i == client )
            return;
        
        PrintToChat(i,"\x04 %N \x01 加入了游戏!", client);
    }
}

void LoadAdvertisment()
{
    g_advertisment_info.Clear();

    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "data/%s",CFG_NAME);
    if( FileExists(sPath) == false ) 
    {
        PrintToServer("[miuwiki_advertisment]: Doesn't find the 'l4d2_advertisment.txt', plugins tring to create.");
        KeyValues kv = CreateKeyValues("Info");

        kv.JumpToKey("Welcome",true);
        kv.SetString(NULL_STRING,"<or>[公告]<dg>欢迎来到服务器, 希望你玩的愉快!");
        kv.Rewind();
        kv.JumpToKey("Advertisment",true);
        for(int i = 1; i <= 5; i++)
        {
            char text[4];
            IntToString(i,text,sizeof(text));
            kv.JumpToKey(text,true);
            kv.SetString(NULL_STRING,"<or>[公告]<dg>请填写公告信息.");
            kv.GoBack();
        }
        kv.Rewind();
        kv.ExportToFile(sPath);
        delete kv;
    }

    char string[1024];
    KeyValues kv = CreateKeyValues("Info");
    kv.ImportFromFile(sPath);

    kv.GetString("Welcome",string,sizeof(string));
    ReplaceColorString(string,sizeof(string));
    g_advertisment_info.SetString("Welcome",string);
    kv.Rewind();

    int i = 1;char text[4];
    kv.JumpToKey("Advertisment",false);
    do
    {
        IntToString(i,text,sizeof(text));
        kv.GetString(text,string,sizeof(string));
        ReplaceColorString(string,sizeof(string));
        g_advertisment_info.SetString(text,string);
        i++;
    }
    while(strcmp(string,"") != 0);
    delete kv;
}
void ReplaceColorString(char[] text, int size)
{
    ReplaceString(text,size,"<or>","\x04");
    ReplaceString(text,size,"<dg>","\x05");
    ReplaceString(text,size,"<lg>","\x03");
    ReplaceString(text,size,"<wh>","\x01");
    ReplaceString(text,size,"<n>","\n");
    char hostname[128];
    FindConVar("hostname").GetString(hostname, sizeof(hostname));
    ReplaceString(text,size,"<hostname>",hostname);
}