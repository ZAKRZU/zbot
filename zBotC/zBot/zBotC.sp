/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <cstrike>
#include <sdktools_functions>

#include <zMessage.sp>

/* DEFINE */
//GAME MISC
#define COUNTDOWNTIME 10
#define MAXROUNDS 15
#define ALLROUNDS MAXROUNDS * 2
#define MESSAGETIME 15
//GAME STATE
#define GSTATE_NOMATCH -1
#define GSTATE_WARMUP 0
#define GSTATE_KNIFEROUND 1
#define GSTATE_W_SIDECHANGEWAIT 2
#define GSTATE_MATCH_1ST 3 //Pausable
#define GSTATE_MATCH_HALFBREAK 4
#define GSTATE_MATCH_2ND 5 //Pausable
#define GSTATE_MATCH_END 6
//TEAMS
#define TEAM_NO -1
#define TEAM_UNKNOWN1 0
#define TEAM_UNKNOWN2 1
#define TEAM_CT 3
#define TEAM_TT 2
#define TEAMCOUNT 4

/* VARIABLES GLOBAL STATIC */
static int g_gameState = GSTATE_NOMATCH;
static bool g_isPaused = false; //inmatch
static char g_config[256]; //creating match
static bool g_enableKnife = true; //creating match
static bool g_autoAssigment = false; //creating match
static char g_gameMap[256] = "de_dust2"; //not used
static bool g_teamReady[TEAMCOUNT]; //on warmup
static bool g_teamPauseReady[TEAMCOUNT];
static bool g_isCountDown = false; //inmatch
static bool g_isAborted = false;
static int g_knife_winner = TEAM_NO; //after knife round
static bool g_knife_end = false;
static bool MessageReset = false;
static float TickRate;
static bool g_debug = false;
/* VARIABLES GLOBAL */
char teamName1[256];
char teamName2[256];
char teamMates[5][256];

/* CONVARS */
ConVar cv_teamName[TEAMCOUNT];

/*----------------------------------------------------------------------------------------------------------*/
public Plugin:myinfo = 
{
	name = "zBot",
	author = "ZAKRZU",
	description = "<- Description ->",
	version = "ALPHA DEV 0.3.0.1",
	url = "<- URL ->"
}

public OnPluginStart()
{
	// Add your own code here...
	//Register Commands
	RegConsoleCmd("zbot_test", Command_zBot_Test);
	RegConsoleCmd("zbot_ready", Command_zBot_AReady);
	RegConsoleCmd("zbot_create", Command_zBot_CreateMatch);
	RegConsoleCmd("zbot_delete", Command_zBot_DeleteMatch);
	//RegConsoleCmd("ready", Command_zBot_Ready);
	//RegConsoleCmd("notready", Command_zBot_UnReady);
	//RegConsoleCmd("abort", Command_zBot_Abort);
	//RegConsoleCmd("switch", Command_zBot_Switch);
	//RegConsoleCmd("stay", Command_zBot_Stay);
	//RegConsoleCmd("zpause", Command_zBot_Pause);
	//RegConsoleCmd("zunpause", Command_zBot_UnPause);
	//Find ConVars
	cv_teamName[TEAM_CT] = FindConVar("mp_teamname_1");
	cv_teamName[TEAM_TT] = FindConVar("mp_teamname_2");
	
	strcopy(teamMates[0], 256, "STEAM_1:0:41511678");
	strcopy(teamMates[1], 256, "STEAM_0:0:87938601");
	strcopy(teamMates[2], 256, "STEAM_0:0:91533278");
	strcopy(teamMates[3], 256, "STEAM_0:1:66698953");
	strcopy(teamMates[4], 256, "STEAM_0:1:35458006");
	
	HookEvent("player_team", zBot_TeamChange, EventHookMode_Pre);
	
	TickRate = 1.0/GetTickInterval();
}

public bool playerIsOnList(char steamid[])
{
	for(int i = 0; i >= 4; i++)
	{
		if(strcmp(steamid, teamMates[i], false) == 0)
		{
			return true;
		} 
		else {
			continue;
		}
	}
	return false;
}

