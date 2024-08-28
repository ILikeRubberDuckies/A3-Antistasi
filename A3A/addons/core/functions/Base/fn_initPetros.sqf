#include "..\..\script_component.hpp"
FIX_LINE_NUMBERS()
Info("initPetros started");
scriptName "fn_initPetros";

petros setSkill 1;
petros setVariable ["respawning",false];
petros allowDamage false;

removeHeadgear petros;
removeGoggles petros;
private _vest = selectRandomWeighted (A3A_rebelGear get "ArmoredVests");
if (_vest == "") then { _vest = selectRandomWeighted (A3A_rebelGear get "CivilianVests") };
petros addVest _vest;
[petros, "Rifles"] call A3A_fnc_randomRifle;
petros selectWeapon (primaryWeapon petros);

if (petros == leader group petros) then {
	group petros setGroupIdGlobal ["Petros","GroupColor4"];
	petros disableAI "MOVE";
	petros disableAI "AUTOTARGET";
	petros setBehaviour "SAFE";
};

// Install both moving and static actions
[petros,"petros"] remoteExec ["A3A_fnc_flagaction", 0, petros];

[petros,true] call A3A_fnc_punishment_FF_addEH;

petros addEventHandler
[
    "HandleDamage",
    {
    diag_log format["Petros received damage:%1",_this];

    private _e = [_this#0,_this#1,_this#2,_this#3,_this#4,_this#5,_this#6,_this#7] call A3A_fnc_handleDamage;
    _e;

    _part = _this select 1;
    _damage = _this select 2;
    _injurer = _this select 3;
    //_injurer = guy;

    _victim = _this select 0;
    _instigator = _this select 6;
    if (isPlayer _injurer) then
    {
        _damage = (_this select 0) getHitPointDamage (_this select 7);
    };
    if ((isNull _injurer) or (_injurer == petros)) then {_damage = 0};
    if (_part == "") then
    {
        diag_log "part = ''";
        if (_damage > 1) then
        {
            diag_log "damage > 1";
            if (!(petros getVariable ["incapacitated",false])) then
            {
                diag_log "if";
                petros setVariable ["incapacitated",true,true];
                _damage = 0.9;
                if (!isNull _injurer) then {[petros,side _injurer,_damage>=2] spawn A3A_fnc_unconscious} else {[petros,sideUnknown,false] spawn A3A_fnc_unconscious};
            }
            else
            {
                diag_log "else";
                _overall = (petros getVariable ["overallDamage",0]) + (_damage - 1);
                if (_overall > 1) then
                {
                    petros removeAllEventHandlers "HandleDamage";
                }
                else
                {
                    petros setVariable ["overallDamage",_overall];
                    _damage = 0.9;
                };
            };
        };
    };
    //diag_log format["damage: %1",_damage];
    _damage;
    }
];

petros addMPEventHandler ["mpkilled",
{
    removeAllActions petros;
    if (!isServer) exitWith {};

    // _killer = _this select 1;
    // if ((side _killer == Invaders) or (side _killer == Occupants) and !(isPlayer _killer) and !(isNull _killer)) then
    // {
    //     garrison setVariable ["Synd_HQ", [], true];
    //     _hr = server getVariable "hr";
    //     _res = server getVariable "resourcesFIA";
    //     [-1*(round(_hr*0.9)), -1*(round(_res*0.9))] spawn A3A_fnc_resourcesFIA;
    //     [] spawn A3A_fnc_petrosDeathMonitor;
    // }
    // else
    // {
        [] call A3A_fnc_createPetros;
    // };
}];
[] spawn {sleep 120; petros allowDamage true;};

Info("initPetros completed");
