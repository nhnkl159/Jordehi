#pragma semicolon 1

//Everything is from javit cause this lastrequest made there fucking lit Kappa
//Tried to integrate javit features, havent test it yet lmao

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "DeagleToss"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //

int gI_Terrorist = 0;
int gI_CT = 0;

int gI_BeamSprite = -1;
int gI_HaloSprite = -1;

int gI_Ammo = -1;
int gI_DeagleTossFirst = 0;
int gI_Deagles[3];

// === Strings === //

// === Booleans === //
bool gB_LRActivated = false;

bool gB_DeagleTossMode = false;
bool gB_AllowEquip = true;
bool gB_Parachute = false;
bool gB_Bhop = false;
bool gB_DeaglePositionMeasured[2];
bool gB_DroppedDeagle[MAXPLAYERS+1];

// === Floats === //
float gF_DeaglePosition[2][3];
float gF_PreJumpPosition[MAXPLAYERS+1][3];


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

public void OnMapStart()
{
	gI_BeamSprite = PrecacheModel("sprites/laserbeam.vmt", true);
	gI_HaloSprite = PrecacheModel("sprites/glow01.vmt", true);
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
	}
	
	if(!Jordehi_IsClientValid(terrorist) && !Jordehi_IsClientValid(ct))
	{
		Jordehi_StopLastRequest();
		return;
	}
	
	if(gB_LRActivated)
	{
		OpenSettingsMenu(terrorist);
	}
}

