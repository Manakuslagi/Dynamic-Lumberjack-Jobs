/*
[SA-MP] Lumberjack Activity V-2.0

Lumberjack Activity FilterScript with dynamic trees using mysql
Author: Palwa
Updated : Naomi

# Feature updated :
	Change to mysql
	    Added Progress Bar
*/

#include <a_samp>
#include <sscanf2>
#include <zcmd>
#include <foreach>
#include <streamer>
#include <a_mysql>
#include <timerfix>

/* Some Macro */
#define MAX_TREES (100)
#define LUMBERJACK_RENT_POS 290.4481, 1139.1969, 8.9228
#define LUMBERJACK_RENT_POS_CAR 293.5457, 1149.7740, 10.9878
#define LUMBERJACK_SELL_POS -544.7388, -189.3582, 78.3852
#define HOLDING(%0) \
	((newkeys & (%0)) == (%0))
#define PRESSED(%0) \
	(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define RELEASED(%0) \
	(((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))
#define DATABASE_ADDRESS 	"localhost" //Change this to your Database Address
#define DATABASE_USERNAME 	"root" // Change this to your database username
#define DATABASE_PASSWORD 	"" //Change this to your database password
#define DATABASE_NAME 		"manachan" // Change this to your database name

/* Variable and enum */
enum
{
	EDITING_TYPE_NONE,
	EDITING_TYPE_CREATE,
	EDITING_TYPE_EDIT
}

enum P_TREE_DATA
{
	P_EDITING_TYPE,
	P_EDITING_TREE,
	P_EDITING_OBJECT,
	//
	P_CUT,
	bool: P_HAS_WOOD
}
new g_player_tree[MAX_PLAYERS][P_TREE_DATA];

enum {OBJECT_INIT_TYPE_CREATE, OBJECT_INIT_TYPE_UPDATE}

enum E_TREE
{
	T_TIME,
	T_OBJECT,
	//
	Float: TX,
	Float: TY,
	Float: TZ,
	Float: TRX,
	Float: TRY,
	Float: TRZ,
	//
	bool: T_ON_CUT,
	bool: T_DOWN,
	Text3D:T_TEXT
}
new g_tree[MAX_TREES][E_TREE];
new Iterator: Trees<MAX_TREES>;
new Iterator: Vehicle<MAX_VEHICLES>;

//
new V_WOOD[MAX_VEHICLES];
new V_WOOD_ATTACH[MAX_VEHICLES];
//
new SADLER_STOCK;
new WOOD_STOCK;
//
new Text3D: WOOD_LABEL;
new Text3D: SADLER_LABEL;
new MySQL:ManaSQL;
new PlayerText:ProgBar[MAX_PLAYERS][6];
new ProgCut[MAX_PLAYERS];
new Text:NameChan[4];
new ProgTimer[MAX_PLAYERS];
new FaseCut[MAX_PLAYERS];

/* Public and function area */

stock CreateGlobalTD()
{
    NameChan[0] = TextDrawCreate(552.000000, 6.000000, "ld_bum:blkdot");
	TextDrawFont(NameChan[0], 4);
	TextDrawLetterSize(NameChan[0], 0.600000, 2.000000);
	TextDrawTextSize(NameChan[0], 49.500000, 52.000000);
	TextDrawSetOutline(NameChan[0], 1);
	TextDrawSetShadow(NameChan[0], 0);
	TextDrawAlignment(NameChan[0], 1);
	TextDrawColor(NameChan[0], 53042175);
	TextDrawBackgroundColor(NameChan[0], 255);
	TextDrawBoxColor(NameChan[0], 50);
	TextDrawUseBox(NameChan[0], 1);
	TextDrawSetProportional(NameChan[0], 1);
	TextDrawSetSelectable(NameChan[0], 0);

	NameChan[1] = TextDrawCreate(577.000000, 34.000000, "Manakuslagi");
	TextDrawFont(NameChan[1], 2);
	TextDrawLetterSize(NameChan[1], 0.158332, 1.599999);
	TextDrawTextSize(NameChan[1], 400.000000, 17.000000);
	TextDrawSetOutline(NameChan[1], 0);
	TextDrawSetShadow(NameChan[1], 0);
	TextDrawAlignment(NameChan[1], 2);
	TextDrawColor(NameChan[1], -1122561);
	TextDrawBackgroundColor(NameChan[1], 255);
	TextDrawBoxColor(NameChan[1], 50);
	TextDrawUseBox(NameChan[1], 0);
	TextDrawSetProportional(NameChan[1], 1);
	TextDrawSetSelectable(NameChan[1], 0);

	NameChan[2] = TextDrawCreate(578.000000, 8.000000, "M");
	TextDrawFont(NameChan[2], 3);
	TextDrawLetterSize(NameChan[2], 1.070832, 3.599998);
	TextDrawTextSize(NameChan[2], 400.000000, 17.000000);
	TextDrawSetOutline(NameChan[2], 0);
	TextDrawSetShadow(NameChan[2], 0);
	TextDrawAlignment(NameChan[2], 2);
	TextDrawColor(NameChan[2], -1122561);
	TextDrawBackgroundColor(NameChan[2], 255);
	TextDrawBoxColor(NameChan[2], 50);
	TextDrawUseBox(NameChan[2], 0);
	TextDrawSetProportional(NameChan[2], 1);
	TextDrawSetSelectable(NameChan[2], 0);

	NameChan[3] = TextDrawCreate(577.000000, 43.000000, "Channel");
	TextDrawFont(NameChan[3], 0);
	TextDrawLetterSize(NameChan[3], 0.279165, 1.049999);
	TextDrawTextSize(NameChan[3], 400.000000, 17.000000);
	TextDrawSetOutline(NameChan[3], 0);
	TextDrawSetShadow(NameChan[3], 0);
	TextDrawAlignment(NameChan[3], 2);
	TextDrawColor(NameChan[3], -1122561);
	TextDrawBackgroundColor(NameChan[3], 255);
	TextDrawBoxColor(NameChan[3], 50);
	TextDrawUseBox(NameChan[3], 0);
	TextDrawSetProportional(NameChan[3], 1);
	TextDrawSetSelectable(NameChan[3], 0);
	return 1;
}

stock CreatePlayerTD(playerid)
{
	ProgCut[playerid] = 0;
    ProgBar[playerid][0] = CreatePlayerTextDraw(playerid, 272.000000, 363.000000, "ld_bum:blkdot");
	PlayerTextDrawFont(playerid, ProgBar[playerid][0], 4);
	PlayerTextDrawLetterSize(playerid, ProgBar[playerid][0], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, ProgBar[playerid][0], 96.000000, 2.000000);
	PlayerTextDrawSetOutline(playerid, ProgBar[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, ProgBar[playerid][0], 0);
	PlayerTextDrawAlignment(playerid, ProgBar[playerid][0], 1);
	PlayerTextDrawColor(playerid, ProgBar[playerid][0], 53042175);
	PlayerTextDrawBackgroundColor(playerid, ProgBar[playerid][0], 255);
	PlayerTextDrawBoxColor(playerid, ProgBar[playerid][0], 50);
	PlayerTextDrawUseBox(playerid, ProgBar[playerid][0], 1);
	PlayerTextDrawSetProportional(playerid, ProgBar[playerid][0], 1);
	PlayerTextDrawSetSelectable(playerid, ProgBar[playerid][0], 0);

	ProgBar[playerid][1] = CreatePlayerTextDraw(playerid, 272.000000, 363.000000, "ld_bum:blkdot");
	PlayerTextDrawFont(playerid, ProgBar[playerid][1], 4);
	PlayerTextDrawLetterSize(playerid, ProgBar[playerid][1], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, ProgBar[playerid][1], 2.000000, 31.500000);
	PlayerTextDrawSetOutline(playerid, ProgBar[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, ProgBar[playerid][1], 0);
	PlayerTextDrawAlignment(playerid, ProgBar[playerid][1], 1);
	PlayerTextDrawColor(playerid, ProgBar[playerid][1], 53042175);
	PlayerTextDrawBackgroundColor(playerid, ProgBar[playerid][1], 255);
	PlayerTextDrawBoxColor(playerid, ProgBar[playerid][1], 50);
	PlayerTextDrawUseBox(playerid, ProgBar[playerid][1], 1);
	PlayerTextDrawSetProportional(playerid, ProgBar[playerid][1], 1);
	PlayerTextDrawSetSelectable(playerid, ProgBar[playerid][1], 0);

	ProgBar[playerid][2] = CreatePlayerTextDraw(playerid, 366.000000, 363.000000, "ld_bum:blkdot");
	PlayerTextDrawFont(playerid, ProgBar[playerid][2], 4);
	PlayerTextDrawLetterSize(playerid, ProgBar[playerid][2], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, ProgBar[playerid][2], 2.000000, 31.500000);
	PlayerTextDrawSetOutline(playerid, ProgBar[playerid][2], 1);
	PlayerTextDrawSetShadow(playerid, ProgBar[playerid][2], 0);
	PlayerTextDrawAlignment(playerid, ProgBar[playerid][2], 1);
	PlayerTextDrawColor(playerid, ProgBar[playerid][2], 53042175);
	PlayerTextDrawBackgroundColor(playerid, ProgBar[playerid][2], 255);
	PlayerTextDrawBoxColor(playerid, ProgBar[playerid][2], 50);
	PlayerTextDrawUseBox(playerid, ProgBar[playerid][2], 1);
	PlayerTextDrawSetProportional(playerid, ProgBar[playerid][2], 1);
	PlayerTextDrawSetSelectable(playerid, ProgBar[playerid][2], 0);

	ProgBar[playerid][3] = CreatePlayerTextDraw(playerid, 272.000000, 393.000000, "ld_bum:blkdot");
	PlayerTextDrawFont(playerid, ProgBar[playerid][3], 4);
	PlayerTextDrawLetterSize(playerid, ProgBar[playerid][3], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, ProgBar[playerid][3], 96.000000, 2.000000);
	PlayerTextDrawSetOutline(playerid, ProgBar[playerid][3], 1);
	PlayerTextDrawSetShadow(playerid, ProgBar[playerid][3], 0);
	PlayerTextDrawAlignment(playerid, ProgBar[playerid][3], 1);
	PlayerTextDrawColor(playerid, ProgBar[playerid][3], 53042175);
	PlayerTextDrawBackgroundColor(playerid, ProgBar[playerid][3], 255);
	PlayerTextDrawBoxColor(playerid, ProgBar[playerid][3], 50);
	PlayerTextDrawUseBox(playerid, ProgBar[playerid][3], 1);
	PlayerTextDrawSetProportional(playerid, ProgBar[playerid][3], 1);
	PlayerTextDrawSetSelectable(playerid, ProgBar[playerid][3], 0);

	ProgBar[playerid][4] = CreatePlayerTextDraw(playerid, 320.000000, 367.000000, "_");
	PlayerTextDrawFont(playerid, ProgBar[playerid][4], 1);
	PlayerTextDrawLetterSize(playerid, ProgBar[playerid][4], 0.600000, 2.600002);
	PlayerTextDrawTextSize(playerid, ProgBar[playerid][4], 301.000000, ProgCut[playerid] * 88.500000/100);
	PlayerTextDrawSetOutline(playerid, ProgBar[playerid][4], 1);
	PlayerTextDrawSetShadow(playerid, ProgBar[playerid][4], 0);
	PlayerTextDrawAlignment(playerid, ProgBar[playerid][4], 2);
	PlayerTextDrawColor(playerid, ProgBar[playerid][4], -1);
	PlayerTextDrawBackgroundColor(playerid, ProgBar[playerid][4], 255);
	PlayerTextDrawBoxColor(playerid, ProgBar[playerid][4], -1122561);
	PlayerTextDrawUseBox(playerid, ProgBar[playerid][4], 1);
	PlayerTextDrawSetProportional(playerid, ProgBar[playerid][4], 1);
	PlayerTextDrawSetSelectable(playerid, ProgBar[playerid][4], 0);

	ProgBar[playerid][5] = CreatePlayerTextDraw(playerid, 323.000000, 369.000000, "PROGRESS...");
	PlayerTextDrawFont(playerid, ProgBar[playerid][5], 2);
	PlayerTextDrawLetterSize(playerid, ProgBar[playerid][5], 0.283333, 2.000000);
	PlayerTextDrawTextSize(playerid, ProgBar[playerid][5], 377.000000, 17.000000);
	PlayerTextDrawSetOutline(playerid, ProgBar[playerid][5], 0);
	PlayerTextDrawSetShadow(playerid, ProgBar[playerid][5], 0);
	PlayerTextDrawAlignment(playerid, ProgBar[playerid][5], 2);
	PlayerTextDrawColor(playerid, ProgBar[playerid][5], 53042175);
	PlayerTextDrawBackgroundColor(playerid, ProgBar[playerid][5], 255);
	PlayerTextDrawBoxColor(playerid, ProgBar[playerid][5], 50);
	PlayerTextDrawUseBox(playerid, ProgBar[playerid][5], 0);
	PlayerTextDrawSetProportional(playerid, ProgBar[playerid][5], 1);
	PlayerTextDrawSetSelectable(playerid, ProgBar[playerid][5], 0);
	return 1;
}

Database_Connect()
{
	ManaSQL = mysql_connect(DATABASE_ADDRESS,DATABASE_USERNAME,DATABASE_PASSWORD,DATABASE_NAME);

	if(mysql_errno(ManaSQL) != 0){
	    print("[MySQL] - Connection Failed!");
	}
	else{
		print("[MySQL] - Connection Estabilished!");
	}
}

public OnFilterScriptInit()
{
   	print("\n");
	print("______________________________________________");
	print("[SA-MP] Lumberjack FilterScript Initialized");
	print("______________________________________________");
	
	Database_Connect();
	mysql_tquery(ManaSQL, "SELECT * FROM `trees`", "LoadTrees", "");
	mysql_tquery(ManaSQL, "SELECT * FROM `treesinit`", "GlobalStockInit", "");
	
	SetTimer("TreeUpdate", 60 * 1000, true);
	SetTimer("SecondUpdate", 1000, true);
	SetTimer("SadlerStock", 1800 * 1000, true);

	CreateGlobalTD();
	CreateDynamicPickup(1239, 23, LUMBERJACK_RENT_POS, -1);
	CreateDynamicPickup(1239, 23, LUMBERJACK_SELL_POS, -1);

	SADLER_LABEL = CreateDynamic3DTextLabel("{FF0000}Sadler Rental\n{FFFFFF}Rent a sadler for lumberjack using {FFFF00}/rentsadler\n{FFFFFF}Sadler Avaible: 0", -1, LUMBERJACK_RENT_POS, 7.5);
	WOOD_LABEL = CreateDynamic3DTextLabel("{FF0000}Lumberjack Center\n{FFFFFF}To sell your logs. type {FFFF00}/unloadlumber", -1, LUMBERJACK_SELL_POS, 10.0);

	return 1;
}

public OnFilterScriptExit()
{
    print("\n");
	print("______________________________________________");
	print("[SA-MP] Lumberjack FilterScript Exit");
	print("______________________________________________");
	return 1;
}

public OnPlayerConnect(playerid)
{
	CreatePlayerTD(playerid);
	for(new i = 0; i != 4; i++)
	{
		TextDrawShowForPlayer(playerid, NameChan[i]);
	}
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    new i = GetClosestTree(playerid, 3.0);
	new t_string[129];
	if(i != -1)
	{
	    if(g_tree[i][T_TIME] < 1)
		{
		 	if(g_tree[i][T_DOWN])
		    {
			    if(HOLDING(KEY_YES) && GetPlayerSpecialAction(playerid) != SPECIAL_ACTION_CARRY)
				{
					if(g_player_tree[playerid][P_CUT] < 100)
					{
						g_player_tree[playerid][P_CUT] += 10;
					    ApplyAnimation(playerid,"BOMBER","BOM_Plant",4.0,0,0,0, 1000,0);
					}
					else
					{
					    g_tree[i][T_DOWN] = false;
						g_tree[i][T_TIME] = 60;

						TreeObjectInit(i, OBJECT_INIT_TYPE_UPDATE);

						g_player_tree[playerid][P_CUT] = 0;
						g_player_tree[playerid][P_HAS_WOOD] = true;

						ClearAnimations(playerid);

						RemovePlayerAttachedObject(playerid, 6);
						SetPlayerAttachedObject(playerid, 6, 1463, 6, 0.0, 0.2, -0.04, -116.0, 2.0, 74.0);
						SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CARRY);
						ProgCut[playerid] = 0;
						SaveTrees(i);
						PlayerTextDrawTextSize(playerid, ProgBar[playerid][4], 301.000000, ProgCut[playerid] * 88.500000/100);
						
						new form[200];
						format(form, 200, "{FF0000}[TREES]\n{7348EB}[ID : %d]\n{FFFFFF}[STATUS : %s]\n{15D4ED}[TIME : {FFFFFF}%d]", i, GetTreeStatus(i), g_tree[i][T_TIME]);
				        UpdateDynamic3DTextLabelText(g_tree[i][T_TEXT], -1, form);

						SendClientMessage(playerid, -1, "{FFFF00}TREE: {FFFFFF}You've finished to take the pile of wood. Go back to your sadler and use {FFFF00}/loadlumber");
					}
				}
				else
				{
				    format(t_string, sizeof(t_string), "TREE ~b~%d~n~~w~DOWN~n~~w~HOLD AND PRESS ~y~Y", i);
           		    GameTextForPlayer(playerid, t_string, 1100, 4);
				}
			}
        }
	}
	return 1;
}

public OnPlayerEditDynamicObject(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
 	if(objectid == g_player_tree[playerid][P_EDITING_OBJECT])
	{
	    if(response == EDIT_RESPONSE_FINAL)
	    {
	        switch(g_player_tree[playerid][P_EDITING_TYPE])
	        {
	            case EDITING_TYPE_CREATE:
	            {
	                CreateTrees(x, y, z, rx, ry, rz);

	                DestroyDynamicObject(g_player_tree[playerid][P_EDITING_OBJECT]);

	                SendClientMessage(playerid, -1, "{FFFF00}TREE: {FFFFFF}You've finished to create a tree");
	                Iter_Add(Trees, Iter_Free(Trees));
	            }
	            case EDITING_TYPE_EDIT:
	            {
					new i = g_player_tree[playerid][P_EDITING_TREE];

					g_tree[i][TX] = x;
					g_tree[i][TY] = y;
					g_tree[i][TZ] = z;

					g_tree[i][TRX] = rx;
					g_tree[i][TRY] = ry;
					g_tree[i][TRZ] = rz;
	            }
	        }
	        g_player_tree[playerid][P_EDITING_OBJECT] = -1;
		}
		else if(response == EDIT_RESPONSE_CANCEL)
		{
		    switch(g_player_tree[playerid][P_EDITING_TYPE])
	        {
	            case EDITING_TYPE_CREATE:
	            {
				    g_player_tree[playerid][P_EDITING_TYPE] = -1;
				    g_player_tree[playerid][P_EDITING_TREE] = -1;
				    g_player_tree[playerid][P_EDITING_OBJECT] = -1;
					DestroyDynamicObject(g_player_tree[playerid][P_EDITING_OBJECT]);
				}
				case EDITING_TYPE_EDIT: SendClientMessage(playerid, -1, "{FFFF00}TREE: {FFFFFF}Tree editing cancelled");
			}
		}
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case 1325:
	    {
			if(response)
			{
			    if(GetPlayerMoney(playerid) >= 2000)
			    {
			        new tmpveh = CreateVehicle(543, LUMBERJACK_RENT_POS_CAR, 90.0, -1, -1, 3600 * 1000);

			        GivePlayerMoney(playerid, -2000);
			        SendClientMessage(playerid, -1, "{FFFF00}RENTAL: {FFFFFF}You've succesfully rent a sadler for 1 hour");

			        SADLER_STOCK--;
					Iter_Add(Vehicle, 1);
			        PutPlayerInVehicle(playerid, tmpveh, 0);
			        SetTimerEx("DestroyTempVeh", 3600 * 1000, false, "i", tmpveh);
			    }
			    else SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}You need at least {00FF00}$2000 {FFFFFF}To rent a sadler");
			}
		}
		case 1326:
		{
		    if(response)
		    {
		        SendClientMessage(playerid, -1, "{FFFF00}GPS: {FFFFFF}Tree Location added on your map radar. Disable it by using {FFFF00}/discp");
		        SetPlayerMapIcon(playerid, 55, g_tree[listitem][TX], g_tree[listitem][TY], g_tree[listitem][TZ], 62, -1, MAPICON_GLOBAL);
		    }
		}
	}
	return 1;
}

CMD:cuttree(playerid, params[])
{
	new i = GetClosestTree(playerid, 2.5);

	if(i == -1) return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}There're not any trees nearby");

	if(g_tree[i][T_ON_CUT]) return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}Someone is trying to cut down this tree already");

	if(g_tree[i][T_DOWN]) return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}This tree is already cut down by someone. Press {FFFF00}Y {FFFFFF}To take");

	if(g_tree[i][T_TIME] > 0) return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}This tree isn't ready to cut down right now");

    if(GetPlayerWeapon(playerid) != WEAPON_CHAINSAW) return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}You must equip an chainshaw");
    
    ProgCut[playerid] = 0;
	ProgTimer[playerid] = SetTimerEx("OnCutTree", 1000, true, "i", playerid);

	for(new o = 0; o != 6; o++)
	{
		PlayerTextDrawShow(playerid, ProgBar[playerid][o]);
	}
	
    SetPlayerArmedWeapon(playerid, WEAPON_CHAINSAW);
	ApplyAnimation(playerid, "CHAINSAW", "WEAPON_csaw", 4.1, 1, 0, 0, 0, 20000, 0);

	TogglePlayerControllable(playerid, false);

	g_tree[i][T_ON_CUT] = true;

	SendClientMessage(playerid, -1, "{FFFF00}TREE: {FFFFFF}You've started to cut a tree");
	return 1;
}

