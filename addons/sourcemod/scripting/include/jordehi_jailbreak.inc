/*
 * Jordehi - jailbreak handler
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

#if defined _jordehi_jailbreak_included
	#endinput
#endif
#define _jordehi_jailbreak_included

#include <cstrike>

#if defined REQUIRE_PLUGIN

#define Jordehi_PREFIX "\x05[Jordehi]\x01"
#define Jordehi_VERSION "1.0b"

#endif

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



/**
 * This native will auto-assign colors and a chat prefix.
 *
 * @param client					Client index.
 * @param format					Formatting rules.
 * @param any						Variable number of format parameters.
 * @return							PrintToChat()
 */
native int Jordehi_PrintToChat(int client, const char[] format, any ...);


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

public SharedPlugin __pl_jordehi_jailbreak =
{
	name = "jordehi_jailbreak",
	file = "jordehi_jailbreak.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};
