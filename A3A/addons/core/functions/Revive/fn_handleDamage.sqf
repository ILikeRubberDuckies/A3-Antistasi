// HandleDamage event handler for rebels and PvPers

params ["_unit","_part","_damage","_injurer","_projectile","_hitIndex","_instigator","_hitPoint"];

// Functionality unrelated to Antistasi revive
// Helmet popping: use _hitpoint rather than _part to work around ACE calling its fake hitpoint "head"
if (_damage >= 1 && {_hitPoint == "hithead"}) then
{
    diag_log "a";
    if (random 100 < helmetLossChance) then
    {
        diag_log "b";
        removeHeadgear _unit;
    };
};

if (_part == "" && _damage > 0.1) then
{
    diag_log "c";
    // this will not work the same with ACE, as damage isn't accumulated
    if (!isPlayer (leader group _unit) && dam < 1.0) then
    {
        diag_log "d";
        //if (_damage > 0.6) then {[_unit,_unit,_injurer] spawn A3A_fnc_chargeWithSmoke};
        if (_damage > 0.6) then {[_unit,_injurer] spawn A3A_fnc_unitGetToCover};
    };

    // Contact report generation for rebels
    if (side group _injurer == Occupants or side group _injurer == Invaders) then
    {
        diag_log "e";
        // Check if unit is part of a rebel garrison
        private _marker = _unit getVariable ["markerX",""];
        if (_marker != "" && {sidesX getVariable [_marker,sideUnknown] == teamPlayer}) then
        {
            diag_log "f";
            // Limit last attack var changes and task updates to once per 30 seconds
            private _lastAttackTime = garrison getVariable [_marker + "_lastAttack", -30];
            if (_lastAttackTime + 30 < serverTime) then {
                garrison setVariable [_marker + "_lastAttack", serverTime, true];
                [_marker, side group _injurer, side group _unit] remoteExec ["A3A_fnc_underAttack", 2];
            };
        };
    };
};


// Let ACE medical handle the rest (inc return value) if it's running
if (A3A_hasACEMedical) exitWith {};


private _makeUnconscious =
{
    diag_log "g";
    params ["_unit", "_injurer", "_fatalWound"];
    //diag_log format ["Friendly unit %1 downed, fatal %2", _unit, _fatalWound];

    _unit setVariable ["incapacitated",true,true];
    _unit setVariable ["helpFailed", 0];
    _unit setUnconscious true;
    _unit setVariable ["incapImmuneTime", time + 0.2];
    _unit setVariable ["overallDamage", 0];
    if (isPlayer _unit) then { _unit allowDamage false;diag_log "h"};

    if (vehicle _unit != _unit) then { moveOut _unit };

    private _fromside = if (!isNull _injurer) then {side group _injurer} else {sideUnknown};
    [_unit, _fromside, _fatalWound] spawn A3A_fnc_unconscious;
};

//diag_log format ["%1 damage on part %2, hitpoint %3", _damage, _part, _hitpoint];

if (_part == "") then
{
    diag_log "i";
    if (_damage >= 1) then
    {
        diag_log "j";
        if (side _injurer == civilian) exitWith 
        {
            diag_log "k";
            // apparently civilians are non-lethal
            _damage = 0.9;
        };

        if !(_unit getVariable ["incapacitated",false]) exitWith
        {
            diag_log "l";
            //diag_log format ["Friendly %1 downed by %2 general damage", _unit, _damage];
            [_unit, _injurer, _damage >= 2] call _makeUnconscious;
            _damage = 0.9;
        };

        // Don't double-tap with one projectile
        if (time < _unit getVariable "incapImmuneTime") exitWith {_damage = 0.9;diag_log "m";};

        // already unconscious, check whether we're pushed into death
        _overall = (_unit getVariable ["overallDamage",0]) + (_damage - 0.9);

        //diag_log format ["Downed friendly %1 accumulated %2 damage from %3", _unit, _overall, _damage];

        if (_overall > 1) exitWith
        {
            diag_log "n";
            _unit setDamage 1;
            // Don't remove for players because it's transferred on respawn
            if (!isPlayer _unit) then { _unit removeAllEventHandlers "HandleDamage" };
        };

        _unit setVariable ["overallDamage",_overall];
        _damage = 0.9;
    }
    else
    {
        diag_log "o";
        if (_damage > 0.25) then
        {
            diag_log "p";
            if (_unit getVariable ["helping",false]) then
            {
                diag_log "q";
                _unit setVariable ["cancelRevive",true];
            };
            if (isPlayer (leader group _unit)) then
            {
                diag_log "r";
                if (autoheal) then
                {
                    diag_log "s";
                    if (!isNull (_unit getVariable ["helped",objNull])) exitWith {};
                    [_unit] call A3A_fnc_askHelp;
                };
            };
        };
    };
}
else
{
    diag_log "t";
    if ("spine" in _part and { !(uniform _unit in A3A_strongUniformsHM) } ) then {
        private _adj = A3A_vestDamageAdj getOrDefaultCall [_part + vest _unit, A3A_fnc_calcVestDamageAdj, true];
        //diag_log format ["Armor adjust: %1 part, %2 damage, %3 oldDamage, %4 adj", _part, _damage, _unit getHit _part, _adj];
        private _oldDmg = _unit getHit _part;
        _damage = _oldDmg + _adj * (_damage - _oldDmg);
    };

    if (_damage >= 1 && { !(_hitpoint in ["hitarms","hithands","hitlegs"]) }) then
    {
        diag_log "x";
        if !(_unit getVariable ["incapacitated",false]) then {
            diag_log "y";
            //diag_log format ["Friendly %1 downed by %2 hit on part %3, hitpoint %4", _unit, _damage, _part, _hitpoint];
            [_unit, _injurer, true] call _makeUnconscious;
        };
        _damage = 0.9;
    };
};

diag_log _damage;
_damage
