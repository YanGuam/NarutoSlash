module("extensions.naruto", package.seeall)
extension = sgs.Package("naruto")

hynaruto = sgs.General(extension, "hynaruto", "wu")
hysasuke = sgs.General(extension, "hysasuke", "wu", "3")
hysakura = sgs.General(extension, "hysakura", "wu", "3", false)
hykakasi = sgs.General(extension, "hykakasi", "wu", "3")

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
			
		
hynaruto:addSkill(hyfennu)
hynaruto:addSkill(hyfenshen)

hysasuke:addSkill(hyhuoshu)
hysasuke:addSkill(hyxielun)
hysasuke:addSkill(hyzhouyin)

hysakura:addSkill(hyzhangxian)
hysakura:addSkill(hyyinghua)

hykakasi:addSkill(hyfengchi)

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
}
