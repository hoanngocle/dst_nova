local perkfuncs = {}

local function getcoinamount(self,coinamount) self.inst.currentcoinamount:set(coinamount) end

-- # ATTRIBUTE
function perkfuncs.currenthungerup(self,hungerupamount) self.inst.currenthungerup:set(hungerupamount) end
function perkfuncs.currenthealthup(self,healthupamount) self.inst.currenthealthup:set(healthupamount) end
function perkfuncs.currentsanityup(self,sanityupamount) self.inst.currentsanityup:set(sanityupamount) end
function perkfuncs.currenthealthregenup(self,healthregenupamount) self.inst.currenthealthregenup:set(healthregenupamount) end
function perkfuncs.currenthungerrateup(self,hungerrateupamount) self.inst.currenthungerrateup:set(hungerrateupamount) end
function perkfuncs.currentsanityregenup(self,sanityregenupamount) self.inst.currentsanityregenup:set(sanityregenupamount) end
function perkfuncs.currentspeedup(self,speedupamount) self.inst.currentspeedup:set(speedupamount) end
function perkfuncs.currentabsorbup(self,absorbupamount) self.inst.currentabsorbup:set(absorbupamount) end
function perkfuncs.currentdamageup(self,damageupamount) self.inst.currentdamageup:set(damageupamount) end
function perkfuncs.currentplanarabsorbup(self,planarabsorbupamount) self.inst.currentplanarabsorbup:set(planarabsorbupamount) end
function perkfuncs.currentplanardamageup(self,planardamageupamount) self.inst.currentplanardamageup:set(planardamageupamount) end
function perkfuncs.currentcriticalup(self,criticalupamount) self.inst.currentcriticalup:set(criticalupamount) end
function perkfuncs.currentcriticaldmgup(self,criticaldmgupamount) self.inst.currentcriticaldmgup:set(criticaldmgupamount) end
function perkfuncs.currentlifestealup(self,lifestealupamount) self.inst.currentlifestealup:set(lifestealupamount) end
function perkfuncs.currentfireflylightup(self,fireflylightupamount) self.inst.currentfireflylightup:set(fireflylightupamount) end
function perkfuncs.currentscaleup(self,scaleupamount) self.inst.currentscaleup:set(scaleupamount) end
function perkfuncs.currentxpmultup(self,xpmultupamount) self.inst.currentxpmultup:set(xpmultupamount) end
function perkfuncs.currentrepairitemup(self,repairitemupamount) self.inst.currentrepairitemup:set(repairitemupamount) end
function perkfuncs.currentrepairmagiup(self,repairmagiupamount) self.inst.currentrepairmagiup:set(repairmagiupamount) end
function perkfuncs.currentrepairfoodup(self,repairfoodupamount) self.inst.currentrepairfoodup:set(repairfoodupamount) end
function perkfuncs.currentkrampussackup(self,krampussackupamount) self.inst.currentkrampussackup:set(krampussackupamount) end

function perkfuncs.currenthungerupcost(self,hungerupcost) self.inst.hungerupcost:set(hungerupcost) end
function perkfuncs.currenthealthupcost(self,healthupcost) self.inst.healthupcost:set(healthupcost) end
function perkfuncs.currentsanityupcost(self,sanityupcost) self.inst.sanityupcost:set(sanityupcost) end
function perkfuncs.currenthealthregenupcost(self,healthregenupcost) self.inst.healthregenupcost:set(healthregenupcost) end
function perkfuncs.currenthungerrateupcost(self,hungerrateupcost) self.inst.hungerrateupcost:set(hungerrateupcost) end
function perkfuncs.currentsanityregenupcost(self,sanityregenupcost) self.inst.sanityregenupcost:set(sanityregenupcost) end
function perkfuncs.currentspeedupcost(self,speedupcost) self.inst.speedupcost:set(speedupcost) end
function perkfuncs.currentabsorbupcost(self,absorbupcost) self.inst.absorbupcost:set(absorbupcost) end
function perkfuncs.currentdamageupcost(self,damageupcost) self.inst.damageupcost:set(damageupcost) end
function perkfuncs.currentplanarabsorbupcost(self,planarabsorbupcost) self.inst.planarabsorbupcost:set(planarabsorbupcost) end
function perkfuncs.currentplanardamageupcost(self,planardamageupcost) self.inst.planardamageupcost:set(planardamageupcost) end
function perkfuncs.currentcriticalupcost(self,criticalupcost) self.inst.criticalupcost:set(criticalupcost) end
function perkfuncs.currentcriticaldmgupcost(self,criticaldmgupcost) self.inst.criticaldmgupcost:set(criticaldmgupcost) end
function perkfuncs.currentlifestealupcost(self,lifestealupcost) self.inst.lifestealupcost:set(lifestealupcost) end
function perkfuncs.currentfireflylightupcost(self,fireflylightupcost) self.inst.fireflylightupcost:set(fireflylightupcost) end
function perkfuncs.currentscaleupcost(self,scaleupcost) self.inst.scaleupcost:set(scaleupcost) end
function perkfuncs.currentxpmultupcost(self,xpmultupcost) self.inst.xpmultupcost:set(xpmultupcost) end
function perkfuncs.currentrepairitemupcost(self,repairitemupcost) self.inst.repairitemupcost:set(repairitemupcost) end
function perkfuncs.currentrepairmagiupcost(self,repairmagiupcost) self.inst.repairmagiupcost:set(repairmagiupcost) end
function perkfuncs.currentrepairfoodupcost(self,repairfoodupcost) self.inst.repairfoodupcost:set(repairfoodupcost) end
function perkfuncs.currentkrampussackupcost(self,krampussackupcost) self.inst.krampussackupcost:set(krampussackupcost) end

