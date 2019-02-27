#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "Race"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //
int gI_BeamSprite = -1;
int gI_HaloSprite = -1;

// === Strings === //

// === Booleans === //
bool gB_LRActivated = false;

// === Floats === //
float fStartPoint[3];
float fEndPoint[3];

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
	
	OpenSettingsMenu(terrorist);
}

void OpenSettingsMenu(int client)
{
	char sTemp[128];
	float fposX = fStartPoint[0];
	float fposY = fStartPoint[1];
	float fposZ = fStartPoint[2];
	
	Menu m = new Menu(Settings_Handler);
	m.SetTitle("Settings Menu :");
	
	FormatEx(sTemp, 128, "Set Starting Location (%f %f %f)", fposX, fposY, fposZ);
	m.AddItem("1", sTemp);
	
	fposX = fEndPoint[0];
	fposY = fEndPoint[1];
	fposZ = fEndPoint[2];
	
	FormatEx(sTemp, 128, "Set Ending Location (%f %f %f)", fposX, fposY, fposZ);
	m.AddItem("2", sTemp);
	
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
				TeleportEntity(client, fStartPoint, NULL_VECTOR, view_as<float>( { 0.0, 0.0, 0.0 } ));
				TeleportEntity(Jordehi_GetClientOpponent(client), fStartPoint, NULL_VECTOR, view_as<float>( { 0.0, 0.0, 0.0 } ));
				
				Jordehi_UpdateExtraInfo("- The race begins !");
				InitiateLR(client);
			}
			case 1:
			{
				if (GetEntityFlags(client) & FL_ONGROUND)
				{
					GetClientAbsOrigin(client, fStartPoint);
					fStartPoint[2] += 10;
					
					TE_SetupBeamRingPoint(fStartPoint, 100.0, 130.0, gI_BeamSprite, gI_HaloSprite, 0, 15, 5.0, 7.0, 0.0, view_as<int>( { 255.0, 0.0, 0.0, 1.0 } ), 1, 0);
					TE_SendToAll();
					
					Jordehi_UpdateExtraInfo("- Terrorist has set the starting point.");
				}
				else
				{
					Jordehi_PrintToChat(client, "You must be on the ground to set a point.");
				}
			}
			case 2:
			{
				if (GetEntityFlags(client) & FL_ONGROUND)
				{
					GetClientAbsOrigin(client, fEndPoint);
					fEndPoint[2] += 10;
					
					TE_SetupBeamRingPoint(fEndPoint, 100.0, 130.0, gI_BeamSprite, gI_HaloSprite, 0, 15, 5.0, 7.0, 0.0, view_as<int>( { 0.0, 0.0, 255.0, 1.0 } ), 1, 0);
					TE_SendToAll();
				}
				else
				{
					Jordehi_PrintToChat(client, "You must be on the ground to set a point.");
				}
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
	SDKHook(terrorist, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(ct, SDKHook_OnTakeDamage, OnTakeDamage);
	
	CreateTimer(1.0, Race_Timer, client, TIMER_REPEAT);
}

public Action Race_Timer(Handle timer, any terrorist)
{
	if (!gB_LRActivated)
	{
		return Plugin_Stop;
	}
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	float fTerroristPosition[3], fCTPosition[3];
	GetClientAbsOrigin(terrorist, fTerroristPosition);
	GetClientAbsOrigin(ct, fCTPosition);
	
	float fTerroristDistance, fCTDistance;
	fTerroristDistance = GetVectorDistance(fTerroristPosition, fEndPoint, false);
	fCTDistance = GetVectorDistance(fCTPosition, fEndPoint, false);
	
	TE_SetupBeamRingPoint(fStartPoint, 100.0, 130.0, gI_BeamSprite, gI_HaloSprite, 0, 15, 1.0, 7.0, 0.0, view_as<int>( { 255.0, 0.0, 0.0, 1.0 } ), 1, 0);
	TE_SendToAll();
	
	TE_SetupBeamRingPoint(fEndPoint, 100.0, 130.0, gI_BeamSprite, gI_HaloSprite, 0, 15, 1.0, 7.0, 0.0, view_as<int>( { 0.0, 0.0, 255.0, 1.0 } ), 1, 0);
	TE_SendToAll();
	
	if (fTerroristDistance < 75.0 || fCTDistance < 75.0)
	{
		if (fTerroristDistance < fCTDistance)
		{
			ForcePlayerSuicide(ct);
		}
		else
		{
			ForcePlayerSuicide(terrorist);
		}
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
	
	if(Jordehi_IsClientValid(winner))
	{	
		SDKUnhook(winner, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(winner, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	
	if(Jordehi_IsClientValid(loser))
	{	
		SDKUnhook(loser, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(loser, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}