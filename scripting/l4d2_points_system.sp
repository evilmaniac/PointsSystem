#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_TITLE "1.7.7"

#define MSGTAG "\x04[PS]\x01"
#define MSGTAG2 "\x04[PS]\x01 "
#define MODULES_SIZE 100

new Handle:ModulesArray = null;
new Handle:Forward1 = null;
new Handle:Forward2 = null;

enum plugin_settings{
	Float:fVersion,
	iStringSize,
	Handle:hEnabled,
	Handle:hModes,
	Handle:hNotifications,
	Handle:hKillSpreeNum,
	Handle:hHeadShotNum,
	Handle:hTankLimit,
	Handle:hWitchLimit,
	Handle:hResetPoints,
	Handle:hStartPoints,
	Handle:hSpawnAttempts
}
new PluginSettings[plugin_settings];

initPluginSettings(){
	PluginSettings[fVersion] = 1.77;
	PluginSettings[iStringSize] = 64;

	PluginSettings[hStartPoints] = CreateConVar("l4d2_points_start", "10", "Points to start each round/map with.", FCVAR_PLUGIN);
	PluginSettings[hNotifications] = CreateConVar("l4d2_points_notify", "1", "Show messages when points are earned?", FCVAR_PLUGIN);
	PluginSettings[hEnabled] = CreateConVar("l4d2_points_enable", "1", "Enable Point System?", FCVAR_PLUGIN);
	PluginSettings[hModes] = CreateConVar("l4d2_points_modes", "coop,realism,versus,teamversus", "Which game modes to use Point System", FCVAR_PLUGIN);
	PluginSettings[hResetPoints] = CreateConVar("l4d2_points_reset_mapchange", "", "Which game modes to reset point count on round end and round start", FCVAR_PLUGIN);
	PluginSettings[hTankLimit] = CreateConVar("l4d2_points_tank_limit", "2", "How many tanks to be allowed spawned per team", FCVAR_PLUGIN);
	PluginSettings[hWitchLimit] = CreateConVar("l4d2_points_witch_limit", "3", "How many witchs' to be allwed spawned per team", FCVAR_PLUGIN);
	PluginSettings[hSpawnAttempts] = CreateConVar("l4d2_points_spawn_tries", "2", "How many times to attempt respawning when buying an special infected", FCVAR_PLUGIN);
	PluginSettings[hKillSpreeNum] = CreateConVar("l4d2_points_cikills", "25", "How many kills you need to earn a killing spree bounty", FCVAR_PLUGIN);
	PluginSettings[hHeadShotNum] = CreateConVar("l4d2_points_headshots", "20", "How many kills you need to earn a head hunter bonus", FCVAR_PLUGIN);
	return;
}

enum plugin_sprites{
	BeamSprite,
	HaloSprite
}
new PluginSprites[plugin_sprites];

initPluginSprites(){
	PluginSprites[BeamSprite] = PrecacheModel("sprites/laserbeam.vmt");
	PluginSprites[HaloSprite] = PrecacheModel("sprites/glow01.vmt");
	return;
}

enum player_data{
	bool:bMessageSent, // Whether welcome message has been displayed to player or not
	bool:bPointsLoaded, // Whether a player's points have been loaded from the Clientprefs database
	bool:bWitchBurning, // Whether a player has ignited a witch on fire or not
	bool:bTankBurning, // Whether a player has ignited a tank on fire or not
	String:sBought[64], // Last purchased item (redundant)
	String:sItemName[64], // The item the player intends to purchase
	iBoughtCost, // Cost of last purchased item (redundant)
	iItemCost, // The cost of an item the player intends to purchase
	iPlayerPoints, // Amount of spendable points
	iProtectCount, // Number of times player has protected a team mate
	iKillCount, // Kills made as a survivor
	iHeadShotCount, // Headshots dealt to infected as a survivor
	iHurtCount // Damage dealt to survivors while infected
}
new PlayerData[MAXPLAYERS][player_data];

initPlayerData(iClientIndex){
	if(iClientIndex < MAXPLAYERS){
		PlayerData[iClientIndex][bMessageSent] 		= false;
		PlayerData[iClientIndex][bPointsLoaded] 	= false;
		PlayerData[iClientIndex][bWitchBurning] 	= false;
		PlayerData[iClientIndex][bTankBurning] 		= false;

		PlayerData[iClientIndex][iBoughtCost]		= 0;
		PlayerData[iClientIndex][iItemCost] 		= 0;
		PlayerData[iClientIndex][iPlayerPoints] 	= 0;
		PlayerData[iClientIndex][iProtectCount] 	= 0;
		PlayerData[iClientIndex][iKillCount] 		= 0;
		PlayerData[iClientIndex][iHeadShotCount] 	= 0;
		PlayerData[iClientIndex][iHurtCount] 		= 0;
		initPlayerData(++iClientIndex);
	}
	return;
}

public initAllPlayerData(){
	initPlayerData(1);
	return;
}

enum counter_data{
	iTanksSpawned,
	iWitchesSpawned,
	iUCommonLeft,
}
new CounterData[counter_data];

initCounterData(){
	CounterData[iTanksSpawned] = 0;
	CounterData[iWitchesSpawned] = 0;
	return;
}

enum item_costs{
	Handle:CostPistol,
	Handle:CostMagnum,
	Handle:CostSMG,
	Handle:CostSilencedSMG,
	Handle:CostMP5,
	Handle:CostM16,
	Handle:CostAK47,
	Handle:CostSCAR,
	Handle:CostSG552,
	Handle:CostHunting,
	Handle:CostMilitary,
	Handle:CostAWP,
	Handle:CostScout,
	Handle:CostAuto,
	Handle:CostSPAS,
	Handle:CostChrome,
	Handle:CostPump,
	Handle:CostLauncher,
	Handle:CostM60,
	Handle:CostGasCan,
	Handle:CostOxygen,
	Handle:CostPropane,
	Handle:CostGnome,
	Handle:CostCola,
	Handle:CostFireworks,
	Handle:CostBat,
	Handle:CostMachete,
	Handle:CostKatana,
	Handle:CostKnife,
	Handle:CostShield,
	Handle:CostTonfa,
	Handle:CostFireAxe,
	Handle:CostGuitar,
	Handle:CostPan,
	Handle:CostCricketBat,
	Handle:CostCrowBar,
	Handle:CostClub,
	Handle:CostChainSaw,
	Handle:CostPipe,
	Handle:CostMolotov,
	Handle:CostBile,
	Handle:CostHealthKit,
	Handle:CostDefib,
	Handle:CostAdren,
	Handle:CostPills,
	Handle:CostExplosiveAmmo,
	Handle:CostFireAmmo,
	Handle:CostExplosivePack,
	Handle:CostFirePack,
	Handle:CostLaserSight,
	Handle:CostAmmo,
	Handle:CostHeal,
	Handle:CostSuicide,
	Handle:CostHunter,
	Handle:CostJockey,
	Handle:CostSmoker,
	Handle:CostCharger,
	Handle:CostBoomer,
	Handle:CostSpitter,
	Handle:CostInfectedHeal,
	Handle:CostWitch,
	Handle:CostTank,
	Handle:CostTankHealMultiplier,
	Handle:CostHorde,
	Handle:CostMob,
	Handle:CostUncommonMob,
}
new ItemCosts[item_costs];

initItemCosts(){
	ItemCosts[CostPistol] = CreateConVar("l4d2_points_pistol", "4", "How many points the pistol costs", FCVAR_PLUGIN);
	ItemCosts[CostMagnum] = CreateConVar("l4d2_points_magnum", "6", "How many points the magnum costs", FCVAR_PLUGIN);
	ItemCosts[CostSMG] = CreateConVar("l4d2_points_smg", "7", "How many points the smg costs", FCVAR_PLUGIN);
	ItemCosts[CostSilencedSMG] = CreateConVar("l4d2_points_ssmg", "7", "How many points the silenced smg costs", FCVAR_PLUGIN);
	ItemCosts[CostMP5] = CreateConVar("l4d2_points_mp5", "7", "How many points the mp5 costs", FCVAR_PLUGIN);
	ItemCosts[CostM16] = CreateConVar("l4d2_points_m16", "12", "How many points the m16 costs", FCVAR_PLUGIN);
	ItemCosts[CostAK47] = CreateConVar("l4d2_points_ak", "12", "How many points the ak47 costs", FCVAR_PLUGIN);
	ItemCosts[CostSCAR] = CreateConVar("l4d2_points_scar", "12", "How many points the scar costs", FCVAR_PLUGIN);
	ItemCosts[CostSG552] = CreateConVar("l4d2_points_sg", "12", "How many points the sg552 costs", FCVAR_PLUGIN);
	ItemCosts[CostMilitary] = CreateConVar("l4d2_points_military_sniper", "14", "How many points the military sniper costs", FCVAR_PLUGIN);
	ItemCosts[CostAWP] = CreateConVar("l4d2_points_awp", "15", "How many points the awp costs", FCVAR_PLUGIN);
	ItemCosts[CostScout] = CreateConVar("l4d2_points_scout", "10", "How many points the scout sniper costs", FCVAR_PLUGIN);
	ItemCosts[CostHunting] = CreateConVar("l4d2_points_hunting_rifle", "10", "How many points the hunting rifle costs", FCVAR_PLUGIN);
	ItemCosts[CostAuto] = CreateConVar("l4d2_points_autoshotgun", "10", "How many points the autoshotgun costs", FCVAR_PLUGIN);
	ItemCosts[CostSPAS] = CreateConVar("l4d2_points_spas", "10", "How many points the spas shotgun costs", FCVAR_PLUGIN);
	ItemCosts[CostChrome] = CreateConVar("l4d2_points_chrome", "7", "How many points the chrome shotgun costs", FCVAR_PLUGIN);
	ItemCosts[CostPump] = CreateConVar("l4d2_points_pump", "7", "How many points the pump shotgun costs", FCVAR_PLUGIN);
	ItemCosts[CostLauncher] = CreateConVar("l4d2_points_grenade", "15", "How many points the grenade launcher costs", FCVAR_PLUGIN);
	ItemCosts[CostM60] = CreateConVar("l4d2_points_m60", "50", "How many points the m60 costs", FCVAR_PLUGIN);
	ItemCosts[CostGasCan] = CreateConVar("l4d2_points_gascan", "5", "How many points the gas can costs", FCVAR_PLUGIN);
	ItemCosts[CostOxygen] = CreateConVar("l4d2_points_oxygen", "2", "How many points the oxgen tank costs", FCVAR_PLUGIN);
	ItemCosts[CostPropane] = CreateConVar("l4d2_points_propane", "2", "How many points the propane tank costs", FCVAR_PLUGIN);
	ItemCosts[CostGnome] = CreateConVar("l4d2_points_gnome", "8", "How many points the gnome costs", FCVAR_PLUGIN);
	ItemCosts[CostCola] = CreateConVar("l4d2_points_cola", "8", "How many points cola bottles costs", FCVAR_PLUGIN);
	ItemCosts[CostFireworks] = CreateConVar("l4d2_points_fireworks", "2", "How many points the fireworks crate costs", FCVAR_PLUGIN);
	ItemCosts[CostBat] = CreateConVar("l4d2_points_bat", "4", "How many points the baseball bat costs", FCVAR_PLUGIN);
	ItemCosts[CostMachete] = CreateConVar("l4d2_points_machete", "6", "How many points the machete costs", FCVAR_PLUGIN);
	ItemCosts[CostKatana] = CreateConVar("l4d2_points_katana", "6", "How many points the katana costs", FCVAR_PLUGIN);
	ItemCosts[CostKnife] = CreateConVar("l4d2_points_knife", "6", "How many points the knife costs", FCVAR_PLUGIN);
	ItemCosts[CostShield] = CreateConVar("l4d2_points_shield", "6", "How many points the shield costs", FCVAR_PLUGIN);
	ItemCosts[CostTonfa] = CreateConVar("l4d2_points_tonfa", "4", "How many points the tonfa costs", FCVAR_PLUGIN);
	ItemCosts[CostFireAxe] = CreateConVar("l4d2_points_fireaxe", "4", "How many points the fireaxe costs", FCVAR_PLUGIN);
	ItemCosts[CostGuitar] = CreateConVar("l4d2_points_guitar", "4", "How many points the guitar costs", FCVAR_PLUGIN);
	ItemCosts[CostPan] = CreateConVar("l4d2_points_pan", "4", "How many points the frying pan costs", FCVAR_PLUGIN);
	ItemCosts[CostCricketBat] = CreateConVar("l4d2_points_cricketbat", "4", "How many points the cricket bat costs", FCVAR_PLUGIN);
	ItemCosts[CostCrowBar] = CreateConVar("l4d2_points_crowbar", "4", "How many points the crowbar costs", FCVAR_PLUGIN);
	ItemCosts[CostClub] = CreateConVar("l4d2_points_golfclub", "6", "How many points the golf club costs", FCVAR_PLUGIN);
	ItemCosts[CostChainSaw] = CreateConVar("l4d2_points_chainsaw", "10", "How many points the chainsaw costs", FCVAR_PLUGIN);
	ItemCosts[CostPipe] = CreateConVar("l4d2_points_pipe", "8", "How many points the pipe bomb costs", FCVAR_PLUGIN);
	ItemCosts[CostMolotov] = CreateConVar("l4d2_points_molotov", "8", "How many points the molotov costs", FCVAR_PLUGIN);
	ItemCosts[CostBile] = CreateConVar("l4d2_points_bile", "8", "How many points the bile jar costs", FCVAR_PLUGIN);
	ItemCosts[CostHealthKit] = CreateConVar("l4d2_points_kit", "20", "How many points the health kit costs", FCVAR_PLUGIN);
	ItemCosts[CostDefib] = CreateConVar("l4d2_points_defib", "20", "How many points the defib costs", FCVAR_PLUGIN);
	ItemCosts[CostAdren] = CreateConVar("l4d2_points_adrenaline", "10", "How many points the adrenaline costs", FCVAR_PLUGIN);
	ItemCosts[CostPills] = CreateConVar("l4d2_points_pills", "10", "How many points the pills costs", FCVAR_PLUGIN);
	ItemCosts[CostExplosiveAmmo] = CreateConVar("l4d2_points_explosive_ammo", "10", "How many points the explosive ammo costs", FCVAR_PLUGIN);
	ItemCosts[CostFireAmmo] = CreateConVar("l4d2_points_incendiary_ammo", "10", "How many points the incendiary ammo costs", FCVAR_PLUGIN);
	ItemCosts[CostExplosivePack] = CreateConVar("l4d2_points_explosive_ammo_pack", "15", "How many points the explosive ammo pack costs", FCVAR_PLUGIN);
	ItemCosts[CostFirePack] = CreateConVar("l4d2_points_incendiary_ammo_pack", "15", "How many points the incendiary ammo pack costs", FCVAR_PLUGIN);
	ItemCosts[CostLaserSight] = CreateConVar("l4d2_points_laser", "10", "How many points the laser sight costs", FCVAR_PLUGIN);
	ItemCosts[CostHeal] = CreateConVar("l4d2_points_survivor_heal", "25", "How many points a complete heal costs", FCVAR_PLUGIN);
	ItemCosts[CostAmmo] = CreateConVar("l4d2_points_refill", "8", "How many points an ammo refill costs", FCVAR_PLUGIN);

	ItemCosts[CostSuicide] = CreateConVar("l4d2_points_suicide", "4", "How many points does suicide cost", FCVAR_PLUGIN);
	ItemCosts[CostHunter] = CreateConVar("l4d2_points_hunter", "4", "How many points does a hunter cost", FCVAR_PLUGIN);
	ItemCosts[CostJockey] = CreateConVar("l4d2_points_jockey", "6", "How many points does a jockey cost", FCVAR_PLUGIN);
	ItemCosts[CostSmoker] = CreateConVar("l4d2_points_smoker", "4", "How many points does a smoker cost", FCVAR_PLUGIN);
	ItemCosts[CostCharger] = CreateConVar("l4d2_points_charger", "6", "How many points does a charger cost", FCVAR_PLUGIN);
	ItemCosts[CostBoomer] = CreateConVar("l4d2_points_boomer", "5", "How many points does a boomer cost", FCVAR_PLUGIN);
	ItemCosts[CostSpitter] = CreateConVar("l4d2_points_spitter", "6", "How many points does a spitter cost", FCVAR_PLUGIN);
	ItemCosts[CostInfectedHeal] = CreateConVar("l4d2_points_infected_heal", "6", "How many points does healing yourself as an infected cost", FCVAR_PLUGIN);
	ItemCosts[CostWitch] = CreateConVar("l4d2_points_witch", "20", "How many points does a witch cost", FCVAR_PLUGIN);
	ItemCosts[CostTank] = CreateConVar("l4d2_points_tank", "30", "How many points does a tank cost", FCVAR_PLUGIN);
	ItemCosts[CostTankHealMultiplier] = CreateConVar("l4d2_points_tank_heal_mult", "3", "How much l4d2_points_infected_heal should be multiplied for tank players", FCVAR_PLUGIN);
	ItemCosts[CostHorde] = CreateConVar("l4d2_points_horde", "15", "How many points does a horde cost", FCVAR_PLUGIN);
	ItemCosts[CostMob] = CreateConVar("l4d2_points_mob", "10", "How many points does a mob cost", FCVAR_PLUGIN);
	ItemCosts[CostUncommonMob] = CreateConVar("l4d2_points_umob", "12", "How many points does an uncommon mob cost", FCVAR_PLUGIN);
	return;
}

