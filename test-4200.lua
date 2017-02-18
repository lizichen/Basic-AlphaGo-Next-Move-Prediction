require 'torch'
require 'optim'
require 'os'
require 'optim'
require 'xlua'
require 'cunn'
require 'cudnn' -- faster convolutions

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

local trainData = torch.load(DATA_PATH..'testdata-2400-c26.t7')
trainData = torch.reshape(trainData,2400,1,27,19,19)
trainData = trainData:cuda()
local target = torch.load(DATA_PATH..'testanswer-2400-c26.t7')
target = torch.reshape(target,2400,361)
target_new = torch.Tensor(2400,1)
for i = 1, 2400 do
    for j = 1,361 do
        if target[i][j] == 1 then
            target_new[i][1] =j
        end
    end
end
target_new=target_new:cuda()
--print(target_new)

--local testData = torch.load(DATA_PATH..'test.t7')
function getIterator(dataset)
    --[[
    -- Hint:  Use ParallelIterator for using multiple CPU cores
    --]]
    return tnt.DatasetIterator{
        dataset = tnt.BatchDataset{
            batchsize = opt.batchsize,
            dataset = dataset
        }
    }
end

testDataset = tnt.ListDataset{
    list = torch.range(1, trainData:size(1)):long(),
    load = function(idx)
        return {
            input = trainData[idx],
            answer = target_new[idx]
        }
    end
}


--[[
-- Hint:  Use :cuda to convert your model to use GPUs
--]]
local model = torch.load('model-4200-c26-30.bin')
--model:cuda()
local engine = tnt.OptimEngine()
local meter = tnt.AverageValueMeter()
local criterion = nn.CrossEntropyCriterion()
local clerr = tnt.ClassErrorMeter{topk = {1}}
local timer = tnt.TimeMeter()
local batch = 1

--local exist_model = torch.load('model.bin')

-- print(model)

engine.hooks.onStart = function(state)

    meter:reset()
    clerr:reset()
    timer:reset()
    batch = 1
    if state.training then
        mode = 'Train'
    else
        mode = 'Val'
    end
end

--[[
-- Hint:  Use onSample function to convert to 
--        cuda tensor for using GPU
--]]
-- engine.hooks.onSample = function(state)
-- end

engine.hooks.onForwardCriterion = function(state)
    meter:add(state.criterion.output)
    clerr:add(state.network.output, state.sample.target)
    if opt.verbose == true then
        print(string.format("%s Batch: %d/%d; avg. loss: %2.4f; avg. error: %2.4f",
                mode, batch, state.iterator.dataset:size(), meter:value(), clerr:value{k = 1}))
    else
        xlua.progress(batch, state.iterator.dataset:size())
    end
    batch = batch + 1 -- batch increment has to happen here to work for train, val and test.
    timer:incUnit()
end

engine.hooks.onEnd = function(state)
    print(string.format("%s: avg. loss: %2.4f; avg. error: %2.4f, time: %2.4f",
    mode, meter:value(), clerr:value{k = 1}, timer:value()))
end

--local epoch = 1
local correct = 0
local almost = 0
print(model)
local rank_num = torch.Tensor(9):fill(0)
local rank_base = torch.Tensor(9):fill(0)
for i = 1,1200 do

    --[[trainDataset:select("train")
    iterator = getIterator(trainDataset)--]]
    --iterator:exec('resample')

    --iterator = getIterator(trainDataset)
    --for example in iterator() do

        tmp = trainData[i]
        local rank = 0
        for j = 18, 26 do
            if trainData[i][1][j][1][1] ~= 0 then
                rank = j-18+1
                rank_num[rank] = rank_num[rank] + 1
                --print(string.format('rank %d',rank))
                break
            end
        end
        model:forward(tmp)
        output = model.output
        --print(#tmp)
        local  biggest = 0
        local  label = 1
        for j = 1, 361 do 
            if biggest < output[j] then
                biggest = output[j]
                label = j
            end
        end
        if label==target_new[i][1] then
            correct = correct + 1
            if rank ~= 0 then
                rank_base[rank] = rank_base[rank] + 1
            end
            --print(correct)
        end

        --print(label)
        --print(target_new[i])
        --print(output)
        --[[print(#tmp)
        model:get(1):forward(tmp)
        tmp = model:get(1).output

        model:get(2):forward(tmp)
        tmp = model:get(2).output

        model:get(3):forward(tmp)
        tmp = model:get(3).output

        print(#model:get(3).output)

        model:get(4):forward(tmp)
        tmp = model:get(4).output

        model:get(5):forward(tmp)
        tmp = model:get(5).output

        --print(model:get(4).output)
        model:get(6):forward(tmp)
        tmp = model:get(6).output

        print(#model:get(6).output)

        model:get(7):forward(tmp)
        tmp = model:get(7).output
        
        model:get(8):forward(tmp)
        tmp = model:get(8).output

        model:get(9):forward(tmp)
        tmp = model:get(9).output

        print(#model:get(9).output)
        --print(#tmp[1])
        --print(#tmp[2])

    end--]]


    --[[trainDataset:select('train')
    engine:train{
        network = model,
        criterion = criterion,
        iterator = iterator,
        optimMethod = optim.sgd,
        maxepoch = 1,
        config = {
            learningRate = opt.LR,
            momentum = opt.momentum
        }
    }

    trainDataset:select('val')
    iterator = getIterator(trainDataset)
    iterator:exec('resample')
    engine:test{
        network = model,
        criterion = criterion,
        iterator = getIterator(trainDataset)
    }
    print('Done with Epoch '..tostring(epoch))
    epoch = epoch + 1--]]
end

--[[local submission = assert(io.open(opt.logDir .. "/submission2.csv", "w"))
submission:write("Filename,ClassId\n")
batch = 1--]]

--[[
--  This piece of code creates the submission
--  file that has to be uploaded in kaggle.
--]]

engine.hooks.onForward = function(state)
    local target  = state.sample.answer
    local _, pred = state.network.output:max(2)
    pred = pred - 1
    for i = 1, pred:size(1) do
        if target[i][1] == pred[i][1] then
            correct = correct + 1
        end
        if target_new[i][1] - pred[i][1] <= 2 then
            almost = almost + 1
        end
        print(string.format("%d vs %d\n", target[i][1],pred[i][1]))
    end
    xlua.progress(batch, state.iterator.dataset:size())
    batch = batch + 1
end

engine.hooks.onEnd = function(state)
    --submission:close()
end
for i =1, 9 do
    print(string.format('rank: %d num: %d correct: %d',i,rank_num[i],rank_base[i]))
end
--engine:test{
    --network = model,
    --iterator = getIterator(testDataset)
--}
--print('Saving network.')
--model:clearState()
--torch.save('model.bin', model)
print(correct)
print(almost)
print("The End!")
