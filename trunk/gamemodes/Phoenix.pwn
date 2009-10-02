/*
*    The contents of this file are subject to the Mozilla Public License
*    Version 1.1 (the "License"); you may not use this file except in
*    compliance with the License. You may obtain a copy of the License at
*    http://www.mozilla.org/MPL/
*    
*    Software distributed under the License is distributed on an "AS IS"
*    basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
*    License for the specific language governing rights and limitations
*    under the License.
*    
*    The Original Code is Phoenix.
*    The Initial Developers of the Original Code are 13th and Jyrno42.
*/

/*
*    EXTERNAL CREDITS
*
*        External Credit #1 - Simon, IsValidSkin
*        External Credit #2 - Alex "Y_Less" Cole, MD5 Core
*        External Credit #3 - Alex "Y_Less" Cole, Y_SERVER
*
*/

/*
*    INCLUDES
*/

#define dcmd(%1,%2,%3) if (!strcmp((%3)[1], #%1, true, (%2)) && ((((%3)[(%2) + 1] == '\0') && (dcmd_%1(playerid, ""))) || (((%3)[(%2) + 1] == ' ') && (dcmd_%1(playerid, (%3)[(%2) + 2]))))) return 1

#include <a_samp>
#include <a_mysql>
#include <md5_core>  // author: Alex "Y_Less" Cole, External Credit #2
#include <Y_server>  // author: Alex "Y_Less" Cole, External Credit #3
#include <phoenix_Core>
#include <phoenix_Lang>
#include <phoenix_RealCarnames>

/*
*    DEFINES
*/

#define SCRIPT_NAME			"Phoenix"
#define SCRIPT_VERSION  	"0.1"
#define SCRIPT_REVISION 	"70"

#define MYSQL_HOST			"localhost"
#define MYSQL_USER			"estrpco_portal"
#define MYSQL_DB			"estrpco_portal"
#define MYSQL_PREFIX		"ph_"

    /*
         *  THREADS IDs
         */
	#define VEHICLE_LOAD_THREAD     1
	#define VEHICLE_SAVE_THREAD     2
	#define FETCH_UINFO_THREAD      3

#define VEHICLE_DELAY 60000
#define SQL_FINISH_TIME 1000
#define CHAT_RADIUS 25
#define CHAT_RADIUS_SHOUT 40

#define STRING_LENGHT 256

#define VEHICLE_GROUP			0	// G�ngid, Grupeeringud
#define VEHICLE_JOB				1	// T��d
#define VEHICLE_BUYABLE			2	// Ostetav masin
#define VEHICLE_SPECIAL			3	// Rongid, transpordivahendid jms. PS: Neid ei saa m�ngijad kasutada. Botid juhivad!
#define VEHICLE_ADMIN			4	// Administraatorite masinad

#define COLOR_YELLOW		0xFFFF00AA
#define COLOR_RED 0xAA3333AA
#define COLOR_GREEN 0x33AA33AA

#define PLAYER_COLOR 0xFFFF0000

#define COLOR_CHAT_IC 0xf2ffacAA
#define COLOR_CHAT_OOC_GLOBAL 0x8cf8ffAA
#define COLOR_CHAT_OOC_LOCAL 0xf2ffacAA
#define COLOR_CHAT_ME 0xda92e5AA
#define COLOR_CHAT_SHOUT 0xd7ff00AA
#define COLOR_CHAT_ES 0xfffc00AA

/* DialogIDs */
#define DIALOG_LOGIN 2009
#define DIALOG_PLAYER 2010
#define DIALOG_SENDES 2011

/*
*    GLOBAL VARIABLES
*/

new WelcomeStr[64];

    /*
         *  THREADS Vars
         */
	new Fetch_UInfo_Thread = -1;

new EaglePickup, SawnoffPickup, MP5Pickup, AKPickup;

enum pInf
{
	uSqlId,
	uUserName[20],	
	uPassWordHash[64],
	uSalt[10],
	pLoggedIn,
	pCharName[30],
	pSqlId,
	pAdmin,
	pJob,
	pMember,
	pLeader,
	pModel,
	
	Float:pPosX,
	Float:pPosY,
	Float:pPosZ,
	Float:pAngle,
	Float:pHealth,
	pVW,
	pInterior,
	
	SelectedPlayer
};
new pInfo[MAX_PLAYERS][pInf];

new Text:  InfoBar[MAX_PLAYERS];
new 	   InfoBarTimer[MAX_PLAYERS];

new VEHICLE_SAVE_NEXT = 0;
new LOADED_VEHICLES = 0;
enum vInf
{
	vSqlID,
	vSampId,
	
	vModel,
	vType,
	
	Float: vPosXd,
	Float: vPosYd,
	Float: vPosZd,
	Float: vAngZd,
	Float: vPosX,
	Float: vPosY,
	Float: vPosZ,
	Float: vAngZ,
	
	vColor1,
	vColor2,
	
	vOwner,
	vValue,
	
	vDeaths,
	Float: vHealth,
};
new Vehicles[700][vInf];

