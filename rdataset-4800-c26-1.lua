require 'torch'

local Max_length = 0
local Actual_length = 0

local numW = 1
local numB = 1

--create and update the map for area
local function refresh( existTensor, change,y,x)
	
	--print(change)
	-- stop recursion when change not equal to true
	if change == false then
		return existTensor
	end

	--return when meet border
	if x == 0 then 
		return existTensor
	end 
	if x == 20 then
		return existTensor
	end
	if y == 0 then
		return existTensor
	end 
	if y == 20 then
		return existTensor
	end 

	change1 = false
	change2 = false
	change3 = false
	change4 = false

	local smallest = existTensor[y][x]
	--print(smallest)
	--check for the smallest numW in the liberties area [y-1][x] [y+1][x] [y][x-1] [y][x+1]
	if y ~= 1 then 
		--check [y-1][x]
		if existTensor[y-1][x] ~= 0 then
			if smallest > existTensor[y-1][x] then
				smallest = existTensor[y-1][x]
				change1 = true
			end
		end
	end
	if y ~= 19 then
		--check [y+1][x]
		if existTensor[y+1][x] ~= 0 then
			if smallest > existTensor[y+1][x] then
				smallest = existTensor[y+1][x]
				change2 = true
			end
		end
	end
	if x ~= 1 then 
		--check [y-1][x]
		if existTensor[y][x-1] ~= 0 then
			if smallest > existTensor[y][x-1] then
				smallest = existTensor[y][x-1]
				change3 = true
			end
		end
	end
	if x ~= 19 then
		--check [y+1][x]
		if existTensor[y][x+1] ~= 0 then
			if smallest > existTensor[y][x+1] then
				smallest = existTensor[y][x+1]
				change4 = true
			end
		end
	end
	--print(change)
	existTensor[y][x] = smallest
	existTensor=refresh(existTensor,change1,y+1,x)
	existTensor=refresh(existTensor,change2,y-1,x)
	existTensor=refresh(existTensor,change3,y,x+1)
	existTensor=refresh(existTensor,change4,y,x-1)
	return existTensor
end 

local tmpBoundary
local function possiblel(existTensorB,y,x)
	--return a 19x19 tensor mark all liberty position for one connect area
	--stop because when mmet border 
	if x == 0 then 
		return
	end 
	if x == 20 then
		return
	end
	if y == 0 then
		return
	end 
	if y == 20 then
		return
	end 
	if tmpBoundary[y][x] == 2 then
		return
	end
	-- stop when the position is out of area for the first time 
	if existTensorB[y][x] == 0 then
		--set tmpboundary to 1 and return
		tmpBoundary[y][x] = 1
		return
	else
		--print(y)
		--print(x)
		--print(tmpBoundary[y][x])
		tmpBoundary[y][x] = 2
		possiblel(existTensorB,y-1,x)
		possiblel(existTensorB,y+1,x)
		possiblel(existTensorB,y,x-1)
		possiblel(existTensorB,y,x+1)
	end
end
--check to update liberty
local function updatel( boundary, existTensor, color )
	local lib = 0
	for i = 1, 19 do 
		for j = 1, 19 do
			if boundary[i][j] == 1 then
				--boundary[i][j] == 1 means it's a boundary postion
				if color == 1 then
					if existTensor[1][i][j] ~= 2 then
						--means it is a liberty
						lib = lib + 1
					end
				else
					if existTensor[1][i][j] ~= 1 then
						lib = lib + 1
					end
				end
			end
		end
	end
	--print(lib)
	for i = 1, 19 do
		for j = 1, 19 do
			if boundary[i][j] == 2 then
				if color == 1 then
					existTensor[6][i][j] = lib
				else
					existTensor[8][i][j] = lib
				end
			end
		end
	end
	return existTensor
end 
--create liberty feature 