-- # ABILITY
function perkfuncs.currentnomoist(self,nomoist) local c = 0 if nomoist then c=1 end self.inst.currentnomoist:set(c) end
function perkfuncs.currenticemaster(self,icemaster) local c = 0 if icemaster then c=1 end self.inst.currenticemaster:set(c) end
function perkfuncs.currentfiremaster(self,firemaster) local c = 0 if firemaster then c=1 end self.inst.currentfiremaster:set(c) end
function perkfuncs.currentfastworker(self,fastworker) local c = 0 if fastworker then c=1 end self.inst.currentfastworker:set(c) end
function perkfuncs.currentminefaster(self,minefaster) local c = 0 if minefaster then c=1 end self.inst.currentminefaster:set(c) end
function perkfuncs.currentchopfaster(self,chopfaster) local c = 0 if chopfaster then c=1 end self.inst.currentchopfaster:set(c) end
function perkfuncs.currentfishfaster(self,fishfaster) local c = 0 if fishfaster then c=1 end self.inst.currentfishfaster:set(c) end
function perkfuncs.currentcookfaster(self,cookfaster) local c = 0 if cookfaster then c=1 end self.inst.currentcookfaster:set(c) end
function perkfuncs.currentwarlychef(self,warlychef) local c = 0 if warlychef then c=1 end self.inst.currentwarlychef:set(c) end
function perkfuncs.currenttrinketowner(self,trinketowner) local c = 0 if trinketowner then c=1 end self.inst.currenttrinketowner:set(c) end
function perkfuncs.currentchristmastbulb(self,christmastbulb) local c = 0 if christmastbulb then c=1 end self.inst.currentchristmastbulb:set(c) end
function perkfuncs.currentstrongergrip(self,strongergrip) local c = 0 if strongergrip then c=1 end self.inst.currentstrongergrip:set(c) end
function perkfuncs.currentdoublehealed(self,doublehealed) local c = 0 if doublehealed then c=1 end self.inst.currentdoublehealed:set(c) end
function perkfuncs.currentdoublepick(self,doublepick) local c = 0 if doublepick then c=1 end self.inst.currentdoublepick:set(c) end
function perkfuncs.currentdoubledrop(self,doubledrop) local c = 0 if doubledrop then c=1 end self.inst.currentdoubledrop:set(c) end
function perkfuncs.currentdoubleworkdrop(self,doubleworkdrop) local c = 0 if doubleworkdrop then c=1 end self.inst.currentdoubleworkdrop:set(c) end
function perkfuncs.currentbuildcheaper(self,buildcheaper) local c = 0 if buildcheaper then c=1 end self.inst.currentbuildcheaper:set(c) end
function perkfuncs.currentsupercritter(self,supercritter) local c = 0 if supercritter then c=1 end self.inst.currentsupercritter:set(c) end
function perkfuncs.currentblueprintextractor(self,blueprintextractor) local c = 0 if blueprintextractor then c=1 end self.inst.currentblueprintextractor:set(c) end
function perkfuncs.currentitemmerger(self,itemmerger) local c = 0 if itemmerger then c=1 end self.inst.currentitemmerger:set(c) end
function perkfuncs.currentitemcleaner(self,itemcleaner) local c = 0 if itemcleaner then c=1 end self.inst.currentitemcleaner:set(c) end
function perkfuncs.currentsharemap(self,sharemap) local c = 0 if sharemap then c=1 end self.inst.currentsharemap:set(c) end

