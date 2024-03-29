#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "Shot4Shot"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //
int gI_Weapon;
int gI_PlayerTurn;
int gI_Ammo = -1;

// === Strings === //
char gS_CSGOPistols[][] =
{
    "weapon_deagle",
    "weapon_revolver",
    "weapon_glock",
    "weapon_fiveseven",
    "weapon_usp_silencer",
    "weapon_p250",
    "weapon_cz75a",
    "weapon_tec9",
    "weapon_hkp2000",
    "weapon_elite"
};

char gS_CSGOPistolNames[][] =
{
    "Night Hawk .50C (Desert Eagle)",
    "R8 Revolver",
    "9×19mm Sidearm (Glock 18)",
    "FN Five-seveN",
    "H&K USP45 Tactical (USP-S)",
    "P250",
    "CZ75-Auto",
    "Tec-9",
    "P2000",
    ".40 Dual Elites (Dual Berettas)"
};

// === Booleans === //
bool gB_LRActivated = false;
bool gB_HeadshotsOnly = false;

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
	HookEvent("weapon_fire", OnPlayerFire);
	
	gI_Ammo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	
	Jordehi_RegisterLR(LR_NAME, "");
	
	gB_LRActivated = false;
}

public void OnPlayerFire(Event e, const char[] name, bool dB)
{
	int client = GetClientOfUserId(e.GetInt("userid"));
	
	if(!Jordehi_IsClientValid(client))
	{
		return;
	}
	
	if(!gB_LRActivated)
	{
		return;
	}
	
	if(Jordehi_IsClientInLastRequest(client) && gI_PlayerTurn == client)
	{
		gI_PlayerTurn = Jordehi_GetClientOpponent(client);
		int iWeapon = GetPlayerWeaponSlot(gI_PlayerTurn, CS_SLOT_SECONDARY);
		
		SetWeaponAmmo(gI_PlayerTurn, iWeapon, 1, 0);
	}
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
	
	
	if(random)
	{
		int iRand = GetRandomInt(1, 2);
		if(iRand == 2)
		{
			gB_HeadshotsOnly = true;
		}
		InitiateLR(terrorist, GetRandomInt(1, sizeof(gS_CSGOPistols)));
		return;
	}
	
	Menu menu = new Menu(MenuHandler_Weapons);
	menu.SetTitle("Choose weapon : ");
	for(int i = 0; i < sizeof(gS_CSGOPistols); i++)
	{
		char[] sMenuInfo = new char[8];
		IntToString(i, sMenuInfo, 8);

		menu.AddItem(sMenuInfo, gS_CSGOPistolNames[i]);
	}
	menu.ExitButton = false;
	menu.Display(terrorist, 60);
}

public int MenuHandler_Weapons(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char sInfo[8];
		menu.GetItem(item, sInfo, 8);

		gI_Weapon = StringToInt(sInfo);
		
		OpenSettingsMenu(client);
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

void OpenSettingsMenu(int client)
{
	char sTemp[128];
	FormatEx(sTemp, 128, "Headshots only : %s", gB_HeadshotsOnly ? "Yes" : "No");
	Menu m = new Menu(Settings_Handler);
	m.SetTitle("Settings Menu :");
	m.AddItem("1", sTemp);
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
				InitiateLR(client, gI_Weapon);
			}
			case 1:
			{
				gB_HeadshotsOnly = !gB_HeadshotsOnly;
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

void InitiateLR(int client, int choice)
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
	
	char sTemp[128];
	FormatEx(sTemp, 128, "- Weapon : %s \n- Headshots only enabled : %s", gS_CSGOPistols[choice], gB_HeadshotsOnly ? "Yes" : "No");
	Jordehi_UpdateExtraInfo(sTemp);
	
	int terrorist = client;
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	Jordehi_LoopClients(i)
	{
		if(IsPlayerAlive(i))
		{
			SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	
	GivePlayerItem(terrorist, "weapon_knife");
	GivePlayerItem(terrorist, gS_CSGOPistols[choice]);

	GivePlayerItem(ct, "weapon_knife");
	GivePlayerItem(ct, gS_CSGOPistols[choice]);
	
	int iRand = GetRandomInt(1, 2);
	gI_PlayerTurn = iRand == 1 ? terrorist : ct;
	
	Jordehi_PrintToChatAll("\x07%N\x01 was selected randomaly to shot first !", gI_PlayerTurn);
	
	int iWeapon = GetPlayerWeaponSlot(gI_PlayerTurn, CS_SLOT_SECONDARY);
	int iWeapon_opp = GetPlayerWeaponSlot(Jordehi_GetClientOpponent(gI_PlayerTurn), CS_SLOT_SECONDARY);
	
	SetWeaponAmmo(gI_PlayerTurn, iWeapon, 1, 0);
	SetWeaponAmmo(Jordehi_GetClientOpponent(gI_PlayerTurn), iWeapon_opp, 0, 0);
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if (!gB_LRActivated || !Jordehi_IsClientInLastRequest(client))
	{
		return Plugin_Continue;
	}
	
	char[] sWeapon = new char[32];
	GetEntityClassname(weapon, sWeapon, 32);
	
	if(!StrEqual(sWeapon, gS_CSGOPistols[gI_Weapon]))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!Jordehi_IsClientValid(attacker))
	{
		return Plugin_Continue;
	}
	
	if(gB_LRActivated)
	{
		char[] sWeapon = new char[32];
		GetClientWeapon(attacker, sWeapon, 32);
	
		if(!StrEqual(sWeapon, gS_CSGOPistols[gI_Weapon]))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		//IDK IF SHOULD BE LIKE THAT
		if(gB_HeadshotsOnly && damagetype & CS_DMG_HEADSHOT == 0)
		{
			damage = 0.0;
			return Plugin_Changed;
		}
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
	gB_HeadshotsOnly = false;
	
	Jordehi_LoopClients(i)
	{
		SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

//Thanks shavit
void SetWeaponAmmo(int client, int weapon, int first = -1, int second = -1)
{
	if(first != -1)
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1", first);
	}

	if(second != -1)
	{
		int iAmmo = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		SetEntData(client, gI_Ammo + (iAmmo * 4), second, 4, true);
		SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", second);
	}
}