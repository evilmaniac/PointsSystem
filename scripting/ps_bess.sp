#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <ps_natives>

#define PLUGIN_VERSION "2.0.0"
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

enum module_settings{
	Float:fVersion,
	Float:fMinLibraryVersion,
	Handle:hVersion,
	Handle:hEnabled,
	bool:bModuleLoaded
}
new ModuleSettings[module_settings];

void initPluginSettings(){
	ModuleSettings[fVersion] = 2.00;
	ModuleSettings[fMinLibraryVersion] = 1.77;

	ModuleSettings[hVersion] = CreateConVar("em_ps_bess", PLUGIN_VERSION, "PS Bess version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	ModuleSettings[hEnabled] = CreateConVar("ps_bess_enable", "1", "Enable BESS Module", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ModuleSettings[bModuleLoaded] = false;
	return;
}

StringMap hItemMap = null;
StringMap hPriceMap = null;
StringMap hTeamExclusive = null;

void populateItemMap(){
	// Health Items
	hItemMap.SetString("pills", "give pain_pills", true);
	hItemMap.SetString("kit", "give first_aid_kit", true);
	hItemMap.SetString("defib", "give defibrillator", true);
	hItemMap.SetString("adren", "give adrenaline", true);
	hItemMap.SetString("fheal", "give health", true);
	hItemMap.SetString("heal", "give health", true);

	// Secondary Pistols
	hItemMap.SetString("pistol", "give pistol", true);
	hItemMap.SetString("magnum", "give pistol_magnum", true);

	// SMGs
	hItemMap.SetString("smg", "give smg", true);
	hItemMap.SetString("ssmg", "give smg_silenced", true);
	hItemMap.SetString("mp5", "give smg_mp5", true);

	// Rifles
	hItemMap.SetString("m16", "give rifle", true);
	hItemMap.SetString("scar", "give rifle_desert", true);
	hItemMap.SetString("ak", "give rifle_ak47", true);
	hItemMap.SetString("sg", "give rifle_sg552", true);
	hItemMap.SetString("m60", "give rifle_m60", true);

	// Sniper
	hItemMap.SetString("huntrifle", "give hunting_rifle", true);
	hItemMap.SetString("scout", "give sniper_scout", true);
	hItemMap.SetString("milrifle", "give sniper_military", true);
	hItemMap.SetString("awp", "give sniper_awp", true);

	// Shotguns
	hItemMap.SetString("chrome", "give shotgun_chrome", true);
	hItemMap.SetString("pump", "give pumpshotgun", true);
	hItemMap.SetString("spas", "give shotgun_spas", true);
	hItemMap.SetString("auto", "give autoshotgun", true);

	// Throwables
	hItemMap.SetString("molly", "give molotov", true);
	hItemMap.SetString("pipe", "give pipe_bomb", true);
	hItemMap.SetString("bile", "give vomitjar", true);

	// Misc
	hItemMap.SetString("csaw", "give chainsaw", true);
	hItemMap.SetString("launcher", "give grenade_launcher", true);
	hItemMap.SetString("gnome", "give gnome", true);
	hItemMap.SetString("cola", "give cola_bottles", true);
	hItemMap.SetString("gas", "give gascan", true);
	hItemMap.SetString("propane", "give propanetank", true);
	hItemMap.SetString("fworks", "give fireworkcrate", true);
	hItemMap.SetString("oxy", "give oxygentank", true);

	// Upgrades
	hItemMap.SetString("packex", "give upgradepack_explosive", true);
	hItemMap.SetString("packin", "give upgradepack_incendiary", true);
	hItemMap.SetString("ammo", "give ammo", true);
	hItemMap.SetString("exammo", "upgrade_add EXPLOSIVE_AMMO", true);
	hItemMap.SetString("inammo", "upgrade_add INCENDIARY_AMMO", true);
	hItemMap.SetString("laser", "upgrade_add LASER_SIGHT", true);

	// Melee
	hItemMap.SetString("cbar", "give crowbar", true);
	hItemMap.SetString("cbat", "give cricket_bat", true);
	hItemMap.SetString("bat", "give baseball_bat", true);
	hItemMap.SetString("machete", "give machete", true);
	hItemMap.SetString("tonfa", "give tonfa", true);
	hItemMap.SetString("katana", "give katana", true);
	hItemMap.SetString("axe", "give fireaxe", true);
	hItemMap.SetString("guitar", "give electric_guitar", true);
	hItemMap.SetString("pan", "give frying_pan", true);
	hItemMap.SetString("club", "give golfclub", true);

	// Infected
	hItemMap.SetString("kill", "kill", true);
	hItemMap.SetString("boomer", "z_spawn_old boomer auto", true);
	hItemMap.SetString("smoker", "z_spawn_old smoker auto", true);
	hItemMap.SetString("hunter", "z_spawn_old hunter auto", true);
	hItemMap.SetString("spitter", "z_spawn_old spitter auto", true);
	hItemMap.SetString("jockey", "z_spawn_old jockey auto", true);
	hItemMap.SetString("charger", "z_spawn_old charger auto", true);
	hItemMap.SetString("witch", "z_spawn_old witch auto", true);
	hItemMap.SetString("bride", "z_spawn_old witch_bride auto", true);
	hItemMap.SetString("tank", "z_spawn_old tank auto", true);
	hItemMap.SetString("horde", "director_force_panic_event", true);
	hItemMap.SetString("mob", "z_spawn_old mob auto", true);
	hItemMap.SetString("umob", "z_spawn_old mob", true);

	return;
}

void populatePriceMap(){
	// Health Items
	hPriceMap.SetValue("pills", FindConVar("l4d2_points_pills").IntValue, true);
	hPriceMap.SetValue("kit", FindConVar("l4d2_points_kit").IntValue, true);
	hPriceMap.SetValue("defib", FindConVar("l4d2_points_defib").IntValue, true);
	hPriceMap.SetValue("adren", FindConVar("l4d2_points_adrenaline").IntValue, true);

	// Secondary Pistols
	hPriceMap.SetValue("pistol", FindConVar("l4d2_points_pistol").IntValue, true);
	hPriceMap.SetValue("magnum", FindConVar("l4d2_points_magnum").IntValue, true);

	// SMGs
	hPriceMap.SetValue("smg", FindConVar("l4d2_points_smg").IntValue, true);
	hPriceMap.SetValue("ssmg", FindConVar("l4d2_points_ssmg").IntValue, true);
	hPriceMap.SetValue("mp5", FindConVar("l4d2_points_mp5").IntValue, true);

	// Rifles
	hPriceMap.SetValue("m16", FindConVar("l4d2_points_m16").IntValue, true);
	hPriceMap.SetValue("scar", FindConVar("l4d2_points_scar").IntValue, true);
	hPriceMap.SetValue("ak", FindConVar("l4d2_points_ak").IntValue, true);
	hPriceMap.SetValue("sg", FindConVar("l4d2_points_sg").IntValue, true);
	hPriceMap.SetValue("m60", FindConVar("l4d2_points_m60").IntValue, true);

	// Snipers
	hPriceMap.SetValue("huntrifle", FindConVar("l4d2_points_hunting_rifle").IntValue, true);
	hPriceMap.SetValue("scout", FindConVar("l4d2_points_scout").IntValue, true);
	hPriceMap.SetValue("milrifle", FindConVar("l4d2_points_military_sniper").IntValue, true);
	hPriceMap.SetValue("awp", FindConVar("l4d2_points_awp").IntValue, true);

	// Shotguns
	hPriceMap.SetValue("chrome", FindConVar("l4d2_points_chrome").IntValue, true);
	hPriceMap.SetValue("pump", FindConVar("l4d2_points_pump").IntValue, true);
	hPriceMap.SetValue("spas", FindConVar("l4d2_points_spas").IntValue, true);
	hPriceMap.SetValue("auto", FindConVar("l4d2_points_autoshotgun").IntValue, true);

	// Throwables
	hPriceMap.SetValue("molly", FindConVar("l4d2_points_molotov").IntValue, true);
	hPriceMap.SetValue("pipe", FindConVar("l4d2_points_pipe").IntValue, true);
	hPriceMap.SetValue("bile", FindConVar("l4d2_points_bile").IntValue, true);

	// Misc
	hPriceMap.SetValue("csaw", FindConVar("l4d2_points_chainsaw").IntValue, true);
	hPriceMap.SetValue("launcher", FindConVar("l4d2_points_grenade").IntValue, true);
	hPriceMap.SetValue("gnome", FindConVar("l4d2_points_gnome").IntValue, true);
	hPriceMap.SetValue("cola", FindConVar("l4d2_points_cola").IntValue, true);
	hPriceMap.SetValue("gas", FindConVar("l4d2_points_gascan").IntValue, true);
	hPriceMap.SetValue("propane", FindConVar("l4d2_points_propane").IntValue, true);
	hPriceMap.SetValue("fworks", FindConVar("l4d2_points_fireworks").IntValue, true);
	hPriceMap.SetValue("oxy", FindConVar("l4d2_points_oxygen").IntValue, true);

	// Upgrades
	hPriceMap.SetValue("packex", FindConVar("l4d2_points_explosive_ammo_pack").IntValue, true);
	hPriceMap.SetValue("packin", FindConVar("l4d2_points_incendiary_ammo_pack").IntValue, true);
	hPriceMap.SetValue("ammo", FindConVar("l4d2_points_refill").IntValue, true);
	hPriceMap.SetValue("exammo", FindConVar("l4d2_points_explosive_ammo").IntValue, true);
	hPriceMap.SetValue("inammo", FindConVar("l4d2_points_incendiary_ammo").IntValue, true);
	hPriceMap.SetValue("laser", FindConVar("l4d2_points_laser").IntValue, true);

	// Melee
	hPriceMap.SetValue("cbar", FindConVar("l4d2_points_crowbar").IntValue, true);
	hPriceMap.SetValue("cbat", FindConVar("l4d2_points_cricketbat").IntValue, true);
	hPriceMap.SetValue("bat", FindConVar("l4d2_points_bat").IntValue, true);
	hPriceMap.SetValue("machete", FindConVar("l4d2_points_machete").IntValue, true);
	hPriceMap.SetValue("tonfa", FindConVar("l4d2_points_tonfa").IntValue, true);
	hPriceMap.SetValue("katana", FindConVar("l4d2_points_katana").IntValue, true);
	hPriceMap.SetValue("axe", FindConVar("l4d2_points_fireaxe").IntValue, true);
	hPriceMap.SetValue("guitar", FindConVar("l4d2_points_guitar").IntValue, true);
	hPriceMap.SetValue("pan", FindConVar("l4d2_points_pan").IntValue, true);
	hPriceMap.SetValue("club", FindConVar("l4d2_points_golfclub").IntValue, true);

	// Infected
	hPriceMap.SetValue("kill", FindConVar("l4d2_points_suicide").IntValue, true);
	hPriceMap.SetValue("boomer", FindConVar("l4d2_points_boomer").IntValue, true);
	hPriceMap.SetValue("smoker", FindConVar("l4d2_points_smoker").IntValue, true);
	hPriceMap.SetValue("hunter", FindConVar("l4d2_points_hunter").IntValue, true);
	hPriceMap.SetValue("spitter", FindConVar("l4d2_points_spitter").IntValue, true);
	hPriceMap.SetValue("jockey", FindConVar("l4d2_points_jockey").IntValue, true);
	hPriceMap.SetValue("charger", FindConVar("l4d2_points_charger").IntValue, true);
	hPriceMap.SetValue("witch", FindConVar("l4d2_points_witch").IntValue, true);
	hPriceMap.SetValue("bride", FindConVar("l4d2_points_witch").IntValue, true);
	hPriceMap.SetValue("tank", FindConVar("l4d2_points_tank").IntValue, true);
	hPriceMap.SetValue("horde", FindConVar("l4d2_points_horde").IntValue, true);
	hPriceMap.SetValue("mob", FindConVar("l4d2_points_mob").IntValue, true);
	hPriceMap.SetValue("umob", FindConVar("l4d2_points_umob").IntValue, true);

	return;
}

void populateExclusiveItemsMap(){
	//  Infected Only
	hTeamExclusive.SetValue("kill", 3, true);
	hTeamExclusive.SetValue("boomer", 3, true);
	hTeamExclusive.SetValue("smoker", 3, true);
	hTeamExclusive.SetValue("hunter", 3, true);
	hTeamExclusive.SetValue("spitter", 3, true);
	hTeamExclusive.SetValue("jockey", 3, true);
	hTeamExclusive.SetValue("charger", 3, true);
	hTeamExclusive.SetValue("witch", 3, true);
	hTeamExclusive.SetValue("bride", 3, true);
	hTeamExclusive.SetValue("tank", 3, true);
	hTeamExclusive.SetValue("horde", 3, true);
	hTeamExclusive.SetValue("mob", 3, true);
	hTeamExclusive.SetValue("umob", 3, true);

	// Survivor Only
	hTeamExclusive.SetValue("laser", 2, true);
	hTeamExclusive.SetValue("packex", 2, true);
	hTeamExclusive.SetValue("packin", 2, true);
	hTeamExclusive.SetValue("exammo", 2, true);
	hTeamExclusive.SetValue("inammo", 2, true);

	return;
}

void buildMap(){
	hItemMap = new StringMap();
	hPriceMap = new StringMap();
	hTeamExclusive = new StringMap();

	populateItemMap();
	populatePriceMap();
	populateExclusiveItemsMap();
	return;
}

void registerConsoleCommands(){
	RegConsoleCmd("sm_buy", Cmd_Buy);
	return;
}

bool IsModuleActive(){
	if(GetConVarBool(ModuleSettings[hEnabled]))
		if(ModuleSettings[bModuleLoaded])
			if(PS_IsSystemEnabled())
				return true;
	return false;
}

public void OnPluginStart(){
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
		SetFailState("%T", "Game Check Fail", LANG_SERVER);
	else{
		initPluginSettings();
		registerConsoleCommands();

		AutoExecConfig(true, "ps_bess");
		LoadTranslations("points_system.phrases");
	}
	return;
}

public void OnAllPluginsLoaded(){
	if(LibraryExists("ps_natives")){
		if(PS_GetVersion() >= ModuleSettings[fMinLibraryVersion]){
			if(!PS_RegisterModule(PS_ModuleName)) // If module registeration has failed
				LogMessage("[PS] Plugin already registered.");
			else{
				buildMap();
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

public void OnPluginEnd(){
	PS_UnregisterModule(PS_ModuleName);

	hItemMap.Clear();
	hPriceMap.Clear();

	return;
}

public OnPSUnloaded(){
	ModuleSettings[bModuleLoaded] = false;
	return;
}

public void OnConfigsExecuted(){
	populatePriceMap();
	return;
}

bool IsClientSurvivor(int iClientIndex){
	if(iClientIndex > 0){
		if(GetClientTeam(iClientIndex) == 2) // Survivor
			return true;
	}
	return false;
}

bool IsClientInfected(int iClientIndex){
	if(iClientIndex > 0){
		if(GetClientTeam(iClientIndex) == 3) // Infected
			return true;
	}
	return false;
}

bool IsClientTank(iClientIndex){
	if(iClientIndex > 0){
		if(GetEntProp(iClientIndex, Prop_Send, "m_zombieClass") == 8)
			return true;
	}
	return false;
}

bool checkDisabled(int iCost){
	if(iCost <= -1)
		//PrintToChat(iClientIndex, "%s %T", MSGTAG, "Item Disabled", LANG_SERVER);
		return true;
	else return false;
}

bool checkPoints(int iClientIndex, int iCost){
	if(PS_GetPoints(iClientIndex) >= iCost)
		return true;
	else
		PrintToChat(iClientIndex, "%s %T", MSGTAG, "Insufficient Funds", LANG_SERVER);
	return false;
}

bool hasEnoughPoints(int iClientIndex, int iCost){
	return(checkPoints(iClientIndex, iCost));
}

void removePoints(int iClientIndex, int iPoints){
	PS_RemovePoints(iClientIndex, iPoints);
	return;
}

int getHealCost(int iClientIndex){
	int iCost = -1;
	if(IsClientInfected(iClientIndex)){
		iCost = FindConVar("l4d2_points_infected_heal").IntValue;

		if(IsClientTank(iClientIndex))
			iCost *= FindConVar("l4d2_points_tank_heal_mult").IntValue;
	}
	else if(IsClientSurvivor(iClientIndex))
		iCost = FindConVar("l4d2_points_survivor_heal").IntValue;

	return(iCost);
}

public Action Cmd_Buy(int iClientIndex, int iNumArgs){
	if(iNumArgs != 1)
		return Plugin_Continue;

	if(!IsModuleActive() || !IsClientInGame(iClientIndex) || iClientIndex > MaxClients)
		return Plugin_Continue;

	if(!IsPlayerAlive(iClientIndex)){
		ReplyToCommand(iClientIndex, "[PS] Must Be Alive To Buy Items!");
		return Plugin_Continue;
	}

	decl String:sPlayerInput[50]; sPlayerInput[0] = '\0';
	decl String:sPurchaseCmd[100]; sPurchaseCmd[0] = '\0';
	GetCmdArg(1, sPlayerInput, sizeof(sPlayerInput));

	if(hItemMap.GetString(sPlayerInput, sPurchaseCmd, sizeof(sPurchaseCmd))){ // If an entry exists
		int iRequiredTeam = 0;
		if(hTeamExclusive.GetValue(sPlayerInput, iRequiredTeam))
			if(GetClientTeam(iClientIndex) != iRequiredTeam)
				return Plugin_Continue;

		int iCost = -2; //-2 = invalid
		if(StrEqual(sPlayerInput, "cola", false)){
			decl String:sMapName[100]; sMapName[0] = '\0';

			GetCurrentMap(sMapName, 100);
			if(StrEqual(sMapName, "c1m2_streets", false))
				PrintToChat(iClientIndex, "[PS] This item is unavailable during this map");
		}
		else if(StrEqual(sPlayerInput, "fheal", false) || StrEqual(sPlayerInput, "heal", false)){
			iCost = getHealCost(iClientIndex);
			if(!checkDisabled(iCost))
				performHeal(iClientIndex, iCost);
			return Plugin_Continue;
		}
		else{ // If not a special case
			if(hPriceMap.GetValue(sPlayerInput, iCost) && !checkDisabled(iCost)){
				if(StrEqual(sPlayerInput, "kill", false) && IsClientInfected(iClientIndex))
					performSuicide(iClientIndex, iCost);
				else if(StrEqual(sPlayerInput, "umob", false) && IsClientInfected(iClientIndex)){
					PS_SetBoughtCost(iClientIndex, iCost);
					PS_SetBought(iClientIndex, sPurchaseCmd);
					HandleUMob(iClientIndex);
				}
				else if(GetClientTeam(iClientIndex) > 1) // If not a spectator
					performPurchase(iClientIndex, iCost, sPurchaseCmd);
			}
		}
	}
	return Plugin_Continue;
}

bool IsCarryingWeapon(int iClientIndex){
	int iWeapon = GetPlayerWeaponSlot(iClientIndex, 0);
	if(iWeapon == -1)
		return false;
	else return true;
}

public reloadAmmo(int iClientIndex, int iCost, const char[] sItem){
	int hWeapon = GetPlayerWeaponSlot(iClientIndex, 0);
	if(IsCarryingWeapon(iClientIndex)){

		decl String:sWeapon[40]; sWeapon[0] = '\0';
		GetEdictClassname(hWeapon, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, "weapon_rifle_m60", false)){
			int iAmmo_m60 = 150;
			new Handle:hGunControl_m60 = FindConVar("l4d2_guncontrol_m60ammo");
			if(hGunControl_m60 != null){
				iAmmo_m60 = GetConVarInt(hGunControl_m60);
				CloseHandle(hGunControl_m60);
			}
			SetEntProp(hWeapon, Prop_Data, "m_iClip1", iAmmo_m60, 1);
		}
		else if(StrEqual(sWeapon, "weapon_grenade_launcher", false)){
			int iAmmo_Launcher = 30;
			Handle hGunControl_Launcher = FindConVar("l4d2_guncontrol_grenadelauncherammo");
			if(hGunControl_Launcher != null){
				iAmmo_Launcher = GetConVarInt(hGunControl_Launcher);
				CloseHandle(hGunControl_Launcher);
			}
			int uOffset = FindDataMapOffs(iClientIndex, "m_iAmmo");
			SetEntData(iClientIndex, uOffset + 68, iAmmo_Launcher);
		}
		execClientCommand(iClientIndex, sItem);
		removePoints(iClientIndex, iCost);
	}
	else
		PrintToChat(iClientIndex, "%s %T", MSGTAG, "Primary Warning", LANG_SERVER);
	return;
}

void setLastPurchase(int iClientIndex, int iCost, const char[] sPurchaseCmd){ // We are doing this so !repeatbuy works
	PS_SetItem(iClientIndex, sPurchaseCmd);
	PS_SetCost(iClientIndex, iCost);
	return;
}

void performPurchase(int iClientIndex, int iCost, const char[] sPurchaseCmd){ // sItem[] should be const
	if(iCost >= 0){
		if(hasEnoughPoints(iClientIndex, iCost)){
			if(StrEqual(sPurchaseCmd, "give ammo", false)){
				reloadAmmo(iClientIndex, iCost, sPurchaseCmd);
				setLastPurchase(iClientIndex, iCost, sPurchaseCmd);
			}
			else{
				execClientCommand(iClientIndex, sPurchaseCmd);
				removePoints(iClientIndex, iCost);
				setLastPurchase(iClientIndex, iCost, sPurchaseCmd);
			}
		}
	}
	return;
}

void performHeal(int iClientIndex, int iCost){
	if(iCost >= 0){
		if(hasEnoughPoints(iClientIndex, iCost)){
			execClientCommand(iClientIndex, "give health");
			SetEntPropFloat(iClientIndex, Prop_Send, "m_healthBuffer", 0.0);
			removePoints(iClientIndex, iCost);
		}
	}
	return;
}

void performSuicide(int iClientIndex, int iCost){
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

void execClientCommand(int iClientIndex, const char[] sCommand){
	RemoveFlags();
	FakeClientCommand(iClientIndex, sCommand);
	AddFlags();
	return;
}

void RemoveFlags(){
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

void AddFlags(){
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
