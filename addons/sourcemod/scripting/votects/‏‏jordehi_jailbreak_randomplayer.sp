#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <jordehi_lastrequests>

#pragma newdecls required

#define VOTECT_NAME "Random Player"
#define VOTECT_TIME 10.0
#define PLUGIN_NAME "Jordehi - VoteCT - " ... VOTECT_NAME

// === Integers === //

// === Strings === //

// === Booleans === //
bool gB_VoteCTActivated = false;

// === Floats === //

// === Handles === //
ArrayList gA_RandomPlayer = null;

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
	
	gA_RandomPlayer = new ArrayList();
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
	
	gA_RandomPlayer.Clear();
	
	Menu menu = new Menu(WouldLike);
	menu.SetTitle("Would you like to be a Counter-Terrorist?");
	menu.AddItem("1", "Yes");
	menu.AddItem("0", "No");
	menu.ExitButton = false;
	Jordehi_LoopClients(i)
	{
		menu.Display(i, 8);
	}
	
	/*char sTemp[128];
	FormatEx(sTemp, 128, "- Something enabled : %s", gB_Something ? "Yes" : "No");
	Jordehi_UpdateExtraInfo(sTemp);*/
}

public int WouldLike(Menu m, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		m.GetItem(item, info, 32);
		
		int iChoice = StringToInt(info);
		
		if(iChoice)
		{
			gA_RandomPlayer.Push(client);
			Jordehi_PrintToChat(client, "You choosed to become \x0BCT!");
		}
		else
		{
			Jordehi_PrintToChat(client, "You choosed to not play as a \x0BCT!");
		}
	}
	if (action == MenuAction_End)
	{
		return;
	}
}

public void Jordehi_OnVoteCTTimesUP(char[] votect_name)
{
	if(!gB_VoteCTActivated)
	{
		return;
	}
	
	if(gA_RandomPlayer.Length == 0)
	{
		Jordehi_StopVoteCT(0);
		Jordehi_PrintToChatAll("Time is up and no entries were submitted.");
	}
	else
	{
		int iRandomClientNum = GetRandomInt(0, gA_RandomPlayer.Length - 1);
		int client = gA_RandomPlayer.Get(iRandomClientNum);
		Jordehi_SetVoteCTWinner(client, true);
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