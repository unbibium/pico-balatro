pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Globals
screen_width = 128
screen_height = 128
card_width = 8
card_height = 8
debug_draw_text = ""
hand_type_text = ""
draw_hand_gap = 4 
init_draw = true 
max_selected = 5
card_selected_count = 0
suits = {'H', 'D', 'C', 'S'}
ranks = {
	{rank = 'A', base_chips = 11},
	{rank = 'K', base_chips = 10},
	{rank = 'Q', base_chips = 10},
	{rank = 'J', base_chips = 10},
	{rank = '10', base_chips = 10},
	{rank = '9', base_chips = 9},
	{rank = '8', base_chips = 8},
	{rank = '7', base_chips = 7},
	{rank = '6', base_chips = 6},
	{rank = '5', base_chips = 5},
	{rank = '4', base_chips = 4},
	{rank = '3', base_chips = 3},
	{rank = '2', base_chips = 2},
}	
hand_types = {
	["Royal Flush"] = {base_chips = 100, base_mult = 8},
	["Straight Flush"] = {base_chips = 100, base_mult = 8},
	["Four of a Kind"] = {base_chips = 60, base_mult = 7},
	["Full House"] = {base_chips = 40, base_mult = 4},
	["Flush"] = {base_chips = 35, base_mult = 4},
	["Straight"] = {base_chips = 30, base_mult = 4},
	["Three of a Kind"] = {base_chips = 30, base_mult = 3},
	["Two Pair"] = {base_chips = 20, base_mult = 2},
	["Pair"] = {base_chips = 10, base_mult = 2},
	["High Card"] = {base_chips = 5, base_mult = 1}
}

-- buttons
btn_width = 16
btn_height = 16
btn_gap = 10
btn_play_hand_sprite_index = 64
btn_play_hand_pos_x = 32 
btn_play_hand_pos_y = 100
btn_discard_hand_sprite_index = 66
btn_discard_hand_pos_x = 80 
btn_discard_hand_pos_y = 100

-- Game State
hand = {}
selected_cards = {}
scored_cards = {}
hand_size = 8
score = 0
chips = 0
mult = 0

-- Input
mx = 0
my = 0

-- Gameplay
function _init()
    -- initialize data
    poke(0x5F2D, 0x7)
	base_deck = create_base_deck()
	shuffled_deck = shuffle_deck(base_deck)
	deal_hand(shuffled_deck, hand_size)
end

function _update()
    --register inputs
    mx = stat(32)
    my = stat(33)
    -- TODO make mouse less jumpy

    -- Check mouse buttons
	-- btn(5) left click, btn(4) right click
	if btnp(5) then 
		left_click_hand_collision()
		update_selected_cards()
		play_button_clicked()
		discard_button_clicked()
	end

    -- Check keyboard
    --if stat(30) then
    --	end
end

function _draw()
    -- draw stuff
    cls()
    draw_background()
    draw_hand()
	draw_play_discard_buttons()
	draw_chips_and_mult()
	draw_score()
	draw_hand_type(hand_type_text)
    draw_mouse(mx, my)
	test_draw_debug() -- TODO remove this
end

function score_hand()
	-- Score cards 
	for card in all(scored_cards) do
		chips = chips + card.chips
		mult = mult + card.mult
	end
	score = score + (chips * mult)
	chips = 0
	mult = 0
	hand_type_text = ""
end

function update_selected_cards()
	for card in all(hand) do
		if card.selected == true and not contains(selected_cards, card) then
			add(selected_cards, card)
		elseif card.selected == false and contains(selected_cards, card) then
			del(selected_cards, card)	
		end
	end
	scored_cards = {}
	local hand_type = check_hand_type()
	if hand_type ~= "None" then
		hand_type_text = hand_type
		chips = 0
		mult = 0
		chips = chips + hand_types[hand_type].base_chips
		mult = mult + hand_types[hand_type].base_mult
	end
end

function check_hand_type()
	if is_royal_flush() then
		return "Royal Flush"	
	elseif is_straight_flush() then
		return "Straight Flush"
	elseif is_four_of_a_kind() then
		return "Four of a Kind"
	elseif is_full_house() then
		return "Full House"
	elseif is_flush() then
		return "Flush"
	elseif is_straight() then
		return "Straight"
	elseif is_three_of_a_kind() then
		return "Three of a Kind"
	elseif is_two_pair() then
		return "Two Pair"
	elseif is_pair() then
		return "Pair"	
	elseif is_high_card() then
		return "High Card"
	else
		hand_type_text = ""
		return "None"
	end
end

