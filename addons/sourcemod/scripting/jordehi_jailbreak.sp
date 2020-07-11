#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jordehi_jailbreak>
#include <geoip>
//#include <ctbans>

#pragma newdecls required
#define REQUIRE_PLUGIN

// === Integers === //
int gI_BeamSprite = -1;
int gI_HaloSprite = -1;
int gI_VoteCT_Winner;

// === Strings === //
char gS_VoteCT_Winner[32]; //Smart one shavit ;)

// === Booleans === //
bool gB_Late = false;
bool gB_VoteCTStarted = false;
bool gB_PostVoteCT = false;

// === Floats === //
float gF_VoteEnd;

// === Handles === //
ArrayList gA_VoteCTTypes = null;
votect_t current_votect_type;

Handle gH_Forwards_OnVoteCTStart = null;
Handle gH_Forwards_OnVoteCTEnd = null;
Handle gH_Forwards_OnVoteCTTimesUP = null;
Handle gH_Forwards_OnVoteCTChat = null;

// === ConVars === //
ConVar gC_StartDay;

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
	CreateNative("Jordehi_RegisterVoteCT", Native_RegisterVoteCT);
	CreateNative("Jordehi_InVoteCT", Native_InVoteCT);
	CreateNative("Jordehi_UpdateVoteCTInfo", Native_UpdateVoteCTInfo);
	CreateNative("Jordehi_SetVoteCTWinner", Native_SetVoteCTWinner);
	CreateNative("Jordehi_SetVIP", Native_SetVIP);
	CreateNative("Jordehi_StopVoteCT", Native_StopVoteCT);
	
	gB_Late = late;
	
	return APLRes_Success;
}