CMD:chainshaw(playerid, params[])
{
	GivePlayerWeapon(playerid, 9, 1);
	GivePlayerMoney(playerid, 2000);
	return 1;
}

CMD:lumhelp(playerid, params[])
{
	SendClientMessage(playerid, -1, "[ADMIN] {FFFF00}/createtree /edittree [treeid]");
	SendClientMessage(playerid, -1, "[PLAYER] {FFFF00}/cuttree /rentsadler /findtree /loadlumber /unloadlumber /droplumber /lumgps");
	return 1;
}

CMD:lumgps(playerid, params[])
{
	SetPlayerMapIcon(playerid, 56, LUMBERJACK_SELL_POS, 11, -1, MAPICON_GLOBAL);

	SendClientMessage(playerid, -1, "{FFFF00}GPS: {FFFFFF}Your GPS is now directed to lumberjack senter (wood sell). You can disable it using {FFFF00}/discp");
	return 1;
}

CMD:edittree(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
	    return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}Only RCON Admins authorized to use this command");

	extract params -> new i; else return SendClientMessage(playerid, -1, "{FFFF00}SYNTAX: {FFFFFF}/edittree [treeid]");

	if(g_tree[i][T_OBJECT] == -1 || !Iter_Contains(Trees, i))
	    return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}Invalid Tree ID");

	g_player_tree[i][P_EDITING_TYPE] = EDITING_TYPE_EDIT;
	g_player_tree[i][P_EDITING_TREE] = i;
	g_player_tree[i][P_EDITING_OBJECT] = g_tree[i][T_OBJECT];

	EditDynamicObject(playerid, g_tree[i][T_OBJECT]);

	return 1;
}