public Action zBot_TeamChange(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_debug)
		return Plugin_Continue;
	if(!g_autoAssigment)
		return Plugin_Continue;
	
	if(g_gameState == GSTATE_WARMUP)
	{
		int user = event.GetInt("userid");
		int team = event.GetInt("team");
		int client = GetClientOfUserId(user);
		char id[255]
		GetClientAuthId(client, AuthId_Engine, id, sizeof(id), true);
		if(team == TEAM_CT)
		{
			if(playerIsOnList(id))
			{
				return Plugin_Continue;
			} else {
				ChangeClientTeam(client, TEAM_TT);
				return Plugin_Continue;
			}
		} else if(team == TEAM_TT){
			if(playerIsOnList(id))
			{
				ChangeClientTeam(client, TEAM_CT);
				return Plugin_Continue;
			} else {
				return Plugin_Continue;
			}
		}
	}
	char name[256];
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("UserId: %d ToTeam: %d ClientId: %d Name: %s", user, team, client, name);
	return Plugin_Continue;
	//return Plugin_Handled;
}

/* COMMANDS */

//               TEST
public Action Command_zBot_Test(int client, int args)
{
	//char arg[128];
	char full[256];
	
	GetCmdArgString(full, sizeof(full));
	
	if(g_debug)
	{
		g_debug = false;
		PrintToConsole(client, "[Debug] FALSE");
	}
	else
	{
		g_debug = true;
		PrintToConsole(client, "[Debug] TRUE");
	}
	
	if(client)
	{
		char id[255]
		GetClientAuthId(client, AuthId_Engine, id, sizeof(id), true);
		PrintToConsole(client, "SteamID: %s", id);
	} else {
		//PrintToConsole(client, "You must be a player!");
		MessageSend(MWarnNP, client);
	}
	
	//ServerCommand("exec esl5on5.cfg");
	
	return Plugin_Handled;
}

public Action Command_zBot_AReady(int client, int args)
{
	TeamSetReady(TEAM_CT);
	TeamSetReady(TEAM_TT);
	
	return Plugin_Handled;
}

//               READY
public Action Command_zBot_Ready(int client, int args)
{	
	if(client)
	{
		if(g_gameState == GSTATE_WARMUP || g_gameState == GSTATE_MATCH_HALFBREAK)
		{
			TeamSetReady(GetClientTeam(client));
			return Plugin_Handled;
		}
	} else{
		//PrintToConsole(client, "You must be a player");
		MessageSend(MWarnNP, client);
	}
	
	return Plugin_Handled;
}

//               UNREADY
public Action Command_zBot_UnReady(int client, int args)
{	
	if(client)
	{
		if(g_gameState == GSTATE_WARMUP || g_gameState == GSTATE_MATCH_HALFBREAK)
		{
			TeamSetUnReady(GetClientTeam(client));
			return Plugin_Handled;
		}
	} else{
		//PrintToConsole(client, "You must be a player");
		MessageSend(MWarnNP, client);
	}
	
	return Plugin_Handled;
}

//               ABORT
public Action Command_zBot_Abort(int client, int args)
{
	if(client)
	{
		if(g_isCountDown)
		{
			TeamSetUnReady(GetClientTeam(client))
			g_isCountDown = false;
			g_isAborted = true;
			return Plugin_Handled;
		}
	} else {
		//PrintToConsole(client, "You must be a player");
		MessageSend(MWarnNP, client);
	}
	
	return Plugin_Handled;
}

//               SWITCH
public Action Command_zBot_Switch(int client, int args)
{
	if(client)
	{
		if(g_gameState == GSTATE_W_SIDECHANGEWAIT)
		{
			if(g_knife_winner == GetClientTeam(client))
			{
				g_knife_winner = TEAM_NO;
				TeamsSwap();
				//PrintToChatAll("TEAM SWAP!!");
				MessageSend(MSwap, 0);
				StartMatch();
				return Plugin_Handled;
			}
		}
	} else {
		//PrintToConsole(client, "You must be a player");
		MessageSend(MWarnNP, client);
	}
	
	return Plugin_Handled;
}

