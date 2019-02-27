#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "Hit & Run"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //
int iInfectedPlayer = 0;
int gI_Ammo = -1;
int gI_NextSecondaryAttack = -1;

// === Strings === //

// === Booleans === //
bool gB_LRActivated = false;

// === Floats === //
float fFloatTime;

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
		int iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		SetWeaponAmmo(client, iWeapon, -1, 1000);
	}
}

public void Jordehi_OnLREnd(char[] lr_name, int winner, int loser)
{
	if(!gB_LRActivated)
	{
		return;
	}
	
	gB_LRActivated = false;
	iInfectedPlayer = 0;
	
	if(Jordehi_IsClientValid(winner))
	{
		SDKUnhook(winner, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(winner, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(winner, SDKHook_PreThink, PreThink);
	}
	if(Jordehi_IsClientValid(loser))
	{
		SDKUnhook(loser, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(loser, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(loser, SDKHook_PreThink, PreThink);
	}
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
	
	int terrorist = client;
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	SDKHook(terrorist, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(ct, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(terrorist, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(ct, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(terrorist, SDKHook_PreThink, PreThink);
	SDKHook(ct, SDKHook_PreThink, PreThink);

	fFloatTime = GetEngineTime();
	CreateTimer(0.1, Timer_Countdown, client, TIMER_REPEAT);
	
	char sTemp[128];
	FormatEx(sTemp, 128, "- Selecting infected player...");
	Jordehi_UpdateExtraInfo(sTemp);
}


public Action Timer_Countdown(Handle timer, any terrorist)
{
	if (!gB_LRActivated)
	{
		return Plugin_Stop;
	}
	
	if ((GetEngineTime() - fFloatTime) > 5.0)
	{
		GivePlayerItem(terrorist, "weapon_ssg08");
		GivePlayerItem(Jordehi_GetClientOpponent(terrorist), "weapon_ssg08");
	
		int iRand = GetRandomInt(1, 2);
		iInfectedPlayer = iRand == 1 ? terrorist : Jordehi_GetClientOpponent(terrorist);
		SetEntityRenderMode(iInfectedPlayer, RENDER_TRANSALPHA);
		SetEntityRenderColor(iInfectedPlayer, GetRandomInt(1, 255), GetRandomInt(1, 255), GetRandomInt(1, 255));
		
		char sTemp[128];
		FormatEx(sTemp, 128, "- Infected Player : %N", iInfectedPlayer);
		Jordehi_UpdateExtraInfo(sTemp);
		
		fFloatTime = GetEngineTime();
		
		Jordehi_PrintToChat(iInfectedPlayer, "Try to \x07Hit\x01 your opponent to transfer the \x07Infection.");
		
		CreateTimer(0.1, Timer_FinishHNR, _, TIMER_REPEAT);
		
		return Plugin_Stop;
	}
	else
	{
		char sHintText[1000];
		Format(sHintText, sizeof(sHintText), "Selecting infected in: %.02f", (fFloatTime + 5.0) - GetEngineTime());
		PrintHintTextToAll(sHintText);
	}
	
	return Plugin_Continue;
}

public Action Timer_FinishHNR(Handle timer)
{
	if (!gB_LRActivated)
	{
		return Plugin_Stop;
	}
	
	if ((GetEngineTime() - fFloatTime) > 30.0)
	{
		Jordehi_PrintToChatAll("Player \x05%N\x01 lost because he didn't spread the \x07Infection!", iInfectedPlayer);
		ForcePlayerSuicide(iInfectedPlayer);
		return Plugin_Stop;
	}
	else
	{
		char sHintText[1000];
		Format(sHintText, sizeof(sHintText), "Time left: %.02f \nInfected: %N", (fFloatTime + 30.0) - GetEngineTime(), iInfectedPlayer);
		PrintHintTextToAll(sHintText);
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
		if(attacker == iInfectedPlayer)
		{
			SetEntityRenderMode(attacker, RENDER_NORMAL);
			SetEntityRenderColor(attacker);
			
			iInfectedPlayer = victim;
			
			SetEntityRenderMode(victim, RENDER_TRANSALPHA);
			SetEntityRenderColor(victim, GetRandomInt(1, 255), GetRandomInt(1, 255), GetRandomInt(1, 255));
			
			Jordehi_PrintToChatAll("\x07!!!  H I T  !!!");
			Jordehi_PrintToChatAll("Player \x05%N\x01 hit \x0B%N\x1 and he is now the \x07Infected !", attacker, victim);
		}

		damage = 0.0;
		return Plugin_Changed;
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


public Action OnWeaponCanUse(int client, int weapon)
{
	if (!gB_LRActivated || !Jordehi_IsClientInLastRequest(client))
	{
		return Plugin_Continue;
	}
	
	char[] sWeapon = new char[32];
	GetEntityClassname(weapon, sWeapon, 32);
	
	if(!StrEqual(sWeapon, "weapon_ssg08"))
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
		InitiateLR(terrorist);
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