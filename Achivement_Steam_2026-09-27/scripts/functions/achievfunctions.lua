local achievfuncs = {}

local function arrayToString(arr, type)
	local s = ""
	local sortedNames = {}
	for k, v in pairs(arr) do
		if type == "literal" then
			table.insert(sortedNames, string.upper(v))
		elseif type == "turf" then
			local groundname = GROUND_NAMES[tonumber(v)] or string.upper(v)
			table.insert(sortedNames, groundname)
		elseif type == "glassmaker" then
			if v == "glassblock" then
				table.insert(sortedNames, STRINGS.NAMES[string.upper(v)])
			elseif v == "glassspike_short" then
				table.insert(sortedNames, "Short " .. STRINGS.NAMES.GLASSSPIKE)
			elseif v == "glassspike_med" then
				table.insert(sortedNames, "Medium " .. STRINGS.NAMES.GLASSSPIKE)
			elseif v == "glassspike_tall" then
				table.insert(sortedNames, "Tall " .. STRINGS.NAMES.GLASSSPIKE)
			end
		else
			table.insert(sortedNames, STRINGS.NAMES[string.upper(v)])
		end
	end
	table.sort(sortedNames)
	for k, v in pairs(sortedNames) do
		s = s .. v .. ",\n"
	end
	s = s:sub(1,-3) -- To remove last ",\n"
	return s
end

-- # FOOD
function achievfuncs.checksupereat(self,supereat) local c = 0 if supereat then c=1 end self.inst.checksupereat:set(c) end
function achievfuncs.currentsupereat(self,supereatamount) self.inst.currentsupereat:set(supereatamount) end
function achievfuncs.checkeathot(self,eathot) local c = 0 if eathot then c=1 end self.inst.checkeathot:set(c) end
function achievfuncs.checkeatcold(self,eatcold) local c = 0 if eatcold then c=1 end self.inst.checkeatcold:set(c) end
function achievfuncs.checkeatmandrake(self,eatmandrake) local c = 0 if eatmandrake then c=1 end self.inst.checkeatmandrake:set(c) end
function achievfuncs.checkeatguardianhorn(self,eatguardianhorn) local c = 0 if eatguardianhorn then c=1 end self.inst.checkeatguardianhorn:set(c) end
function achievfuncs.checkeatnightberry(self,eatnightberry) local c = 0 if eatnightberry then c=1 end self.inst.checkeatnightberry:set(c) end
function achievfuncs.checkeatmonsterlasagna(self,eatmonsterlasagna) local c = 0 if eatmonsterlasagna then c=1 end self.inst.checkeatmonsterlasagna:set(c) end
function achievfuncs.currenteatmonsterlasagna(self,eatmonsterlasagnaamount) self.inst.currenteatmonsterlasagna:set(eatmonsterlasagnaamount) end
function achievfuncs.checkeatfavourite(self,eatfavourite) local c = 0 if eatfavourite then c=1 end self.inst.checkeatfavourite:set(c) end
function achievfuncs.currenteatfavourite(self,eatfavouriteamount) self.inst.currenteatfavourite:set(eatfavouriteamount) end
function achievfuncs.checkeatgear(self,eatgear) local c = 0 if eatgear then c=1 end self.inst.checkeatgear:set(c) end
function achievfuncs.currenteatgear(self,eatgearamount) self.inst.currenteatgear:set(eatgearamount) end
function achievfuncs.checkeatkitschyidol(self,eatkitschyidol) local c = 0 if eatkitschyidol then c=1 end self.inst.checkeatkitschyidol:set(c) end
function achievfuncs.currenteatkitschyidol(self,eatkitschyidolamount) self.inst.currenteatkitschyidol:set(eatkitschyidolamount) end
function achievfuncs.currenteatkitschyidollist(self,eatkitschyidollist) self.inst.currenteatkitschyidollist:set(arrayToString(eatkitschyidollist)) end
function achievfuncs.currentfeedplayer(self,feedplayer) self.inst.currentfeedplayer:set(feedplayer) end
function achievfuncs.checkfeedplayer(self,feedplayer) local c = 0 if feedplayer then c=1 end self.inst.checkfeedplayer:set(c) end
function achievfuncs.checkfeedlivinglog(self,feedlivinglog) local c = 0 if feedlivinglog then c=1 end self.inst.checkfeedlivinglog:set(c) end
function achievfuncs.checkfeedwebber(self,feedwebber) local c = 0 if feedwebber then c=1 end self.inst.checkfeedwebber:set(c) end
function achievfuncs.currentfeedwebber(self,feedwebberamount) self.inst.currentfeedwebber:set(feedwebberamount) end
function achievfuncs.currentfeedwebberlist(self,feedwebberlist) self.inst.currentfeedwebberlist:set(arrayToString(feedwebberlist)) end