//               STAY
public Action Command_zBot_Stay(int client, int args)
{
	if(client)
	{
		if(g_gameState == GSTATE_W_SIDECHANGEWAIT)
		{
			if(g_knife_winner == GetClientTeam(client))
			{
				g_knife_winner = TEAM_NO;
				StartMatch();
				//PrintToChatAll("TEAM STAY!!");
				MessageSend(MStay, 0);
				return Plugin_Handled;
			}
		}
	} else {
		//PrintToConsole(client, "You must be a player");
		MessageSend(MWarnNP, client);
	}
	
	return Plugin_Handled;
}

//               PAUSE
public Action Command_zBot_Pause(int client, int args)
{	
	if(client)
	{
		int tmp_team = GetClientTeam(client);
		if(g_isPaused)
		{
			if(TeamIsReqUnPause(tmp_team))
			{
				TeamSetPause(tmp_team);
				return Plugin_Handled;
			}
			return Plugin_Handled;
		}
		executePause();
		//PrintToChatAll("zBot:  Team %s get a pause.", TeamGetName(tmp_team));
		MessageSend(MPause, tmp_team);
		return Plugin_Handled;
	} else {
		//PrintToConsole(client, "You must be a player");
		MessageSend(MWarnNP, client);
	}
	
	return Plugin_Handled;
}

//               UNPAUSE
public Action Command_zBot_UnPause(int client, int args)
{	
	if(client)
	{
		if(!g_isPaused)
			return Plugin_Handled;
		int tmp_team = GetClientTeam(client);
		if(TeamIsReqUnPause(tmp_team))
			return Plugin_Handled;
		TeamSetUnPause(tmp_team);
		//PrintToChatAll("zBot:  Team %s requested a unpause.", TeamGetName(tmp_team));
		MessageSend(MUnPause, tmp_team);
		return Plugin_Handled;
	} else {
		//PrintToConsole(client, "You must be a player");
		MessageSend(MWarnNP, client);
	}
	
	return Plugin_Handled;
}