CMD:createtree(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
	    return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}Only RCON Admins authorized to use this command");

	new Float: x, Float: y, Float: z;

	GetPlayerPos(playerid, x, y, z);

	g_player_tree[playerid][P_EDITING_TYPE] = EDITING_TYPE_CREATE;
	g_player_tree[playerid][P_EDITING_OBJECT] = CreateDynamicObject(618, x + 3.0, y + 3.0, z, 0, 0, 0);

	SendClientMessage(playerid, -1, "{FFFF00}TREE: {FFFFFF}You've started to creating a tree");
	EditDynamicObject(playerid, g_player_tree[playerid][P_EDITING_OBJECT]);
	return 1;
}

CMD:unloadlumber(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);

	if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER || GetVehicleModel(vehicleid) != 543)
	    return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}Your must be driver in a sadler to use this command");

	if(!IsPlayerInRangeOfPoint(playerid, 5.0, LUMBERJACK_SELL_POS))
	    return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}You must at lumberjack center to use this command. type {FFFF00}/lumgps");

    if(V_WOOD[vehicleid] < 1) return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}Your sadler didn't have any wood to sell");

    if(V_WOOD[vehicleid] + WOOD_STOCK >= 1000) return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}You can't sell more wood anymore due to maximum capacity of storage");

    new price;
    new string[129];

    switch(WOOD_STOCK)
    {
        case 0..300: price = 500;
        case 301..800: price = 300;
        case 801..900: price = 250;
        default: price = 100;
    }

	GivePlayerMoney(playerid, V_WOOD[vehicleid] * price);

	format(string, sizeof(string), "{FFFF00}LUMBER: {FFFFFF}You've sold all of your woods and get paid for {00FF00}$%d", V_WOOD[vehicleid] * 500);
	SendClientMessage(playerid, -1, string);

	WOOD_STOCK += V_WOOD[vehicleid];

    V_WOOD[vehicleid] = 0;
	return 1;
}