local function getliberties( existTensor,color )
	--feature 15,16,17,18 with 1, 2, 3, >= 4 liberties for white
	--feature 19,20,21,22 with 1, 2, 3, >= 4 liberties for black
	--feature 5 is liberty for white before initialize with 10
	--feature 6 is liberty for white after initialize with 10
	--feature 7 is liberty for black before initialize with 10
	--feature 8 is liberty for black after initialize with 10
	
	if color == 1 then
		--clear feature broad
		existTensor[15]:fill(0)
		existTensor[16]:fill(0)
		existTensor[17]:fill(0)
		existTensor[18]:fill(0)
		--white stone
		for i = 1, 19 do
			for j = 1, 19 do
				--go through liberty after feature for white
				if existTensor[6][i][j] ~= 10 then
					--renew 
					tmp = existTensor[6][i][j]
					if tmp < 4 then
						existTensor[15+tmp-1][i][j] = 1
					else 
						existTensor[18][i][j] = 1
					end
				end
			end
		end
	end
	if color == 2 then
		--black stone
		--clear feature broad
		existTensor[19]:fill(0)
		existTensor[20]:fill(0)
		existTensor[21]:fill(0)
		existTensor[22]:fill(0)
		for i = 1, 19 do
			for j = 1, 19 do
				--go through liberty after feature for white
				if existTensor[8][i][j] ~= 10 then
					--renew 
					tmp = existTensor[8][i][j]
					if tmp < 4 then
						existTensor[19+tmp-1][i][j] = 1
					else 
						existTensor[22][i][j] = 1
					end
				end
			end
		end
	end
	return existTensor
end 

--create and update ladder 
local function possibleLadder( existTensor, y, x, color )
	--four direction
	--left
	existTensor[9]:fill(0)
	existTensor[10]:fill(0)
	if y ~= 1 then
		--possible 
		if color == 1 then
			--white stone
			if existTensor[1][y-1][x] == 2 then
				--has black stone in this direction could countinue 
				tmp = y-1
				while  tmp > 0 do
					--start loop
					if existTensor[1][tmp][x] == 1 then
						--find the other side of ladder finished
						existTensor[9]:fill(1)--mark
						--existTensor[9][tmp][x] = 1 --mark the end
						break
					end
					if existTensor[1][tmp][x] == 0 then
						break
					end 
					tmp = tmp - 1
				end
			end
		else
			--black stone
			if existTensor[1][y-1][x] == 1 then
				--has white stone in this direction could countinue 
				tmp = y-1
				while  tmp > 0 do
					--start loop
					if existTensor[1][tmp][x] == 2 then
						--find the other side of ladderfinished
						existTensor[10]:fill(1)--mark the start
						break
					end
					if existTensor[1][tmp][x] == 0 then
						break
					end 
					tmp = tmp - 1
				end
			end
		end
	end
	--right
	if y ~= 19 then
		--possible 
		if color == 1 then
			--white stone
			if existTensor[1][y+1][x] == 2 then
				--has black stone in this direction could countinue 
				tmp = y + 1
				while  tmp < 20 do
					--start loop
					if existTensor[1][tmp][x] == 1 then
						--find the other side of ladderfinished
						existTensor[9]:fill(1)--mark the start
						break
					end
					if existTensor[1][tmp][x] == 0 then
						break
					end 
					tmp = tmp + 1
				end
			end
		else
			--black stone
			if existTensor[1][y+1][x] == 1 then
				--has white stone in this direction could countinue 
				tmp = y+1
				while  tmp < 20 do
					--start loop
					if existTensor[1][tmp][x] == 2 then
						--find the other side of ladderfinished
						existTensor[10]:fill(1)--mark the start
						break
					end
					if existTensor[1][tmp][x] == 0 then
						break
					end 
					tmp = tmp + 1
				end
			end
		end
	end
	--up
	if x ~= 1 then
		--possible 
		if color == 1 then
			--white stone
			if existTensor[1][y][x-1] == 2 then
				--has black stone in this direction could countinue 
				tmp = x-1
				while  tmp > 0 do
					--start loop
					if existTensor[1][y][tmp] == 1 then
						--find the other side of ladderfinished
						existTensor[9]:fill(1)--mark the start
						break
					end
					if existTensor[1][y][tmp] == 0 then
						break
					end 
					tmp = tmp - 1
				end
			end
		else
			--black stone
			if existTensor[1][y][x-1] == 1 then
				--has white stone in this direction could countinue 
				tmp = x-1
				while  tmp > 0 do
					--start loop
					if existTensor[1][y][tmp] == 2 then
						--find the other side of ladderfinished
						existTensor[10]:fill(1)--mark the start
						break
					end
					if existTensor[1][y][tmp] == 0 then
						break
					end 
					tmp = tmp - 1
				end
			end
		end
	end
	--down
	if x ~= 19 then
		--possible 
		if color == 1 then
			--white stone
			if existTensor[1][y][x+1] == 2 then
				--has black stone in this direction could countinue 
				tmp = x+1
				while  tmp < 20 do
					--start loop
					if existTensor[1][y][tmp] == 1 then
						--find the other side of ladderfinished
						existTensor[9]:fill(1)--mark the start
						break
					end
					if existTensor[1][y][tmp] == 0 then
						break
					end
					tmp = tmp + 1
				end
			end
		else
			--black stone
			if existTensor[1][y][x+1] == 1 then
				--has white stone in this direction could countinue 
				tmp = x+1
				while  tmp < 20 do
					--start loop
					if existTensor[1][y][tmp] == 2 then
						--find the other side of ladderfinished
						existTensor[10]:fill(1)
						--existTensor[10][y][tmp] = 1 --mark the end
						break
					end
					if existTensor[1][y][tmp] == 0 then
						break
					end 
					tmp = tmp + 1
				end
			end
		end
	end
	return existTensor