//               COMMANDS
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	//               READY
	if (strcmp(sArgs, "!ready", false) == 0 || strcmp(sArgs, ".ready", false) == 0)
	{
		if(client)
		{
			if(g_gameState == GSTATE_WARMUP || g_gameState == GSTATE_MATCH_HALFBREAK)
			{
				TeamSetReady(GetClientTeam(client));
				return Plugin_Continue;
			}
		} else {
			//PrintToConsole(client, "You must be a player");
			MessageSend(MWarnNP, client);
			return Plugin_Continue;
		}
	}
	
	//               UNREADY
	if (strcmp(sArgs, "!notready", false) == 0 || strcmp(sArgs, ".notready", false) == 0 || strcmp(sArgs, "!unready" , false) == 0 || strcmp(sArgs, ".unready" , false) == 0)
	{
		if(client)
		{
			if(g_gameState == GSTATE_WARMUP || g_gameState == GSTATE_MATCH_HALFBREAK)
			{
				TeamSetUnReady(GetClientTeam(client));
				return Plugin_Continue;
			}
		} else {
			//PrintToConsole(client, "You must be a player");
			MessageSend(MWarnNP, client);
			return Plugin_Continue;
		}
	}
	//               ABORT
	if (strcmp(sArgs, "!abort", false) == 0 || strcmp(sArgs, ".abort", false) == 0)
	{
		if(client)
		{
			if(g_isCountDown)
			{
				TeamSetUnReady(GetClientTeam(client));
				g_isCountDown = false;
				g_isAborted = true;
				return Plugin_Continue;
			}
		} else {
			//PrintToConsole(client, "You must be a player");
			MessageSend(MWarnNP, client);
			return Plugin_Continue;
		}
	}
	//               SWITCH
	if (strcmp(sArgs, "!switch", false) == 0 || strcmp(sArgs, ".switch", false) == 0)
	{
		if(client)
		{
			if(g_gameState == GSTATE_W_SIDECHANGEWAIT)
			{
				if(g_knife_winner == GetClientTeam(client))
				{
					g_knife_winner = TEAM_NO;
					TeamsSwap();
					//PrintToChatAll("TEAM SWAP!!");
					MessageSend(MSwap, client);
					StartMatch();
					return Plugin_Continue;
				}
			}
		} else {
			//PrintToConsole(client, "You must be a player");
			MessageSend(MWarnNP, client);
			return Plugin_Continue;
		}
	}
	//               STAY
	if (strcmp(sArgs, "!stay", false) == 0 || strcmp(sArgs, ".stay", false) == 0)
	{
		if(client)
		{
			if(g_gameState == GSTATE_W_SIDECHANGEWAIT)
			{
				if(g_knife_winner == GetClientTeam(client))
				{
					g_knife_winner = TEAM_NO;
					StartMatch();
					//PrintToChatAll("TEAM STAY!!");
					MessageSend(MStay, client);
					return Plugin_Continue;
				}
			}
		} else {
			//PrintToConsole(client, "You must be a player");
			MessageSend(MWarnNP, client);
			return Plugin_Continue;
		}
	}
	//               PAUSE
	if (strcmp(sArgs, "!pause", false) == 0 || strcmp(sArgs, ".pause", false) == 0)
	{
		if(client)
		{
			int tmp_team = GetClientTeam(client);
			if(g_isPaused)
			{
				if(TeamIsReqUnPause(tmp_team))
				{
					TeamSetPause(tmp_team);
					return Plugin_Continue;
				}
				return Plugin_Continue;
			}
			executePause();
			//PrintToChatAll("zBot:  Team %s get a pause.", TeamGetName(tmp_team));
			MessageSend(MPause, client);
			return Plugin_Continue;
		} else {
			//PrintToConsole(client, "You must be a player");
			MessageSend(MWarnNP, client);
		}
	}
	//               UNPAUSE
	if (strcmp(sArgs, "!unpause", false) == 0 || strcmp(sArgs, ".unpause", false) == 0)
	{
		if(client)
		{
			if(!g_isPaused)
				return Plugin_Continue;
			int tmp_team = GetClientTeam(client);
			if(TeamIsReqUnPause(tmp_team))
				return Plugin_Continue;
			TeamSetUnPause(tmp_team);
			//PrintToChatAll("zBot:  Team %s requested a unpause.", TeamGetName(tmp_team));
			MessageSend(MUnPause, client);
			return Plugin_Continue;
		} else {
			//PrintToConsole(client, "You must be a player");
			MessageSend(MWarnNP, client);
		}
	}
 
	/* Let say continue normally */
	return Plugin_Continue;
}

//               CREATE_MATCH
public Action Command_zBot_CreateMatch(int client, int args)
{
	char arg[256];
	char full[256];
	
	GetCmdArgString(full, sizeof(full));
	
	if(args < 3)
	{
		//MessageHelpCreate(client);
		MessageSend(MCCreateHelp, client);
		return Plugin_Handled;
	}
	
	//TEAM NAMES
	GetCmdArg(1, arg, sizeof(arg));
	TeamSetName(arg, TEAM_CT);
	GetCmdArg(2, arg, sizeof(arg));
	TeamSetName(arg, TEAM_TT);
	//CONFIG NAME
	GetCmdArg(3, arg, sizeof(arg));
	g_config = arg;
	/*
	//MAP NAME
	GetCmdArg(4, arg, sizeof(arg));
	g_gameMap = arg;
	//KNIFE ROUND BOOL
	GetCmdArg(5, arg, sizeof(arg));
	if(strcmp(arg, "true", false))
	{
		g_enableKnife = true;
	} else if(strcmp(arg, "false", false))
	{
		g_enableKnife = false;
	}
	//AUTO ASSIGMENT BOOL
	GetCmdArg(6, arg, sizeof(arg));
	if(strcmp(arg, "true", false))
	{
		g_autoAssigment = true;
	} else if(strcmp(arg, "false", false))
	{
		g_autoAssigment = false;
	}
	*/
	g_gameState = GSTATE_WARMUP;
	
	if(args == 4)
	{
		GetCmdArg(4, arg, sizeof(arg));
		setPass(arg);
	}
	TeamSetUp();
	TeamsClearPause();
	startWarmup();
	
	return Plugin_Handled;
}

