#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
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
	
	if(gB_LRActivated && Jordehi_IsClientInLastRequest(client))
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
	
	if(gB_LRActivated)
	{
		if(random)
		{
			StartShot4Shot(terrorist, GetRandomInt(1, sizeof(gS_CSGOPistols)));
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
}

public int MenuHandler_Weapons(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char sInfo[8];
		menu.GetItem(item, sInfo, 8);

		gI_Weapon = StringToInt(sInfo);
		
		StartShot4Shot(client, gI_Weapon);
	}

	else if(action == MenuAction_End)
	{
		Jordehi_StopLastRequest();
		delete menu;
	}

	return 0;
}

void StartShot4Shot(int client, int choice)
{
	int terrorist = client;
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	GivePlayerItem(terrorist, "weapon_knife");
	GivePlayerItem(terrorist, gS_CSGOPistols[choice]);

	GivePlayerItem(ct, "weapon_knife");
	GivePlayerItem(ct, gS_CSGOPistols[choice]);
	
	int iRand = GetRandomInt(1, 2);
	switch(iRand)
	{
		case 1:
		{
			gI_PlayerTurn = terrorist;
		}
		case 2:
		{
			gI_PlayerTurn = ct;
		}
	}
	
	int iWeapon = GetPlayerWeaponSlot(gI_PlayerTurn, CS_SLOT_SECONDARY);
	
	SetWeaponAmmo(gI_PlayerTurn, iWeapon, 1, 0);
}

public void Jordehi_OnLREnd(char[] lr_name, int winner, int loser)
{
	gB_LRActivated = false;
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