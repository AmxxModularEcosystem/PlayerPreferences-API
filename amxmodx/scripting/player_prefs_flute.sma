#include <amxmodx>
#include <easy_http>
#include <json>
#include <player_prefs_provider>

const MAX_KEY_LENGTH   = 64;
const MAX_VALUE_LENGTH = 256;
const MAX_URL_LENGTH   = 256;
const MAX_TOKEN_LENGTH = 256;

const DEFAULT_TIMEOUT_MS = 10000;
new const CONFIG_FILE[] = "addons/amxmodx/configs/player_prefs_flute.json";
new const ENDPOINT_SETTINGS[] = "/api/player-preferences/settings";

enum RequestType
{
  RequestType_LoadPlayer,
  RequestType_SavePref
};

enum _: RequestData
{
  RequestType: rd_type,                // RequestType
  rd_player,              // индекс игрока
  rd_userid,              // userid на момент отправки (защита от рассинхрона)
  rd_key[MAX_KEY_LENGTH]  // имя ключа (только для SavePref, иначе пусто)
};

new g_szBaseUrl[MAX_URL_LENGTH];
new g_szAuthHeader[MAX_TOKEN_LENGTH + 8];
new g_szToken[MAX_TOKEN_LENGTH];

new g_iServerId;
new g_iTimeoutMs;

new bool: g_bDebugMode;

public plugin_init()
{
  register_plugin("Player Prefs — Flute REST Provider", "1.0.0", "ufame");

  g_bDebugMode = bool: (plugin_flags() & AMX_FLAG_DEBUG);
}

public pp_provider_connect()
{
  if (!ReadConfig())
  {
    pp_provider_ready(false);
    return;
  }

  log_amx("[PP Flute] Конфиг загружен. URL: %s, Server ID: %d", g_szBaseUrl, g_iServerId);
  pp_provider_ready(true);
}

public pp_provider_load_keys()
{
  pp_provider_keys_done();
}

public pp_provider_load_player(const playerIndex, const authId[])
{
  new szUrl[MAX_URL_LENGTH + 128];
  formatex(szUrl, charsmax(szUrl),
    "%s%s?steamid=%s&server_id=%d",
    g_szBaseUrl, ENDPOINT_SETTINGS, authId, g_iServerId
  );

  new data[RequestData];
  data[rd_type]   = RequestType_LoadPlayer;
  data[rd_player] = playerIndex;
  data[rd_userid] = get_user_userid(playerIndex);

  new EzHttpOptions: hOptions = BuildRequestOptions();
  ezhttp_option_set_user_data(hOptions, data, sizeof data);

  ezhttp_get(szUrl, "OnLoadPlayerComplete", hOptions);

  __debug("[PP Flute] LoadPlayer #%d — GET %s", playerIndex, szUrl);
}

public pp_provider_save_pref(const playerIndex, const authId[], const key[], const value[])
{
  new data[RequestData];
  data[rd_type]   = RequestType_SavePref;
  data[rd_player] = playerIndex;
  data[rd_userid] = get_user_userid(playerIndex);
  formatex(data[rd_key], MAX_KEY_LENGTH, key);

  new szUrl[MAX_URL_LENGTH + 32];
  formatex(szUrl, charsmax(szUrl), "%s%s", g_szBaseUrl, ENDPOINT_SETTINGS);

  new EzHttpOptions: hOptions = BuildRequestOptions();
  ezhttp_option_set_header(hOptions,   "Content-Type", "application/json");
  ezhttp_option_set_user_data(hOptions, data, sizeof data);
  SetSavePrefBody(hOptions, authId, key, value);

  ezhttp_post(szUrl, "OnSavePrefComplete", hOptions);

  __debug("[PP Flute] SavePref #%d <%s> = <%s>", playerIndex, key, value);
}

