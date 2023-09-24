#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define	PLUGIN_VERSION	"1.0.0"
#define CFG_FILE "configs/hostname.txt"

ConVar 
    cvar_hostname,
    cvar_hostport,
    cvar_mpgamemode;
    
char 
    g_hostname[128],
    g_descripename[128],
    g_gamemode[128];

public Plugin myinfo = 
{
	name = "[L4D2] Hostname And Mode Name Setter.",
	author = "miuwiki",
	description = "Change your hostname and mode name base on your server port.",
	version = PLUGIN_VERSION,
	url = "https://miuwiki.site"
}

public void OnPluginStart()
{
    cvar_mpgamemode = FindConVar("mp_gamemode");
    cvar_hostname = FindConVar("hostname");
    cvar_hostport = FindConVar("hostport");
    cvar_mpgamemode.AddChangeHook();
    cvar_hostname.AddChangeHook();
    
    LoadHostname();

    RegAdminCmd("sm_rehostname",Cmd_RefreshHostname,ADMFLAG_ROOT,"刷新服务器名称，z权限可用");
}

public void OnConfigsExecuted()
{
    
}

void LoadHostname()
{
    char path[PLATFORM_MAX_PATH];
    char port[32], servername[128], modename[128], descripename[128];
    BuildPath(Path_SM, path, sizeof(path), "%s", CFG_FILE);


    if( !FileExists(path) )
    {
        KeyValues kv = new KeyValues("info");
        kv.JumpToKey(port, true);
        kv.SetString("server_name", "Server Name");
        kv.SetString("mode_name", "Mode Name");
        kv.ExportToFile(path);
        delete kv;
    }

    KeyValues kv = new KeyValues("");
    kv.ImportFromFile(path);
    if( !kv.JumpToKey(port, true) )
    {
        kv.SetString("server_name", "Server Name");
        kv.SetString("mode_name", "Mode Name");
    }
    
    kv.GetString("server_name", servername, sizeof(servername));
    cvar_hostname.

    kv.ExportToFile(path);
}

void SetHostName(const char[] name)
{
    if( cvar_hostname == null )
        return;
    
    cvar_hostname.SetString(name);
}

Action Cmd_RefreshHostname(int client,int args)
{
    if( client && client <= MaxClients )
    {
        LoadHostname();
        cvar_hostname.SetString(g_hostname);
        ReplyToCommand(client,"刷新服务器hostname成功!");
    }
    return Plugin_Handled;
}