//               DELETE_MATCH
public Action Command_zBot_DeleteMatch(int client, int args)
{	
	if(g_gameState == GSTATE_NOMATCH)
	{
		PrintToConsole(client, "First create match. zbot_creatematch")
		return Plugin_Handled;
	}
	g_gameState = GSTATE_NOMATCH;
	stopWarmup();
	TeamsClear();
	MapForceChange("de_dust2");
	
	return Plugin_Handled;
}

/* TEAM FUNCTIONS */

char[] TeamGetName(int teamIndex)
{
	char tmp_teamName[256];
	cv_teamName[teamIndex].GetString(tmp_teamName, 256);
	return tmp_teamName;
}

char[] TeamGetSide(int teamIndex)
{
	char tmp_teamName[256];
	GetTeamName(teamIndex, tmp_teamName, sizeof(tmp_teamName));
	return tmp_teamName;
}

public void TeamSetName(char[] teamName, int teamIndex)
{
	if(teamIndex == TEAM_CT)
	{
		strcopy(teamName1, 256, teamName);
		return;
	} else if(teamIndex == TEAM_TT)
	{
		strcopy(teamName2, 256, teamName);
		return;
	}
	return;
}

public bool TeamIsReady(int teamIndex)
{
	if(g_teamReady[teamIndex])
		return true;
	return false;
}

public bool TeamIsReqUnPause(int teamIndex)
{
	if(g_teamPauseReady[teamIndex])
		return true;
	return false;
}

char[] TeamIsReadyString(int teamIndex)
{
	char tmp_ready[12] = "ready";
	char tmp_notready[12] = "not ready";
	if(g_teamReady[teamIndex])
		return tmp_ready;
	return tmp_notready;
}

public bool TeamSetReady(int teamIndex)
{
	if(teamIndex == TEAM_CT || teamIndex == TEAM_TT)
	{
		if(!TeamIsReady(teamIndex))
		{
			g_teamReady[teamIndex] = true;
			//PrintToChatAll("zBot: Team %s[%s] is ready!", TeamGetName(teamIndex), TeamGetSide(teamIndex));
			MessageSend(MTReady, teamIndex);
		}
	}
}

public bool TeamSetUnPause(int teamIndex)
{
	if(teamIndex == TEAM_CT || teamIndex == TEAM_TT)
	{
		if(!TeamIsReqUnPause(teamIndex))
		{
			g_teamPauseReady[teamIndex] = true;
			//PrintToChatAll("zBot: Team %s[%s] requested unpause!", TeamGetName(teamIndex), TeamGetSide(teamIndex));
			MessageSend(MUnPause, teamIndex);
		}
	}
}

public bool TeamSetUnReady(int teamIndex)
{
	if(teamIndex == TEAM_CT || teamIndex == TEAM_TT)
	{
		if(TeamIsReady(teamIndex))
		{
			g_teamReady[teamIndex] = false;
			//PrintToChatAll("zBot: Team %s[%s] is not ready!", TeamGetName(teamIndex), TeamGetSide(teamIndex));
			MessageSend(MTUnReady, teamIndex);
		}
	}
}

public bool TeamSetPause(int teamIndex)
{
	if(teamIndex == TEAM_CT || teamIndex == TEAM_TT)
	{
		if(TeamIsReqUnPause(teamIndex))
		{
			g_teamPauseReady[teamIndex] = false;
			//PrintToChatAll("zBot: Team %s[%s] is not ready!", TeamGetName(teamIndex), TeamGetSide(teamIndex));
			MessageSend(MUnReady, teamIndex);
		}
	}
}

public bool TeamsCheckReady()
{
	if(TeamIsReady(TEAM_CT) && TeamIsReady(TEAM_TT))
	{
		return true;
	}
	return false;
}

public bool TeamsCheckPause()
{
	if(TeamIsReqUnPause(TEAM_CT) && TeamIsReqUnPause(TEAM_TT))
	{
		return true;
	}
	return false;
}

public void TeamsClearReady()
{
	g_teamReady[TEAM_CT] = false;
	g_teamReady[TEAM_TT] = false;
}

public void TeamsClearPause()
{
	g_teamPauseReady[TEAM_CT] = false;
	g_teamPauseReady[TEAM_TT] = false;
}

