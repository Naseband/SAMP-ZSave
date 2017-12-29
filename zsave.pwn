//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                  //
//                                     //////////  //////////   ////////   //      //  //////////                                                   //
//                                           //    //          //      //   //    //   //                                                           //
/////////////////////////////////////////////      //////////  //////////    //  //    ///////////////////////////////////////////////////////////////
//                                       //                //  //      //     ////     //                                                           //
//                                     //////////  //////////  //      //      //      //////////  v1.0  by NaS                                     //
//                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// This FS lets you save coordinates in any format.
// /save mostly works well, but if you want to save a lot of positions in a specific format you'll have to copy and paste around a lot of coords.
// I made this some time ago to completely get rid of that process for any kind of target format or type of data.
//
// Furthermore it allows to store a lot of different data as well, for example camera position, vehicle quaternion, velocity or time/date.
//
//
// Commands:
//
//	/zfile (filename)
//		Selects a file to be written to (will be appended).
//		Leave filename empty to see the current file name.
//
// /zformat (id)
//		Opens the type dialog, which lets you select a format type to write.
//		Here you can also add/edit format types.
//		You can also quick-select a specific id.
//
//	/z (text/comment)
//		Saves a coordinate to the selected file with (text/command is optional, but a possible format specifier).
//
//
// Format Type Specifiers:
//
//		&c 		Text/Comment (from /z)
//
//		&x 		Position X
//		&y 		Position Y
//		&z 		Position Z
//
//		&rx 	Rotation X
//		&ry 	Rotation Y
//		&rz 	Rotation Z (also facing angle on-foot)
//
//		&vx 	Velocity X
//		&vy 	Velocity Y
//		&vz 	Velocity Z
//
//		&s 		Skin ID
//		&m 		Vehicle Model
//
//		&qw 	Vehicle Quat W
//		&qx 	Vehicle Quat X
//		&qy 	Vehicle Quat Y
//		&qz 	Vehicle Quat Z
//
//		&cpx 	Camera Pos X
//		&cpy 	Camera Pos Y
//		&cpz 	Camera Pos Z
//
//		&cvx 	Camera Vector X
//		&cvy 	Camera Vector Y
//		&cvz 	Camera Vector Z
//
//		&t 		Current Time (hh:mm:ss)
//		&d 		Current Date (dd.mm.yyyy)
//
// 		Note: Format specifiers that are for vehicles/on-foot only will be zero (0.0) when used in a wrong state.
//
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#define FILTERSCRIPT

#include <a_samp>
#include <zcmd>

// ------------------------------------------------------------------------------------ Config/Defines

#define BASE_DIALOG_ID		27000

#define FILE_FORMAT_TYPES 	"zsave_format_types.txt"

#define MAX_Z_FORMAT_TYPES	32
#define MAX_Z_FORMAT_NAME 	32
#define MAX_Z_FORMAT_LEN	128 // Formats longer than 128 characters cannot be added ingame because of the dialog inputtext limit
#define MAX_Z_FILENAME		128

// ------------------------------------------------------------------------------------ Vars & Enumerators

enum
{
	DID_F_SEL = BASE_DIALOG_ID,
	DID_F_ADD,
	DID_F_ADD_NAME,
	DID_F_ADD_FORMAT,

	DID_F_EDIT_LIST,
	DID_F_EDIT,
	DID_F_EDIT_NAME,
	DID_F_EDIT_NAME_C,
	DID_F_EDIT_FORMAT,
	DID_F_EDIT_FORMAT_C,
	DID_F_EDIT_DELETE
};

#define zfValid(%1) (%1 >= 0 && %1 < MAX_Z_FORMAT_TYPES && FormatTypes[%1][zfName][0] != 0 ? 1 : 0)

enum E_FORMAT_TYPES
{
	zfName[MAX_Z_FORMAT_NAME + 1], // Empty = non-existant
	zfFormat[MAX_Z_FORMAT_LEN + 1]
};
new FormatTypes[MAX_Z_FORMAT_TYPES][E_FORMAT_TYPES];

new bool:Initialized, FileName[MAX_Z_FILENAME], FormatType = -1, FTmpName[MAX_PLAYERS][MAX_Z_FORMAT_NAME + 1], FTmpFormat[MAX_PLAYERS][MAX_Z_FORMAT_LEN + 1], FTmpID[MAX_PLAYERS];

new bigstring[1200];

// ------------------------------------------------------------------------------------ Public Functions

