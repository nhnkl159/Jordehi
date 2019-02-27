#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "Knife Fight"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //

// === Strings === //

// === Booleans === //
bool gB_LRActivated = false;

// === Floats === //

// === Handles === //

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Keepomod.com",
	description = "",
	version = "1.0",
	url = "Keepomod.com"
};

public void OnAllPluginsLoaded()
{
	Jordehi_RegisterLR(LR_NAME, "");
	
	gB_LRActivated = false;
}

public void Jordehi_OnLRStart(char[] lr_name, int terrorist, int ct, bool random)
{
	if(StrEqual(lr_name, LR_NAME))
	{
		gB_LRActivated = true;
	}
	
	if(!Jordehi_IsClientValid(terrorist) && !Jordehi_IsClientValid(ct))
	{
		Jordehi_StopLastRequest();
		return;
	}
	
	if(!gB_LRActivated)
	{
		return;
	}
	
	//Start Here
	
	//OpenSettingsMenu(terrorist);
}


void OpenSettingsMenu(int client)
{
	Menu m = new Menu(Settings_Handler);
	m.SetTitle("Settings Menu :");
	m.AddItem("1", "");
	m.AddItem("0", "End Settings");
	m.ExitButton = false;
	m.Display(client, 30);
}

public int Settings_Handler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char sInfo[8];
		menu.GetItem(item, sInfo, 8);
		int iItem = StringToInt(sInfo);
		switch(iItem)
		{
			case 0:
			{
				InitiateLR(client);
			}
		}
		if(iItem != 0)
		{
			OpenSettingsMenu(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		Jordehi_StopLastRequest();
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void InitiateLR(int client)
{
	if(!gB_LRActivated)
	{
		return;
	}
	
	if(!Jordehi_IsAbleToStartLR(client))
	{
		Jordehi_StopLastRequest();
		return;
	}
	
	/*char sTemp[128];
	FormatEx(sTemp, 128, "- Something enabled : %s", gB_Something ? "Yes" : "No");
	Jordehi_UpdateExtraInfo(sTemp);*/
	
	int terrorist = client;
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	SDKHook(terrorist, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(ct, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if (!gB_LRActivated || !Jordehi_IsClientInLastRequest(client))
	{
		return Plugin_Continue;
	}
	
	char[] sWeapon = new char[32];
	GetEntityClassname(weapon, sWeapon, 32);
	
	if(!StrEqual(sWeapon, ""))
	{
		
	}
	
	return Plugin_Continue;
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	if(gB_LRActivated)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void Jordehi_OnLREnd(char[] lr_name, int winner, int loser)
{
	if(!gB_LRActivated)
	{
		return;
	}
	
	gB_LRActivated = false;
	
	//Reset vars
	
	if(Jordehi_IsClientValid(winner))
	{	
		SDKUnhook(winner, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
	
	if(Jordehi_IsClientValid(loser))
	{
		SDKUnhook(loser, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
}