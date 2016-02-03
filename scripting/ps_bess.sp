#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#include <ps_natives>

#define PLUGIN_VERSION "1.7.1"
#define PS_ModuleName "\nBuy Extended Support Structure (BESS Module)"

#define MSGTAG "\x04[PS]\x01"

public Plugin:myinfo = 
{
	name = "[PS] Buy Extended Support Structure",
	author = "McFlurry && evilmaniac",
	description = "Module to extend buy support, example: !buy pills // this would buy you pills",
	version = PLUGIN_VERSION,
	url = "http://www.evilmania.net"
}

new Handle:h_Trie = null;

enum module_settings{
	Float:fVersion,
	Float:fMinLibraryVersion,
	Handle:hEnabled,
	bool:bModuleLoaded
}
new ModuleSettings[module_settings];

public initPluginSettings(){
	ModuleSettings[fVersion] = 1.71;
	ModuleSettings[fMinLibraryVersion] = 1.77;
	ModuleSettings[hEnabled] = CreateConVar("ps_bess_enable", "1", "Enable BESS Module", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ModuleSettings[bModuleLoaded] = false;
	return;
}

public registerConsoleCommands(){
	RegConsoleCmd("sm_buy", Cmd_Buy);
	return;
}

public bool:IsModuleActive(){
	if(GetConVarBool(ModuleSettings[hEnabled]))
		if(ModuleSettings[bModuleLoaded])
			if(PS_IsSystemEnabled())
				return true;
	return false;
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
		SetFailState("%T", "Game Check Fail", LANG_SERVER);
	else{
		h_Trie = CreateTrie();
		initPluginSettings();
		registerConsoleCommands();

		AutoExecConfig(true, "ps_bess");
		LoadTranslations("points_system.phrases");
	}
	return;
}

public OnAllPluginsLoaded(){
	if(LibraryExists("ps_natives")){
		if(PS_GetVersion() >= ModuleSettings[fMinLibraryVersion]){
			if(!PS_RegisterModule(PS_ModuleName)) // If module registeration has failed
				LogMessage("[PS] Plugin already registered.");
			else{
				SetUpBuyTrie();
				ModuleSettings[bModuleLoaded] = true;
				return;
			}
		}	
		else
			SetFailState("[PS] Outdated version of Points System installed.");
	}
	else
		SetFailState("[PS] PS Natives are not loaded.");

	return;
}

public OnPluginEnd(){
	PS_UnregisterModule(PS_ModuleName);
	CloseHandle(h_Trie);
	return;
}

public OnPSUnloaded(){
	ModuleSettings[bModuleLoaded] = false;
	return;
}	

public OnConfigsExecuted()
{
	UpdateBuyTrie();
}	

public SetUpBuyTrie()
{
	//health
	SetTrieString(h_Trie, "pills", "give pain_pills");
	SetTrieValue(h_Trie, "pillscost", GetConVarInt(FindConVar("l4d2_points_pills")));
	SetTrieString(h_Trie, "kit", "give first_aid_kit");
	SetTrieValue(h_Trie, "kitcost", GetConVarInt(FindConVar("l4d2_points_kit")));
	SetTrieString(h_Trie, "defib", "give defibrillator");
	SetTrieValue(h_Trie, "defibcost", GetConVarInt(FindConVar("l4d2_points_defib")));
	SetTrieString(h_Trie, "adren", "give adrenaline");
	SetTrieValue(h_Trie, "adrencost", GetConVarInt(FindConVar("l4d2_points_adrenaline")));
	SetTrieString(h_Trie, "fheal", "give health");
	SetTrieString(h_Trie, "heal", "give health");
	//SetTrieValue(h_Trie, "fhealcost", GetConVarInt(FindConVar(""))) inapplicable for fheal since cost is dependant on 2 different cvars for different teams
	//secondaries
	SetTrieString(h_Trie, "pistol", "give pistol");
	SetTrieValue(h_Trie, "pistolcost", GetConVarInt(FindConVar("l4d2_points_pistol")));
	SetTrieString(h_Trie, "magnum", "give pistol_magnum");
	SetTrieValue(h_Trie, "magnumcost", GetConVarInt(FindConVar("l4d2_points_magnum")));
	//smgs
	SetTrieString(h_Trie, "smg", "give smg");
	SetTrieValue(h_Trie, "smgcost", GetConVarInt(FindConVar("l4d2_points_smg")));
	SetTrieString(h_Trie, "ssmg", "give smg_silenced");
	SetTrieValue(h_Trie, "ssmgcost", GetConVarInt(FindConVar("l4d2_points_ssmg")));
	SetTrieString(h_Trie, "mp5", "give smg_mp5");
	SetTrieValue(h_Trie, "mp5cost", GetConVarInt(FindConVar("l4d2_points_mp5")));
	//rifles
	SetTrieString(h_Trie, "m16", "give rifle");
	SetTrieValue(h_Trie, "m16cost", GetConVarInt(FindConVar("l4d2_points_m16")));
	SetTrieString(h_Trie, "scar", "give rifle_desert");
	SetTrieValue(h_Trie, "scarcost", GetConVarInt(FindConVar("l4d2_points_scar")));
	SetTrieString(h_Trie, "ak", "give rifle_ak47");
	SetTrieValue(h_Trie, "akcost", GetConVarInt(FindConVar("l4d2_points_ak")));
	SetTrieString(h_Trie, "sg", "give rifle_sg552");
	SetTrieValue(h_Trie, "sgcost", GetConVarInt(FindConVar("l4d2_points_sg")));
	SetTrieString(h_Trie, "m60", "give rifle_m60");
	SetTrieValue(h_Trie, "m60cost", GetConVarInt(FindConVar("l4d2_points_m60")));
	//snipers
	SetTrieString(h_Trie, "huntrifle", "give hunting_rifle");
	SetTrieValue(h_Trie, "huntriflecost", GetConVarInt(FindConVar("l4d2_points_hunting_rifle")));
	SetTrieString(h_Trie, "scout", "give sniper_scout");
	SetTrieValue(h_Trie, "scoutcost", GetConVarInt(FindConVar("l4d2_points_scout")));
	SetTrieString(h_Trie, "milrifle", "give sniper_military");
	SetTrieValue(h_Trie, "milriflecost", GetConVarInt(FindConVar("l4d2_points_military_sniper")));
	SetTrieString(h_Trie, "awp", "give sniper_awp");
	SetTrieValue(h_Trie, "awpcost", GetConVarInt(FindConVar("l4d2_points_awp")));
	//shotguns
	SetTrieString(h_Trie, "chrome", "give shotgun_chrome");
	SetTrieValue(h_Trie, "chromecost", GetConVarInt(FindConVar("l4d2_points_chrome")));
	SetTrieString(h_Trie, "pump", "give pumpshotgun");
	SetTrieValue(h_Trie, "pumpcost", GetConVarInt(FindConVar("l4d2_points_pump")));
	SetTrieString(h_Trie, "spas", "give shotgun_spas");
	SetTrieValue(h_Trie, "spascost", GetConVarInt(FindConVar("l4d2_points_spas")));
	SetTrieString(h_Trie, "auto", "give autoshotgun");
	SetTrieValue(h_Trie, "autocost", GetConVarInt(FindConVar("l4d2_points_autoshotgun")));
	//throwables
	SetTrieString(h_Trie, "molly", "give molotov");
	SetTrieValue(h_Trie, "mollycost", GetConVarInt(FindConVar("l4d2_points_molotov")));
	SetTrieString(h_Trie, "pipe", "give pipe_bomb");
	SetTrieValue(h_Trie, "pipecost", GetConVarInt(FindConVar("l4d2_points_pipe")));
	SetTrieString(h_Trie, "bile", "give vomitjar");
	SetTrieValue(h_Trie, "bilecost", GetConVarInt(FindConVar("l4d2_points_bile")));
	//misc
	SetTrieString(h_Trie, "csaw", "give chainsaw");
	SetTrieValue(h_Trie, "csawcost", GetConVarInt(FindConVar("l4d2_points_chainsaw")));
	SetTrieString(h_Trie, "launcher", "give grenade_launcher");
	SetTrieValue(h_Trie, "launchercost", GetConVarInt(FindConVar("l4d2_points_grenade")));
	SetTrieString(h_Trie, "gnome", "give gnome");
	SetTrieValue(h_Trie, "gnomecost", GetConVarInt(FindConVar("l4d2_points_gnome")));
	SetTrieString(h_Trie, "cola", "give cola_bottles");
	SetTrieValue(h_Trie, "colacost", GetConVarInt(FindConVar("l4d2_points_cola")));
	SetTrieString(h_Trie, "gas", "give gascan");
	SetTrieValue(h_Trie, "gascost", GetConVarInt(FindConVar("l4d2_points_gascan")));
	SetTrieString(h_Trie, "propane", "give propanetank");
	SetTrieValue(h_Trie, "propanecost", GetConVarInt(FindConVar("l4d2_points_propane")));
	SetTrieString(h_Trie, "fworks", "give fireworkcrate");
	SetTrieValue(h_Trie, "fworkscost", GetConVarInt(FindConVar("l4d2_points_fireworks")));
	SetTrieString(h_Trie, "oxy", "give oxygentank");
	SetTrieValue(h_Trie, "oxycost", GetConVarInt(FindConVar("l4d2_points_oxygen")));
	//upgrades
	SetTrieString(h_Trie, "packex", "give upgradepack_explosive");
	SetTrieValue(h_Trie, "packexcost", GetConVarInt(FindConVar("l4d2_points_explosive_ammo_pack")));
	SetTrieString(h_Trie, "packin", "give upgradepack_incendiary");
	SetTrieValue(h_Trie, "packincost", GetConVarInt(FindConVar("l4d2_points_incendiary_ammo_pack")));
	SetTrieString(h_Trie, "ammo", "give ammo");
	SetTrieValue(h_Trie, "ammocost", GetConVarInt(FindConVar("l4d2_points_refill")));
	SetTrieString(h_Trie, "exammo", "upgrade_add EXPLOSIVE_AMMO");
	SetTrieValue(h_Trie, "exammocost", GetConVarInt(FindConVar("l4d2_points_explosive_ammo")));
	SetTrieString(h_Trie, "inammo", "upgrade_add INCENDIARY_AMMO");
	SetTrieValue(h_Trie, "inammocost", GetConVarInt(FindConVar("l4d2_points_incendiary_ammo")));
	SetTrieString(h_Trie, "laser", "upgrade_add LASER_SIGHT");
	SetTrieValue(h_Trie, "lasercost", GetConVarInt(FindConVar("l4d2_points_laser")));
	//melee
	SetTrieString(h_Trie, "cbar", "give crowbar");
	SetTrieValue(h_Trie, "cbarcost", GetConVarInt(FindConVar("l4d2_points_crowbar")));
	SetTrieString(h_Trie, "cbat", "give cricket_bat");
	SetTrieValue(h_Trie, "cbatcost", GetConVarInt(FindConVar("l4d2_points_cricketbat")));
	SetTrieString(h_Trie, "bat", "give baseball_bat");
	SetTrieValue(h_Trie, "batcost", GetConVarInt(FindConVar("l4d2_points_bat")));
	SetTrieString(h_Trie, "machete", "give machete");
	SetTrieValue(h_Trie, "machetecost", GetConVarInt(FindConVar("l4d2_points_machete")));
	SetTrieString(h_Trie, "tonfa", "give tonfa");
	SetTrieValue(h_Trie, "tonfacost", GetConVarInt(FindConVar("l4d2_points_tonfa")));
	SetTrieString(h_Trie, "katana", "give katana");
	SetTrieValue(h_Trie, "katanacost", GetConVarInt(FindConVar("l4d2_points_katana")));
	SetTrieString(h_Trie, "axe", "give fireaxe");
	SetTrieValue(h_Trie, "axecost", GetConVarInt(FindConVar("l4d2_points_fireaxe")));
	SetTrieString(h_Trie, "guitar", "give electric_guitar");
	SetTrieValue(h_Trie, "guitarcost", GetConVarInt(FindConVar("l4d2_points_guitar")));
	SetTrieString(h_Trie, "pan", "give frying_pan");
	SetTrieValue(h_Trie, "pancost", GetConVarInt(FindConVar("l4d2_points_pan")));
	SetTrieString(h_Trie, "club", "give golfclub");
	SetTrieValue(h_Trie, "clubcost", GetConVarInt(FindConVar("l4d2_points_golfclub")));
	//infected
	SetTrieString(h_Trie, "kill", "kill");
	SetTrieValue(h_Trie, "killcost", GetConVarInt(FindConVar("l4d2_points_suicide")));
	SetTrieString(h_Trie, "boomer", "z_spawn_old boomer auto");
	SetTrieValue(h_Trie, "boomercost", GetConVarInt(FindConVar("l4d2_points_boomer")));
	SetTrieString(h_Trie, "smoker", "z_spawn_old smoker auto");
	SetTrieValue(h_Trie, "smokercost", GetConVarInt(FindConVar("l4d2_points_smoker")));
	SetTrieString(h_Trie, "hunter", "z_spawn_old hunter auto");
	SetTrieValue(h_Trie, "huntercost", GetConVarInt(FindConVar("l4d2_points_hunter")));
	SetTrieString(h_Trie, "spitter", "z_spawn_old spitter auto");
	SetTrieValue(h_Trie, "spittercost", GetConVarInt(FindConVar("l4d2_points_spitter")));
	SetTrieString(h_Trie, "jockey", "z_spawn_old jockey auto");
	SetTrieValue(h_Trie, "jockeycost", GetConVarInt(FindConVar("l4d2_points_jockey")));
	SetTrieString(h_Trie, "charger", "z_spawn_old charger auto");
	SetTrieValue(h_Trie, "chargercost", GetConVarInt(FindConVar("l4d2_points_charger")));
	SetTrieString(h_Trie, "witch", "z_spawn_old witch auto");
	SetTrieValue(h_Trie, "witchcost", GetConVarInt(FindConVar("l4d2_points_witch")));
	SetTrieString(h_Trie, "bride", "z_spawn_old witch_bride auto");
	SetTrieValue(h_Trie, "bridecost", GetConVarInt(FindConVar("l4d2_points_witch")));
	SetTrieString(h_Trie, "tank", "z_spawn_old tank auto");
	SetTrieValue(h_Trie, "tankcost", GetConVarInt(FindConVar("l4d2_points_tank")));
	SetTrieString(h_Trie, "horde", "director_force_panic_event");
	SetTrieValue(h_Trie, "hordecost", GetConVarInt(FindConVar("l4d2_points_horde")));
	SetTrieString(h_Trie, "mob", "z_spawn_old mob auto");
	SetTrieValue(h_Trie, "mobcost", GetConVarInt(FindConVar("l4d2_points_mob")));
	SetTrieString(h_Trie, "umob", "z_spawn_old mob");
	SetTrieValue(h_Trie, "umobcost", GetConVarInt(FindConVar("l4d2_points_umob")));
}	

public UpdateBuyTrie()
{
	//health
	SetTrieValue(h_Trie, "pillscost", GetConVarInt(FindConVar("l4d2_points_pills")), true);
	SetTrieValue(h_Trie, "kitcost", GetConVarInt(FindConVar("l4d2_points_kit")), true);
	SetTrieValue(h_Trie, "defibcost", GetConVarInt(FindConVar("l4d2_points_defib")), true);
	SetTrieValue(h_Trie, "adrencost", GetConVarInt(FindConVar("l4d2_points_adrenaline")), true);
	//SetTrieValue(h_Trie, "fhealcost", GetConVarInt(FindConVar(""))) inapplicable for fheal since cost is dependant on 2 different cvars for different teams
	//secondaries
	SetTrieValue(h_Trie, "pistolcost", GetConVarInt(FindConVar("l4d2_points_pistol")), true);
	SetTrieValue(h_Trie, "magnumcost", GetConVarInt(FindConVar("l4d2_points_magnum")), true);
	//smgs
	SetTrieValue(h_Trie, "smgcost", GetConVarInt(FindConVar("l4d2_points_smg")), true);
	SetTrieValue(h_Trie, "ssmgcost", GetConVarInt(FindConVar("l4d2_points_ssmg")), true);
	SetTrieValue(h_Trie, "mp5cost", GetConVarInt(FindConVar("l4d2_points_mp5")), true);
	//rifles
	SetTrieValue(h_Trie, "m16cost", GetConVarInt(FindConVar("l4d2_points_m16")), true);
	SetTrieValue(h_Trie, "scarcost", GetConVarInt(FindConVar("l4d2_points_scar")), true);
	SetTrieValue(h_Trie, "akcost", GetConVarInt(FindConVar("l4d2_points_ak")), true);
	SetTrieValue(h_Trie, "sgcost", GetConVarInt(FindConVar("l4d2_points_sg")), true);
	SetTrieValue(h_Trie, "m60cost", GetConVarInt(FindConVar("l4d2_points_m60")), true);
	//snipers
	SetTrieValue(h_Trie, "huntriflecost", GetConVarInt(FindConVar("l4d2_points_hunting_rifle")), true);
	SetTrieValue(h_Trie, "scoutcost", GetConVarInt(FindConVar("l4d2_points_scout")), true);
	SetTrieValue(h_Trie, "milriflecost", GetConVarInt(FindConVar("l4d2_points_military_sniper")), true);
	SetTrieValue(h_Trie, "awpcost", GetConVarInt(FindConVar("l4d2_points_awp")), true);
	//shotguns
	SetTrieValue(h_Trie, "chromecost", GetConVarInt(FindConVar("l4d2_points_chrome")), true);
	SetTrieValue(h_Trie, "pumpcost", GetConVarInt(FindConVar("l4d2_points_pump")), true);
	SetTrieValue(h_Trie, "spascost", GetConVarInt(FindConVar("l4d2_points_spas")), true);
	SetTrieValue(h_Trie, "autocost", GetConVarInt(FindConVar("l4d2_points_autoshotgun")), true);
	//throwables
	SetTrieValue(h_Trie, "mollycost", GetConVarInt(FindConVar("l4d2_points_molotov")), true);
	SetTrieValue(h_Trie, "pipecost", GetConVarInt(FindConVar("l4d2_points_pipe")), true);
	SetTrieValue(h_Trie, "bilecost", GetConVarInt(FindConVar("l4d2_points_bile")), true);
	//misc
	SetTrieValue(h_Trie, "csawcost", GetConVarInt(FindConVar("l4d2_points_chainsaw")), true);
	SetTrieValue(h_Trie, "launchercost", GetConVarInt(FindConVar("l4d2_points_grenade")), true);
	SetTrieValue(h_Trie, "gnomecost", GetConVarInt(FindConVar("l4d2_points_gnome")), true);
	SetTrieValue(h_Trie, "colacost", GetConVarInt(FindConVar("l4d2_points_cola")), true);
	SetTrieValue(h_Trie, "gascost", GetConVarInt(FindConVar("l4d2_points_gascan")), true);
	SetTrieValue(h_Trie, "propanecost", GetConVarInt(FindConVar("l4d2_points_propane")), true);
	SetTrieValue(h_Trie, "fworkscost", GetConVarInt(FindConVar("l4d2_points_fireworks")), true);
	SetTrieValue(h_Trie, "oxycost", GetConVarInt(FindConVar("l4d2_points_oxygen")), true);
	//upgrades
	SetTrieValue(h_Trie, "packexcost", GetConVarInt(FindConVar("l4d2_points_explosive_ammo_pack")), true);
	SetTrieValue(h_Trie, "packincost", GetConVarInt(FindConVar("l4d2_points_incendiary_ammo_pack")), true);
	SetTrieValue(h_Trie, "ammocost", GetConVarInt(FindConVar("l4d2_points_refill")), true);
	SetTrieValue(h_Trie, "exammocost", GetConVarInt(FindConVar("l4d2_points_explosive_ammo")), true);
	SetTrieValue(h_Trie, "inammocost", GetConVarInt(FindConVar("l4d2_points_incendiary_ammo")), true);
	SetTrieValue(h_Trie, "lasercost", GetConVarInt(FindConVar("l4d2_points_laser")), true);
	//melee
	SetTrieValue(h_Trie, "cbarcost", GetConVarInt(FindConVar("l4d2_points_crowbar")), true);
	SetTrieValue(h_Trie, "cbatcost", GetConVarInt(FindConVar("l4d2_points_cricketbat")), true);
	SetTrieValue(h_Trie, "batcost", GetConVarInt(FindConVar("l4d2_points_bat")), true);
	SetTrieValue(h_Trie, "machetecost", GetConVarInt(FindConVar("l4d2_points_machete")), true);
	SetTrieValue(h_Trie, "tonfacost", GetConVarInt(FindConVar("l4d2_points_tonfa")), true);
	SetTrieValue(h_Trie, "katanacost", GetConVarInt(FindConVar("l4d2_points_katana")), true);
	SetTrieValue(h_Trie, "axecost", GetConVarInt(FindConVar("l4d2_points_fireaxe")), true);
	SetTrieValue(h_Trie, "guitarcost", GetConVarInt(FindConVar("l4d2_points_guitar")), true);
	SetTrieValue(h_Trie, "pancost", GetConVarInt(FindConVar("l4d2_points_pan")), true);
	SetTrieValue(h_Trie, "clubcost", GetConVarInt(FindConVar("l4d2_points_golfclub")), true);
	//infected
	SetTrieValue(h_Trie, "killcost", GetConVarInt(FindConVar("l4d2_points_suicide")), true);
	SetTrieValue(h_Trie, "boomercost", GetConVarInt(FindConVar("l4d2_points_boomer")), true);
	SetTrieValue(h_Trie, "smokercost", GetConVarInt(FindConVar("l4d2_points_smoker")), true);
	SetTrieValue(h_Trie, "huntercost", GetConVarInt(FindConVar("l4d2_points_hunter")), true);
	SetTrieValue(h_Trie, "spittercost", GetConVarInt(FindConVar("l4d2_points_spitter")), true);
	SetTrieValue(h_Trie, "jockeycost", GetConVarInt(FindConVar("l4d2_points_jockey")), true);
	SetTrieValue(h_Trie, "chargercost", GetConVarInt(FindConVar("l4d2_points_charger")), true);
	SetTrieValue(h_Trie, "witchcost", GetConVarInt(FindConVar("l4d2_points_witch")), true);
	SetTrieValue(h_Trie, "bridecost", GetConVarInt(FindConVar("l4d2_points_witch")), true);
	SetTrieValue(h_Trie, "tankcost", GetConVarInt(FindConVar("l4d2_points_tank")), true);
	SetTrieValue(h_Trie, "hordecost", GetConVarInt(FindConVar("l4d2_points_horde")), true);
	SetTrieValue(h_Trie, "mobcost", GetConVarInt(FindConVar("l4d2_points_mob")), true);
	SetTrieValue(h_Trie, "umobcost", GetConVarInt(FindConVar("l4d2_points_umob")), true);
}

public bool:checkDisabled(iCost){
	if(iCost <= -1)
		//PrintToChat(iClientIndex, "%s %T", MSGTAG, "Item Disabled", LANG_SERVER);
		return true;
	else return false;
}

public bool:hasEnoughPoints(iClientIndex, iCost){
	return(checkPoints(iClientIndex, iCost));
}

public bool:checkPoints(iClientIndex, iCost){
	if(PS_GetPoints(iClientIndex) >= iCost)
		return true;
	else{
		PrintToChat(iClientIndex, "%s %T", MSGTAG, "Insufficient Funds", LANG_SERVER);
		return false;
	}
}

public removePoints(iClientIndex, iPoints){
	PS_RemovePoints(iClientIndex, iPoints);
	return;
}

public Action:Cmd_Buy(iClientIndex, iNumArgs)
{
	if(iNumArgs != 1)
		return Plugin_Continue;

	if(!IsModuleActive() || !IsClientInGame(iClientIndex) || iClientIndex > MaxClients)
		return Plugin_Continue;

	if(!IsPlayerAlive(iClientIndex)){
		ReplyToCommand(iClientIndex, "[PS] Must Be Alive To Buy Items!");
		return Plugin_Continue;
	}	

	new String:arg[50];
	GetCmdArg(1, arg, sizeof(arg));
	new String:argval[100];
	if(!GetTrieString(h_Trie, arg, argval, sizeof(argval)))
	{
		return Plugin_Continue;
	}
	else
	{
		new iCost = -2; //-2 = invalid
		if(StrEqual(arg, "cola", false))
		{
			new String:map[100];
			GetCurrentMap(map, 100);
			if(StrEqual(map, "c1m2_streets", false))
			{
				PrintToChat(iClientIndex, "[PS] This item is unavailable during this map");
				return Plugin_Continue;
			}
		}
		if(StrEqual(arg, "fheal", false) || StrEqual(arg, "heal", false)){
			if(GetClientTeam(iClientIndex) == 3){ // If player is Infected
				iCost = GetConVarInt(FindConVar("l4d2_points_infected_heal"));

				if(IsClientTank(iClientIndex)) // If player is a Tank
					iCost *= GetConVarInt(FindConVar("l4d2_points_tank_heal_mult"));

				if(checkDisabled(iCost))
					return Plugin_Continue;

				performHeal(iClientIndex, iCost);	
				return Plugin_Continue;
			}	
			else if(GetClientTeam(iClientIndex) == 2){// If player is Survivor
				iCost = GetConVarInt(FindConVar("l4d2_points_survivor_heal"));
				if(checkDisabled(iCost))
					return Plugin_Continue;

				performHeal(iClientIndex, iCost);
				return Plugin_Continue;
			}	
		}
		if(StrEqual(arg, "kill", false) && GetClientTeam(iClientIndex) == 3){
			// Get Cost
			Format(arg, sizeof(arg), "%scost", arg);
			GetTrieValue(h_Trie, arg, iCost);

			if(checkDisabled(iCost))
				return Plugin_Continue;

			performSuicide(iClientIndex, iCost);
			return Plugin_Continue;
		}
		else if(StrEqual(arg, "umob", false) && GetClientTeam(iClientIndex) == 3)
		{
			Format(arg, sizeof(arg), "%scost", arg);
			GetTrieValue(h_Trie, arg, iCost);
			if(checkDisabled(iCost))
				return Plugin_Continue;
			PS_SetBoughtCost(iClientIndex, iCost);
			PS_SetBought(iClientIndex, argval);
			HandleUMob(iClientIndex);
		}
		else if(GetClientTeam(iClientIndex) > 1){ // If not a spectator
			Format(arg, sizeof(arg), "%scost", arg);
			GetTrieValue(h_Trie, arg, iCost);

			if(checkDisabled(iCost) || iCost == -2)
				return Plugin_Continue;
			else 
				performPurchase(iClientIndex, iCost, argval);
		}	
	}
	return Plugin_Continue;
}

public bool:IsCarryingWeapon(iClientIndex){
	new iWeapon = GetPlayerWeaponSlot(iClientIndex, 0);
	if(iWeapon == -1)
		return false;
	else return true;
}

public reloadAmmo(iClientIndex, iCost, const String:sItem[]){
	new hWeapon = GetPlayerWeaponSlot(iClientIndex, 0);
	if(IsCarryingWeapon(iClientIndex)){

		decl String:sWeapon[40]; sWeapon[0] = '\0';
		GetEdictClassname(hWeapon, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, "weapon_rifle_m60", false)){
			new iAmmo_m60 = 150;
			new Handle:hGunControl_m60 = FindConVar("l4d2_guncontrol_m60ammo");
			if(hGunControl_m60 != INVALID_HANDLE){
				iAmmo_m60 = GetConVarInt(hGunControl_m60);
				CloseHandle(hGunControl_m60);
			}
			SetEntProp(hWeapon, Prop_Data, "m_iClip1", iAmmo_m60, 1);
		}
		else if(StrEqual(sWeapon, "weapon_grenade_launcher", false)){
			new iAmmo_Launcher = 30;
			new Handle:hGunControl_Launcher = FindConVar("l4d2_guncontrol_grenadelauncherammo");
			if(hGunControl_Launcher != INVALID_HANDLE){
				iAmmo_Launcher = GetConVarInt(hGunControl_Launcher);
				CloseHandle(hGunControl_Launcher);
			}
			new uOffset = FindDataMapOffs(iClientIndex, "m_iAmmo");
			SetEntData(iClientIndex, uOffset + 68, iAmmo_Launcher);
		}
		execClientCommand(iClientIndex, sItem);
		removePoints(iClientIndex, iCost);
	}
	else
		PrintToChat(iClientIndex, "%s %T", MSGTAG, "Primary Warning", LANG_SERVER);
	return;
}