/*
*    FORWARDS
*/
forward SendEs(playerid);
forward ForwardEs(playerid, message[]);
forward SendEmote(playerid, emote[]);
forward SCMTAInPlayerRadius(playerid, radius, color, message[]);
forward LoadAllVehiclesStart();
forward LoadAllVehiclesFinish();
forward SaveAllVehicles(closingdown);
forward SaveVehicle(vId, saveall);
forward SetVehicleSpawn(vId);
forward OnDriverEnterVehicle(playerid);
forward OnDriverExitVehicle(playerid);
forward ShowSpeedo(playerid);
forward OnSpeedoUpdate(playerid);
forward CheckCharacter(playerid);
forward CheckCharacterFinish(playerid);
forward GetUserInfo(playerid);
forward GetUserInfoFinish(playerid);
forward AuthenticateUser(playerid, givenPassword[]);
forward FetchCharacterInformation(playerid);
forward FetchCharacterInformationFinish(playerid);
forward UpdatePlayer(playerid);
forward UpdateAllPlayers();
forward UpdatePlayerInt(sqlid, data[], value);
forward UpdatePlayerFlo(sqlid, data[], Float:value);
forward UpdatePlayerStr(sqlid, data[], value[]);
/*
*    MAIN()
*/

main()
{
	print("FIREBIRDIE HAS MAIN()");
}

/*
*    STOCKS
*/

stock GetVehicleSqlId(vehicleid)
{
	for(new i; i < LOADED_VEHICLES; i++)
	{
		if(Vehicles[i][vSampId] == vehicleid) return i;
	}
	return -1;
}

stock VehPos(vId)
{
	GetVehiclePos(Vehicles[vId][vSampId], Vehicles[vId][vPosX], Vehicles[vId][vPosY], Vehicles[vId][vPosZ]);
	GetVehicleZAngle(Vehicles[vId][vSampId], Vehicles[vId][vAngZ]);
}

stock VehPosd(vId)
{
	Vehicles[vId][vPosX] = Vehicles[vId][vPosXd];
	Vehicles[vId][vPosY] = Vehicles[vId][vPosZd];
	Vehicles[vId][vPosZ] = Vehicles[vId][vPosYd];
	Vehicles[vId][vAngZ] = Vehicles[vId][vAngZd];
}

stock IsValidSkin(skinid) // author: Simon, External Credit #1
{
    #define	MAX_BAD_SKINS 22
    new badSkins[MAX_BAD_SKINS] =
    { 3, 4, 5, 6, 8, 42, 65, 74, 86, 119, 149, 208, 268, 273, 289 };
    if (skinid < 0 || skinid > 299) return false;
    for (new i = 0; i < MAX_BAD_SKINS; i++) { if (skinid == badSkins[i]) return false; }
    #undef MAX_BAD_SKINS
    return 1;
}

stock IsGroupMember(playerid)
{
	new ret = pInfo[playerid][pMember];
	if(pInfo[playerid][pLeader] > 0) ret = pInfo[playerid][pLeader];
	return ret;
}

stock showLogin(playerid)
{
	new string[64];
	format(string, 64, LANG_DIALOG_LOGIN_INFO, pInfo[playerid][uUserName]);
	ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, LANG_DIALOG_LOGIN_CAPTION, string, LANG_DIALOG_LOGIN_LOGINBUTTON, LANG_DIALOG_LOGIN_EXITBUTTON);
}

PasswordHash(password[], salt[])
{
	new string[STRING_LENGHT];
	format(string, STRING_LENGHT, "%s%s", strtolower(MD5_Hash(password)), salt);
	format(string, STRING_LENGHT, "%s", strtolower(MD5_Hash(string)));
	return string;
}

/*
*    NATIVES
*/


public OnGameModeInit()
{
	// First things first, lets attempt to connect to database.
	new Connection = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DB, MYSQL_PASSWORD);
	if(!Connection)
	{
		printf(LANG_FAILED_TO_CONNECT, SCRIPT_NAME);
		SendRconCommand("exit");
		return 1;
	}
	printf(LANG_CONNECTED, SCRIPT_NAME);
	mysql_debug(1);

	new string[24]; // 24 should be enough.
	format(string, 24, "%s %s r%s", SCRIPT_NAME, SCRIPT_VERSION, SCRIPT_REVISION);
	SetGameModeText(string);
	
	printf(LANG_LOADED, SCRIPT_NAME, SCRIPT_VERSION, SCRIPT_REVISION, SCRIPTER_NAME);
	format(WelcomeStr, 64, LANG_WELCOME_TO, SCRIPT_NAME, SCRIPT_VERSION, SCRIPT_REVISION, SCRIPTER_NAME);
	
	AddPlayerClass(0, 1492.5065, 1007.7800, 10.8203, 90, 0, 0, 0, 0, 0, 0);
	
	LoadAllVehiclesStart();
	
	for(new td; td < MAX_PLAYERS; td++)
	{
		InfoBar[td] = TextDrawCreate(200.0,418.0,":)"); //minX = 120 // 330
		TextDrawAlignment(InfoBar[td],1);
		TextDrawUseBox(InfoBar[td],1);
		TextDrawBoxColor(InfoBar[td],0x00000050);
		TextDrawTextSize(InfoBar[td],640.0,480.0);
		TextDrawFont(InfoBar[td],1);
		TextDrawSetOutline(InfoBar[td],0);
	}
	
	ShowNameTags(0);
	LimitGlobalChatRadius(CHAT_RADIUS);
	SetNameTagDrawDistance(40.0);	
	
	SetTimer("UpdateAllPlayers", 1000*60*15, true);
	
	EaglePickup = CreatePickup(348 , 2, 2394.2112,-1206.5466,27.8595, 0); // eagle
	SawnoffPickup = CreatePickup(350 , 2, 2505.4795,-1117.3652,56.2031, 0); // sawnoff
	MP5Pickup = CreatePickup(353 , 2, 2526.4465,-1237.0942,43.6563, 0); // mp5
	AKPickup = CreatePickup(355 , 2, 2345.6289,-1364.8751,28.0859, 0); // AK
	
	return 1;
}

