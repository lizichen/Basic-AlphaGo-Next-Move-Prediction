local nn = require 'nn'


local Convolution = nn.SpatialConvolutionMM
--trying
local ReLU = nn.ReLU
local Max = nn.SpatialMaxPooling
local View = nn.View
local Linear = nn.Linear
local Softmax = nn.LogSoftMax
local Spatialbn = nn.SpatialBatchNormalization

local model  = nn.Sequential()

model:add(Convolution(27, 92, 5, 5, 1, 1, 2, 2))
model:add(ReLU())
model:add(Spatialbn(92))

model:add(Convolution(92, 384, 3, 3, 1, 1, 1, 1))
model:add(ReLU())
model:add(Spatialbn(384))

model:add(Convolution(384, 384, 3, 3, 1, 1, 1, 1))
model:add(ReLU())
model:add(Spatialbn(384))

model:add(Convolution(384, 384, 3, 3, 1, 1, 1, 1))
model:add(ReLU())
model:add(Spatialbn(384))

model:add(Convolution(384, 384, 3, 3, 1, 1, 1, 1))
model:add(ReLU())
model:add(Spatialbn(384))

model:add(Convolution(384, 384, 3, 3, 1, 1, 1, 1))
model:add(ReLU())
model:add(Spatialbn(384))

model:add(Convolution(384, 384, 3, 3, 1, 1, 1, 1))
model:add(ReLU())
model:add(Spatialbn(384))

model:add(Convolution(384, 384, 3, 3, 1, 1, 1, 1))
model:add(ReLU())
model:add(Spatialbn(384))

model:add(Convolution(384, 384, 3, 3, 1, 1, 1, 1))
model:add(ReLU())
model:add(Spatialbn(384))

model:add(Convolution(384, 384, 3, 3, 1, 1, 1, 1))
model:add(ReLU())
model:add(Spatialbn(384))

model:add(Convolution(384, 384, 3, 3, 1, 1, 1, 1))
model:add(ReLU())
model:add(Spatialbn(384))

model:add(Convolution(384, 1, 3, 3, 1, 1, 1, 1))

model:add(View(19*19))

return model