end
local tmpNumW = 0
local tmpNumB = 0
--check if there is any capture stone
local function capture( existTensor, color )
	local num = 0
	local tmpNum
	--check liberties for each area
	if color == 1 then
		--print(numW)
		--the largest possible capture area is equal to numW
		tmpNum = torch.Tensor(numW):fill(0)
		--check white liberties
		for i=1, 19 do
			for j=1, 19 do
				if existTensor[6][i][j] == 0 then
					--stone is capture,calculate the number of captured stone 
					--record tmp No for the erea
					local k--to record the number for tmpNum
					for k=1, numW do
						--print(k)
						if tmpNum[k] == existTensor[3][i][j] then
							--already exist
							break
						else
							if tmpNum[k] == 0 then
								tmpNum[k] = existTensor[3][i][j]
								--find a new place
								break
							end
						end
					end
					num = num + 1
				end
			end
		end
		for i = 1, 19 do
			for j = 1, 19 do
				if existTensor[6][i][j] == 0 then
					--add number of captured stone on the map
					--need refresh,just need to
					--remove it from the broad 
					existTensor[1][i][j] = 0
					--remove it from the area map
					existTensor[3][i][j] = 0
					--remove it from the area of liberty
					existTensor[6][i][j] = 10
					existTensor[11][i][j] = 1
				end
			end
		end
		tmpNumW = num
		--if need refresh
		--rearrange
		local tmpNum_idx = torch.Tensor(numW):fill(0)
		for k = 1, numW do
			if tmpNum[k] ~= 0 then
				--have area
				tmp = tmpNum[k]
				tmpNum_idx[tmp] = tmp
			end
		end
		local total = numW
		--start from the top
		while total > 0 do
			if tmpNum_idx[total] ~= 0 then
				for i = 1, 19 do
					for j = 1, 19 do
						if existTensor[3][i][j] > tmpNum_idx[total] then
							existTensor[3][i][j] = existTensor[3][i][j] - 1
						end
					end
				end
				numW = numW - 1
			end
			total = total-1
		end
	end
	--check liberties for each area
	if color == 2 then
		--
		tmpNum = torch.Tensor(numB):fill(0)
		--check white liberties
		for i=1, 19 do
			for j=1, 19 do
				if existTensor[8][i][j] == 0 then
					--stone is capture,calculate the number of captured stone 
					--record tmp No for the erea
					--to record the number for tmpNum
					for k = 1, numB do
						if tmpNum[k] == existTensor[4][i][j] then
							--already exist
							break
						else
							if tmpNum[k] == 0 then
								--find a new place
								tmpNum[k] = existTensor[4][i][j]
								break
							end
						end
					end
					--stone is capture,calculate the number of caputured stone 
					num = num + 1
				end
			end
		end
		for i = 1, 19 do
			for j = 1, 19 do
				if existTensor[8][i][j] == 0 then
					--add number of captured stone on the map
					--need refresh 
					--remove it from the broad 
					existTensor[1][i][j] = 0
					--remove it from the area map
					existTensor[4][i][j] = 0
					existTensor[8][i][j] = 10
					existTensor[12][i][j] = 1
				end
			end
		end
		tmpNumB = num
		--print(tmpNumB)
		--rearrange
		local tmpNum_idx = torch.Tensor(numB):fill(0)
		for k = 1, numB do
			if tmpNum[k] ~= 0 then
				--have area
				tmp = tmpNum[k]
				tmpNum_idx[tmp] = tmp
			end
		end
		local total = numB
		--start from the top
		while total > 0 do
			if tmpNum_idx[total] ~= 0 then
				for i = 1, 19 do
					for j = 1, 19 do
						if existTensor[4][i][j] > tmpNum_idx[total] then
							existTensor[4][i][j] = existTensor[4][i][j] - 1
						end
					end
				end
				numB = numB - 1
			end
			total = total-1
		end
	end
	return existTensor
	-- body
