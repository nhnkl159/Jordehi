#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>
#include <smlib>

#pragma newdecls required

#define VOTECT_NAME "Fast Write"
#define VOTECT_TIME 5.0
#define PLUGIN_NAME "Jordehi - VoteCT - " ... VOTECT_NAME

// === Integers === //

// === Strings === //
char gS_RandomString[64];

// === Booleans === //
bool gB_VoteCTActivated = false;

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
	Jordehi_RegisterVoteCT(VOTECT_NAME, "", VOTECT_TIME);
	
	gB_VoteCTActivated = false;
}

public void Jordehi_OnVoteCTStart(char[] votect_name)
{
	if(StrEqual(votect_name, VOTECT_NAME))
	{
		gB_VoteCTActivated = true;
	}
	
	if(!gB_VoteCTActivated)
	{
		return;
	}
	
	PrintToChatAll("1");
	
	//Start Here
	InitiateVoteCT();
}

void InitiateVoteCT()
{
	if(!gB_VoteCTActivated)
	{
		return;
	}
	
	PrintToChatAll("2");
	
	if(Jordehi_InVoteCT())
	{
		Jordehi_StopVoteCT(0);
		return;
	}
	
	PrintToChatAll("3");
	
	IntToString(GetRandomInt(10000000, 99999999), gS_RandomString, 64);
	
	char sTemp[128];
	FormatEx(sTemp, 128, "- The Combination is: %s", gS_RandomString);
	Jordehi_UpdateExtraInfo(sTemp);
	
	PrintToChatAll("4");
}

public void Jordehi_OnVoteCTChat(int client, char[] message)
{
	if(!Jordehi_IsClientValid(client))
	{
		return;
	}
	
	if(!gB_VoteCTActivated)
	{
		return;
	}
	
	if(StrEqual(message, gS_RandomString))
	{
		Jordehi_SetVoteCTWinner(client, true);
	}
}

public void Jordehi_OnVoteCTEnd(char[] votect_name, int winner)
{
	if(!gB_VoteCTActivated)
	{
		return;
	}
	
	gB_VoteCTActivated = false;
	
	//Reset vars
}