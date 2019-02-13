#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <jordehi_lastrequests>
#include <geoip>

#pragma newdecls required
#define REQUIRE_PLUGIN

// === Integers === //
int gI_BeamSprite = -1;
int gI_HaloSprite = -1;
int gI_LROpponent[MAXPLAYERS + 1];
int gI_LRWinner = 0;

// === Strings === //

// === Booleans === //
bool gB_LRAvailable = false;
bool gB_LRStarted = false;
bool gB_InLR[MAXPLAYERS + 1]; //Probably switch to defines idk


// === Handles === //
ArrayList gA_Games = null;
lastrequest_game_t current_lastrequest; //idk if it belongs here lol

Handle gH_Forwards_OnLRAvailable = null;
Handle gH_Forwards_OnLRStart = null;
Handle gH_Forwards_OnLREnd = null;

//TODO:
// Sounds 
// Create cheating system.

public Plugin myinfo = 
{
	name = "[CS:GO/?] Jordehi - Lastrequests Core (BETA)", 
	author = "Keepomod.com & shavit", 
	description = "Lastrequests handler for CS:S/CS:GO Israeli Jailbreak servers.", 
	version = Jordehi_VERSION, 
	url = "http://keepomod.com/ & https://github.com/shavitush"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("jordehi_lastrquests");
	
	CreateNative("Jordehi_PrintToChat", Native_PrintToChat);
	CreateNative("Jordehi_RegisterLR", Native_RegisterLR);
	CreateNative("Jordehi_IsClientInLastRequest", Native_IsClientInLastRequest);
	CreateNative("Jordehi_GetClientOpponent", Native_GetClientOpponent);
	CreateNative("Jordehi_StopLastRequest", Native_StopLastRequest);
	
	return APLRes_Success;
}


