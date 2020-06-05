
R = Random.new

Cards = 60
Lands = 24
Iteration = 1_000_000

class Deck
	def initialize(lands, good_lands, cards)
		@cards = []
		
		1.upto(good_lands) { @cards << 1 }
		(good_lands+1).upto(lands) { @cards << 2 }
		(lands+1).upto(cards) { @cards << 3 }
		
		shuffle
	end
	
	def shuffle
		(@cards.size-1).downto(1).each { |i|
			j = R.rand(i+1)
			tmp = @cards[i]
			@cards[i] = @cards[j]
			@cards[j] = tmp
		}
	end
	
	def draw
		@cards.shift
	end
	
	def scry
		card = self.draw
		if yield(card)
			put_top(card)
		else
			put_bottom(card)
		end
	end
	
	def put_top(card)
		@cards.unshift(card)
	end
	
	def put_bottom(card)
		@cards << card
	end
end


class Hand
	def initialize
		@good_lands = @not_good_lands = @spell = 0
	end

	def add(card)
		@good_lands += 1    if card == 1
		@not_good_lands +=1 if card == 2
		@spell += 1         if card == 3
	end
	
	def malligan?
		lands < 2 || lands > 5
	end
	
	def take(cmc)
		if lands > cmc
			if @not_good_lands == 0
				@good_lands -= 1
				return 1
			else
				@not_good_lands -= 1
				return 2
			end
		else
			@spell -= 1
			return 3
		end
	end
	
	def lands
		@good_lands + @not_good_lands
	end
	def good_lands
		@good_lands
	end
	def size
		@good_lands + @not_good_lands + @spell
	end
end

#
def simulate(needs_lands, cmc)
	needs_lands.upto(Lands) { |good_lands|
		conditional = ok = 0

		Iteration.times {
			deck = hand = nil
			try = 0
		
			# ダブルマリガンまで
			3.times {
				try += 1
				# 初期手札
				deck = Deck.new(Lands, good_lands, Cards)
				hand = Hand.new
				7.times { hand.add(deck.draw) }
			
				break unless hand.malligan?
			}
		
			# マリガンした場合、ボトムに送る
			(try-1).times { deck.put_bottom(hand.take(cmc)) }
		
			# ２ターン目以降のドロー（先手）
#			2.upto(cmc) { hand.add(deck.draw) }
			until hand.lands >= cmc
				hand.add(deck.draw)
			end
		
			ok += 1 if hand.good_lands >= needs_lands #&& hand.lands >= cmc
			conditional += 1 #if hand.lands >= cmc
		}
	
		ok_rate = ok.to_f / conditional
		total_rate = conditional.to_f / Iteration
		yield("#{good_lands}, #{ok_rate}, #{total_rate}")
	
		break if ok_rate > 0.999
	}
end

needs_lands = 2
(4..4).each { |cmc|
	filename = "%02d%02d_%d%s.csv" % [Lands, Cards, cmc - needs_lands, 'C'*needs_lands]
	
	File.open(filename, 'w') { |f|
		f.puts "mana source, P(play), P(land)"
		
		simulate(needs_lands, cmc) { |result|
			f.puts result
			f.flush
		}
	}
}
