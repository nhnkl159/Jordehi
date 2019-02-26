#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "NoScope Battle"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //
int gI_Weapon;
int gI_Ammo = -1;
int gI_NextSecondaryAttack = -1;

// === Strings === //
char gS_CSGOSnipers[][] =
{
    "weapon_awp",
    "weapon_g3sg1",
    "weapon_scar20",
    "weapon_ssg08"
};

char gS_CSGOSniperNames[][] =
{
    "Magnum Sniper Rifle (AWP)",
    "D3/AU-1 (G3SG1)",
    "SCAR-20",
    "SSG 08 (Scout)"
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
	Jordehi_RegisterLR(LR_NAME, "");
	
	HookEvent("weapon_fire", OnPlayerFire);
	
	gI_Ammo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	gI_NextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	
	gB_LRActivated = false;
}

public void OnPlayerFire(Event e, const char[] name, bool dB)
{
	int client = GetClientOfUserId(e.GetInt("userid"));
	
	if(!Jordehi_IsClientValid(client))
	{
		return;
	}
	
	if(gB_LRActivated && Jordehi_IsClientInLastRequest(client))
	{
		int iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		SetWeaponAmmo(client, iWeapon, 1000, 1000);
	}
}

public void Jordehi_OnLRStart(char[] lr_name, int terrorist, int ct, bool random)
{
	if(StrEqual(lr_name, LR_NAME))
	{
		gB_LRActivated = true;
		SDKHook(terrorist, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKHook(ct, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKHook(terrorist, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(ct, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(terrorist, SDKHook_PreThink, PreThink);
		SDKHook(ct, SDKHook_PreThink, PreThink);
	}
	
	if(!Jordehi_IsClientValid(terrorist) && !Jordehi_IsClientValid(ct))
	{
		Jordehi_StopLastRequest();
		return;
	}
	
	if(gB_LRActivated)
	{
		if(random)
		{
			int iRand = GetRandomInt(1, 2);
			if(iRand == 2)
			{
				gB_HeadshotsOnly = true;
			}
			InitiateLR(terrorist, GetRandomInt(1, sizeof(gS_CSGOSnipers)));
			return;
		}
		
		Menu menu = new Menu(MenuHandler_Weapons);
		menu.SetTitle("Choose weapon : ");
		for(int i = 0; i < sizeof(gS_CSGOSnipers); i++)
		{
			char[] sMenuInfo = new char[8];
			IntToString(i, sMenuInfo, 8);

			menu.AddItem(sMenuInfo, gS_CSGOSniperNames[i]);
		}
		menu.ExitButton = false;
		menu.Display(terrorist, 60);
	}
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

	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

public void Jordehi_OnLREnd(char[] lr_name, int winner, int loser)
{
	if(gB_LRActivated)
	{
		SDKUnhook(winner, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(loser, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(winner, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(loser, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(winner, SDKHook_PreThink, PreThink);
		SDKUnhook(loser, SDKHook_PreThink, PreThink);
		gB_LRActivated = false;
		gB_HeadshotsOnly = false;
	}
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
	
	char sTemp[128];
	FormatEx(sTemp, 128, "- Weapon : %s \n- Headshots only enabled : %s", gS_CSGOSniperNames[choice], gB_HeadshotsOnly ? "Yes" : "No");
	Jordehi_UpdateExtraInfo(sTemp);
	
	int terrorist = client;
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	GivePlayerItem(terrorist, gS_CSGOSnipers[choice]);

	GivePlayerItem(ct, gS_CSGOSnipers[choice]);
	
	int iWeapon = GetPlayerWeaponSlot(terrorist, CS_SLOT_PRIMARY);
	SetWeaponAmmo(terrorist, iWeapon, -1, 1000);
	iWeapon = GetPlayerWeaponSlot(ct, CS_SLOT_PRIMARY);
	SetWeaponAmmo(ct, iWeapon, -1, 1000);
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if (!gB_LRActivated && !Jordehi_IsClientInLastRequest(client))
	{
		return Plugin_Continue;
	}
	
	char[] sWeapon = new char[32];
	GetEntityClassname(weapon, sWeapon, 32);
	
	if(!StrEqual(sWeapon, gS_CSGOSnipers[gI_Weapon]))
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
	
		if(!StrEqual(sWeapon, gS_CSGOSnipers[gI_Weapon]))
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

public void PreThink(int client)
{
	if(!gB_LRActivated)
	{
		return;
	}

	int iWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if(iWeapon != -1 && IsValidEntity(iWeapon))
	{
		SetEntDataFloat(iWeapon, gI_NextSecondaryAttack, GetGameTime() + 1.0);
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