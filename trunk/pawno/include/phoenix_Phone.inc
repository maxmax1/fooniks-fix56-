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
*    The Initial Developers of the Original Code are Jyrno42 and 13th.
*/

/*
*    This File: phoenix_Phone.inc
*    Purpose: Create the phone system for Phoenix.
*/

/*
*    DEFINES
*/

#if !defined rand
rand(minnum = cellmin,maxnum = cellmax) return random(maxnum - minnum + 1) + minnum;
#endif

#define COLOR_PHONE 0xF0DC82AA

#define MAX_CONTACTS 12

#define MAX_SIMCARDS 300

#define CALL_NONE 			0
#define CALL_PLAYER 		1
#define CALL_RECIVE			2
#define CALL_CONNECTED 		3

#define HANGUP_ME 			0
#define CALL_PLAYER 		1
#define CALL_RECIVE			2
#define CALL_CONNECTED 		3

#define CALL_END_UNKNOWN	0
#define CALL_END_WRONG_NR	1
#define CALL_NUMBER_INUSE	2
#define CALL_END_NO_ANWSER	3
#define CALL_END_DENIED		4
#define CALL_END_HANGUP		5
#define CALL_END_HANGUP_ME	6
#define CALL_END_HANGUP_OT	7

#define ITEM_SIMCARD 13

/*
*    GLOBALS
*/

enum phoneInf
{	
	// Other Inf
	bool: hasPhone,
	bool: simCardIn,
	simCard,	

	// Callin stuff.
	onCall,
	ringTime,
	callPlayer	
};
new gPlayerPhone[MAX_PLAYERS][phoneInf];

enum simInf
{
	sNumber,
	companyId
};
new gSimCards[MAX_SIMCARDS][simInf];
Itter_Create(SimCard, MAX_SIMCARDS);

new 
	gContactMemoryNR[MAX_SIMCARDS][MAX_CONTACTS],
	gContactMemoryName[MAX_SIMCARDS][MAX_CONTACTS][16], 
	bool: gContactMemoryUsed[MAX_SIMCARDS][MAX_CONTACTS];

/*
*    FORWARDS
*/

forward GiveSimCard(playerid, company);
forward ActivateSimCard(playerid, selectedCard, other);
forward PlayerCallNumber(playerid, number);
forward EndCall(playerid, reason);
forward PhoneTimer();

forward ph_Phone_OnPlayerText(playerid, text[]);

/*
*    STOCKS
*/

stock GenerateRandomNumber(company)
{
	new number[12];	
	format(number, 12, "5%d%d", company, rand(100000, 999999));
	return strval(number);
}

stock FindNumberFromContactname(simcard, namestr[])
{
	for(new i; i < MAX_CONTACTS; i++)
	{
		if(!gContactMemoryUsed[simcard][i]) continue;
		if(!strcmp(namestr, gContactMemoryName[simcard][i])) return gContactMemoryNR[simcard][i];
	}
	return -1;
}

stock findPlayerFromNumber(number)
{
	foreach(User, i)
	{
		if(!gPlayerPhone[i][hasPhone] || !gPlayerPhone[i][simCardIn] || gPlayerPhone[i][simCard] < 0 || gPlayerPhone[i][simCard] > MAX_SIMCARDS) continue;
		if(gSimCards[gPlayerPhone[i][simCard]][sNumber] == number) return i;
	}
	return -1;
}

/*
*    COMMANDS
*/

COMMAND:helista(playerid, params[])
{
	if(!gPlayerPhone[playerid][hasPhone]) return SendClientMessage(playerid, COLOR_RED, "Sul pole telefoni!");
	if(!gPlayerPhone[playerid][simCardIn]) return SendClientMessage(playerid, COLOR_RED, "Su telefonis pole SIM-kaarti!");

	new nr = -1, name[16], found = true;
	if(sscanf(params, "d", nr)) found = false;
	else if(sscanf(params, "s", name)) found = false;
	
	if(!found) return SendClientMessage(playerid, COLOR_YELLOW, "KASUTUS: /helista number/nimi");
	
	if(nr != -1)
	{
		PlayerCallNumber(playerid, nr);
	}
	else
	{
		nr = FindNumberFromContactname(gPlayerPhone[playerid][simCard], name);
		if(nr != -1) PlayerCallNumber(playerid, nr);
		else SendClientMessage(playerid, COLOR_YELLOW, "Sellist nime pole sinu kontaktide hulgas.");
	}	
	return 1;
}