-- # LIFE
function achievfuncs.checkdiecharlie(self,diecharlie) local c = 0 if diecharlie then c=1 end self.inst.checkdiecharlie:set(c) end
function achievfuncs.checkdiemeteor(self,diemeteor) local c = 0 if diemeteor then c=1 end self.inst.checkdiemeteor:set(c) end
function achievfuncs.checkdierose(self,dierose) local c = 0 if dierose then c=1 end self.inst.checkdierose:set(c) end
function achievfuncs.checkdiepoison(self,diepoison) local c = 0 if diepoison then c=1 end self.inst.checkdiepoison:set(c) end
function achievfuncs.checkdeath(self,death) local c = 0 if death then c=1 end self.inst.checkdeath:set(c) end
function achievfuncs.currentdeath(self,deathamount) self.inst.currentdeath:set(deathamount) end
function achievfuncs.checkreviveeffigy(self,reviveeffigy) local c = 0 if reviveeffigy then c=1 end self.inst.checkreviveeffigy:set(c) end
function achievfuncs.checkrevivewanda(self,revivewanda) local c = 0 if revivewanda then c=1 end self.inst.checkrevivewanda:set(c) end
function achievfuncs.checkreviveamulet(self,reviveamulet) local c = 0 if reviveamulet then c=1 end self.inst.checkreviveamulet:set(c) end
function achievfuncs.currentreviveamulet(self,reviveamulet) self.inst.currentreviveamulet:set(reviveamulet) end
function achievfuncs.checkrevive(self,revive) local c = 0 if revive then c=1 end self.inst.checkrevive:set(c) end
function achievfuncs.currentrevive(self,reviveamount) self.inst.currentrevive:set(reviveamount) end
function achievfuncs.checkhealtillweed(self,healtillweed) local c = 0 if healtillweed then c=1 end self.inst.checkhealtillweed:set(c) end
function achievfuncs.checkhealwortox(self,healwortox) local c = 0 if healwortox then c=1 end self.inst.checkhealwortox:set(c) end
function achievfuncs.currenthealwortox(self,healwortoxamount) self.inst.currenthealwortox:set(healwortoxamount) end

-- # HURT
function achievfuncs.checkpacifist(self,pacifist) local c = 0 if pacifist then c=1 end self.inst.checkpacifist:set(c) end
function achievfuncs.currentpacifist(self,pacifist) self.inst.currentpacifist:set(pacifist) end
function achievfuncs.checkdamagedeal(self,damagedeal) local c = 0 if damagedeal then c=1 end self.inst.checkdamagedeal:set(c) end
function achievfuncs.currentdamagedeal(self,damagedealamount) self.inst.currentdamagedeal:set(damagedealamount) end
function achievfuncs.checktank(self,tank) local c = 0 if tank then c=1 end self.inst.checktank:set(c) end
function achievfuncs.currenttank(self,tankamount) self.inst.currenttank:set(tankamount) end
function achievfuncs.checkdmgnodmg(self,dmgnodmg) local c = 0 if dmgnodmg then c=1 end self.inst.checkdmgnodmg:set(c) end
function achievfuncs.currentdmgnodmg(self,dmgnodmg) self.inst.currentdmgnodmg:set(dmgnodmg) end
function achievfuncs.checkburn(self,burn) local c = 0 if burn then c=1 end self.inst.checkburn:set(c) end
function achievfuncs.checkfreeze(self,freeze) local c = 0 if freeze then c=1 end self.inst.checkfreeze:set(c) end
function achievfuncs.checkdrown(self,drown) local c = 0 if drown then c=1 end self.inst.checkdrown:set(c) end
function achievfuncs.checklightning(self,lightning) local c = 0 if lightning then c=1 end self.inst.checklightning:set(c) end

-- # WORK
function achievfuncs.checkplantmaster(self,plantmaster) local c = 0 if plantmaster then c=1 end self.inst.checkplantmaster:set(c) end
function achievfuncs.currentplantmaster(self,plantmasteramount) self.inst.currentplantmaster:set(plantmasteramount) end
function achievfuncs.checkfishmaster(self,fishmaster) local c = 0 if fishmaster then c=1 end self.inst.checkfishmaster:set(c) end
function achievfuncs.currentfishmaster(self,fishmasteramount) self.inst.currentfishmaster:set(fishmasteramount) end
function achievfuncs.checkpickmaster(self,pickmaster) local c = 0 if pickmaster then c=1 end self.inst.checkpickmaster:set(c) end
function achievfuncs.currentpickmaster(self,pickmasteramount) self.inst.currentpickmaster:set(pickmasteramount) end
function achievfuncs.checkchopmaster(self,chopmaster) local c = 0 if chopmaster then c=1 end self.inst.checkchopmaster:set(c) end
function achievfuncs.currentchopmaster(self,chopmasteramount) self.inst.currentchopmaster:set(chopmasteramount) end
function achievfuncs.checkcookmaster(self,cookmaster) local c = 0 if cookmaster then c=1 end self.inst.checkcookmaster:set(c) end
function achievfuncs.currentcookmaster(self,cookmasteramount) self.inst.currentcookmaster:set(cookmasteramount) end
function achievfuncs.checkminemaster(self,minemaster) local c = 0 if minemaster then c=1 end self.inst.checkminemaster:set(c) end
function achievfuncs.currentminemaster(self,minemasteramount) self.inst.currentminemaster:set(minemasteramount) end
function achievfuncs.checkbuildmaster(self,buildmaster) local c = 0 if buildmaster then c=1 end self.inst.checkbuildmaster:set(c) end
function achievfuncs.currentbuildmaster(self,buildmasteramount) self.inst.currentbuildmaster:set(buildmasteramount) end
function achievfuncs.checkhoneymaster(self,honeymaster) local c = 0 if honeymaster then c=1 end self.inst.checkhoneymaster:set(c) end
function achievfuncs.currenthoneymaster(self,honeymasteramount) self.inst.currenthoneymaster:set(honeymasteramount) end
function achievfuncs.checkjerkymaster(self,jerkymaster) local c = 0 if jerkymaster then c=1 end self.inst.checkjerkymaster:set(c) end
function achievfuncs.currentjerkymaster(self,jerkymasteramount) self.inst.currentjerkymaster:set(jerkymasteramount) end
function achievfuncs.checkflowermaster(self,flowermaster) local c = 0 if flowermaster then c=1 end self.inst.checkflowermaster:set(c) end
function achievfuncs.currentflowermaster(self,flowermasteramount) self.inst.currentflowermaster:set(flowermasteramount) end
function achievfuncs.checkfertilizemaster(self,fertilizemaster) local c = 0 if fertilizemaster then c=1 end self.inst.checkfertilizemaster:set(c) end
function achievfuncs.currentfertilizemaster(self,fertilizemasteramount) self.inst.currentfertilizemaster:set(fertilizemasteramount) end
function achievfuncs.checkfertilizebigmaster(self,fertilizebigmaster) local c = 0 if fertilizebigmaster then c=1 end self.inst.checkfertilizebigmaster:set(c) end
function achievfuncs.currentfertilizebigmaster(self,fertilizebigmasteramount) self.inst.currentfertilizebigmaster:set(fertilizebigmasteramount) end
function achievfuncs.checkwallmaster(self,wallmaster) local c = 0 if wallmaster then c=1 end self.inst.checkwallmaster:set(c) end
function achievfuncs.currentwallmaster(self,wallmasteramount) self.inst.currentwallmaster:set(wallmasteramount) end
function achievfuncs.checkpicktumbleweed(self,picktumbleweed) local c = 0 if picktumbleweed then c=1 end self.inst.checkpicktumbleweed:set(c) end
function achievfuncs.currentpicktumbleweed(self,picktumbleweedamount) self.inst.currentpicktumbleweed:set(picktumbleweedamount) end

