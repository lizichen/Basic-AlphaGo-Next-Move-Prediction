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
local optParser = require 'opts-27'
local opt = optParser.parse(arg)

local WIDTH, HEIGHT = 48, 48
--local WIDTH,HEIGHT =32,32
local DATA_PATH = (opt.data ~= '' and opt.data or './data/')

torch.setdefaulttensortype('torch.DoubleTensor')

-- torch.setnumthreads(1)
torch.manualSeed(opt.manualSeed)
-- cutorch.manualSeedAll(opt.manualSeed)

function resize(img)
    return image.scale(img, WIDTH,HEIGHT)
end

function crop(img,r)
    --print(r)
    return image.crop(img,r[5],r[6],r[7],r[8])
end
function cropT(img,r)
    --print(r)
    return image.crop(img,r[4],r[5],r[6],r[7])
end
function yuv(img)
    return image.rgb2y(img)
end

function grey( im )
    local dim, w, h = im:size()[1], im:size()[2], im:size()[3]
    if dim ~= 3 then
         print('<error> expected 3 channels')
         return im
    end

    -- a cool application of tensor:select
    local r = im:select(1, 1)
    local g = im:select(1, 2)
    local b = im:select(1, 3)

    local z = torch.Tensor(w, h):zero()

    -- z = z + 0.21r
    z = z:add(0.21, r)
    z = z:add(0.72, g)
    z = z:add(0.07, b)
    return z
end

function mean(img)
    return img-torch.mean(img)
end

function  contract_normalization( img )
    return image.lcn(img,image.gaussian(5))
end

--[[
-- Hint:  Should we add some more transforms? shifting, scaling?
-- Should all images be of size 32x32?  Are we losing 
-- information by resizing bigger images to a smaller size?
--]]
function transformInput(inp,r,type)
    --print(type)
    --image.display(inp)
    if type == "train" then
        inp = crop(inp,r)
        inp = resize(inp)
        inp = grey(inp)
        inp = contract_normalization(inp)
        --
        --inp = yuv(inp)
        --inp = mean(inp)
        inp = torch.reshape(inp,1,44,44)
    else
        inp = cropT(inp,r)
        inp = resize(inp)
        inp = grey(inp)
        inp = contract_normalization(inp)
        --
        --inp = yuv(inp)
        --inp = mean(inp)
        inp = torch.reshape(inp,1,44,44)
    end
    return inp
end

function getTrainSample(dataset, idx)
    r = dataset[idx]
    classId, track, file = r[9], r[1], r[2]
    file = string.format("%05d/%05d_%05d.ppm", classId, track, file)
    return transformInput(image.load(DATA_PATH .. '/train_images/'..file),r,"train")
end

function getTrainLabel(dataset, idx)
    return torch.LongTensor{dataset[idx][9] + 1}
end

function getTestSample(dataset, idx)
    r = dataset[idx]
    file = DATA_PATH .. "/test_images/" .. string.format("%05d.ppm", r[1])
    return transformInput(image.load(file),r,"test")
end

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

local trainData = torch.load(DATA_PATH..'dataset-4200-c26.t7')
--print(#trainData)
--trainData = torch.reshape(trainData,48000,27,19,19)
trainData = trainData:cuda()
local target_new = torch.load(DATA_PATH..'answerset-4200-c26.t7')
--print(#target)
target_new = target_new:cuda()
--print(target_new)

--local testData = torch.load(DATA_PATH..'test.t7')

function resampling()
    dataset = tnt.ShuffleDataset{
        dataset = tnt.ListDataset{
            list = torch.range(1, trainData:size(1)):long(),
            load = function(idx)
                return {
                    input =  trainData[idx],
                    target = target_new[idx]
                }
            end
        }
    }
    return dataset
end

trainDataset = tnt.SplitDataset{
    partitions = {train=0.9, val=0.1},
    initialpartition = 'train',
    --[[
    --  Hint:  Use a resampling strategy that keeps the 
    --  class distribution even during initial training epochs 
    --  and then slowly converges to the actual distribution 
    --  in later stages of training.
    --]]
    dataset = resampling()
}

--[[testDataset = tnt.ListDataset{
    list = torch.range(1, testData:size(1)):long(),
    load = function(idx)
        return {
            input = getTestSample(testData, idx),
            sampleId = torch.LongTensor{testData[idx][1]}
        }
    end
}--]]


--[[
-- Hint:  Use :cuda to convert your model to use GPUs
--]]
local model = require(opt.model)
model:cuda()
local engine = tnt.OptimEngine()
local meter = tnt.AverageValueMeter()
local criterion = nn.CrossEntropyCriterion()
criterion = criterion:cuda()
local clerr = tnt.ClassErrorMeter{topk = {1}}
local timer = tnt.TimeMeter()
local batch = 1

--local exist_model = torch.load('model.bin')

print(model)

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

local epoch = 1
while epoch <= opt.nEpochs do

    trainDataset:select("train")
    iterator = getIterator(trainDataset)
    --iterator:exec('resample')

    --[[iterator = getIterator(trainDataset)
    for example in iterator() do

        tmp = example.input
        output = example.target
        --print(#tmp)
        print(#output)
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


    trainDataset:select('train')
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
    if epoch % 10 ==0 then
        torch.save('model-4200-c26-l-'..epoch..'.bin', model)
    end
    epoch = epoch + 1
end

--[[local submission = assert(io.open(opt.logDir .. "/submission2.csv", "w"))
submission:write("Filename,ClassId\n")
batch = 1--]]

--[[
--  This piece of code creates the submission
--  file that has to be uploaded in kaggle.
--]]
engine.hooks.onForward = function(state)
    local fileNames  = state.sample.sampleId
    local _, pred = state.network.output:max(2)
    pred = pred - 1
    for i = 1, pred:size(1) do
        submission:write(string.format("%05d,%d\n", fileNames[i][1], pred[i][1]))
    end
    xlua.progress(batch, state.iterator.dataset:size())
    batch = batch + 1
end

engine.hooks.onEnd = function(state)
    submission:close()
end

--[[engine:test{
    network = model,
    iterator = getIterator(testDataset)
}--]]
print('Saving network.')
model:clearState()
torch.save('model-4200-c26-l.bin', model)
print("The End!")