COMMAND:vasta(playerid, params[])
{
	if(!gPlayerPhone[playerid][hasPhone]) return SendClientMessage(playerid, COLOR_RED, "Sul pole telefoni!");
	if(!gPlayerPhone[playerid][simCardIn]) return SendClientMessage(playerid, COLOR_RED, "Su telefonis pole SIM-kaarti!");
	if(gPlayerPhone[playerid][onCall] != CALL_RECIVE) return SendClientMessage(playerid, COLOR_RED, "Keegi ei helista sulle!");
	
	new otherId = gPlayerPhone[playerid][callPlayer];
	gPlayerPhone[playerid][onCall] = CALL_CONNECTED;
	gPlayerPhone[otherId][onCall] = CALL_CONNECTED;
	
	SendClientMessage(playerid, COLOR_PHONE, "...�hendatud... (( saad n��d telefoni r��kida ))");
	SendClientMessage(otherId, COLOR_PHONE, "...�hendatud... (( saad n��d telefoni r��kida ))");
	
	return 1;
}

COMMAND:katkesta(playerid, params[])
{
	if(!gPlayerPhone[playerid][hasPhone]) return SendClientMessage(playerid, COLOR_RED, "Sul pole telefoni!");
	if(!gPlayerPhone[playerid][simCardIn]) return SendClientMessage(playerid, COLOR_RED, "Su telefonis pole SIM-kaarti!");
	
	if(gPlayerPhone[playerid][onCall] == CALL_RECIVE)
	{
		EndCall(playerid, HANGUP_ME);
		return 1;
	}
	else if(gPlayerPhone[playerid][onCall] == CALL_CONNECTED)
	{
		EndCall(playerid, HANGUP_ME);
		return 1;
	}	
	
	return SendClientMessage(playerid, COLOR_RED, "Keegi ei helista sulle/sa ei helista kellegile!");
}

/*
*    PUBLICS
*/

public GiveSimCard(playerid, company)
{
	new freeId = Itter_Free(SimCard);
	if(freeId == -1) return 1;
	
	gSimCards[freeId][sNumber] = GenerateRandomNumber(company);
	gSimCards[freeId][companyId] = company;
	Itter_Add(SimCard, freeId);
	
	giveItem(playerid, ITEM_SIMCARD, freeId);	
	return 0;
}

public ActivateSimCard(playerid, selectedCard, other)
{
	if(!gPlayerPhone[playerid][hasPhone])
	{
		return SendClientMessage(playerid, COLOR_RED, "Sul pole telefoni kuhu seda simkaarti panna!");
	}
	if(gPlayerPhone[playerid][simCard] == selectedCard)
	{
		return SendClientMessage(playerid, COLOR_YELLOW, "See simkaart on juba su telefonis.");
	}
	
	gPlayerPhone[playerid][simCard] = selectedCard;
	gPlayerPhone[playerid][simCardIn] = true;
	return SendClientMessage(playerid, COLOR_YELLOW, "Paigaldasid oma telefoni edukalt SIM-Kaardi.");
}

public PlayerCallNumber(playerid, number)
{
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USECELLPHONE);
	gPlayerPhone[playerid][callPlayer] = findPlayerFromNumber(number);
	gPlayerPhone[playerid][onCall] = CALL_PLAYER;
	gPlayerPhone[playerid][ringTime] = 5;
	
	if(gPlayerPhone[playerid][callPlayer] != -1)
	{
		new otherId = gPlayerPhone[playerid][callPlayer];
		
		if(gPlayerPhone[otherId][onCall] == CALL_NONE)
		{
			gPlayerPhone[otherId][callPlayer] = playerid;
			gPlayerPhone[otherId][onCall] = CALL_RECIVE;
			gPlayerPhone[otherId][ringTime] = 5;
		}
		else
		{
			EndCall(playerid, CALL_NUMBER_INUSE);
		}
	}
	
	SendClientMessage(playerid, COLOR_PHONE, "kutsub...");
}