public void OnPluginStart()
{
	// === Shit & uuh stuff === //
	if (gA_Games != null)
	{
		gA_Games.Clear();
	}
	
	gA_Games = new ArrayList(sizeof(lastrequest_game_t));
	
	gH_Forwards_OnLRAvailable = CreateGlobalForward("Jordehi_OnLRAvailable", ET_Event);
	gH_Forwards_OnLRStart = CreateGlobalForward("Jordehi_OnLRStart", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	gH_Forwards_OnLREnd = CreateGlobalForward("Jordehi_OnLREnd", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	
	//cause fuck bitbuffer usermessages https://i.imgur.com/NBFonQq.png
	if (GetUserMessageType() == UM_Protobuf)
	{
		HookUserMessage(GetUserMessageId("RadioText"), BlockRadio, true);
	}
	
	// === Admin Commands === //
	RegAdminCmd("sm_stoplr", Command_AbortLR, ADMFLAG_BAN, "Aborts the current active LR.");
	RegAdminCmd("sm_abortlr", Command_AbortLR, ADMFLAG_BAN, "Aborts the current active LR.");
	
	// === Player Commands === //
	RegConsoleCmd("sm_lr", Command_LastRequest, "Opens the available lastrequests menu.");
	RegConsoleCmd("sm_lastrequest", Command_LastRequest, "Opens the available lastrequests menu.");
	
	// === Events === //
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart);
	
	// === ConVars === //
	
	AutoExecConfig();
}

public Action BlockRadio(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
	return Plugin_Handled;
}

public void OnMapStart()
{
	gI_BeamSprite = PrecacheModel("sprites/laserbeam.vmt", true);
	gI_HaloSprite = PrecacheModel("sprites/glow01.vmt", true);
	
	CreateTimer(0.50, LRBeacon_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPostAdminCheck(int client)
{
	if (Jordehi_IsClientValid(client))
	{
		char sAuthid[64], sIP[16], sCountry[64];
		GetClientAuthId(client, AuthId_Steam2, sAuthid, sizeof(sAuthid));
		
		GetClientIP(client, sIP, sizeof(sIP), true);
		
		if (!GeoipCountry(sIP, sCountry, sizeof sCountry))FormatEx(sCountry, sizeof(sCountry), "Unknown Country");
		
		Jordehi_PrintToChat(client, "\x04+\x01 \x07%N\01 [\x07%s\x01] connected from \x07%s\x01.", client, sAuthid, sCountry);
	}
}

public void OnClientDisconnect(int client)
{
	if (Jordehi_IsClientValid(client))
	{
		if(Jordehi_IsClientInLastRequest(client) && gB_LRStarted)
		{
			Jordehi_StopLastRequest();
		}
		
		char sAuthid[64];
		GetClientAuthId(client, AuthId_Steam2, sAuthid, sizeof(sAuthid));
		
		Jordehi_PrintToChat(client, "\x02-\x01 \x07%N\01 [\x07%s\x01] disconnected.", client, sAuthid);
	}
}

public void OnRoundStart(Event e, const char[] name, bool dB)
{
	//in case wanna using freeday or some shit.
	CreateTimer(1.5, StopLastrequest_Timer);
}

public Action StopLastrequest_Timer(Handle Timer)
{
	Jordehi_StopLastRequest();
}

public void OnPlayerSpawn(Event e, const char[] name, bool dB)
{
	int client = GetClientOfUserId(e.GetInt("userid"));
	
	Jordehi_StripAllWeapons(client);
	
	GivePlayerItem(client, "weapon_knife");

	if(GetClientTeam(client) == 3)
	{
		GivePlayerItem(client, "weapon_deagle");

		int iWeapon = GivePlayerItem(client, "weapon_m4a1_silencer");
		EquipPlayerWeapon(client, iWeapon);
	}
}

public void OnPlayerDeath(Event e, const char[] name, bool dB)
{
	int victim = GetClientOfUserId(e.GetInt("userid"));
	
	if(gB_LRStarted && Jordehi_IsClientInLastRequest(victim))
	{
		gI_LRWinner = Jordehi_GetClientOpponent(victim); //Player might suicide or force to be.
		Jordehi_StopLastRequest();
	}
	
	if (GetTeamPlayers(2, true) == 1 && GetTeamPlayers(3, true) >= 1 && !gB_LRStarted && !gB_LRAvailable)
	{
		gB_LRAvailable = true;
		
		Call_StartForward(gH_Forwards_OnLRAvailable);
		Call_Finish();
		
		//TODO: sounds
	}
}

public Action Command_AbortLR(int client, int args)
{
	if (!Jordehi_IsClientValid(client))
	{
		return Plugin_Handled;
	}
	
	Jordehi_StopLastRequest();
	
	return Plugin_Handled;
}

public Action Command_LastRequest(int client, int args)
{
	if (!Jordehi_IsClientValid(client))
	{
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) != CS_TEAM_T)
	{
		Jordehi_PrintToChat(client, "In order to use this command, you must be the last terrorist alive.");
		return Plugin_Handled;
	}
	
	if (GetTeamPlayers(2, true) > 1)
	{
		Jordehi_PrintToChat(client, "In order to use this command, you must be the last terrorist alive.");
		return Plugin_Handled;
	}
	
	if (GetTeamPlayers(3, true) <= 0)
	{
		Jordehi_PrintToChat(client, "In order to use this command, there are must be an alive counter terrorist.");
		return Plugin_Handled;
	}
	
	if (gB_LRStarted)
	{
		Jordehi_PrintToChat(client, "In order to use this command, there are must be no active lastrequest.");
		return Plugin_Handled;
	}
	
	if (gB_InLR[client])
	{
		Jordehi_PrintToChat(client, "In order to use this command, there are must be no active lastrequest.");
		return Plugin_Handled;
	}
	
	if (!gB_LRAvailable)
	{
		Jordehi_PrintToChat(client, "Lastrequest in not available at the moment.");
		return Plugin_Handled;
	}
	
	ShowAvailableLastRequestsMenu(client);
	
	return Plugin_Handled;
}

void ShowAvailableLastRequestsMenu(int client)
{
	Menu menu = new Menu(Menu_LastRequest);
	menu.SetTitle("Choose a last request:");
	
	int iLength = gA_Games.Length;
	
	for (int i = 0; i < iLength; i++)
	{
		lastrequest_game_t game;
		gA_Games.GetArray(i, game);
		
		char sInfo[8];
		IntToString(game.lr_id, sInfo, 8);
		
		menu.AddItem(sInfo, game.lr_name);
	}
	
	if (menu.ItemCount == 0)
	{
		menu.AddItem("-1", "No games found.");
	}
	
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_LastRequest(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char sParam[32];
		GetMenuItem(menu, param, sParam, sizeof(sParam));
		
		int iInfo = StringToInt(sParam);
		GetLRByID(iInfo, current_lastrequest);
		
		Menu oppMenu = new Menu(Menu_OPPMenu);
		oppMenu.SetTitle("Choose your opponent:");
		
		Jordehi_LoopClients(i)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && IsPlayerAlive(i))
			{
				char sIndex[12], sName[MAX_NAME_LENGTH];
				IntToString(i, sIndex, sizeof(sIndex));
				GetClientName(i, sName, sizeof(sName));
				oppMenu.AddItem(sIndex, sName);
			}
		}
		
		oppMenu.ExitButton = false;
		oppMenu.Display(client, MENU_TIME_FOREVER);
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

public int Menu_OPPMenu(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char sParam[32];
		GetMenuItem(menu, param, sParam, sizeof(sParam));
		
		int target = StringToInt(sParam);
		
		InitiateLastRequest(client, target);
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

void InitiateLastRequest(int client, int target)
{
	if (!Jordehi_IsClientValid(client) || !Jordehi_IsClientValid(target))
	{
		Jordehi_PrintToChatAll("Last request aborted! Client invalid");
		return;
	}
	
	Call_StartForward(gH_Forwards_OnLRStart);
	Call_PushString(current_lastrequest.lr_name);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_Finish();
	
	
	gB_LRStarted = true;
	
	gB_InLR[client] = true;
	gB_InLR[target] = true;
	
	gI_LROpponent[client] = target;
	gI_LROpponent[target] = client;
	
	SetEntityHealth(client, 100);
	SetEntityHealth(target, 100);
	
	//TODO: Save pre LR weapons.
	
	Jordehi_StripAllWeapons(client);
	Jordehi_StripAllWeapons(target);
	
	//Prints lastrequest name client and opponent
	Jordehi_PrintToChatAll("Game : \x07%s\x01 | Player : \x07%N\x01 | Opponent : \x07%N\x01", current_lastrequest.lr_name, client, target);
	
	char sTemp[128];
	
	Panel panel = new Panel();
	panel.SetTitle("Current Last Request :", false);
	panel.DrawText("================");
	FormatEx(sTemp, 128, "Game : %s", current_lastrequest.lr_name);
	panel.DrawText(sTemp);
	FormatEx(sTemp, 128, "Player : %s", client);
	panel.DrawText(sTemp);
	FormatEx(sTemp, 128, "Opponent : %s", target);
	panel.DrawText(sTemp);
	panel.DrawText("================");
	panel.DrawText("Extra Information : ");
	FormatEx(sTemp, 128, "%s", current_lastrequest.lr_extrainfo);
	panel.DrawText(sTemp);
	//panel.CurrentKey = 9;
	
	Jordehi_LoopClients(i)
	{
		SendPanelToClient(panel, i, LastrequestPanel_Callback, MENU_TIME_FOREVER);
	}
}

public int LastrequestPanel_Callback(Menu menu, MenuAction action, int client, int item)
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

public Action LRBeacon_Timer(Handle Timer)
{
	if(!gB_LRStarted)
	{
		return Plugin_Continue;
	}

	//TODO: beacon sound
	
	//Stolen from javit 3>
	float origin[3];
	
	Jordehi_LoopClients(i)
	{
		if(gB_InLR[i])
		{
			if(i <= MaxClients)
			{
				GetClientAbsOrigin(i, origin);
			}
		
			else
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", origin);
			}
		
			origin[2] += 10;
		
			int colors[4] = {0, 0, 0, 255};
			colors[0] = GetRandomInt(0, 255);
			colors[1] = GetRandomInt(0, 255);
			colors[2] = GetRandomInt(0, 255);
		
			TE_SetupBeamRingPoint(origin, 10.0, 250.0, gI_BeamSprite, gI_HaloSprite, 0, 60, 0.75, 2.5, 0.0, colors, 10, 0);
			TE_SendToAll();
		}
	}
	
	return Plugin_Continue;
}

//Stolen from shavit Kappa
bool GetLRByID(int lr_id, lastrequest_game_t game)
{
	int iLength = gA_Games.Length;
	
	for (int i = 0; i < iLength; i++)
	{
		lastrequest_game_t tempgame;
		gA_Games.GetArray(i, tempgame);
		
		if (tempgame.lr_id == lr_id)
		{
			game = tempgame;
			
			return true;
		}
	}
	
	return false;
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

public int Native_RegisterLR(Handle plugin, int numParams)
{
	char sName[Jordehi_MAX_NAME_LENGTH];
	char sExtraInfo[Jordehi_MAX_EXTRAINFO_LENGTH];
	
	GetNativeString(1, sName, sizeof(sName));
	GetNativeString(2, sExtraInfo, sizeof(sExtraInfo));
	
	int iID = gA_Games.Length + 1;
	
	lastrequest_game_t game;
	game.lr_id = iID;
	FormatEx(game.lr_name, sizeof(game.lr_name), sName);
	FormatEx(game.lr_extrainfo, sizeof(game.lr_extrainfo), sExtraInfo);
	
	gA_Games.PushArray(game);
	
	LogMessage("[Jordehi Lastrequests] ID: %d - Name: %s", iID, sName);
	
	return true;
}

public int Native_IsClientInLastRequest(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return gB_InLR[client];
}

public int Native_GetClientOpponent(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	return Jordehi_IsClientValid(gI_LROpponent[client]) ? gI_LROpponent[client] : 0;
}

public int Native_StopLastRequest(Handle plugin, int numParams)
{
	if(gB_LRStarted)
	{
		gB_LRStarted = false;
		
		Call_StartForward(gH_Forwards_OnLREnd);
		Call_PushString(current_lastrequest.lr_name);
		Call_PushCell(gI_LRWinner);
		Call_PushCell(Jordehi_GetClientOpponent(gI_LRWinner));
		Call_Finish();
		Jordehi_PrintToChatAll("Game : \x07%s\x01 | Winner : \x07%N\x01 | Loser : \x07%N\x01", current_lastrequest.lr_name, gI_LRWinner, Jordehi_GetClientOpponent(gI_LRWinner));
		//TODO: if lastrequest is running give pre weapon to winner.
	}
	else
	{
		Jordehi_PrintToChatAll("The current last request has been stopped.");
	}
	
	gI_LRWinner = 0;
	
	Jordehi_LoopClients(i)
	{
		if (gB_InLR[i])
		{
			gB_InLR[i] = false;
		}
		else if(gI_LROpponent[i])
		{
			gI_LROpponent[i] = 0;
		}
	}
}