-- Deck
function create_base_deck()
	sprite_index = 0
	card_id = 1
	base_deck = {}

	-- Set the sorting order		
	for i, card in pairs(ranks) do
    	card.order = 14 - i
	end

	-- Create deck
	for x=1,#ranks do
		for y=1,#suits do
			card_info = {
				card_id = card_id,	
				rank = ranks[x].rank,
				suit = suits[y],
				chips = ranks[x].base_chips,
				mult = 0,
				sprite_index = sprite_index,
				order = ranks[x].order,
				-- Resettable params
				selected = false,
				pos_x = 0,
				pos_y = 0
			}
			add(base_deck, card_info)
			card_id = card_id + 1
			sprite_index = sprite_index + 1
		end
	end
		
	return base_deck
end

function shuffle_deck(deck)
	copy_deck = {}
	for x=1,#deck do
		add(copy_deck, deck[x])
	end
	shuffled_deck = {}

	for x=1,#copy_deck do
		random_card = rnd(copy_deck)
		add(shuffled_deck, random_card)
		del(copy_deck, random_card)
	end
	return shuffled_deck
end

function deal_hand(shuffled_deck, cards_to_deal)
	if #shuffled_deck < cards_to_deal then
		for card in all(shuffled_deck) do
			add(hand, card)				
			del(shuffled_deck, card)
		end
	else
		for x=1,cards_to_deal do
			add(hand, shuffled_deck[1])				
			del(shuffled_deck, shuffled_deck[1])
		end
	end
	sort_by_rank_decreasing(hand)
end

-- Graphics 
function draw_background()
    rectfill(0, 0, 128, 128, 3) 
end

function draw_hand()	
	draw_hand_start_x = 15	
	draw_hand_start_y = 80
	if init_draw then
		for x=1,#hand do
 	   		spr(hand[x].sprite_index, draw_hand_start_x, draw_hand_start_y) 
			hand[x].pos_x = draw_hand_start_x
			hand[x].pos_y = draw_hand_start_y
			draw_hand_start_x = draw_hand_start_x + card_width + draw_hand_gap
		end
		init_draw = false
	else
		for x=1,#hand do
 	   		spr(hand[x].sprite_index, hand[x].pos_x, hand[x].pos_y) 
		end
	end
end

function draw_mouse(x, y)
	spr(192, x, y)
end

function select_hand(card)
	if card.selected == false and card_selected_count < max_selected then 
		card.selected = true
		card_selected_count = card_selected_count + 1
		card.pos_y = card.pos_y - 10
	elseif card.selected == true then	
		card.selected = false
		card_selected_count = card_selected_count - 1
		card.pos_y = card.pos_y + 10
		if card_selected_count == 4 then debug_draw_text = "" end
	else
		debug_draw_text = "You can only select 5 \ncards at a time"
	end
end

function draw_play_discard_buttons()
	spr(btn_play_hand_sprite_index, btn_play_hand_pos_x, btn_play_hand_pos_y, 2, 2)
	spr(btn_discard_hand_sprite_index, btn_discard_hand_pos_x, btn_discard_hand_pos_y, 2, 2)
end

function draw_chips_and_mult()
	print(chips .. " X " .. mult, 10, 50, 7)
end

function draw_score()
	print(score, 10, 30, 7)
end

function draw_hand_type()
	print(hand_type_text, 45, 55, 7)	
end

-- Inputs
function left_click_hand_collision()
	-- Check if the mouse is colliding with a card in our hand 
	for x=1, #hand do
		if mx >= hand[x].pos_x and mx < hand[x].pos_x + card_width and
			my >= hand[x].pos_y and my < hand[x].pos_y + card_height then
				select_hand(hand[x])
				break
		end
	end
end

function mouse_sprite_collision(sx, sy, sw, sh)
    return mx >= sx and mx < sx + sw and
           my >= sy and my < sy + sh
end

function play_button_clicked()
	if mouse_sprite_collision(btn_play_hand_pos_x, btn_play_hand_pos_y, btn_width, btn_height) and #selected_cards > 0 then
		score_hand()
		for card in all(selected_cards) do
			del(hand, card)	
			del(selected_cards, card)
		end
		deal_hand(shuffled_deck, card_selected_count)
		init_draw = true
		card_selected_count = 0
		scored_cards = {}
	end
end

function discard_button_clicked()
	if mouse_sprite_collision(btn_discard_hand_pos_x, btn_discard_hand_pos_y, btn_width, btn_height) and #selected_cards > 0 then
		for card in all(selected_cards) do
			del(hand, card)	
			del(selected_cards, card)
		end
		deal_hand(shuffled_deck, card_selected_count)
		init_draw = true
		card_selected_count = 0
	end
end

-- Hand Detection
function is_royal_flush()
	if contains_royal(selected_cards) and contains_flush(selected_cards) then
		add_all_cards_to_score(selected_cards)
		return true
	end
	return false