public void OnPluginStart()
{
	// === Admin Commands === //
	RegAdminCmd("sm_votect", Command_VoteCT, ADMFLAG_BAN, "Initiates a manual CT vote.");
	
	
	
	AddCommandListener(Command_CancelVoteCT, "sm_cancelvote");
	
	// === Player Commands === //
	
	// === Events === //
	HookEvent("round_start", OnRoundStart);
	
	// === ConVars === //
	CreateConVar("jordehi_jailbreak_version", Jordehi_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	gC_StartDay = CreateConVar("jordehi_jailbreak_dayround", "7", "The day number to start days mode, should be sunday obv.");
	
	// === Shit & uuh stuff === //
	if (gA_VoteCTTypes != null)
	{
		gA_VoteCTTypes.Clear();
	}
	
	gA_VoteCTTypes = new ArrayList(sizeof(votect_t));
	
	
	gH_Forwards_OnVoteCTStart = CreateGlobalForward("Jordehi_OnVoteCTStart", ET_Event, Param_String);
	gH_Forwards_OnVoteCTEnd = CreateGlobalForward("Jordehi_OnVoteCTEnd", ET_Event, Param_String, Param_Cell);
	gH_Forwards_OnVoteCTTimesUP = CreateGlobalForward("Jordehi_OnVoteCTTimesUP", ET_Event, Param_String);
	gH_Forwards_OnVoteCTChat = CreateGlobalForward("Jordehi_OnVoteCTChat", ET_Event, Param_Cell, Param_String);
	
	if (gB_Late)
	{
		Jordehi_LoopClients(i)
		{
			OnClientPutInServer(i);
		}
	}
	
	AutoExecConfig(true, "sm_jordehi_jailbreak");
}

public void OnMapStart()
{
	gI_BeamSprite = PrecacheModel("sprites/laserbeam.vmt", true);
	gI_HaloSprite = PrecacheModel("sprites/glow01.vmt", true);
}


public void OnClientPutInServer(int client)
{
	if (Jordehi_IsClientValid(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!Jordehi_IsClientValid(attacker))
	{
		return Plugin_Continue;
	}
	
	if (gB_VoteCTStarted)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

//Liked the idea shavit ;)
public void OnGameFrame()
{
	int iTicks = GetGameTickCount();
	
	if (iTicks % 10 == 0)
	{
		Cron();
	}
	
	/*if(iTicks % 100 == 0)
	{
		BeaconVIPs();
	}*/
}

void Cron()
{
	Jordehi_LoopClients(i)
	{
		PrintVoteCTHUD(i);
	}
}

void PrintVoteCTHUD(int client)
{
	if (gB_PostVoteCT)
	{
		float fTimeLeft = current_votect_type.type_time - (GetEngineTime() - gF_VoteEnd);
		
		if (fTimeLeft <= 0.0)
		{
			//loop
			Call_StartForward(gH_Forwards_OnVoteCTTimesUP);
			Call_PushString(current_votect_type.type_name);
			Call_Finish();
			
			if (gI_VoteCT_Winner != -1)
			{
				Jordehi_StopVoteCT(gI_VoteCT_Winner);
				
				char sTemp[128];
				
				Panel panel = new Panel();
				panel.SetTitle("[Jordehi] Choosed VoteCT type :", false);
				panel.DrawText("================");
				FormatEx(sTemp, 128, " - Type : %s", current_votect_type.type_name);
				panel.DrawText(sTemp);
				FormatEx(sTemp, 128, " - Winner : %N !", gI_VoteCT_Winner);
				panel.DrawText(sTemp);
				panel.DrawText("================");
				FormatEx(sTemp, 128, "%s", current_votect_type.type_extrainfo);
				panel.DrawText(sTemp);
				panel.CurrentKey = 9;
				panel.DrawItem("Exit", ITEMDRAW_CONTROL);
				
				SendPanelToClient(panel, client, Panel_Handler, MENU_TIME_FOREVER);
			}
			else
			{
				char sTemp[128];
				
				Panel panel = new Panel();
				panel.SetTitle("[Jordehi] Choosed VoteCT type :", false);
				panel.DrawText("================");
				FormatEx(sTemp, 128, " - Type : %s", current_votect_type.type_name);
				panel.DrawText(sTemp);
				panel.DrawText("================");
				FormatEx(sTemp, 128, "%s", current_votect_type.type_extrainfo);
				panel.DrawText(sTemp);
				panel.CurrentKey = 9;
				panel.DrawItem("Exit", ITEMDRAW_CONTROL);
				
				SendPanelToClient(panel, client, Panel_Handler, MENU_TIME_FOREVER);
			}
			return;
		}
		else
		{
			if (GetClientMenu(client) == MenuSource_None)
			{
				char sTemp[128];
				
				Panel panel = new Panel();
				panel.SetTitle("[Jordehi] Choosed VoteCT type :", false);
				panel.DrawText("================");
				FormatEx(sTemp, 128, " - Type : %s", current_votect_type.type_name);
				panel.DrawText(sTemp);
				FormatEx(sTemp, 128, " - [ %.01f ] seconds left!", fTimeLeft);
				panel.DrawText(sTemp);
				panel.DrawText("================");
				FormatEx(sTemp, 128, "%s", current_votect_type.type_extrainfo);
				panel.DrawText(sTemp);
				panel.CurrentKey = 9;
				panel.DrawItem("Exit", ITEMDRAW_CONTROL);
				
				SendPanelToClient(panel, client, Panel_Handler, MENU_TIME_FOREVER);
			}
		}
	}
}

public int Panel_Handler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		delete menu;
	}
	else if (action == MenuAction_End)
	{
		if (menu != null)
		{
			delete menu;
		}
	}
	return 0;
}

/*void BeaconVIPs()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!gB_VIP[i] || !IsClientInGame(i) || GetClientTeam(i) != CS_TEAM_T || !IsPlayerAlive(i))
		{
			continue;
		}

		Javit_BeaconEntity(i);
	}
}*/

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (!gB_PostVoteCT)
	{
		return Plugin_Continue;
	}
	
	/*if(CTBans_IsCTBanned(client))
	{
		Jordehi_PrintToChat(client, "You cannot write during votes as you're CT banned.");

		return Plugin_Handled;
	}*/
	
	char sAuthID[32];
	
	if (!GetClientAuthId(client, AuthId_SteamID64, sAuthID, 32)) //why you love AuthId_Steam3 so much lol, use 64 so much easier to fucking understand
	{
		Jordehi_PrintToChat(client, "Could not authenticate your SteamID. Reconnect and try again.");
		
		return Plugin_Handled;
	}
	
	if (StrEqual(sAuthID, gS_VoteCT_Winner))
	{
		Jordehi_PrintToChat(client, "You have won the previous votect, so you cannot participate in this one.");
		
		return Plugin_Handled;
	}
	
	Call_StartForward(gH_Forwards_OnVoteCTChat);
	Call_PushCell(client);
	Call_PushString(sArgs);
	Call_Finish();
	
	return Plugin_Continue;
}


