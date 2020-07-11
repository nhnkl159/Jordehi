#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define VOTECT_NAME "Template"
#define VOTECT_TIME 10.0
#define PLUGIN_NAME "Jordehi - VoteCT - " ... VOTECT_NAME

// === Integers === //

// === Strings === //

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
	
	//Start Here
	InitiateVoteCT();
}

void InitiateVoteCT()
{
	if(!gB_VoteCTActivated)
	{
		return;
	}
	
	if(!Jordehi_InVoteCT())
	{
		Jordehi_StopVoteCT(0);
		return;
	}
	
	/*char sTemp[128];
	FormatEx(sTemp, 128, "- Something enabled : %s", gB_Something ? "Yes" : "No");
	Jordehi_UpdateExtraInfo(sTemp);*/
}

public void Jordehi_OnVoteCTTimesUP(char[] votect_name)
{
	if(!gB_VoteCTActivated)
	{
		return;
	}
	
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