public OnGameModeExit()
{
	SaveAllVehicles(true);
	UpdateAllPlayers();

	printf(LANG_UNLOADED, SCRIPT_NAME, SCRIPT_VERSION, SCRIPT_REVISION, SCRIPTER_NAME);
	return 1;
}

public OnPlayerConnect(playerid)
{
    GetPlayerName(playerid, pInfo[playerid][pCharName], 30);
	SendClientMessage(playerid, COLOR_YELLOW, WelcomeStr);
	InfoBarTimer[playerid] = -1;
	CheckCharacter(playerid);

	pInfo[playerid][pLoggedIn] = 0;
	return 1;
}

public OnPlayerDisconnect(playerid)
{
	UpdatePlayer(playerid);
}

public OnPlayerRequestClass(playerid)
{
	SetPlayerVirtualWorld(playerid, playerid);
	SetPlayerPos(playerid, 			1668.3400, 1392.7003, 15.4365);
	SetPlayerFacingAngle(playerid, 90);
	
	SetPlayerCameraPos(playerid, 	1730.4994, 1431.5691, 23.7563);
	SetPlayerCameraLookAt(playerid, 1679.3628, 1401.7775, 29.8623);
	return 1;
}

public OnPlayerSpawn(playerid)
{
    SetPlayerPos(playerid, pInfo[playerid][pPosX],pInfo[playerid][pPosY],pInfo[playerid][pPosZ]+1);
	SetPlayerVirtualWorld(playerid, pInfo[playerid][pVW]);
	SetPlayerInterior(playerid,pInfo[playerid][pInterior]);
	SetPlayerFacingAngle(playerid, pInfo[playerid][pAngle]);
	SetPlayerSkin(playerid, pInfo[playerid][pModel]);
	SetPlayerHealth(playerid, pInfo[playerid][pHealth]);
	SetPlayerColor(playerid, PLAYER_COLOR);
	
	SetCameraBehindPlayer(playerid);
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(newstate == PLAYER_STATE_DRIVER) 										OnDriverEnterVehicle(playerid);
	else if(oldstate == PLAYER_STATE_DRIVER && newstate == PLAYER_STATE_ONFOOT) OnDriverExitVehicle(playerid);
}

public OnVehicleDeath(vehicleid)
{
	SetVehicleToRespawn(vehicleid);
	
	new vSqlId = GetVehicleSqlId(vehicleid);
	if(vSqlId != -1)
	{
		Vehicles[vSqlId][vDeaths]++;
		VehPosd(vSqlId);
		SetTimerEx("SetVehicleSpawn", 500, 0, "d", vSqlId);
	}
	return 1;
}