end

function is_straight_flush()
	if contains_flush(selected_cards) and contains_straight(selected_cards) then	
		add_all_cards_to_score(selected_cards)
		return true
	end
	return false
end

function is_four_of_a_kind()
	if contains_four_of_a_kind(selected_cards) then
		sort_by_rank_decreasing(selected_cards)
		for x=1, #selected_cards - 3 do
			if selected_cards[x].rank == selected_cards[x + 1].rank and selected_cards[x].rank == selected_cards[x + 2].rank and selected_cards[x].rank == selected_cards[x + 3].rank then
				add(scored_cards, selected_cards[x])	
				add(scored_cards, selected_cards[x + 1])	
				add(scored_cards, selected_cards[x + 2])	
				add(scored_cards, selected_cards[x + 3])	
				return true
			end
		end
	end
	return false
end

function is_full_house()
	if contains_pair(selected_cards) and contains_three_of_a_kind(selected_cards) then
		add_all_cards_to_score(selected_cards)
		return true
	end
	return false
end

function is_flush()
	if contains_flush(selected_cards) then	
		add_all_cards_to_score(selected_cards)
		return true
	end
	return false
end

function is_straight()
	if contains_straight(selected_cards) then	
		add_all_cards_to_score(selected_cards)
		return true
	end
	return false
end

function is_three_of_a_kind()
	if contains_three_of_a_kind(selected_cards) then
		sort_by_rank_decreasing(selected_cards)
		for x=1, #selected_cards - 2 do
			if selected_cards[x].rank == selected_cards[x + 1].rank and selected_cards[x].rank == selected_cards[x + 2].rank then
				add(scored_cards, selected_cards[x])	
				add(scored_cards, selected_cards[x + 1])	
				add(scored_cards, selected_cards[x + 2])	
				return true
			end
		end
	end
	return false
end

function is_two_pair()
	if contains_two_pair(selected_cards) then
		sort_by_rank_decreasing(selected_cards)
		local times = 0
		for x=1, #selected_cards - 1 do
			if selected_cards[x].rank == selected_cards[x + 1].rank then
				add(scored_cards, selected_cards[x])	
				add(scored_cards, selected_cards[x + 1])	
				times = times + 1
				if times == 2 then
					return true
				end
				x = x + 2
			end
		end
	end
	return false
end

function is_pair()
	if contains_pair(selected_cards) then
		sort_by_rank_decreasing(selected_cards)
		for x=1, #selected_cards - 1 do
			if selected_cards[x].rank == selected_cards[x + 1].rank then
				add(scored_cards, selected_cards[x])	
				add(scored_cards, selected_cards[x + 1])	
				return true
			end
		end
	end
	return false
end

function is_high_card()
	if #selected_cards > 0 then
		sort_by_rank_decreasing(selected_cards)
		add(scored_cards, selected_cards[1])
		return true
	end
	return false
end

-- Helpers
function contains(table, value)
	-- is there a value in a table
    for item in all(table) do
        if item == value then
            return true
        end
    end
    return false
end

function contains_royal(cards)
	if #cards == 5 then
		sort_by_rank_decreasing(cards)
		local start_order = 13
		for x=1, #cards do
			if start_order != cards[x].order then
				return false
			end
			start_order = start_order - 1
		end
		return true 
	end
	return false
end

function contains_four_of_a_kind(cards)
	if contains_multiple_of_a_rank(cards, 4) then
		return true
	end
	return false
end

function contains_flush(cards)
	local suit_arr = {}
	for card in all(cards) do 
		add(suit_arr, card.suit)
	end
	for suit in all(suit_arr) do
		if count(suit_arr, suit) == 5 then				
			return true
		end
	end
	return false
end

function contains_straight(cards)
	if #cards == 5 then
		sort_by_rank_decreasing(cards)
		for x=1,#cards - 1 do
			if cards[x].order != cards[x + 1].order + 1 then
				return false	
			end
		end
		return true 
	else
		return false
	end
end

function contains_three_of_a_kind(cards)
	if contains_multiple_of_a_rank(cards, 3) then
		return true
	end
	return false
end

function contains_two_pair(cards)
	if #cards >= 4 then
		local order_arr = {}
		for card in all(cards) do
			add(order_arr, card.order)		
		end
		local times = 0
		local first_pair = 0
		for order_num in all(order_arr) do 
			if count(order_arr, order_num) == 2 and order_num != first_pair then
				times = times + 1
				first_pair = order_num
				if times == 2 then
					return true
				end
			end
		end
	end
	return false
end

function contains_pair(cards)
	if contains_multiple_of_a_rank(cards, 2) then
		return true
	end
	return false
