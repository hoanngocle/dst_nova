local levelfuncs = {}

function levelfuncs.getlevel(self,level) self.inst.currentlevel:set(level) end
function levelfuncs.getlevelxp(self,levelxp) self.inst.currentlevelxp:set(levelxp) end
function levelfuncs.getoverallxp(self,overallxp) self.inst.currentoverallxp:set(overallxp) end
function levelfuncs.getattributepoints(self,attributepoints) self.inst.currentattributepoints:set(attributepoints) end

function levelfuncs.getpetlevel(self,petlevel) self.inst.currentpetlevel:set(petlevel) end
function levelfuncs.getpetlevelxp(self,petlevelxp) self.inst.currentpetlevelxp:set(petlevelxp) end
function levelfuncs.getpetoverallxp(self,petoverallxp) self.inst.currentpetoverallxp:set(petoverallxp) end
function levelfuncs.getpetattributepoints(self,petattributepoints) self.inst.currentpetattributepoints:set(petattributepoints) end
function levelfuncs.getpetcanevolve(self,petcanevolve) self.inst.currentpetcanevolve:set(petcanevolve) end

function levelfuncs.currenthungerlevel(self,hungerlevelamount) self.inst.currenthungerlevel:set(hungerlevelamount) end
function levelfuncs.currentsanitylevel(self,sanitylevelamount) self.inst.currentsanitylevel:set(sanitylevelamount) end
function levelfuncs.currenthealthlevel(self,healthlevelamount) self.inst.currenthealthlevel:set(healthlevelamount) end
function levelfuncs.currentspeedlevel(self,speedlevelamount) self.inst.currentspeedlevel:set(speedlevelamount) end
function levelfuncs.currentabsorblevel(self,absorblevelamount) self.inst.currentabsorblevel:set(absorblevelamount) end
function levelfuncs.currentdamagelevel(self,damagelevelamount) self.inst.currentdamagelevel:set(damagelevelamount) end

function levelfuncs.currenthungerlevelcost(self,hungerlevelcost) self.inst.currenthungerlevelcost:set(hungerlevelcost) end
function levelfuncs.currentsanitylevelcost(self,sanitylevelcost) self.inst.currentsanitylevelcost:set(sanitylevelcost) end
function levelfuncs.currenthealthlevelcost(self,healthlevelcost) self.inst.currenthealthlevelcost:set(healthlevelcost) end
function levelfuncs.currentspeedlevelcost(self,speedlevelcost) self.inst.currentspeedlevelcost:set(speedlevelcost) end
function levelfuncs.currentabsorblevelcost(self,absorblevelcost) self.inst.currentabsorblevelcost:set(absorblevelcost) end
function levelfuncs.currentdamagelevelcost(self,damagelevelcost) self.inst.currentdamagelevelcost:set(damagelevelcost) end

function levelfuncs.currenthungerlevelmax(self,hungerlevelmax) self.inst.currenthungerlevelmax:set(hungerlevelmax) end
function levelfuncs.currentsanitylevelmax(self,sanitylevelmax) self.inst.currentsanitylevelmax:set(sanitylevelmax) end
function levelfuncs.currenthealthlevelmax(self,healthlevelmax) self.inst.currenthealthlevelmax:set(healthlevelmax) end
function levelfuncs.currentspeedlevelmax(self,speedlevelmax) self.inst.currentspeedlevelmax:set(speedlevelmax) end
function levelfuncs.currentabsorblevelmax(self,absorblevelmax) self.inst.currentabsorblevelmax:set(absorblevelmax) end
function levelfuncs.currentdamagelevelmax(self,damagelevelmax) self.inst.currentdamagelevelmax:set(damagelevelmax) end