CMD:loadlumber(playerid, params[])
{
	new vehicleid = GetClosestVehicle(playerid, 4.0);

	if(!g_player_tree[playerid][P_HAS_WOOD] || GetPlayerSpecialAction(playerid) != SPECIAL_ACTION_CARRY)
	    return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}You didn't have any wood to load");

	if(vehicleid == INVALID_VEHICLE_ID || GetVehicleModel(vehicleid) != 543) return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}There're not any vehicle nearby");

	if(GetVehicleModel(vehicleid) != 543) return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}This vehicle must be sadler");

	if(V_WOOD[vehicleid] >= 5) return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}This vehicle unable to load more woods {FFFF00}(Max: 5)");

	V_WOOD[vehicleid] += 1;

	g_player_tree[playerid][P_HAS_WOOD] = false;

	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
	RemovePlayerAttachedObject(playerid, 6);

	new string[129];

	format(string, sizeof(string), "{FFFF00}LUMBER: {FFFFFF}Loaded a wood to nearest vehicle. Total wood: {FFFF00}%d {FFFFFF}Woods", V_WOOD[vehicleid]);
	SendClientMessage(playerid, -1, string);

	return 1;
}

CMD:droplumber(playerid, params[])
{
	if(!g_player_tree[playerid][P_HAS_WOOD] || GetPlayerSpecialAction(playerid) != SPECIAL_ACTION_CARRY)
	    return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}You didn't have any wood to throw");

	g_player_tree[playerid][P_HAS_WOOD] = false;

	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
	RemovePlayerAttachedObject(playerid, 6);

	SendClientMessage(playerid, -1, "{FFFF00}LUMBER: {FFFFFF}You've threw your wood for mile away");
	return 1;
}

