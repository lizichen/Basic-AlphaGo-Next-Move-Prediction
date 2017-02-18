require 'torch'
require 'optim'
require 'os'
require 'optim'
require 'xlua'
--require 'cunn'
--require 'cudnn' -- faster convolutions

--[[
--  Hint:  Plot as much as you can.  
--  Look into torch wiki for packages that can help you plot.
--]]

local tnt = require 'torchnet'
local image = require 'image'
local optParser = require 'opts'
local opt = optParser.parse(arg)

local WIDTH, HEIGHT = 48, 48
--local WIDTH,HEIGHT =32,32
local DATA_PATH = (opt.data ~= '' and opt.data or './data/')

torch.setdefaulttensortype('torch.DoubleTensor')

local trainData_1 = torch.load(DATA_PATH..'dataset-4800-c26-1.t7')
trainData_1 = torch.reshape(trainData_1,24000,27,19,19)
local trainData_2 = torch.load(DATA_PATH..'dataset-4800-c26-2.t7')
trainData_2 = torch.reshape(trainData_2,24000,27,19,19)
local trainData_3 = torch.load(DATA_PATH..'dataset-4800-c26-3.t7')
trainData_3 = torch.reshape(trainData_3,24000,27,19,19)
--local trainData_4 = torch.load(DATA_PATH..'dataset-4800-c26-4.t7')
--trainData_4 = torch.reshape(trainData_4,24000,27,19,19)
local trainData_5 = torch.load(DATA_PATH..'dataset-4800-c26-5.t7')
trainData_5 = torch.reshape(trainData_5,24000,27,19,19)
local trainData_6 = torch.load(DATA_PATH..'dataset-4800-c26-6.t7')
trainData_6 = torch.reshape(trainData_6,24000,27,19,19)
local trainData_7 = torch.load(DATA_PATH..'dataset-4800-c26-7.t7')
trainData_7 = torch.reshape(trainData_7,24000,27,19,19)
local trainData_8 = torch.load(DATA_PATH..'dataset-4800-c26-8.t7')
trainData_8 = torch.reshape(trainData_8,24000,27,19,19)
local trainData = torch.Tensor(168000,27,19,19):fill(0)
for i = 1,24000 do
    --print(#trainData[i])
    --print(#trainData_1[i])
    trainData[i] = trainData_1[i]
end
for i = 24001,48000 do
    trainData[i] = trainData_2[i-24000]
end
for i = 48001,72000 do
    trainData[i] = trainData_3[i-48000]
end
for i = 72001,96000 do 
    trainData[i] = trainData_5[i-72000]
end
for i = 96001,120000 do
    --print(#trainData[i])
    --print(#trainData_1[i])
    trainData[i] = trainData_6[i-96000]
end
for i = 120001,144000 do
    trainData[i] = trainData_7[i-120000]
end
for i = 144001,168000 do
    trainData[i] = trainData_8[i-144000]
end
--[[for i = 168001,192000 do 
    trainData[i] = trainData_4[i-168000]
end--]]
--print(#trainData)
--trainData = torch.reshape(trainData,48000,27,19,19)
local target_1 = torch.load(DATA_PATH..'answerset-4800-c26-1.t7')
local target_2 = torch.load(DATA_PATH..'answerset-4800-c26-2.t7')
local target_3 = torch.load(DATA_PATH..'answerset-4800-c26-3.t7')
--local target_4 = torch.load(DATA_PATH..'answerset-4800-c26-4.t7')
local target_5 = torch.load(DATA_PATH..'answerset-4800-c26-5.t7')
local target_6 = torch.load(DATA_PATH..'answerset-4800-c26-6.t7')
local target_7 = torch.load(DATA_PATH..'answerset-4800-c26-7.t7')
local target_8 = torch.load(DATA_PATH..'answerset-4800-c26-8.t7')
--print(#target)
target_1 = torch.reshape(target_1,24000,361)
target_2 = torch.reshape(target_2,24000,361)
target_3 = torch.reshape(target_3,24000,361)
--target_4 = torch.reshape(target_4,24000,361)
target_5 = torch.reshape(target_5,24000,361)
target_6 = torch.reshape(target_6,24000,361)
target_7 = torch.reshape(target_7,24000,361)
target_8 = torch.reshape(target_8,24000,361)

target_new = torch.Tensor(168000,1)
for i = 1, 24000 do
    for j = 1,361 do
        if target_1[i][j] == 1 then
            target_new[i][1] =j
        end
    end
end
for i = 24001, 48000 do
    for j = 1,361 do
        if target_2[i-24000][j] == 1 then
            target_new[i][1] =j
        end
    end
end
for i = 48001, 72000 do
    for j = 1,361 do
        if target_3[i-48000][j] == 1 then
            target_new[i][1] =j
        end
    end
end
for i = 72001, 96000 do
    for j = 1,361 do
        if target_5[i-72000][j] == 1 then
            target_new[i][1] =j
        end
    end
end
for i = 96001, 120000 do
    for j = 1,361 do
        if target_6[i-96000][j] == 1 then
            target_new[i][1] =j
        end
    end
end
for i = 120001, 144000 do
    for j = 1,361 do
        if target_7[i-120000][j] == 1 then
            target_new[i][1] =j
        end
    end
end
for i = 144001, 168000 do
    for j = 1,361 do
        if target_8[i-144000][j] == 1 then
            target_new[i][1] =j
        end
    end
end
--[[for i = 168001, 192000 do
    for j = 1,361 do
        if target_4[i-168000][j] == 1 then
            target_new[i][1] =j
        end
    end
end--]]

torch.save('dataset-4200-c26.t7',trainData)
torch.save('answerset-4200-c26.t7',target_new)