public OnFilterScriptInit()
{
	if(Initialized) return 1;

	LoadFormatTypes();
	FileName[0] = 0;
	FormatType = -1;

	Initialized = true;

	new count;
	for(new i = 0; i < MAX_Z_FORMAT_TYPES; i ++) if(zfValid(i)) count ++;

	printf("\nzSave by NaS initialized.\n> %d/"#MAX_Z_FORMAT_TYPES" Format Types loaded.\n", count);

	return 1;
}

public OnFilterScriptExit()
{
	if(!Initialized) return 1;

	Initialized = false;

	return 1;
}

public OnGameModeInit()
{
	OnFilterScriptInit();

	return 1;
}

public OnGameModeExit()
{
	OnFilterScriptExit();

	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	return 0;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DID_F_SEL)
	{
		if(response)
		{
			if(listitem == 0) return DialogFormatAdd(playerid), 1;

			if(listitem == 1) return DialogFormatEditList(playerid), 1;

			new len = strlen(inputtext);

			if(!len || len > 8) return DialogFormatType(playerid), 1;

			new id = strval(inputtext);

			if(!zfValid(id)) return DialogFormatType(playerid);

			FormatType = id;

			DialogFormatType(playerid);
		}

		return 1;
	}

	if(dialogid == DID_F_ADD_NAME)
	{
		if(response)
		{
			new len = strlen(inputtext);

			if(!len || len > MAX_Z_FORMAT_NAME) return DialogFormatAdd(playerid);

			format(FTmpName[playerid], MAX_Z_FORMAT_NAME + 1, inputtext);

			DialogFormatAdd(playerid, 2);
		}
		else
		{
			DialogFormatType(playerid);
		}	

		return 1;
	}

	if(dialogid == DID_F_ADD_FORMAT)
	{
		if(response)
		{
			new len = strlen(inputtext);

			if(!len || len > MAX_Z_FORMAT_LEN) return DialogFormatAdd(playerid);

			format(FTmpFormat[playerid], MAX_Z_FORMAT_LEN + 1, inputtext);

			DialogFormatAdd(playerid, 3);
		}
		else
		{
			DialogFormatAdd(playerid, 1);
		}	

		return 1;
	}

	if(dialogid == DID_F_ADD)
	{
		if(response)
		{
			if(FTmpName[playerid][0] != 0 && FTmpFormat[playerid][0] != 0)
			{
				new slot = -1;

				for(new i = 0; i < MAX_Z_FORMAT_TYPES; i ++) if(!zfValid(i))
				{
					slot = i;
					break;
				}

				if(slot != -1)
				{
					FormatTypes[slot][zfName] = FTmpName[playerid];
					FormatTypes[slot][zfFormat] = FTmpFormat[playerid];

					if(!SaveFormatTypes()) SendClientMessage(playerid, -1, "[zSave] Error: Failed to save format types.");
				}
				else return SendClientMessage(playerid, -1, "[zSave] Error: There are currently no more slots available.");

				DialogFormatType(playerid);
			}
		}
		else
		{
			DialogFormatAdd(playerid, 2);
		}
	}

	if(dialogid == DID_F_EDIT_LIST)
	{
		if(response)
		{
			new len = strlen(inputtext);

			if(!len || len > 8) return DialogFormatEditList(playerid), 1;

			new id = strval(inputtext);

			if(!zfValid(id)) return DialogFormatEditList(playerid), 1;

			FTmpID[playerid] = id;

			DialogFormatEdit(playerid);
		}
		else
		{
			DialogFormatType(playerid);
		}

		return 1;
	}

	if(dialogid == DID_F_EDIT)
	{
		if(response)
		{
			switch(listitem)
			{
				case 0: DialogFormatEditName(playerid);
				case 1: DialogFormatEditFormat(playerid);
				case 2: DialogFormatEditDelete(playerid);
			}
		}
		else
		{
			DialogFormatEditList(playerid);
		}

		return 1;
	}

	if(dialogid == DID_F_EDIT_NAME)
	{
		if(response)
		{
			new len = strlen(inputtext);

			if(!len || len > MAX_Z_FORMAT_NAME) return DialogFormatEditName(playerid);

			format(FTmpName[playerid], MAX_Z_FORMAT_NAME + 1, inputtext);
			FTmpFormat[playerid][0] = 0;

			DialogFormatEditNameC(playerid);
		}
		else
		{
			DialogFormatEdit(playerid);
		}

		return 1;
	}

	if(dialogid == DID_F_EDIT_NAME_C)
	{
		if(response)
		{
			FormatTypes[FTmpID[playerid]][zfName] = FTmpName[playerid];
			if(!SaveFormatTypes()) SendClientMessage(playerid, -1, "[zSave] Error: Failed to save format types.");

			SendClientMessage(playerid, -1, "[zSave] Name updated.");

			DialogFormatEdit(playerid);
		}
		else
		{
			DialogFormatEditName(playerid);
		}

		return 1;
	}

	if(dialogid == DID_F_EDIT_FORMAT)
	{
		if(response)
		{
			new len = strlen(inputtext);

			if(!len || len > MAX_Z_FORMAT_LEN) return DialogFormatEditFormat(playerid);

			format(FTmpFormat[playerid], MAX_Z_FORMAT_LEN + 1, inputtext);
			FTmpName[playerid][0] = 0;

			DialogFormatEditFormatC(playerid);
		}
		else
		{
			DialogFormatEdit(playerid);
		}

		return 1;
	}

	if(dialogid == DID_F_EDIT_FORMAT_C)
	{
		if(response)
		{
			FormatTypes[FTmpID[playerid]][zfFormat] = FTmpFormat[playerid];
			if(!SaveFormatTypes()) SendClientMessage(playerid, -1, "[zSave] Error: Failed to save format types.");

			SendClientMessage(playerid, -1, "[zSave] Format updated.");

			DialogFormatEdit(playerid);
		}
		else
		{
			DialogFormatEditFormat(playerid);
		}

		return 1;
	}

	if(dialogid == DID_F_EDIT_DELETE)
	{
		if(response)
		{
			FormatTypes[FTmpID[playerid]][zfName][0] = 0;
			FormatTypes[FTmpID[playerid]][zfFormat][0] = 0;

			if(!SaveFormatTypes()) SendClientMessage(playerid, -1, "[zSave] Error: Failed to save format types.");

			SendClientMessage(playerid, -1, "[zSave] Format Type deleted.");

			DialogFormatEditList(playerid);	
		}
		else
		{
			DialogFormatEdit(playerid);
		}

		return 1;
	}

	return 0;
}

