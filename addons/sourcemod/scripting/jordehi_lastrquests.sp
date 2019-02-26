#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
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
char gS_PrePrimaryWeapon[MAXPLAYERS + 1][32];
char gS_PreSecondaryWeapon[MAXPLAYERS + 1][32];

// === Booleans === //
bool gB_Late = false;
bool gB_LRAvailable = false;
bool gB_LRStarted = false;
bool gB_InLR[MAXPLAYERS + 1]; //Probably switch to defines idk
bool gB_Random = false;
bool gB_Rebel = false;

// === Floats === //

// === Handles === //
ArrayList gA_Games = null;
lastrequest_game_t current_lastrequest; //idk if it belongs here lol

Handle gH_Forwards_OnLRAvailable = null;
Handle gH_Forwards_OnLRStart = null;
Handle gH_Forwards_OnLREnd = null;

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
	CreateNative("Jordehi_UpdateExtraInfo", Native_UpdateExtraInfo);
	CreateNative("Jordehi_IsClientInLastRequest", Native_IsClientInLastRequest);
	CreateNative("Jordehi_GetClientOpponent", Native_GetClientOpponent);
	CreateNative("Jordehi_StopLastRequest", Native_StopLastRequest);
	
	gB_Late = late;
	
	return APLRes_Success;
}


