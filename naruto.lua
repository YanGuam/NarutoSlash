module("extensions.naruto", package.seeall)
extension = sgs.Package("naruto")

hynaruto = sgs.General(extension, "hynaruto", "wu")
hysasuke = sgs.General(extension, "hysasuke", "wu", "3")
hysakura = sgs.General(extension, "hysakura", "wu", "3", false)
hykakasi = sgs.General(extension, "hykakasi", "wu", "3")
hyrii = sgs.General(extension, "hyrii", "wu")
hygaara = sgs.General(extension, "hygaara", "shu")
hyneiji = sgs.General(extension, "hyneiji", "wu", "3")

hyfennu = sgs.CreateTriggerSkill{
	name = "hyfennu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if card:isKindOf("Slash") and card:isRed() then
				local room = player:getRoom()
				if room:askForSkillInvoke(player, "hyfennu", data) then
					local judge = sgs.JudgeStruct()
					judge.who = player
					judge.pattern = sgs.QRegExp("(.*):(diamond):(.*)")
					judge.good = true
					judge.reason = self:objectName()
					room:judge(judge)
					if judge:isGood() then
						local hurt = damage.damage
						damage.damage = hurt + 1
						data:setValue(damage)
					end
				end
			end
		end
	end,
}

hyfenshen = sgs.CreateTriggerSkill{
	name = "hyfenshen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return end
		local room = player:getRoom()
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:inMyAttackRange(p) and not use.to:contains(p) and not sgs.Sanguosha:isProhibited(player,p,sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)) then
				room:setPlayerFlag(p, "fenshenslash")
				targets:append(p)
			end
		end
		if targets:isEmpty() then return end
		if not player:askForSkillInvoke(self:objectName()) then return end
		local target=room:askForPlayerChosen(player,targets,self:objectName())
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("fenshenslash") then
				room:setPlayerFlag(p, "-fenshenslash")
			end
		end
		use.to:append(target)
		data:setValue(use)
		room:broadcastSkillInvoke(self:objectName())
	end,
}

sgs.hyhuoshuPattern = {"diamond", "heart"}
hyhuoshu = sgs.CreateViewAsSkill{
	name = "hyhuoshu",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected < 1 then
			local suit = to_select:getSuit()
			if sgs.hyhuoshuPattern[1] == "true" and suit == sgs.Card_Diamond then
				return true
			elseif sgs.hyhuoshuPattern[2] == "true" and suit == sgs.Card_Heart then
				return true
			end
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local new_card = nil
			local suit = card:getSuit()
			local number = card:getNumber()
			if suit == sgs.Card_Diamond then
				new_card = sgs.Sanguosha:cloneCard("FireAttack", suit, number)
			elseif suit == sgs.Card_Heart then
				new_card = sgs.Sanguosha:cloneCard("fire_slash", suit, number)
			end
			if new_card then
				new_card:setSkillName(self:objectName())
				new_card:addSubcard(card)
			end
			return new_card
		end
	end,
	enabled_at_play = function(self, player)
		sgs.hyhuoshuPattern = {"false", "false"}
		local flag = false
		if sgs.Slash_IsAvailable(player) then
			sgs.hyhuoshuPattern[1] = "true"
			sgs.hyhuoshuPattern[2] = "true"
			flag = true
		else
			sgs.hyhuoshuPattern[1] = "true"
			flag = true
		end
		return flag
	end,
	enabled_at_response = function(self, player, pattern)
		sgs.hyhuoshuPattern = {"false", "false"}
		if pattern == "slash" then
			sgs.hyhuoshuPattern[2] = "true"
			return true
		end
	end,
}

hyxielun = sgs.CreateViewAsSkill{
	name = "hyxielun",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Club
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local chain = sgs.Sanguosha:cloneCard("iron_chain", suit, point)
			chain:addSubcard(id)
			chain:setSkillName(self:objectName())
			return chain
		end
	end,
}

hyzhouyin = sgs.CreateFilterSkill{
	name = "hyzhouyin",
	view_filter = function(self, to_select)
		local suit = to_select:getSuit()
		return suit == sgs.Card_Spade
	end,
	view_as = function(self, card)
		local id = card:getId()
		local suit = card:getSuit()
		local point = card:getNumber()
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", suit, point)
		analeptic:setSkillName(self:objectName())
		local vs_card = sgs.Sanguosha:getWrappedCard(id)
		vs_card:takeOver(analeptic)
		return vs_card
	end,
}

