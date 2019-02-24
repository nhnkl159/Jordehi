# Jordehi - Jailbreak Management & Last requests
Complete rework of my current plugins, Jailbreak management and last requests handler for Israeli CS: GO jailbreak servers.

## Jailbreak Management
* Includes API to register new votes to VoteCT to make it easier to add & remove votes (dynamic).
* Includes Days system which integrates with automatic votect, includes API to register new days to make it easier to add/remove days (dynamic), days should be separated to terrorists vs terrorists & counter terrorists vs terrorists.
* Use "Addicted." CTBans to check if the player is a free killer and block him from participate in the VoteCT.
* UI and sounds to make it more fun I guess.
### Admin Commands
- [ ] **sm_votect** - Initiates a manual CT vote.
- [ ] **sm_viewkills** - Open's a menu with all kills made on that round.
- [ ] **sm_hns** - Open's a menu with enable/disable Hide and Seek options.
- [ ] **sm_ck** - Open's a menu with enable/disable Crazy Knife options.
- [ ] **sm_cm / sm_changemap** - Start's the change map vote.
- [ ] **sm_setbutton** [THANKS SHAVIT <3]- Set the cell open button.
- [ ] **Mute Commands** - Basic commands to mute terrorists / counter terrorists / ALL / and admins cause they might be annoying sometimes.

### Player Commands
- [ ] **sm_admins** - Open's a menu with online admins on the server (shh admins can be invisible).
- [ ] **sm_maptime** - Print's to chat the current time on the current map.
#### **Counter Terrorists commands only**
- [ ] **sm_guard / sm_guards** **[CT Chooser]** - Open's a menu with CT chooser options.
- [ ] **sm_open** - Open's jailbreak cells on current map.
- [ ] **sm_vip / sm_freeday** - Assign freeday status for player.
- [ ] **sm_box / sm_pvp** - Open's a menu with enable/disable Box options.
- [ ] **sm_games** - Open's a menu with games to play with terrorists.
- [ ] **sm_deagle** - Give's all terrorists a empty deagle.
- [ ] **sm_cd / sm_countdown** **(?)** - Open's a menu with seconds and freeze option to start countdown for terrorists.
- [ ] **sm_glow** **(?)** - Open's a menu with glow options to mark player / team of players.
#### **Terrorists commands only**
- [ ] **sm_fk / sm_freekill** - Send terrorist complain about freekill to online admins.
- [ ] **sm_givelr** - Give's lastrequest to another player (Can be used once in a round).
- [ ] **sm_medic** - Request's medic from counter terrorists.

### Developer API
- [ ] SOON

## Last requests
* Includes API to register new last requests to make it easier to add & remove (dynamic).
* Start weapons.
* Colored beacons.
* No block (?)
* Block radio messages
* Connect / Disconnect messages with GEO.
* Should be lightweight because it only contains core features.
* Smart cheating system that recognizes when a player is cheating, the punishment should be nothing/slap for a certain amount on health / slay.
* Last request panel that contains all extra information the last terrorist choose.
* UI and sounds to make it more fun I guess.

### Admin Commands
- [x] **sm_stoplr / sm_abortlr** - Aborts the current active LR.

### Player Commands
- [x] **sm_lr / sm_lastrequest** - Open's the available lastrequests menu.

### Games (Lastrequests)
- [x] Random LR (stats and extra information is random).
- [x] Rebel
- [x] Dodgeball
- [x] Shot4Shot
- [x] Mag4Mag
- [x] Knife fight
- [x] Russian Roulette
- [x] NoScope Battle
- [x] DeagleToss
- [ ] FreeDay (Use JB Management API)
- [x] Hot Potato
- [ ] Race
- [ ] Hit and Run
- [ ] Survive The Rain

### Developer API
#### **Forwards**
- [x] void Jordehi_OnLRAvailable();
- [x] void Jordehi_OnLRStart(char[] lr_name, int terrorist, int ct);
- [x] void Jordehi_OnLREnd(char[] lr_name, int winner, int loser); 
#### **Natives**
- [x] int Jordehi_PrintToChat(int client, const char[] format, any ...);
- [x] bool Jordehi_RegisterLR(const char[] name, const char[] extrainfo);
- [x] bool Jordehi_UpdateExtraInfo(const char[] extrainfo);
- [x] bool Jordehi_IsClientInLastRequest(int client);
- [x] int Jordehi_GetClientOpponent(int client);
- [x] void Jordehi_StopLastRequest();
