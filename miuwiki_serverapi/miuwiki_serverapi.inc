/** Double-include prevention */
#if defined _miuwiki_serverapi_included_
  #endinput
#endif
#define _miuwiki_serverapi_included_

#define COUNT_HUMAN 0
#define COUNT_BOT 1
#define COUNT_BOTH 2

/**
 * This property check the state that event "round_start" and OnMapStart() both fire.
 * Because sometime "round_start" fired before OnMapStart which will cause some problem.
 * Actuall you can check OnConfigExecute by yourself. It always fire after then.
 * 
 * @return True if both them start, false if "round_end" or OnMapEnd() fire.
 */
native bool M_IsChapterStart();

/**
 * Create new survivor bot.
 * 
 * @return The bot client index. -1 on failure.
 */
native int M_CreateSurvivorBot();

/**
 * Set player to a bot spec, and take over this bot.
 * 
 * @param client  The valid client index of spector.
 * @param bot     The bot client index who doesn't have human spec it.
 */
native void M_TakeOverBot(int client, int bot);

/**
 * Check a bot is used or not. Used meaning it has a human spec or not.
 * 
 * @param bot   The bot client index.
 * 
 * @return True if bot has human spec, false otherwise.
 */
native bool M_IsSurvivorBotused(int bot);

/**
 * Create a ragdoll for death client. 
 * 
 * @param client  Valid client index who need create.
 */
native void M_CreateRagDoll();

/**
 * Respawn death survivor in safe room. 
 * 
 * @note Don't forget teleport survivor .
 * 
 * @param client  Death survivor client index.
 */
native void M_RespawnSurvivor(int client);

/**
 * Let bot do some action you want.
 * Use this before you have turely understood what they mean. Detailes in https://developer.valvesoftware.com/wiki/List_of_L4D2_Script_Functions/CommandABot
 * 
 * @param bot   The bot client index.
 * @param cmd   The cmd define in document.(BOT_CMD_ATTACK,BOT_CMD_MOVE,BOT_CMD_RETREAT,BOT_CMD_RESET)
 * @param target    Base on which cmd you used, attack and retreat should use this param.
 * @param pos    Base on which cmd you used, move should use this param.
 */
native void M_CommandBot(int bot,int cmd, int target = 0, float pos[3] = {0.0,0.0,0.0});

/**
 * Get current survivor count of human or bot or human and bot.
 * 
 * @param type  Choose to count survivor or bot.0 = huamn, 1 = bot, 2 = both;
 * @return Count of the survivor human / bot / both them.
 */
native int M_SurvivorCount(int type);

/**
 * Is survivor be hold by special infected or not.
 * 
 * @param client  Valid client index.
 * @return True if is getting hold, false otherwise.
 */
native bool M_IsSurvivorBeHold(int client);

/**
 * Is survivor getting up or not.
 * This check the m_nsequence base on client model.
 * 
 * @param client  Valid client index.
 * @return True if is getting up, false otherwise.
 */
native bool M_IsSurvivorGetup(int client);

/**
 * Give player a weapon base on GivePlayerItem().
 * 
 * @note If you want to give player a melee by slot 1 in this native,
 * you can only get a random melee because we don't know which 
 * melee has been unlock and write in the script.
 * 
 * @param client  Valid client index.
 * @param slot    Player weapon slot, start from 0 end 4. 
 * @param index   Weapon index base on convar. -1 mean random give.
 * 
 * @return Entity index if give success, -1 mean false.
 */
native int M_GivePlayerWeapon(int client, int slot, int index = -1);