public setLastPurchase(iClientIndex, iCost, String:sItem[]){ // We are doing this so !repeatbuy works
	PS_SetItem(iClientIndex, sItem);
	PS_SetCost(iClientIndex, iCost);
	return;
}

public performPurchase(iClientIndex, iCost, String:sItem[]){ // sItem[] should be const
	if(iCost >= 0){
		if(hasEnoughPoints(iClientIndex, iCost)){
			if(StrEqual(sItem, "give ammo", false)){
				reloadAmmo(iClientIndex, iCost, sItem);
				setLastPurchase(iClientIndex, iCost, sItem);
			}
			else{
				execClientCommand(iClientIndex, sItem);
				removePoints(iClientIndex, iCost);
				setLastPurchase(iClientIndex, iCost, sItem);
			}
		}
	}
	return;
}

public performHeal(iClientIndex, iCost){
	if(iCost >= 0){
		if(hasEnoughPoints(iClientIndex, iCost)){
			execClientCommand(iClientIndex, "give health");
			SetEntPropFloat(iClientIndex, Prop_Send, "m_healthBuffer", 0.0);
			removePoints(iClientIndex, iCost);
		}
	}
	return;
}	

public bool:IsClientTank(iClientIndex){
	if(iClientIndex > 0){
		if(GetEntProp(iClientIndex, Prop_Send, "m_zombieClass") == 8)
			return true;
	}
	return false;
}