enum categories_enabled{
	Handle:CategoryRifles,
	Handle:CategorySMG,
	Handle:CategorySnipers,
	Handle:CategoryShotguns,
	Handle:CategoryHealth,
	Handle:CategoryUpgrades,
	Handle:CategoryThrowables,
	Handle:CategoryMisc,
	Handle:CategoryMelee,
	Handle:CategoryWeapons
}
new CategoriesEnabled[categories_enabled];

initCategoriesEnabled(){
	CategoriesEnabled[CategoryRifles] = CreateConVar("l4d2_points_cat_rifles", "1", "Enable rifles catergory", FCVAR_PLUGIN);
	CategoriesEnabled[CategorySMG] = CreateConVar("l4d2_points_cat_smg", "1", "Enable smg catergory", FCVAR_PLUGIN);
	CategoriesEnabled[CategorySnipers] = CreateConVar("l4d2_points_cat_snipers", "1", "Enable snipers catergory", FCVAR_PLUGIN);
	CategoriesEnabled[CategoryShotguns] = CreateConVar("l4d2_points_cat_shotguns", "1", "Enable shotguns catergory", FCVAR_PLUGIN);
	CategoriesEnabled[CategoryHealth] = CreateConVar("l4d2_points_cat_health", "1", "Enable health catergory", FCVAR_PLUGIN);
	CategoriesEnabled[CategoryUpgrades] = CreateConVar("l4d2_points_cat_upgrades", "1", "Enable upgrades catergory", FCVAR_PLUGIN);
	CategoriesEnabled[CategoryThrowables] = CreateConVar("l4d2_points_cat_throwables", "1", "Enable throwables catergory", FCVAR_PLUGIN);
	CategoriesEnabled[CategoryMisc] = CreateConVar("l4d2_points_cat_misc", "1", "Enable misc catergory", FCVAR_PLUGIN);
	CategoriesEnabled[CategoryMelee] = CreateConVar("l4d2_points_cat_melee", "1", "Enable melee catergory", FCVAR_PLUGIN);
	CategoriesEnabled[CategoryWeapons] = CreateConVar("l4d2_points_cat_weapons", "1", "Enable weapons catergory", FCVAR_PLUGIN);
	return;
}

enum point_rewards{
	Handle:SurvRewardKillSpree,
	Handle:SurvRewardHeadShots,
	Handle:SurvKillInfec,
	Handle:SurvKillTank,
	Handle:SurvKillWitch,
	Handle:SurvCrownWitch,
	Handle:SurvTeamHeal,
	Handle:SurvTeamHealFarm,
	Handle:SurvTeamProtect,
	Handle:SurvTeamRevive,
	Handle:SurvTeamLedge,
	Handle:SurvTeamDefib,
	Handle:SurvBurnTank,
	Handle:SurvBileTank,
	Handle:SurvBurnWitch,
	Handle:SurvTankSolo,
	Handle:InfecChokeSurv,
	Handle:InfecPounceSurv,
	Handle:InfecChargeSurv,
	Handle:InfecImpactSurv,
	Handle:InfecRideSurv,
	Handle:InfecBoomSurv,
	Handle:InfecIncapSurv,
	Handle:InfecHurtSurv,
	Handle:InfecKillSurv
}
new PointRewards[point_rewards];

initPointRewards(){
	PointRewards[SurvRewardKillSpree] = CreateConVar("l4d2_points_cikill_value", "2", "How many points does killing a certain amount of infected earn", FCVAR_PLUGIN);
	PointRewards[SurvRewardHeadShots] = CreateConVar("l4d2_points_headshots_value", "4", "How many points does killing a certain amount of infected with headshots earn", FCVAR_PLUGIN);
	PointRewards[SurvKillInfec] = CreateConVar("l4d2_points_sikill", "1", "How many points does killing a special infected earn", FCVAR_PLUGIN);
	PointRewards[SurvKillTank] = CreateConVar("l4d2_points_tankkill", "2", "How many points does killing a tank earn", FCVAR_PLUGIN);
	PointRewards[SurvKillWitch] = CreateConVar("l4d2_points_witchkill", "4", "How many points does killing a witch earn", FCVAR_PLUGIN);
	PointRewards[SurvCrownWitch] = CreateConVar("l4d2_points_witchcrown", "2", "How many points does crowning a witch earn", FCVAR_PLUGIN);
	PointRewards[SurvTeamHeal] = CreateConVar("l4d2_points_heal", "5", "How many points does healing a team mate earn", FCVAR_PLUGIN);
	PointRewards[SurvTeamHealFarm] = CreateConVar("l4d2_points_heal_warning", "1", "How many points does healing a team mate who did not need healing earn", FCVAR_PLUGIN);
	PointRewards[SurvTeamProtect] = CreateConVar("l4d2_points_protect", "1", "How many points does protecting a team mate earn", FCVAR_PLUGIN);
	PointRewards[SurvTeamRevive] = CreateConVar("l4d2_points_revive", "3", "How many points does reviving a team mate earn", FCVAR_PLUGIN);
	PointRewards[SurvTeamLedge] = CreateConVar("l4d2_points_ledge", "1", "How many points does reviving a hanging team mate earn", FCVAR_PLUGIN);
	PointRewards[SurvTeamDefib] = CreateConVar("l4d2_points_defib_action", "5", "How many points does defibbing a team mate earn", FCVAR_PLUGIN);
	PointRewards[SurvBurnTank] = CreateConVar("l4d2_points_tankburn", "2", "How many points does burning a tank earn", FCVAR_PLUGIN);
	PointRewards[SurvTankSolo] = CreateConVar("l4d2_points_tanksolo", "8", "How many points does killing a tank single-handedly earn", FCVAR_PLUGIN);
	PointRewards[SurvBurnWitch] = CreateConVar("l4d2_points_witchburn", "1", "How many points does burning a witch earn", FCVAR_PLUGIN);
	PointRewards[SurvBileTank] = CreateConVar("l4d2_points_bile_tank", "2", "How many points does biling a tank earn", FCVAR_PLUGIN);
	PointRewards[InfecChokeSurv] = CreateConVar("l4d2_points_smoke", "2", "How many points does smoking a survivor earn", FCVAR_PLUGIN);
	PointRewards[InfecPounceSurv] = CreateConVar("l4d2_points_pounce", "1", "How many points does pouncing a survivor earn", FCVAR_PLUGIN);
	PointRewards[InfecChargeSurv] = CreateConVar("l4d2_points_charge", "2", "How many points does charging a survivor earn", FCVAR_PLUGIN);
	PointRewards[InfecImpactSurv] = CreateConVar("l4d2_points_impact", "1", "How many points does impacting a survivor earn", FCVAR_PLUGIN);
	PointRewards[InfecRideSurv] = CreateConVar("l4d2_points_ride", "2", "How many points does riding a survivor earn", FCVAR_PLUGIN);
	PointRewards[InfecBoomSurv] = CreateConVar("l4d2_points_boom", "1", "How many points does booming a survivor earn", FCVAR_PLUGIN);
	PointRewards[InfecIncapSurv] = CreateConVar("l4d2_points_incap", "3", "How many points does incapping a survivor earn", FCVAR_PLUGIN);
	PointRewards[InfecHurtSurv] = CreateConVar("l4d2_points_damage", "2", "How many points does doing damage earn", FCVAR_PLUGIN);
	PointRewards[InfecKillSurv] = CreateConVar("l4d2_points_kill", "5", "How many points does killing a survivor earn", FCVAR_PLUGIN);
	return;
}

public initStructures(){
	initPluginSettings();
	initAllPlayerData();
	initPluginSprites();
	initCounterData();
	initItemCosts();
	initCategoriesEnabled();
	initPointRewards();
	return;
}

//melee check

#define MAX_MELEE_LENGTH 13
new String:meleelist[MAX_MELEE_LENGTH][20] =
{
	"cricket_bat",
	"crowbar",
	"baseball_bat",
	"electric_guitar",
	"fireaxe",
	"katana",
	"knife",
	"tonfa",
	"golfclub",
	"machete",
	"frying_pan",
	"hunting_knife",
	"riotshield"
};

new String:validmelee[MAX_MELEE_LENGTH][20];
new String:MapName[60];
//stuffs
new SendProp_IsAlive;
new SendProp_IsGhost;
new SendProp_LifeState;

new bool:lateload = false;
new bool:bFirstRun = true;

public Plugin:myinfo = 
{
	name = "Points System",
	author = "McFlurry & evilmaniac",
	description = "Customized edition of McFlurry's points system",
	version = PLUGIN_TITLE,
	url = "http://www.evilmania.net"
}