-- # EXPERTISE
function perkfuncs.currentexpertwilson1(self,expertwilson1) local c = 0 if expertwilson1 then c=1 end self.inst.currentexpertwilson1:set(c) end
function perkfuncs.currentexpertwilson2(self,expertwilson2) local c = 0 if expertwilson2 then c=1 end self.inst.currentexpertwilson2:set(c) end
function perkfuncs.currentexpertwes1(self,expertwes1) local c = 0 if expertwes1 then c=1 end self.inst.currentexpertwes1:set(c) end
function perkfuncs.currentexpertwes2(self,expertwes2) local c = 0 if expertwes2 then c=1 end self.inst.currentexpertwes2:set(c) end
function perkfuncs.currentexpertwoodie1(self,expertwoodie1) local c = 0 if expertwoodie1 then c=1 end self.inst.currentexpertwoodie1:set(c) end
function perkfuncs.currentexpertwoodie2(self,expertwoodie2) local c = 0 if expertwoodie2 then c=1 end self.inst.currentexpertwoodie2:set(c) end
function perkfuncs.currentexpertwoodie3(self,expertwoodie3) local c = 0 if expertwoodie3 then c=1 end self.inst.currentexpertwoodie3:set(c) end
function perkfuncs.currentexpertwinona1(self,expertwinona1) local c = 0 if expertwinona1 then c=1 end self.inst.currentexpertwinona1:set(c) end
function perkfuncs.currentexpertwinona2(self,expertwinona2) local c = 0 if expertwinona2 then c=1 end self.inst.currentexpertwinona2:set(c) end
function perkfuncs.currentexpertwebber1(self,expertwebber1) local c = 0 if expertwebber1 then c=1 end self.inst.currentexpertwebber1:set(c) end
function perkfuncs.currentexpertwebber2(self,expertwebber2) local c = 0 if expertwebber2 then c=1 end self.inst.currentexpertwebber2:set(c) end
function perkfuncs.currentexpertwebber3(self,expertwebber3) local c = 0 if expertwebber3 then c=1 end self.inst.currentexpertwebber3:set(c) end
function perkfuncs.currentexpertwx1(self,expertwx1) local c = 0 if expertwx1 then c=1 end self.inst.currentexpertwx1:set(c) end
function perkfuncs.currentexpertwx2(self,expertwx2) local c = 0 if expertwx2 then c=1 end self.inst.currentexpertwx2:set(c) end
function perkfuncs.currentexpertwx4(self,expertwx4) local c = 0 if expertwx4 then c=1 end self.inst.currentexpertwx4:set(c) end
function perkfuncs.currentexpertwillow3(self,expertwillow3) local c = 0 if expertwillow3 then c=1 end self.inst.currentexpertwillow3:set(c) end
function perkfuncs.currentexpertwillow4(self,expertwillow4) local c = 0 if expertwillow4 then c=1 end self.inst.currentexpertwillow4:set(c) end
function perkfuncs.currentexpertwathg1(self,expertwathg1) local c = 0 if expertwathg1 then c=1 end self.inst.currentexpertwathg1:set(c) end
function perkfuncs.currentexpertwathg2(self,expertwathg2) local c = 0 if expertwathg2 then c=1 end self.inst.currentexpertwathg2:set(c) end
function perkfuncs.currentexpertwendy1(self,expertwendy1) local c = 0 if expertwendy1 then c=1 end self.inst.currentexpertwendy1:set(c) end
function perkfuncs.currentexpertwendy2(self,expertwendy2) local c = 0 if expertwendy2 then c=1 end self.inst.currentexpertwendy2:set(c) end
function perkfuncs.currentexpertwendy3(self,expertwendy3) local c = 0 if expertwendy3 then c=1 end self.inst.currentexpertwendy3:set(c) end
function perkfuncs.currentexpertwolf1(self,expertwolf1) local c = 0 if expertwolf1 then c=1 end self.inst.currentexpertwolf1:set(c) end
function perkfuncs.currentexpertwolf2(self,expertwolf2) local c = 0 if expertwolf2 then c=1 end self.inst.currentexpertwolf2:set(c) end
function perkfuncs.currentexpertwalter1(self,expertwalter1) local c = 0 if expertwalter1 then c=1 end self.inst.currentexpertwalter1:set(c) end
function perkfuncs.currentexpertwalter3(self,expertwalter3) local c = 0 if expertwalter3 then c=1 end self.inst.currentexpertwalter3:set(c) end
function perkfuncs.currentexpertwalter4(self,expertwalter4) local c = 0 if expertwalter4 then c=1 end self.inst.currentexpertwalter4:set(c) end
function perkfuncs.currentexpertwicker2(self,expertwicker2) local c = 0 if expertwicker2 then c=1 end self.inst.currentexpertwicker2:set(c) end
function perkfuncs.currentexpertwicker3(self,expertwicker3) local c = 0 if expertwicker3 then c=1 end self.inst.currentexpertwicker3:set(c) end
function perkfuncs.currentexpertwaxwell2(self,expertwaxwell2) local c = 0 if expertwaxwell2 then c=1 end self.inst.currentexpertwaxwell2:set(c) end
function perkfuncs.currentexpertwaxwell3(self,expertwaxwell3) local c = 0 if expertwaxwell3 then c=1 end self.inst.currentexpertwaxwell3:set(c) end
function perkfuncs.currentexpertwaxwell4(self,expertwaxwell4) local c = 0 if expertwaxwell4 then c=1 end self.inst.currentexpertwaxwell4:set(c) end
function perkfuncs.currentexpertwarly3(self,expertwarly3) local c = 0 if expertwarly3 then c=1 end self.inst.currentexpertwarly3:set(c) end
function perkfuncs.currentexpertwarly4(self,expertwarly4) local c = 0 if expertwarly4 then c=1 end self.inst.currentexpertwarly4:set(c) end
function perkfuncs.currentexpertworm1(self,expertworm1) local c = 0 if expertworm1 then c=1 end self.inst.currentexpertworm1:set(c) end
function perkfuncs.currentexpertworm2(self,expertworm2) local c = 0 if expertworm2 then c=1 end self.inst.currentexpertworm2:set(c) end
function perkfuncs.currentexpertwortox1(self,expertwortox1) local c = 0 if expertwortox1 then c=1 end self.inst.currentexpertwortox1:set(c) end
function perkfuncs.currentexpertwortox3(self,expertwortox3) local c = 0 if expertwortox3 then c=1 end self.inst.currentexpertwortox3:set(c) end
function perkfuncs.currentexpertwanda1(self,expertwanda1) local c = 0 if expertwanda1 then c=1 end self.inst.currentexpertwanda1:set(c) end
function perkfuncs.currentexpertwanda2(self,expertwanda2) local c = 0 if expertwanda2 then c=1 end self.inst.currentexpertwanda2:set(c) end
function perkfuncs.currentexpertwurt1(self,expertwurt1) local c = 0 if expertwurt1 then c=1 end self.inst.currentexpertwurt1:set(c) end
function perkfuncs.currentexpertwurt2(self,expertwurt2) local c = 0 if expertwurt2 then c=1 end self.inst.currentexpertwurt2:set(c) end
function perkfuncs.currentexpertwonk1(self,expertwonk1) local c = 0 if expertwonk1 then c=1 end self.inst.currentexpertwonk1:set(c) end
function perkfuncs.currentexpertwonk2(self,expertwonk2) local c = 0 if expertwonk2 then c=1 end self.inst.currentexpertwonk2:set(c) end

