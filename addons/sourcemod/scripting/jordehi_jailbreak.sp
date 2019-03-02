#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <geoip>

#pragma newdecls required
#define REQUIRE_PLUGIN

// === Integers === //

// === Strings === //
char gS_VoteCT_Winner[32]; //Smart one shavit ;)

// === Booleans === //
bool gB_Late = false;

// === Floats === //

// === Handles === //
Handle gH_Forwards_OnVoteCTStart = null;
Handle gH_Forwards_OnVoteCTEnd = null;
Handle gH_Forwards_OnVoteCTChat = null;

public Plugin myinfo = 
{
	name = "[CS:GO/?] Jordehi - Jailbreak Management Core (BETA)", 
	author = "Keepomod.com & shavit", 
	description = "Jailbreak Management for CS:S/CS:GO Israeli Jailbreak servers.", 
	version = Jordehi_VERSION, 
	url = "http://keepomod.com/ & https://github.com/shavitush"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("jordehi_jailbreak");
	
	CreateNative("Jordehi_PrintToChat", Native_PrintToChat);
	CreateNative("Jordehi_FinishVoteCT", Native_FinishVoteCT);
	CreateNative("Jordehi_RegisterVoteCT", Native_RegisterVoteCT);
	CreateNative("Jordehi_UpdateVoteCTInfo", Native_UpdateVoteCTInfo);
	CreateNative("Jordehi_InVoteCT", Native_InVoteCT);
	CreateNative("Jordehi_GetVoteCTWinner", Native_GetVoteCTWinner);
	CreateNative("Jordehi_SetVoteCTWinner", Native_SetVoteCTWinner);
	CreateNative("Jordehi_SetVIP", Native_SetVIP);
	CreateNative("Jordehi_StopVoteCT", Native_StopVoteCT);

	gB_Late = late;
	
	return APLRes_Success;
}


public void OnPluginStart()
{
	// === Admin Commands === //
	
	// === Player Commands === //
	
	// === Events === //
	
	// === ConVars === //
	CreateConVar("jordehi_jailbreak_version", Jordehi_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// === Shit & uuh stuff === //
	
	if(gB_Late)
	{
		Jordehi_LoopClients(i)
		{
			OnClientPutInServer(i);
		}
	}
	
	AutoExecConfig(true, "sm_jordehi_jailbreak");
}


public void OnClientPutInServer(int client)
{
	if (Jordehi_IsClientValid(client))
	{
		
	}
}


public int Native_PrintToChat(Handle handler, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsClientInGame(client))
	{
		return;
	}
	
	static int iWritten = 0; // useless?
	
	char sBuffer[300];
	FormatNativeString(0, 2, 3, 300, iWritten, sBuffer);
	Format(sBuffer, 300, Jordehi_PREFIX..." %s", sBuffer);
	
	if (GetEngineVersion() != Engine_CSGO)
	{
		Handle hSayText2 = StartMessageOne("SayText2", client);
		
		if (hSayText2 != null)
		{
			BfWriteByte(hSayText2, 0);
			BfWriteByte(hSayText2, true);
			BfWriteString(hSayText2, sBuffer);
		}
		
		EndMessage();
	}
	
	else
	{
		PrintToChat(client, " %s", sBuffer);
	}
}