public void OnPluginStart()
{
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
	CreateConVar("jordehi_version", Jordehi_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// === Shit & uuh stuff === //
	if (gA_Games != null)
	{
		gA_Games.Clear();
	}
	
	gA_Games = new ArrayList(sizeof(lastrequest_game_t));
	
	gH_Forwards_OnLRAvailable = CreateGlobalForward("Jordehi_OnLRAvailable", ET_Event);
	gH_Forwards_OnLRStart = CreateGlobalForward("Jordehi_OnLRStart", ET_Event, Param_String, Param_Cell, Param_Cell, Param_Cell);
	gH_Forwards_OnLREnd = CreateGlobalForward("Jordehi_OnLREnd", ET_Event, Param_String, Param_Cell, Param_Cell);
	
	//cause fuck bitbuffer usermessages https://i.imgur.com/NBFonQq.png
	if (GetUserMessageType() == UM_Protobuf)
	{
		HookUserMessage(GetUserMessageId("RadioText"), BlockRadio, true);
	}
	
	if(gB_Late)
	{
		Jordehi_LoopClients(i)
		{
			OnClientPutInServer(i);
		}
	}
	
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
	
	AddFileToDownloadsTable("sound/jordehi/jordehi_beacon.mp3");
	PrecacheSound("jordehi/jordehi_beacon.mp3", true);
	
	AddFileToDownloadsTable("sound/jordehi/jordehi_lr_start.mp3");
	PrecacheSound("jordehi/jordehi_lr_start.mp3", true);
	
	AddFileToDownloadsTable("sound/jordehi/jordehi_lr_end.mp3");
	PrecacheSound("jordehi/jordehi_lr_end.mp3", true);
	
	AddFileToDownloadsTable("sound/jordehi/jordehi_lr_end2.mp3");
	PrecacheSound("jordehi/jordehi_lr_end2.mp3", true);
	
	AddFileToDownloadsTable("sound/jordehi/jordehi_lr_activated.mp3");
	PrecacheSound("jordehi/jordehi_lr_activated.mp3", true);
	
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

public void OnClientPutInServer(int client)
{
	if (Jordehi_IsClientValid(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		
		gB_InLR[client] = false;
		gI_LROpponent[client] = 0;
		FormatEx(gS_PrePrimaryWeapon[client], 32, "");
		FormatEx(gS_PreSecondaryWeapon[client], 32, "");
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

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!Jordehi_IsClientValid(attacker))
	{
		return Plugin_Continue;
	}
	
	// Currently simple cheating system.
	if(gB_LRStarted)
	{
		int iOpponent = Jordehi_GetClientOpponent(victim);
		if(attacker != iOpponent)
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
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
		Command_LastRequest(gI_LRWinner, 0);
	}
	
	if (GetTeamPlayers(2, true) == 1 && GetTeamPlayers(3, true) >= 1 && !gB_LRStarted && !gB_LRAvailable)
	{
		gB_LRAvailable = true;
		
		Call_StartForward(gH_Forwards_OnLRAvailable);
		Call_Finish();
		
		Jordehi_LoopClients(i)
		{
			if(IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				Command_LastRequest(i, 0);
				Jordehi_PrintToChatAll("Player \x05%N\x01 had to kill \x07%d \x0BCT\x01 to win.", i, GetTeamPlayers(2, true));
			}
		}
		
		EmitSoundToAll("jordehi/jordehi_lr_activated.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
	}
}

public Action Command_AbortLR(int client, int args)
{
	if (!Jordehi_IsClientValid(client))
	{
		return Plugin_Handled;
	}
	
	Jordehi_StopLastRequest();
	
	Jordehi_PrintToChatAll("The current last request has been stopped.");
	
	return Plugin_Handled;
}

public Action Command_LastRequest(int client, int args)
{
	if (!Jordehi_IsClientValid(client))
	{
		return Plugin_Handled;
	}
	
	if(!IsAbleToStartLR(client))
	{
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
	
	if(iLength >= 1)
	{
		menu.AddItem("rand", "Random LR");
	}
	
	menu.AddItem("rebel", "Rebel");
	
	SortADTArray(gA_Games, Sort_Descending, Sort_Integer);
	
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
		
		if(!IsAbleToStartLR(client))
		{
			return 0;
		}
		
		int iInfo = StringToInt(sParam);
		
		if(StrEqual(sParam, "rebel"))
		{
			gB_Rebel = true;
			GivePlayerItem(client, "weapon_negev");
			GivePlayerItem(client, "weapon_deagle");
			SetEntityHealth(client, 350);
			return 0;
		}
		
		
		if(StrEqual(sParam, "rand"))
		{
			iInfo = GetRandomInt(1, gA_Games.Length);
			gB_Random = true;
		}

		
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
		
		if (menu.ItemCount == 0)
		{
			menu.AddItem("-1", "No counter terrorists found.");
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
		
		if(!IsAbleToStartLR(client))
		{
			return 0;
		}
		
		int target = StringToInt(sParam);
		
		InitiateLastRequest(client, target, gB_Random);
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

void InitiateLastRequest(int client, int target, bool bRandom)
{
	if (!Jordehi_IsClientValid(client) || !Jordehi_IsClientValid(target))
	{
		Jordehi_PrintToChatAll("Last request aborted! Client invalid");
		return;
	}
	
	EmitSoundToAll("jordehi/jordehi_lr_start.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
	
	gB_LRStarted = true;
	
	gB_InLR[client] = true;
	gB_InLR[target] = true;
	
	gI_LROpponent[client] = target;
	gI_LROpponent[target] = client;
	
	Call_StartForward(gH_Forwards_OnLRStart);
	Call_PushString(current_lastrequest.lr_name);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(bRandom);
	Call_Finish();
	
	SetEntityHealth(client, 100);
	SetEntityHealth(target, 100);
	
	SavePrimaryAndSecondary(client);
	SavePrimaryAndSecondary(target);
	
	Jordehi_StripAllWeapons(client);
	Jordehi_StripAllWeapons(target);
	
	Jordehi_PrintToChatAll("Game : \x07%s\x01 | Player : \x07%N\x01 | Opponent : \x07%N\x01", current_lastrequest.lr_name, client, target);
	
	char sTemp[128];
	
	Panel panel = new Panel();
	panel.SetTitle("[Jordehi] Current Last Request :", false);
	panel.DrawText("================");
	FormatEx(sTemp, 128, " - Game : %s", current_lastrequest.lr_name);
	panel.DrawText(sTemp);
	FormatEx(sTemp, 128, " - Player : %N", client);
	panel.DrawText(sTemp);
	FormatEx(sTemp, 128, " - Opponent : %N", target);
	panel.DrawText(sTemp);
	panel.DrawText("================");
	FormatEx(sTemp, 128, "%s", current_lastrequest.lr_extrainfo);
	panel.DrawText(sTemp);
	panel.CurrentKey = 9;
	
	Jordehi_LoopClients(i)
	{
		if(i != client)
		{
			SendPanelToClient(panel, i, LastrequestPanel_Handler, MENU_TIME_FOREVER);
		}
	}
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

public Action LRBeacon_Timer(Handle Timer)
{
	if(!gB_LRStarted)
	{
		return Plugin_Continue;
	}

	EmitSoundToAll("jordehi/jordehi_beacon.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, 20);
	
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

void SavePrimaryAndSecondary(int client)
{
	int iSlot = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(iSlot != -1)
	{
		GetEntityClassname(iSlot, gS_PrePrimaryWeapon[client], 32);
	}
	else
	{
		strcopy(gS_PrePrimaryWeapon[client], 32, "");
	}
	
	iSlot = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(iSlot != -1)
	{
		GetEntityClassname(iSlot, gS_PreSecondaryWeapon[client], 32);
	}
	else
	{
		strcopy(gS_PreSecondaryWeapon[client], 32, "");
	}
}

bool IsAbleToStartLR(int client)
{
	if (GetClientTeam(client) != CS_TEAM_T || !IsPlayerAlive(client) || GetTeamPlayers(2, true) > 1)
	{
		Jordehi_PrintToChat(client, "In order to use this command, you must be the last terrorist alive.");
		return false;
	}
	
	if (GetTeamPlayers(3, true) <= 0)
	{
		Jordehi_PrintToChat(client, "In order to use this command, there are must be an alive counter terrorist.");
		return false;
	}
	
	if (gB_LRStarted)
	{
		Jordehi_PrintToChat(client, "In order to use this command, there are must be no active lastrequest.");
		return false;
	}
	
	if (gB_InLR[client])
	{
		Jordehi_PrintToChat(client, "In order to use this command, there are must be no active lastrequest.");
		return false;
	}
	
	if (!gB_LRAvailable)
	{
		Jordehi_PrintToChat(client, "Lastrequest in not available at the moment.");
		return false;
	}
	
	if(gB_Rebel)
	{
		Jordehi_PrintToChat(client, "Lastrequest in not available after you choosed to rebel.");
		return false;
	}
	
	return true;
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

bool IsLRNameExist(char[] sName)
{
	int iLength = gA_Games.Length;
	
	for (int i = 0; i < iLength; i++)
	{
		lastrequest_game_t tempgame;
		gA_Games.GetArray(i, tempgame);
		
		if (StrEqual(sName, tempgame.lr_name))
		{
			return true;
		}
	}
	
	return false;
}

stock int GetLRTerrorist()
{
	int iTerrorist = 0;
	Jordehi_LoopClients(i)
	{
		if (gB_InLR[i] && GetClientTeam(i) == 2)
		{
			iTerrorist = i;
		}
	}
	
	return iTerrorist;
}

stock int GetLRCT()
{
	int iCTerrorist = 0;
	Jordehi_LoopClients(i)
	{
		if (gB_InLR[i] && GetClientTeam(i) == 3)
		{
			iCTerrorist = i;
		}
	}
	
	return iCTerrorist;
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
	
	if(!IsLRNameExist(sName))
	{
		lastrequest_game_t game;
		game.lr_id = iID;
		FormatEx(game.lr_name, sizeof(game.lr_name), sName);
		FormatEx(game.lr_extrainfo, sizeof(game.lr_extrainfo), sExtraInfo);
		
		gA_Games.PushArray(game);
		
		LogMessage("[Jordehi Lastrequests] ID: %d - Name: %s", iID, sName);
		return true;
	}
	
	return false;
}

public int Native_UpdateExtraInfo(Handle plugin, int numParams)
{
	char sExtraInfo[Jordehi_MAX_EXTRAINFO_LENGTH];
	
	GetNativeString(1, sExtraInfo, sizeof(sExtraInfo));
	
	FormatEx(current_lastrequest.lr_extrainfo, sizeof(current_lastrequest.lr_extrainfo), sExtraInfo);
	
	char sTemp[128];
	
	int iTerrorist = GetLRTerrorist();

	Panel panel = new Panel();
	panel.SetTitle("[Jordehi] Current Last Request :", false);
	panel.DrawText("================");
	FormatEx(sTemp, 128, " - Game : %s", current_lastrequest.lr_name);
	panel.DrawText(sTemp);
	FormatEx(sTemp, 128, " - Player : %N", iTerrorist);
	panel.DrawText(sTemp);
	FormatEx(sTemp, 128, " - Opponent : %N", Jordehi_GetClientOpponent(iTerrorist));
	panel.DrawText(sTemp);
	panel.DrawText("================");
	FormatEx(sTemp, 128, "%s", current_lastrequest.lr_extrainfo);
	panel.DrawText(sTemp);
	panel.CurrentKey = 9;
	
	Jordehi_LoopClients(i)
	{
		SendPanelToClient(panel, i, LastrequestPanel_Handler, MENU_TIME_FOREVER);
	}
	
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
	if (Jordehi_IsClientValid(gI_LRWinner) && Jordehi_IsClientValid(Jordehi_GetClientOpponent(gI_LRWinner)))
	{
		Call_StartForward(gH_Forwards_OnLREnd);
		Call_PushString(current_lastrequest.lr_name);
		Call_PushCell(gI_LRWinner);
		Call_PushCell(Jordehi_GetClientOpponent(gI_LRWinner));
		Call_Finish();
	}
	else
	{
		int iTerrorist = GetLRTerrorist();
		Call_StartForward(gH_Forwards_OnLREnd);
		Call_PushString(current_lastrequest.lr_name);
		Call_PushCell(iTerrorist);
		Call_PushCell(Jordehi_GetClientOpponent(iTerrorist));
		Call_Finish();
	}
	
	if(gB_LRStarted)
	{
		gB_LRStarted = false;
		
		if (Jordehi_IsClientValid(gI_LRWinner) && Jordehi_IsClientValid(Jordehi_GetClientOpponent(gI_LRWinner)))
		{
			Jordehi_PrintToChatAll("Game : \x07%s\x01 | Winner : \x07%N\x01 | Loser : \x07%N\x01", current_lastrequest.lr_name, gI_LRWinner, Jordehi_GetClientOpponent(gI_LRWinner));
			
			if(GetClientTeam(gI_LRWinner) == 2)
			{
				EmitSoundToAll("jordehi/jordehi_lr_end.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
			}
			else
			{
				EmitSoundToAll("jordehi/jordehi_lr_end2.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
			}
			
			char sTemp[32];
			FormatEx(sTemp, 32, "- Lastrequest Winner : %N", gI_LRWinner);
			Jordehi_UpdateExtraInfo(sTemp);
			
			GivePlayerItem(gI_LRWinner, "weapon_knife");
	
			if(strlen(gS_PrePrimaryWeapon[gI_LRWinner]) > 0)
			{
				GivePlayerItem(gI_LRWinner, gS_PrePrimaryWeapon[gI_LRWinner]);
			}
			
			if(strlen(gS_PreSecondaryWeapon[gI_LRWinner]) > 0)
			{
				GivePlayerItem(gI_LRWinner, gS_PreSecondaryWeapon[gI_LRWinner]);
			}
		}
	}
	
	gI_LRWinner = 0;
	gB_Rebel = false;
	gB_Random = false;
	
	Jordehi_LoopClients(i)
	{
		if (gB_InLR[i])
		{
			SetEntityHealth(i, 100);
			gB_InLR[i] = false;
		}
		else if(gI_LROpponent[i])
		{
			gI_LROpponent[i] = 0;
		}
		
		FormatEx(gS_PrePrimaryWeapon[i], 32, "");
		FormatEx(gS_PreSecondaryWeapon[i], 32, "");
	}
}