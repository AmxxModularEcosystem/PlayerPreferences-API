# Player preferences API

Allows you to easily manage and store player preferences, such as hats, music and other settings.

With this plugin, players can easily save and load their preferences, even on different servers. This means they can quickly and easily return to their preferred settings without having to manually adjust settings every time they join a new server.

## Installation

Load **core** first, then exactly one provider:
 
```
player_prefs_core.amxx
player_prefs_mysql.amxx    ; or flute
```

| Provider | Config file |
|----------|-------------|
| MySQL | `configs/player_prefs_mysql.json` → `host`, `user`, `pass`, `db` |
| Flute | `configs/player_prefs_flute.json` → `url`, `token`, `server_id`, `timeout` |

For Flute provider need a [Flute-PlayerPreferences](https://github.com/AmxxModularEcosystem/Flute-PlayerPreferences) module.

## Usage

```Pawn
#include <amxmodx>
#include <player_prefs>

new const PREF_HUD_POSITION[] = "dhud_position";
const Float: HUD_UPDATE_INTERVAL = 1.0;
const POSITION_COUNT = 4;

new const Float: g_aPositions[POSITION_COUNT][] =
{
  { 0.02, 0.55, },
  { 0.02, 0.80, },
  { 0.75, 0.55, },
  { 0.75, 0.80, }
};

new const g_szPositionNames[POSITION_COUNT][] =
{
  "Left / Middle",
  "Left / Bottom",
  "Right / Middle",
  "Right / Bottom"
};

new g_iHudPosition[MAX_PLAYERS + 1];

public plugin_init()
{
  register_plugin("Prefs Test", "1.0.0", "ufame");

  register_clcmd("say /hudpos", "Cmd_HudPosition");

  set_task(HUD_UPDATE_INTERVAL, "Task_UpdateHud", .flags = "b");
}

public pp_initialized(const bool: bSuccess)
{
  if (!bSuccess)
    return;

  pp_register_key(PREF_HUD_POSITION, "0");
}

public pp_player_loaded(const playerIndex)
{
  g_iHudPosition[playerIndex] = pp_get_int(playerIndex, PREF_HUD_POSITION, 0);
}

public Cmd_HudPosition(const playerIndex)
{
  ShowPositionMenu(playerIndex);

  return PLUGIN_HANDLED;
}

ShowPositionMenu(const playerIndex)
{
  new menu = menu_create("Позиция DHUD", "MenuHandler_Position");

  for (new i = 0; i < POSITION_COUNT; i++)
  {
    menu_additem(menu, g_szPositionNames[i]);
  }

  menu_display(playerIndex, menu);
}

public MenuHandler_Position(const playerIndex, menu, const item)
{
  menu_destroy(menu);

  if (item == MENU_EXIT)
    return;

  if (item < 0 || item >= POSITION_COUNT)
    return;

  g_iHudPosition[playerIndex] = item;
  pp_set_int(playerIndex, PREF_HUD_POSITION, item, 0);

  client_print(playerIndex, print_chat, "[HUD] The position has been changed to: %s", g_szPositionNames[item]);
}

public Task_UpdateHud()
{
  for (new playerIndex = 1; playerIndex < MaxClients; playerIndex++)
  {
    if (!is_user_connected(playerIndex))
      continue;

    if (pp_is_loaded(playerIndex))
      DrawHud(playerIndex);
  }
}

DrawHud(playerIndex)
{
  new positionIndex = g_iHudPosition[playerIndex];

  new Float: x = Float: g_aPositions[positionIndex][0];
  new Float: y = Float: g_aPositions[positionIndex][1];

  set_dhudmessage(220, 220, 220, x, y, .holdtime = HUD_UPDATE_INTERVAL + 0.1);
  show_dhudmessage(playerIndex, "TEST MESSAGE");
}

```

## Forwards
 
| Forward | When |
|---------|------|
| `pp_initialized(bool: success)` | Provider connected, register keys here |
| `pp_player_loaded(playerIndex)` | Player data ready, safe to read |
| `pp_player_saved(playerIndex)` | A preference was written to storage |
 
## Natives
 
| Native | Description |
|--------|-------------|
| `pp_is_loaded(playerIndex)` | Returns true when the player's data is ready |
| `pp_register_key(key[], default[])` | Register a key with a default value |
| `pp_get_int(playerIndex, key[], default)` | Read an integer |
| `pp_get_float(playerIndex, key[], default)` | Read a float |
| `pp_get_bool(playerIndex, key[], default)` | Read a boolean |
| `pp_get_string(playerIndex, key[], dest[], len)` | Read a string |
| `pp_set_int(playerIndex, key[], value, default)` | Write an integer |
| `pp_set_float(playerIndex, key[], value, default)` | Write a float |
| `pp_set_bool(playerIndex, key[], value, default)` | Write a boolean |
| `pp_set_string(playerIndex, key[], value[], default[])` | Write a string |