public OnRconCommand(cmd[])
{
	if( strcmp(cmd, "gmx", true) == 0 ) OnGameModeExit();
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_LOGIN)
	{
		if(response == 0)
		{
			SendClientMessage(playerid, COLOR_RED, LANG_MUST_LOGIN);
			
			SendClientMessage(playerid, COLOR_GREEN, "N�gemist!");
			Kick(playerid);
			return 1;
		}
		else
		{
			AuthenticateUser(playerid, inputtext);
			return 1;
		}
	}
	else if( dialogid == DIALOG_PLAYER )
	{
	    if( response == 0 )
	    {
	        return 1;
	    }
	    else if( listitem == 0 )
	    {
			SendEs(playerid);
	    }
	}
	else if( dialogid == DIALOG_SENDES )
	{
	    if( strlen(inputtext) == 0 )
		{
		    SendClientMessage(playerid, COLOR_RED, "T�hja eras�numit ei saa saata!");
		    SendEs(playerid);
		}
		else
		{
		    if( IsPlayerConnected(pInfo[playerid][SelectedPlayer]) && pInfo[pInfo[playerid][SelectedPlayer]][pLoggedIn] )
		    {
				ForwardEs(playerid, inputtext);
		    }
			else
			SendClientMessage(playerid, COLOR_RED, "M�ngijat ei ole (enam) online!");
		}
	}
	return 1;
}
public OnPlayerRequestSpawn(playerid)
{
    if( !pInfo[playerid][pLoggedIn] )
    {
        SendClientMessage(playerid, COLOR_RED, LANG_MUST_LOGIN);
		
		showLogin(playerid);
		return 0;    
    }
    return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	if( pickupid == EaglePickup )
		GivePlayerWeapon(playerid, 24, 100);
	if( pickupid == SawnoffPickup )
		GivePlayerWeapon(playerid, 26, 100);
	if( pickupid == MP5Pickup )
		GivePlayerWeapon(playerid, 29, 100);
	if( pickupid == AKPickup )
		GivePlayerWeapon(playerid, 30, 100);

	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	pInfo[playerid][pPosX] = 2420.3459;
	pInfo[playerid][pPosY] = -1229.8799;
	pInfo[playerid][pPosZ] = 24.7299;
	pInfo[playerid][pAngle] = 180;
	pInfo[playerid][pHealth] = 100;
	pInfo[playerid][pVW] = 0;
	pInfo[playerid][pInterior] = 0;
	
	return 1;
}

public OnPlayerText(playerid, text[])
{
	new delay = ( strlen(text) * 150 ) + 2000;
	new str[STRING_LENGHT];
	format(str, sizeof(str),"%s:  %s", pInfo[playerid][pCharName], text);
	SetPlayerChatBubble(playerid, str, COLOR_CHAT_IC, CHAT_RADIUS, delay);
	SCMTAInPlayerRadius(playerid,CHAT_RADIUS, COLOR_CHAT_IC, str);
	return 0;
}
public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
    pInfo[playerid][SelectedPlayer] = clickedplayerid;
	ShowPlayerDialog( playerid, DIALOG_PLAYER, DIALOG_STYLE_LIST, "M�ngija Valikud", "Eras�num", "Ok", "V�lju");
	return 1;
}
/*
*    COMMANDS
*/
public OnPlayerCommandText(playerid, cmdtext[])
{
	dcmd(o, 1, cmdtext);
	dcmd(b, 1, cmdtext);
	dcmd(me, 2, cmdtext);
	dcmd(s, 1, cmdtext);
	dcmd(es, 2, cmdtext);
	dcmd(mj, 2, cmdtext);
	return 1;
}

dcmd_o(playerid, params[])
{
	new text[STRING_LENGHT], str[STRING_LENGHT];
	sscanf(params, "s", text);
	
	if(strlen(text) == 0) return SendClientMessage(playerid, COLOR_RED, "KASUTUS: /o tekst");

	format(str, sizeof(str), "(( %s: %s ))", pInfo[playerid][pCharName], text);
	SendClientMessageToAll(COLOR_CHAT_OOC_GLOBAL, str);
	return 1;
}
dcmd_b(playerid, params[])
{
	new text[STRING_LENGHT], str[STRING_LENGHT];
	sscanf(params, "s", text);

	if(strlen(text) == 0) return SendClientMessage(playerid, COLOR_RED, "KASUTUS: /b tekst");

	format(str, sizeof(str), "%s OOC:(( %s ))", pInfo[playerid][pCharName], text);
	SCMTAInPlayerRadius(playerid, CHAT_RADIUS, COLOR_CHAT_OOC_LOCAL, str);
	return 1;
}
dcmd_me(playerid, params[])
{
	new text[STRING_LENGHT];
	sscanf(params, "s", text);

	if(strlen(text) == 0) return SendClientMessage(playerid, COLOR_RED, "KASUTUS: /me tekst");

	SendEmote(playerid, text);
	return 1;
}
dcmd_s(playerid, params[])
{
	new text[STRING_LENGHT], str[STRING_LENGHT];
	sscanf(params, "s", text);

	if(strlen(text) == 0) return SendClientMessage(playerid, COLOR_RED, "KASUTUS: /s tekst");

	new delay = ( strlen(text) * 150 ) + 2000;
	format(str, sizeof(str), "%s karjub: %s", pInfo[playerid][pCharName], text);
	SetPlayerChatBubble(playerid, str, COLOR_CHAT_SHOUT, CHAT_RADIUS_SHOUT, delay);
	SCMTAInPlayerRadius(playerid,CHAT_RADIUS_SHOUT, COLOR_CHAT_SHOUT, str);
	return 1;
}
dcmd_es(playerid, params[])
{
	new selplayer;
	sscanf(params, "u", selplayer);
	pInfo[playerid][SelectedPlayer] = selplayer;
	SendEs(playerid);
}

dcmd_mj(playerid, params[])
{
	#pragma unused params
	new Float: vx, Float: vy, Float: vz;
	GetPlayerVelocity(playerid, vx, vy, vz);
	vz += 10.0;
	GetPlayerVelocity(playerid, vx, vy, vz);
	SendEmote(playerid, "h�ppab jube k�rgele.");
	return 1;
}
/*
*    PUBLICS
*/