-- # HAVE
function achievfuncs.checkspore(self,spore) local c = 0 if spore then c=1 end self.inst.checkspore:set(c) end
function achievfuncs.currentspore(self,sporeamount) self.inst.currentspore:set(sporeamount) end
function achievfuncs.checkcursedtrinket(self,cursedtrinket) local c = 0 if cursedtrinket then c=1 end self.inst.checkcursedtrinket:set(c) end
function achievfuncs.currentcursedtrinket(self,cursedtrinketamount) self.inst.currentcursedtrinket:set(cursedtrinketamount) end
function achievfuncs.checkequipingkrampussack(self,equipingkrampussack) local c = 0 if equipingkrampussack then c=1 end self.inst.checkequipingkrampussack:set(c) end
function achievfuncs.checkequipingskin(self,equipingskin) local c = 0 if equipingskin then c=1 end self.inst.checkequipingskin:set(c) end
function achievfuncs.checkdarkheart(self,darkheart) local c = 0 if darkheart then c=1 end self.inst.checkdarkheart:set(c) end
function achievfuncs.checkluckyrabbit(self,luckyrabbit) local c = 0 if luckyrabbit then c=1 end self.inst.checkluckyrabbit:set(c) end
function achievfuncs.checkgiantplant(self,giantplant) local c = 0 if giantplant then c=1 end self.inst.checkgiantplant:set(c) end
function achievfuncs.currentgiantplant(self,giantplantamount) self.inst.currentgiantplant:set(giantplantamount) end
function achievfuncs.currentgiantplantlist(self,giantplantlist) self.inst.currentgiantplantlist:set(arrayToString(giantplantlist)) end
function achievfuncs.checkoceanfish(self,oceanfish) local c = 0 if oceanfish then c=1 end self.inst.checkoceanfish:set(c) end
function achievfuncs.currentoceanfish(self,oceanfishamount) self.inst.currentoceanfish:set(oceanfishamount) end
function achievfuncs.currentoceanfishlist(self,oceanfishlist) self.inst.currentoceanfishlist:set(arrayToString(oceanfishlist)) end
function achievfuncs.checkhavebird(self,havebird) local c = 0 if havebird then c=1 end self.inst.checkhavebird:set(c) end
function achievfuncs.currenthavebird(self,havebirdamount) self.inst.currenthavebird:set(havebirdamount) end
function achievfuncs.currenthavebirdlist(self,havebirdlist) self.inst.currenthavebirdlist:set(arrayToString(havebirdlist)) end
function achievfuncs.checkglassmaker(self,glassmaker) local c = 0 if glassmaker then c=1 end self.inst.checkglassmaker:set(c) end
function achievfuncs.currentglassmaker(self,glassmakeramount) self.inst.currentglassmaker:set(glassmakeramount) end
function achievfuncs.currentglassmakerlist(self,glassmakerlist) self.inst.currentglassmakerlist:set(arrayToString(glassmakerlist, "glassmaker")) end
function achievfuncs.checkcraftnet(self,craftnet) local c = 0 if craftnet then c=1 end self.inst.checkcraftnet:set(c) end
function achievfuncs.checkiridescentgems(self,iridescentgems) local c = 0 if iridescentgems then c=1 end self.inst.checkiridescentgems:set(c) end
function achievfuncs.checkwickerbook(self,wickerbook) local c = 0 if wickerbook then c=1 end self.inst.checkwickerbook:set(c) end
function achievfuncs.currentwickerbook(self,wickerbookamount) self.inst.currentwickerbook:set(wickerbookamount) end
function achievfuncs.currentwickerbooklist(self,wickerbooklist) self.inst.currentwickerbooklist:set(arrayToString(wickerbooklist)) end