// ------------------------------------------------------------------------------------ Loading/Saving

LoadFormatTypes()
{
	if(!fexist(FILE_FORMAT_TYPES)) return print("[zSave]: File \""FILE_FORMAT_TYPES"\" not found"), 1;

	new File:FIn = fopen(FILE_FORMAT_TYPES, io_read);

	if(FIn)
	{
		new text[MAX_Z_FORMAT_NAME + MAX_Z_FORMAT_LEN + 10], id, len;

		while((len = fread(FIn, text)) && id < MAX_Z_FORMAT_TYPES)
		{
			if(len < 3 || len >= MAX_Z_FORMAT_NAME + MAX_Z_FORMAT_LEN) continue;

			new pos = -1;
			for(new i = 0; i < len; i ++)
			{
				if(text[i] == '\r' || text[i] == '\n')
				{
					text[i] = 0;
					len = i + 1;
					break;
				}

				if(pos == -1 && text[i] == ',') pos = i;
			}

			if(pos <= 0) continue;

			strmid(FormatTypes[id][zfName], text, 0, pos, MAX_Z_FORMAT_NAME);
			strmid(FormatTypes[id][zfFormat], text, pos + 1, len, MAX_Z_FORMAT_LEN);

			id ++;
		}

		fclose(FIn);
	}

	return 1;
}

SaveFormatTypes()
{
	new File:FOut = fopen(FILE_FORMAT_TYPES, io_write);

	if(FOut)
	{
		new text[MAX_Z_FORMAT_NAME + MAX_Z_FORMAT_LEN + 10], count;

		for(new i = 0; i < MAX_Z_FORMAT_TYPES; i ++) if(zfValid(i))
		{
			format(text, sizeof(text), "%s,%s\r\n", FormatTypes[i][zfName], FormatTypes[i][zfFormat]);
			fwrite(FOut, text);

			count ++;
		}

		fclose(FOut);

		return count;
	}

	return 0;
}

// ------------------------------------------------------------------------------------ Commands

