module.exports =
	ui:
		sortBy: 'name'
		selected: 2

	restaurants:
		1:
			id: 1, name: 'La Neta', address: 'Drottninggatan 132',
			desc: 'Our tacos and quesadillas perfect catering for corporate events or private parties. We even have vegetarian, vegan, gluten-free and lactose-free options.'
		2:
			id: 2, name: 'Rolfs Kök', address: 'Tegnérgatan 41',
			desc: 'Rolfs Kitchen repaired only food that we like ourselves. It is based on simplicity and quality, without fuss and frills. Here are the joy of food and the atmosphere is more important than trends and what is "in" or "out".'
		3:
			id: 3, name: 'Kimchi', address: 'Luntmakargatan 95',
			desc: 'We are building on our web site. It is not quite ready yet but in the meantime, you can find our menus on our Facebook page.'
		4:
			id: 4, name: 'Martins Gröna', address: 'Regeringsgatan 91',
			desc: 'Martin Green is a vegetarian lunch restaurant situated in central Stockholm. Since 1998 we have served vegetarian food using fresh ingredients and spices from all over the world with much love.'
		5:
			id: 5, name: 'Indian Garden', address: 'Västgötagatan 18',
			desc: 'Rezaul Karim, founder and owner of Indian Garden. Born in Bangladesh in 1975 and came to Sweden 19 years old. Even as a child in Bangladesh, he showed a great interest in cooking and spent much time alongside his mother in the kitchen.'
			
	reviews:
		1:
			id: 1, ts: 1480086468, restaurant: 1, stars: 2,
			text: 'Not really my thing, too litle burger and too litle beer',
			user: {name: 'Martin', color: '#8DDA91', initials: 'M'}
		2:
			id: 2, ts: 1480186468, restaurant: 1, stars: 4,
			text: 'Great food but a bit noisy place'
			user: {name: 'Tina', color: '#C48DDA', initials: 'T'}
		3:
			id: 3, user: 'Malin', ts: 1481186468, restaurant: 1, stars: 5,
			text: 'Gott och snabbt!'
			user: {name: 'Tina', color: '#DAC48D', initials: 'T'}
		4:
			id: 4, user: 'André', ts: 1480286468, restaurant: 2, stars: 5,
			text: 'Bra mat!'
			user: {name: 'Tina', color: '#8DDA91', initials: 'T'}