public void OnRoundStart(Event e, const char[] name, bool dB)
{
	int iCurrentRound = GetTeamScore(2) + GetTeamScore(3) + 1;
	
	if (iCurrentRound >= gC_StartDay.IntValue)
	{
		//Jordehi_StopVoteCT(0);
		//StartVoteCT();
	}
}

public Action Command_VoteCT(int client, int args)
{
	if (Jordehi_IsClientValid(client))
	{
		Jordehi_PrintToChatAll("\x07%N\x01 has started the votect manually.", client);
	}
	
	StartVoteCT();
	
	return Plugin_Handled;
}

void StartVoteCT()
{
	if (IsVoteInProgress())
	{
		return;
	}
	
	if (Jordehi_InVoteCT())
	{
		return;
	}
	
	gI_VoteCT_Winner = -1;
	
	gB_VoteCTStarted = true;
	
	Menu menu = new Menu(VoteCT_Handler);
	menu.SetTitle("Choose VoteCT type:");
	
	int iLength = gA_VoteCTTypes.Length;

	for (int i = 0; i < iLength; i++)
	{
		votect_t type;
		gA_VoteCTTypes.GetArray(i, type);
		
		char sInfo[8];
		IntToString(type.type_id, sInfo, 8);
		
		menu.AddItem(sInfo, type.type_name);
	}
	
	if (menu.ItemCount == 0)
	{
		Jordehi_PrintToChatAll("[Jordehi VoteCT] No VoteCT types were found while trying to start the votect.");
		return;
	}
	
	
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
}

public int VoteCT_Handler(Menu m, MenuAction a, int vote_choice, int item)
{
	if (a == MenuAction_VoteEnd)
	{
		int iInfo = vote_choice+1;
		GetVoteCTByID(iInfo, current_votect_type);
		
		//EmitSoundToAll("jordehi/lastrequest/jordehi_lr_start.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
		
		Call_StartForward(gH_Forwards_OnVoteCTStart);
		Call_PushString(current_votect_type.type_name);
		Call_Finish();
		
		gB_PostVoteCT = true;
		
		gF_VoteEnd = GetEngineTime();
	}
	else if (a == MenuAction_VoteCancel)
	{
		Jordehi_StopVoteCT(0);
	}
	
	else if (a == MenuAction_End)
	{
		delete m;
	}
}


public Action Command_CancelVoteCT(int client, char[] command, int args)
{
	if (!Jordehi_IsClientValid(client))
	{
		return Plugin_Continue;
	}
	if (!CheckCommandAccess(client, "", ADMFLAG_BAN))
	{
		Jordehi_PrintToChat(client, "\x07You are not allowed to use this command!");
		return Plugin_Handled;
	}
	
	gB_VoteCTStarted = false;
	Jordehi_StopVoteCT(0);
	
	Jordehi_PrintToChatAll("\x07%N\x01 has canceled the \x0BVoteCT!", client);
	
	return Plugin_Handled;
}

//Stolen from shavit Kappa
bool GetVoteCTByID(int type_id, votect_t type)
{
	int iLength = gA_VoteCTTypes.Length;
	
	for (int i = 0; i < iLength; i++)
	{
		votect_t temptype;
		gA_VoteCTTypes.GetArray(i, temptype);
		
		if (temptype.type_id == type_id)
		{
			type = temptype;
			
			return true;
		}
	}
	
	return false;
}

bool IsVoteCTNameExist(char[] sName)
{
	int iLength = gA_VoteCTTypes.Length;
	
	for (int i = 0; i < iLength; i++)
	{
		votect_t temptype;
		gA_VoteCTTypes.GetArray(i, temptype);
		
		if (StrEqual(sName, temptype.type_name))
		{
			return true;
		}
	}
	
	return false;
}

public int Native_RegisterVoteCT(Handle plugin, int numParams)
{
	char sName[Jordehi_MAX_NAME_LENGTH];
	char sExtraInfo[Jordehi_MAX_EXTRAINFO_LENGTH];
	float fTypeTime = 1.0;
	
	GetNativeString(1, sName, sizeof(sName));
	GetNativeString(2, sExtraInfo, sizeof(sExtraInfo));
	fTypeTime = GetNativeCell(3);
	
	int iID = gA_VoteCTTypes.Length + 1;
	
	if (!IsVoteCTNameExist(sName))
	{
		votect_t type;
		type.type_id = iID;
		type.type_time = fTypeTime;
		FormatEx(type.type_name, sizeof(type.type_name), sName);
		FormatEx(type.type_extrainfo, sizeof(type.type_extrainfo), sExtraInfo);
		
		gA_VoteCTTypes.PushArray(type);
		
		LogMessage("[Jordehi VoteCT] ID: %d - Name: %s", iID, sName);
		return true;
	}
	
	return false;
}