public void TeamSetUp()
{
	cv_teamName[TEAM_CT].SetString(teamName1);
	cv_teamName[TEAM_TT].SetString(teamName2);
}

public void TeamsClear()
{
	cv_teamName[TEAM_CT].SetString("");
	cv_teamName[TEAM_TT].SetString("");
	TeamSetName("", TEAM_CT);
	TeamSetName("", TEAM_TT);
	TeamsClearReady();
}

public int TeamGetScore(int TeamIndex)
{
	return CS_GetTeamScore(TeamIndex);
}

public void TeamsSwap()
{
	ServerCommand("mp_swapteams");
}

public void TeamsAutoAssigment()
{
}

/* MAP FUNCTIONS */

public void MapForceChange(char[] mapName)
{
	ServerCommand("changelevel %s", mapName);
}

public void MapChange()
{
	char currentMap[128];
	GetCurrentMap(currentMap, sizeof(currentMap));
	if(strcmp(currentMap, g_gameMap, false))
	{
		return;
	} else {
		ServerCommand("changelevel %s", g_gameMap);
		return;
	}
}

public bool MapIsHalfScore()
{
	int tmp_teamct = TeamGetScore(TEAM_CT);
	int tmp_teamtt = TeamGetScore(TEAM_TT);
	if((tmp_teamct + tmp_teamtt) == MAXROUNDS)
	{
		return true;
	}
	return false;
}

public bool MapIsEnd()
{
	int tmp_teamct = TeamGetScore(TEAM_CT);
	int tmp_teamtt = TeamGetScore(TEAM_TT);
	if(tmp_teamct > MAXROUNDS)
		return true;
	if(tmp_teamtt > MAXROUNDS)
		return true;
	if(tmp_teamct + tmp_teamtt == ALLROUNDS)
		return true;
	return false;
}

/* CONFIG EXECUTE*/

public void executeKnifeConfig()
{
	PrintToChatAll("Executing knife config");
	ServerCommand("mp_halftime_duration 1; mp_roundtime 60; mp_roundtime_defuse 60; mp_roundtime_hostage 60; mp_ct_default_secondary ''; mp_t_default_secondary ''; mp_free_armor 1; mp_give_player_c4 0; mp_maxmoney 0; mp_freezetime 5; mp_friendlyfire 1");
}

public void undoKnifeConfig()
{
	ServerCommand("mp_halftime_duration 15; mp_roundtime 5; mp_roundtime_defuse 0; mp_roundtime_hostage 0; mp_ct_default_secondary \"weapon_hkp2000\"; mp_t_default_secondary \"weapon_glock\"; mp_free_armor 0; mp_give_player_c4 1; mp_maxmoney 16000; mp_friendlyfire 0");
}

public void executeWarmupConfig()
{
	ServerCommand("mp_warmuptime 3600; mp_warmup_pausetimer 1; mp_maxmoney 60000; mp_startmoney 60000; mp_free_armor 1; mp_warmup_start");
}

public void undoWarmupConfig()
{
	ServerCommand("mp_warmuptime 30; mp_warmup_pausetimer 0; mp_maxmoney 16000; mp_startmoney 800; mp_free_armor 0; mp_warmup_end");
}

public void executeMatchConfig()
{
	ServerCommand("exec %s; mp_warmuptime 0; mp_halftime_pausetimer 1; mp_maxrounds %d", g_config, ALLROUNDS);
}


public void executeRestart()
{
	ServerCommand("mp_restartgame 1");
}

public void executePause()
{
	TeamsClearPause();
	ServerCommand("mp_pause_match");
	g_isPaused = true;
}

public void undoPause()
{
	ServerCommand("mp_unpause_match");
	PrintToChatAll("zBot: Match has been resumed");
	TeamsClearPause();
	g_isPaused = false;
}

public void setPass(char[] pass)
{
	ServerCommand("sv_password %s", pass);
}

/* MATCH */

public void startWarmup()
{
	executeWarmupConfig();
}

public void stopWarmup()
{
	undoWarmupConfig();
}

public void EndGame()
{
	ZKickAllPlayers("Match ended!");
	TeamsClear();
	MapForceChange("de_dust2");
}