registerAdminCommands(){
	RegAdminCmd("sm_listmodules", ListModules, ADMFLAG_GENERIC, "List modules currently loaded to Points System");
	RegAdminCmd("sm_listmelee", ListMelee, ADMFLAG_GENERIC, "List melee weapons available on this map");
	RegAdminCmd("sm_heal", Command_Heal, ADMFLAG_SLAY, "sm_heal <target>");
	RegAdminCmd("sm_givepoints", Command_Points, ADMFLAG_SLAY, "sm_givepoints <target> [amount]");
	RegAdminCmd("sm_setpoints", Command_SPoints, ADMFLAG_SLAY, "sm_setpoints <target> [amount]");
	return;
}

registerConsoleCommands(){
	RegConsoleCmd("sm_buystuff", BuyMenu, "Open the buy menu (only in-game)");
	RegConsoleCmd("sm_repeatbuy", Command_RBuy, "Repeat your last buy transaction");
	RegConsoleCmd("sm_buy", BuyMenu, "Open the buy menu (only in-game)");
	RegConsoleCmd("sm_points", ShowPoints, "Show the amount of points you have (only in-game)");
	return;
}

hookGameEvents(){
	HookEvent("infected_death", Event_Kill);
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_death", Event_Death);
	HookEvent("tank_killed", Event_TankDeath, EventHookMode_Pre);
	HookEvent("witch_killed", Event_WitchDeath);
	HookEvent("heal_success", Event_Heal);
	HookEvent("award_earned", Event_Protect);
	HookEvent("revive_success", Event_Revive);
	HookEvent("defibrillator_used", Event_Shock);
	HookEvent("choke_start", Event_Choke);
	HookEvent("player_now_it", Event_Boom);
	HookEvent("lunge_pounce", Event_Pounce);
	HookEvent("jockey_ride", Event_Ride);
	HookEvent("charger_carry_start", Event_Carry);
	HookEvent("charger_impact", Event_Impact);
	HookEvent("player_hurt", Event_Hurt);
	HookEvent("zombie_ignited", Event_Burn);
	HookEvent("round_end", Event_REnd);
	HookEvent("round_start", Event_RStart);
	HookEvent("finale_win", Event_Finale);
	return;	
}

public OnPluginStart(){
	ModulesArray = CreateArray(10); // Reduced from 100 to 10.
	if(ModulesArray == null)
		SetFailState("%T", "Modules Array Failure", LANG_SERVER);

	AddMultiTargetFilter("@survivors", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@survivor", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@s", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@infected", FilterInfected, "all Infected players", true);
	AddMultiTargetFilter("@i", FilterInfected, "all Infected players", true);
	//CreateConVar("l4d2_points_sys_version", PLUGIN_TITLE, "Version of Points System on this server.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	CreateConVar("em_points_sys_version", PLUGIN_TITLE, "Version of Points System on this server.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);

	registerAdminCommands();
	registerConsoleCommands();
	hookGameEvents();
	initStructures();

	SendProp_LifeState = FindSendPropInfo("CTerrorPlayer", "m_lifeState");
	SendProp_IsAlive = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	SendProp_IsGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");

	AutoExecConfig(true, "l4d2_points_system");
	if(!lateload) CreateTimer(0.5, PrecacheGuns);
}

// Will retreive the current gamemode and place it into sGameMode
// sGameMode is a Character array passed by refrence.
getGameMode(String:sGameMode[], iSize){
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, iSize);
}

getAttackerIndex(Handle:hEvent){
	new iAttackerIndex = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	return(iAttackerIndex);
}

getClientIndex(Handle:hEvent){
	new iClientIndex = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	return(iClientIndex);
}

bool:IsClientPlaying(iClientIndex){
	if(iClientIndex > 0){
		if(IsClientConnected(iClientIndex))
			if(IsClientInGame(iClientIndex))
				if(GetClientTeam(iClientIndex) > 1)
					return true;
	}
	return false;
}

bool:IsClientBot(iClientIndex){
	if(iClientIndex > 0){
		if(IsClientConnected(iClientIndex))
			if(IsFakeClient(iClientIndex))
				return true;
	}
	return false;
}

bool:IsPlayerGhost(iClientIndex){
	if(iClientIndex > 0){
		if(GetEntData(iClientIndex, SendProp_IsGhost, 1))
			return true;
	}
	return false;
}

bool:IsClientTank(iClientIndex){
	if(iClientIndex > 0){
		if(GetEntProp(iClientIndex, Prop_Send, "m_zombieClass") == 8)
			return true;
	}
	return false;
}

bool:IsClientSurvivor(iClientIndex){
	if(iClientIndex > 0){
		if(GetClientTeam(iClientIndex) == 2) // Survivor
			return true;
	}
	return false;
}

bool:IsClientInfected(iClientIndex){
	if(iClientIndex > 0){
		if(GetClientTeam(iClientIndex) == 3) // Infected
			return true;
	}
	return false;
}

bool:IsModEnabled(){
	if(GetConVarInt(PluginSettings[hEnabled]) == 1){
		if(IsAllowedGameMode())
			return true;
	}
	return false;
}

stock bool:IsAllowedGameMode(){ // change name
	decl String:sGameMode[40]; sGameMode[0] = '\0';
	decl String:sEnabledModes[64]; sEnabledModes[0] = '\0';

	getGameMode(sGameMode, sizeof(sGameMode));
	GetConVarString(PluginSettings[hModes], sEnabledModes, sizeof(sEnabledModes));

	return (StrContains(sEnabledModes, sGameMode) != -1);
}

stock bool:IsAllowedReset(){
	decl String:sGameMode[40]; sGameMode[0] = '\0';
	decl String:sEnabledModes[64]; sEnabledModes[0] = '\0';

	getGameMode(sGameMode, sizeof(sGameMode));
	GetConVarString(PluginSettings[hResetPoints], sEnabledModes, sizeof(sEnabledModes));

	return (StrContains(sEnabledModes, sGameMode) != -1);
}

setStartPoints(iClientIndex){
	if(iClientIndex <= 0) 
		return;

	new iStartPoints = GetConVarInt(PluginSettings[hStartPoints]);
	PlayerData[iClientIndex][iPlayerPoints] = iStartPoints;
}

addPointsToTeam(iClientIndex, iTeam, iPoints, const String:sMessage[]){
	if(MaxClients >= iClientIndex){
		if(!IsClientBot(iClientIndex))
			if(GetClientTeam(iClientIndex) == iTeam)
				addPoints(iClientIndex, iPoints, sMessage);
		addPointsToTeam(++iClientIndex, iTeam, iPoints, sMessage);
	}
	return;
}

addPoints(iClientIndex, iPoints, const String:sMessage[]){
	if(!IsClientBot(iClientIndex)){
		PlayerData[iClientIndex][iPlayerPoints] += iPoints;
		if(GetConVarBool(PluginSettings[hNotifications])){
			PrintToChat(iClientIndex, "%s %T", MSGTAG, sMessage, LANG_SERVER, iPoints);
			return;
		}
	}
	return;
}

removePoints(iClientIndex, iPoints){
	PlayerData[iClientIndex][iPlayerPoints] -= iPoints;
	return;
}

public bool:FilterSurvivors(const String:pattern[], Handle:clients)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			PushArrayCell(clients, i);
		}
	}
	return true;
}	

public bool:FilterInfected(const String:pattern[], Handle:clients)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			PushArrayCell(clients, i);
		}
	}
	return true;
}	

public Action:PrecacheGuns(Handle:Timer)
{
	decl String:map[128]; map[0] = '\0';
	GetCurrentMap(map, sizeof(map));
	if(DispatchAndRemove("weapon_rifle_sg552") &&
	DispatchAndRemove("weapon_smg_mp5") &&
	DispatchAndRemove("weapon_sniper_awp") &&
	DispatchAndRemove("weapon_sniper_scout") &&
	DispatchAndRemove("weapon_rifle_m60"))
	{
		ForceChangeLevel(map, "Initialize CS:S weapons");
	}
	else
	{
		LogError("Plugin failed to initialize a CS:S weapon, consult developer!");
		ForceChangeLevel(map, "Initialize CS:S weapons");
	}	
}

stock DispatchAndRemove(const String:gun[])
{
	new ent = CreateEntityByName(gun);	
	if(IsValidEdict(ent))
	{
		DispatchSpawn(ent);
		RemoveEdict(ent);
		return true;
	}
	else return false;
}	

public OnAllPluginsLoaded()
{
	//forward
	Call_StartForward(Forward1);
	Call_Finish();
}	

public OnConfigsExecuted()
{
	if(bFirstRun)
	{
		for(new i=0;i<=MaxClients;i++)
		{
			setStartPoints(i);
			//points[i] = GetConVarInt(StartPoints);
		}
		bFirstRun = false;
	}
}

public OnMapStart()
{
	PrecacheModel("models/w_models/v_rif_m60.mdl", true);
	PrecacheModel("models/w_models/weapons/w_m60.mdl", true);
	PrecacheModel("models/v_models/v_m60.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	initPluginSprites();
	GetCurrentMap(MapName, sizeof(MapName));
	CreateTimer(6.0, CheckMelee, _, TIMER_FLAG_NO_MAPCHANGE);
}	

public Action:CheckMelee(Handle:Timer)
{
	new mCounter;
	for(new i=0;i<MAX_MELEE_LENGTH;i++)
	{
		Format(validmelee[i], sizeof(validmelee[]), "");
	}
	for(new i=0;i<MAX_MELEE_LENGTH;i++)
	{
		new entity = CreateEntityByName("weapon_melee");
		DispatchKeyValue(entity, "melee_script_name", meleelist[i]);
		DispatchSpawn(entity);
		decl String:modelname[256];
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
		if(StrContains(modelname, "hunter", false) == -1)
		{
			Format(validmelee[mCounter++], sizeof(validmelee[]), meleelist[i]);
		}
		RemoveEdict(entity);
	}
}	

public Action:ListMelee(client, args)
{
	if(args > 0) return;
	for(new i=0;i<MAX_MELEE_LENGTH;i++)
	{
		if(strlen(validmelee[i]) > 0) ReplyToCommand(client, validmelee[i]);	
	}	
}	

public Action:ListModules(client, args)
{
	if(args > 0) return Plugin_Handled;
	ReplyToCommand(client, "%s %T", MSGTAG, "Modules", LANG_SERVER);
	new size = GetArraySize(ModulesArray);
	for(new i=0; i<size; i++)
	{
		decl String:buffer[MODULES_SIZE];
		GetArrayString(ModulesArray, i, buffer, MODULES_SIZE);
		if(strlen(buffer) > 0) ReplyToCommand(client, buffer);
	}
	ReplyToCommand(client, "%s %T", MSGTAG, "End...", LANG_SERVER);
	return Plugin_Handled;
}	

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:game_name[128];
	GetGameFolderName(game_name, sizeof(game_name));
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("points_system.phrases");
	LoadTranslations("points_system_menus.phrases");
	if(!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("%T", "Game Check Fail", LANG_SERVER);
	}
	CreateNative("PS_IsSystemEnabled", PS_IsSystemEnabled);
	CreateNative("PS_GetVersion", PS_GetVersion);
	CreateNative("PS_SetPoints", PS_SetPoints);
	CreateNative("PS_SetItem", PS_SetItem);
	CreateNative("PS_SetCost", PS_SetCost);
	CreateNative("PS_SetBought", PS_SetBought);
	CreateNative("PS_SetBoughtCost", PS_SetBoughtCost);
	CreateNative("PS_SetupUMob", PS_SetupUMob);
	CreateNative("PS_GetPoints", PS_GetPoints);
	CreateNative("PS_GetBoughtCost", PS_GetBoughtCost);
	CreateNative("PS_GetCost", PS_GetCost);
	CreateNative("PS_GetItem", PS_GetItem);
	CreateNative("PS_GetBought", PS_GetBought);
	CreateNative("PS_RegisterModule", PS_RegisterModule);
	CreateNative("PS_UnregisterModule", PS_UnregisterModule);
	CreateNative("PS_RemovePoints", PS_RemovePoints);
	Forward1 = CreateGlobalForward("OnPSLoaded", ET_Ignore);
	Forward2 = CreateGlobalForward("OnPSUnloaded", ET_Ignore);
	RegPluginLibrary("ps_natives");
	lateload = late;
	return APLRes_Success;
}

public OnPluginEnd()
{
	new Action:result;
	Call_StartForward(Forward2);
	Call_Finish(_:result);
}	

public PS_IsSystemEnabled(Handle:hPlugin, iNumArguments){
	return bool:(GetConVarInt(PluginSettings[hEnabled]) == 1);
}

public PS_RemovePoints(Handle:hPlugin, iNumArguments){
	removePoints(GetNativeCell(1), GetNativeCell(2));
	return;
}

