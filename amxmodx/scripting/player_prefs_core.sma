#include <amxmodx>
#include <player_prefs>

enum _: PublicForward
{
  PublicForward_Initialized,  // pp_initialized(bool: bSuccess)
  PublicForward_PlayerLoaded, // pp_player_loaded(playerIndex)
  PublicForward_PlayerSaved   // pp_player_saved(playerIndex)
};

enum _: ProviderForward
{
  ProviderForward_Connect,      // pp_provider_connect()
  ProviderForward_LoadKeys,     // pp_provider_load_keys()
  ProviderForward_LoadPlayer,   // pp_provider_load_player(playerIndex, szAuthId[])
  ProviderForward_SavePref,     // pp_provider_save_pref(playerIndex, szAuthId[], szKey[], szValue[])
  ProviderForward_RegisterKey   // pp_provider_register_key(szKey[], szDefaultValue[])
};

new Trie: g_tPlayerPrefs[MAX_PLAYERS + 1];
new bool: g_bPlayerLoaded[MAX_PLAYERS + 1];
new Trie: g_tKeyDefaults;
new g_iPublicForwards[PublicForward];
new g_iProviderForwards[ProviderForward];

public plugin_init()
{
  register_plugin("Player Prefs Core", "1.0.2", "ufame");

  g_tKeyDefaults = TrieCreate();

  RegisterPublicForwards();
  RegisterProviderForwards();

  ExecuteForward(g_iProviderForwards[ProviderForward_Connect]);
}

public plugin_natives()
{
  register_library("player_prefs_core");

  register_native("pp_is_loaded",    "Native_IsLoaded");
  register_native("pp_get_string",   "Native_GetString");
  register_native("pp_get_int",      "Native_GetInt");
  register_native("pp_get_float",    "Native_GetFloat");
  register_native("pp_get_bool",     "Native_GetBool");
  register_native("pp_set_string",   "Native_SetString");
  register_native("pp_set_int",      "Native_SetInt");
  register_native("pp_set_float",    "Native_SetFloat");
  register_native("pp_set_bool",     "Native_SetBool");
  register_native("pp_register_key", "Native_RegisterKey");

  register_native("pp_provider_ready",       "Native_ProviderReady");
  register_native("pp_provider_key_loaded",  "Native_ProviderKeyLoaded");
  register_native("pp_provider_keys_done",   "Native_ProviderKeysDone");
  register_native("pp_provider_pref_loaded", "Native_ProviderPrefLoaded");
  register_native("pp_provider_player_done", "Native_ProviderPlayerDone");
}

public client_putinserver(playerIndex)
{
  if (is_user_hltv(playerIndex) || is_user_bot(playerIndex))
    return;

  ResetPlayerState(playerIndex);
  RequestPlayerLoad(playerIndex);
}

public client_disconnected(playerIndex)
{
  ResetPlayerState(playerIndex);
}

public bool: Native_IsLoaded(plugin, argc)
{
  enum { arg_player = 1 };
  new playerIndex = get_param(arg_player);

  return IsPlayerLoaded(playerIndex);
}

public bool: Native_GetString(plugin, argc)
{
  enum { arg_player = 1, arg_key, arg_dest, arg_destlen };

  new playerIndex = get_param(arg_player);
  new szKey[MAX_KEY_LENGTH];
  get_string(arg_key, szKey, charsmax(szKey));

  new szValue[MAX_VALUE_LENGTH];
  ResolveValue(playerIndex, szKey, szValue, charsmax(szValue));

  set_string(arg_dest, szValue, get_param(arg_destlen));

  return true;
}

public Native_GetInt(plugin, argc)
{
  enum { arg_player = 1, arg_key, arg_default };

  new playerIndex = get_param(arg_player);
  new szKey[MAX_KEY_LENGTH];
  get_string(arg_key, szKey, charsmax(szKey));

  new szValue[MAX_VALUE_LENGTH];

  if (!ResolveValue(playerIndex, szKey, szValue, charsmax(szValue)))
    return get_param(arg_default);

  return str_to_num(szValue);
}

public Float: Native_GetFloat(plugin, argc)
{
  enum { arg_player = 1, arg_key, arg_default };

  new playerIndex = get_param(arg_player);
  new szKey[MAX_KEY_LENGTH];
  get_string(arg_key, szKey, charsmax(szKey));

  new szValue[MAX_VALUE_LENGTH];

  if (!ResolveValue(playerIndex, szKey, szValue, charsmax(szValue)))
    return get_param_f(arg_default);

  return Float: str_to_float(szValue);
}

public bool: Native_GetBool(plugin, argc)
{
  enum { arg_player = 1, arg_key, arg_default };

  new playerIndex = get_param(arg_player);
  new szKey[MAX_KEY_LENGTH];
  get_string(arg_key, szKey, charsmax(szKey));

  new szValue[MAX_VALUE_LENGTH];

  if (!ResolveValue(playerIndex, szKey, szValue, charsmax(szValue)))
    return bool: get_param(arg_default);

  return bool: str_to_num(szValue);
}