public void startKnifeRound()
{
	TeamsClearReady();
	stopWarmup();
	g_gameState = GSTATE_KNIFEROUND;
	executeKnifeConfig();
	PrintToChatAll("KNIFE ROUND LIVE!");
	PrintToChatAll("KNIFE ROUND LIVE!");
	PrintToChatAll("KNIFE ROUND LIVE!");
	executeRestart();
}

public void stopKnifeRound()
{
	if(!CountKnife())
		return;
	g_gameState = GSTATE_W_SIDECHANGEWAIT;
	undoKnifeConfig();
	startWarmup();
	g_knife_end = false;
}

public void StartMatch()
{
	g_gameState = GSTATE_MATCH_1ST;
	executeMatchConfig();
}

public bool CountDown()
{
	static int seconds = COUNTDOWNTIME;
	if(g_isAborted && seconds != COUNTDOWNTIME)
	{
		seconds = COUNTDOWNTIME;
		g_isAborted = false;
		return false;
	}
	PrintToChatAll("zBot: %d seconds left.", seconds);
	if(seconds <= 0)
	{
		seconds = COUNTDOWNTIME;
		return true;
	}
	seconds--;
	return false;
}

public bool CountKnife()
{
	static int seconds = 3;
	if(seconds <= 0)
	{
		seconds = 3;
		return true;
	}
	seconds--;
	return false;
}

/* PLUGIN LOOP */
public void OnGameFrame()
{
	static float frames = 0.0;
	if(TickRate <= frames)
	{
		frames = 0.0;
		if(g_gameState == GSTATE_NOMATCH)
			return;
		if(g_gameState == GSTATE_WARMUP)
		{
			if(TeamsCheckReady())
			{
				g_isCountDown = true;
				if(CountDown())
				{
					g_isCountDown = false;
					startKnifeRound();
				}
			} else {
				if(g_isCountDown)
				{
					g_isCountDown = false;
					CountDown();
				}
				MessageTypeReady();
			}
		}
		if(g_gameState == GSTATE_KNIFEROUND)
		{
			if(g_knife_end)
			{
				stopKnifeRound();
			}
			return;
		}
		
		if(g_gameState == GSTATE_W_SIDECHANGEWAIT)
		{
			MessageSwap();
			return;
		}
		
		if(g_gameState == GSTATE_MATCH_HALFBREAK)
		{
			if(TeamsCheckReady())
			{
				g_isCountDown = true;
				if(CountDown())
				{
					g_isCountDown = false;
					ServerCommand("mp_halftime_pausetimer 0");
					g_gameState = GSTATE_MATCH_2ND;
				}
			} else {
				if(g_isCountDown)
				{
					g_isCountDown = false;
					CountDown();
				}
				MessageHalfReady();
			}
		}
		
		if(g_gameState == GSTATE_MATCH_END)
		{
			return;
		}
		if(g_isPaused)
		{
			if(TeamsCheckPause())
			{
				undoPause();
				return;
			}
			MessageMatchPause();
			return;
		}
	}
	frames++;
}

/* ACTION */

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if(g_gameState == GSTATE_KNIFEROUND)
	{
		if(reason == CSRoundEnd_CTWin)
			g_knife_winner = TEAM_CT;
		if(reason == CSRoundEnd_TerroristWin)
			g_knife_winner = TEAM_TT;
		MessageSetReset(true);
		g_knife_end = true;
		return Plugin_Continue;
	}
	
	if(g_gameState == GSTATE_MATCH_1ST)
	{
		if(MapIsHalfScore())
		{
			g_gameState = GSTATE_MATCH_HALFBREAK;
			ServerCommand("mp_halftime_pausetimer 1");
			MessageSetReset(true);
			return Plugin_Continue;
		} else {
			MessageScoreFST();
		}
	}
	
	if(g_gameState == GSTATE_MATCH_2ND)
	{
		if(MapIsEnd())
		{
			g_gameState = GSTATE_MATCH_END;
			EndGame();
			return Plugin_Continue;
		} else {
			MessageScoreSND();
		}
	}
	
	return Plugin_Continue;
}

/* MESSAGES */