-- # CRAFT
function perkfuncs.currentancientstation(self,ancientstation) local c = 0 if ancientstation then c=1 end self.inst.currentancientstation:set(c) end
function perkfuncs.currentlunarcraft(self,lunarcraft) local c = 0 if lunarcraft then c=1 end self.inst.currentlunarcraft:set(c) end
function perkfuncs.currentpearlcraft(self,pearlcraft) local c = 0 if pearlcraft then c=1 end self.inst.currentpearlcraft:set(c) end
function perkfuncs.currentrabbitkingcraft(self,rabbitkingcraft) local c = 0 if rabbitkingcraft then c=1 end self.inst.currentrabbitkingcraft:set(c) end
function perkfuncs.currentcarpentercraft(self,carpentercraft) local c = 0 if carpentercraft then c=1 end self.inst.currentcarpentercraft:set(c) end
function perkfuncs.currentcrittercraft(self,crittercraft) local c = 0 if crittercraft then c=1 end self.inst.currentcrittercraft:set(c) end
function perkfuncs.currentmadsciencecraft(self,madsciencecraft) local c = 0 if madsciencecraft then c=1 end self.inst.currentmadsciencecraft:set(c) end
function perkfuncs.currenteventcraft(self,eventcraft) local c = 0 if eventcraft then c=1 end self.inst.currenteventcraft:set(c) end
function perkfuncs.currentcarnivalcraft(self,carnivalcraft) local c = 0 if carnivalcraft then c=1 end self.inst.currentcarnivalcraft:set(c) end
function perkfuncs.currentklaussackbuilder(self,klaussackbuilder) local c = 0 if klaussackbuilder then c=1 end self.inst.currentklaussackbuilder:set(c) end
function perkfuncs.currentbossitemcraft(self,bossitemcraft) local c = 0 if bossitemcraft then c=1 end self.inst.currentbossitemcraft:set(c) end
function perkfuncs.currentdencraft(self,dencraft) local c = 0 if dencraft then c=1 end self.inst.currentdencraft:set(c) end
function perkfuncs.currenttrinketcraft(self,trinketcraft) local c = 0 if trinketcraft then c=1 end self.inst.currenttrinketcraft:set(c) end
function perkfuncs.currentclustercraft(self,clustercraft) local c = 0 if clustercraft then c=1 end self.inst.currentclustercraft:set(c) end
function perkfuncs.currentmulticraft(self,multicraft) local c = 0 if multicraft then c=1 end self.inst.currentmulticraft:set(c) end
function perkfuncs.currentduppercritter(self,duppercritter) local c = 0 if duppercritter then c=1 end self.inst.currentduppercritter:set(c) end