public void Jordehi_OnLREnd(char[] lr_name, int winner, int loser)
{
	if(gB_LRActivated)
	{
		SDKUnhook(winner, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(loser, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(winner, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(loser, SDKHook_OnTakeDamage, OnTakeDamage);
		gB_LRActivated = false;
		gB_Parachute = false;
		gB_Bhop = false;
		gB_DeagleTossMode = false;
		gI_DeagleTossFirst = -1;
		gI_Deagles[winner] = -1;
		gI_Deagles[loser] = -1;
		gB_DeaglePositionMeasured[winner] = false;
		gB_DeaglePositionMeasured[loser] = false;
		gB_DroppedDeagle[winner] = false;
		gB_DroppedDeagle[loser] = false;
		gB_AllowEquip = true;
	}
}

void OpenSettingsMenu(int client)
{
	char sTemp[128];
	FormatEx(sTemp, 128, "DeagleToss Mode : %s", gB_DeagleTossMode ? "Closest toss (lowest distance)" : "Furthest toss (highest distance)");
	Menu m = new Menu(Settings_Handler);
	m.SetTitle("Settings Menu :");
	m.AddItem("1", sTemp);
	FormatEx(sTemp, 128, "Allow Parachute : %s", gB_Parachute ? "Yes" : "No");
	m.AddItem("2", sTemp);
	FormatEx(sTemp, 128, "Allow Bhop : %s", gB_Bhop ? "Yes" : "No");
	m.AddItem("3", sTemp);
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
				gB_DeagleTossMode = !gB_DeagleTossMode;
			}
			case 2:
			{
				gB_Parachute = !gB_Parachute;
			}
			case 3:
			{
				gB_Bhop = !gB_Bhop;
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

void InitiateLR(int client)
{
	if(!gB_LRActivated)
	{
		return;
	}
	
	char sTemp[128];
	FormatEx(sTemp, 128, "- DeagleToss Mode : %s \n- Allow Parachute : %s \n- Allow Bhop : %s", gB_DeagleTossMode ? "Closest toss (lowest distance)" : "Furthest toss (highest distance)", gB_Parachute ? "Yes" : "No", gB_Bhop ? "Yes" : "No");
	Jordehi_UpdateExtraInfo(sTemp);
	
	gI_Terrorist = client;
	gI_CT = Jordehi_GetClientOpponent(gI_Terrorist);
	

	//Terrorist
	gI_Deagles[gI_Terrorist] = GivePlayerItem(gI_Terrorist, "weapon_deagle");
	SetWeaponAmmo(gI_Terrorist, gI_Deagles[gI_Terrorist], 0, 0);
	EquipPlayerWeapon(gI_Terrorist, gI_Deagles[gI_Terrorist]);

	GetClientAbsOrigin(gI_Terrorist, gF_DeaglePosition[gI_Terrorist]);

	gB_DeaglePositionMeasured[gI_Terrorist] = false;
	gB_DroppedDeagle[gI_Terrorist] = false;
	
	//Counter Terrorist
	gI_Deagles[gI_CT] = GivePlayerItem(gI_CT, "weapon_deagle");
	SetWeaponAmmo(gI_CT, gI_Deagles[gI_CT], 0, 0);
	EquipPlayerWeapon(gI_CT, gI_Deagles[gI_CT]);

	GetClientAbsOrigin(gI_CT, gF_DeaglePosition[gI_CT]);

	gB_DeaglePositionMeasured[gI_CT] = false;
	gB_DroppedDeagle[gI_CT] = false;
	
	
	CreateTimer(0.5, Timer_DeagleToss, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	gB_AllowEquip = false;
}

public Action Timer_DeagleToss(Handle Timer)
{
	if(!gB_LRActivated)
	{
		return Plugin_Stop;
	}
	if(!IsValidEntity(gI_Deagles[gI_Terrorist]))
	{
		Jordehi_PrintToChatAll("Aborting Deagle Toss! \x03%N\x01's deagle couldn't be found.", gI_Terrorist);
		Jordehi_StopLastRequest();

		return Plugin_Stop;
	}
	if(!IsValidEntity(gI_Deagles[gI_CT]))
	{
		Jordehi_PrintToChatAll("Aborting Deagle Toss! \x03%N\x01's deagle couldn't be found.", gI_Terrorist);
		Jordehi_StopLastRequest();

		return Plugin_Stop;
	}
	
	//Terrorist
	if(GetEntPropEnt(gI_Deagles[gI_Terrorist], Prop_Data, "m_hOwner") == INVALID_ENT_REFERENCE)
	{
		float fTempPosition[3];
		GetEntPropVector(gI_Deagles[gI_Terrorist], Prop_Send, "m_vecOrigin", fTempPosition);

		if(GetVectorDistance(fTempPosition, gF_DeaglePosition[gI_Terrorist]) < 10.0)
		{
			gB_DeaglePositionMeasured[gI_Terrorist] = true;
		}

		gF_DeaglePosition[gI_Terrorist][0] = fTempPosition[0];
		gF_DeaglePosition[gI_Terrorist][1] = fTempPosition[1];
		gF_DeaglePosition[gI_Terrorist][2] = fTempPosition[2];

		if(gB_DeaglePositionMeasured[gI_Terrorist])
		{
			int color[4] = {0, 0, 0, 255};
			color[0] = 255;

			TE_SetupBeamPoints(gF_DeaglePosition[gI_Terrorist], (gI_DeagleTossFirst == -1)? gF_PreJumpPosition[gI_Terrorist]:gF_PreJumpPosition[gI_DeagleTossFirst], gI_BeamSprite, gI_HaloSprite, 0, 0, 10.0, 7.5, 5.0, 0, 0.0, color, 0);
			TE_SendToAll(0.0);

			TE_SetupEnergySplash(gF_DeaglePosition[gI_Terrorist], NULL_VECTOR, false);
			TE_SendToAll(0.0);

			if(gI_DeagleTossFirst == -1)
			{
				gI_DeagleTossFirst = gI_Terrorist;
			}
		}
	}

	//Counter Terrorist
	if(GetEntPropEnt(gI_Deagles[gI_CT], Prop_Data, "m_hOwner") == INVALID_ENT_REFERENCE)
	{
		float fTempPosition[3];
		GetEntPropVector(gI_Deagles[gI_CT], Prop_Send, "m_vecOrigin", fTempPosition);

		if(GetVectorDistance(fTempPosition, gF_DeaglePosition[gI_CT]) < 10.0)
		{
			gB_DeaglePositionMeasured[gI_CT] = true;
		}

		gF_DeaglePosition[gI_CT][0] = fTempPosition[0];
		gF_DeaglePosition[gI_CT][1] = fTempPosition[1];
		gF_DeaglePosition[gI_CT][2] = fTempPosition[2];

		if(gB_DeaglePositionMeasured[gI_CT])
		{
			int color[4] = {0, 0, 0, 255};
			color[0] = 255;

			TE_SetupBeamPoints(gF_DeaglePosition[gI_CT], (gI_DeagleTossFirst == -1)? gF_PreJumpPosition[gI_CT]:gF_PreJumpPosition[gI_DeagleTossFirst], gI_BeamSprite, gI_HaloSprite, 0, 0, 10.0, 7.5, 5.0, 0, 0.0, color, 0);
			TE_SendToAll(0.0);

			TE_SetupEnergySplash(gF_DeaglePosition[gI_CT], NULL_VECTOR, false);
			TE_SendToAll(0.0);

			if(gI_DeagleTossFirst == -1)
			{
				gI_DeagleTossFirst = gI_CT;
			}
		}
	}

	if(gB_DeaglePositionMeasured[gI_Terrorist] && gB_DeaglePositionMeasured[gI_CT])
	{
		if(GetVectorDistance(gF_DeaglePosition[gI_Terrorist], gF_DeaglePosition[gI_CT]) >= 1500.00)
		{
			Jordehi_PrintToChatAll("The deagles are too far away. Aborting LR.");
			Jordehi_StopLastRequest();
		}

		else
		{
			CreateTimer(3.0, Timer_KillTheLoser, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
			
			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

public Action Timer_KillTheLoser(Handle Timer, any data)
{
	if(!gB_LRActivated)
	{
		return Plugin_Stop;
	}

	float[] fDistances = new float[2];
	fDistances[gI_Terrorist] = GetVectorDistance(gF_DeaglePosition[gI_Terrorist], gF_PreJumpPosition[gI_DeagleTossFirst]);
	fDistances[gI_CT] = GetVectorDistance(gF_DeaglePosition[gI_CT], gF_PreJumpPosition[gI_DeagleTossFirst]);

	Jordehi_PrintToChatAll("\x04[\x03%N\x04] - \x05%d", gI_Terrorist, RoundToNearest(fDistances[gI_Terrorist]));
	Jordehi_PrintToChatAll("\x04[\x03%N\x04] - \x05%d", gI_CT, RoundToNearest(fDistances[gI_CT]));

	int iWinner = 0;

	if(!gB_DeagleTossMode) // furthest
	{
		iWinner = (fDistances[gI_Terrorist] > fDistances[gI_CT]) ? gI_Terrorist:gI_CT;
	}
	else
	{
		iWinner = (fDistances[gI_Terrorist] < fDistances[gI_CT]) ? gI_Terrorist:gI_CT;
	}

	Jordehi_PrintToChatAll("Winner: \x03%N\x01.", iWinner);

	int iPartner = Jordehi_GetClientOpponent(iWinner);

	gB_AllowEquip = true;
	
	SetEntityHealth(iWinner, 125);
	SetEntityHealth(iPartner, 1);
	
	Jordehi_StripAllWeapons(iWinner);
	Jordehi_StripAllWeapons(iPartner);

	GivePlayerItem(iWinner, "weapon_knife");
	GivePlayerItem(iWinner, "weapon_knife");

	int iPistol = GivePlayerItem(iWinner, "weapon_deagle");
	SetWeaponAmmo(iWinner, iPistol, 255, 0);

	int iPrimary = GivePlayerItem(iWinner, "weapon_ak47");
	SetWeaponAmmo(iWinner, iPrimary, 255, 0);

	return Plugin_Stop;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!Jordehi_IsClientValid(attacker))
	{
		return Plugin_Continue;
	}
	
	if(gB_LRActivated && !gB_AllowEquip)
	{
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
	
	if(!gB_AllowEquip && gB_DroppedDeagle[client])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	if(gB_LRActivated)
	{
		if(gB_DroppedDeagle[client])
		{
			Jordehi_PrintToChat(client, "You have already tossed this deagle.");

			return Plugin_Handled;
		}

		gB_DroppedDeagle[client] = true;
	}

	return Plugin_Continue;
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