-- # STAT
function achievfuncs.checkfullsanity(self,fullsanity) local c = 0 if fullsanity then c=1 end self.inst.checkfullsanity:set(c) end
function achievfuncs.currentfullsanity(self,fullsanityamount) self.inst.currentfullsanity:set(fullsanityamount) end
function achievfuncs.checkfullhunger(self,fullhunger) local c = 0 if fullhunger then c=1 end self.inst.checkfullhunger:set(c) end
function achievfuncs.currentfullhunger(self,fullhungeramount) self.inst.currentfullhunger:set(fullhungeramount) end
function achievfuncs.checkfullmighty(self,fullmighty) local c = 0 if fullmighty then c=1 end self.inst.checkfullmighty:set(c) end
function achievfuncs.currentfullmighty(self,fullmightyamount) self.inst.currentfullmighty:set(fullmightyamount) end
function achievfuncs.checkfullsinginsp(self,fullsinginsp) local c = 0 if fullsinginsp then c=1 end self.inst.checkfullsinginsp:set(c) end
function achievfuncs.currentfullsinginsp(self,fullsinginspamount) self.inst.currentfullsinginsp:set(fullsinginspamount) end
function achievfuncs.checksanitymaxwell(self,sanitymaxwell) local c = 0 if sanitymaxwell then c=1 end self.inst.checksanitymaxwell:set(c) end
function achievfuncs.currentsanitymaxwell(self,sanitymaxwellamount) self.inst.currentsanitymaxwell:set(sanitymaxwellamount) end
function achievfuncs.checknosanity(self,nosanity) local c = 0 if nosanity then c=1 end self.inst.checknosanity:set(c) end
function achievfuncs.currentnosanity(self,nosanityamount) self.inst.currentnosanity:set(nosanityamount) end
function achievfuncs.checklunacy(self,lunacy) local c = 0 if lunacy then c=1 end self.inst.checklunacy:set(c) end
function achievfuncs.currentlunacy(self,lunacyamount) self.inst.currentlunacy:set(lunacyamount) end
function achievfuncs.checkstarve(self,starve) local c = 0 if starve then c=1 end self.inst.checkstarve:set(c) end
function achievfuncs.currentstarve(self,starveamount) self.inst.currentstarve:set(starveamount) end
function achievfuncs.checkicebody(self,icebody) local c = 0 if icebody then c=1 end self.inst.checkicebody:set(c) end
function achievfuncs.currenticebody(self,icebodyamount) self.inst.currenticebody:set(icebodyamount) end
function achievfuncs.checkfirebody(self,firebody) local c = 0 if firebody then c=1 end self.inst.checkfirebody:set(c) end
function achievfuncs.currentfirebody(self,firebodyamount) self.inst.currentfirebody:set(firebodyamount) end
function achievfuncs.checkmoistbody(self,moistbody) local c = 0 if moistbody then c=1 end self.inst.checkmoistbody:set(c) end
function achievfuncs.currentmoistbody(self,moistbodyamount) self.inst.currentmoistbody:set(moistbodyamount) end

-- # BOND
function achievfuncs.checkfriendbunny(self,friendbunny) local c = 0 if friendbunny then c=1 end self.inst.checkfriendbunny:set(c) end
function achievfuncs.currentfriendbunny(self,friendbunnyamount) self.inst.currentfriendbunny:set(friendbunnyamount) end
function achievfuncs.checkfriendmerm(self,friendmerm) local c = 0 if friendmerm then c=1 end self.inst.checkfriendmerm:set(c) end
function achievfuncs.currentfriendmerm(self,friendmermamount) self.inst.currentfriendmerm:set(friendmermamount) end
function achievfuncs.checkfriendcat(self,friendcat) local c = 0 if friendcat then c=1 end self.inst.checkfriendcat:set(c) end
function achievfuncs.currentfriendcat(self,friendcatamount) self.inst.currentfriendcat:set(friendcatamount) end
function achievfuncs.checkfriendrocky(self,friendrocky) local c = 0 if friendrocky then c=1 end self.inst.checkfriendrocky:set(c) end
function achievfuncs.currentfriendrocky(self,friendrockyamount) self.inst.currentfriendrocky:set(friendrockyamount) end
function achievfuncs.checkfriendclockwork(self,friendclockwork) local c = 0 if friendclockwork then c=1 end self.inst.checkfriendclockwork:set(c) end
function achievfuncs.currentfriendclockwork(self,friendclockworkamount) self.inst.currentfriendclockwork:set(friendclockworkamount) end
function achievfuncs.checkmandrake(self,mandrake) local c = 0 if mandrake then c=1 end self.inst.checkmandrake:set(c) end
function achievfuncs.currentmandrake(self,mandrakeamount) self.inst.currentmandrake:set(mandrakeamount) end
function achievfuncs.checksnowchester(self,snowchester) local c = 0 if snowchester then c=1 end self.inst.checksnowchester:set(c) end
function achievfuncs.checksmallbird(self,smallbird) local c = 0 if smallbird then c=1 end self.inst.checksmallbird:set(c) end
function achievfuncs.checkfriendlylavae(self,friendlylavae) local c = 0 if friendlylavae then c=1 end self.inst.checkfriendlylavae:set(c) end

-- # TALK
function achievfuncs.checkpigkingtrading(self,pigkingtrading) local c = 0 if pigkingtrading then c=1 end self.inst.checkpigkingtrading:set(c) end
function achievfuncs.currentpigkingtrading(self,pigkingtradingamount) self.inst.currentpigkingtrading:set(pigkingtradingamount) end
function achievfuncs.checkicetrading(self,icetrading) local c = 0 if icetrading then c=1 end self.inst.checkicetrading:set(c) end
function achievfuncs.currenticetrading(self,icetradingamount) self.inst.currenticetrading:set(icetradingamount) end
function achievfuncs.checkpearltrading(self,pearltrading) local c = 0 if pearltrading then c=1 end self.inst.checkpearltrading:set(c) end
function achievfuncs.currentpearltrading(self,pearltradingamount) self.inst.currentpearltrading:set(pearltradingamount) end
function achievfuncs.checkwagstafftrading(self,wagstafftrading) local c = 0 if wagstafftrading then c=1 end self.inst.checkwagstafftrading:set(c) end
function achievfuncs.currentwagstafftrading(self,wagstafftradingamount) self.inst.currentwagstafftrading:set(wagstafftradingamount) end
function achievfuncs.checkbuygears(self,buygears) local c = 0 if buygears then c=1 end self.inst.checkbuygears:set(c) end
function achievfuncs.checkdance(self,dance) local c = 0 if dance then c=1 end self.inst.checkdance:set(c) end
function achievfuncs.currentdance(self,danceamount) self.inst.currentdance:set(danceamount) end
function achievfuncs.checkfloatparty(self,floatparty) local c = 0 if floatparty then c=1 end self.inst.checkfloatparty:set(c) end
function achievfuncs.checkpearlparty(self,pearlparty) local c = 0 if pearlparty then c=1 end self.inst.checkpearlparty:set(c) end
function achievfuncs.checkpipspook(self,pipspook) local c = 0 if pipspook then c=1 end self.inst.checkpipspook:set(c) end
function achievfuncs.currentpipspook(self,pipspookamount) self.inst.currentpipspook:set(pipspookamount) end
function achievfuncs.checkdodgecharlie(self,dodgecharlie) local c = 0 if dodgecharlie then c=1 end self.inst.checkdodgecharlie:set(c) end
function achievfuncs.currentdodgecharlie(self,dodgecharlieamount) self.inst.currentdodgecharlie:set(dodgecharlieamount) end

