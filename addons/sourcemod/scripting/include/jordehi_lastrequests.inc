/*
 * Jordehi - Lastrequests handler
 * by: http://keepomod.com/
 *
 * This file is part of jordehi.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
*/

#if defined _jordehi_lastrquests_included
	#endinput
#endif
#define _jordehi_lastrequests_included

#include <cstrike>

#if defined REQUIRE_PLUGIN
#define Jordehi_MAX_NAME_LENGTH 32
#define Jordehi_MAX_EXTRAINFO_LENGTH 1080

#define Jordehi_PREFIX "\x05[Jordehi]\x01"
#define Jordehi_VERSION "1.0b"


// Thanks Bara ;)
#define Jordehi_LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(Jordehi_IsClientValid(%1))

stock bool Jordehi_IsClientValid(int client)
{
	if (client > 0 && client <= MaxClients)
	{
		if(IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
		{
			return true;
		}
	}
	return false;
}

stock void Jordehi_StripAllWeapons(int client)
{
	for(int i = CS_SLOT_PRIMARY; i <= CS_SLOT_C4; i++)
	{
		int index = -1;
		while((index = GetPlayerWeaponSlot(client, i)) != -1)
		{
			Jordehi_SafeRemoveWeapon(client, index);
		}
	}
}

stock bool Jordehi_SafeRemoveWeapon(int client, int weapon)
{
	if (!IsValidEntity(weapon) || !IsValidEdict(weapon))
	{
		return false;
	}
	
	if (!HasEntProp(weapon, Prop_Send, "m_hOwnerEntity"))
	{
		return false;
	}
	
	int iOwner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
	if (iOwner != client)
	{
		SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
	}
	
	CS_DropWeapon(client, weapon, false);
	
	if (HasEntProp(weapon, Prop_Send, "m_hWeaponWorldModel"))
	{
		int iWorldModel = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
		
		if (IsValidEdict(iWorldModel) && IsValidEntity(iWorldModel))
		{
			if (!AcceptEntityInput(iWorldModel, "Kill"))
			{
				return false;
			}
		}
	}
	
	if (!AcceptEntityInput(weapon, "Kill"))
	{
		return false;
	}
	
	return true;
}

stock int GetTeamPlayers(int team, bool alive)
{
	int count = 0;
	Jordehi_LoopClients(i)
	{
		if(GetClientTeam(i) == team)
		{
			//yea thats fucked up :D
			if(alive)
			{
				if(IsPlayerAlive(i))
				{
					count++;
				}
			}
			else
			{
				count++;
			}
		}
	}
	
	return count;
}

#endif

enum struct lastrequest_game_t
{
	int lr_id;
	char lr_name[32];
	char lr_extrainfo[1080];
};

/**
 * Called when an LR is available.
 *
 * @noreturn
 */
forward void Jordehi_OnLRAvailable();

/**
 * Called when an LR starts.
 *
 * @param lr_name  					The name of the LR that starts.
 * @param terrorist					Client index of LR terrorist.
 * @param ct 					Client index of LR counter terrorist.
 * @return                          null
 */
forward void Jordehi_OnLRStart(char[] lr_name, int terrorist, int ct);

/**
 * Called when an LR is finished by someone winning.
 *
 * @param type  					The LR that ended.
 * @param winner					Client index of LR winner.
 * @param loser 					Client index of LR loser.
 * @noreturn
 */
forward void Jordehi_OnLREnd(char[] lr_name, int winner, int loser);



/**
 * This native will auto-assign colors and a chat prefix.
 *
 * @param client					Client index.
 * @param format					Formatting rules.
 * @param any						Variable number of format parameters.
 * @return							PrintToChat()
 */
native int Jordehi_PrintToChat(int client, const char[] format, any ...);

/**
 * This native will register new last request to lastrequests menu.
 *
 * @param name					Lastrequest name.
 * @param extrainfo					Extra info to show at the panel.
 * @return							true
 */
native bool Jordehi_RegisterLR(const char[] name, const char[] extrainfo);

/**
 * This native will check if client is in lastrequest.
 *
 * @param client					Client index.
 * @return							true
 */
native bool Jordehi_IsClientInLastRequest(int client);

/**
 * This native will return client opponent in lastrequest.
 *
 * @param client					Client index.
 * @return							Client index
 */
native int Jordehi_GetClientOpponent(int client);

/**
 * This native will stop the current lastrequest.
 *
 * @return							true
 */
native void Jordehi_StopLastRequest();

// code stolen from the base halflife.inc file and shavit kapppa
stock void Jordehi_PrintToChatAll(const char[] format, any ...)
{
	char[] buffer = new char[300];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 300, format, 2);
			Jordehi_PrintToChat(i, "%s", buffer);
		}
	}
}

public SharedPlugin __pl_jordehi_lastrquests =
{
	name = "jordehi_lastrquests",
	file = "jordehi_lastrquests.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};