public bool: Native_SetString(plugin, argc)
{
  enum { arg_player = 1, arg_key, arg_value, arg_default };

  new playerIndex = get_param(arg_player);

  if (!is_user_connected(playerIndex) || !IsPlayerLoaded(playerIndex))
    return false;

  new szKey[MAX_KEY_LENGTH], szValue[MAX_VALUE_LENGTH], szDefault[MAX_VALUE_LENGTH];
  get_string(arg_key,     szKey,     charsmax(szKey));
  get_string(arg_value,   szValue,   charsmax(szValue));
  get_string(arg_default, szDefault, charsmax(szDefault));

  return CommitPreference(playerIndex, szKey, szValue, szDefault);
}

public bool: Native_SetInt(plugin, argc)
{
  enum { arg_player = 1, arg_key, arg_value, arg_default };

  new playerIndex = get_param(arg_player);

  if (!is_user_connected(playerIndex) || !IsPlayerLoaded(playerIndex))
    return false;

  new szKey[MAX_KEY_LENGTH], szValue[MAX_VALUE_LENGTH], szDefault[MAX_VALUE_LENGTH];
  get_string(arg_key, szKey, charsmax(szKey));
  num_to_str(get_param(arg_value),   szValue,   charsmax(szValue));
  num_to_str(get_param(arg_default), szDefault, charsmax(szDefault));

  return CommitPreference(playerIndex, szKey, szValue, szDefault);
}

public bool: Native_SetFloat(plugin, argc)
{
  enum { arg_player = 1, arg_key, arg_value, arg_default };

  new playerIndex = get_param(arg_player);

  if (!is_user_connected(playerIndex) || !IsPlayerLoaded(playerIndex))
    return false;

  new szKey[MAX_KEY_LENGTH], szValue[MAX_VALUE_LENGTH], szDefault[MAX_VALUE_LENGTH];
  get_string(arg_key, szKey, charsmax(szKey));
  float_to_str(get_param_f(arg_value),   szValue,   charsmax(szValue));
  float_to_str(get_param_f(arg_default), szDefault, charsmax(szDefault));

  return CommitPreference(playerIndex, szKey, szValue, szDefault);
}

public bool: Native_SetBool(plugin, argc)
{
  enum { arg_player = 1, arg_key, arg_value, arg_default };

  new playerIndex = get_param(arg_player);

  if (!is_user_connected(playerIndex) || !IsPlayerLoaded(playerIndex))
    return false;

  new szKey[MAX_KEY_LENGTH], szValue[MAX_VALUE_LENGTH], szDefault[MAX_VALUE_LENGTH];
  get_string(arg_key, szKey, charsmax(szKey));
  num_to_str(get_param(arg_value),   szValue,   charsmax(szValue));
  num_to_str(get_param(arg_default), szDefault, charsmax(szDefault));

  return CommitPreference(playerIndex, szKey, szValue, szDefault);
}

public bool: Native_RegisterKey(plugin, argc)
{
  enum { arg_key = 1, arg_default };

  new szKey[MAX_KEY_LENGTH], szDefault[MAX_VALUE_LENGTH];
  get_string(arg_key,     szKey,     charsmax(szKey));
  get_string(arg_default, szDefault, charsmax(szDefault));

  TrieSetString(g_tKeyDefaults, szKey, szDefault);
  ExecuteForward(g_iProviderForwards[ProviderForward_RegisterKey], _, szKey, szDefault);

  return true;
}

public Native_ProviderReady(plugin, argc)
{
  enum { arg_success = 1 };
  new bool: bSuccess = bool: get_param(arg_success);

  if (bSuccess)
    ExecuteForward(g_iProviderForwards[ProviderForward_LoadKeys]);

  ExecuteForward(g_iPublicForwards[PublicForward_Initialized], _, bSuccess);
}

public Native_ProviderKeyLoaded(plugin, argc)
{
  enum { arg_key = 1, arg_default };

  new szKey[MAX_KEY_LENGTH], szDefault[MAX_VALUE_LENGTH];
  get_string(arg_key, szKey, charsmax(szKey));
  get_string(arg_default, szDefault, charsmax(szDefault));

  TrieSetString(g_tKeyDefaults, szKey, szDefault);
}

public Native_ProviderKeysDone(plugin, argc)
{
  for (new playerIndex = 1; playerIndex <= MaxClients; playerIndex++)
  {
    if (!is_user_connected(playerIndex))
      continue;

    if (!g_bPlayerLoaded[playerIndex])
      RequestPlayerLoad(playerIndex);
  }
}