public performSuicide(iClientIndex, iCost){
	if(iCost >= 0){
		if(hasEnoughPoints(iClientIndex, iCost)){
			if(IsClientInGame(iClientIndex) && IsPlayerAlive(iClientIndex)){
				ForcePlayerSuicide(iClientIndex);
				if(IsClientTank(iClientIndex))
					return;
				else
				removePoints(iClientIndex, iCost);
			}
		}
	}
	return;
}

stock HandleUMob(iClientIndex)
{
	PS_SetCost(iClientIndex, PS_GetBoughtCost(iClientIndex));
	if(PS_GetCost(iClientIndex) > -1 && PS_GetPoints(iClientIndex) >= PS_GetCost(iClientIndex))
	{
		PS_SetupUMob(GetConVarInt(FindConVar("z_common_limit")));
		PS_SetItem(iClientIndex, "z_spawn_old mob");

		removePoints(iClientIndex, PS_GetCost(iClientIndex));

	}
	else if(checkDisabled(PS_GetCost(iClientIndex)))
		PS_SetBoughtCost(iClientIndex, PS_GetBoughtCost(iClientIndex));
	else
	{
		PS_SetBoughtCost(iClientIndex, PS_GetBoughtCost(iClientIndex));
		ReplyToCommand(iClientIndex, "%s %T", MSGTAG, "Insufficient Funds", LANG_SERVER);
	}	
}	

public execClientCommand(iClientIndex, const String:sCommand[]){
	RemoveFlags();
	FakeClientCommand(iClientIndex, sCommand);
	AddFlags();
	return;
}

RemoveFlags()
{
	new flagsgive = GetCommandFlags("give");
	new flagszspawn = GetCommandFlags("z_spawn_old");
	new flagsupgradeadd = GetCommandFlags("upgrade_add");
	new flagspanic = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn_old", flagszspawn & ~FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic & ~FCVAR_CHEAT);
	return;
}	

AddFlags()
{
	new flagsgive = GetCommandFlags("give");
	new flagszspawn = GetCommandFlags("z_spawn_old");
	new flagsupgradeadd = GetCommandFlags("upgrade_add");
	new flagspanic = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
	SetCommandFlags("z_spawn_old", flagszspawn|FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic|FCVAR_CHEAT);
	return;
}