end

local function renewLiberty( existTensor )
	--renew liberties for white
	for  k=1, numW - 1 do -- there will be totally numB black area
		--create tmporary map to record one area and its boundary
		tmpBoundary = torch.Tensor(19,19):fill(0)
		--find one perticular position in the area K
		tmpX = 0
		tmpY = 0
		for i = 1, 19 do
			for j = 1, 19 do
				if existTensor[3][i][j] == k then
					--find one stone in this area
					tmpX = j
					tmpY = i
				end
			end
		end
		possiblel(existTensor[3],tmpY,tmpX)
		existTensor = updatel (tmpBoundary,existTensor,1)
	end
	--renew liberties for black
	for  k=1, numB - 1 do -- there will be totally numB black area
		tmpBoundary = torch.Tensor(19,19):fill(0)
		tmpX = 0
		tmpY = 0
		for i=1, 19 do
			for j=1, 19 do
				if existTensor[4][i][j] == k then
					--find one stone in this area
					tmpX = j
					tmpY = i
				end
			end
		end
		possiblel(existTensor[4],tmpY,tmpX)
		existTensor = updatel (tmpBoundary,existTensor,2)
	end
	return existTensor
end
--create capture feature 
--[[local function captureFeature( existTensor, color )
	--feature 11 is the number of capured white stone, stored in the stone position
	--feature 12 is the number of capured black stone, stored in the stone position
	--feature 35,36,37,38,39,40,41 might capture 1,2,3,4,5,6,>= 7 for white 
	--feature 42,43,44,45,46,47,48 might capture 1,2,3,4,5,7,>= 7 for black

	if color == 1 then
		--white stone 
		local tmp = tmpNumW
		existTensor[35]:fill(0)
		existTensor[36]:fill(0)
		existTensor[37]:fill(0)
		existTensor[38]:fill(0)
		existTensor[39]:fill(0)
		existTensor[40]:fill(0)
		existTensor[41]:fill(0)
		if tmp < 7 then
			existTensor[35+tmp-1]:fill(1)
		else
			existTensor[41]:fill(1)
		end
	end
	if color == 2 then
		--black stone 
		local tmp = tmpNumB
		existTensor[42]:fill(0)
		existTensor[43]:fill(0)
		existTensor[44]:fill(0)
		existTensor[45]:fill(0)
		existTensor[46]:fill(0)
		existTensor[47]:fill(0)
		existTensor[48]:fill(0)
		if tmp < 7 then
			existTensor[42+tmp-1]:fill(1)
		else
			existTensor[48]:fill(1)
		end
	end
	return existTensor
end--]]

