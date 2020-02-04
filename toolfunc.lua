local tm=love.timer
local gc=love.graphics
local kb=love.keyboard
local setFont=setFont
local int,abs,rnd,max,min=math.floor,math.abs,math.random,math.max,math.min
local sub,find=string.sub,string.find
local ins,rem=table.insert,table.remove
local toN,toS=tonumber,tostring
local concat=table.concat

local function splitS(s,sep)
	local t,n={},1
	repeat
		local p=find(s,sep)or #s+1
		t[n]=sub(s,1,p-1)
		n=n+1
		s=sub(s,p+#sep)
	until #s==0
	return t
end
function mStr(s,x,y)
	gc.printf(s,x-320,y,640,"center")
end
function mDraw(s,x,y)
	gc.draw(s,x-s:getWidth()*.5,y)
end

function getNewRow(val)
	local t=rem(freeRow)
	for i=1,10 do
		t[i]=val
	end
	freeRow.L=freeRow.L-1
	--get a row from buffer
	if not freeRow[1]then
		for i=1,10 do
			freeRow[i]={0,0,0,0,0,0,0,0,0,0}
		end
		freeRow.L=freeRow.L+10
	end
	--prepare new rows
	return t
end
function removeRow(t,k)
	freeRow[#freeRow+1]=rem(t,k)
	freeRow.L=freeRow.L+1
end
--Single-usage funcs
langName={"中文","全中文","English"}
local langID={"chi","chi_full","eng"}
local drawableTextLoad={
	"next",
	"hold",
	"pause",
	"finish",
	"custom",
	"keyboard",
	"joystick",
	"setting2Help",
	"musicRoom",
	"nowPlaying",
}
function swapLanguage(l)
	text=require("language/"..langID[l])
	Buttons.sel=nil
	for S,L in next,Buttons do
		for N,B in next,L do
			B.alpha=0
			B.t=text.ButtonText[S][N]
		end
	end
	gc.push("transform")
	gc.origin()
		royaleCtrlPad=gc.newCanvas(300,100)
		gc.setCanvas(royaleCtrlPad)
		gc.setColor(1,1,1)
		setFont(25)
		gc.setLineWidth(2)
		for i=1,4 do
			gc.rectangle("line",RCPB[2*i-1],RCPB[2*i],90,35,8,4)
			mStr(text.atkModeName[i],RCPB[2*i-1]+45,RCPB[2*i]+3)
		end
	gc.pop()
	gc.setCanvas()
	for _,s in next,drawableTextLoad do
		drawableText[s]:set(text[s])
	end
	collectgarbage()
end
function changeBlockSkin(n)
	n=n-1
	gc.push("transform")
	gc.origin()
	for i=1,13 do
		gc.setCanvas(blockSkin[i])
		gc.draw(blockImg,30-30*i,-30*n)
		gc.setCanvas(blockSkinmini[i])
		gc.draw(blockImg,6-6*i,-6*n,nil,.2)
	end
	gc.pop()
	gc.setCanvas()
end

local vibrateLevel={0,.02,.03,.04,.05,.06,.07,.08}
function VIB(t)
	if setting.vib>0 then
		love.system.vibrate(vibrateLevel[setting.vib+t])
	end
end
function SFX(s,v)
	if setting.sfx then
		local n=1
		::L::if sfx[s][n]:isPlaying()then
			n=n+1
			if not sfx[s][n]then
				sfx[s][n]=sfx[s][n-1]:clone()
				sfx[s][n]:seek(0)
				goto quit
			end
			goto L
		end::quit::
		sfx[s][n]:setVolume(v or 1)
		sfx[s][n]:play()
	end
end
function VOICE(s,n)
	if setting.voc then
		voicePlaying[#voicePlaying+1]=voice[s][n or rnd(#voice[s])]
		if #voicePlaying==1 then
			voicePlaying[1]:play()
		end
	end
end
function BGM(s)
	if setting.bgm and bgmPlaying~=s then
		if bgmPlaying then newTask(Event_task.bgmFadeOut,nil,bgmPlaying)end
		for i=#Task,1,-1 do
			local T=Task[i]
			if T.code==Event_task.bgmFadeIn then
				T.code=Event_task.bgmFadeOut
			elseif T.code==Event_task.bgmFadeOut and T.data==s then
				rem(Task,i)
			end
		end
		if s then
			newTask(Event_task.bgmFadeIn,nil,s)
			bgm[s]:play()
		end
		bgmPlaying=s
	end
end

local swapDeck_data={
	{4,0,1,1},{6,0,15,1},{5,0,9,1},{6,0,6,1},
	{1,0,3,1},{3,0,12,1},{1,1,8,1},{2,1,4,2},
	{3,2,13,2},{4,1,12,2},{5,2,1,2},{7,1,11,2},
	{2,1,9,3},{3,0,6,3},{4,2,14,3},{1,0,4,4},
	{7,1,1,4},{6,0,2,4},{5,2,6,4},{6,0,14,5},
	{3,3,15,5},{4,0,7,6},{7,1,10,5},{5,0,2,6},
	{2,1,1,7},{1,0,4,6},{4,1,13,5},{1,1,6,7},
	{5,3,11,5},{3,2,11,7},{6,0,8,7},{4,2,12,8},
	{7,0,8,9},{1,0,2,8},{5,2,4,8},{6,0,15,8},
}--Block id [ZSLJTOI] ,dir,x,y
local swap={
	none={2,1,d=function()end},
	flash={8,1,d=function()gc.clear(1,1,1)end},
	fade={30,15,d=function()
		local t=1-abs(sceneSwaping.time*.06667-1)
		gc.setColor(0,0,0,t)
		gc.rectangle("fill",0,0,1280,720)
	end},
	deck={50,8,d=function()
		local t=sceneSwaping.time
		gc.setColor(1,1,1)
		if t>8 then
			local t=max(t,15)
			for i=1,51-t do
				local bn=swapDeck_data[i][1]
				local b=blocks[bn][swapDeck_data[i][2]]
				local cx,cy=swapDeck_data[i][3],swapDeck_data[i][4]
				for y=1,#b do for x=1,#b[1]do
					if b[y][x]then
						gc.draw(blockSkin[bn],80*(cx+x-2),80*(10-cy-y),nil,8/3)
					end
				end end
			end
		end
		if t<17 then
			gc.setColor(1,1,1,(8-abs(t-8))*.125)
			gc.rectangle("fill",0,0,1280,720)
		end
	end},
}--Scene swapping animations
function gotoScene(s,style)
	if not sceneSwaping and s~=scene then
		style=style or"fade"
		sceneSwaping={
			tar=s,style=style,
			time=swap[style][1],mid=swap[style][2],
			draw=swap[style].d
		}
		Buttons.sel=nil
		if style~="none"then
			SFX("swipe")
		end
	end
end
function updateStat()
	for k,v in next,players[1].stat do
		stat[k]=stat[k]+v
	end
end
local prevMenu={
	load=love.event.quit,
	intro="quit",
	main="intro",
	music="main",
	mode="main",
	custom="mode",
	draw=function()
		kb.setKeyRepeat(false)
		gotoScene("custom")
	end,
	play=function()
		updateStat()
		clearTask("play")
		gotoScene(curMode.id~="custom"and"mode"or"custom","deck")
	end,
	pause=nil,
	setting=function()
		saveSetting()
		gotoScene("main")
	end,
	setting2="setting",
	setting3="setting",
	help="main",
	history="help",
	stat="main",
}prevMenu.pause=prevMenu.play
function back()
	local t=prevMenu[scene]
	if type(t)=="string"then
		gotoScene(t)
	else
		t()
	end
end
function pauseGame()
	pauseTimer=0--Pause timer for animation
	if not gamefinished then
		pauseCount=pauseCount+1
		if bgmPlaying then bgm[bgmPlaying]:pause()end
	end
	for i=1,#players.alive do
		local l=players.alive[i].keyPressing
		for j=1,#l do
			if l[j]then
				releaseKey(j,players.alive[i])
			end
		end
	end
	gotoScene("pause","none")
end
function resumeGame()
	if bgmPlaying then bgm[bgmPlaying]:play()end
	gotoScene("play","fade")
end
local dataOpt={
	"run","game","time",
	"key","rotate","hold","piece","row",
	"atk","send","recv","pend",
	"clear_1","clear_2","clear_3","clear_4",
	"spin_0","spin_1","spin_2","spin_3",
	"b2b","b3b","pc","score",
}
function loadData()
	userData:open("r")
	local t=userData:read()
	if not find(t,"spin")then
		t=love.data.decompress("string","zlib",t)
	end
	t=splitS(t,"\r\n")
	userData:close()
	for i=1,#t do
		local p=find(t[i],"=")
		if p then
			local t,v=sub(t[i],1,p-1),sub(t[i],p+1)
			if t=="gametime"then t="time"end
			for i=1,#dataOpt do
				if t==dataOpt[i]then
					v=toN(v)if not v or v<0 then v=0 end
					stat[t]=v
					break
				end
			end
		end
	end
end
function saveData()
	local t={}
	for i=1,#dataOpt do
		t[i]=dataOpt[i].."="..toS(stat[dataOpt[i]])
	end
	t=concat(t,"\r\n")
	t=love.data.compress("string","zlib",t)
	userData:open("w")
	userData:write(t)
	userData:close()
end
function loadSetting()
	userSetting:open("r")
	local t=userSetting:read()
	if not find(t,"virtual")then
		t=love.data.decompress("string","zlib",t)
	end
	t=splitS(t,"\r\n")
	userSetting:close()
	for i=1,#t do
		local p=find(t[i],"=")
		if p then
			local t,v=sub(t[i],1,p-1),sub(t[i],p+1)
			if t=="sfx"or t=="bgm"or t=="bgblock"or t=="voc"then
				setting[t]=v=="true"
			elseif t=="vib"then
				setting.vib=toN(v:match("[012345]"))or 0
			elseif t=="fullscreen"then
				setting.fullscreen=v=="true"
				love.window.setFullscreen(setting.fullscreen)
			elseif t=="keymap"then
				v=splitS(v,"/")
				for i=1,16 do
					local v1=splitS(v[i],",")
					for j=1,#v1 do
						setting.keyMap[i][j]=v1[j]
					end
				end
			elseif t=="virtualkey"then
				v=splitS(v,"/")
				for i=1,10 do
					if v[i]then
						virtualkey[i]=splitS(v[i],",")
						for j=1,4 do
							virtualkey[i][j]=toN(virtualkey[i][j])
						end
					end
				end
			elseif t=="virtualkeyAlpha"then
				setting.virtualkeyAlpha=min(int(abs(toN(v))),10)
			elseif t=="virtualkeyIcon"or t=="virtualkeySwitch"then
				setting[t]=v=="true"
			elseif t=="frameMul"then
				setting.frameMul=min(max(toN(v)or 100,0),100)
			elseif t=="das"or t=="arr"or t=="sddas"or t=="sdarr"then
				v=toN(v)if not v or v<0 then v=0 end
				setting[t]=int(v)
			elseif t=="ghost"or t=="center"or t=="grid"or t=="swap"or t=="bg"or t=="smo"then
				setting[t]=v=="true"
			elseif t=="fxs"then
				setting[t]=toN(v:match("[0123]"))or 0
			elseif t=="lang"then
				setting[t]=toN(v:match("[123]"))or 1
			elseif t=="skin"then
				setting[t]=toN(v:match("[123456]"))or 1
			end
		end
	end
end
local saveOpt={
	"ghost","center",
	"grid","swap",
	"fxs","bg",
	"das","arr",
	"sddas","sdarr",
	"lang",

	"sfx","bgm",
	"vib","voc",
	"fullscreen",
	"bgblock",
	"skin","smo",
	"virtualkeyAlpha",
	"virtualkeyIcon",
	"virtualkeySwitch",
	"frameMul",
}
function saveSetting()
	local vk={}
	for i=1,10 do
		for j=1,4 do
			virtualkey[i][j]=int(virtualkey[i][j]+.5)
		end--Saving a integer is better?
		vk[i]=concat(virtualkey[i],",")
	end--pre-pack virtualkey setting
	local map={}
	for i=1,16 do
		map[i]=concat(setting.keyMap[i],",")
	end
	local t={
		"keymap="..toS(concat(map,"/")),
		"virtualkey="..toS(concat(vk,"/")),
	}
	for i=1,#saveOpt do
		t[i+2]=saveOpt[i].."="..toS(setting[saveOpt[i]])
		--not always i+2!
	end
	t=concat(t,"\r\n")
	t=love.data.compress("string","zlib",t)
	userSetting:open("w")
	userSetting:write(t)
	userSetting:close()
end