hyzhangxianCard = sgs.CreateSkillCard{
	name = "hyzhangxianCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			local count = to_select:getMark("@sakura")
			return count == 0
		end
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local effect = sgs.CardEffectStruct()
		effect.card = self
		effect.from = source
		effect.to = target
		room:cardEffect(effect)
	end,
	on_effect = function(self, effect)
		local dest = effect.to
		dest:gainMark("@sakura")
	end,
}

hyzhangxianVS = sgs.CreateViewAsSkill{
	name = "hyzhangxianVS",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:objectName() == "peach"
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local zx_card = hyzhangxianCard:clone()
			zx_card:addSubcard(card)
			return zx_card
		end
	end,
}

hyzhangxian = sgs.CreateTriggerSkill{
	name = "hyzhangxian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TurnStart},
	view_as_skill = hyzhangxianVS,
	on_trigger = function(self, event, player, data)
		if player:getHandcardNum() >= player:getHp() then
			local room = player:getRoom()
			if player:isWounded() then
				local choice = room:askForChoice(player, self:objectName(), "recover+gainmaxhp")
				if choice == "gainmaxhp" then
					local mhp = sgs.QVariant()
					local count = player:getMaxHp()
					mhp:setValue(count+1)
					room:setPlayerProperty(player, "maxhp", mhp)
					local msg = sgs.LogMessage()
					msg.type = "#upgrade"
					msg.from = player
					msg.arg = 1
					room:sendLog(msg)
				elseif choice == "recover" then
					local recover = sgs.RecoverStruct()
					room:recover(player, recover)
				end
			else
				local mhp = sgs.QVariant()
				local count = player:getMaxHp()
				mhp:setValue(count+1)
				room:setPlayerProperty(player, "maxhp", mhp)
				local msg = sgs.LogMessage()
				msg.type = "#upgrade"
				msg.from = player
				msg.arg = 1
				room:sendLog(msg)
			end
		end
		player:loseAllMarks("@sakura")
	end,
	can_trigger = function(self, target)
		return target:getMark("@sakura") > 0 
	end,
}

hyyinghua = sgs.CreateTriggerSkill{
	name = "hyyinghua",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		if player:isWounded() then
			if not player:isKongcheng() then
				if player:askForSkillInvoke("hyyinghua", data) then
					local room = player:getRoom()
					if room:askForCard(player, ".", "~hyyinghua", data, sgs.CardDiscarded) then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
					end
				end
			end
		end
		return false
	end,
}

hyfengchi = sgs.CreateTriggerSkill{
	name = "hyfengchi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw) then
		if not player:askForSkillInvoke(self:objectName()) then return end
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			slash:setSkillName(self:objectName())
			local use = sgs.CardUseStruct()
			use.card = slash
			use.from = player
			use.to:append(target)
			room:useCard(use,false)
			player:skip(sgs.Player_Draw)
		end
	end,
}

hydianche = sgs.CreateTriggerSkill{
	name = "hydianche",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged, sgs.Predamage, sgs.Damage},
	on_trigger = function(self, event, player, data)
		if event == sgs.Damaged or event == sgs.Damage then
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Thunder then
				local room = player:getRoom()
				if room:askForSkillInvoke(player, self:objectName()) then
					local x = damage.damage
					for i = 0, x-1, 1 do
						local move = sgs.CardsMoveStruct()
						local cardA = room:drawCard()
						move.card_ids:append(cardA)
						local cardB = room:drawCard()
						move.card_ids:append(cardB)
						move.to = player
						move.to_place = sgs.Player_PlaceHand
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, player:objectName(), self:objectName(), nil)
						room:moveCards(move, false)
						if not move.card_ids:isEmpty() then
							local flag = true
							while flag do
								flag = room:askForYiji(player, move.card_ids)
							end
						end
					end
				end
			end
		end
		if event == sgs.Predamage then
			local effect = data:toDamage()
			if effect.nature ~= sgs.DamageStruct_Thunder then
				effect.nature = sgs.DamageStruct_Thunder 
				data:setValue(effect)
			end
			return false
		end
	end,
}

hyningtongCard = sgs.CreateSkillCard{
	name = "hyningtongCard",
	target_fixed = true,
	will_throw = false,
	on_effect = function(self, effect)
	end,
}

hyningtongVS = sgs.CreateViewAsSkill{
	name = "hyningtongVS",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isRed() and not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = hyningtongCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@hyningtong"
	end,
}