end

function contains_multiple_of_a_rank(cards, num)
	if #cards >= num then
		local order_arr = {}
		for card in all(cards) do
			add(order_arr, card.order)		
		end
		for order_num in all(order_arr) do 
			if count(order_arr, order_num) == num then
				return true
			end
		end
	end
	return false
end

function add_all_cards_to_score(cards)
	sort_by_rank_decreasing(cards)
	for card in all(cards) do
		add(scored_cards, card)
	end
end

function sort_by_rank_decreasing(cards)
	-- insertion sort
	for i=2,#cards do
		current_order = cards[i].order
		current = cards[i]
		j = i - 1
		while (j >= 1 and current_order > cards[j].order) do
			cards[j + 1] = cards[j]
			j = j - 1
		end
		cards[j + 1] = current
	end
end

-- TEST
function test_draw_debug()
	print(debug_draw_text, 5, 20, 7)
end

function test_draw_table(table)
	for card in all(table) do
		debug_draw_text = debug_draw_text .. " " .. card.rank .. card.suit
	end
end

__gfx__
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
7778887777799977777ccc777775557778777887797779977c777cc775777557778888777799997777cccc777755557778888887799999977cccccc775555557
778778777797797777c77c777757757778788777797997777c7cc7777575577778777787797777977c7777c775777757777778777777797777777c7777777577
78888887799999977cccccc77555555778877777799777777cc777777557777778777787797777977c7777c775777757777778777777797777777c7777777577
78777787797777977c7777c77577775778888777799997777cccc7777555577778778787797797977c77c7c77577575778777877797779777c777c7775777577
78777787797777977c7777c77577775778778877797799777c77cc777577557778777877797779777c777c777577757778777877797779777c777c7775777577
78777787797777977c7777c77577775778777887797779977c777cc775777557778887877799979777ccc7c777555757778888777799997777cccc7777555577
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
78788887797999977c7cccc77575555778888887799999977cccccc77555555778888887799999977cccccc77555555778888887799999977cccccc775555557
78787787797977977c7c77c77575775778777787797777977c7777c77577775778777787797777977c7777c77577775778777787797777977c7777c775777757
78787787797977977c7c77c77575775778777787797777977c7777c77577775778888887799999977cccccc7755555577777778777777797777777c777777757
78787787797977977c7c77c77575775778888887799999977cccccc77555555778777787797777977c7777c7757777577777778777777797777777c777777757
78787787797977977c7c77c7757577577777778777777797777777c77777775778777787797777977c7777c7757777577777778777777797777777c777777757
78788887797999977c7cccc7757555577777778777777797777777c77777775778888887799999977cccccc7755555577777778777777797777777c777777757
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
7778887777799977777ccc777775557778888887799999977cccccc77555555777778877777799777777cc777777557778888887799999977cccccc775555557
778777777797777777c777777757777778777777797777777c777777757777777778787777797977777c7c77777575777777778777777797777777c777777757
78777777797777777c7777777577777778888887799999977cccccc775555557778778777797797777c77c77775775777777778777777797777777c777777757
78888887799999977cccccc7755555577777778777777797777777c77777775778888887799999977cccccc775555557778888877799999777ccccc777555557
78777787797777977c7777c7757777577777778777777797777777c777777757777778777777797777777c77777775777777778777777797777777c777777757
78888887799999977cccccc77555555778888887799999977cccccc775555557777778777777797777777c777777757778888887799999977cccccc775555557
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
778888877799999777ccccc777555557000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
78777787797777977c7777c775777757000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777778877777799777777cc777777557000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
778887777799977777ccc77777555777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
78877777799777777cc7777775577777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
78888887799999977cccccc775555557000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccceeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccce777e777e777eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c777c7cc777c7c7ce7e7ee7ee7eeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c7c7c7cc7c7c7c7ce7e7ee7ee777eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c777c7cc777c7c7ce7e7ee7eeee7e77e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c7ccc7cc7c7cc7cce7e7ee7eeee7eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c7ccc77c7c7cc7cce777e777e777eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccceeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccceeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccceeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c7c7c777c777c777e77e777e777e777e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c7c7c7c7c7c7c7c7e7ee7e7e7e7e7e7e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c777c777c7c7c7c7e7ee777e777e7e7e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c7c7c7c7c7c7c7c7e7ee7e7e77ee7e7e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c7c7c7c7c7c7c777e77e7e7e7e7e777e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccceeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17771000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17777100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17777710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17777771000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17777110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000005050090503e05039050370503505033050310502e0502c050290503d0503a05037050350503405032050300502f0502d0502b05029050270502405022050000000000000000000000000000000