function levelfuncs.currentpetspeedlevel(self,petspeedlevelamount) self.inst.currentpetspeedlevel:set(petspeedlevelamount) end
function levelfuncs.currentpetdamagelevel(self,petdamagelevelamount) self.inst.currentpetdamagelevel:set(petdamagelevelamount) end
function levelfuncs.currentpetattackspeedlevel(self,petattackspeedlevelamount) self.inst.currentpetattackspeedlevel:set(petattackspeedlevelamount) end
function levelfuncs.currentpetcooldownlevel(self,petcooldownlevelamount) self.inst.currentpetcooldownlevel:set(petcooldownlevelamount) end
function levelfuncs.currentpetspelllevel(self,petspelllevelamount) self.inst.currentpetspelllevel:set(petspelllevelamount) end
function levelfuncs.currentpetpassivelevel(self,petpassivelevelamount) self.inst.currentpetpassivelevel:set(petpassivelevelamount) end

function levelfuncs.currentpetspeedlevelcost(self,petspeedlevelcost) self.inst.currentpetspeedlevelcost:set(petspeedlevelcost) end
function levelfuncs.currentpetdamagelevelcost(self,petdamagelevelcost) self.inst.currentpetdamagelevelcost:set(petdamagelevelcost) end
function levelfuncs.currentpetattackspeedlevelcost(self,petattackspeedlevelcost) self.inst.currentpetattackspeedlevelcost:set(petattackspeedlevelcost) end
function levelfuncs.currentpetcooldownlevelcost(self,petcooldownlevelcost) self.inst.currentpetcooldownlevelcost:set(petcooldownlevelcost) end
function levelfuncs.currentpetspelllevelcost(self,petspelllevelcost) self.inst.currentpetspelllevelcost:set(petspelllevelcost) end
function levelfuncs.currentpetpassivelevelcost(self,petpassivelevelcost) self.inst.currentpetpassivelevelcost:set(petpassivelevelcost) end

function levelfuncs.currentpetspeedlevelmax(self,petspeedlevelmax) self.inst.currentpetspeedlevelmax:set(petspeedlevelmax) end
function levelfuncs.currentpetdamagelevelmax(self,petdamagelevelmax) self.inst.currentpetdamagelevelmax:set(petdamagelevelmax) end
function levelfuncs.currentpetattackspeedlevelmax(self,petattackspeedlevelmax) self.inst.currentpetattackspeedlevelmax:set(petattackspeedlevelmax) end
function levelfuncs.currentpetcooldownlevelmax(self,petcooldownlevelmax) self.inst.currentpetcooldownlevelmax:set(petcooldownlevelmax) end
function levelfuncs.currentpetspelllevelmax(self,petspelllevelmax) self.inst.currentpetspelllevelmax:set(petspelllevelmax) end
function levelfuncs.currentpetpassivelevelmax(self,petpassivelevelmax) self.inst.currentpetpassivelevelmax:set(petpassivelevelmax) end

function levelfuncs.currentzoomlevel(self,zoomlevel) self.inst.currentzoomlevel:set(zoomlevel) end
function levelfuncs.currentmainhudtype(self,mainhudtype) self.inst.currentmainhudtype:set(mainhudtype) end
function levelfuncs.currentwidgetxpos(self,widgetxpos) self.inst.currentwidgetxpos:set(widgetxpos) end

function levelfuncs.getlevelfunction()
    local data = {
        level = levelfuncs.getlevel,
        levelxp = levelfuncs.getlevelxp,
        overallxp = levelfuncs.getoverallxp,
        attributepoints = levelfuncs.getattributepoints,

        petlevel = levelfuncs.getpetlevel,
        petlevelxp = levelfuncs.getpetlevelxp,
        petoverallxp = levelfuncs.getpetoverallxp,
        petattributepoints = levelfuncs.getpetattributepoints,
        petcanevolve = levelfuncs.getpetcanevolve,

        zoomlevel = levelfuncs.currentzoomlevel,
        mainhudtype = levelfuncs.currentmainhudtype,
        widgetXpos = levelfuncs.currentwidgetxpos,
    }
    for lvlname, lvl in pairs(level_lists) do
        data[lvlname.."amount"] = levelfuncs["current"..lvlname]
        data[lvlname.."cost"] = levelfuncs["current"..lvlname.."cost"]
        data[lvlname.."max"] = levelfuncs["current"..lvlname.."max"]
    end
    return data
end

return levelfuncs