-- # VILE
function achievfuncs.checkkillbutterfly(self,killbutterfly) local c = 0 if killbutterfly then c=1 end self.inst.checkkillbutterfly:set(c) end
function achievfuncs.currentkillbutterfly(self,killbutterflyamount) self.inst.currentkillbutterfly:set(killbutterflyamount) end
function achievfuncs.checkkillbird(self,killbird) local c = 0 if killbird then c=1 end self.inst.checkkillbird:set(c) end
function achievfuncs.currentkillbird(self,killbirdamount) self.inst.currentkillbird:set(killbirdamount) end
function achievfuncs.checkkillgloomer(self,killgloomer) local c = 0 if killgloomer then c=1 end self.inst.checkkillgloomer:set(c) end
function achievfuncs.checkkillchester(self,killchester) local c = 0 if killchester then c=1 end self.inst.checkkillchester:set(c) end
function achievfuncs.checkkillhutch(self,killhutch) local c = 0 if killhutch then c=1 end self.inst.checkkillhutch:set(c) end
function achievfuncs.checkkillfriendlyfruitfly(self,killfriendlyfruitfly) local c = 0 if killfriendlyfruitfly then c=1 end self.inst.checkkillfriendlyfruitfly:set(c) end
function achievfuncs.checkkillotterhouse(self,killotterhouse) local c = 0 if killotterhouse then c=1 end self.inst.checkkillotterhouse:set(c) end
function achievfuncs.checkhitstagehand(self,hitstagehand) local c = 0 if hitstagehand then c=1 end self.inst.checkhitstagehand:set(c) end
function achievfuncs.checkhauntpig(self,hauntpig) local c = 0 if hauntpig then c=1 end self.inst.checkhauntpig:set(c) end
function achievfuncs.currenthauntpig(self,hauntpig) self.inst.currenthauntpig:set(hauntpig) end
function achievfuncs.checkpasstrinket(self,passtrinket) local c = 0 if passtrinket then c=1 end self.inst.checkpasstrinket:set(c) end
function achievfuncs.checkwaterballoon(self,waterballoon) local c = 0 if waterballoon then c=1 end self.inst.checkwaterballoon:set(c) end
function achievfuncs.currentwaterballoon(self,waterballoonamount) self.inst.currentwaterballoon:set(waterballoonamount) end
function achievfuncs.checkvilewormwood(self,vilewormwood) local c = 0 if vilewormwood then c=1 end self.inst.checkvilewormwood:set(c) end
function achievfuncs.currentvilewormwood(self,vilewormwoodamount) self.inst.currentvilewormwood:set(vilewormwoodamount) end
function achievfuncs.checkplaywes(self,playwes) local c = 0 if playwes then c=1 end self.inst.checkplaywes:set(c) end

-- # SLAY
function achievfuncs.checklightninggoat(self,lightninggoat) local c = 0 if lightninggoat then c=1 end self.inst.checklightninggoat:set(c) end
function achievfuncs.currentlightninggoat(self,lightninggoatamount) self.inst.currentlightninggoat:set(lightninggoatamount) end
function achievfuncs.checkbeefalo(self,beefalo) local c = 0 if beefalo then c=1 end self.inst.checkbeefalo:set(c) end
function achievfuncs.currentbeefalo(self,beefaloamount) self.inst.currentbeefalo:set(beefaloamount) end
function achievfuncs.checkkoalefant(self,koalefant) local c = 0 if koalefant then c=1 end self.inst.checkkoalefant:set(c) end
function achievfuncs.currentkoalefant(self,koalefant) self.inst.currentkoalefant:set(koalefant) end
function achievfuncs.checksaladmander(self,saladmander) local c = 0 if saladmander then c=1 end self.inst.checksaladmander:set(c) end
function achievfuncs.currentsaladmander(self,saladmander) self.inst.currentsaladmander:set(saladmander) end
function achievfuncs.checkhorrorhound(self,horrorhound) local c = 0 if horrorhound then c=1 end self.inst.checkhorrorhound:set(c) end
function achievfuncs.currenthorrorhound(self,horrorhound) self.inst.currenthorrorhound:set(horrorhound) end
function achievfuncs.checkwerepig(self,werepig) local c = 0 if werepig then c=1 end self.inst.checkwerepig:set(c) end
function achievfuncs.currentwerepig(self,werepig) self.inst.currentwerepig:set(werepig) end
function achievfuncs.checkbeardlord(self,beardlord) local c = 0 if beardlord then c=1 end self.inst.checkbeardlord:set(c) end
function achievfuncs.currentbeardlord(self,beardlord) self.inst.currentbeardlord:set(beardlord) end
function achievfuncs.checksnurtle(self,snurtle) local c = 0 if snurtle then c=1 end self.inst.checksnurtle:set(c) end
function achievfuncs.currentsnurtle(self,snurtle) self.inst.currentsnurtle:set(snurtle) end
function achievfuncs.checkmosling(self,mosling) local c = 0 if mosling then c=1 end self.inst.checkmosling:set(c) end
function achievfuncs.currentmosling(self,moslingamount) self.inst.currentmosling:set(moslingamount) end
-- # SLAY2
function achievfuncs.checkvulture(self,vulture) local c = 0 if vulture then c=1 end self.inst.checkvulture:set(c) end
function achievfuncs.currentvulture(self,vultureamount) self.inst.currentvulture:set(vultureamount) end
function achievfuncs.checkmoonfrog(self,moonfrog) local c = 0 if moonfrog then c=1 end self.inst.checkmoonfrog:set(c) end
function achievfuncs.currentmoonfrog(self,moonfrogamount) self.inst.currentmoonfrog:set(moonfrogamount) end
function achievfuncs.checkdarkcentipede(self,darkcentipede) local c = 0 if darkcentipede then c=1 end self.inst.checkdarkcentipede:set(c) end
function achievfuncs.checkcavemite(self,cavemite) local c = 0 if cavemite then c=1 end self.inst.checkcavemite:set(c) end
function achievfuncs.currentcavemite(self,cavemiteamount) self.inst.currentcavemite:set(cavemiteamount) end

