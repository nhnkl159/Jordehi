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
 * @param random 					If lastrequest is random.
 * @return                          null
 */
forward void Jordehi_OnLRStart(char[] lr_name, int terrorist, int ct, bool random);

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
 * This native will register new last request to lastrequests menu.
 *
 * @param name					Lastrequest name.
 * @param extrainfo					Extra info to show at the panel.
 * @return							true
 */
native bool Jordehi_RegisterLR(const char[] name, const char[] extrainfo);

/**
 * This native will update the extra information of the current lastrequest.
 *
 * @param extrainfo					Extra info to show at the panel.
 * @return							true
 */
native bool Jordehi_UpdateExtraInfo(const char[] extrainfo);

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