public bool MessageCanSend()
{
	static int secondsCounter = 0;
	if(MessageReset)
	{
		MessageReset = false;
		secondsCounter = 0;
	}
	if(g_gameState != GSTATE_WARMUP && g_gameState != GSTATE_MATCH_HALFBREAK && g_gameState != GSTATE_W_SIDECHANGEWAIT)
	{
		secondsCounter = MESSAGETIME;
		return false;
	}
	if(secondsCounter == 0) 
	{
		secondsCounter = MESSAGETIME;
		return true;
	}
	secondsCounter--;
	return false;
}

public void MessageSetReset(bool r)
{
	MessageReset = r;
}

public void MessageScoreFST()
{
	PrintToChatAll("zBot: %s [%d] / %s [%d]", TeamGetName(TEAM_CT), TeamGetScore(TEAM_CT), TeamGetName(TEAM_TT), TeamGetScore(TEAM_TT));
}

public void MessageScoreSND()
{
	PrintToChatAll("zBot: %s [%d] / %s [%d]", TeamGetName(TEAM_CT), TeamGetScore(TEAM_TT), TeamGetName(TEAM_TT), TeamGetScore(TEAM_CT));
}

public void MessageTypeReady()
{
	if(!MessageCanSend())
		return;
	//PrintToChatAll("zBot: %s [%s] is [%s] | %s [%s] is [%s]", TeamGetName(TEAM_CT), TeamGetSide(TEAM_CT), TeamIsReadyString(TEAM_CT), TeamGetName(TEAM_TT), TeamGetSide(TEAM_TT), TeamIsReadyString(TEAM_TT));
	PrintToChatAll("zBot: %s is [%s] | %s is [%s]", TeamGetName(TEAM_CT), TeamIsReadyString(TEAM_CT), TeamGetName(TEAM_TT), TeamIsReadyString(TEAM_TT));
	PrintToChatAll("zBot: Please type !ready if your team is ready!");
	MessageCommands();
}

public void MessageSwap()
{
	if(!MessageCanSend())
		return;
	PrintToChatAll("zBot: Waiting for %s to choose side (!stay/!swtich)", TeamGetName(g_knife_winner));
	MessageCommands();
}

public void MessageHalfReady()
{
	if(!MessageCanSend())
		return;
	PrintToChatAll("zBot: HalfTime Team: %s [%d] | Team: %s [%d]", TeamGetName(TEAM_CT), TeamGetScore(TEAM_CT), TeamGetName(TEAM_TT), TeamGetScore(TEAM_TT));
	PrintToChatAll("zBot: Please type !ready if your team is ready!");
	MessageCommands();
}

public void MessageMatchPause()
{
	if(!MessageCanSend())
		return;
	PrintToChatAll("zBot: Match is paused!");
	PrintToChatAll("zBot: Please type !unpause if your team is ready!");
	MessageCommands();
}

public void MessageHelpCreate(int client)
{
	PrintToConsole(client, "zbot_create TeamName1 TeamName2 Config Password");
	PrintToConsole(client, "TeamName1 - Set name of team 1.");
	PrintToConsole(client, "TeamName2 - Set name of team 2.");
	PrintToConsole(client, "Config - Set config (with .cfg). Ex.(esl5on5.cfg)");
	PrintToConsole(client, "Password - Set server password (optional)");
	//PrintToConsole(client, "MapName - Set map.(U can ignore, type something)");
	//PrintToConsole(client, "KnifeRound - Set that you want knife round, or not.(type true if you want or false if not)");
	//PrintToConsole(client, "AutoTeamAssigment - Reserved. Type something");
}

public void MessageCommands()
{
	PrintToChatAll("zBot: Commands available: !ready, !notready, !stay, !switch");
	//PrintToChatAll("zBot:  Commands available: !help, !status, !stats, !morestats, !score, !ready, !notready, !stop, !restart (for knife round), !stay, !switch");
}

/* PLAYERS */

public void ZKickAllPlayers(char[] text)
{
	//int MaxClients = GetMaxClients();
	for(int i=1;i<=MaxClients;i++)
	{
		if(!IsClientConnected(i))
			continue;
		
		KickClient(i, text);
	}
}