#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "Survive the rain"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //

// === Strings === //

// === Booleans === //
bool gB_LRActivated = false;
bool gB_SurviveMode = false; // false == Hard | true == Easy

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
	
	OpenSettingsMenu(terrorist);
}

void OpenSettingsMenu(int client)
{
	char sTemp[128];
	FormatEx(sTemp, 128, "Change Mode : (Current: %s)", gB_SurviveMode ? "Easy" : "Hard");
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
				gB_SurviveMode = !gB_SurviveMode;
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
	FormatEx(sTemp, 128, "- Current Mode : (%s)", gB_SurviveMode ? "Easy" : "Hard");
	Jordehi_UpdateExtraInfo(sTemp);
	
	int terrorist = client;
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	SDKHook(terrorist, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(ct, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(terrorist, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(ct, SDKHook_OnTakeDamage, OnTakeDamage);
	
	CreateTimer(gB_SurviveMode == true ? 1.5 : 0.5, Timer_Molly, client, TIMER_REPEAT);
}

public Action Timer_Molly(Handle timer, any terrorist)
{
	if (!gB_LRActivated)
	{
		return Plugin_Stop;
	}
	
	float fPos[3];
	
	int iMolly = CreateEntityByName("molotov_projectile");
	if (iMolly == -1)
		return Plugin_Continue;

	float fRadX = GetRandomFloat(0.0, 200.0), fRadY = GetRandomFloat(0.0, 200.0);
	if (GetRandomInt(0, 1) > 0)
		fRadX = -fRadX;
	if (GetRandomInt(0, 1) > 0)
		fRadY = -fRadY;
	
	int iRand = GetRandomInt(1, 2);
	GetEntPropVector(iRand == 1 ? terrorist : Jordehi_GetClientOpponent(terrorist), Prop_Data, "m_vecOrigin", fPos);
	
	fPos[0] += fRadX;
	fPos[1] += fRadY;
	fPos[2] += 100.0;
	
	DispatchSpawn(iMolly);
	TeleportEntity(iMolly, fPos, NULL_VECTOR, NULL_VECTOR);
	SetEntityGravity(iMolly, 100.0 / 100.0);
	SDKHook(iMolly, SDKHook_Touch, StartTouch);
	SDKHook(iMolly, SDKHook_OnTakeDamage, TakeTouch);
	return Plugin_Continue;
}

public Action StartTouch(int molly, int other)
{
	SetEntProp(molly, Prop_Data, "m_takedamage", 2);
	SetEntProp(molly, Prop_Data, "m_iHealth", 1);
	SDKHooks_TakeDamage(molly, molly, 1, 1.0, DMG_BURN, -1, NULL_VECTOR, NULL_VECTOR);
}

public Action TakeTouch(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(Jordehi_IsClientValid(attacker))
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
		if(damagetype == DMG_BURN)
		{
			float fRand = GetRandomFloat(1.0, 3.0);
			IgniteEntity(victim, fRand);
		}
		damage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}


public Action OnWeaponCanUse(int client, int weapon)
{
	if (!gB_LRActivated || !Jordehi_IsClientInLastRequest(client))
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
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
	gB_SurviveMode = false;
	
	Jordehi_LoopClients(i)
	{
		SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}