COMMAND:zfile(playerid, params[])
{
	if(strlen(params) >= MAX_Z_FILENAME) return SendClientMessage(playerid, -1, "[zSave] Error: Input too long");

	if(strlen(params) == 0)
	{
		if(FileName[0] == 0) SendClientMessage(playerid, -1, "[zSave] No FileName set");
		else
		{
			new text[MAX_Z_FILENAME + 30];
			format(text, sizeof(text), "[zSave] Current FileName: \"%s\"", FileName);
			SendClientMessage(playerid, -1, text);
		}

		return 1;
	}

	FileName[0] = 0;
	strcat(FileName, params);

	new text[MAX_Z_FILENAME + 30];
	format(text, sizeof(text), "[zSave] New FileName: \"%s\"", params);
	SendClientMessage(playerid, -1, text);

	return 1;
}

COMMAND:zformat(playerid, params[])
{
	DialogFormatType(playerid);

	return 1;
}

COMMAND:zfedit(playerid, params[])
{
	DialogFormatEditList(playerid);

	return 1;
}

COMMAND:z(playerid, params[])
{
	if(FileName[0] == 0) return SendClientMessage(playerid, -1, "[zSave] Error: No FileName set, use /zformat first");

	if(!zfValid(FormatType)) return SendClientMessage(playerid, -1, "[zSave] Error: No valid FormatType set, use /zformat first");

	bigstring[0] = 0;
	strcat(bigstring, FormatTypes[FormatType][zfFormat]);

	new Float:posx, Float:posy, Float:posz, 
		Float:rotx, Float:roty, Float:rotz,
		Float:velx, Float:vely, Float:velz,
		smodel, vmodel,
		Float:vquatw, Float:vquatx, Float:vquaty, Float:vquatz,
		Float:cpx, Float:cpy, Float:cpz, Float:cvx, Float:cvy, Float:cvz,
		t_h, t_m, t_s, d_y, d_m, d_d, tmp[20];

	gettime(t_h, t_m, t_s);
	getdate(d_y, d_m, d_d);

	new vid = GetPlayerVehicleID(playerid);

	if(vid != 0)
	{
		GetVehiclePos(vid, posx, posy, posz);

		rotx = 0.0;
		roty = 0.0;
		GetVehicleZAngle(vid, rotz);

		GetVehicleVelocity(vid, velx, vely, velz);

		GetVehicleRotationQuat(vid, vquatw, vquatx, vquaty, vquatz);

		vmodel = GetVehicleModel(vid);
	}
	else
	{
		GetPlayerPos(playerid, posx, posy, posz);

		rotx = 0.0;
		roty = 0.0;
		GetPlayerFacingAngle(playerid, rotz);

		GetPlayerVelocity(playerid, velx, vely, velz);

		smodel = GetPlayerSkin(playerid);
	}

	GetPlayerCameraPos(playerid, cpx, cpy, cpz);
	GetPlayerCameraFrontVector(playerid, cvx, cvy, cvz);

	zformat_replace_f(bigstring, "&x", posx);
	zformat_replace_f(bigstring, "&y", posy);
	zformat_replace_f(bigstring, "&z", posz);

	zformat_replace_f(bigstring, "&rx", rotx);
	zformat_replace_f(bigstring, "&ry", roty);
	zformat_replace_f(bigstring, "&rz", rotz);

	zformat_replace_f(bigstring, "&vx", velx);
	zformat_replace_f(bigstring, "&vy", vely);
	zformat_replace_f(bigstring, "&vz", velz);

	zformat_replace_i(bigstring, "&s", smodel);
	zformat_replace_i(bigstring, "&m", vmodel);
	
	zformat_replace_f(bigstring, "&qw", vquatw);
	zformat_replace_f(bigstring, "&qx", vquatx);
	zformat_replace_f(bigstring, "&qy", vquaty);
	zformat_replace_f(bigstring, "&qz", vquatz);

	zformat_replace_f(bigstring, "&cpx", cpx);
	zformat_replace_f(bigstring, "&cpy", cpy);
	zformat_replace_f(bigstring, "&cpz", cpz);

	zformat_replace_f(bigstring, "&cvx", cvx);
	zformat_replace_f(bigstring, "&cvy", cvy);
	zformat_replace_f(bigstring, "&cvz", cvz);

	format(tmp, sizeof(tmp), "%d:%02d:%02d", t_h, t_m, t_s);
	zformat_replace(bigstring, "&t", tmp);

	format(tmp, sizeof(tmp), "%d.%d.%d", d_d, d_m, d_y);
	zformat_replace(bigstring, "&d", tmp);

	if(!isnull(params))
	{
		new idx;
		while((idx = strfind(params, "&c", false)) != -1) params[idx] = '?'; // Temporarily changes &c to ?c which otherwise would result in an infinite loop

		zformat_replace(bigstring, "&c", params);

		while((idx = strfind(bigstring, "?c", false)) != -1) bigstring[idx] = '&'; // Restores &c specifiers
	}
	else zformat_replace(bigstring, "&c", "");

	new File:FOut = fopen(FileName, io_append);

	if(!FOut)
	{
		SendClientMessage(playerid, -1, "[zSave] Error: Cannot write to file.");

		return 1;
	}

	fwrite(FOut, bigstring);
	fwrite(FOut, "\r\n");

	fclose(FOut);

	return 1;
}

