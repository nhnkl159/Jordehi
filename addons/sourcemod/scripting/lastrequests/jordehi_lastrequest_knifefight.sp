#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "Knife Fight"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //
int gI_Choice = 1;

// === Strings === //

// === Booleans === //
bool gB_LRActivated = false;
bool gB_Backstab = false;

// === Floats === //
float g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

// === Handles === //
UserMsg g_FadeUserMsgId;

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
	
	g_FadeUserMsgId = GetUserMessageId("Fade");
	
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
	
	if(random)
	{
		InitiateLR(terrorist, GetRandomInt(1, 4));
		return;
	}
	
	OpenSettingsMenu(terrorist);
}


void OpenSettingsMenu(int client)
{
	char sTemp[128];
	switch(gI_Choice)
	{
		case 1:
		{
			FormatEx(sTemp, 128, "Current Mode : Normal Knife Fight");
		}
		case 2:
		{
			FormatEx(sTemp, 128, "Current Mode : Backstabs only");
		}
		case 3:
		{
			FormatEx(sTemp, 128, "Current Mode : The Flash");
		}
		case 4:
		{
			FormatEx(sTemp, 128, "Current Mode : Party Mode");
		}
	}
	
	
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
				InitiateLR(client, gI_Choice);
			}
			case 1:
			{
				Menu m = new Menu(KnifeModes_Handler);
				m.SetTitle("Choose knife mode : ");
				m.AddItem("1", "Normal Knife Fight");
				m.AddItem("2", "Backstabs only");
				m.AddItem("3", "The Flash");
				m.AddItem("4", "Party Mode");
				m.ExitButton = false;
				m.Display(client, 60);
			}
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

public int KnifeModes_Handler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(item, info, sizeof(info));
		
		gI_Choice = StringToInt(info);
		OpenSettingsMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void InitiateLR(int client, int choice)
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
	
	Jordehi_LoopClients(i)
	{
		if(IsPlayerAlive(i))
		{
			SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
			SDKHook(i, SDKHook_TraceAttack, OnTraceAttack);
		}
	}
	
	
	switch(choice)
	{
		case 1:
		{
			Jordehi_UpdateExtraInfo("- Current Mode : Normal Knife Fight");
		}
		case 2:
		{
			gB_Backstab = true;
			Jordehi_UpdateExtraInfo("- Current Mode : Backstabs only");
		}
		case 3:
		{
			SetEntPropFloat(terrorist, Prop_Data, "m_flLaggedMovementValue", 2.0);
			SetEntPropFloat(ct, Prop_Data, "m_flLaggedMovementValue", 2.0);
			Jordehi_UpdateExtraInfo("- Current Mode : The Flash");
		}
		case 4:
		{
			DrugPlayer(terrorist, true);
			DrugPlayer(ct, true);
			Jordehi_UpdateExtraInfo("- Current Mode : Party Mode");
		}
	}
	
	GivePlayerItem(terrorist, "weapon_knife");
	GivePlayerItem(ct, "weapon_knife");
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if (!gB_LRActivated || !Jordehi_IsClientInLastRequest(client))
	{
		return Plugin_Continue;
	}
	
	char[] sWeapon = new char[32];
	GetEntityClassname(weapon, sWeapon, 32);
	
	if(!StrEqual(sWeapon, "weapon_knife"))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(!gB_LRActivated)
	{
		return Plugin_Continue;
	}
	
	if(!Jordehi_IsClientValid(victim) || !Jordehi_IsClientValid(attacker))
	{
		return Plugin_Continue;
	}
	
	char sWeapon[32];
	GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
	
	if ((StrContains(sWeapon, "knife", false) != -1) || (StrContains(sWeapon, "bayonet", false) != -1))
	{
		if(gB_Backstab)
		{
			float fAAngle[3], fVAngle[3], fBAngle[3];
			
			GetClientAbsAngles(victim, fVAngle);
			GetClientAbsAngles(attacker, fAAngle);
			MakeVectorFromPoints(fVAngle, fAAngle, fBAngle);
			
			if(fBAngle[1] > -90.0 && fBAngle[1] < 90.0)
			{
				return Plugin_Continue;
			}
			else
			{
				return Plugin_Handled;
			}
		}
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
	gI_Choice = 1;
	
	if(gB_Backstab)
	{
		gB_Backstab = false;
	}
	
	Jordehi_LoopClients(i)
	{
		SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(i, SDKHook_TraceAttack, OnTraceAttack);
		SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
		DrugPlayer(i, false);
	}
}

void DrugPlayer(int target, bool toggle)
{
	if(toggle)
	{
		CreateTimer(1.0, PerformDrug_Timer, target, TIMER_REPEAT);
	}
	else
	{
		float angs[3];
		GetClientEyeAngles(target, angs);
		
		angs[2] = 0.0;
		
		TeleportEntity(target, NULL_VECTOR, angs, NULL_VECTOR);	
		
		int clients[2];
		clients[0] = target;
	
		int duration = 1536;
		int holdtime = 1536;
		int flags = (0x0001 | 0x0010);
		int color[4] = { 0, 0, 0, 0 };
	
		Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
		if (GetUserMessageType() == UM_Protobuf)
		{
			Protobuf pb = UserMessageToProtobuf(message);
			pb.SetInt("duration", duration);
			pb.SetInt("hold_time", holdtime);
			pb.SetInt("flags", flags);
			pb.SetColor("clr", color);
		}
		else
		{	
			BfWrite bf = UserMessageToBfWrite(message);
			bf.WriteShort(duration);
			bf.WriteShort(holdtime);
			bf.WriteShort(flags);
			bf.WriteByte(color[0]);
			bf.WriteByte(color[1]);
			bf.WriteByte(color[2]);
			bf.WriteByte(color[3]);
		}
		
		EndMessage();
	}
}


public Action PerformDrug_Timer(Handle timer, any client)
{
	if (!gB_LRActivated)
	{
		return Plugin_Stop;
	}
	
	if (!IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	float angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];
	
	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
	
	int clients[2];
	clients[0] = client;	
	
	int duration = 255;
	int holdtime = 255;
	int flags = 0x0002;
	int color[4] = { 0, 0, 0, 128 };
	color[0] = GetRandomInt(0,255);
	color[1] = GetRandomInt(0,255);
	color[2] = GetRandomInt(0,255);

	Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
	}
	
	EndMessage();
	
	return Plugin_Continue;
}