public PS_RegisterModule(Handle:plugin, numParams)
{
	new size = GetArraySize(ModulesArray);
	decl String:test[MODULES_SIZE];
	GetNativeString(1, test, MODULES_SIZE);
	for(new i; i<size; i++)
	{
		decl String:buffer[MODULES_SIZE];
		GetArrayString(ModulesArray, i, buffer, MODULES_SIZE);
		if(StrEqual(buffer, test))
		{
			return false;
		}	
	}
	PushArrayString(ModulesArray, test);
	return true;
}	

public PS_UnregisterModule(Handle:plugin, numParams)
{
	new size = GetArraySize(ModulesArray);
	new String:container[MODULES_SIZE];
	GetNativeString(1, container, MODULES_SIZE);
	for(new i; i<size; i++)
	{
		decl String:buffer[MODULES_SIZE];
		GetArrayString(ModulesArray, i, buffer, MODULES_SIZE);
		if(StrEqual(buffer, container))
		{
			RemoveFromArray(ModulesArray, i);
			return true;
		}
	}
	return false;
}	

public PS_GetVersion(Handle:plugin, numParams)
{
	return _:PluginSettings[fVersion];
}	

public PS_SetPoints(Handle:plugin, numParams)
{
	PlayerData[GetNativeCell(1)][iPlayerPoints] = GetNativeCell(2);
}	

public PS_SetItem(Handle:plugin, numParams)
{
	GetNativeString(2, PlayerData[GetNativeCell(1)][sItemName], 64);
}

public PS_SetCost(Handle:plugin, numParams)
{
	PlayerData[GetNativeCell(1)][iItemCost] = GetNativeCell(2);
}

public PS_SetBought(Handle:plugin, numParams)
{
	GetNativeString(2, PlayerData[GetNativeCell(1)][sBought], 64);
}

public PS_SetBoughtCost(Handle:plugin, numParams)
{
	PlayerData[GetNativeCell(1)][iBoughtCost] = GetNativeCell(2);
}	

public PS_SetupUMob(Handle:plugin, numParams)
{
	CounterData[iUCommonLeft] = GetNativeCell(1);
}	

public PS_GetPoints(Handle:plugin, numParams)
{
	return PlayerData[GetNativeCell(1)][iPlayerPoints];
}	

public PS_GetCost(Handle:plugin, numParams)
{
	return PlayerData[GetNativeCell(1)][iItemCost];
}	

public PS_GetBoughtCost(Handle:plugin, numParams)
{
	return PlayerData[GetNativeCell(1)][iBoughtCost];
}	

public PS_GetItem(Handle:plugin, numParams)
{
	SetNativeString(2, PlayerData[GetNativeCell(1)][sItemName], GetNativeCell(3));
}

public PS_GetBought(Handle:plugin, numParams)
{
	SetNativeString(2, PlayerData[GetNativeCell(1)][sBought], 64);
}

resetClientData(iClientIndex){
	setStartPoints(iClientIndex);

	PlayerData[iClientIndex][iKillCount] 		= 0;
	PlayerData[iClientIndex][iHurtCount] 		= 0;
	PlayerData[iClientIndex][iProtectCount] 	= 0;
	PlayerData[iClientIndex][iHeadShotCount] 	= 0;
	PlayerData[iClientIndex][bMessageSent] 		= false;
}

public Action:Check(Handle:hTimer, any:iClientIndex){
	if(iClientIndex == 0 || !IsClientConnected(iClientIndex))
		resetClientData(iClientIndex);
}

public OnClientAuthorized(iClientIndex, const String:sSteamID[]){
	if(IsClientBot(iClientIndex))
		return;
	else{
		if(PlayerData[iClientIndex][iPlayerPoints] < GetConVarInt(PluginSettings[hStartPoints]))
			setStartPoints(iClientIndex);
	}
}

public OnClientDisconnect(iClientIndex){
	if(IsClientBot(iClientIndex))
		return;
	else{
		if(PlayerData[iClientIndex][iPlayerPoints] < GetConVarInt(PluginSettings[hStartPoints]))
			resetClientData(iClientIndex);
		CreateTimer(4.0, Check, iClientIndex);
	}
}

public resetAllPlayers(iClientIndex){ // Check if 0
	if(MaxClients >= iClientIndex){
		resetClientData(iClientIndex);
		resetAllPlayers(++iClientIndex);
	}
	return;
}

public Action:Event_REnd(Handle:hEvent, String:sEventName[], bool:bDontBroadcast){
	if(IsAllowedReset())
		resetAllPlayers(1);

	initCounterData();
}	

public Action:Event_RStart(Handle:hEvent, String:sEventName[], bool:bDontBroadcast){
	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl")) PrecacheModel("models/w_models/weapons/w_m60.mdl");
	if (!IsModelPrecached("models/v_models/v_m60.mdl")) PrecacheModel("models/v_models/v_m60.mdl");

	if(IsAllowedReset())
		resetAllPlayers(1);

	initCounterData();
}	

public Action:Event_Finale(Handle:hEvent, String:sEventName[], bool:bDontBroadcast){
	decl String:sGameMode[40]; sGameMode[0] = '\0';
	getGameMode(sGameMode, sizeof(sGameMode));

	if(StrContains(sGameMode, "versus", false) != -1) 
		return;
	else resetAllPlayers(1);
}	

handleHeadshots(iClientIndex){
	new iHeadShotReward = GetConVarInt(PointRewards[SurvRewardHeadShots]);
	new iHeadShotsRequired = GetConVarInt(PluginSettings[hHeadShotNum]);
	if(iHeadShotReward > 0){
		PlayerData[iClientIndex][iHeadShotCount]++;
		if(PlayerData[iClientIndex][iHeadShotCount] >= iHeadShotsRequired){
			addPoints(iClientIndex, iHeadShotReward, "Head Hunter");
			PlayerData[iClientIndex][iHeadShotCount] -= iHeadShotsRequired;
		}
	}
	return;
}

handleKillSpree(iClientIndex){
	new iKillSpreeReward = GetConVarInt(PointRewards[SurvRewardKillSpree]);
	new iKillSpreeRequired = GetConVarInt(PluginSettings[hKillSpreeNum]);
	if(iKillSpreeReward > 0){
		PlayerData[iClientIndex][iKillCount]++;
		if(PlayerData[iClientIndex][iKillCount] >= iKillSpreeRequired){
			addPoints(iClientIndex, iKillSpreeReward, "Killing Spree");
			PlayerData[iClientIndex][iKillCount] -= iKillSpreeRequired;
		}
	}
	return;
}

public Action:Event_Kill(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new bool:bHeadShot = GetEventBool(hEvent, "bHeadShot");
	new iAttackerIndex = getAttackerIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientSurvivor(iAttackerIndex)){
			if(bHeadShot)
				handleHeadshots(iAttackerIndex);
			handleKillSpree(iAttackerIndex);
		}
	}
	return;
}

public Action:Event_Incap(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new iAttackerIndex = getAttackerIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientInfected(iAttackerIndex)){
			new iIncapPoints = GetConVarInt(PointRewards[InfecIncapSurv]);
			if(iIncapPoints > 0)
				addPoints(iAttackerIndex, iIncapPoints, "Incapped Survivor");
		}
	}
	return;
}	

public Action:Event_Death(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new iAttackerIndex = getAttackerIndex(hEvent);
	new iVictimIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientSurvivor(iAttackerIndex)){
			new iInfectedKilledReward = GetConVarInt(PointRewards[SurvKillInfec]);
			if(iInfectedKilledReward > 0){
				if(IsClientInfected(iVictimIndex)){ // If the person killed by the survivor is infected
					if(IsClientTank(iVictimIndex)) // Ignore tank death since it is handled elsewhere
						return;
					else{
						handleHeadshots(iAttackerIndex);
						addPoints(iAttackerIndex, iInfectedKilledReward, "Killed SI");
					}
				}
			}
		}
		else if(IsClientInfected(iAttackerIndex)){
			new iSurvivorKilledReward = GetConVarInt(PointRewards[InfecKillSurv]);
			if(iSurvivorKilledReward > 0)
				if(IsClientSurvivor(iVictimIndex)) // If the person killed by the infected is a survivor
					addPoints(iAttackerIndex, iSurvivorKilledReward, "Killed Survivor");
		}
	}
	return;
}

handleTankKilled(){
	new iTankKilledReward = GetConVarInt(PointRewards[SurvKillTank]);
	if(iTankKilledReward > 0)
		handleTankKilledPoints(1, iTankKilledReward, "Killed Tank");
	return;
}

handleTankKilledPoints(iClientIndex, iPoints, const String:sMessage[]){
	if(iClientIndex > 0 && MaxClients >= iClientIndex){
		if(!IsClientBot(iClientIndex))
			if(IsClientInGame(iClientIndex))
				if(IsClientSurvivor(iClientIndex))
					if(IsPlayerAlive(iClientIndex)){
						addPoints(iClientIndex, iPoints, sMessage);
					}
		handleTankKilledPoints(++iClientIndex, iPoints, sMessage);
	}
	return;
}

public Action:Event_TankDeath(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new bool:bSoloKill = GetEventBool(hEvent, "solo");
	new iAttackerIndex = getAttackerIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientSurvivor(iAttackerIndex)){
			new iTankSoloReward = GetConVarInt(PointRewards[SurvTankSolo]); // Points to be rewarded for killing a tank, solo
			if(iTankSoloReward > 0){ // If solo kill reward is enabled
				if(bSoloKill) // If kill was solo
					addPoints(iAttackerIndex, iTankSoloReward, "TANK SOLO");
				else
					handleTankKilled(); // Reward survivors for killing a tank
			}
		}
	}
	PlayerData[iAttackerIndex][bTankBurning] = false;
	return;
}	

public Action:Event_WitchDeath(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new bool:bOneShot = GetEventBool(hEvent, "oneshot");
	new iClientIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientSurvivor(iClientIndex)){
			new iWitchKilledReward = GetConVarInt(PointRewards[SurvKillWitch]);
			if(iWitchKilledReward > 0)
				addPoints(iClientIndex, iWitchKilledReward, "Killed Witch");

			if(bOneShot){
				new iWitchCrownedReward = GetConVarInt(PointRewards[SurvCrownWitch]);
				if(iWitchCrownedReward > 0)
					addPoints(iClientIndex, iWitchCrownedReward, "Crowned Witch");
			}
		}
	}
	PlayerData[iClientIndex][bWitchBurning] = false;
	return;
}	

public Action:Event_Heal(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new iHealthRestored = GetEventInt(hEvent, "health_restored");
	new iTargetIndex = GetClientOfUserId(GetEventInt(hEvent, "subject"));
	new iClientIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientSurvivor(iClientIndex)){
			if(iClientIndex != iTargetIndex){ // If player did not heal himself with the medkit
				if(iHealthRestored > 39){
					new iHealTeamReward = GetConVarInt(PointRewards[SurvTeamHeal]);
					if(iHealTeamReward > 0)
						addPoints(iClientIndex, iHealTeamReward, "Team Heal");
				}
				else{
					new iHealTeamReward = GetConVarInt(PointRewards[SurvTeamHealFarm]);
					if(iHealTeamReward > 0)
						addPoints(iClientIndex, iHealTeamReward, "Team Heal Warning");
				}
			}
		}
	}
	return;
}	

handleProtect(iClientIndex){
	new iProtectReward = GetConVarInt(PointRewards[SurvTeamProtect]);
	if(iProtectReward > 0){
		PlayerData[iClientIndex][iProtectCount]++;
		if(PlayerData[iClientIndex][iProtectCount] == 6){
			addPoints(iClientIndex, iProtectReward, "Protect");
			PlayerData[iClientIndex][iProtectCount] -= 6;
		}
	}
	return;
}

public Action:Event_Protect(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new iAwardType = GetEventInt(hEvent, "award");
	new iClientIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iClientIndex))
		if(IsClientPlaying(iClientIndex))
			if(IsClientSurvivor(iClientIndex))
				if(iAwardType == 67) // if(iAwardType == Protect)
					handleProtect(iClientIndex);
	return;
}

public Action:Event_Revive(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new bool:bLedgeRevive = GetEventBool(hEvent, "ledge_hang");
	new iTargetIndex = GetClientOfUserId(GetEventInt(hEvent, "subject"));
	new iClientIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientSurvivor(iClientIndex)){
			if(iClientIndex != iTargetIndex){
				if(bLedgeRevive){
					new iLedgeReviveReward = GetConVarInt(PointRewards[SurvTeamLedge]);
					if(iLedgeReviveReward > 0)
						addPoints(iClientIndex, iLedgeReviveReward, "Ledge Revive");	
				}
				else{
					new iReviveReward = GetConVarInt(PointRewards[SurvTeamRevive]);
					if(iReviveReward > 0)
						addPoints(iClientIndex, iReviveReward, "Revive");

				}
			}
		}
	}
	return;
}	

public Action:Event_Shock(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){ // Defib
	new iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientSurvivor(iClientIndex)){
			new iDefibReward = GetConVarInt(PointRewards[SurvTeamDefib]);
			if(iDefibReward > 0)
				addPoints(iClientIndex, iDefibReward, "Defib");
		}
	}
	return;
}	