-- # GLOBAL
function perkfuncs.currenteternalcage(self,eternalcage) local c = 0 if TUNING.ACH["eternalcage"] then c=TUNING.ACH["eternalcage"] end self.inst.currenteternalcage:set(c) end
function perkfuncs.currenteternalicebox(self,eternalicebox) local c = 0 if TUNING.ACH["eternalicebox"] then c=TUNING.ACH["eternalicebox"] end self.inst.currenteternalicebox:set(c) end
function perkfuncs.currenteternalthermal(self,eternalthermal) local c = 0 if TUNING.ACH["eternalthermal"] then c=TUNING.ACH["eternalthermal"] end self.inst.currenteternalthermal:set(c) end
function perkfuncs.currenteasyfarm(self,easyfarm) local c = 0 if TUNING.ACH["easyfarm"] then c=TUNING.ACH["easyfarm"] end self.inst.currenteasyfarm:set(c) end
function perkfuncs.currenteasybeef(self,easybeef) local c = 0 if TUNING.ACH["easybeef"] then c=TUNING.ACH["easybeef"] end self.inst.currenteasybeef:set(c) end
function perkfuncs.currenticyweed(self,icyweed) local c = 0 if TUNING.ACH["icyweed"] then c=TUNING.ACH["icyweed"] end self.inst.currenticyweed:set(c) end
function perkfuncs.currentbosshunting(self,bosshunting) local c = 0 if TUNING.ACH["bosshunting"] then c=TUNING.ACH["bosshunting"] end self.inst.currentbosshunting:set(c) end
function perkfuncs.currentstackinfinite(self,stackinfinite) local c = 0 if TUNING.ACH["stackinfinite"] then c=TUNING.ACH["stackinfinite"] end self.inst.currentstackinfinite:set(c) end
function perkfuncs.currentinsightinfinite(self,insightinfinite) local c = 0 if TUNING.ACH["insightinfinite"] then c=TUNING.ACH["insightinfinite"] end self.inst.currentinsightinfinite:set(c) end
function perkfuncs.currentgroundedscream(self,groundedscream) local c = 0 if TUNING.ACH["groundedscream"] then c=TUNING.ACH["groundedscream"] end self.inst.currentgroundedscream:set(c) end
function perkfuncs.currentriftcontroller(self,riftcontroller) local c = 0 if TUNING.ACH["riftcontroller"] then c=TUNING.ACH["riftcontroller"] end self.inst.currentriftcontroller:set(c) end

function perkfuncs.getperkfunction()
    local data = {
        coinamount = getcoinamount,
    }
    for perkname, perk in pairs(perk_lists) do
        if perk.single ~= true then
            if perk.multi then
                data[perkname .."amount"] = perkfuncs["current".. perkname]
                data[perkname .."cost"] = perkfuncs["current".. perkname .."cost"]
            else
                data[perkname] = perkfuncs["current".. perkname]
            end
        end
    end
    return data
end

return perkfuncs