public OnLoadPlayerComplete(EzHttpRequest: request)
{
  new data[RequestData];
  ezhttp_get_user_data(request, data);

  new playerIndex = data[rd_player];
  new userId = data[rd_userid];

  if (ezhttp_get_error_code(request) != EZH_OK)
  {
    new szError[128];
    ezhttp_get_error_message(request, szError, charsmax(szError));
    log_amx("[PP Flute] LoadPlayer #%d: ошибка запроса: %s", playerIndex, szError);

    if (IsUseridValid(playerIndex, userId))
      pp_provider_player_done(playerIndex);

    return;
  }

  if (!IsUseridValid(playerIndex, userId))
  {
    __debug("[PP Flute] LoadPlayer: игрок %d уже отключился.", playerIndex);
    return;
  }

  new statusCode = ezhttp_get_http_code(request);

  if (statusCode == 404)
  {
    __debug("[PP Flute] LoadPlayer #%d: Steam-аккаунт не найден в Flute (404).", playerIndex);
    pp_provider_player_done(playerIndex);
    return;
  }

  if (statusCode != 200)
  {
    log_amx("[PP Flute] LoadPlayer #%d: неожиданный HTTP %d.", playerIndex, statusCode);
    pp_provider_player_done(playerIndex);
    return;
  }

  new EzJSON: hRoot = ezhttp_parse_json_response(request);

  if (hRoot == EzInvalid_JSON)
  {
    log_amx("[PP Flute] LoadPlayer #%d: не удалось разобрать JSON ответа.", playerIndex);
    pp_provider_player_done(playerIndex);
    return;
  }

  new EzJSON: hSettings = ezjson_object_get_value(hRoot, "settings");

  if (hSettings != EzInvalid_JSON)
  {
    ParseAndForwardSettings(playerIndex, hSettings);
    ezjson_free(hSettings);
  }

  ezjson_free(hRoot);

  pp_provider_player_done(playerIndex);

  __debug("[PP Flute] LoadPlayer #%d завершён.", playerIndex);
}

public OnSavePrefComplete(EzHttpRequest: request)
{
  new data[RequestData];
  ezhttp_get_user_data(request, data);

  new playerIndex = data[rd_player];
  new userId = data[rd_userid];

  if (ezhttp_get_error_code(request) != EZH_OK)
  {
    new szError[128];
    ezhttp_get_error_message(request, szError, charsmax(szError));
    log_amx("[PP Flute] SavePref #%d <%s>: ошибка запроса: %s", playerIndex, data[rd_key], szError);
    return;
  }

  if (!IsUseridValid(playerIndex, userId))
    return;

  new statusCode = ezhttp_get_http_code(request);

  if (statusCode != 200 && statusCode != 201)
  {
    log_amx("[PP Flute] SavePref #%d <%s>: HTTP %d.", playerIndex, data[rd_key], statusCode);
    return;
  }

  __debug("[PP Flute] SavePref #%d <%s>: сохранено (HTTP %d).", playerIndex, data[rd_key], statusCode);
}

ParseAndForwardSettings(playerIndex, EzJSON: hSettings)
{
  new count = ezjson_object_get_count(hSettings);
  new key[MAX_KEY_LENGTH], value[MAX_VALUE_LENGTH];

  for (new i = 0; i < count; i++)
  {
    ezjson_object_get_name(hSettings, i, key, charsmax(key));

    new EzJSON: hVal = ezjson_object_get_value_at(hSettings, i);

    if (hVal == EzInvalid_JSON)
      continue;

    JsonValueToString(hVal, value, charsmax(value));
    ezjson_free(hVal);

    pp_provider_pref_loaded(playerIndex, key, value);

    __debug("[PP Flute] Загружено: player %d <%s> = <%s>", playerIndex, key, value);
  }
}

JsonValueToString(EzJSON: hVal, szDest[], iDestLen)
{
  switch (ezjson_get_type(hVal))
  {
    case EzJSONString:
    {
      ezjson_get_string(hVal, szDest, iDestLen);
    }
    case EzJSONNumber:
    {
      new Float: flVal = ezjson_get_real(hVal);
      new iVal = ezjson_get_number(hVal);

      if (float(iVal) == flVal)
        num_to_str(iVal, szDest, iDestLen);
      else
        float_to_str(flVal, szDest, iDestLen);
    }
    case EzJSONBoolean:
    {
      szDest[0] = ezjson_get_bool(hVal) ? '1' : '0';
      szDest[1] = EOS;
    }
    default:
    {
      szDest[0] = EOS;
    }
  }
}