CMD:findtree(playerid, params[])
{
    new Float: tempdist;

    new
        temp_string[50],
		dialog[15 * sizeof(temp_string)];


	foreach(new i : Trees)
	{
	    tempdist = GetPlayerDistanceFromPoint(playerid, g_tree[i][TX], g_tree[i][TY], g_tree[i][TZ]);
		if(tempdist > 250.0) continue;

		if(i != -1)
		{
		    format(
			temp_string, sizeof(temp_string),
		    "Tree %d\t%s\t%.0f Mil.\n",
			i + 1, GetTreeStatus(i), GetPlayerDistanceFromPoint(playerid, g_tree[i][TX], g_tree[i][TY], g_tree[i][TZ])
			);

			strcat(dialog, temp_string);
		}
	}

	ShowPlayerDialog(playerid, 1326, DIALOG_STYLE_TABLIST, "Tree List", dialog, "Trace", "Cancel");
	return 1;
}

CMD:gotorent(playerid)
{
	SetPlayerPos(playerid, LUMBERJACK_RENT_POS);
	return 1;
}

CMD:rentsadler(playerid, params[])
{
	if(!IsPlayerInRangeOfPoint(playerid, 3.0, LUMBERJACK_RENT_POS))
	    return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}You must be at sadler rental to use this command");

    if(SADLER_STOCK < 1)
        return SendClientMessage(playerid, -1, "{FF0000}ERROR: {FFFFFF}This rental has been run out of sadler to rent. Comeback later...");

	ShowPlayerDialog(playerid, 1325, DIALOG_STYLE_MSGBOX, "Sadler Rental", "Are you sure to rent a sadler for 1 hour?\nIt will cost you {00FF00}$2000", "Rent", "Close");

	return 1;
}