public Action:Event_Choke(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			new iChokeReward = GetConVarInt(PointRewards[InfecChokeSurv]);
			if(iChokeReward > 0)
				addPoints(iClientIndex, iChokeReward, "Smoke");
		}
	}
	return;
}

public Action:Event_Boom(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new iAttackerIndex = getAttackerIndex(hEvent);
	new iVictimIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientInfected(iAttackerIndex)){ // If boomer biles survivors
			new iBoomedReward = GetConVarInt(PointRewards[InfecBoomSurv]);
			if(iBoomedReward > 0)
				addPoints(iAttackerIndex, iBoomedReward, "Boom");
		}
		else if(IsClientSurvivor(iAttackerIndex)){ // If survivor biles a tank
			new iBiledReward = GetConVarInt(PointRewards[SurvBileTank]);
			if(iBiledReward > 0){
				if(IsClientTank(iVictimIndex))
					addPoints(iAttackerIndex, iBiledReward, "Biled");
			}
		}
	}
	return;
}	

public Action:Event_Pounce(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			new iPounceReward = GetConVarInt(PointRewards[InfecPounceSurv]);
			if(iPounceReward > 0)
				addPoints(iClientIndex, iPounceReward, "Pounce");
		}
	}
	return;
}	

public Action:Event_Ride(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			new iRideReward = GetConVarInt(PointRewards[InfecRideSurv]);
			if(iRideReward > 0)
				addPoints(iClientIndex, iRideReward, "Jockey Ride");
		}
	}
	return;
}

public Action:Event_Carry(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			new iCarryReward = GetConVarInt(PointRewards[InfecChargeSurv]);
			if(iCarryReward > 0)
				addPoints(iClientIndex, iCarryReward, "Charge");
		}
	}
	return;
}

public Action:Event_Impact(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	new iClientIndex = getClientIndex(hEvent);
	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			new iImpactReward = GetConVarInt(PointRewards[InfecImpactSurv]);
			if(iImpactReward > 0)
				addPoints(iClientIndex, iImpactReward, "Charge Collateral");
		}
	}
	return;
}	

public Action:Event_Burn(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
	decl String:sVictimName[30]; sVictimName[0] = '\0';
	GetEventString(hEvent, "victimname", sVictimName, sizeof(sVictimName));
	new iClientIndex = getClientIndex(hEvent);

	if(IsModEnabled() && !IsClientBot(iClientIndex)){
		if(IsClientSurvivor(iClientIndex)){
			if(StrEqual(sVictimName, "Tank", false)){
				new iTankBurnReward = GetConVarInt(PointRewards[SurvBurnTank]);
				if(iTankBurnReward > 0)
					if(!PlayerData[iClientIndex][bTankBurning]){
						PlayerData[iClientIndex][bTankBurning] = true;
						addPoints(iClientIndex, iTankBurnReward, "Burn Tank");
					}
			}
			else if(StrEqual(sVictimName, "Witch", false)){
				new iWitchBurnReward = GetConVarInt(PointRewards[SurvBurnWitch]);
				if(iWitchBurnReward > 0){
					if(!PlayerData[iClientIndex][bWitchBurning]){
						PlayerData[iClientIndex][bWitchBurning] = true;
						addPoints(iClientIndex, iWitchBurnReward, "Burn Witch");
					}
				}
			}
		}
	}
	return;
}

handleSpit(iClientIndex, iPoints){
    if(PlayerData[iClientIndex][iHurtCount] >= 8){
        addPoints(iClientIndex, iPoints, "Spit Damage");
        PlayerData[iClientIndex][iHurtCount] -= 8;
    }
    return;
}

handleDamage(iClientIndex, iPoints){
    if(PlayerData[iClientIndex][iHurtCount] >= 3){
        addPoints(iClientIndex, iPoints, "Damage");
        PlayerData[iClientIndex][iHurtCount] -= 3;
    }
    return;
}

public bool:IsSpitterDamage(iDamageType){
    if(iDamageType == 263168 || iDamageType == 265216)
        return true;
    else return false;
}

public Action:Event_Hurt(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast){
    new iVictimIndex = getClientIndex(hEvent);
    new iAttackerIndex = getAttackerIndex(hEvent);

    if(IsModEnabled() && !IsClientBot(iAttackerIndex)){
		if(IsClientInfected(iAttackerIndex) && IsClientSurvivor(iVictimIndex)){
			PlayerData[iAttackerIndex][iHurtCount]++;
			new iSurvivorDamagedReward = GetConVarInt(PointRewards[InfecHurtSurv]);
			if(iSurvivorDamagedReward > 0){
				new iDamageType = GetEventInt(hEvent, "type");
				if(IsSpitterDamage(iDamageType))
					handleSpit(iAttackerIndex, iSurvivorDamagedReward);
				else{
					if(!IsSpitterDamage(iDamageType))
						handleDamage(iAttackerIndex, iSurvivorDamagedReward);
				}
			}
		}
	}
}

public Action:BuyMenu(iClientIndex, iNumArguments){
	if(IsModEnabled() && iNumArguments == 0){
		if(IsClientPlaying(iClientIndex))
			BuildBuyMenu(iClientIndex);
	}
	return Plugin_Handled;
}

public Action:ShowPoints(iClientIndex, iNumArguments){
	if(IsModEnabled() && iNumArguments == 0){
		if(IsClientPlaying(iClientIndex))
			ReplyToCommand(iClientIndex, "%s %T", MSGTAG, "Your Points", LANG_SERVER, PlayerData[iClientIndex][iPlayerPoints]);
	}
	return Plugin_Handled;
}

public bool:CheckPurchase(iClientIndex, iCost){
	if(iClientIndex > 0){
		if(IsItemEnabled(iClientIndex, iCost) && HasEnoughPoints(iClientIndex, iCost))
			return true;
		else
			return false;
	}
	return false;
}

public bool:IsItemEnabled(iClientIndex, iCost){
	if(iClientIndex > 0){
		if(iCost >= 0)
			return true;
		else{
			ReplyToCommand(iClientIndex, "%s %T", MSGTAG, "Item Disabled", LANG_SERVER);
			return false;
		}
	}
	return false;
}

public bool:HasEnoughPoints(iClientIndex, iCost){
	if(iClientIndex > 0){
		if(PlayerData[iClientIndex][iPlayerPoints] >= iCost)
			return true;
		else{
			ReplyToCommand(iClientIndex, "%s %T", MSGTAG, "Insufficient Funds", LANG_SERVER);
			return false;
		}
	}
	return false;
}

performSuicide(iClientIndex, iCost){
	if(iClientIndex > 0 && !IsClientBot(iClientIndex)){
		if(IsClientInfected(iClientIndex)){
			ForcePlayerSuicide(iClientIndex);

			if(IsClientTank(iClientIndex))
				return;
			else
				removePoints(iClientIndex, iCost);
		}
	}
	return;
}

public Action:Command_RBuy(iClientIndex, iNumArguments){
	if(iClientIndex > 0 && iNumArguments == 0){
		if(!IsClientBot(iClientIndex) && IsClientPlaying(iClientIndex)){
			if(CheckPurchase(iClientIndex, PlayerData[iClientIndex][iItemCost])){ // Check if item is Enabled & Player has points
				if(StrEqual(PlayerData[iClientIndex][sItemName], "suicide", false)){
					performSuicide(iClientIndex, PlayerData[iClientIndex][iItemCost]);
					return;
				}
				else{ // If we are not dealing with a suicide
					execClientCommand(iClientIndex, PlayerData[iClientIndex][sItemName]);
					removePoints(iClientIndex, PlayerData[iClientIndex][iItemCost]);
					//do additional actions for certain items
					if(StrEqual(PlayerData[iClientIndex][sItemName], "z_spawn_old mob", false))
						CounterData[iUCommonLeft] += GetConVarInt(FindConVar("z_common_limit"));
					else if(StrEqual(PlayerData[iClientIndex][sItemName], "give ammo", false))
						reloadAmmo(iClientIndex, PlayerData[iClientIndex][iItemCost], PlayerData[iClientIndex][sItemName]);
					return;
				}
			}
		}
	}
}

