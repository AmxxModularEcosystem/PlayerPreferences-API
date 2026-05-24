#if defined _player_prefs_provider_included
  #endinput
#endif
#define _player_prefs_provider_included

#pragma reqlib player_prefs_core

/**
 * Ядро просит провайдера установить соединение / открыть хранилище.
 * Провайдер обязан завершить инициализацию и вызвать pp_provider_ready().
 */
forward pp_provider_connect();

/**
 * Ядро просит провайдера загрузить все зарегистрированные ключи.
 * Провайдер вызывает pp_provider_key_loaded() для каждого ключа,
 * затем pp_provider_keys_done().
 */
forward pp_provider_load_keys();

/**
 * Ядро просит провайдера загрузить предпочтения конкретного игрока.
 * Провайдер вызывает pp_provider_pref_loaded() для каждой пары key/value,
 * затем pp_provider_player_done(const playerIndex).
 *
 * @param (const playerIndex    Индекс игрока.
 * @param szAuthId   SteamID игрока.
 */
forward pp_provider_load_player(const playerIndex, const szAuthId[]);

/**
 * Ядро просит провайдера сохранить одно предпочтение игрока.
 *
 * @param (const playerIndex    Индекс игрока.
 * @param szAuthId   SteamID игрока.
 * @param szKey      Имя ключа.
 * @param szValue    Строковое значение.
 */
forward pp_provider_save_pref(const playerIndex, const szAuthId[], const szKey[], const szValue[]);

/**
 * Ядро просит провайдера зарегистрировать ключ с дефолтным значением.
 *
 * @param szKey          Имя ключа.
 * @param szDefaultValue Дефолтное значение.
 */
forward pp_provider_register_key(const szKey[], const szDefaultValue[]);

/**
 * Провайдер сообщает о результате соединения.
 *
 * @param bSuccess  true — соединение успешно.
 */
native pp_provider_ready(bool: bSuccess);

/**
 * Провайдер передаёт ядру один загруженный ключ.
 * Вызывается в цикле внутри обработчика pp_provider_load_keys.
 *
 * @param szKey          Имя ключа.
 * @param szDefaultValue Дефолтное значение.
 */
native pp_provider_key_loaded(const szKey[], const szDefaultValue[]);

/**
 * Провайдер сообщает, что все ключи переданы.
 */
native pp_provider_keys_done();

/**
 * Провайдер передаёт ядру одно предпочтение игрока.
 *
 * @param (const playerIndex  Индекс игрока.
 * @param szKey    Имя ключа.
 * @param szValue  Строковое значение.
 */
native pp_provider_pref_loaded(const playerIndex, const szKey[], const szValue[]);

/**
 * Провайдер сообщает, что все предпочтения игрока переданы.
 *
 * @param (const playerIndex  Индекс игрока.
 */
native pp_provider_player_done(const playerIndex);