public SendEs(playerid)
{
	new str[STRING_LENGHT];
	format(str, sizeof(str),"Saada eras�num m�ngijale: %s", pInfo[pInfo[playerid][SelectedPlayer]][pCharName]);
	ShowPlayerDialog(playerid, DIALOG_SENDES, DIALOG_STYLE_INPUT,"Eras�num", str, "Saada", "V�lju");
}
public ForwardEs(playerid, message[])
{
	new str[STRING_LENGHT];
	
	format(str, sizeof(str),"-> %s: %s", pInfo[pInfo[playerid][SelectedPlayer]][pCharName], message);
	SendClientMessage(playerid, COLOR_CHAT_ES, str);
	format(str, sizeof(str),"<- %s: %s", pInfo[playerid][pCharName], message);
	SendClientMessage(pInfo[playerid][SelectedPlayer], COLOR_CHAT_ES, str);
}

public SendEmote(playerid, emote[])
{
	new Float:PlayerLocX, Float:PlayerLocY, Float:PlayerLocZ, str[STRING_LENGHT];
	GetPlayerPos(playerid, PlayerLocX, PlayerLocY, PlayerLocZ);
	format(str, sizeof(str),"*%s %s*", pInfo[playerid][pCharName], emote);
	for( new i = 0; i <= MAX_PLAYERS; i++ )
	{
	    if( IsPlayerConnected(i) && pInfo[i][pLoggedIn] )
	    {
	        if( IsPlayerInRangeOfPoint(i, CHAT_RADIUS, PlayerLocX, PlayerLocY, PlayerLocZ) )
	        {
				SendClientMessage(i, COLOR_CHAT_ME, str);
	        }
	    }
	}
}
public SCMTAInPlayerRadius(playerid, radius, color, message[])
{
	new Float:PlayerLocX, Float:PlayerLocY, Float:PlayerLocZ;
	GetPlayerPos(playerid, PlayerLocX, PlayerLocY, PlayerLocZ);
	for( new i = 0; i <= MAX_PLAYERS; i++ )
	{
	    if( IsPlayerConnected(i) && pInfo[i][pLoggedIn] )
	    {
	        if( IsPlayerInRangeOfPoint(i, radius, PlayerLocX, PlayerLocY, PlayerLocZ) )
	        {
				SendClientMessage(i, color, message);
	        }
	    }
	}
}

public OnQueryFinish(query[], resultid)
{
	if( resultid == VEHICLE_LOAD_THREAD )
	{
		LoadAllVehiclesFinish();
	}
	else if( resultid == VEHICLE_SAVE_THREAD )
	{
		if(VEHICLE_SAVE_NEXT < LOADED_VEHICLES)
		{
			SaveVehicle(VEHICLE_SAVE_NEXT, true);
			VEHICLE_SAVE_NEXT++;
		}
		else VEHICLE_SAVE_NEXT = 0;
	}
	else if( resultid == FETCH_UINFO_THREAD )
	{
		FetchCharacterInformationFinish(Fetch_UInfo_Thread);
	}
}

public LoadAllVehiclesStart()
{
	print("\t\t Started Loading Vehicles.");
	new query[32];
	format(query, 32, "SELECT * FROM %svehicles", MYSQL_PREFIX);
	mysql_query(query, VEHICLE_LOAD_THREAD);
}

public LoadAllVehiclesFinish()
{
	mysql_store_result();
	
	new Field[64], Data[128], vId;
	for(vId = 0; vId < mysql_num_rows(); vId++)
	{
		mysql_fetch_row(Data);
		
		mysql_fetch_field_row(Field, "vehicleId");
		Vehicles[vId][vSqlID] = strval(Field);
		
		mysql_fetch_field_row(Field, "vModel");
		Vehicles[vId][vModel] = strval(Field);
		
		mysql_fetch_field_row(Field, "vType");
		Vehicles[vId][vType] = strval(Field);
		
		mysql_fetch_field_row(Field, "vPosXd");
		Vehicles[vId][vPosXd] = floatstr(Field);
		
		mysql_fetch_field_row(Field, "vPosYd");
		Vehicles[vId][vPosYd] = floatstr(Field);
		
		mysql_fetch_field_row(Field, "vPosZd");
		Vehicles[vId][vPosZd] = floatstr(Field);
		
		mysql_fetch_field_row(Field, "vAngZd");
		Vehicles[vId][vAngZd] = floatstr(Field);
		
		mysql_fetch_field_row(Field, "vPosX");
		Vehicles[vId][vPosX] = floatstr(Field);
		
		mysql_fetch_field_row(Field, "vPosY");
		Vehicles[vId][vPosY] = floatstr(Field);
		
		mysql_fetch_field_row(Field, "vPosZ");
		Vehicles[vId][vPosZ] = floatstr(Field);
		
		mysql_fetch_field_row(Field, "vAngZ");
		Vehicles[vId][vAngZ] = floatstr(Field);
		
		mysql_fetch_field_row(Field, "vColor1");
		Vehicles[vId][vColor1] = strval(Field);
		
		mysql_fetch_field_row(Field, "vOwner");
		Vehicles[vId][vOwner] = strval(Field);
		
		mysql_fetch_field_row(Field, "vValue");
		Vehicles[vId][vValue] = strval(Field);
		
		mysql_fetch_field_row(Field, "vDeaths");
		Vehicles[vId][vDeaths] = strval(Field);
		
		mysql_fetch_field_row(Field, "vHealth");
		Vehicles[vId][vHealth] = floatstr(Field);
		if(Vehicles[vId][vHealth] < 400.0) Vehicles[vId][vHealth] = 450.0;
		
		Vehicles[vId][vSampId] = AddStaticVehicleEx(Vehicles[vId][vModel], 
													Vehicles[vId][vPosXd],
													Vehicles[vId][vPosYd],
													Vehicles[vId][vPosZd],
													Vehicles[vId][vAngZd],
													Vehicles[vId][vColor1],
													Vehicles[vId][vColor2],
													VEHICLE_DELAY);
		SetTimerEx("SetVehicleSpawn", 500, 0, "d", vId);
	}
	LOADED_VEHICLES = vId+1;
	printf("\t\t %d Vehicles Loaded.", LOADED_VEHICLES);
	mysql_free_result();
}