--create legal feature 
local function legal( existTensor, color )
	if color == 1 then
		--white stone
		--create basic map by putting all position which doesn't equal to 1 or 2  equal to 1
		for i = 1, 19 do
			for j = 1, 19 do
				if existTensor[1][i][j] == 0 then
					existTensor[13][i][j] = 1
				else
					existTensor[13][i][j] = 0
				end
			end
		end
		--mark those captured position illegal 
		for i = 1, 19 do
			for j = 1, 19 do
				if existTensor[11][i][j] ~= 0 then
					local check = false
					--chcek whether this position could cause another capture 
					--by checking if any surrounded other color stone has only 1 liberty
					if i ~= 1 then 
						--check left
						if existTensor[8][i-1][j] == 1 then
							check = true
						end
					end
					if i ~= 19 then
						--check right
						if existTensor[8][i+1][j] == 1 then
							check = true
						end
					end
					if j ~= 1 then
						--check up
						if existTensor[8][i][j-1] == 1 then
							check = true
						end
					end
					if j ~= 19 then
						--check down
						if existTensor[8][i][j+1] == 1 then
							check = true
						end
					end
					if check == false then
						--illegal
						existTensor[13][i][j] = 0
					else
						--legal
						existTensor[13][i][j] = 1
					end
				end
			end 
		end
	end
	if color == 2 then
		--black stone
		--create basic map by putting all position which doesn't equal to 1 or 2  equal to 1
		for i = 1, 19 do
			for j = 1, 19 do
				if existTensor[1][i][j] == 0 then
					existTensor[14][i][j] = 1
				else
					existTensor[14][i][j] = 0
				end
			end
		end
		--mark those captured position illegal 
		for i = 1, 19 do
			for j = 1, 19 do
				if existTensor[12][i][j] ~= 0 then
					local check = false
					--chcek whether this position could cause another capture 
					--by checking if any surrounded other color stone has only 1 liberty
					if i ~= 1 then 
						--check left
						if existTensor[6][i-1][j] == 1 then
							check = true
						end
					end
					if i ~= 19 then
						--check right
						if existTensor[6][i+1][j] == 1 then
							check = true
						end
					end
					if j ~= 1 then
						--check up
						if existTensor[6][i][j-1] == 1 then
							check = true
						end
					end
					if j ~= 19 then
						--check down
						if existTensor[6][i][j+1] == 1 then
							check = true
						end
					end
					if check == false then
						--illegal
						existTensor[14][i][j] = 0
					else
						--legal
						existTensor[14][i][j] = 1
					end
				end
			end 
		end
	end
	return existTensor
	-- body
end
--create seperate abroad 
local function braodFeature( existTensor )
	--do not need to distinguish white from black
	--feature 23,24,25 -- white black empty / pay attention, for white stone, use 23,24,25, for black stone, use 24,23,25
	--feature 26 history for white
	--feature 27 history for black
	existTensor[23]:fill(0)
	existTensor[24]:fill(0)
	existTensor[25]:fill(0)
	for i = 1, 19 do
		for j = 1, 19 do
			if existTensor[1][i][j] == 1 then
				--white
				existTensor[23][i][j] = 1
			end
			if existTensor[1][i][j] == 2 then
				--black
				existTensor[24][i][j] = 1
			end
			if existTensor[1][i][j] == 0 then
				--empty
				existTensor[25][i][j] = 1
			end
		end
	end
	return existTensor
end

