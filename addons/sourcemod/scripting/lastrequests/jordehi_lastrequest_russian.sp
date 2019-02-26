#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "Russian Roulette"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //
int gI_PlayerTurn = -1;
int gI_Ammo = -1;

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
	
	if(gB_LRActivated && Jordehi_IsClientInLastRequest(client) && gI_PlayerTurn == client)
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
		SDKHook(terrorist, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKHook(ct, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKHook(terrorist, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(ct, SDKHook_OnTakeDamage, OnTakeDamage);
		Jordehi_UpdateExtraInfo("- Nothing here");
		InitiateLR(terrorist);
	}
	
	if(!Jordehi_IsClientValid(terrorist) && !Jordehi_IsClientValid(ct))
	{
		Jordehi_StopLastRequest();
		return;
	}
}

public void Jordehi_OnLREnd(char[] lr_name, int winner, int loser)
{
	if(gB_LRActivated)
	{
		SDKUnhook(winner, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(loser, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(loser, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(winner, SDKHook_OnTakeDamage, OnTakeDamage);
		gB_LRActivated = false;
		SetEntityMoveType(winner, MOVETYPE_WALK);
		SetEntityMoveType(loser, MOVETYPE_WALK);
	}
}

void InitiateLR(int client)
{
	if(!gB_LRActivated)
	{
		return;
	}
	
	int terrorist = client;
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	if(!IsSafeTeleport(terrorist, 250.0))
	{
		//Even texts from javit Kappa
		Jordehi_PrintToChat(terrorist, "Your partner cannot teleport to this place!");
		Jordehi_PrintToChat(terrorist, "Please look at somewhere else.");
		Jordehi_StopLastRequest();
		return;
	}
	
	GivePlayerItem(terrorist, "weapon_deagle");
	GivePlayerItem(ct, "weapon_deagle");
	
	SetEntityMoveType(terrorist, MOVETYPE_NONE);
	SetEntityMoveType(ct, MOVETYPE_NONE);
	
	int iRand = GetRandomInt(1, 2);
	gI_PlayerTurn = iRand == 1 ? terrorist : ct;
	
	int iWeapon = GetPlayerWeaponSlot(gI_PlayerTurn, CS_SLOT_SECONDARY);
	
	SetWeaponAmmo(gI_PlayerTurn, iWeapon, 1, 0);

	float fClientOrigin[3];
	GetClientAbsOrigin(terrorist, fClientOrigin);

	float fEyeAngles[3];
	GetClientEyeAngles(terrorist, fEyeAngles);

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
	
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!Jordehi_IsClientValid(attacker))
	{
		return Plugin_Continue;
	}
	
	if(gB_LRActivated)
	{
		int iWeapon = GetPlayerWeaponSlot(attacker, CS_SLOT_SECONDARY);

		int iRandom = GetRandomInt(1, 8);

		switch(iRandom)
		{
			case 1:
			{
				SDKHooks_TakeDamage(victim, attacker, attacker, GetClientHealth(victim) * 1.0, CS_DMG_HEADSHOT, iWeapon);
			}

			case 2:
			{
				SDKHooks_TakeDamage(attacker, attacker, victim, GetClientHealth(attacker) * 1.0, CS_DMG_HEADSHOT, iWeapon);
			}

			default:
			{
				damage = 0.0;
				return Plugin_Changed;
			}
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
	
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, 32);
	
	if(!StrEqual(sWeapon, "weapon_deagle"))
	{
		return Plugin_Handled;
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