stock GetTreeStatus(i)
{
	new status[24];

	switch(g_tree[i][T_TIME])
	{
	    case 1..60: status = "{FF0000}Not Ready";
	    case 0: status = "{00FF00}Ready";
	}

	return status;
}

stock CreateTrees(Float: x, Float: y, Float: z, Float: rx, Float: ry, Float: rz)
{
	new tid = Iter_Free(Trees), query[256];

	if(tid != -1)
	{
	    g_tree[tid][TX] = x, g_tree[tid][TY] = y, g_tree[tid][TZ] = z;
	   	g_tree[tid][TRX] = rx, g_tree[tid][TRY] = ry, g_tree[tid][TRZ] = rz;
		g_tree[tid][T_TIME] = 0;
		TreeObjectInit(tid, OBJECT_INIT_TYPE_CREATE);
		Iter_Add(Trees, Iter_Free(Trees));
		mysql_format(ManaSQL, query, sizeof(query), "INSERT INTO trees SET id='%d', TX='%f', TY='%f', TZ='%f', TRX='%f', TRY='%f', TRZ='%f'", tid, g_tree[tid][TX], g_tree[tid][TY], g_tree[tid][TZ], g_tree[tid][TRX], g_tree[tid][TRY], g_tree[tid][TRZ]);
		mysql_tquery(ManaSQL, query, "OnTreeCreated", "d", tid);
		CreateDynamicCP(g_tree[tid][TX], g_tree[tid][TY], g_tree[tid][TZ], 2.5, -1, -1, _, 3.0);
	}
	else print("[ERROR] Couldn't to create more tree due to max trees reached");
	return 1;
}

forward OnTreeCreated(tid);
public OnTreeCreated(tid)
{
	SaveTrees(tid);
	return 1;
}

forward LoadTrees();
public LoadTrees()
{
    new tid;

	new rows = cache_num_rows();
 	if(rows)
  	{
		for(new i; i < rows; i++)
		{
			cache_get_value_name_int(i, "id", tid);
			
			cache_get_value_name_float(i, "TX", g_tree[tid][TX]);
			cache_get_value_name_float(i, "TY", g_tree[tid][TY]);
			cache_get_value_name_float(i, "TZ", g_tree[tid][TZ]);
			
			cache_get_value_name_float(i, "TRX", g_tree[tid][TRX]);
			cache_get_value_name_float(i, "TRY", g_tree[tid][TRY]);
			cache_get_value_name_float(i, "TRZ", g_tree[tid][TRZ]);
            
            cache_get_value_name_int(i, "time", g_tree[tid][T_TIME]);

	    	CreateDynamicCP(g_tree[tid][TX], g_tree[tid][TY], g_tree[tid][TZ], 2.5, -1, -1, _, 3.0);
	    	new form[120];
	    	format(form, 120, "{FF0000}[TREES]\n{7348EB}[ID : %d]\n{FFFFFF}[STATUS : %s]\n{15D4ED}[TIME : {FFFFFF}%d{15D4ED}]", tid, GetTreeStatus(tid), g_tree[tid][T_TIME]);
            g_tree[tid][T_TEXT] = CreateDynamic3DTextLabel(form, -1, g_tree[tid][TX], g_tree[tid][TY], g_tree[tid][TZ], 3.0);
			TreeObjectInit(tid, OBJECT_INIT_TYPE_CREATE);
			Iter_Add(Trees, Iter_Free(Trees));
		}
	}
	print("\n");
	print("______________________________________________");
	print("[SA-MP] Lumberjack Trees Initialized");
	print("______________________________________________");
	return 1;
}

