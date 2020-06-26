#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "Hot Potato"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //
int gI_PotatoPlayer = 0;
int gI_Ammo = -1;
int gI_HotPotatoDeagle = -1;

// === Strings === //

// === Booleans === //
bool gB_LRActivated = false;
bool gB_HotPotatoMode = false; // false == teleport and freeze | true == teleport and run

// === Floats === //
float gI_HotPotatoMinTime = 10.0;
float gI_HotPotatoMaxTime = 30.0;

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
	
	gI_Ammo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	
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
	FormatEx(sTemp, 128, "Change Mode : (Current: %s)", gB_HotPotatoMode ? "Teleport & Run" : "Teleport & Freeze");
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
				gB_HotPotatoMode = !gB_HotPotatoMode;
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
	FormatEx(sTemp, 128, "- Current Mode : %s", gB_HotPotatoMode ? "Teleport & Run" : "Teleport & Freeze");
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

	if(!IsSafeTeleport(terrorist, 250.0))
	{
		//Even texts from javit Kappa
		Jordehi_PrintToChat(terrorist, "Your partner cannot teleport to this place!");
		Jordehi_PrintToChat(terrorist, "Please look at somewhere else.");
		Jordehi_StopLastRequest();
		return;
	}
	
	gI_PotatoPlayer = terrorist;
	
	gI_HotPotatoDeagle = GivePlayerItem(gI_PotatoPlayer, "weapon_deagle");
	SetWeaponAmmo(gI_PotatoPlayer, gI_HotPotatoDeagle, 0, 0);
	
	float fClientOrigin[3];
	GetClientAbsOrigin(gI_PotatoPlayer, fClientOrigin);

	float fEyeAngles[3];
	GetClientEyeAngles(gI_PotatoPlayer, fEyeAngles);

	float fAdd[3];
	GetAngleVectors(fEyeAngles, fAdd, NULL_VECTOR, NULL_VECTOR);

	fClientOrigin[0] += fAdd[0] * 125.0;
	fClientOrigin[1] += fAdd[1] * 125.0;

	fEyeAngles[1] += 180.0;

	if(fEyeAngles[1] > 180.0)
	{
		fEyeAngles[1] -= 360.0;
	}

	float fPartnerOrigin[3];
	GetClientAbsOrigin(ct, fPartnerOrigin);
	fClientOrigin[2] += 12.0;

	TeleportEntity(ct, fClientOrigin, fEyeAngles, view_as<float>({0.0, 0.0, 0.0}));
	
	float fRandom = GetRandomFloat(gI_HotPotatoMinTime, gI_HotPotatoMaxTime);
	
	if(gB_HotPotatoMode) // free run
	{
		SetEntPropFloat(gI_PotatoPlayer, Prop_Data, "m_flLaggedMovementValue", 2.0);
	}
	else //teleport & freeze
	{
		SetEntityMoveType(gI_PotatoPlayer, MOVETYPE_NONE);
		SetEntityMoveType(ct, MOVETYPE_NONE);
	}
	
	CreateTimer(fRandom, Timer_EndHotPotato);
}

public Action Timer_EndHotPotato(Handle timer)
{
	if(!gB_LRActivated)
	{
		return Plugin_Stop;
	}
	
	ForcePlayerSuicide(gI_PotatoPlayer);
	
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
	
	//I'm pretty sure this should work
	if(weapon == gI_HotPotatoDeagle)
	{
		gI_PotatoPlayer = client;
	}
	
	if(!StrEqual(sWeapon, "weapon_deagle") && weapon != gI_HotPotatoDeagle)
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
		damage = 0.0;
		return Plugin_Changed;
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
	gB_HotPotatoMode = false;
	gI_PotatoPlayer = 0;
	gI_HotPotatoDeagle = -1;
	
	Jordehi_LoopClients(i)
	{
		SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		SetEntityMoveType(i, MOVETYPE_WALK);
		SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}


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

bool IsSafeTeleport(int client, float distance)
{
	float fEyePos[3];
	float fEyeAngles[3];

	bool bLookingAtWall = false;

	GetClientEyePosition(client, fEyePos);
	GetClientEyeAngles(client, fEyeAngles);

	fEyeAngles[0] = 0.0;

	Handle trace = TR_TraceRayFilterEx(fEyePos, fEyeAngles, CONTENTS_SOLID, RayType_Infinite, bFilterNothing);

	if(TR_DidHit(trace))
	{
		float fEnd[3];
		TR_GetEndPosition(fEnd, trace);

		if(GetVectorDistance(fEyePos, fEnd) <= distance)
		{
			float fHullMin[3] = {-16.0, -16.0, 0.0};
			float fHullMax[3] = {16.0, 16.0, 90.0};

			Handle hullTrace = TR_TraceHullEx(fEyePos, fEnd, fHullMin, fHullMax, CONTENTS_SOLID);

			if(TR_DidHit(hullTrace))
			{
				TR_GetEndPosition(fEnd, hullTrace);

				if(GetVectorDistance(fEyePos, fEnd) <= distance)
				{
					bLookingAtWall = true;
				}
			}

			delete hullTrace;
		}
	}

	delete trace;

	return !bLookingAtWall;
}

public bool bFilterNothing(int entity, int mask)
{
	return (entity == 0);
}