-- # DUEL
function achievfuncs.checklavae(self,lavae) local c = 0 if lavae then c=1 end self.inst.checklavae:set(c) end
function achievfuncs.currentlavae(self,lavae) self.inst.currentlavae:set(lavae) end
function achievfuncs.checkspiderqueen(self,spiderqueen) local c = 0 if spiderqueen then c=1 end self.inst.checkspiderqueen:set(c) end
function achievfuncs.currentspiderqueen(self,spiderqueen) self.inst.currentspiderqueen:set(spiderqueen) end
function achievfuncs.checkpengul(self,pengul) local c = 0 if pengul then c=1 end self.inst.checkpengul:set(c) end
function achievfuncs.currentpengul(self,pengul) self.inst.currentpengul:set(pengul) end
function achievfuncs.checktentapillar(self,tentapillar) local c = 0 if tentapillar then c=1 end self.inst.checktentapillar:set(c) end
function achievfuncs.currenttentapillar(self,tentapillaramount) self.inst.currenttentapillar:set(tentapillaramount) end
function achievfuncs.checkseaweed(self,seaweed) local c = 0 if seaweed then c=1 end self.inst.checkseaweed:set(c) end
function achievfuncs.currentseaweed(self,seaweed) self.inst.currentseaweed:set(seaweed) end
function achievfuncs.checkgrassgator(self,grassgator) local c = 0 if grassgator then c=1 end self.inst.checkgrassgator:set(c) end
function achievfuncs.currentgrassgator(self,grassgator) self.inst.currentgrassgator:set(grassgator) end
function achievfuncs.checkewecus(self,ewecus) local c = 0 if ewecus then c=1 end self.inst.checkewecus:set(c) end
function achievfuncs.checkghost(self,ghost) local c = 0 if ghost then c=1 end self.inst.checkghost:set(c) end
function achievfuncs.checkgnarwail(self,gnarwail) local c = 0 if gnarwail then c=1 end self.inst.checkgnarwail:set(c) end
function achievfuncs.checkrockjaw(self,rockjaw) local c = 0 if rockjaw then c=1 end self.inst.checkrockjaw:set(c) end
function achievfuncs.checkbigworm(self,bigworm) local c = 0 if bigworm then c=1 end self.inst.checkbigworm:set(c) end
function achievfuncs.checksoloyourself(self,soloyourself) local c = 0 if soloyourself then c=1 end self.inst.checksoloyourself:set(c) end

