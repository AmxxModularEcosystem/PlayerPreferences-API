#if defined _player_prefs_included
  #endinput
#endif
#define _player_prefs_included

#pragma reqlib player_prefs_core

/**
 * Возвращает true, если предпочтения игрока загружены из провайдера
 * и готовы к использованию.
 *
 * @param playerIndex  Индекс игрока (1..MAX_PLAYERS).
 * @return         true — загружен, false — нет.
 */
native bool: pp_is_loaded(const playerIndex);

/**
 * Получает строковое предпочтение игрока.
 * Если значение не задано — возвращает дефолтное значение ключа.
 *
 * @param playerIndex   Индекс игрока.
 * @param szKey     Имя ключа.
 * @param szDest    Буфер для результата.
 * @param iDestLen  Длина буфера.
 * @return          true при успехе.
 */
native bool: pp_get_string(const playerIndex, const szKey[], szDest[], iDestLen);

/**
 * Получает целочисленное предпочтение игрока.
 * Если значение не задано — возвращает iDefault.
 *
 * @param playerIndex   Индекс игрока.
 * @param szKey     Имя ключа.
 * @param iDefault  Значение по умолчанию.
 * @return          Значение предпочтения или iDefault.
 */
native pp_get_int(const playerIndex, const szKey[], iDefault = 0);

/**
 * Получает float-предпочтение игрока.
 *
 * @param playerIndex   Индекс игрока.
 * @param szKey     Имя ключа.
 * @param flDefault Значение по умолчанию.
 * @return          Значение предпочтения или flDefault.
 */
native Float: pp_get_float(const playerIndex, const szKey[], Float: flDefault = 0.0);

/**
 * Получает булево предпочтение игрока.
 *
 * @param playerIndex   Индекс игрока.
 * @param szKey     Имя ключа.
 * @param bDefault  Значение по умолчанию.
 * @return          true/false.
 */
native bool: pp_get_bool(const playerIndex, const szKey[], bool: bDefault = false);

/**
 * Устанавливает строковое предпочтение игрока.
 * Значение сохраняется в памяти немедленно и асинхронно пишется в провайдер.
 *
 * @param playerIndex        Индекс игрока.
 * @param szKey          Имя ключа.
 * @param szValue        Новое значение.
 * @param szDefaultValue Дефолтное значение ключа (для регистрации ключа в провайдере).
 * @return               true при успехе.
 */
native bool: pp_set_string(const playerIndex, const szKey[], const szValue[], const szDefaultValue[] = "");

/**
 * Устанавливает целочисленное предпочтение игрока.
 *
 * @param playerIndex        Индекс игрока.
 * @param szKey          Имя ключа.
 * @param iValue         Новое значение.
 * @param iDefault       Дефолтное значение ключа.
 * @return               true при успехе.
 */
native bool: pp_set_int(const playerIndex, const szKey[], iValue, iDefault = 0);

/**
 * Устанавливает float-предпочтение игрока.
 *
 * @param playerIndex        Индекс игрока.
 * @param szKey          Имя ключа.
 * @param flValue        Новое значение.
 * @param flDefault      Дефолтное значение ключа.
 * @return               true при успехе.
 */
native bool: pp_set_float(const playerIndex, const szKey[], Float: flValue, Float: flDefault = 0.0);

/**
 * Устанавливает булево предпочтение игрока.
 *
 * @param playerIndex        Индекс игрока.
 * @param szKey          Имя ключа.
 * @param bValue         Новое значение.
 * @param bDefault       Дефолтное значение ключа.
 * @return               true при успехе.
 */
native bool: pp_set_bool(const playerIndex, const szKey[], bool: bValue, bool: bDefault = false);

/**
 * Регистрирует ключ и его дефолтное значение в провайдере.
 * Вызывать из pp_initialized при bSuccess == true.
 *
 * @param szKey          Имя ключа.
 * @param szDefaultValue Строковое дефолтное значение.
 * @return               true при успехе.
 */
native bool: pp_register_key(const szKey[], const szDefaultValue[] = "");