forward GlobalStockInit();
public GlobalStockInit()
{
    new rows = cache_num_rows();
 	if(rows)
  	{
		for(new i; i < rows; i++)
		{
		    cache_get_value_name_int(i, "SADLER_STOCK", SADLER_STOCK);
            cache_get_value_name_int(i, "WOOD_STOCK", WOOD_STOCK);
		}
	}
	print("\n");
	print("______________________________________________");
	print("[SA-MP] Lumberjack Global Stock Initialized");
	print("______________________________________________");
	return 1;
}

forward SaveTrees(tid);
public SaveTrees(tid)
{
	new cQuery[512];
	format(cQuery, sizeof(cQuery), "UPDATE trees SET TX='%f', TY='%f', TZ='%f', TRX='%f', TRY='%f', TRZ='%f', time = '%d' WHERE id='%d'",
	g_tree[tid][TX],
	g_tree[tid][TY],
	g_tree[tid][TZ],
	g_tree[tid][TRX],
	g_tree[tid][TRY],
	g_tree[tid][TRZ],
	g_tree[tid][T_TIME],
	tid
	);
	return mysql_tquery(ManaSQL, cQuery);
}

forward SaveInit();
public SaveInit()
{
	new cQuery[512];
	format(cQuery, sizeof(cQuery), "UPDATE treesinit SET SADLER_STOCK = '%d', WOOD_STOCK = '%d' WHERE id='1'",
	SADLER_STOCK,
	WOOD_STOCK
	);
	return mysql_tquery(ManaSQL, cQuery);
}
stock TreeObjectInit(i, type)
{
	switch(type)
	{
	    case OBJECT_INIT_TYPE_CREATE:
	    {
	        switch(g_tree[i][T_TIME])
	        {
	            case 40..60: g_tree[i][T_OBJECT] = CreateDynamicObject(618, g_tree[i][TX], g_tree[i][TY], g_tree[i][TZ] - 10.0, g_tree[i][TRX], g_tree[i][TRY], g_tree[i][TRZ]);
	            case 20..39: g_tree[i][T_OBJECT] = CreateDynamicObject(618, g_tree[i][TX], g_tree[i][TY] - 7.5, g_tree[i][TZ], g_tree[i][TRX], g_tree[i][TRY], g_tree[i][TRZ]);
	            case 5..19: g_tree[i][T_OBJECT] = CreateDynamicObject(618, g_tree[i][TX], g_tree[i][TY] - 5.0, g_tree[i][TZ], g_tree[i][TRX], g_tree[i][TRY], g_tree[i][TRZ]);
				default: g_tree[i][T_OBJECT] = CreateDynamicObject(618, g_tree[i][TX], g_tree[i][TY], g_tree[i][TZ], g_tree[i][TRX], g_tree[i][TRY], g_tree[i][TRZ]);
			}
		}
		case OBJECT_INIT_TYPE_UPDATE:
	    {
	        switch(g_tree[i][T_TIME])
	        {
	           case 40..60: SetDynamicObjectPos(g_tree[i][T_OBJECT], g_tree[i][TX], g_tree[i][TY], g_tree[i][TZ] - 10.0);
	           case 20..39: SetDynamicObjectPos(g_tree[i][T_OBJECT], g_tree[i][TX], g_tree[i][TY], g_tree[i][TZ] - 7.5);
	           case 5..19: SetDynamicObjectPos(g_tree[i][T_OBJECT], g_tree[i][TX], g_tree[i][TY], g_tree[i][TZ] - 5.0);
	           default: SetDynamicObjectPos(g_tree[i][T_OBJECT], g_tree[i][TX], g_tree[i][TY], g_tree[i][TZ]);
			}
		}
	}
	return 1;
}

stock Float: SetPlayerFacingObject(playerid, objectid)
{
    new Float:pX, Float:pY, Float:pZ, Float:X, Float:Y, Float:Z,Float:ang, Float: result;
    GetDynamicObjectPos(objectid, X, Y, Z),GetPlayerPos(playerid, pX, pY, pZ);
    if( Y > pY ) ang = (-acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 90.0);
    else if( Y < pY && X < pX ) ang = (acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 450.0);
    else if( Y < pY ) ang = (acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 90.0);
    if(X > pX) ang = (floatabs(floatabs(ang) + 180.0));
    else ang = (floatabs(ang) - 180.0);
	return SetPlayerFacingAngle(playerid, ang + 270.0);
}

stock GetClosestTree(playerid, Float: range = 2.5)
{
	new id = -1, Float: dist = range, Float: tempdist;
	foreach(new i : Trees)
	{
	    tempdist = GetPlayerDistanceFromPoint(playerid, g_tree[i][TX], g_tree[i][TY], g_tree[i][TZ]);
		if(tempdist > range) continue;
		if(tempdist <= dist)
		{
			dist = tempdist;
			id = i;
			break;
		}
	}

	return id;
}