public Action:Command_Heal(client, args)
{
	if(args == 0)
	{
		execClientCommand(client, "give health");
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);	
		return Plugin_Handled;
	}
	else if(args == 1)
	{
		decl String:arg[65];
		GetCmdArg(1, arg, sizeof(arg));
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		if ((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else
		{
			ShowActivity2(client, MSGTAG2, "%t", "Give Health", target_name);
			
			for (new i = 0; i < target_count; i++)
			{
				new targetclient = target_list[i];
				execClientCommand(targetclient, "give health");
				SetEntPropFloat(targetclient, Prop_Send, "m_healthBuffer", 0.0);	
			}
			return Plugin_Handled;
		}	
	}
	else
	{
		ReplyToCommand(client, "%s%T", MSGTAG, "Usage sm_heal", LANG_SERVER);
		return Plugin_Handled;
	}
}

public Action:Command_Points(client, args)
{
	if(args == 2)
	{
		decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		new targetclient, amount = StringToInt(arg2);
		if ((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else
		{
			//ShowActivity2(client, MSGTAG2, "%t", "Give Points", amount, target_name);
			for (new i = 0; i < target_count; i++)
			{
				targetclient = target_list[i];
				PlayerData[targetclient][iPlayerPoints] += amount;
			}
			return Plugin_Handled;
		}	
	}
	else
	{
		ReplyToCommand(client, "%s %T", MSGTAG, "Usage sm_givepoints", LANG_SERVER);
		return Plugin_Handled;
	}
}	

public Action:Command_SPoints(client, args)
{
	if(args == 2)
	{
		decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		new targetclient, amount = StringToInt(arg2);
		if ((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else
		{
			//ShowActivity2(client, MSGTAG2, "%t", "Set Points", target_name, amount);
			for (new i = 0; i < target_count; i++)
			{
				targetclient = target_list[i];
				PlayerData[targetclient][iPlayerPoints] = amount;
			}
			return Plugin_Handled;
		}
	}	
	else
	{
		ReplyToCommand(client, "%s %T", MSGTAG, "Usage sm_setpoints", LANG_SERVER, MSGTAG);
		return Plugin_Handled;
	}	
}

execClientCommand(iClientIndex, const String:sCommand[]){
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
}	

BuildBuyMenu(client)
{
	if(GetClientTeam(client) == 2)
	{
		decl String:title[40], String:weapons[40], String:upgrades[40], String:health[40];
		new Handle:menu = CreateMenu(TopMenu);
		if(GetConVarInt(CategoriesEnabled[CategoryWeapons]) == 1)
		{
			Format(weapons, sizeof(weapons), "%T", "Weapons", LANG_SERVER);
			AddMenuItem(menu, "g_WeaponsMenu", weapons);
		}
		if(GetConVarInt(CategoriesEnabled[CategoryUpgrades]) == 1)
		{
			Format(upgrades, sizeof(upgrades), "%T", "Upgrades", LANG_SERVER);
			AddMenuItem(menu, "g_UpgradesMenu", upgrades);
		}
		if(GetConVarInt(CategoriesEnabled[CategoryHealth]) == 1)
		{
			Format(health, sizeof(health), "%T", "Health", LANG_SERVER);
			AddMenuItem(menu, "g_HealthMenu", health);
		}	
		Format(title, sizeof(title), "%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if(GetClientTeam(client) == 3)
	{
		decl String:title[40], String:boomer[40], String:spitter[40], String:smoker[40], String:hunter[40], String:charger[40], String:jockey[40], String:tank[40], String:witch[40], String:witch_bride[40], String:heal[40], String:suicide[40], String:horde[40], String:mob[40], String:umob[40];
		new Handle:menu = CreateMenu(InfectedMenu);
		if(GetConVarInt(ItemCosts[CostInfectedHeal]) > -1)
		{
			Format(heal, sizeof(heal), "%T", "Heal", LANG_SERVER);
			AddMenuItem(menu, "heal", heal);
		}
		if(GetConVarInt(ItemCosts[CostSuicide]) > -1)
		{
			Format(suicide, sizeof(suicide), "%T", "Suicide", LANG_SERVER);
			AddMenuItem(menu, "suicide", suicide);
		}	
		if(GetConVarInt(ItemCosts[CostBoomer]) > -1)
		{
			Format(boomer, sizeof(boomer), "%T", "Boomer", LANG_SERVER);
			AddMenuItem(menu, "boomer", boomer);
		}	
		if(GetConVarInt(ItemCosts[CostSpitter]) > -1)
		{
			Format(spitter, sizeof(spitter), "%T", "Spitter", LANG_SERVER);
			AddMenuItem(menu, "spitter", spitter);
		}	
		if(GetConVarInt(ItemCosts[CostSmoker]) > -1)
		{
			Format(smoker, sizeof(smoker), "%T", "Smoker", LANG_SERVER);
			AddMenuItem(menu, "smoker", smoker);
		}	
		if(GetConVarInt(ItemCosts[CostHunter]) > -1)
		{
			Format(hunter, sizeof(hunter), "%T", "Hunter", LANG_SERVER);
			AddMenuItem(menu, "hunter", hunter);
		}	
		if(GetConVarInt(ItemCosts[CostCharger]) > -1)
		{
			Format(charger, sizeof(charger), "%T", "Charger", LANG_SERVER);
			AddMenuItem(menu, "charger", charger);
		}	
		if(GetConVarInt(ItemCosts[CostJockey]) > -1)
		{
			Format(jockey, sizeof(jockey), "%T", "Jockey", LANG_SERVER);
			AddMenuItem(menu, "jockey", jockey);
		}	
		if(GetConVarInt(ItemCosts[CostTank]) > -1)
		{
			Format(tank, sizeof(tank), "%T", "Tank", LANG_SERVER);
			AddMenuItem(menu, "tank", tank);
		}	
		if(StrEqual(MapName, "c6m1_riverbank", false) && GetConVarInt(ItemCosts[CostWitch]) > -1)
		{
			Format(witch_bride, sizeof(witch_bride), "%T", "Witch Bride", LANG_SERVER);
			AddMenuItem(menu, "witch_bride", witch_bride);
		}
		else if(GetConVarInt(ItemCosts[CostWitch]) > -1)
		{
			Format(witch, sizeof(witch), "%T", "Witch", LANG_SERVER);
			AddMenuItem(menu, "witch", witch);
		}	
		if(GetConVarInt(ItemCosts[CostHorde]) > -1)
		{
			Format(horde, sizeof(horde), "%T", "Horde", LANG_SERVER);
			AddMenuItem(menu, "horde", horde);
		}	
		if(GetConVarInt(ItemCosts[CostMob]) > -1)
		{	
			Format(mob, sizeof(mob), "%T", "Mob", LANG_SERVER);
			AddMenuItem(menu, "mob", mob);
		}	
		if(GetConVarInt(ItemCosts[CostUncommonMob]) > -1)
		{	
			Format(umob, sizeof(umob), "%T", "Uncommon Mob", LANG_SERVER);
			AddMenuItem(menu, "uncommon_mob", umob);
		}	
		Format(title, sizeof(title), "%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
		SetMenuTitle(menu, title);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}	

BuildWeaponsMenu(client)
{
	decl String:melee[40], String:rifles[40], String:shotguns[40], String:smg[40], String:snipers[40], String:misc[40], String:title[40], String:throwables[40];
	new Handle:menu = CreateMenu(MenuHandler);
	SetMenuExitBackButton(menu, true);
	if(GetConVarInt(CategoriesEnabled[CategoryMelee]) == 1)
	{
		Format(melee, sizeof(melee), "%T", "Melee", LANG_SERVER);
		AddMenuItem(menu, "g_MeleeMenu", melee);
	}
	if(GetConVarInt(CategoriesEnabled[CategorySnipers]) == 1)
	{
		Format(snipers, sizeof(snipers), "%T", "Snipers", LANG_SERVER);
		AddMenuItem(menu, "g_SnipersMenu", snipers);
	}
	if(GetConVarInt(CategoriesEnabled[CategoryRifles]) == 1)
	{
		Format(rifles, sizeof(rifles), "%T", "Rifles", LANG_SERVER);
		AddMenuItem(menu, "g_RiflesMenu", rifles);
	}
	if(GetConVarInt(CategoriesEnabled[CategoryShotguns]) == 1)
	{
		Format(shotguns, sizeof(shotguns), "%T", "Shotguns", LANG_SERVER);
		AddMenuItem(menu, "g_ShotgunsMenu", shotguns);
	}
	if(GetConVarInt(CategoriesEnabled[CategorySMG]) == 1)
	{
		Format(smg, sizeof(smg), "%T", "SMGs", LANG_SERVER);
		AddMenuItem(menu, "g_SMGMenu", smg);
	}
	if(GetConVarInt(CategoriesEnabled[CategoryThrowables]) == 1)
	{
		Format(throwables, sizeof(throwables), "%T", "Throwables", LANG_SERVER);
		AddMenuItem(menu, "g_ThrowablesMenu", throwables);
	}
	if(GetConVarInt(CategoriesEnabled[CategoryMisc]) == 1)
	{
		Format(misc, sizeof(misc), "%T", "Misc", LANG_SERVER);
		AddMenuItem(menu, "g_MiscMenu", misc);
	}	
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public TopMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Select:
		{
			new String:menu1[56];
			GetMenuItem(menu, param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "g_WeaponsMenu"))
			{
				BuildWeaponsMenu(param1);
			}	
			else if(StrEqual(menu1, "g_HealthMenu"))
			{
				BuildHealthMenu(param1);
			}	
			else if(StrEqual(menu1, "g_UpgradesMenu"))
			{
				BuildUpgradesMenu(param1);
			}	
		}
	}
}	

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				BuildBuyMenu(param1);
			}
		}		
		case MenuAction_Select:
		{
			new String:menu1[56];
			GetMenuItem(menu, param2, menu1, sizeof(menu1));
			if(StrEqual(menu1, "g_MeleeMenu"))
			{
				BuildMeleeMenu(param1);
			}
			else if(StrEqual(menu1, "g_RiflesMenu"))
			{
				BuildRiflesMenu(param1);
			}
			else if(StrEqual(menu1, "g_SnipersMenu"))
			{
				BuildSniperMenu(param1);
			}
			else if(StrEqual(menu1, "g_ShotgunsMenu"))
			{
				BuildShotgunMenu(param1);
			}	
			else if(StrEqual(menu1, "g_SMGMenu"))
			{
				BuildSMGMenu(param1);
			}
			else if(StrEqual(menu1, "g_ThrowablesMenu"))
			{
				BuildThrowablesMenu(param1);
			}	
			else if(StrEqual(menu1, "g_MiscMenu"))
			{
				BuildMiscMenu(param1);
			}	
		}
	}
}

BuildMeleeMenu(client)
{
	decl String:container[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_Melee);
	for(new i;i<MAX_MELEE_LENGTH;i++)
	{
		if(strlen(validmelee[i]) < 1)
		{
			continue;
		}	
		if(i == 0 && GetConVarInt(ItemCosts[CostCricketBat]) < 0)
		{
			continue;
		}	
		else if(i == 1 && GetConVarInt(ItemCosts[CostCrowBar]) < 0)
		{
			continue;
		}	
		else if(i == 2 && GetConVarInt(ItemCosts[CostBat]) < 0)
		{
			continue;
		}	
		else if(i == 3 && GetConVarInt(ItemCosts[CostGuitar]) < 0)
		{
			continue;
		}	
		else if(i == 4 && GetConVarInt(ItemCosts[CostFireAxe]) < 0)
		{
			continue;
		}	
		else if(i == 5 && GetConVarInt(ItemCosts[CostKatana]) < 0)
		{
			continue;
		}	
		else if(i == 6 && GetConVarInt(ItemCosts[CostKnife]) < 0)
		{
			continue;
		}	
		else if(i == 7 && GetConVarInt(ItemCosts[CostTonfa]) < 0)
		{
			continue;
		}	
		else if(i == 8 && GetConVarInt(ItemCosts[CostClub]) < 0)
		{
			continue;
		}	
		else if(i == 9 && GetConVarInt(ItemCosts[CostMachete]) < 0)
		{
			continue;
		}	
		else if(i == 10 && GetConVarInt(ItemCosts[CostPan]) < 0)
		{
			continue;
		}		
		else if(i == 11 && GetConVarInt(ItemCosts[CostKnife]) < 0)
		{
			continue;
		}		
		else if(i == 12 && GetConVarInt(ItemCosts[CostShield]) < 0)
		{
			continue;
		}	
		Format(container, sizeof(container), "%T", validmelee[i], LANG_SERVER);
		AddMenuItem(menu, validmelee[i], container);
	}	
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildSniperMenu(client)
{
	decl String:hunting_rifle[40], String:title[40], String:sniper_military[40], String:sniper_scout[40], String:sniper_awp[40];
	new Handle:menu = CreateMenu(MenuHandler_Snipers);
	if(GetConVarInt(ItemCosts[CostHunting]) > -1)
	{
		Format(hunting_rifle, sizeof(hunting_rifle), "%T", "Hunting Rifle", LANG_SERVER);
		AddMenuItem(menu, "weapon_hunting_rifle", hunting_rifle);
	}
	if(GetConVarInt(ItemCosts[CostMilitary]) > -1)
	{
		Format(sniper_military, sizeof(sniper_military), "%T", "Military Sniper", LANG_SERVER);
		AddMenuItem(menu, "weapon_sniper_military", sniper_military);
	}
	if(GetConVarInt(ItemCosts[CostAWP]) > -1)
	{
		Format(sniper_awp, sizeof(sniper_awp), "%T", "AWP", LANG_SERVER);
		AddMenuItem(menu, "weapon_sniper_awp", sniper_awp);
	}
	if(GetConVarInt(ItemCosts[CostScout]) > -1)
	{
		Format(sniper_scout, sizeof(sniper_scout), "%T", "Scout Sniper", LANG_SERVER);
		AddMenuItem(menu, "weapon_sniper_scout", sniper_scout);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildRiflesMenu(client)
{
	decl String:rifle[40], String:title[40], String:rifle_desert[40], String:rifle_ak47[40], String:rifle_sg552[40], String:rifle_m60[40];
	new Handle:menu = CreateMenu(MenuHandler_Rifles);
	if(GetConVarInt(ItemCosts[CostM60]) > -1)
	{
		Format(rifle_m60, sizeof(rifle_m60), "%T", "M60", LANG_SERVER);
		AddMenuItem(menu, "weapon_rifle_m60", rifle_m60);
	}
	if(GetConVarInt(ItemCosts[CostM16]) > -1)
	{
		Format(rifle, sizeof(rifle), "%T", "M16", LANG_SERVER);
		AddMenuItem(menu, "weapon_rifle", rifle);
	}
	if(GetConVarInt(ItemCosts[CostSCAR]) > -1)
	{
		Format(rifle_desert, sizeof(rifle_desert), "%T", "SCAR", LANG_SERVER);
		AddMenuItem(menu, "weapon_rifle_desert", rifle_desert);
	}
	if(GetConVarInt(ItemCosts[CostAK47]) > -1)
	{
		Format(rifle_ak47, sizeof(rifle_ak47), "%T", "AK-47", LANG_SERVER);
		AddMenuItem(menu, "weapon_rifle_ak47", rifle_ak47);
	}
	if(GetConVarInt(ItemCosts[CostSG552]) > -1)
	{
		Format(rifle_sg552, sizeof(rifle_sg552), "%T", "SG552", LANG_SERVER);
		AddMenuItem(menu, "weapon_rifle_sg552", rifle_sg552);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildShotgunMenu(client)
{
	decl String:autoshotgun[40], String:shotgun_chrome[40], String:shotgun_spas[40], String:pumpshotgun[40], String:title[40]; 
	new Handle:menu = CreateMenu(MenuHandler_Shotguns);
	if(GetConVarInt(ItemCosts[CostAuto]) > -1)
	{
		Format(autoshotgun, sizeof(autoshotgun), "%T", "Auto Shotgun", LANG_SERVER);
		AddMenuItem(menu, "weapon_autoshotgun", autoshotgun);
	}
	if(GetConVarInt(ItemCosts[CostChrome]) > -1)
	{
		Format(shotgun_chrome, sizeof(shotgun_chrome), "%T", "Chrome Shotgun", LANG_SERVER);
		AddMenuItem(menu, "weapon_shotgun_chrome", shotgun_chrome);
	}
	if(GetConVarInt(ItemCosts[CostSPAS]) > -1)
	{
		Format(shotgun_spas, sizeof(shotgun_spas), "%T", "Spas Shotgun", LANG_SERVER);
		AddMenuItem(menu, "weapon_shotgun_spas", shotgun_spas);
	}
	if(GetConVarInt(ItemCosts[CostPump]) > -1)
	{
		Format(pumpshotgun, sizeof(pumpshotgun), "%T", "Pump Shotgun", LANG_SERVER);
		AddMenuItem(menu, "weapon_pumpshotgun", pumpshotgun);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildSMGMenu(client)
{
	decl String:smg[40], String:title[40], String:smg_silenced[40], String:smg_mp5[40];
	new Handle:menu = CreateMenu(MenuHandler_SMG);
	if(GetConVarInt(ItemCosts[CostSMG]) > -1)
	{
		Format(smg, sizeof(smg), "%T", "SMG", LANG_SERVER);
		AddMenuItem(menu, "weapon_smg", smg);
	}
	if(GetConVarInt(ItemCosts[CostSilencedSMG]) > -1)
	{
		Format(smg_silenced, sizeof(smg_silenced), "%T", "Silenced SMG", LANG_SERVER);
		AddMenuItem(menu, "weapon_smg_silenced", smg_silenced);
	}
	if(GetConVarInt(ItemCosts[CostMP5]) > -1)
	{
		Format(smg_mp5, sizeof(smg_mp5), "%T", "MP5", LANG_SERVER);
		AddMenuItem(menu, "weapon_smg_mp5", smg_mp5);
	}
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildHealthMenu(client)
{
	decl String:adrenaline[40], String:defibrillator[40], String:first_aid_kit[40], String:pain_pills[40], String:health[40], String:title[40]; 
	new Handle:menu = CreateMenu(MenuHandler_Health);
	if(GetConVarInt(ItemCosts[CostHealthKit]) > -1)
	{
		Format(first_aid_kit, sizeof(first_aid_kit), "%T", "First Aid", LANG_SERVER);
		AddMenuItem(menu, "weapon_first_aid_kit", first_aid_kit);
	}
	if(GetConVarInt(ItemCosts[CostDefib]) > -1)
	{
		Format(defibrillator, sizeof(defibrillator), "%T", "Defib2", LANG_SERVER);
		AddMenuItem(menu, "weapon_defibrillator", defibrillator);
	}
	if(GetConVarInt(ItemCosts[CostPills]) > -1)
	{
		Format(pain_pills, sizeof(pain_pills), "%T", "Pills", LANG_SERVER);
		AddMenuItem(menu, "weapon_pain_pills", pain_pills);
	}
	if(GetConVarInt(ItemCosts[CostAdren]) > -1)
	{
		Format(adrenaline, sizeof(adrenaline), "%T", "Adrenaline", LANG_SERVER);
		AddMenuItem(menu, "weapon_adrenaline", adrenaline);
	}
	if(GetConVarInt(ItemCosts[CostHeal]) > -1)
	{
		Format(health, sizeof(health), "%T", "Full Heal", LANG_SERVER);
		AddMenuItem(menu, "health", health);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildThrowablesMenu(client)
{
	decl String:molotov[40], String:pipe_bomb[40], String:vomitjar[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_Throwables);
	if(GetConVarInt(ItemCosts[CostMolotov]) > -1)
	{
		Format(molotov, sizeof(molotov), "%T", "Molotov", LANG_SERVER);
		AddMenuItem(menu, "weapon_molotov", molotov);
	}
	if(GetConVarInt(ItemCosts[CostPipe]) > -1)
	{
		Format(pipe_bomb, sizeof(pipe_bomb), "%T", "Pipe Bomb", LANG_SERVER);
		AddMenuItem(menu, "weapon_pipe_bomb", pipe_bomb);
	}
	if(GetConVarInt(ItemCosts[CostBile]) > -1)
	{
		Format(vomitjar, sizeof(vomitjar), "%T", "Bile Bomb", LANG_SERVER);
		AddMenuItem(menu, "weapon_vomitjar", vomitjar);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildMiscMenu(client)
{
	decl String:grenade_launcher[40], String:fireworkcrate[40], String:gascan[40], String:oxygentank[40], String:propanetank[40], String:pistol[40], String:pistol_magnum[40], String:title[40];
	decl String:gnome[40], String:cola_bottles[40], String:chainsaw[40];
	new Handle:menu = CreateMenu(MenuHandler_Misc);
	if(GetConVarInt(ItemCosts[CostLauncher]) > -1)
	{
		Format(grenade_launcher, sizeof(grenade_launcher), "%T", "Grenade Launcher", LANG_SERVER);
		AddMenuItem(menu, "weapon_grenade_launcher", grenade_launcher);
	}
	if(GetConVarInt(ItemCosts[CostPistol]) > -1)
	{
		Format(pistol, sizeof(pistol), "%T", "Pistol", LANG_SERVER);
		AddMenuItem(menu, "weapon_pistol", pistol);
	}
	if(GetConVarInt(ItemCosts[CostMagnum]) > -1)
	{
		Format(pistol_magnum, sizeof(pistol_magnum), "%T", "Magnum", LANG_SERVER);
		AddMenuItem(menu, "weapon_pistol_magnum", pistol_magnum);
	}
	if(GetConVarInt(ItemCosts[CostChainSaw]) > -1)
	{
		Format(chainsaw, sizeof(chainsaw), "%T", "Chainsaw", LANG_SERVER);
		AddMenuItem(menu, "weapon_chainsaw", chainsaw);
	}
	if(GetConVarInt(ItemCosts[CostGnome]) > -1)
	{
		Format(gnome, sizeof(gnome), "%T", "Gnome", LANG_SERVER);
		AddMenuItem(menu, "weapon_gnome", gnome);
	}
	if(!StrEqual(MapName, "c1m2_streets", false) && GetConVarInt(ItemCosts[CostCola]) > -1)
	{
		Format(cola_bottles, sizeof(cola_bottles), "%T", "Cola Bottles", LANG_SERVER);
		AddMenuItem(menu, "weapon_cola_bottles", cola_bottles);
	}
	if(GetConVarInt(ItemCosts[CostFireworks]) > -1)
	{
		Format(fireworkcrate, sizeof(fireworkcrate), "%T", "Fireworks Crate", LANG_SERVER);
		AddMenuItem(menu, "weapon_fireworkcrate", fireworkcrate);
	}
	new String:gamemode[20];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if(!StrEqual(gamemode, "scavenge", false) && GetConVarInt(ItemCosts[CostGasCan]) > -1)
	{
		Format(gascan, sizeof(gascan), "%T", "Gascan", LANG_SERVER);
		AddMenuItem(menu, "weapon_gascan", gascan);
	}	
	if(GetConVarInt(ItemCosts[CostOxygen]) > -1)
	{
		Format(oxygentank, sizeof(oxygentank), "%T", "Oxygen Tank", LANG_SERVER);
		AddMenuItem(menu, "weapon_oxygentank", oxygentank);
	}
	if(GetConVarInt(ItemCosts[CostPropane]) > -1)
	{
		Format(propanetank, sizeof(propanetank), "%T", "Propane Tank", LANG_SERVER);
		AddMenuItem(menu, "weapon_propanetank", propanetank);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

BuildUpgradesMenu(client)
{
	decl String:upgradepack_explosive[40], String:upgradepack_incendiary[40], String:title[40];
	decl String:laser_sight[40], String:explosive_ammo[40], String:incendiary_ammo[40], String:ammo[40];
	new Handle:menu = CreateMenu(MenuHandler_Upgrades);
	if(GetConVarInt(ItemCosts[CostLaserSight]) > -1)
	{
		Format(laser_sight, sizeof(laser_sight), "%T", "Laser Sight", LANG_SERVER);
		AddMenuItem(menu, "laser_sight", laser_sight);
	}
	if(GetConVarInt(ItemCosts[CostExplosiveAmmo]) > -1)
	{
		Format(explosive_ammo, sizeof(explosive_ammo), "%T", "Explosive Ammo", LANG_SERVER);
		AddMenuItem(menu, "explosive_ammo", explosive_ammo);
	}
	if(GetConVarInt(ItemCosts[CostFireAmmo]) > -1)
	{
		Format(incendiary_ammo, sizeof(incendiary_ammo), "%T", "Incendiary Ammo", LANG_SERVER);
		AddMenuItem(menu, "incendiary_ammo", incendiary_ammo);
	}
	if(GetConVarInt(ItemCosts[CostExplosivePack]) > -1)
	{
		Format(upgradepack_explosive, sizeof(upgradepack_explosive), "%T", "Explosive Ammo Pack", LANG_SERVER);
		AddMenuItem(menu, "upgradepack_explosive", upgradepack_explosive);
	}
	if(GetConVarInt(ItemCosts[CostFirePack]) > -1)
	{
		Format(upgradepack_incendiary, sizeof(upgradepack_incendiary), "%T", "Incendiary Ammo Pack", LANG_SERVER);
		AddMenuItem(menu, "upgradepack_incendiary", upgradepack_incendiary);
	}
	if(GetConVarInt(ItemCosts[CostAmmo]) > -1)
	{
		Format(ammo, sizeof(ammo), "%T", "Ammo", LANG_SERVER);
		AddMenuItem(menu, "ammo", ammo);
	}
	Format(title, sizeof(title),"%T", "Points Left", LANG_SERVER, PlayerData[client][iPlayerPoints]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Melee(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "crowbar", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give crowbar");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostCrowBar]);
			}
			else if(StrEqual(item1, "cricket_bat", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give cricket_bat");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostCricketBat]);
			}		
			else if(StrEqual(item1, "baseball_bat", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give baseball_bat");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostBat]);
			}
			else if(StrEqual(item1, "machete", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give machete");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostMachete]);
			}
			else if(StrEqual(item1, "tonfa", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give tonfa");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostTonfa]);
			}
			else if(StrEqual(item1, "katana", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give katana");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostKatana]);
			}
			else if(StrEqual(item1, "knife", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give knife");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostKnife]);
			}
			else if(StrEqual(item1, "hunting_knife", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give hunting_knife");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostKnife]);
			}
			else if(StrEqual(item1, "riotshield", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give riotshield");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostShield]);
			}
			else if(StrEqual(item1, "fireaxe", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give fireaxe");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostFireAxe]);
			}
			else if(StrEqual(item1, "electric_guitar", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give electric_guitar");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostGuitar]);
			}
			else if(StrEqual(item1, "frying_pan", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give frying_pan");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostPan]);
			}
			else if(StrEqual(item1, "golfclub", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give golfclub");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostClub]);
			}
			DisplayConfirmMenuMelee(param1);
		}
	}
}	

public MenuHandler_SMG(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));			
			if(StrEqual(item1, "weapon_smg", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give smg");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostSMG]);
			}
			else if(StrEqual(item1, "weapon_smg_silenced", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give smg_silenced");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostSilencedSMG]);
			}
			else if(StrEqual(item1, "weapon_smg_mp5", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give smg_mp5");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostMP5]);
			}
			DisplayConfirmMenuSMG(param1);
		}
	}
}	
			
public MenuHandler_Rifles(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));			
			if(StrEqual(item1, "weapon_rifle", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give weapon_rifle");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostM16]);
			}
			else if(StrEqual(item1, "weapon_rifle_desert", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give rifle_desert");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostSCAR]);
			}
			else if(StrEqual(item1, "weapon_rifle_ak47", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give rifle_ak47");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostAK47]);
			}
			else if(StrEqual(item1, "weapon_rifle_sg552", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give rifle_sg552");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostSG552]);
			}
			else if(StrEqual(item1, "weapon_rifle_m60", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give rifle_m60");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostM60]);
			}
			DisplayConfirmMenuRifles(param1);
		}
	}
}	
			
public MenuHandler_Snipers(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));			
			if(StrEqual(item1, "weapon_hunting_rifle", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give hunting_rifle");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostHunting]);
			}
			else if(StrEqual(item1, "weapon_sniper_scout", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give sniper_scout");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostScout]);
			}
			else if(StrEqual(item1, "weapon_sniper_awp", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give sniper_awp");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostScout]);
			}
			else if(StrEqual(item1, "weapon_sniper_military", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give sniper_military");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostMilitary]);
			}
			DisplayConfirmMenuSnipers(param1);
		}
	}
}	
			
public MenuHandler_Shotguns(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));			
			if(StrEqual(item1, "weapon_shotgun_chrome", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give shotgun_chrome");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostChrome]);
			}
			else if(StrEqual(item1, "weapon_pumpshotgun", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give pumpshotgun");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostPump]);
			}
			else if(StrEqual(item1, "weapon_autoshotgun", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give autoshotgun");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostAuto]);
			}
			else if(StrEqual(item1, "weapon_shotgun_spas", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give shotgun_spas");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostSPAS]);
			}
			DisplayConfirmMenuShotguns(param1);
		}
	}
}	
			
public MenuHandler_Throwables(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));			
			if(StrEqual(item1, "weapon_molotov", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give molotov");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostMolotov]);
			}
			else if(StrEqual(item1, "weapon_pipe_bomb", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give pipe_bomb");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostPipe]);
			}
			else if(StrEqual(item1, "weapon_vomitjar", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give vomitjar");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostBile]);
			}
			DisplayConfirmMenuThrow(param1);
		}
	}
}	
			
public MenuHandler_Misc(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildWeaponsMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "weapon_pistol", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give pistol");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostPistol]);
			}
			else if(StrEqual(item1, "weapon_pistol_magnum", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give pistol_magnum");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostMagnum]);
			}
			else if(StrEqual(item1, "weapon_grenade_launcher", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give grenade_launcher");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostLauncher]);
			}
			else if(StrEqual(item1, "weapon_chainsaw", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give chainsaw");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostChainSaw]);
			}
			else if(StrEqual(item1, "weapon_gnome", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give gnome");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostGnome]);
			}
			else if(StrEqual(item1, "weapon_cola_bottles", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give cola_bottles");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostCola]);
			}
			else if(StrEqual(item1, "weapon_gascan", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give gascan");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostGasCan]);
			}
			else if(StrEqual(item1, "weapon_propanetank", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give propanetank");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostPropane]);
			}
			else if(StrEqual(item1, "weapon_fireworkcrate", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give fireworkcrate");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostFireworks]);
			}
			else if(StrEqual(item1, "weapon_oxygentank", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give oxygentank");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostOxygen]);
			}
			DisplayConfirmMenuMisc(param1);
		}
	}
}

public MenuHandler_Health(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildBuyMenu(param1);
			}
		}
	case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "weapon_first_aid_kit", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give first_aid_kit");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostHealthKit]);
			}
			else if(StrEqual(item1, "weapon_defibrillator", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give defibrillator");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostDefib]);
			}
			else if(StrEqual(item1, "weapon_pain_pills", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give pain_pills");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostPills]);
			}
			else if(StrEqual(item1, "weapon_adrenaline", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give adrenaline");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostAdren]);
			}
			else if(StrEqual(item1, "health", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give health");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostHeal]);
			}
			DisplayConfirmMenuHealth(param1);
		}
	}
}

public MenuHandler_Upgrades(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildBuyMenu(param1);
			}
		}	
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "upgradepack_explosive", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give upgradepack_explosive");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostExplosiveAmmo]);
			}
			else if(StrEqual(item1, "upgradepack_incendiary", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give upgradepack_incendiary");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostFireAmmo]);
			}
			else if(StrEqual(item1, "explosive_ammo", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "upgrade_add EXPLOSIVE_AMMO");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostExplosivePack]);
			}
			else if(StrEqual(item1, "incendiary_ammo", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "upgrade_add INCENDIARY_AMMO");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostFirePack]);
			}
			else if(StrEqual(item1, "laser_sight", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "upgrade_add LASER_SIGHT");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostLaserSight]);
			}
			else if(StrEqual(item1, "ammo", false))
			{
				strcopy(PlayerData[param1][sItemName], 64, "give ammo");
				PlayerData[param1][iItemCost] = GetConVarInt(ItemCosts[CostAmmo]);
			}
			DisplayConfirmMenuUpgrades(param1);
		}
	}
}	

public InfectedMenu(Handle:hMenu, MenuAction:action, iClientIndex, iPosition)
{
	switch(action)
	{
	case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
	case MenuAction_Select:
		{
			decl String:sItem[64]; sItem[0] = '\0';
			GetMenuItem(hMenu, iPosition, sItem, sizeof(sItem));
			if (StrEqual(sItem, "heal", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "give health");
				if(IsClientTank(iClientIndex))
					PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostInfectedHeal])*GetConVarInt(ItemCosts[CostTankHealMultiplier]);
				else
					PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostInfectedHeal]);
			}
			else if (StrEqual(sItem, "suicide", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "suicide");
				if(IsClientTank(iClientIndex))
					PlayerData[iClientIndex][iItemCost] = 0;
				else
					PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostSuicide]);
			}		
			else if (StrEqual(sItem, "boomer", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old boomer auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostBoomer]);
			}
			else if (StrEqual(sItem, "spitter", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old spitter auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostSpitter]);
			}
			else if (StrEqual(sItem, "smoker", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old smoker auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostSmoker]);
			}
			else if (StrEqual(sItem, "hunter", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old hunter auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostHunter]);
			}
			else if (StrEqual(sItem, "charger", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old charger auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostCharger]);
			}
			else if (StrEqual(sItem, "jockey", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old jockey auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostJockey]);
			}
			else if (StrEqual(sItem, "witch", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old witch auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostWitch]);
			}
			else if (StrEqual(sItem, "witch_bride", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old witch_bride auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostWitch]);
			}
			else if (StrEqual(sItem, "tank", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old tank auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostTank]);
			}
			else if (StrEqual(sItem, "horde", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "director_force_panic_event");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostHorde]);
			}
			else if (StrEqual(sItem, "mob", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old mob auto");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostMob]);
			}
			else if (StrEqual(sItem, "uncommon_mob", false))
			{
				strcopy(PlayerData[iClientIndex][sItemName], 64, "z_spawn_old mob");
				PlayerData[iClientIndex][iItemCost] = GetConVarInt(ItemCosts[CostUncommonMob]);
			}
			DisplayConfirmMenuI(iClientIndex);
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{	
	if(StrEqual(classname, "infected", false) && CounterData[iUCommonLeft] > 0)
	{
		new rand = GetRandomInt(1, 6);
		switch(rand)
		{
			case 1:
			{
				SetEntityModel(entity, "models/infected/common_male_riot.mdl");
			}
			case 2:
			{
				SetEntityModel(entity, "models/infected/common_male_ceda.mdl");
			}
			case 3:
			{
				SetEntityModel(entity, "models/infected/common_male_clown.mdl");
			}
			case 4:
			{
				SetEntityModel(entity, "models/infected/common_male_mud.mdl");
			}
			case 5:
			{
				SetEntityModel(entity, "models/infected/common_male_roadcrew.mdl");
			}
			case 6:
			{
				SetEntityModel(entity, "models/infected/common_male_fallen_survivor.mdl");
			}
		}	
		CounterData[iUCommonLeft]--;
	}	
}

DisplayConfirmMenuMelee(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmMelee);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuSMG(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmSMG);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuRifles(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmRifles);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuSnipers(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmSniper);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuShotguns(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmShotguns);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuThrow(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmThrow);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuMisc(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmMisc);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuHealth(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmHealth);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}

DisplayConfirmMenuUpgrades(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmUpgrades);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}	

DisplayConfirmMenuI(param1)
{
	decl String:yes[40], String:no[40], String:title[40];
	new Handle:menu = CreateMenu(MenuHandler_ConfirmI);
	Format(yes, sizeof(yes),"%T", "Yes", LANG_SERVER);
	AddMenuItem(menu, "yes", yes);
	Format(no, sizeof(no),"%T", "No", LANG_SERVER);
	AddMenuItem(menu, "no", no);
	Format(title, sizeof(title),"%T", "Cost", LANG_SERVER, PlayerData[param1][iItemCost]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, param1, MENU_TIME_FOREVER);
}	

public MenuHandler_ConfirmMelee(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildMeleeMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildMeleeMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}	
			}	
		}
	}
}	

public MenuHandler_ConfirmRifles(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildRiflesMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildRiflesMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}	
			}
		}
	}
}	

