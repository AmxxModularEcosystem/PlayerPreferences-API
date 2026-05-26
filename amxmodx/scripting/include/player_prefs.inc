#if defined _player_prefs_included
  #endinput
#endif
#define _player_prefs_included

#pragma reqlib player_prefs_core

const MAX_KEY_LENGTH   = 64;
const MAX_VALUE_LENGTH = 256;

/**
 * Called once after the core and provider finish initialization.
 *
 * This is the correct place to call pp_register_key().
 * If success is false the provider failed to connect;
 * keys can still be registered in memory but nothing will
 * be persisted to storage.
 *
 * @param success   true if the storage provider is ready.
 */
forward pp_initialized(const bool: success);

/**
 * Called when all preferences for a player have been loaded
 * from storage and are ready to read.
 *
 * @param playerIndex   Player index (1..MAX_PLAYERS).
 */
forward pp_player_loaded(const playerIndex);

/**
 * Called after a player's preference has been written to storage.
 *
 * @param playerIndex   Player index.
 */
forward pp_player_saved(const playerIndex);

/**
 * Returns true if the player's preferences are fully loaded
 * from storage and safe to read or write.
 *
 * @param playerIndex   Player index (1..MAX_PLAYERS).
 * @return              true if loaded.
 */
native bool: pp_is_loaded(const playerIndex);

/**
 * Gets the player's string preference.
 * Falls back to the key's registered default if no value is stored.
 *
 * @param playerIndex   Player index.
 * @param key           Preference key name.
 * @param dest          Destination buffer.
 * @param destLen       Size of the destination buffer.
 * @return              true on success.
 */
native bool: pp_get_string(const playerIndex, const key[], dest[], destLen);

/**
 * Gets the player's integer preference.
 * Falls back to defaultValue if no value is stored.
 *
 * @param playerIndex   Player index.
 * @param key           Preference key name.
 * @param defaultValue  Value returned when nothing is stored.
 * @return              Stored value or defaultValue.
 */
native pp_get_int(const playerIndex, const key[], defaultValue = 0);

/**
 * Gets the player's float preference.
 * Falls back to defaultValue if no value is stored.
 *
 * @param playerIndex   Player index.
 * @param key           Preference key name.
 * @param defaultValue  Value returned when nothing is stored.
 * @return              Stored value or defaultValue.
 */
native Float: pp_get_float(const playerIndex, const key[], Float: defaultValue = 0.0);

/**
 * Gets the player's boolean preference.
 * Falls back to defaultValue if no value is stored.
 *
 * @param playerIndex   Player index.
 * @param key           Preference key name.
 * @param defaultValue  Value returned when nothing is stored.
 * @return              Stored value or defaultValue.
 */
native bool: pp_get_bool(const playerIndex, const key[], bool: defaultValue = false);

/**
 * Sets the player's string preference.
 *
 * @param playerIndex   Player index.
 * @param key           Preference key name.
 * @param value         New value.
 * @param defaultValue  Default forwarded to the provider for key registration.
 * @return              true on success.
 */
native bool: pp_set_string(const playerIndex, const key[], const value[], const defaultValue[] = "");

/**
 * Sets the player's integer preference.
 *
 * @param playerIndex   Player index.
 * @param key           Preference key name.
 * @param value         New value.
 * @param defaultValue  Default forwarded to the provider for key registration.
 * @return              true on success.
 */
native bool: pp_set_int(const playerIndex, const key[], value, defaultValue = 0);

/**
 * Sets the player's float preference.
 *
 * @param playerIndex   Player index.
 * @param key           Preference key name.
 * @param value         New value.
 * @param defaultValue  Default forwarded to the provider for key registration.
 * @return              true on success.
 */
native bool: pp_set_float(const playerIndex, const key[], Float: value, Float: defaultValue = 0.0);

/**
 * Sets the player's boolean preference.
 *
 * @param playerIndex   Player index.
 * @param key           Preference key name.
 * @param value         New value.
 * @param defaultValue  Default forwarded to the provider for key registration.
 * @return              true on success.
 */
native bool: pp_set_bool(const playerIndex, const key[], bool: value, bool: defaultValue = false);

/**
 * Registers a key and its default value with the active provider.
 *
 * Call from pp_initialized. Safe to call multiple times —
 * subsequent calls update the stored default value.
 *
 * @param key           Preference key name.
 * @param defaultValue  String representation of the default value.
 * @return              true on success.
 */
native bool: pp_register_key(const key[], const defaultValue[] = "");

/**
 * Core requests the provider to open the storage connection.
 * Must finish by calling pp_provider_ready() exactly once.
 */
forward pp_provider_connect();

/**
 * Core requests the provider to load all known keys from storage.
 * Call pp_provider_key_loaded() for each key,
 * then pp_provider_keys_done() when done.
 */
forward pp_provider_load_keys();

/**
 * Core requests the provider to load all preferences for a player.
 * Call pp_provider_pref_loaded() for each stored key/value pair,
 * then pp_provider_player_done() when done (even if nothing was found).
 *
 * @param playerIndex   Player index.
 * @param authId        Player's SteamID string.
 */
forward pp_provider_load_player(const playerIndex, const authId[]);

/**
 * Core requests the provider to persist one preference for a player.
 *
 * @param playerIndex   Player index.
 * @param authId        Player's SteamID string.
 * @param key           Preference key name.
 * @param value         String value to store.
 */
forward pp_provider_save_pref(const playerIndex, const authId[], const key[], const value[]);

/**
 * Core requests the provider to register or update a key's default value.
 *
 * @param key           Preference key name.
 * @param defaultValue  Default value string.
 */
forward pp_provider_register_key(const key[], const defaultValue[]);

/**
 * Reports the result of the connection attempt to the core.
 * Must be called exactly once after pp_provider_connect fires.
 *
 * @param success   true if the storage is open and ready.
 */
native pp_provider_ready(const bool: success);

/**
 * Passes one key from storage to the core.
 * Call inside the pp_provider_load_keys handler, once per key.
 *
 * @param key           Preference key name.
 * @param defaultValue  Stored default value for this key.
 */
native pp_provider_key_loaded(const key[], const defaultValue[]);

/**
 * Signals that all keys have been delivered to the core.
 * Must be called once, after the last pp_provider_key_loaded call.
 */
native pp_provider_keys_done();

/**
 * Passes one stored preference for a player to the core.
 * Call inside the pp_provider_load_player handler, once per pair.
 *
 * @param playerIndex   Player index.
 * @param key           Preference key name.
 * @param value         Stored value string.
 */
native pp_provider_pref_loaded(const playerIndex, const key[], const value[]);

/**
 * Signals that all preferences for a player have been delivered.
 * Must be called once — after the last pp_provider_pref_loaded call,
 * or immediately if the player has no stored preferences.
 *
 * @param playerIndex   Player index.
 */
native pp_provider_player_done(const playerIndex);