public SaveAllVehicles(closingdown)
{
	print("Started Saving all vehicles.");
	if(closingdown)
	{
		print("Saving all before server shutdown.");
		for(new i; i < LOADED_VEHICLES; i++)
		{
			SaveVehicle(i, false); // Kui server on kinni minemas peame kindlad olema, et ennem asjad salvestatud on.
		}
		print("All vehicles saved.");
	}
	else
	{
		SaveVehicle(VEHICLE_SAVE_NEXT, true);
		VEHICLE_SAVE_NEXT++;
	}
}

public SaveVehicle(vId, saveall)
{
	VehPos(vId);
	new query[512];
	
	format(query, 512, "UPDATE %svehicles SET vPosX = '%.5f', vPosY = '%.5f', vPosZ = '%.5f', vAngZ = '%.5f', vColor1 = '%d', vColor2 = '%d', vOwner = '%d', vValue = '%d', vDeaths = '%d', vHealth = '%f' WHERE vehicleId = '%d'",
		MYSQL_PREFIX,
		Vehicles[vId][vPosX],
		Vehicles[vId][vPosY],
		Vehicles[vId][vPosZ],
		Vehicles[vId][vAngZ],
		Vehicles[vId][vColor1],
		Vehicles[vId][vColor2],
		Vehicles[vId][vOwner],
		Vehicles[vId][vValue],
		Vehicles[vId][vDeaths],
		Vehicles[vId][vHealth],
		Vehicles[vId][vSqlID]);
	if(!saveall) mysql_query(query);
	else mysql_query(query, VEHICLE_SAVE_THREAD);
}

public SetVehicleSpawn(vId)
{
	SetVehicleHealth(Vehicles[vId][vSampId], Vehicles[vId][vHealth]);
	SetVehiclePos(Vehicles[vId][vSampId], Vehicles[vId][vPosX], Vehicles[vId][vPosY], Vehicles[vId][vPosZ]);
	SetVehicleZAngle(Vehicles[vId][vSampId], Vehicles[vId][vAngZ]);
}

public OnDriverEnterVehicle(playerid)
{
	new vId = GetVehicleSqlId(GetPlayerVehicleID(playerid));
	new Remove = false, Freeze = false;
	new string[128];
	
	if(vId == -1) return 1;
	else
	{
		if		(Vehicles[vId][vType] == VEHICLE_GROUP)
		{
			if(Vehicles[vId][vOwner] == 0) Remove = false;
			else if(IsGroupMember(playerid) != Vehicles[vId][vOwner]) Remove = true;
		}
		else if	(Vehicles[vId][vType] == VEHICLE_JOB)
		{
			if(Vehicles[vId][vOwner] == 0) Remove = false;
			else if(pInfo[playerid][pJob] != Vehicles[vId][vOwner]) Remove = true;
		}
		else if	(Vehicles[vId][vType] == VEHICLE_BUYABLE)
		{
			if(Vehicles[vId][vOwner] > 0) Remove = true;
			else
			{	
				format(string, 128, "~y~ %s ~n~~g~ Hind: %d SAK", CarNames[Vehicles[vId][vModel] - 400], Vehicles[vId][vValue]);
				GameTextForPlayer(playerid, string, 3000, 4);
				
				format(string, 128, "Kirjuta: /omasin, et seda masinat osta.");
				SendClientMessage(playerid, COLOR_GREEN, string);	
				Freeze = false;
			}
		}
		else if	(Vehicles[vId][vType] == VEHICLE_SPECIAL)
		{
			if(!IsPlayerNPC(playerid)) Remove = true;
		}
		else
		{
			if(pInfo[playerid][pAdmin] < 1) Remove = true;
			else if(pInfo[playerid][pAdmin] < Vehicles[vId][vOwner]) Remove = true;
		}
	}
	
	if(Remove)
	{
		RemovePlayerFromVehicle(playerid);
		SendClientMessage(playerid, COLOR_RED, "Sul pole selle auto v�tmeid.");
	}
	else
	{
		if(Freeze) TogglePlayerControllable(playerid, 0);
	
		ShowSpeedo(playerid);
		format(string, 128, "%s", CarNames[Vehicles[vId][vModel] - 400]);
		GameTextForPlayer(playerid, string, 6000, 1);
	}
	return 1;
}