SetSavePrefBody(EzHttpOptions: hOptions, const authId[], const key[], const value[])
{
  new EzJSON: hRoot     = ezjson_init_object();
  new EzJSON: hSettings = ezjson_init_object();
  new EzJSON: hVal      = StringToJsonValue(value);

  ezjson_object_set_string(hRoot, "steamid",   authId);
  ezjson_object_set_number(hRoot, "server_id", g_iServerId);
  ezjson_object_set_value(hSettings, key,       hVal);
  ezjson_object_set_value(hRoot,    "settings", hSettings);

  ezhttp_option_set_body_from_json(hOptions, hRoot);

  ezjson_free(hVal);
  ezjson_free(hSettings);
  ezjson_free(hRoot);
}


EzJSON: StringToJsonValue(const value[])
{
  if (IsNumericString(value))
  {
    if (contain(value, ".") >= 0)
      return ezjson_init_real(str_to_float(value));
    else
      return ezjson_init_number(str_to_num(value));
  }

  return ezjson_init_string(value);
}

bool: IsNumericString(const szStr[])
{
  new iLen = strlen(szStr);

  if (iLen == 0)
    return false;

  new iStart          = (szStr[0] == '-') ? 1 : 0;
  new bool: bHasDot   = false;
  new bool: bHasDigit = false;

  for (new i = iStart; i < iLen; i++)
  {
    if (szStr[i] == '.')
    {
      if (bHasDot)
        return false;
      bHasDot = true;
    } else if (szStr[i] >= '0' && szStr[i] <= '9') {
      bHasDigit = true;
    } else {
      return false;
    }
  }

  return bHasDigit;
}

EzHttpOptions: BuildRequestOptions()
{
  new EzHttpOptions: hOptions = ezhttp_create_options();

  ezhttp_option_set_header(hOptions,  "Authorization", g_szAuthHeader);
  ezhttp_option_set_header(hOptions, "X-API-Key", g_szToken);
  ezhttp_option_set_header(hOptions,  "Accept", "application/json");
  ezhttp_option_set_timeout(hOptions, g_iTimeoutMs);

  return hOptions;
}

bool: ReadConfig()
{
  if (!file_exists(CONFIG_FILE))
  {
    log_amx("[PP Flute] Файл конфига не найден: %s", CONFIG_FILE);
    return false;
  }

  new JSON: hConfig = json_parse(CONFIG_FILE, .is_file = true);

  if (hConfig == Invalid_JSON || !json_is_object(hConfig))
  {
    if (hConfig != Invalid_JSON) json_free(hConfig);
    log_amx("[PP Flute] Ошибка JSON в файле конфига: %s", CONFIG_FILE);
    return false;
  }

  json_object_get_string(hConfig, "url", g_szBaseUrl, charsmax(g_szBaseUrl));
  json_object_get_string(hConfig, "token", g_szToken, charsmax(g_szToken));
  g_iServerId  = json_object_get_number(hConfig, "server_id");
  g_iTimeoutMs = json_object_get_number(hConfig, "timeout");

  json_free(hConfig);

  if (g_iTimeoutMs <= 0)
    g_iTimeoutMs = DEFAULT_TIMEOUT_MS;

  new iLen = strlen(g_szBaseUrl);
  if (iLen > 0 && g_szBaseUrl[iLen - 1] == '/')
    g_szBaseUrl[iLen - 1] = EOS;

  formatex(g_szAuthHeader, charsmax(g_szAuthHeader), "Bearer %s", g_szToken);

  if (g_szBaseUrl[0] == EOS || g_szToken[0] == EOS || g_iServerId <= 0)
  {
    log_amx("[PP Flute] Конфиг неполный: нужны url, token и server_id > 0.");
    return false;
  }

  return true;
}

bool: IsUseridValid(const playerIndex, const userId)
{
  return is_user_connected(playerIndex) && get_user_userid(playerIndex) == userId;
}

__debug(const szFormat[], any: ...) {
  if (!g_bDebugMode)
    return;

  new szMessage[1024];
  vformat(szMessage, charsmax(szMessage), szFormat, 2);
  log_to_file("pp_debug.log", szMessage);
}