public MenuHandler_ConfirmSniper(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildSniperMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildSniperMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}	
			}
		}
	}
}	

public MenuHandler_ConfirmSMG(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildSMGMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildSMGMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}	
			}
		}
	}
}	

public MenuHandler_ConfirmShotguns(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildShotgunMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildShotgunMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}	
			}
		}
	}
}	

public MenuHandler_ConfirmThrow(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildThrowablesMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildThrowablesMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}	
			}
		}
	}
}	

public MenuHandler_ConfirmMisc(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildMiscMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildMiscMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
				{
					strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
					PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
					removePoints(param1, PlayerData[param1][iItemCost]);
					execClientCommand(param1, PlayerData[param1][sItemName]);
				}	
			}
		}
	}
}	

public MenuHandler_ConfirmHealth(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildHealthMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildHealthMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if(StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost])){
					if(StrEqual(PlayerData[param1][sItemName], "give health", false))
					{
						strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
						PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
						removePoints(param1, PlayerData[param1][iItemCost]);
						execClientCommand(param1, PlayerData[param1][sItemName]);
						SetEntPropFloat(param1, Prop_Send, "m_healthBuffer", 0.0);
					}	
					else
					{	
						strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
						PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
						removePoints(param1, PlayerData[param1][iItemCost]);
						execClientCommand(param1, PlayerData[param1][sItemName]);
					}
				}	
			}
		}
	}
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
			if(hGunControl_m60 != null){
				iAmmo_m60 = GetConVarInt(hGunControl_m60);
				CloseHandle(hGunControl_m60);
			}
			SetEntProp(hWeapon, Prop_Data, "m_iClip1", iAmmo_m60, 1);
		}
		else if(StrEqual(sWeapon, "weapon_grenade_launcher", false)){
			new iAmmo_Launcher = 30;
			new Handle:hGunControl_Launcher = FindConVar("l4d2_guncontrol_grenadelauncherammo");
			if(hGunControl_Launcher != null){
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

public MenuHandler_ConfirmUpgrades(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				BuildUpgradesMenu(param1);
			}
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildUpgradesMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if (StrEqual(choice, "yes", false))
			{
				if(HasEnoughPoints(param1, PlayerData[param1][iItemCost])){
					if(StrEqual(PlayerData[param1][sItemName], "give ammo", false))
						reloadAmmo(param1, PlayerData[param1][iItemCost], PlayerData[param1][sItemName]);
					else
					{
						strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
						PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
						removePoints(param1, PlayerData[param1][iItemCost]);
						execClientCommand(param1, PlayerData[param1][sItemName]);
					}
				}
			}
		}
	}
}	