public OnDriverExitVehicle(playerid)
{
	InfoBarTimer[playerid] = -1;
}

public ShowSpeedo(playerid)
{
	if(InfoBarTimer[playerid] != -1) return 0;
	
	InfoBarTimer[playerid] = SetTimerEx("OnSpeedoUpdate", 500, 1, "i", playerid);
	TextDrawShowForPlayer(playerid, InfoBar[playerid]);	
	return 1;
}

public OnSpeedoUpdate(playerid)
{
	if(IsPlayerConnected(playerid) && IsPlayerInAnyVehicle(playerid))
	{
		new vId = GetVehicleSqlId(GetPlayerVehicleID(playerid));
		GetVehicleHealth(Vehicles[vId][vSampId], Vehicles[vId][vHealth]);
		new hProtsenti = floatround((Vehicles[vId][vHealth] - 300) / 10);
		new string[128], fuel[3] = "-";
		
		GetVehicleVelocity(Vehicles[vId][vSampId], Vehicles[vId][vPosX], Vehicles[vId][vPosY], Vehicles[vId][vPosZ]);
		new Float: distance = floatabs(Vehicles[vId][vPosX]) + floatabs(Vehicles[vId][vPosY]) + floatabs(Vehicles[vId][vPosZ]);
		new speed = floatround(distance * 175);
		format(string,sizeof(string),"~y~~h~Bensiin: %s  ~y~~h~Kiirus: ~w~%i km/h  ~y~~h~Korras: ~w~%d", fuel, speed, hProtsenti);
		TextDrawSetString(InfoBar[playerid], string);
	}
	else
	{
		TextDrawHideForPlayer(playerid, InfoBar[playerid]);
		KillTimer(InfoBarTimer[playerid]);
	}
}

public CheckCharacter(playerid)
{
	new eName[32], query[86];
	mysql_real_escape_string(pInfo[playerid][pCharName], eName);
	format(query, 86, "SELECT id, userid FROM %scharacters WHERE name = '%s' LIMIT 0, 1", MYSQL_PREFIX, eName);	
	mysql_query(query);
		
	if(mysql_store_result())
	{
		if(mysql_num_rows() > 0)
		{
			new Field[64], Data[128];
			mysql_fetch_row(Data);
			
			mysql_fetch_field_row(Field, "id");
			pInfo[playerid][pSqlId] = strval(Field);
			
			mysql_fetch_field_row(Field, "userid");
			pInfo[playerid][uSqlId] = strval(Field);
			mysql_free_result();
			
			GetUserInfo(playerid);
			return 1;
		}	
	}
	
	SendClientMessage(playerid, COLOR_RED, LANG_NOCHARACTER);
	Kick(playerid);
	return 1;
}

public GetUserInfo(playerid)
{
	new query[86];
	format(query, 86, "SELECT username, password, salt FROM user WHERE userid = '%d' LIMIT 1", pInfo[playerid][uSqlId]);
	mysql_query(query);

	if(mysql_store_result() == 1)
	{		
		if(mysql_num_rows() > 0)
		{
			new Field[64], Data[128];
			mysql_fetch_row(Data);
			
			mysql_fetch_field_row(Field, "username");
			strmid(pInfo[playerid][uUserName], Field, 0, strlen(Field), STRING_LENGHT);
			
			mysql_fetch_field_row(Field, "password");
			strmid(pInfo[playerid][uPassWordHash], Field, 0, strlen(Field), STRING_LENGHT);
			
			mysql_fetch_field_row(Field, "salt");
			strmid(pInfo[playerid][uSalt], Field, 0, strlen(Field), STRING_LENGHT);
			mysql_free_result();
		}	
		showLogin(playerid);
		return 1;
	}
	SendClientMessage(playerid, COLOR_RED, LANG_NOUSER);
	Kick(playerid);
	return 1;
}

public AuthenticateUser(playerid, givenPassword[])
{
	new string[STRING_LENGHT];
	format(string, STRING_LENGHT, "%s", PasswordHash(givenPassword, pInfo[playerid][uSalt]));
	new strC = strcmp(pInfo[playerid][uPassWordHash], string, true);
	

	if(strC != 0) // wrong Password
	{
		SendClientMessage(playerid, COLOR_RED, LANG_WRONG_PASSWORD);
		showLogin(playerid);
	}
	else
	{
	    FetchCharacterInformation(playerid);
	}
	return 1;
}