stock GetClosestVehicle(playerid, Float: range = 3.0)
{
	new id = -1, Float: dist = range, Float: tempdist, Float: x, Float: y, Float: z;
	for(new i; i < MAX_VEHICLES; ++i)
	{
	    GetVehiclePos(i, x, y, z);
	    tempdist = GetPlayerDistanceFromPoint(playerid, x, y, z);
		if(tempdist > range) continue;
		if(tempdist <= dist)
		{
			dist = tempdist;
			id = i;
			break;
		}
	}

	return id;
}

//

forward TreeUpdate();
public TreeUpdate()
{
	foreach(new i : Trees)
	{
	    if(g_tree[i][T_TIME] > 0)
	    {
	        g_tree[i][T_TIME]--;

			TreeObjectInit(i, OBJECT_INIT_TYPE_UPDATE);
	    }
	    new form[120];
		format(form, 120, "{FF0000}[TREES]\n{7348EB}[ID : %d]\n{FFFFFF}[STATUS : %s]\n{15D4ED}[TIME : {FFFFFF}%d{15D4ED}]", i, GetTreeStatus(i), g_tree[i][T_TIME]);
        UpdateDynamic3DTextLabelText(g_tree[i][T_TEXT], -1, form);
	    SaveTrees(i);
	}

//	SaveAllTrees();
	return 1;
}

forward SecondUpdate();
public SecondUpdate()
{
	foreach(new vehicleid : Vehicle)
	{
	    if(GetVehicleModel(vehicleid) == 543)
	    {
		    if(V_WOOD[vehicleid] > 0)
		    {
	            if(V_WOOD_ATTACH[vehicleid] == -1)
	            {
	                V_WOOD_ATTACH[vehicleid] = CreateDynamicObject(1463,0.0,0.0,-1000.0,0.0,0.0,0.0,-1,-1,-1,300.0,300.0);
	  			    AttachDynamicObjectToVehicle(V_WOOD_ATTACH[vehicleid], vehicleid, 0.054, -1.539, 0.139, 0.000, 0.000, 92.000);
	  			}
	  		}
	  		else
	  		{
	            if(V_WOOD_ATTACH[vehicleid] != -1)
	            {
	                DestroyDynamicObject(V_WOOD_ATTACH[vehicleid]);
	                V_WOOD_ATTACH[vehicleid] = -1;
	  			}
	  		}
	  	}
	}

    if(SADLER_STOCK > 5) SADLER_STOCK = 5;
	if(WOOD_STOCK > 1000) SADLER_STOCK = 1000;
	
	SaveInit();
	new l_string[229];
	format(l_string, sizeof(l_string), "{FF0000}Sadler Rental\n{FFFFFF}Rent a sadler for lumberjack using {FFFF00}/rentsadler\n{FFFFFF}Sadler Avaible: %d", SADLER_STOCK);
	UpdateDynamic3DTextLabelText(SADLER_LABEL, -1, l_string);

	format(l_string, sizeof(l_string), "{FF0000}Lumberjack Center\n{FFFFFF}To sell your logs. type {FFFF00}/unloadlumber\n{FFFFFF}Current Stock: {FFFF00}%d/1000 Logs", WOOD_STOCK);
	UpdateDynamic3DTextLabelText(WOOD_LABEL, -1, l_string);

	foreach(new playerid : Player)
	{
		new i = GetClosestTree(playerid);

		if(i == -1) g_player_tree[playerid][P_CUT] = 0;
	}
	return 1;
}

forward AddProgCut(playerid);
public AddProgCut(playerid)
{
    ProgCut[playerid] += 1;
    new Float:progress = ProgCut[playerid] * 88.5/100;
    PlayerTextDrawTextSize(playerid, ProgBar[playerid][4], 301.0, progress);
    PlayerTextDrawShow(playerid, ProgBar[playerid][4]);
    return 1;
}

forward OnCutTree(playerid);
public OnCutTree(playerid)
{
	new i = GetClosestTree(playerid);

	if(ProgCut[playerid] < 100)
	{
	    if(!IsValidTimer(FaseCut[playerid]))
	    {
	    	FaseCut[playerid] = SetTimerEx("AddProgCut", 200, true, "i", playerid);
		}
	}
	else if(ProgCut[playerid] >= 100)
	{
	    for(new o = 0; o != 6; o++)
		{
			PlayerTextDrawHide(playerid, ProgBar[playerid][o]);
		}
	    g_tree[i][T_ON_CUT] = false;
		g_tree[i][T_DOWN] = true;

        KillTimer(ProgTimer[playerid]);
        KillTimer(FaseCut[playerid]);
		MoveDynamicObject(g_tree[i][T_OBJECT], g_tree[i][TX], g_tree[i][TY], g_tree[i][TZ], 10.0, g_tree[i][TRX] + 90.0, g_tree[i][TRY], g_tree[i][TRZ]);
		ClearAnimations(playerid);

		TogglePlayerControllable(playerid, true);

		SendClientMessage(playerid, -1, "{FFFF00}TREE: {FFFFFF}You've finished cut down a tree. press {FFFF00}Y {FFFFFF}multiple times To cut the tree into pieces");
	}
	return 1;
}

forward SadlerStock();
public SadlerStock(){
	SADLER_STOCK++;
	return 1;
}

forward DestroyTempVeh(vehicleid);
public DestroyTempVeh(vehicleid){
	DestroyVehicle(vehicleid);
	SADLER_STOCK++;
	return 1;
}