public MenuHandler_ConfirmI(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
			PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
		}
		case MenuAction_Select:
		{
			decl String:choice[40];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			if (StrEqual(choice, "no", false))
			{
				BuildBuyMenu(param1);
				strcopy(PlayerData[param1][sItemName], 64, PlayerData[param1][sBought]);
				PlayerData[param1][iItemCost] = PlayerData[param1][iBoughtCost];
			}
			else if(StrEqual(choice, "yes", false))
			{
				if(!HasEnoughPoints(param1, PlayerData[param1][iItemCost]))
					return;
				
				if(StrEqual(PlayerData[param1][sItemName], "suicide", false))
				{
					performSuicide(param1, PlayerData[param1][iItemCost]);
					return;
				}
				else if(StrEqual(PlayerData[param1][sItemName], "z_spawn_old mob", false))
				{
					CounterData[iUCommonLeft] += GetConVarInt(FindConVar("z_common_limit"));
				}	
				else if(StrEqual(PlayerData[param1][sItemName], "z_spawn_old tank auto", false))
				{
					if(CounterData[iTanksSpawned] == GetConVarInt(PluginSettings[hTankLimit]))
					{
						PrintToChat(param1,  "%T", "Tank Limit", LANG_SERVER);
						return;
					}	
					CounterData[iTanksSpawned]++;
				}
				else if(StrEqual(PlayerData[param1][sItemName], "z_spawn_old witch auto", false) || StrEqual(PlayerData[param1][sItemName], "z_spawn_old witch_bride auto", false))
				{
					if(CounterData[iWitchesSpawned] == GetConVarInt(PluginSettings[hWitchLimit]))
					{
						PrintToChat(param1,  "%T", "Witch Limit", LANG_SERVER);
						return;
					}
					CounterData[iWitchesSpawned]++;
				}
				else if(StrContains(PlayerData[param1][sItemName], "z_spawn_old", false) != -1 && StrContains(PlayerData[param1][sItemName], "mob", false) == -1)
				{
					if(IsPlayerAlive(param1) || IsPlayerGhost(param1))
					{
						return;
					}	
					new bool:resetGhost[MaxClients+1], bool:resetAlive[MaxClients+1], bool:resetLifeState[MaxClients+1];
					for(new i=1;i<=MaxClients;i++)
					{
						if(i == param1 || !IsClientInGame(i) || GetClientTeam(i) != 3 || IsFakeClient(i))
						{
							continue;
						}
						
						if(IsPlayerGhost(i))
						{
							resetGhost[i] = true;
							resetAlive[i] = true;
							SetPlayerGhost(i, false);
							SetPlayerAlive(i, true);
						}
						else if(!IsPlayerAlive(i))
						{
							resetLifeState[i] = true;
							SetPlayerLifeState(i, false);
						}	
					}

					execClientCommand(param1, PlayerData[param1][sItemName]);
					
					new maxretry = GetConVarInt(PluginSettings[hSpawnAttempts]);
					for(new i;i<maxretry;i++)
					{
						if(!IsPlayerAlive(param1))
						{
							execClientCommand(param1, PlayerData[param1][sItemName]);
						}	
					}
					
					if(IsPlayerAlive(param1))
					{
						strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
						PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
						removePoints(param1, PlayerData[param1][iItemCost]);
					}
					else
					{
						PrintToChat(param1, "%s %T", MSGTAG, "Spawn Failed", param1);
					}	
					

					for(new i=1;i<=MaxClients;i++)
					{
						if (resetGhost[i]) SetPlayerGhost(i, true);
						if (resetAlive[i]) SetPlayerAlive(i, false);
						if (resetLifeState[i]) SetPlayerLifeState(i, true);
					}
					return;
				}	
				strcopy(PlayerData[param1][sBought], 64, PlayerData[param1][sItemName]);
				PlayerData[param1][iBoughtCost] = PlayerData[param1][iItemCost];
				removePoints(param1, PlayerData[param1][iItemCost]);
				execClientCommand(param1, PlayerData[param1][sItemName]);
			}
		}
	}
}

stock SetPlayerLifeState(client, bool:lifestate)
{
	SetEntData(client, SendProp_LifeState, lifestate, 1);
}

stock SetPlayerAlive(client, bool:alive)
{
	SetEntData(client, SendProp_IsAlive, alive, 1, true);
}

stock SetPlayerGhost(client, bool:ghost)
{
	SetEntData(client, SendProp_IsGhost, ghost, 1);
}