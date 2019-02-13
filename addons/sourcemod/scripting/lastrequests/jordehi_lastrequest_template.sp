#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <jordehi_lastrequests>

#pragma newdecls required

#define LR_NAME "Knife Fight"
#define PLUGIN_NAME "Jordehi - Last Request - " ... LR_NAME

// === Integers === //

// === Strings === //

// === Booleans === //
bool gB_LRActivated = false;

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
	Jordehi_RegisterLR(LR_NAME, "");
	
	gB_LRActivated = false;
}

public void Jordehi_OnLRStart(char[] lr_name, int terrorist, int ct)
{
	if(StrEqual(lr_name, LR_NAME))
	{
		gB_LRActivated = true;
	}
}

public void Jordehi_OnLREnd(char[] lr_name, int winner, int loser)
{
	gB_LRActivated = false;
}