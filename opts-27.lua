local M = {}

function M.parse(arg)
    local cmd = torch.CmdLine();
    cmd:text()
    cmd:text('The German Traffic Sign Recognition Benchmark: A multi-class classification ')
    cmd:text()
    cmd:text('Options:')
    cmd:option('-data',             '/scratch/jy2293/',             'Path to dataset')
    cmd:option('-val',              10,            'Percentage to use for validation set')
    cmd:option('-nEpochs',          40,            'Maximum epochs')
    cmd:option('-batchsize',        128,            'Batch size for epochs')
    cmd:option('-nThreads',         3,              'Number of dataloading threads')
    cmd:option('-manualSeed',       '0',            'Manual seed for RNG')
    cmd:option('-LR',               0.001,           'initial learning rate')
    cmd:option('-momentum',         0.9,            'momentum')
    cmd:option('-weightDecay',      1e-4,           'weight decay')
    cmd:option('-logDir',           'logs',         'log directory')
    cmd:option('-model',            'network-27',     'Model to use for training')
    cmd:option('-verbose',          'false',        'Print stats for every batch')
    --[[
    -- Hint: Use this option to convert your code to use GPUs
    --]]
    -- cmd:option('-cuda',            '',             'Use cuda tensor')

    local opt = cmd:parse(arg or {})

    if opt.model == '' or not paths.filep(opt.model..'.lua') then
        cmd:error('Invalid model ' .. opt.model)
    end

    return opt
end

return M