public EndCall(playerid, reason)
{	
	gPlayerPhone[playerid][callPlayer] = -1;
	gPlayerPhone[playerid][onCall] = CALL_NONE;
	gPlayerPhone[playerid][ringTime] = 0;
	
	if(reason == CALL_END_WRONG_NR)
	{
		SendClientMessage(playerid, COLOR_PHONE, "...telefon millele te helistate ei ole sisse l�litatud v�i asub v�ljaspool teeninduspiirkonda...");
	}
	else if(reason == CALL_NUMBER_INUSE)
	{
		SendClientMessage(playerid, COLOR_PHONE, "...kinnine toon...");
	}
	else if(reason == CALL_END_NO_ANWSER)
	{
		SendClientMessage(playerid, COLOR_PHONE, "...ei vasta...");
	}
	else if(reason == CALL_END_DENIED)
	{
		SendClientMessage(playerid, COLOR_PHONE, "...k�nest keelduti...");
	}
	else if(reason == CALL_END_HANGUP || reason == CALL_END_UNKNOWN)
	{
		SendClientMessage(playerid, COLOR_PHONE, "...k�ne l�ppes...");
	}
	else if(reason == CALL_END_HANGUP_ME)
	{
		SendClientMessage(playerid, COLOR_PHONE, "panid toru �ra");
	}
	else if(reason == CALL_END_HANGUP_OT)
	{
		SendClientMessage(playerid, COLOR_PHONE, "teine m�ngija pani toru �ra");
	}
	
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_STOPUSECELLPHONE);
}

public PhoneTimer()
{
	foreach(User, playerid)
	{
		if(gPlayerPhone[playerid][onCall] == CALL_PLAYER)
		{
			if(gPlayerPhone[playerid][callPlayer] == -1)
			{
				EndCall(playerid, CALL_END_WRONG_NR);
				continue;
			}
			
			gPlayerPhone[playerid][ringTime]--;
			if(gPlayerPhone[playerid][ringTime] < 0)
			{
				EndCall(playerid, CALL_END_NO_ANWSER);
			}
			
			new otherId = gPlayerPhone[playerid][callPlayer];
			if(otherId < 0 || otherId > MAX_PLAYERS || !IsPlayerConnected(otherId) || gPlayerPhone[otherId][onCall] == CALL_NONE) EndCall(playerid, CALL_END_DENIED);
		}
		else if(gPlayerPhone[playerid][onCall] == CALL_CONNECTED)
		{
			new otherId = gPlayerPhone[playerid][callPlayer];			
			if(otherId < 0 || otherId > MAX_PLAYERS || !IsPlayerConnected(otherId) || gPlayerPhone[otherId][onCall] == CALL_NONE)
			{
				EndCall(playerid, CALL_END_HANGUP);
			}
		}
		else if(gPlayerPhone[playerid][onCall] == CALL_RECIVE)
		{
			new otherId = gPlayerPhone[playerid][callPlayer];
			if(otherId < 0 || otherId > MAX_PLAYERS || !IsPlayerConnected(otherId) || gPlayerPhone[otherId][onCall] == CALL_NONE) EndCall(playerid, CALL_END_HANGUP_OT);
			
			gPlayerPhone[playerid][ringTime]--;
			if(gPlayerPhone[playerid][ringTime] > 0)
			{
				// Play Music
			}			
		}
	}
}

/*
*    ALS
*/

public OnPlayerText(playerid, text[])
{
	if(gPlayerPhone[playerid][onCall] == CALL_CONNECTED)
	{
		new otherId = gPlayerPhone[playerid][callPlayer];
		if(otherId < 0 || otherId > MAX_PLAYERS || !IsPlayerConnected(otherId) || gPlayerPhone[otherId][onCall] == CALL_NONE)
		{
			EndCall(playerid, CALL_END_HANGUP);
		}
		else
		{
			new string[128];
			format(string, 128, "TELEFON %s:  %s", pInfo[playerid][pCharName], text);
			SendClientMessage(playerid, COLOR_PHONE, string);
			SendClientMessage(otherId, COLOR_PHONE, string);
		}		
		
		return 0;
	}

	
    if (funcidx("ph_Phone_OnPlayerText") != -1)
    {
        return CallLocalFunction("ph_Phone_OnPlayerText", "is", playerid, text);
    }
    return 1;
}

#if defined _ALS_OnPlayerText
    #undef OnPlayerText
#else
    #define _ALS_OnPlayerText
#endif
#define OnPlayerText ph_Phone_OnPlayerText