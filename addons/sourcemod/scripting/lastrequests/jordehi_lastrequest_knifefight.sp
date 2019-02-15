#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "Knife Fight"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //

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
	
	if(gB_LRActivated)
	{
		if(random)
		{
			StartKnifeFight(terrorist, GetRandomInt(1, 4));
			return;
		}
		
		Menu menu = new Menu(KnifeModes_Handler);
		menu.SetTitle("Choose knife mode : ");
		menu.AddItem("1", "Normal Knife Fight");
		menu.AddItem("2", "Backstabs only");
		menu.AddItem("3", "The Flash");
		menu.AddItem("4", "Party Mode");
		menu.ExitButton = false;
		menu.Display(terrorist, 60);
	}
}

public int KnifeModes_Handler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(item, info, sizeof(info));
		
		int iChoice = StringToInt(info);

		StartKnifeFight(client, iChoice);
		
	}
	else if (action == MenuAction_End)
	{
		Jordehi_StopLastRequest();
		delete menu;
	}
}

void StartKnifeFight(int client, int choice)
{
	int terrorist = client;
	int ct = Jordehi_GetClientOpponent(terrorist);
	
	switch(choice)
	{
		case 1:
		{
			Jordehi_UpdateExtraInfo("- Current Mode : Normal Knife Fight");
		}
		case 2:
		{
			gB_Backstab = true;
			SDKHook(terrorist, SDKHook_TraceAttack, OnTraceAttack);
			SDKHook(ct, SDKHook_TraceAttack, OnTraceAttack);
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

public void Jordehi_OnLREnd(char[] lr_name, int winner, int loser)
{
	gB_LRActivated = false;
	if(gB_Backstab)
	{
		SDKUnhook(winner, SDKHook_TraceAttack, OnTraceAttack);
		SDKUnhook(loser, SDKHook_TraceAttack, OnTraceAttack);
		gB_Backstab = false;
	}
	if(Jordehi_IsClientValid(winner))
	{
		SetEntPropFloat(winner, Prop_Data, "m_flLaggedMovementValue", 1.0);
		DrugPlayer(winner, false);
	}
	if(Jordehi_IsClientValid(loser))
	{
		SetEntPropFloat(loser, Prop_Data, "m_flLaggedMovementValue", 1.0);
		DrugPlayer(loser, false);
	}
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
	
	return Plugin_Handled;
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