-- # BOSS
function achievfuncs.checksantaklaus(self,santaklaus) local c = 0 if santaklaus then c=1 end self.inst.checksantaklaus:set(c) end
function achievfuncs.checkdragonflybeequeen(self,dragonflybeequeen) local c = 0 if dragonflybeequeen then c=1 end self.inst.checkdragonflybeequeen:set(c) end
function achievfuncs.checkdragonflybeequeen1(self,dragonflybeequeen1) local c = 0 if dragonflybeequeen1 then c=1 end self.inst.checkdragonflybeequeen1:set(c) end
function achievfuncs.checkdragonflybeequeen2(self,dragonflybeequeen2) local c = 0 if dragonflybeequeen2 then c=1 end self.inst.checkdragonflybeequeen2:set(c) end
function achievfuncs.checkmalbatrosscrabking(self,malbatrosscrabking) local c = 0 if malbatrosscrabking then c=1 end self.inst.checkmalbatrosscrabking:set(c) end
function achievfuncs.checkmalbatrosscrabking1(self,malbatrosscrabking1) local c = 0 if malbatrosscrabking1 then c=1 end self.inst.checkmalbatrosscrabking1:set(c) end
function achievfuncs.checkmalbatrosscrabking2(self,malbatrosscrabking2) local c = 0 if malbatrosscrabking2 then c=1 end self.inst.checkmalbatrosscrabking2:set(c) end
function achievfuncs.checkshadowpieche(self,shadowpieche) local c = 0 if shadowpieche then c=1 end self.inst.checkshadowpieche:set(c) end
function achievfuncs.checkshadowknight(self,shadowknight) local c = 0 if shadowknight then c=1 end self.inst.checkshadowknight:set(c) end
function achievfuncs.checkshadowbishop(self,shadowbishop) local c = 0 if shadowbishop then c=1 end self.inst.checkshadowbishop:set(c) end
function achievfuncs.checkshadowrook(self,shadowrook) local c = 0 if shadowrook then c=1 end self.inst.checkshadowrook:set(c) end
function achievfuncs.checkancientguardianancientfuelweaver(self,ancientguardianancientfuelweaver) local c = 0 if ancientguardianancientfuelweaver then c=1 end self.inst.checkancientguardianancientfuelweaver:set(c) end
function achievfuncs.checkancientguardianancientfuelweaver1(self,ancientguardianancientfuelweaver1) local c = 0 if ancientguardianancientfuelweaver1 then c=1 end self.inst.checkancientguardianancientfuelweaver1:set(c) end
function achievfuncs.checkancientguardianancientfuelweaver2(self,ancientguardianancientfuelweaver2) local c = 0 if ancientguardianancientfuelweaver2 then c=1 end self.inst.checkancientguardianancientfuelweaver2:set(c) end
function achievfuncs.checkcelestialchampion(self,celestialchampion) local c = 0 if celestialchampion then c=1 end self.inst.checkcelestialchampion:set(c) end
function achievfuncs.checkcelestialscion(self,celestialscion) local c = 0 if celestialscion then c=1 end self.inst.checkcelestialscion:set(c) end
function achievfuncs.checkguardtower(self,guardtower) local c = 0 if guardtower then c=1 end self.inst.checkguardtower:set(c) end
function achievfuncs.currentguardtower(self,guardtower) self.inst.currentguardtower:set(guardtower) end
function achievfuncs.checkwerepigs(self,werepigs) local c = 0 if werepigs then c=1 end self.inst.checkwerepigs:set(c) end
function achievfuncs.checkwerepigs1(self,werepigs1) local c = 0 if werepigs1 then c=1 end self.inst.checkwerepigs1:set(c) end
function achievfuncs.checkwerepigs2(self,werepigs2) local c = 0 if werepigs2 then c=1 end self.inst.checkwerepigs2:set(c) end
function achievfuncs.checktoadstool(self,toadstool) local c = 0 if toadstool then c=1 end self.inst.checktoadstool:set(c) end
function achievfuncs.checktwinterror(self,twinterror) local c = 0 if twinterror then c=1 end self.inst.checktwinterror:set(c) end
function achievfuncs.checktwinterror1(self,twinterror1) local c = 0 if twinterror1 then c=1 end self.inst.checktwinterror1:set(c) end
function achievfuncs.checktwinterror2(self,twinterror2) local c = 0 if twinterror2 then c=1 end self.inst.checktwinterror2:set(c) end
function achievfuncs.checkseasonboss(self,seasonboss) local c = 0 if seasonboss then c=1 end self.inst.checkseasonboss:set(c) end
function achievfuncs.checkbosswinter(self,bosswinter) local c = 0 if bosswinter then c=1 end self.inst.checkbosswinter:set(c) end
function achievfuncs.checkbossspring(self,bossspring) local c = 0 if bossspring then c=1 end self.inst.checkbossspring:set(c) end
function achievfuncs.checkbosssummer(self,bosssummer) local c = 0 if bosssummer then c=1 end self.inst.checkbosssummer:set(c) end
function achievfuncs.checkbossautumn(self,bossautumn) local c = 0 if bossautumn then c=1 end self.inst.checkbossautumn:set(c) end
function achievfuncs.checkmutationboss(self,mutationboss) local c = 0 if mutationboss then c=1 end self.inst.checkmutationboss:set(c) end
function achievfuncs.checkmutatedwarg(self,mutatedwarg) local c = 0 if mutatedwarg then c=1 end self.inst.checkmutatedwarg:set(c) end
function achievfuncs.checkmutatedbearger(self,mutatedbearger) local c = 0 if mutatedbearger then c=1 end self.inst.checkmutatedbearger:set(c) end
function achievfuncs.checkmutateddeerclops(self,mutateddeerclops) local c = 0 if mutateddeerclops then c=1 end self.inst.checkmutateddeerclops:set(c) end
function achievfuncs.checkbossautumn(self,bossautumn) local c = 0 if bossautumn then c=1 end self.inst.checkbossautumn:set(c) end

-- # MISC
function achievfuncs.checkopentreasure(self,opentreasure) local c = 0 if opentreasure then c=1 end self.inst.checkopentreasure:set(c) end
function achievfuncs.checkpiratechest(self,piratechest) local c = 0 if piratechest then c=1 end self.inst.checkpiratechest:set(c) end
function achievfuncs.currentpiratechest(self,piratechestamount) self.inst.currentpiratechest:set(piratechestamount) end
function achievfuncs.checksitting(self,sitting) local c = 0 if sitting then c=1 end self.inst.checksitting:set(c) end
function achievfuncs.checksacrificecotl(self,sacrificecotl) local c = 0 if sacrificecotl then c=1 end self.inst.checksacrificecotl:set(c) end
function achievfuncs.checksewing(self,sewing) local c = 0 if sewing then c=1 end self.inst.checksewing:set(c) end
function achievfuncs.checkwither(self,wither) local c = 0 if wither then c=1 end self.inst.checkwither:set(c) end
function achievfuncs.currentwither(self,wither) self.inst.currentwither:set(wither) end
function achievfuncs.checkminemoon(self,minemoon) local c = 0 if minemoon then c=1 end self.inst.checkminemoon:set(c) end
function achievfuncs.currentminemoon(self,minemoon) self.inst.currentminemoon:set(minemoon) end
function achievfuncs.checkbirchnut(self,birchnut) local c = 0 if birchnut then c=1 end self.inst.checkbirchnut:set(c) end
function achievfuncs.currentbirchnut(self,birchnut) self.inst.currentbirchnut:set(birchnut) end
function achievfuncs.checkaquarium(self,aquarium) local c = 0 if aquarium then c=1 end self.inst.checkaquarium:set(c) end
function achievfuncs.checkbernie(self,bernie) local c = 0 if bernie then c=1 end self.inst.checkbernie:set(c) end
function achievfuncs.checkfoodwarly(self,foodwarly) local c = 0 if foodwarly then c=1 end self.inst.checkfoodwarly:set(c) end
function achievfuncs.currentfoodwarly(self,foodwarlyamount) self.inst.currentfoodwarly:set(foodwarlyamount) end
function achievfuncs.currentfoodwarlylist(self,foodwarlylist) self.inst.currentfoodwarlylist:set(arrayToString(foodwarlylist)) end