hyningtong = sgs.CreateTriggerSkill{
	name = "hyningtong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.AskForRetrial},
	view_as_skill = hyningtongVS,
	on_trigger = function(self, event, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			local judge = data:toJudge()
			local room = player:getRoom()
			local card = room:askForCard(player, "@hyningtong", nil, data, sgs.AskForRetrial)
			room:retrial(card, player, judge, self:objectName())
			return false
		end
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				return not target:isKongcheng()
			end
		end
		return false
	end,
}

hybadun = sgs.CreateTriggerSkill{
	name = "hybadun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed,sgs.ConfirmDamage,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local source = use.from
			if source:objectName() == player:objectName() then
				local card = use.card
				if card:isKindOf("Slash") then
					local phase = player:getPhase()
					if phase == sgs.Player_Play then
						local count = player:getMark("@men")
						if  count < 8 then
							player:gainMark("@men")
						end
					end
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			local slash = damage.card
			if slash and slash:isKindOf("Slash") then
				if player:getPhase() == sgs.Player_Play then
					local x = player:getMark("@men")
					if x > 0 then
						damage.damage = damage.damage + x
						data:setValue(damage)
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local x = player:getMark("@men")
				if x > 0 then
					local room = player:getRoom()
					if x > 7 then
						local damage = sgs.DamageStruct()
						damage.from = player
						room:killPlayer(player, damage)
					else
						player:loseMark("@men", x)
					end
				end
			end
		end
		return false
	end,
}

hyliandanCard = sgs.CreateSkillCard{
	name = "hyliandanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
	    room:broadcastSkillInvoke("hyliandan")
		room:loseHp(source, 1)
		if source:isAlive() then
			room:setPlayerMark(targets[1],"liandantarget",1)
			room:setFixedDistance(source,targets[1],1)
		end
	end,
}

hyliandanVS = sgs.CreateViewAsSkill{
	name = "hyliandanVS",
	n = 0,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		return hyliandanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#hyliandanCard")
	end,
}

hyliandan = sgs.CreateTriggerSkill{
	name = "hyliandan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.SlashMissed},
	view_as_skill = hyliandanVS,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_NotActive then return end
			local room = player:getRoom()
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("liandantarget")>0 then
					room:setPlayerMark(p, "liandantarget", 0)
					room:setFixedDistance(player, p, -1)
				end
			end
		elseif event == sgs.SlashMissed then
			local room = player:getRoom()
			local effect = data:toSlashEffect()
			local dest = effect.to
			if dest:isAlive() then
				if effect.from:canSlash(dest, nil, false) then
					local prompt = "InvokeForSlash"
					room:askForUseSlashTo(player, dest, prompt)
				end
			end
		end
        return false
	end,
	priority = -2,
}

hyroubo = sgs.CreateFilterSkill{
	name = "hyroubo",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		if place == sgs.Player_PlaceHand then
			return to_select:isKindOf("EquipCard")
		end
		return false
	end,
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local id = card:getId()
		local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
		slash:setSkillName(self:objectName())
		local vs_card = sgs.Sanguosha:getWrappedCard(id)
		vs_card:takeOver(slash)
		return vs_card
	end,
}

hyshakai = sgs.CreateTriggerSkill{
	name = "hyshakai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local point = damage.damage
		if point > 1 then
			damage.damage = 1
			data:setValue(damage)
		end
		return false
	end,
	priority = -2,
}

hyjiamei = sgs.CreateTriggerSkill{
	name = "hyjiamei", 
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:gainMark("@waked")
		room:loseMaxHp(player)
		room:detachSkillFromPlayer(player, "hyshakai")
		room:acquireSkill(player, "hyshouhe", true)
		room:acquireSkill(player, "hyjueyu", true)
		room:setPlayerMark(player, "jiamei", 1)
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getMark("jiamei") == 0 then
					if target:getPhase() == sgs.Player_Start then
						local self_weapon = target:getWeapon()
						if self_weapon then 
							return true
						end
					end
				end
			end
		end
		return false
	end,
}

hyshouhe = sgs.CreateTriggerSkill{
	name = "hyshouhe",
	frequency = sgs.Skill_NotFrequency,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				player:turnOver()
				local all_players = room:getAllPlayers()
				for _,victim in sgs.qlist(all_players) do
					local damage = sgs.DamageStruct()
					damage.from = player
					damage.to = victim
					room:damage(damage)
				end
			end
		end
	end,
}

hyjueyu = sgs.CreateTriggerSkill{
	name = "hyjueyu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageForseen},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		return damage.nature ~= sgs.DamageStruct_Fire
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				return target:getHp() == 1
			end
		end
	end,
}

local shouhe = sgs.Sanguosha:getSkill("hyshouhe")
if not shouhe then
	local skillList = sgs.SkillList()
	skillList:append(hyshouhe)
	sgs.Sanguosha:addSkills(skillList)
end

local jueyu = sgs.Sanguosha:getSkill("hyjueyu")
if not jueyu then
	local skillList = sgs.SkillList()
	skillList:append(hyjueyu)
	sgs.Sanguosha:addSkills(skillList)
end

hybaiyanCard = sgs.CreateSkillCard{
	name = "hybaiyanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:fillAG(target:handCards(), source)
		local card_id = room:askForAG(source, target:handCards(), true, "hybaiyan")
		source:invoke("clearAG")
		local getcard = sgs.Sanguosha:getCard(card_id)
		if getcard:getSuit() == sgs.Card_Diamond then
			room:obtainCard(source, card_id, true)
		end
	end,
}

hybaiyan = sgs.CreateViewAsSkill{
	name = "hybaiyan",
	n = 0,
	view_as = function(self, cards)
		local card = hybaiyanCard:clone()
		card:setSkillName(self:objectName())
		return card 
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#hybaiyanCard")
	end,
}

hynaruto:addSkill(hyfennu)
hynaruto:addSkill(hyfenshen)

hysasuke:addSkill(hyhuoshu)
hysasuke:addSkill(hyxielun)
hysasuke:addSkill(hyzhouyin)

hysakura:addSkill(hyzhangxian)
hysakura:addSkill(hyyinghua)

hykakasi:addSkill(hyfengchi)
hykakasi:addSkill(hydianche)
hykakasi:addSkill(hyningtong)

hyrii:addSkill(hybadun)
hyrii:addSkill(hyliandan)
hyrii:addSkill(hyroubo)

hygaara:addSkill(hyshakai)
hygaara:addSkill(hyjiamei)

hyneiji:addSkill(hybaiyan)

sgs.LoadTranslationTable{
	["naruto"] = "火影",
	
	["hynaruto"] = "鸣人",
	["#hynaruto"] = "吊车尾的白痴",
	["designer:hynaruto"] = "啦啦SLG",
	["cv:hynaruto"] = "竹内顺子",
	["illustrator:hynaruto"] = "岸本齐史",
	["hyfennu"] = "愤怒",
	[":hyfennu"] = "当你使用红色的【杀】造成伤害时，可以进行一次判定，若结果为方块，此伤害+1。",
	["hyfenshen"] = "分身",
	[":hyfenshen"] = "你的【杀】可以额外指定一个目标。",
	
	["hysasuke"] = "佐助",
	["#hysasuke"] = "写轮俊杰",
	["designer:hysasuke"] = "啦啦SLG",
	["cv:hysasuke"] = "杉山纪彰",
	["illustrator:hysasuke"] = "岸本齐史",
	["hyhuoshu"] = "火术",
	[":hyhuoshu"] = "你可以将方块花色的牌作为【火攻】使用，将红桃花色的牌作为【火杀】使用或打出。",
	["hyxielun"] = "写轮",
	[":hyxielun"] = "你可以将梅花花色的牌作为【铁锁链环】使用或重铸。",
	["hyzhouyin"] = "咒印",
	[":hyzhouyin"] = "<b>锁定技</b>,你的黑桃花色的牌均视为【酒】。",
	
	["hysakura"] = "樱",
	["#hysakura"] = "医之樱花",
	["designer:hysakura"] = "啦啦SLG",
	["cv:hysakura"] = "中村千绘",
	["illustrator:hysakura"] = "岸本齐史",
	["hyzhangxianCard"] = "掌仙",
	["hyzhangxianVS"] = "掌仙",
	["hyzhangxian"] = "掌仙",
	[":hyzhangxian"] = "你可以弃置一张【桃】并指定一名没有【樱】标记的角色，该角色获得一枚【樱】标记。拥有【樱】标记的角色，在其下个回合开始前，若其手牌数大于或等于其体力值，则须选择回复一点体力或增加一点体力上限。然后不论结果，该角色须弃置【樱】标记。",
	["@sakura"] = "樱",
	["#upgrade"] = "%from 增加了 %arg 点体力上限。",
	["recover"] = "回复1点体力",
	["gainmaxhp"] = "增加1点体力上限",
	["hyyinghua"] = "樱花",
	[":hyyinghua"] = "每当你受到一次伤害后，你可以弃置一张手牌，然后回复一点体力。",
	["~hyyinghua"] = "请弃置一张手牌。",
	
	["hykakasi"] = "卡卡西",
	["#hykakasi"] = "拷贝忍者",
	["designer:hykakasi"] = "啦啦SLG",
	["cv:hykakasi"] = "井上和彦",
	["illustrator:hykakasi"] = "岸本齐史",
	["hyfengchi"] = "风驰",
	[":hyfengchi"] = "你可以跳过你此回合的摸牌阶段。若如此做，视为对一名其他角色使用一张【杀】。",
	["hydianche"] = "电掣",
	[":hydianche"] = "你每受到或造成1点雷属性伤害，可摸两张牌，将其中的一张交给任意一名角色，然后将另一张交给任意一名角色。你造成的伤害均视为雷属性伤害。",	
	["hyningtongCard"] = "凝瞳",
	["hyningtongVS"] = "凝瞳",
	["hyningtong"] = "凝瞳",
	[":hyningtong"] = "在任意角色的判定牌生效前，你可以打出一张红色手牌代替之。",
	["~hyningtong"] = "请弃置一张红色手牌更改判定结果。",
	
	["hyrii"] = "李",
	["#hyrii"] = "热血少年",
	["designer:hyrii"] = "啦啦SLG",
	["cv:hyrii"] = "增川洋一",
	["illustrator:hyrii"] = "岸本齐史",
	["hybadun"] = "八遁",
	[":hybadun"] = "<b>锁定技</b>,出牌阶段，每当你使用一张【杀】，你获得一枚【门】标记（最多8枚），你的【杀】造成的伤害始终+X（X=【门】标记的数量）。回合结束阶段开始时，若【门】标记数量为8枚，你立即死亡，若不足8枚，你弃置所有【门】标记。",
	["@men"] = "门",
	["hyliandanCard"] = "连弹",
	["hyliandanVS"] = "连弹",
	["hyliandan"] = "连弹",
	[":hyliandan"] = "出牌阶段，你可以失去1点体力并指定一名角色，你与该角色的距离始终视为1，直到回合结束。每阶段限1次。当你使用的【杀】被【闪】抵消时，你可以对相同的目标再使用一张【杀】（无距离限制）。",
	["InvokeForSlash"] = "你可以对目标再使用一张【杀】。",
	["hyroubo"] = "肉搏",
	[":hyroubo"] = "<b>锁定技</b>,你手牌中的装备牌均视为【杀】。",
	
	["hygaara"] = "我爱罗",
	["#hygaara"] = "冷血少年",
	["designer:hygaara"] = "啦啦SLG",
	["cv:hygaara"] = "石田彰",
	["illustrator:hygaara"] = "岸本齐史",
	["hyshakai"] = "沙铠",
	[":hyshakai"] = "<b>锁定技</b>，每当你受到伤害时，若此伤害多于1点，则防止多余的伤害。",
	["hyjiamei"] = "假寐",
	[":hyjiamei"] = "<b>觉醒技</b>，回合开始阶段开始时，若你装备了武器，你须减1点体力上限，失去技能“沙铠”并获得技能“守鹤”和“绝御”。",
	["hyshouhe"] = "守鹤",
	[":hyshouhe"] = "回合开始阶段开始时，你可以将你的武将牌翻面，然后对场上所有角色各造成1点伤害。",
	["hyjueyu"] = "绝御",
	[":hyjueyu"] = "<b>锁定技</b>，每当你受到的非火焰伤害结算开始时，若你的体力值为1，防止此伤害。",
	
	["hyneiji"] = "宁次",
	["#hyneiji"] = "天才少年",
	["designer:hyneiji"] = "啦啦SLG",
	["cv:hyneiji"] = "远近孝一",
	["illustrator:hyneiji"] = "岸本齐史",
	["hybaiyanCard"] = "白眼",
	["hybaiyan"] = "白眼",
	[":hybaiyan"] = "出牌阶段，你可以观看一名其他角色的手牌并选择一张方块花色的牌展示并获得之。",
}
