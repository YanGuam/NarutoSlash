sgs.ai_skill_invoke.hyfennu = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then return false end
	return true
end

sgs.ai_chaofeng.hynaruto = 1

sgs.ai_suit_priority.hyfennu=function(self,card) 
	return card:isKindOf("Slash") and "club|spade|diamond|heart"
end

function sgs.ai_cardneed.hyfennu(to, card, self)
	return isCard("Slash", card, to) and card:isRed()
end