local function bwFeature( nextMove, existTensor )
	-- body
	local tmp = nextMove
	
	--improve each history move by one
	for i=1,19 do
		for j=1,19 do
			if existTensor[2][i][j] ~=0 then
				existTensor[2][i][j] = existTensor[2][i][j]+1
			end
		end
	end
	--dupliccate present liberty feature and use it as former 
	--check if it is a move setence
	--decide white or blace 
	x = tmp[3]-97+1
	y = tmp[4]-97+1
	existTensor[46]:fill(0)
	existTensor[46][y][x] = 1
	if tmp[1]==87 then
		--white, change alpha into number, record as 1
		existTensor[1][y][x] = 1
		--add a new move on the map
		--create broad features
		existTensor = braodFeature(existTensor)
		--existTensor[26] = existTensor[26]:mul(0.1)
		--existTensor[26][y][x] = 1
		existTensor[2][y][x] = 1
		for i = 1, 19 do
			for j = 1, 19 do
				if existTensor[2][i][j] ~= 0 then
					--have stone on i,j position
					if existTensor[1][i][j] == 1 then
						--white stone
						--print(existTensor[2][i][j]*(-0.1))
						existTensor[26][i][j] = torch.exp(existTensor[2][i][j]*(-0.1))
					end
				end
				if existTensor[26][i][j] ~= 0 then
					--for caputured stone
					if existTensor[1][i][j] == 0 then
						existTensor[26][i][j] = torch.exp(existTensor[2][i][j]*(-0.1))
					end
				end
			end
		end
		--define area, check stone [y-1][x] [y+1][x] [y][x-1] [y][x+1] 
		--set a tmp area number
		--add position mask exp(-0.5*l^2)
		existTensor[47][y][x] = torch.exp((-0.5)*torch.pow(((y-10)*(y-10)+(x-10)*(x-10)),0.5))
		existTensor[3][y][x] = numW
		--refresh the whole map, start from the position of ston
		existTensor[3] = refresh(existTensor[3],true,y,x)
		if existTensor[3][y][x] == numW then 
			numW = numW + 1
		end
		--print(existTensor[3])
		---renew liberties for white
		existTensor[5] = existTensor[6]
		--renew liberties
		existTensor = renewLiberty(existTensor)

		-- create feature for liberties
		existTensor = getliberties(existTensor,1)
		--check whether there is any capture stone
		existTensor = capture (existTensor, 2)
		--create capture feature
		--existTensor = captureFeature(existTensor,2)
		--renew liberties
		existTensor = renewLiberty(existTensor)
		--renew ladder
		existTensor = possibleLadder (existTensor, y, x, 1)
		--check legal 
		existTensor = legal (existTensor,1)
		--create laddel move for white 
		--print(existTensor[10])
		--print(existTensor[2])
		--print(existTensor[1])
		--print(existTensor[47])
	end
	if tmp[1]==66 then
		--black, change alpha into number, record as 2
		existTensor[1][y][x] = 2
		--add a new move on the map
		existTensor[2][y][x] = 1
		--add a new move on the map
		--create broad features
		existTensor = braodFeature(existTensor)
		--existTensor[27] = existTensor[27]:mul(0.1)
		--existTensor[27][y][x] = 1
		for i = 1, 19 do
			for j = 1, 19 do
				if existTensor[2][i][j] ~= 0 then
					--have stone on i,j position
					if existTensor[1][i][j] == 2 then
						--black stone
						existTensor[27][i][j] = torch.exp(existTensor[2][i][j]*(-0.1))
					end
				end
				if existTensor[27][i][j] ~= 0 then
					--for caputured stone
					if existTensor[1][i][j] == 0 then
						existTensor[27][i][j] = torch.exp(existTensor[2][i][j]*(-0.1))
					end
				end
			end
		end
		--define area, check stone [y-1][x] [y+1][x] [y][x-1] [y][x+1]
		--position mask
		existTensor[47][y][x] = torch.exp((-0.5)*torch.pow(((y-10)*(y-10)+(x-10)*(x-10)),0.5))
		--set a tmp area number 
		existTensor[4][y][x] = numB
		--refresh the whole map, start from the position of stone
		existTensor[4] = refresh(existTensor[4],true,y,x)
		if existTensor[4][y][x] == numB then
			numB = numB + 1
		end

		existTensor[7] = existTensor[8]
		--renew liberties
		existTensor = renewLiberty(existTensor)
		-- create feature for liberties
		-- create feature for liberties
		existTensor = getliberties(existTensor,2)
		--captured stone
		existTensor = capture(existTensor, 1)
		--create capture feature
		--existTensor = captureFeature(existTensor,1)
		--renew liberties
		existTensor = renewLiberty(existTensor)
		--renew ladder
		existTensor = possibleLadder (existTensor, y, x, 2)
		--check legal 
		existTensor = legal (existTensor,2)
		--print(existTensor[10])
		--print(existTensor[8])--]]
	end
	--print(numW)
	--print(existTensor[1])

	--print(numW)
	return existTensor
end

--feature 1 is for stone
--feature 2 is for how long the move has been mad
--feature 3 is area for white 
--feature 4 is area for black
--feature 5 is liberty for white before initialize with 10
--feature 6 is liberty for white after initialize with 10
--feature 7 is liberty for black before initialize with 10
--feature 8 is liberty for black after initialize with 10
--feature 9 is record of ladder move for white	
--feature 10 is record of ladder move for blace
--feature 11 is the number of capured white stone, stored in the stone position √
--feature 12 is the number of capured black stone, stored in the stone position √
--feature 13 is the legal position for white √
--feature 14 is the legal position for black √
--feature 15,16,17,18 with 1, 2, 3, >= 4 liberties for white √
--feature 19,20,21,22 with 1, 2, 3, >= 4 liberties for black √
--feature 23,24,25 -- white black empty / pay attention, for white stone, use 23,24,25, for black stone, use 24,23,25 √
--feature 26 history for white √
--feature 27 history for black √
--feature 28,29,30,31,32,33,34,35,36 rank 1-8 white √
--feature 37,38,39,40,41,42,43,44,45 rank 1-8 black √
--feature 46 just record current move 
--feature 47 position distance--√for both


