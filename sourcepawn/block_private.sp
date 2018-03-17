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
        pack.WriteCell(128);
        pack.WriteString("获取您的Steam64位ID失败\n请您重新进入服务器");
        RequestFrame(Frame_KickClient, pack);
        return;
    }
    
    if(CheckWhiteList(steamid))
        return;

    char url[192];
    FormatEx(url, 192, "https://csgogamers.com/check.php?steam=%d", steamid);
    System2_GetPage(CheckClient, url, "", "Half Life 2", userid);
}

public void CheckClient(const char[] output, const int size, CMDReturn status, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client || !IsClientConnected(client))
        return;
    
    if(status != CMD_SUCCESS)
    {
        OnClientAuthorized(client, "");
        LogError("CheckClient -> %L -> status code [%d]", client, view_as<int>(status));
        return;
    }
    
    if(StrContains(output, "curl error", false) == 0)
    {
        OnClientAuthorized(client, "");
        LogError("CheckClient -> %L -> %s", client, output);
        return;
    }
    
    if(strcmp(output, "Allow") == 0)
    {
        PrintToServer("%L is allowed.", client);
        PushClientToWhiteList(client);
        return;
    }
    
    DataPack pack = new DataPack();
    pack.WriteCell(userid);
    pack.WriteCell(size);

    if(strcmp(output, "Private Profiles") == 0)
    {
        pack.WriteString("您的Steam个人资料是私密的\n请先设置为公开");
    }
    else
    {
        pack.WriteString(output);
    }

    RequestFrame(Frame_KickClient, pack);
}

static void Frame_KickClient(DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    int maxLen = pack.ReadCell();
    char[] output = new char[maxLen];
    pack.ReadString(output, maxLen);
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