public int Native_InVoteCT(Handle plugin, int numParams)
{
	if (gB_VoteCTStarted)
	{
		return true;
	}
	return false;
}


public int Native_SetVoteCTWinner(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool hud = GetNativeCell(2);
	
	if (Jordehi_IsClientValid(client))
	{
		gI_VoteCT_Winner = client;
		
		char sSteamID[32];
		GetClientAuthId(client, AuthId_SteamID64, sSteamID, 32);
		strcopy(gS_VoteCT_Winner, 32, sSteamID);
		
		if (hud)
		{
			Jordehi_StopVoteCT(gI_VoteCT_Winner);
			
			char sTemp[128];
			
			Panel panel = new Panel();
			panel.SetTitle("[Jordehi] Choosed VoteCT type :", false);
			panel.DrawText("================");
			FormatEx(sTemp, 128, " - Type : %s", current_votect_type.type_name);
			panel.DrawText(sTemp);
			FormatEx(sTemp, 128, " - Winner : %N !", gI_VoteCT_Winner);
			panel.DrawText(sTemp);
			panel.DrawText("================");
			FormatEx(sTemp, 128, "%s", current_votect_type.type_extrainfo);
			panel.DrawText(sTemp);
			panel.CurrentKey = 9;
			panel.DrawItem("Exit", ITEMDRAW_CONTROL);
			
			SendPanelToClient(panel, client, Panel_Handler, MENU_TIME_FOREVER);
		}
	}
	
	return false;
}

public int Native_SetVIP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (Jordehi_IsClientValid(client))
	{
		//Set VIP
	}
	
	return false;
}

public int Native_StopVoteCT(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (Jordehi_IsClientValid(client))
	{
		Call_StartForward(gH_Forwards_OnVoteCTEnd);
		Call_PushString(current_votect_type.type_name);
		Call_PushCell(client);
		Call_Finish();
	}
	else
	{
		Call_StartForward(gH_Forwards_OnVoteCTEnd);
		Call_PushString(current_votect_type.type_name);
		Call_PushCell(0);
		Call_Finish();
	}
	
	if (gB_VoteCTStarted)
	{
		gB_VoteCTStarted = false;
		gB_PostVoteCT = false;
		
		if (Jordehi_IsClientValid(client))
		{
			Jordehi_PrintToChatAll("VoteCT Type : \x07%s\x01 | Winner : \x07%N\x01", current_votect_type.type_name, client);
			
			EmitSoundToAll("ui/achievement_earned.wav");
			
			Jordehi_LoopClients(i)
			{
				if (i == client || GetClientTeam(i) != CS_TEAM_CT)
				{
					continue;
				}
				
				CS_SwitchTeam(i, CS_TEAM_T);
				CS_RespawnPlayer(i);
			}
			
			CS_SwitchTeam(client, CS_TEAM_CT);
			CS_RespawnPlayer(client);
		}
	}
}

public int Native_UpdateVoteCTInfo(Handle plugin, int numParams)
{
	char sExtraInfo[Jordehi_MAX_EXTRAINFO_LENGTH];
	
	GetNativeString(1, sExtraInfo, sizeof(sExtraInfo));
	
	FormatEx(current_votect_type.type_extrainfo, sizeof(current_votect_type.type_extrainfo), sExtraInfo);
	
	char sTemp[328];
	
	
	Panel panel = new Panel();
	panel.SetTitle("[Jordehi] Choosed VoteCT type :", false);
	panel.DrawText("================");
	FormatEx(sTemp, 128, " - Type : %s", current_votect_type.type_name);
	panel.DrawText(sTemp);
	panel.DrawText("================");
	FormatEx(sTemp, 128, "%s", current_votect_type.type_extrainfo);
	panel.DrawText(sTemp);
	panel.CurrentKey = 9;
	panel.DrawItem("Exit", ITEMDRAW_CONTROL);
	
	Jordehi_LoopClients(i)
	{
		SendPanelToClient(panel, i, LastrequestPanel_Handler, MENU_TIME_FOREVER);
	}
	
	return true;
}

public int LastrequestPanel_Handler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		delete menu;
	}
	else if (action == MenuAction_End)
	{
		if (menu != null)
		{
			delete menu;
		}
	}
	return 0;
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
