#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

#define STR_TITLESEPARA "-------------------"
#define STR_SPACER "  "
#define STR_SELECT "▸"
#define STR_OPEN "▾"

enum struct player
{
    ArrayList arr_section;
    KeyValues kv;
    float presuretime;
    float endtime;
    int   displaytime;
    bool  isitem;
    char  iteminfo[128];
    char  itemname[128];

    void Init()
    {
        this.isitem = false;
        this.iteminfo = "";
        this.itemname = "";
        this.presuretime = 0.0;
        this.endtime = 0.0;
        this.arr_section = new ArrayList();
        this.kv = new KeyValues("");
    }

    void InfoClear()
    {
        this.isitem = false;
        this.iteminfo = "";
        this.itemname = "";
        this.presuretime = 0.0;
        this.endtime = 0.0;
        this.arr_section.Clear();
        this.kv.Rewind();
        this.kv.DeleteThis();
    }
}


PrivateForward g_hNewmenuAdditemForward;
player g_player[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[L4D2] New Menu System API",
	author = "Miuwiki",
	description = "Make menu more useful.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}
public void OnPluginStart()
{
    g_hNewmenuAdditemForward = new PrivateForward(ET_Ignore, Param_Array, Param_Cell, Param_String);
    for(int i = 1; i <= MaxClients; i++)
    {
        g_player[i].Init();
    }
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if( GetEngineVersion() != Engine_Left4Dead2 ) // only support left4dead2
        return APLRes_SilentFailure;

    RegPluginLibrary("miuwiki_menusys");
    /**
     * These for methodmap server
     */
    CreateNative("Newmenu.AddTitle", Native_Miuwiki_MenuSysAddTitle);
    CreateNative("Newmenu.AddSection", Native_Miuwiki_MenuSysAddSection);
    CreateNative("Newmenu.AddItem", Native_Miuwiki_MenuSysAddItem);
    CreateNative("Newmenu.GoBack", Native_Miuwiki_MenuSysSectionGoback);
    CreateNative("Newmenu.Send", Native_Miuwiki_MenuSysSend);

    return APLRes_Success;
}
/** 
 * methodmap native start 
 */
any Native_Miuwiki_MenuSysAddTitle(Handle plugin, int arg_num)
{
    int client = GetNativeCell(1);
    int size;
    GetNativeStringLength(2, size);
    size++;

    char [] name = new char [size];
    GetNativeString(2, name, size);
    g_player[client].kv.Rewind();
    g_player[client].kv.SetSectionName(name);
    return 1;
}
any Native_Miuwiki_MenuSysAddSection(Handle plugin, int arg_num)
{
    int client = GetNativeCell(1);
    int size;
    GetNativeStringLength(2, size);
    size++;

    char [] name = new char [size];
    GetNativeString(2, name, size);
    g_player[client].kv.JumpToKey(name, true);
    return 1;
}
any Native_Miuwiki_MenuSysAddItem(Handle plugin, int arg_num)
{
    int client = GetNativeCell(1);
    int size1, size2;
    GetNativeStringLength(2, size1);
    GetNativeStringLength(3, size2);
    size1++; size2++;

    char [] name = new char [size1];
    char [] info = new char [size2];
    GetNativeString(2, name, size1);
    GetNativeString(3, info, size2);
    g_player[client].kv.JumpToKey(name, true);
    // g_player[client].kv.SetString(NULL_STRING, info);
    g_player[client].kv.SetString(name, info);
    g_player[client].kv.GoBack();
    return 1;
}
any Native_Miuwiki_MenuSysSectionGoback(Handle plugin, int arg_num)
{
    int client = GetNativeCell(1);
    g_player[client].kv.GoBack();
    return 1;
}
any Native_Miuwiki_MenuSysSend(Handle plugin, int arg_num)
{
    int client = GetNativeCell(1);
    int target = GetNativeCell(2);
    g_hNewmenuAdditemForward.RemoveFunction(plugin, GetNativeFunction(3));
    g_hNewmenuAdditemForward.AddFunction(plugin, GetNativeFunction(3));
    g_player[target].kv = g_player[client].kv; // do this for the situtation that show to all player.
    g_player[target].displaytime = GetNativeCell(4);
    g_player[target].arr_section.Push(0);

    // char path[PLATFORM_MAX_PATH];
    // BuildPath(Path_SM, path, sizeof(path) ,"%s/data/testkv.txt", path);
    // g_player[target].kv.ExportToFile(path);

    // 
    SetMenuByKv(client);
    SetEntityMoveType(client, MOVETYPE_NONE);
    SDKHook(client, SDKHook_PostThink, SDKCallback_PT);
    
    return 1;
}

public void OnClientConnected(int client)
{
    if( IsFakeClient(client) )
        return;
    
    g_player[client].InfoClear();
}

public void OnClientDisconnect(int client)
{
    if( IsFakeClient(client) )
        return;

    g_player[client].InfoClear();
}

void SDKCallback_PT(int client)
{
    if( !IsClientInGame(client) )
        return;
    
    int buttons = GetClientButtons(client);

    if( GetEngineTime() - g_player[client].presuretime <= 0.1 )
        return;
    else
        g_player[client].presuretime = GetEngineTime();

    if( buttons & IN_MOVERIGHT )
    {
        // check is item or not.
        if( g_player[client].isitem )
        {
            SDKUnhook(client, SDKHook_PostThink, SDKCallback_PT);
            SetEntityMoveType(client, MOVETYPE_WALK);

            SetMenuCallback(client);
            return;
        }

        // show the sections detail and go to the first item
        g_player[client].arr_section.Push( 0 ); // push new section and set the position 0.
        SetMenuByKv(client);
    }
    else if( buttons & IN_MOVELEFT)
    {
        // close the sections detail and go to the last section
        if( g_player[client].arr_section.Length == 1 )
            return;

        g_player[client].arr_section.Erase( g_player[client].arr_section.Length - 1 ); // erase the last one of the arraylist.
        SetMenuByKv(client);
    }
    else if( buttons & IN_FORWARD )
    {
        // go to last item
        int position = g_player[client].arr_section.Get(g_player[client].arr_section.Length - 1);
        if( position == 0 )
            return;
        
        g_player[client].arr_section.Set(g_player[client].arr_section.Length - 1, position - 1);
        SetMenuByKv(client);
    }
    else if( buttons & IN_BACK)
    {
        // go to next item
        int position = g_player[client].arr_section.Get(g_player[client].arr_section.Length - 1);
        if( position == GetSectionKeyNum(client) - 1 )
            return;

        g_player[client].arr_section.Set(g_player[client].arr_section.Length - 1, position + 1);
        SetMenuByKv(client);
    }
}

void SetMenuByKv(int client)
{
    static char name[512]; name = "";
    static char spacer[64]; spacer = "";
    int step, position;
    bool firstone, isitem;

    Panel p = new Panel();
    g_player[client].kv.Rewind();
    g_player[client].kv.GetSectionName(name, sizeof(name));
    if( strcmp(name, "") != 0 )
    {
        p.SetTitle(name);
        p.DrawText(STR_TITLESEPARA);
    }
    
    g_player[client].kv.GotoFirstSubKey();
    do
    {
        if( firstone )
        {
            Format(spacer, sizeof(spacer), "%s%s", spacer, STR_SPACER);
            g_player[client].kv.GoBack();
            firstone = false;
        }

        g_player[client].kv.GetSectionName(name, sizeof(name));
        // first time the menu opening or the section is no need open.
        if( step == g_player[client].arr_section.Length - 1 || position < g_player[client].arr_section.Get(step) ) 
        {
            if( position == g_player[client].arr_section.Get(step) )
            {
                if( g_player[client].kv.GotoFirstSubKey() )
                    g_player[client].kv.GoBack();
                else
                {
                    // now we are in an item, set it's name and info.
                    isitem = true;
                    g_player[client].kv.GetString(name, g_player[client].iteminfo, sizeof(g_player[].iteminfo));
                    FormatEx(g_player[client].itemname, sizeof(g_player[].itemname), "%s", name);
                }

                Format(name, sizeof(name), "%s %s", STR_SELECT, name);
            }
                
            Format(name, sizeof(name), "%s%s", spacer, name);
            p.DrawText(name);
            position++;
        }
        else
        {
            Format(name, sizeof(name), "%s%s %s", spacer, STR_OPEN, name);
            p.DrawText(name);

            if( g_player[client].kv.GotoFirstSubKey() ) // this children still a sections, go and get it's section name.
            {
                g_player[client].kv.SavePosition();
                firstone = true;
                step++; position = 0;
            }
            else
            {
                // something wrong here.
            }
        }
    }
    while(g_player[client].kv.GotoNextKey());

    // now we need to draw the sections after the opening section.
    firstone = false;
    for(int i = 0; i < step; i++)
    {
        g_player[client].kv.GoBack();
        spacer[strlen(spacer) - strlen(STR_SPACER)] = '\x0';
        firstone = true;
        do
        {
            if( firstone ) // skip the first one, since this is the open section and has draw upon.
            {
                firstone = false;
                continue;
            }
                
            g_player[client].kv.GetSectionName(name, sizeof(name));
            Format(name, sizeof(name), "%s%s", spacer, name);
            p.DrawText(name);
        }
        while(g_player[client].kv.GotoNextKey());
    }

    // if( p.TextRemaining <= 0 )
    // {
    //     delete p;
    //     p = new Panel();
    // }

    g_player[client].isitem = isitem;
    g_player[client].endtime = GetEngineTime() + g_player[client].displaytime;
    p.Send(client, PanelHandler, g_player[client].displaytime);
}

int GetSectionKeyNum(int client)
{
    g_player[client].kv.Rewind();
    g_player[client].kv.GotoFirstSubKey();
    int count, index, position;
    bool firstone;
    do
    {
        if( firstone )
        {
            g_player[client].kv.GoBack();
            firstone = false;
        }

        if( index == g_player[client].arr_section.Length - 1 ) // is the target section?
        {
            count++;
        }
        else if( position == g_player[client].arr_section.Get(index) ) // is the index need to go to next?
        {
            g_player[client].kv.GotoFirstSubKey();
            g_player[client].kv.SavePosition();
            firstone = true;
            index++; position = 0;
        }
        else
        {
            position++;
        }
    }
    while(g_player[client].kv.GotoNextKey());

    // PrintToChat(client, "当前页面position max 是%d", count);
    return count;
}

void SetMenuCallback(int client)
{
    int [] list = new int[g_player[client].arr_section.Length];
    for(int i = 0; i < g_player[client].arr_section.Length - 1; i++)
    {
        list[i] = g_player[client].arr_section.Get(i);
    }
    Call_StartForward(g_hNewmenuAdditemForward);
    Call_PushArray(list, g_player[client].arr_section.Length);
    Call_PushCell(client);
    Call_PushString(g_player[client].iteminfo);
    Call_Finish();

    // if someone know how to cancel a client's panel, please tell me.
    Panel p = new Panel();
    static char name[128];
    FormatEx(name, sizeof(name), "你选择了 %s", g_player[client].itemname);
    p.DrawText(name);

    p.Send(client, PanelHandler, 5);
    g_player[client].InfoClear();
}
int PanelHandler(Menu menu, MenuAction action, int client, int item)
{
    if( action == MenuAction_Select )
    {
        SDKUnhook(client, SDKHook_PostThink, SDKCallback_PT);
        SetEntityMoveType(client, MOVETYPE_WALK);
        g_player[client].InfoClear();
        
        // PrintToChat(client, "select %d index", item);
    }
    else if( action == MenuAction_Cancel )  
    {
        if( GetEngineTime() >= g_player[client].endtime ) // time out close
        {
            SDKUnhook(client, SDKHook_PostThink, SDKCallback_PT);
            SetEntityMoveType(client, MOVETYPE_WALK);
            g_player[client].InfoClear();
        }

        delete menu;
    }
    
    return 1;
}