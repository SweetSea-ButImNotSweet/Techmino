return{
	name={
		"本地多人",
		"本地多人",
		"Multiplayer",
	},
	level={
		"3P",
		"3P",
		"3P",
	},
	info={
		"友尽模式(非联网/局域网)",
		"友尽模式(非联网/局域网)",
		"End of friendship",
	},
	color=color.white,
	env={
		drop=60,lock=60,
		freshLimit=15,
		bg="none",bgm="way",
	},
	load=function()
		newPlayer(1,20,100,.65)
		newPlayer(2,435,100,.65)
		newPlayer(3,850,100,.65)
	end,
	mesDisp=function(P,dx,dy)
	end,
}