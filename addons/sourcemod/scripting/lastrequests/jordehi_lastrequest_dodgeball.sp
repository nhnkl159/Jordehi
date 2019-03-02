#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "Dodgeball"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //

// === Strings === //

// === Booleans === //
bool gB_LRActivated = false;
bool gB_Gravity = false;

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
	
	if(!Jordehi_IsClientValid(terrorist) || !Jordehi_IsClientValid(ct))
	{
		Jordehi_StopLastRequest();
		return;
	}
	
	if(!gB_LRActivated)
	{
		return;
	}
	
	OpenSettingsMenu(terrorist);
}

void OpenSettingsMenu(int client)
{
	char sTemp[128];
	FormatEx(sTemp, 128, "Enable Gravity : %s", gB_Gravity ? "Yes" : "No");
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
				InitiateLR(client);
			}
			case 1:
			{
				gB_Gravity = !gB_Gravity;
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
	
	char sTemp[128];
	FormatEx(sTemp, 128, "- Gravity enabled : %s", gB_Gravity ? "Yes" : "No");
	Jordehi_UpdateExtraInfo(sTemp);
	
	int terrorist = client;
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	SDKHook(terrorist, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(ct, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(terrorist, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(ct, SDKHook_WeaponCanUse, OnWeaponCanUse);
	
	SetEntityHealth(terrorist, 1);
	SetEntityHealth(ct, 1);

	GivePlayerItem(terrorist, "weapon_flashbang");
	GivePlayerItem(ct, "weapon_flashbang");
	
	if(gB_Gravity)
	{
		SetEntityGravity(terrorist, 0.5);
		SetEntityGravity(ct, 0.5);
	}

	SetEntProp(terrorist, Prop_Data, "m_CollisionGroup", 5);
	SetEntProp(ct, Prop_Data, "m_CollisionGroup", 5);
	
	CreateTimer(0.5, Cheating_Timer, terrorist, TIMER_REPEAT);
	CreateTimer(0.5, Cheating_Timer, ct, TIMER_REPEAT);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(gB_LRActivated && StrEqual(classname, "flashbang_projectile"))
	{
		CreateTimer(1.5, Timer_KillFlashbang, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_KillFlashbang(Handle Timer, any entity)
{
	if(IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE)
	{
		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		
		AcceptEntityInput(entity, "Kill");
		
		Jordehi_StripAllWeapons(client);
		
		CreateTimer(0.25, Timer_AutoSwitch, client);
	}

}

public Action Timer_AutoSwitch(Handle Timer, any client)
{
	if(!Jordehi_IsClientValid(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	GivePlayerItem(client, "weapon_flashbang");
	FakeClientCommand(client, "use weapon_flashbang");

	return Plugin_Stop;
}

public Action Cheating_Timer(Handle Timer, any client)
{
	if (!gB_LRActivated)
	{
		return Plugin_Stop;
	}
	
	if (!IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	if(GetClientHealth(client) > 1)
	{
		SetEntityHealth(client, 1);
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
	
		if(!StrEqual(sWeapon, "weapon_flashbang"))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if (!gB_LRActivated || !Jordehi_IsClientInLastRequest(client))
	{
		return Plugin_Continue;
	}
	
	char[] sWeapon = new char[32];
	GetEntityClassname(weapon, sWeapon, 32);
	
	if(!StrEqual(sWeapon, "weapon_flashbang"))
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
	gB_Gravity = false;
	
	Jordehi_LoopClients(i)
	{
		SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
		SetEntityGravity(i, 1.0);
	}
}