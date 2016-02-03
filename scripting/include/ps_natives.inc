#if defined _ps
 #endinput
#endif
#define _ps

/**
 * Gets the status of the points system
 *
 * @return Boolean value corresponding to the status of the points system. false if disabled, true if enabled.
*/
native PS_IsSystemEnabled();

/**
 * Gets the version of PS
 *
 * @return				current version of ps system in form of a float
 */
native PS_GetVersion();

/**
 * Sets a client's points
 *
 * @param client			client index
 * @param newval			new value of a client's points
 * @return				none
 */
native PS_SetPoints(client, newval);

/**
 * Deduct's points from client
 *
 * @param iClientIndex		client index
 * @param iCost				Points to deduct
 * @return					none
 */
native PS_RemovePoints(iClientIndex, iCost);

/**
 * Sets a client's item string
 *
 * @param client			client index
 * @param newstring			new value of a client's item string
 * @return				none
 */
native PS_SetItem(client, String:newstring[]);

/**
 * Sets a client's item cost
 *
 * @param client			client index
 * @param newval			new value of a client's points
 * @return				none
 */
native PS_SetCost(client, newval);

/**
 * Sets a client's bought string
 *
 * @param client			client index
 * @param newstring			new value of a client's bought string
 * @return				none
 */
native PS_SetBought(client, String:newstring[]);

/**
 * Sets a client's bought cost
 *
 * @param client			client index
 * @param newval			new value of a client's points
 * @return				none
 */
native PS_SetBoughtCost(client, newval);

/**
 * Sets up an uncommon mob
 *
 * @param newval		amount of uncommon to spawn
 * @return				none
 */
native PS_SetupUMob(newval);

/**
 * Gets a client's bought cost
 *
 * @param client			client index
 * @return				boughtcost
 */
native PS_GetBoughtCost(client);

/**
 * Gets a client's points
 *
 * @param client			client index
 * @return				points
 */
native PS_GetPoints(client);

/**
 * Gets a client's current item cost
 *
 * @param client			client index
 * @return				cost
 */
native PS_GetCost(client);

/**
 * Gets a client's current item
 *
 * @param client			client index
 * @param dest				destination for the item string to go
 * @return				cost
 */
native PS_GetItem(client, String:dest[]);

/**
 * Gets a client's current bought item
 *
 * @param client		client index
 * @param dest			destination for the bought string to go
 * @return				cost
 */
native PS_GetBought(client, String:dest[]);

/**
 * Registers a module for points system
 *
 * @param modulename	String that contains the module to be registered's name
 * @return				false if successful true if already registered
 */
 native bool:PS_RegisterModule(String:modulename[]);
 
 /**
 * Unregisters a module for points system
 *
 * @param modulename	String that contains the module to be unregistered's name
 * @return				none
 */
 native PS_UnregisterModule(String:modulename[]);
 
  /**
 * Called when Points System is loaded
 *
 * @param late			if PS was late loaded this will be true
 * @return				none
 */
 forward OnPSLoaded(bool:late);
 
  /**
 * Called when Points System is unloaded
 *
 * @param late			if PS was late loaded this will be true
 * @return				none
 */
 forward OnPSUnloaded();