public Native_ProviderPrefLoaded(plugin, argc)
{
  enum { arg_player = 1, arg_key, arg_value };

  new playerIndex = get_param(arg_player);
  new szKey[MAX_KEY_LENGTH], szValue[MAX_VALUE_LENGTH];
  get_string(arg_key,   szKey,   charsmax(szKey));
  get_string(arg_value, szValue, charsmax(szValue));

  if (g_tPlayerPrefs[playerIndex] == Invalid_Trie)
    g_tPlayerPrefs[playerIndex] = TrieCreate();

  TrieSetString(g_tPlayerPrefs[playerIndex], szKey, szValue);
}

public Native_ProviderPlayerDone(plugin, argc)
{
  enum { arg_player = 1 };
  new playerIndex = get_param(arg_player);

  if (g_tPlayerPrefs[playerIndex] == Invalid_Trie)
    g_tPlayerPrefs[playerIndex] = TrieCreate();

  g_bPlayerLoaded[playerIndex] = true;

  ExecuteForward(g_iPublicForwards[PublicForward_PlayerLoaded], _, playerIndex);
}

ResetPlayerState(playerIndex)
{
  g_bPlayerLoaded[playerIndex] = false;

  if (g_tPlayerPrefs[playerIndex] != Invalid_Trie)
  {
    TrieDestroy(g_tPlayerPrefs[playerIndex]);
    g_tPlayerPrefs[playerIndex] = Invalid_Trie;
  }
}

RequestPlayerLoad(playerIndex)
{
  new szAuthId[MAX_AUTHID_LENGTH];
  get_user_authid(playerIndex, szAuthId, charsmax(szAuthId));

  ExecuteForward(g_iProviderForwards[ProviderForward_LoadPlayer], _, playerIndex, szAuthId);
}

bool: ResolveValue(playerIndex, const szKey[], szDest[], iDestLen)
{
  if (g_tPlayerPrefs[playerIndex] != Invalid_Trie
    && TrieGetString(g_tPlayerPrefs[playerIndex], szKey, szDest, iDestLen))
  {
    return true;
  }

  if (g_tKeyDefaults != Invalid_Trie
    && TrieGetString(g_tKeyDefaults, szKey, szDest, iDestLen))
  {
    return true;
  }

  szDest[0] = EOS;

  return false;
}

bool: CommitPreference(playerIndex, const szKey[], const szValue[], const szDefaultValue[])
{
  if (g_tPlayerPrefs[playerIndex] == Invalid_Trie)
    g_tPlayerPrefs[playerIndex] = TrieCreate();

  TrieSetString(g_tPlayerPrefs[playerIndex], szKey, szValue);

  new szAuthId[MAX_AUTHID_LENGTH];
  get_user_authid(playerIndex, szAuthId, charsmax(szAuthId));

  TrieSetString(g_tKeyDefaults, szKey, szDefaultValue);
  ExecuteForward(g_iProviderForwards[ProviderForward_RegisterKey], _, szKey, szDefaultValue);
  ExecuteForward(g_iProviderForwards[ProviderForward_SavePref], _, playerIndex, szAuthId, szKey, szValue);
  ExecuteForward(g_iPublicForwards[PublicForward_PlayerSaved], _, playerIndex);

  return true;
}

bool: IsPlayerLoaded(const playerIndex)
{
  return is_user_connected(playerIndex) && g_bPlayerLoaded[playerIndex] && g_tPlayerPrefs[playerIndex] != Invalid_Trie;
}

RegisterPublicForwards()
{
  g_iPublicForwards[PublicForward_Initialized]  = CreateMultiForward("pp_initialized",   ET_IGNORE, FP_CELL);
  g_iPublicForwards[PublicForward_PlayerLoaded] = CreateMultiForward("pp_player_loaded", ET_IGNORE, FP_CELL);
  g_iPublicForwards[PublicForward_PlayerSaved]  = CreateMultiForward("pp_player_saved",  ET_IGNORE, FP_CELL);
}

RegisterProviderForwards()
{
  g_iProviderForwards[ProviderForward_Connect] = CreateMultiForward("pp_provider_connect",      ET_IGNORE);
  g_iProviderForwards[ProviderForward_LoadKeys] = CreateMultiForward("pp_provider_load_keys",    ET_IGNORE);
  g_iProviderForwards[ProviderForward_LoadPlayer] = CreateMultiForward("pp_provider_load_player",  ET_IGNORE, FP_CELL, FP_STRING);
  g_iProviderForwards[ProviderForward_SavePref] = CreateMultiForward("pp_provider_save_pref",    ET_IGNORE, FP_CELL, FP_STRING, FP_STRING, FP_STRING);
  g_iProviderForwards[ProviderForward_RegisterKey] = CreateMultiForward("pp_provider_register_key", ET_IGNORE, FP_STRING, FP_STRING);
}