local path = '/scratch/jy2293'
print('path')
print(path)
local year = 2010
--calculate number in the fold 
local fileNum = torch.Tensor(4):fill(0)
while year < 2014 do
	--print(year)
	local fileIndex = 1
	while fileIndex < 3000 do
		local file = io.open(path..'/'..year..'/'..fileIndex..'.sgf','r')
		if file ~= nil then
			fileNum[year-2010+1] = fileNum[year-2010+1]+1
			--print(fileNum[year-2010+1])
		else
			break
		end
		file:close()
		fileIndex = fileIndex + 1
	end
	year = year + 1
end
print(fileNum)
--600 game 40 steps 26 features 19x19 broad
--300 for train 30 for test
local dataset = torch.Tensor(600,40,27,19,19):fill(0)
local answerset = torch.Tensor(600,40,361):fill(0)
--local dataset = torch.Tensor(30,40,26,19,19):fill(0)
--local answerset = torch.Tensor(30,40,361):fill(0)

--save the actual action number for each game

local features = torch.Tensor(47,19,19):fill(0)
for i=1,1 do
	for j=1,19 do
		features[5] = 10
		features[6] = 10
		features[7] = 10
		features[8] = 10
	end
end

local index = 1
local number = 0
local total = fileNum[1] + fileNum[2] + fileNum[3] + fileNum[4]
print(total)
--get the number of total game 
local year = 2010
local fileIndex = 1
while index < total do
	--get year and fileIndex through index
	while true do
		if index < fileNum[1] + 1 then
			year = 2010
			fileIndex = index
			break
		end
		if index < fileNum[1] + fileNum[2] + 1 then
			year = 2011
			fileIndex = index - fileNum[1]
			break
		end 
		if index < fileNum[1] + fileNum[2] + fileNum[3] + 1 then
			fileIndex = index - fileNum[1] - fileNum[2]
			year = 2012
			break
		end
		fileIndex = index - fileNum[1] - fileNum[2] - fileNum[3]
		year = 2013
		break
	end
	print(year)
	print(fileIndex)

	local file = io.open(path..'/'..year..'/'..fileIndex..'.sgf','r')
	if file ~= nil then
		--load file
		number = number + 1
		if number > 600 then
			print(number)
			break
		end
		--a game a features
		features:fill(0)
		features[5] = 10
		features[6] = 10
		features[7] = 10
		features[8] = 10

		numW = 1
		numB = 1
		local content = file:read('*all')
		file:close()
		local section = string.split(content,';')
		--store the whole game
		local game = torch.Tensor(#section,47,19,19):fill(0)
		--print(#game)
		--head file
		local head = torch.CharStorage(#section[2]):string(section[2])
		for i = 1, #section[2] do
			if head[i] == 87 then	
				if head[i+1] == 82 then
					--WR
					rankW = head[i+3]-48
					if rankW < 9 then
						features[28+rankW-1]:fill(-1)
					end
					if rankW == 9 then
						features[28+rankW-1]:fill(1)
						print("higher than 9 white")
					end
					if rankW > 9 then
						print('out of range.')
					end
					break
				end
			end
		end	
		for i = 1, #section[2] do
			if head[i] == 66 then	
				if head[i+1] == 82 then
					--BR
					rankW = head[i+3]-48
					if rankW < 9 then
						features[37+rankW-1]:fill(-1)
					end
					if rankW == 9 then
						features[37+rankW-1]:fill(1)
						print("higher than 9 black")
					end
					break
					if rankW > 9 then
						print('out of range.')
					end
					break
				end
			end
		end
		print(string.format("game %d, file %d",number,index))
		for line = 3, #section do
			local tmp = torch.CharStorage(#section[line]):string(section[line])
			features = bwFeature(tmp,features)
			game[line] = features
			--print(game[line][1])
			--print(game[line][46])
		end
		--random integer from 3 to #section-1
		local randomInt = torch.Tensor(40)
		randomInt:random(3,#section-1)
		--print(randomInt)
		for j = 1,40 do
			if randomInt[j]%2 == 1 then
				--wait for white to decide next step--]]
				dataset[number][j][1] = game[randomInt[j]][23]--braod information
				dataset[number][j][2] = game[randomInt[j]][24]
				dataset[number][j][2]:mul(-1)
				dataset[number][j][3] = game[randomInt[j]][25]
				dataset[number][j][4] = game[randomInt[j]][13]--legal position
				dataset[number][j][5] = game[randomInt[j]][26]--history 
				dataset[number][j][6] = game[randomInt[j]][27]
				dataset[number][j][6]:mul(-1)
				dataset[number][j][7] = game[randomInt[j]][15]--liberties
				dataset[number][j][8] = game[randomInt[j]][16]
				dataset[number][j][9] = game[randomInt[j]][17]
				dataset[number][j][10] = game[randomInt[j]][18]
				dataset[number][j][11] = game[randomInt[j]][19]--liberties
				dataset[number][j][12] = game[randomInt[j]][20]
				dataset[number][j][13] = game[randomInt[j]][21]
				dataset[number][j][14] = game[randomInt[j]][22]
				dataset[number][j][15] = game[randomInt[j]][11]--capture
				dataset[number][j][16] = game[randomInt[j]][12]
				dataset[number][j][17] = game[randomInt[j]][9]--ladder
				dataset[number][j][18] = game[randomInt[j]][37]--rank
				dataset[number][j][19] = game[randomInt[j]][38]
				dataset[number][j][20] = game[randomInt[j]][39]
				dataset[number][j][21] = game[randomInt[j]][40]
				dataset[number][j][22] = game[randomInt[j]][41]
				dataset[number][j][23] = game[randomInt[j]][42]
				dataset[number][j][24] = game[randomInt[j]][43]
				dataset[number][j][25] = game[randomInt[j]][44]
				dataset[number][j][26] = game[randomInt[j]][45]
				dataset[number][j][27] = game[randomInt[j]][47]--position mask
			else
				--wait for black to decide next stone
				dataset[number][j][1] = game[randomInt[j]][24]
				dataset[number][j][2] = game[randomInt[j]][23]
				dataset[number][j][2]:mul(-1)
				dataset[number][j][3] = game[randomInt[j]][25]
				dataset[number][j][4] = game[randomInt[j]][14]
				dataset[number][j][5] = game[randomInt[j]][27]
				dataset[number][j][6] = game[randomInt[j]][26]
				dataset[number][j][6]:mul(-1)
				dataset[number][j][7] = game[randomInt[j]][19]
				dataset[number][j][8] = game[randomInt[j]][20]
				dataset[number][j][9] = game[randomInt[j]][21]
				dataset[number][j][10] = game[randomInt[j]][22]
				dataset[number][j][11] = game[randomInt[j]][15]
				dataset[number][j][12] = game[randomInt[j]][16]
				dataset[number][j][13] = game[randomInt[j]][17]
				dataset[number][j][14] = game[randomInt[j]][18]
				dataset[number][j][15] = game[randomInt[j]][12]
				dataset[number][j][16] = game[randomInt[j]][11]
				dataset[number][j][17] = game[randomInt[j]][10]
				dataset[number][j][18] = game[randomInt[j]][28]
				dataset[number][j][19] = game[randomInt[j]][29]
				dataset[number][j][20] = game[randomInt[j]][30]
				dataset[number][j][21] = game[randomInt[j]][31]
				dataset[number][j][22] = game[randomInt[j]][32]
				dataset[number][j][23] = game[randomInt[j]][33]
				dataset[number][j][24] = game[randomInt[j]][34]
				dataset[number][j][25] = game[randomInt[j]][35]
				dataset[number][j][26] = game[randomInt[j]][36]
				dataset[number][j][27] = game[randomInt[j]][47]
			end
			--record answer 
			--print(dataset[number][j][27])
			answerset[number][j] = torch.reshape(game[randomInt[j]+1][46],361)
		end
	else
		break
	end
	index = index + 2
end

torch.save("dataset-4800-c26-1.t7",dataset)
torch.save("answerset-4800-c26-1.t7",answerset)
--extract sample feature to 

