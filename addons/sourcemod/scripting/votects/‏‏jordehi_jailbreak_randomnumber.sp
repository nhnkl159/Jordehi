#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define VOTECT_NAME "Random Number"
#define VOTECT_TIME 15.0
#define PLUGIN_NAME "Jordehi - VoteCT - " ... VOTECT_NAME

// === Integers === //

// === Strings === //
char gS_RandomString[64];

// === Booleans === //
bool gB_VoteCTActivated = false;

// === Floats === //

// === Handles === //
ArrayList gA_RandomNumber = null;

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
	
	gA_RandomNumber = new ArrayList(2);
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
	
	if(Jordehi_InVoteCT())
	{
		Jordehi_StopVoteCT(0);
		return;
	}
	
	gA_RandomNumber.Clear();
	IntToString(GetRandomInt(1, 350), gS_RandomString, 64);
	
	char sTemp[128];
	FormatEx(sTemp, 128, "- Submit a number from 1 to 350.");
	Jordehi_UpdateExtraInfo(sTemp);
}


public void Jordehi_OnVoteCTTimesUP(char[] votect_name)
{
	if(!gB_VoteCTActivated)
	{
		return;
	}
	
	if(gA_RandomNumber.Length == 0)
	{
		Jordehi_StopVoteCT(0);
		Jordehi_PrintToChatAll("Time is up and no entries were submitted.");
	}
	else
	{
		DrawRandomNumberWinner();
	}
}

void DrawRandomNumberWinner()
{
	int iDistance = 350;
	int iWinner = 0;
	int iWinnerNumber = 0;
	int iAnswer = StringToInt(gS_RandomString);

	int iLength = gA_RandomNumber.Length;

	for(int i = 0; i < iLength; i++)
	{
		int arr[2];
		gA_RandomNumber.GetArray(i, arr, 2);

		int client = GetClientFromSerial(arr[0]);

		if(client == 0)
		{
			continue;
		}

		int iRealDist = Abs(iAnswer - arr[1]);

		if(iRealDist < iDistance)
		{
			iDistance = iRealDist;
			iWinner = client;
			iWinnerNumber = arr[1];
		}
	}

	if(iWinner > 0)
	{
		Jordehi_PrintToChatAll("\x03%N\x01 won with the number \x05%d\x01. The random number was \x05%d\x01.", iWinner, iWinnerNumber, iAnswer);
		Jordehi_SetVoteCTWinner(iWinner, true);
	}

	else
	{
		Jordehi_StopVoteCT(0);
		Jordehi_PrintToChatAll("Winner is not present in the server.");
	}
}

any Abs(any num)
{
	return (num < 0)? -num:num;
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
	
	int iSerial = GetClientSerial(client);
	int iNumber = gA_RandomNumber.FindValue(iSerial);

	if(iNumber != -1)
	{
		Jordehi_PrintToChat(client, "You have already submitted a number. You have submitted the number \x05%d\x01.", gA_RandomNumber.Get(iNumber, 1));

		return;
	}

	iNumber = StringToInt(message);

	if(!(1 <= iNumber <= 350))
	{
		Jordehi_PrintToChat(client, "Your number has to be between \x051\x01 and \x05350\x01.");

		return;
	}

	int arr[2];
	arr[0] = iSerial;
	arr[1] = iNumber;

	gA_RandomNumber.PushArray(arr);

	Jordehi_PrintToChat(client, "You have submitted the number \x05%d\x01.", iNumber);

	return;
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