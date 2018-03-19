/******************************************************************/
/*                                                                */
/*                         Block Private                          */
/*                                                                */
/*                                                                */
/*  File:          block_private.sp                               */
/*  Description:   block player who is private profiles.          */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle   https://kxnrl.com                  */
/*  2018/03/17 16:41:55                                           */
/*                                                                */
/*  This code is licensed under the MIT License (MIT).            */
/*                                                                */
/******************************************************************/

// エトランゼ - doriko feat. Hatsune Miku

#pragma semicolon 1
#pragma newdecls required

#include <system2>

#define PI_NAME "Block Private"
#define PI_AUTH "Kyle"
#define PI_DESC "block player who is private profiles"
#define PI_VERS "1.0"
#define PI_URLS "https://kxnrl.com"

public Plugin myinfo = 
{
    name        = PI_NAME,
    author      = PI_AUTH,
    description = PI_DESC,
    version     = PI_VERS,
    url         = PI_URLS
};


StringMap g_smWihteList = null;

public void OnPluginStart()
{
    g_smWihteList = new StringMap();
    
    char path[128];
    BuildPath(Path_SM, path, 128, "data/block_private");
    if(!DirExists(path))
        CreateDirectory(path, 511);
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if(IsFakeClient(client) || IsClientSourceTV(client))
        return;
    
    int userid = GetClientUserId(client);
    
    char steamid[32];
    if(!GetClientAuthId(client, AuthId_SteamID64, steamid, 32, true))
    {
        DataPack pack = new DataPack();
        pack.WriteCell(userid);
        pack.WriteString("获取您的Steam64位ID失败\n请您重新进入服务器");
        RequestFrame(Frame_KickClient, pack);
        return;
    }
    
    if(CheckWhiteList(steamid))
        return;

    char url[128], loc[128];
    FormatEx(url, 128, "https://csgogamers.com/check.php?steam=%s",   steamid);
    FormatEx(loc, 128, "addons/sourcemod/data/block_private/%d.data", userid);
    System2_DownloadFile(CheckClient, url, loc, userid);
}

public void CheckClient(bool finished, const char[] error, float dltotal, float dlnow, float ultotal, float ulnow, int userid)
{
    if(!finished)
        return;

    int client = GetClientOfUserId(userid);
    if(!client || !IsClientConnected(client))
        return;

    if(error[0])
    {
        CreateTimer(3.0, Timer_ReAuth, userid, TIMER_FLAG_NO_MAPCHANGE);
        LogError("CheckClient -> %L -> %s", client, error);
        return;
    }
    
    char loc[128];
    FormatEx(loc, 128, "addons/sourcemod/data/block_private/%d.data", userid);
    File file = OpenFile(loc, "r+");
    if(file == null)
    {
        CreateTimer(3.0, Timer_ReAuth, userid, TIMER_FLAG_NO_MAPCHANGE);
        LogError("CheckClient -> %L -> %s is null", client, loc);
        return;
    }
    
    char output[256];
    file.ReadString(output, 256);
    delete file;
    DeleteFile(loc);

    LogEx("\"%L\" -> output[%s]", client, output);

    if(StrContains(output, "curl error") == 0)
    {
        CreateTimer(3.0, Timer_ReAuth, userid, TIMER_FLAG_NO_MAPCHANGE);
        LogError("CheckClient -> %L -> %s", client, output);
        return;
    }

    if(StrContains(output, "Allow") == 0)
    {
        PrintToServer("%L is allowed.", client);
        PushClientToWhiteList(client);
        return;
    }

    DataPack pack = new DataPack();
    pack.WriteCell(userid);

    if(StrContains(output, "Private Profiles") == 0)
        pack.WriteString("您的Steam个人资料是私密的\n请先设置为公开");
    else
        pack.WriteString(output);

    RequestFrame(Frame_KickClient, pack);
}

public Action Timer_ReAuth(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client || !IsClientAuthorized(client))
        return Plugin_Stop;
    
    OnClientAuthorized(client, "");
    
    return Plugin_Stop;
}

static void Frame_KickClient(DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    char output[256];
    pack.ReadString(output, 256);
    delete pack;

    int client = GetClientOfUserId(userid);
    if(!client || !IsClientConnected(client))
        return;

    KickClient(client, output);
}

static void PushClientToWhiteList(int client)
{
    char steamid[32];
    GetClientAuthId(client, AuthId_SteamID64, steamid, 32, true);
    g_smWihteList.SetValue(steamid, GetTime()+1800, true);
}

static bool CheckWhiteList(const char[] steamid)
{
    int val = -1;
    if(!g_smWihteList.GetValue(steamid, val) || val == -1)
        return false;
    
    if(val < GetTime())
    {
        g_smWihteList.Remove(steamid);
        return false;
    }
    
    return true;
}

static void LogEx(const char[] buf, any ...)
{
    char vf[512];
    VFormat(vf, 512, buf, 2);
    LogToFileEx("addons/sourcemod/logs/block.private.log", vf);
}