public FetchCharacterInformation(playerid)
{
	if(Fetch_UInfo_Thread != -1) // thread is busy, lets attemp again in 1 second.
	{
		SetTimerEx("FetchUserInformation", 1000, 0, "i", playerid);
		return 1;
	}
	Fetch_UInfo_Thread = playerid;

	new query[86];
	format(query, 86, "SELECT * FROM %scharacters WHERE id = '%d' LIMIT 0, 1", MYSQL_PREFIX, pInfo[playerid][pSqlId]);
	mysql_query(query, FETCH_UINFO_THREAD);
	SetTimerEx("FetchCharacterInformationFinish", SQL_FINISH_TIME, 0, "i", playerid);
	return 1;

}

public FetchCharacterInformationFinish(playerid)
{
	if(Fetch_UInfo_Thread != playerid) return 1;
	
	if(mysql_store_result() == 1)
	{
		if(mysql_num_rows() < 1)
		{
			SendClientMessage(playerid, COLOR_RED, LANG_NOCHARACTER);
			Kick(playerid);
		}
		else
		{
			new Field[64], Data[128];
			mysql_fetch_row(Data);
			
			mysql_fetch_field_row(Field, "model");
			pInfo[playerid][pModel] = strval(Field);
			mysql_fetch_field_row(Field, "money");
			GivePlayerMoney(playerid, strval(Field));
			mysql_fetch_field_row(Field, "posX");
			pInfo[playerid][pPosX] = floatstr(Field);
			mysql_fetch_field_row(Field, "posY");
			pInfo[playerid][pPosY] = floatstr(Field);
			mysql_fetch_field_row(Field, "posZ");
			pInfo[playerid][pPosZ] = floatstr(Field);
			mysql_fetch_field_row(Field, "angle");
			pInfo[playerid][pAngle] = floatstr(Field);
			mysql_fetch_field_row(Field, "VirtualWorld");
			pInfo[playerid][pVW] = strval(Field);
			mysql_fetch_field_row(Field, "interior");
			pInfo[playerid][pInterior] = strval(Field);
			mysql_fetch_field_row(Field, "health");
			pInfo[playerid][pHealth] = floatstr(Field);
			
			mysql_free_result();
			SendClientMessage(playerid, COLOR_GREEN, LANG_LOGGED_IN);
			pInfo[playerid][pLoggedIn] = 1;
			SpawnPlayer(playerid);
		}
	}
	Fetch_UInfo_Thread = -1;
	return 1;
}

public UpdatePlayer(playerid)
{
	if(!pInfo[playerid][pLoggedIn]) return 1;
	
	GetPlayerPos(playerid, pInfo[playerid][pPosX], pInfo[playerid][pPosY], pInfo[playerid][pPosZ]);
	GetPlayerFacingAngle(playerid, pInfo[playerid][pAngle]);
	GetPlayerHealth(playerid, pInfo[playerid][pHealth]);
	
	new sqlid = pInfo[playerid][pSqlId];
	
	UpdatePlayerInt(sqlid, "money", GetPlayerMoney(playerid));
	UpdatePlayerInt(sqlid, "model", pInfo[playerid][pModel]);
	UpdatePlayerFlo(sqlid, "posX", pInfo[playerid][pPosX]);
	UpdatePlayerFlo(sqlid, "posY", pInfo[playerid][pPosY]);
	UpdatePlayerFlo(sqlid, "posZ", pInfo[playerid][pPosZ]);
	UpdatePlayerFlo(sqlid, "angle", pInfo[playerid][pAngle]);
	UpdatePlayerInt(sqlid, "VirtualWorld", pInfo[playerid][pVW]);
	UpdatePlayerInt(sqlid, "interior", pInfo[playerid][pInterior]);
	UpdatePlayerFlo(sqlid, "health", pInfo[playerid][pHealth]);

	return 1;
}

public UpdateAllPlayers()
{
	for( new i = 0; i <= MAX_PLAYERS; i++ )
	{
	    if( IsPlayerConnected(i) && pInfo[i][pLoggedIn] )
	    UpdatePlayer(i);
	}
}

public UpdatePlayerInt(sqlid, data[], value)
{
    new query[128];
    format(query, 128, "UPDATE %scharacters SET %s = '%i' WHERE id = '%d'", MYSQL_PREFIX, data, value, sqlid);
    mysql_query(query);
}
public UpdatePlayerFlo(sqlid, data[], Float:value)
{
    new query[128];
    format(query, 128, "UPDATE %scharacters SET %s = '%f' WHERE id = '%d'", MYSQL_PREFIX, data, value, sqlid);
    mysql_query(query);
}
public UpdatePlayerStr(sqlid, data[], value[])
{
    new query[128];
    format(query, 128, "UPDATE %scharacters SET %s = '%s' WHERE id = '%d'", MYSQL_PREFIX, data, value, sqlid);
    mysql_query(query);
}

/*
*    EOF
*/
