#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "DeagleToss"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //
int gI_Deagles[MAXPLAYERS + 1];
int gI_CurrentThrower = 0;

int gI_BeamSprite = -1;
int gI_HaloSprite = -1;
int gI_Ammo = -1;

// === Strings === //

// === Booleans === //
bool gB_LRActivated = false;

bool gB_DeagleTossMode = false;
bool gB_AllowParachute = false;
bool gB_AllowBhop = false;
bool gB_Equip = true;
bool gB_PlayerDrop[MAXPLAYERS + 1];
bool gB_DeaglePositionMeasured[MAXPLAYERS + 1];

// === Floats === //
float gF_DeaglePos[MAXPLAYERS + 1][3];
float gF_PreJumpPosition[MAXPLAYERS + 1][3];

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
	gI_Ammo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	
	Jordehi_RegisterLR(LR_NAME, "");
	
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
	
	OpenSettingsMenu(terrorist);
}


void OpenSettingsMenu(int client)
{
	char sTemp[128];
	FormatEx(sTemp, 128, "DeagleToss Mode : %s", gB_DeagleTossMode ? "Closest toss (lowest distance)" : "Furthest toss (highest distance)");
	Menu m = new Menu(Settings_Handler);
	m.SetTitle("Settings Menu :");
	m.AddItem("1", sTemp);
	FormatEx(sTemp, 128, "Allow Parachute : %s", gB_AllowParachute ? "Yes" : "No");
	m.AddItem("2", sTemp);
	FormatEx(sTemp, 128, "Allow Bhop : %s", gB_AllowBhop ? "Yes" : "No");
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
				gB_AllowParachute = !gB_AllowParachute;
			}
			case 3:
			{
				gB_AllowBhop = !gB_AllowBhop;
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
	
	int terrorist = client;
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	SDKHook(terrorist, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(ct, SDKHook_WeaponCanUse, OnWeaponCanUse);
	
	int iRand = GetRandomInt(1, 2);
	gI_CurrentThrower = iRand == 1 ? terrorist : Jordehi_GetClientOpponent(terrorist);
	
	Jordehi_PrintToChat(client, "\x07%N\x01 was picked randomly to toss first.", gI_CurrentThrower);
	
	char sTemp[328];
	FormatEx(sTemp, 328, "- DeagleToss Mode : %s \n- Allow Parachute : %s \n- Allow Bhop : %s \n- Current Thrower : %N", gB_DeagleTossMode ? "Closest toss (lowest distance)" : "Furthest toss (highest distance)", gB_AllowParachute ? "Yes" : "No", gB_AllowBhop ? "Yes" : "No", gI_CurrentThrower);
	Jordehi_UpdateExtraInfo(sTemp);
	
	gI_Deagles[terrorist] = GivePlayerItem(terrorist, "weapon_deagle");
	SetWeaponAmmo(terrorist, gI_Deagles[terrorist], 0, 0);
	GetClientAbsOrigin(terrorist, gF_DeaglePos[terrorist]);
	
	gI_Deagles[ct] = GivePlayerItem(ct, "weapon_deagle");
	SetWeaponAmmo(ct, gI_Deagles[ct], 0, 0);
	GetClientAbsOrigin(ct, gF_DeaglePos[ct]);
	
	gB_Equip = false;
	
	CreateTimer(1.0, Timer_DeagleToss, terrorist, TIMER_REPEAT);
}

//Thanks shavit Kappa
public Action Timer_DeagleToss(Handle timer, any terrorist)
{
	if (!gB_LRActivated)
	{
		return Plugin_Stop;
	}
	
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	if(!IsValidEntity(gI_Deagles[terrorist]))
	{
		Jordehi_PrintToChatAll("Aborting Deagle Toss! \x07%N\x01's deagle couldn't be found.", terrorist);
		Jordehi_StopLastRequest();

		return Plugin_Stop;
	}
	
	if(!IsValidEntity(gI_Deagles[ct]))
	{
		Jordehi_PrintToChatAll("Aborting Deagle Toss! \x07%N\x01's deagle couldn't be found.", ct);
		Jordehi_StopLastRequest();

		return Plugin_Stop;
	}

	if(GetEntPropEnt(gI_Deagles[terrorist], Prop_Data, "m_hOwner") == INVALID_ENT_REFERENCE && gB_DeaglePositionMeasured[terrorist] == false)
	{
		float fTempPosition[3];
		GetEntPropVector(gI_Deagles[terrorist], Prop_Send, "m_vecOrigin", fTempPosition);

		if(GetVectorDistance(fTempPosition, gF_DeaglePos[terrorist]) < 10.0)
		{
			gB_DeaglePositionMeasured[terrorist] = true;
		}

		gF_DeaglePos[terrorist][0] = fTempPosition[0];
		gF_DeaglePos[terrorist][1] = fTempPosition[1];
		gF_DeaglePos[terrorist][2] = fTempPosition[2];

		if(gB_DeaglePositionMeasured[terrorist])
		{
			int color[4] = {0, 0, 0, 255};
			color[0] = 255;

			TE_SetupBeamPoints(gF_DeaglePos[terrorist], gF_PreJumpPosition[terrorist], gI_BeamSprite, gI_HaloSprite, 0, 0, 10.0, 7.5, 5.0, 0, 0.0, color, 0);
			TE_SendToAll(0.0);

			TE_SetupEnergySplash(gF_DeaglePos[terrorist], NULL_VECTOR, false);
			TE_SendToAll(0.0);
		}
	}
	
	if(GetEntPropEnt(gI_Deagles[ct], Prop_Data, "m_hOwner") == INVALID_ENT_REFERENCE && gB_DeaglePositionMeasured[ct] == false)
	{
		float fTempPosition[3];
		GetEntPropVector(gI_Deagles[ct], Prop_Send, "m_vecOrigin", fTempPosition);

		if(GetVectorDistance(fTempPosition, gF_DeaglePos[ct]) < 10.0)
		{
			gB_DeaglePositionMeasured[ct] = true;
		}

		gF_DeaglePos[ct][0] = fTempPosition[0];
		gF_DeaglePos[ct][1] = fTempPosition[1];
		gF_DeaglePos[ct][2] = fTempPosition[2];

		if(gB_DeaglePositionMeasured[ct])
		{
			int color[4] = {0, 0, 0, 255};
			color[2] = 255;

			TE_SetupBeamPoints(gF_DeaglePos[ct], gF_PreJumpPosition[ct], gI_BeamSprite, gI_HaloSprite, 0, 0, 10.0, 7.5, 5.0, 0, 0.0, color, 0);
			TE_SendToAll(0.0);

			TE_SetupEnergySplash(gF_DeaglePos[ct], NULL_VECTOR, false);
			TE_SendToAll(0.0);
		}
	}
	
	if(gB_DeaglePositionMeasured[terrorist] && gB_DeaglePositionMeasured[ct])
	{
		if(GetVectorDistance(gF_DeaglePos[terrorist], gF_DeaglePos[ct]) >= 1500.00)
		{
			Jordehi_PrintToChatAll("The deagles are too far away. Aborting LR.");
			Jordehi_StopLastRequest();
		}

		else
		{
			CreateTimer(3.0, Timer_KillTheLoser, terrorist, TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_KillTheLoser(Handle Timer, any terrorist)
{
	if(!gB_LRActivated)
	{
		return Plugin_Stop;
	}
	
	int ct = Jordehi_GetClientOpponent(terrorist);

	float[] fDistances = new float[2];
	
	fDistances[terrorist] = GetVectorDistance(gF_DeaglePos[terrorist], gF_PreJumpPosition[terrorist]);
	fDistances[ct] = GetVectorDistance(gF_DeaglePos[ct], gF_PreJumpPosition[ct]);

	Jordehi_PrintToChatAll("\x04[\x03%N\x04] - \x05%d", terrorist, RoundToNearest(fDistances[terrorist]));
	Jordehi_PrintToChatAll("\x04[\x03%N\x04] - \x05%d", ct, RoundToNearest(fDistances[ct]));

	int iWinner = 0;

	if(gB_DeagleTossMode == false) // furthest
	{
		iWinner = fDistances[terrorist] > fDistances[ct]? terrorist:ct;
	}

	else
	{
		iWinner = fDistances[terrorist] < fDistances[ct]? terrorist:ct;
	}

	Jordehi_PrintToChatAll("Winner: \x03%N\x01.", iWinner);

	int iPartner = Jordehi_GetClientOpponent(iWinner);

	gB_Equip = true;

	SetEntityHealth(iWinner, 125);
	SetEntityHealth(iPartner, 1);
	
	Jordehi_StripAllWeapons(iWinner);
	Jordehi_StripAllWeapons(iPartner);

	GivePlayerItem(iWinner, "weapon_knife");

	int iPistol = GivePlayerItem(iWinner, "weapon_deagle");
	SetWeaponAmmo(iWinner, iPistol, 255, 0);

	int iPrimary = GivePlayerItem(iWinner, "weapon_ak47");
	SetWeaponAmmo(iWinner, iPrimary, 255, 0);

	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(!gB_LRActivated)
	{
		return Plugin_Continue;
	}

	if(GetEntityFlags(client) & FL_ONGROUND && !gB_PlayerDrop[client])
	{
		GetClientAbsOrigin(client, gF_PreJumpPosition[client]);
	}

	return Plugin_Continue;
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if (!gB_LRActivated || !Jordehi_IsClientInLastRequest(client))
	{
		return Plugin_Continue;
	}
	
	if(!gB_Equip)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	if(!gB_LRActivated)
	{
		return Plugin_Continue;
	}
	
	if(gB_PlayerDrop[client])
	{
		Jordehi_PrintToChat(client, "You already dropped your deagle.");
		return Plugin_Handled;
	}
	
	if(Jordehi_IsClientInLastRequest(client) && !gB_PlayerDrop[client] && gI_CurrentThrower && (weapon == gI_Deagles[gI_CurrentThrower]))
	{
		gB_PlayerDrop[client] = true;
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
	gI_CurrentThrower = 0;
	gB_DeagleTossMode = false;
	gB_AllowParachute = false;
	gB_AllowBhop = false;
	gB_Equip = true;
	
	Jordehi_LoopClients(i)
	{
		SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
		
		gI_Deagles[i] = -1;
		gB_PlayerDrop[i] = false;
		gF_DeaglePos[i] = view_as<float>({0.0,0.0,0.0});
		gB_DeaglePositionMeasured[i] = false;
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