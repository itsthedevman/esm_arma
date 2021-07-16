/**
 * ESM_util_log
 * 	It logs a log
 *
 * Exile Server Manager
 * www.esmbot.com
 * © 2018-2021 WolfkillArcadia
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
 */

private _function = _this select 0;
private _message = _this select 1;
private _logLevel = _this param [2, "info"];

diag_log format["[ESM] %1 - %2 - %3", toUpperANSI(_logLevel), _function, _message];