// ------------------------------------------------------------------------------------ Replace Functions

zformat_replace_f(target[], specifier[], Float:value, size = sizeof target)
{
	if(strfind(target, specifier, false) == -1) return 0;

	new tmp[15];
	format(tmp, sizeof(tmp), "%f", value);

	return zformat_replace(target, specifier, tmp, size);
}

zformat_replace_i(target[], specifier[], value, size = sizeof target)
{
	if(strfind(target, specifier, false) == -1) return 0;

	new tmp[15];
	format(tmp, sizeof(tmp), "%d", value);

	return zformat_replace(target, specifier, tmp, size);
}

zformat_replace(target[], specifier[], text[], size = sizeof target)
{
	new idx = -1, count;
	while((idx = strfind(target, specifier, false)) != -1)
	{
		strdel(target, idx, idx + strlen(specifier));
		strins(target, text, idx, size);

		count ++;
	}

	return count;
}

// ------------------------------------------------------------------------------------ Dialog Functions

DialogFormatType(playerid)
{
	bigstring[0] = 0;

	strcat(bigstring, "ID\tName\n{FFFF00}New\t \n{FFFF00}Edit\t \n");

	for(new i = 0; i < MAX_Z_FORMAT_TYPES; i ++) if(zfValid(i))
	{
		format(bigstring, sizeof(bigstring), "%s%s%d\t%s\n", bigstring, FormatType == i ? ("{00FF00}") : (""), i, FormatTypes[i][zfName]);
	}

	ShowPlayerDialog(playerid, DID_F_SEL, DIALOG_STYLE_TABLIST_HEADERS, "Select a Format Type", bigstring, "Select", "Close");

	return 1;
}

DialogFormatEditList(playerid)
{
	bigstring[0] = 0;

	strcat(bigstring, "ID\tName\n");

	for(new i = 0; i < MAX_Z_FORMAT_TYPES; i ++) if(zfValid(i))
	{
		format(bigstring, sizeof(bigstring), "%s%d\t%s\n", bigstring, i, FormatTypes[i][zfName]);
	}

	ShowPlayerDialog(playerid, DID_F_EDIT_LIST, DIALOG_STYLE_TABLIST_HEADERS, "Select a Format Type to Edit", bigstring, "Select", "Back");

	return 1;
}

DialogFormatEdit(playerid)
{
	ShowPlayerDialog(playerid, DID_F_EDIT, DIALOG_STYLE_LIST, "Edit Format Type", "Edit Name\nEdit Format\nDelete", "Select", "Back");

	return 1;
}