-- # MILE
function achievfuncs.checkintogame(self,intogame) local c = 0 if intogame then c=1 end self.inst.checkintogame:set(c) end
function achievfuncs.checkstarspent(self,starspent) local c = 0 if starspent then c=1 end self.inst.checkstarspent:set(c) end
function achievfuncs.currentstarspent(self,starspentamount) self.inst.currentstarspent:set(starspentamount) end
function achievfuncs.checkdidtask(self,didtask) local c = 0 if didtask then c=1 end self.inst.checkdidtask:set(c) end
function achievfuncs.currentdidtask(self,didtaskamount) self.inst.currentdidtask:set(didtaskamount) end
function achievfuncs.checkoldage(self,oldage) local c = 0 if oldage then c=1 end self.inst.checkoldage:set(c) end
function achievfuncs.currentoldage(self,oldageamount) self.inst.currentoldage:set(oldageamount) end
function achievfuncs.checkwalkalot(self,walkalot) local c = 0 if walkalot then c=1 end self.inst.checkwalkalot:set(c) end
function achievfuncs.currentwalkalot(self,walkalotamount) self.inst.currentwalkalot:set(walkalotamount) end
function achievfuncs.checkstopalot(self,stopalot) local c = 0 if stopalot then c=1 end self.inst.checkstopalot:set(c) end
function achievfuncs.currentstopalot(self,stopalotamount) self.inst.currentstopalot:set(stopalotamount) end
function achievfuncs.checkcaveage(self,caveage) local c = 0 if caveage then c=1 end self.inst.checkcaveage:set(c) end
function achievfuncs.currentcaveage(self,caveageamount) self.inst.currentcaveage:set(caveageamount) end
function achievfuncs.checkwaterage(self,waterage) local c = 0 if waterage then c=1 end self.inst.checkwaterage:set(c) end
function achievfuncs.currentwaterage(self,waterageamount) self.inst.currentwaterage:set(waterageamount) end
function achievfuncs.checkrider(self,rider) local c = 0 if rider then c=1 end self.inst.checkrider:set(c) end
function achievfuncs.currentrider(self,rideramount) self.inst.currentrider:set(rideramount) end
function achievfuncs.checkriderwoby(self,riderwoby) local c = 0 if riderwoby then c=1 end self.inst.checkriderwoby:set(c) end
function achievfuncs.currentriderwoby(self,riderwobyamount) self.inst.currentriderwoby:set(riderwobyamount) end
function achievfuncs.checkwalkturf(self,walkturf) local c = 0 if walkturf then c=1 end self.inst.checkwalkturf:set(c) end
function achievfuncs.currentwalkturf(self,walkturfamount) self.inst.currentwalkturf:set(walkturfamount) end
function achievfuncs.currentwalkturflist(self,walkturflist) self.inst.currentwalkturflist:set(arrayToString(walkturflist, "turf")) end
function achievfuncs.checkcomplete(self,complete) local c = 0 if complete then c=1 end self.inst.checkcomplete:set(c) end
function achievfuncs.currentcomplete(self,completeamount) self.inst.currentcomplete:set(completeamount) end

-- # TASK
function achievfuncs.checktask1(self,task1) local c = 0 if task1 then c=1 end self.inst.checktask1:set(c) end
function achievfuncs.checktask2(self,task2) local c = 0 if task2 then c=1 end self.inst.checktask2:set(c) end
function achievfuncs.checktask3(self,task3) local c = 0 if task3 then c=1 end self.inst.checktask3:set(c) end
function achievfuncs.checktask4(self,task4) local c = 0 if task4 then c=1 end self.inst.checktask4:set(c) end
function achievfuncs.checktask5(self,task5) local c = 0 if task5 then c=1 end self.inst.checktask5:set(c) end
function achievfuncs.currenttask5(self,task5amount) self.inst.currenttask5:set(task5amount) end
function achievfuncs.checktask6(self,task6) local c = 0 if task6 then c=1 end self.inst.checktask6:set(c) end
function achievfuncs.currenttask6(self,task6amount) self.inst.currenttask6:set(task6amount) end
function achievfuncs.gettaskprize1(self,taskprize1) self.inst.taskprize1:set(taskprize1) end
function achievfuncs.gettaskprize2(self,taskprize2) self.inst.taskprize2:set(taskprize2) end
function achievfuncs.gettaskprize3(self,taskprize3) self.inst.taskprize3:set(taskprize3) end
function achievfuncs.gettaskprize4(self,taskprize4) self.inst.taskprize4:set(taskprize4) end

function achievfuncs.getachievfunction()
	local data = {
		taskprize1 = achievfuncs.gettaskprize1,
		taskprize2 = achievfuncs.gettaskprize2,
		taskprize3 = achievfuncs.gettaskprize3,
		taskprize4 = achievfuncs.gettaskprize4,
	}
	for achname, ach in pairs(ach_lists) do
		data[achname] = achievfuncs["check"..achname]
		if data[achname] == nil then
			local name = achname
			data[achname] = function(self, completed)
				self.inst["check"..name]:set(completed and 1 or 0)
			end
		end
		if ach.current then
			data[achname.."amount"] = achievfuncs["current"..achname]
			if data[achname.."amount"] == nil then
				local name = achname
				data[achname.."amount"] = function(self, amount)
					self.inst["current"..name]:set(amount or 0)
				end
			end
		end
		if ach.list then
			data[achname.."list"] = achievfuncs["current"..achname.."list"]
		end
	end
	return data
end

return achievfuncs
