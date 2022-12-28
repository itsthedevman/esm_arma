/*
	Exile Server Manager
	www.esmbot.com
	© 2018-2020 Exile Server Manager Team
	This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
	To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/.

	Description:
		Calls the ESM DLL and returns the resulting array
*/

private _function = _this select 0;
private _arguments = _this select [1, count(_this) - 1];

private _sanitizedPackage = [];
private _sanitizer = {
	private _package = _this select 0;
	private _item = _this select 1;

	switch (typeName(_item)) do
	{
		case "ARRAY":
		{
			private _tempPackage = [];

			{
				[_tempPackage, _x] call _sanitizer;
			}
			forEach _item;

			_package pushBack _tempPackage;
		};

		case "STRING":
		{
			_package pushBack (_item call ExileClient_util_string_escapeJson);
		};

		default
		{
			_package pushBack _item;
		};
	};
};

{
	[_sanitizedPackage, _x] call _sanitizer;
}
forEach _arguments;

"esm_client" callExtension [_function, _sanitizedPackage];