DialogFormatEditName(playerid)
{
	ShowPlayerDialog(playerid, DID_F_EDIT_NAME, DIALOG_STYLE_INPUT, "Name", "Type the Name for the Format Type (1-"#MAX_Z_FORMAT_NAME" char.):", "Edit", "Back");

	return 1;
}

DialogFormatEditNameC(playerid)
{
	new string[MAX_Z_FORMAT_NAME + 37];
	format(string, sizeof(string), "Confirm to change the Format Name to:\n\n%s", FTmpName[playerid]);

	ShowPlayerDialog(playerid, DID_F_EDIT_NAME_C, DIALOG_STYLE_MSGBOX, "Confirm Name", string, "Edit", "Back");

	return 1;
}

DialogFormatEditFormat(playerid)
{
	static string[] = 
		"Type the Format for the Format Type (1-"#MAX_Z_FORMAT_LEN" char.).\n\nYou can use the following specifiers:\n"\
		"&c\tText/Comment (from /Z)\n"\
		"\n"\
		"&x\tPosition X\n"\
		"&y\tPosition Y\n"\
		"&z\tPosition Z\n"\
		"\n"\
		"&rx\tRotation X\n"\
		"&ry\tRotation Y\n"\
		"&rz\tRotation Z\n"\
		"\n"\
		"&vx\tVelocity X\n"\
		"&vy\tVelocity Y\n"\
		"&vz\tVelocity Z\n"\
		"\n"\
		"&s\tSkin ID\n"\
		"&m\tVehicle Model\n"\
		"\n"\
		"&qw\tVehicle Quat W\n"\
		"&qx\tVehicle Quat X\n"\
		"&qy\tVehicle Quat Y\n"\
		"&qz\tVehicle Quat Z\n"\
		"\n"\
		"&cpx\tCamera Pos X\n"\
		"&cpy\tCamera Pos Y\n"\
		"&cpz\tCamera Pos Z\n"\
		"&cvx\tCamera Vector X\n"\
		"&cvy\tCamera Vector Y\n"\
		"&cvz\tCamera Vector Z\n"\
		"\n"\
		"&t\tCurrent Time\n"\
		"&d\tCurrent Date\n"\
		"\nNote: Specifiers that aren't available will be 0 or 0.0."
	;

	format(bigstring, sizeof(bigstring), "%s\n\nThe current Format is:\n{FFFFFF}%s", string, FormatTypes[FTmpID[playerid]][zfFormat]);

	ShowPlayerDialog(playerid, DID_F_EDIT_FORMAT, DIALOG_STYLE_INPUT, "Format", bigstring, "Edit", "Back");

	return 1;
}

DialogFormatEditFormatC(playerid)
{
	new string[MAX_Z_FORMAT_LEN + 37];
	format(string, sizeof(string), "Confirm to change the Format to:\n\n%s", FTmpFormat[playerid]);

	ShowPlayerDialog(playerid, DID_F_EDIT_FORMAT_C, DIALOG_STYLE_MSGBOX, "Confirm Format", string, "Edit", "Back");

	return 1;
}

DialogFormatEditDelete(playerid)
{
	ShowPlayerDialog(playerid, DID_F_EDIT_DELETE, DIALOG_STYLE_MSGBOX, "Delete Format Type", "Deleting a Format Type cannot be undone.\n\nContinue?", "Delete", "Back");

	return 1;
}

DialogFormatAdd(playerid, page = 1)
{
	if(page == 1) ShowPlayerDialog(playerid, DID_F_ADD_NAME, DIALOG_STYLE_INPUT, "Name", "Type the Name for the new Format Type (1-"#MAX_Z_FORMAT_NAME" char.):", "Next", "Back");
	else if(page == 2)
	{
		static string[] = 
			"Type the Format for the Format Type (1-"#MAX_Z_FORMAT_LEN" char.).\n\nYou can use the following specifiers:\n"\
			"&c\tText/Comment (from /Z)\n"\
			"\n"\
			"&x\tPosition X\n"\
			"&y\tPosition Y\n"\
			"&z\tPosition Z\n"\
			"\n"\
			"&rx\tRotation X\n"\
			"&ry\tRotation Y\n"\
			"&rz\tRotation Z\n"\
			"\n"\
			"&vx\tVelocity X\n"\
			"&vy\tVelocity Y\n"\
			"&vz\tVelocity Z\n"\
			"\n"\
			"&s\tSkin ID\n"\
			"&m\tVehicle Model\n"\
			"\n"\
			"&qw\tVehicle Quat W\n"\
			"&qx\tVehicle Quat X\n"\
			"&qy\tVehicle Quat Y\n"\
			"&qz\tVehicle Quat Z\n"\
			"\n"\
			"&cpx\tCamera Pos X\n"\
			"&cpy\tCamera Pos Y\n"\
			"&cpz\tCamera Pos Z\n"\
			"&cvx\tCamera Vector X\n"\
			"&cvy\tCamera Vector Y\n"\
			"&cvz\tCamera Vector Z\n"\
			"\n"\
			"&t\tCurrent Time\n"\
			"&d\tCurrent Date\n"\
			"\nNote: Specifiers that aren't available will be 0 or 0.0."
		;

		ShowPlayerDialog(playerid, DID_F_ADD_FORMAT, DIALOG_STYLE_INPUT, "Format", string, "Next", "Back");
	}
	else if(page == 3)
	{
		new string[MAX_Z_FORMAT_NAME + MAX_Z_FORMAT_LEN + 40];
		format(string, sizeof(string), "Are you sure to add the following Format Type?\n\nName\t: %s\nFormat\t: %s", FTmpName[playerid], FTmpFormat[playerid]);

		ShowPlayerDialog(playerid, DID_F_ADD, DIALOG_STYLE_MSGBOX, "Add Format Type", string, "Add", "Back");
	}

	return 1;
}

// EOF
