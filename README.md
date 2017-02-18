##TRAINING A DEEP NEURAL NETWORK FOR COMPUTER GO PLAYER FOR NEXT-MOVE PREDICTION
#### A Class Project in Computer Vision with Deep Learning, by Rob Fergus, Fall 2016

### Intro

Using Deep Convolutional Neural Network(DCNN) based move predictions by comparing and contrasting various training models and data pre-processing approaches from well-known publications. The work is inspired by Facebook Darkforest Go project and the research paper from Tian and Zhu. The Monte Carlo Tree Search (MCTS) is excluded as being off the research area.
  
The DCNN model is trained it with newly purchased data from GoGoD 2015 and compare the result with other publications. 

### Prior Work

Take-away from Papers Facebook Darkforest Go and Maddison’s paper “Deep Go”

After analyzing two models from these two papers by comparison and contrast, we find several interesting points that need to be mentioned and could be used in our own experiments:

1. Training model structure:   
    Darkforest paper uses 12-layer full convolutional network whereas Maddison’s paper has only 6 layers. However, their results are close. Darkforest has 25 feature planes but Maddison’s paper has more: 36 feature planes including liberties after the move, captures after the move, ladder move, etc. Darkforest paper has accuracy that drops when adding too much layers. This justifies Maddison’s paper that they find excessive layers cannot break the learning barrier when a model has more than 12 Covn layers: even though the model gets more layers, the improvement  stalls, and this maybe due to information loss.

2. Using nonlinearity function ReLU instead of Tanh:   
    We find both articles use ReLU method. The definition of ReLU is  f(x) = max(0, x) where x = Weight*a + b. There are basically two benefits: The first one is to induce sparsity when x ≤ 0. If ReLU exists in a layer, it creates more sparse results for the hidden layer. The second one is that ReLU causes less gradient vanishing problem. Since when x > 0, gradient has a constant value whereas sigmoid and tanh will have the gradient smaller when x increases.

3. Using kernel size 5x5 or 3x3:  
      Kernel size has to be odd since we need to have 1 kernel in the middle in order to not blur the graph. Then we find 5 x 5 and 3 x 3 is the most useful kernel size to train Go because: on the one hand, the practice on data shows that low level features within 5 x 5 pixels are representative and we take a close look by using smaller kernel in that situation; on the other hand, if we try to use 1 layer with 7 x 7 filter size as first layer, we had better to use a 2-layer stack with 5 x 5 kernel or a 3-layer stack with 3 x 3 kernel because the later ones use fewer parameters and make the possibility closer to locality.

4. Using of SoftMax and ClassNllCriterion for next move prediction:  
      Softmax classifier can transform hidden units into probability scores of the class labels the model provides. We are able to transform pattern recognition problem into a two dimensional grid classification problems. Since the eventual goal is to figure out the likelihood of next move.

5. Not using Max pooling:  
      We tried max pooling function for every three layers among those 10 consecutive layers in Facebook DarkForest model source code. Our purpose is to discretize the input and keep the most responsive interest points for further layers to analyze. But it turns out to result in lower accuracy. This might be caused: a good move may not be such responsive unless it’s an obvious move; max pooling will prevent some irregular but good moves to show up in the model.


### NEURAL NETWORK ARCHITECTURE

The training process is to extract features from an input and predict a next move based on existing features. To get as accurate prediction as we could. We trying to improve the result accuracy in the following two aspects.

**Training Model:** 
- Our model is based on Facebook’s DarkForest model, which has 12 convolutional layers, each followed by a ReLU non-linear layer and a SpatialBatchNormalization layer. In order to save time, we use 7 Convolutional layers instead of 12 in most tests, but there are also tests with 12 layers but less game datasets.   
- We choose to use convolutional layer with zero stride to ensure that for each 19-by-19 input feature plane, we will get an 19-by-19 output.  We don’t use pooling layers for the same reason. Some paper we read use linear layer after convolutional layer. We try 2 different networks with linear layer: one with 1 linear layer and another with 2 linear layer including 1000 hidden units. Both of them cannot converge during the first 10 epochs.

**Dataset:**    
Several experiments have been put in practice with various parameter tweaks.   
- The amount of data used for training:  
    We extract 300 games among all games in 2013 from the GoGoD and choose 40 steps randomly to generate training data in the beginning. Then we increase number of games used for training from 300 to 600, 1200, 2400 and 4200.
- Weights of history layer:  
    Originally, we used last 5 step’s position as history layer. We changed formula into exp(h*(-0.1)) where h is the number of turn since stone is put. This formula comes from Facebook’s paper and has two advantages:  
    + Recent moves weights more in the final move decision.   
    + Allows more history steps to be taken into consideration. 
- Layer marking for the rank of a player:  
    Two approaches to mark rank layers. One is to fill corresponding layer with 1, the other is to fill corresponding layer with -1 if player’s rank is less than 9 and only fill out 1 at the ‘9th’ layer if a player ranks 9d. This is because that 9d rank is professional for Go player and it worth larger weight.  The idea also come from Facebook’s paper.
- Add position mask using formula exp(-0.5*l) where l is the distance between stone’s position and center of board.  
- Multiply -1 for opponent’s layer to distinguish current player and its opponent. During the first few experiment, we generate both feature equally. Using layer 1 and layer 2 as example, these two layers contain information of all current player and opponent’s stone’s position, assuming that current player has stone on position [yx], we will then put an 1 on layer 1’s corresponding position. And we do the same for opponent’s stone.  After several experiments, we decide to use -1 rather than 1 to represents opponent’s position, which distinguish it from current player, the purpose for such change is to let model learn difference between current player and opponent.

### Excluding MCTS

One thing that needs to be pointed out is the neglection of MCTS in this project. We acknowledge that by all means MCTS; a powerful value and fast-policy network that helps to rollout the game all the way to the end to see who wins, will definitively improve the final result of our trained model. However, its field is not aligned with the Deep Learning subject.


###Conclusions

According to all experiments that have been illustrated with tables and graphs in section 2.2, we conclude several factors which could affect model’s performance.

- Number of the training data: the increase amount of training data improves model’s performance significantly.
- Way to mark rank layers. Separate normal player from professional player increase model’s performance.
- Position mask. Models using position mask feature have better performance than those without.
- Increasing conflict between current players and opponent. Change way to mark board information layer and history layer improve the performance. However. changing way to mark liberty layer will decrease performance.

Our result is not as good as Facebook’s Darkforest model. Although many factors may exist, one of the main reasons is the number of data used for training. Since our dataset is generated by our preprocessing code, each time we modify features, we need to regenerate our training dataset. Unfortunately, our code for preprocessing is not optimized enough and it takes around 1 hour to process 100 source files.

Our best training results is trained with a 7 convolutional layer model, using 4,200 games from GoGoD, for 24 hours while Facebook’s result has 144,748 games, trained with 12 convolutional layer model and takes 2 weeks to finish the training process with 50 epochs.  

###Further work:

- Resume a previously trained model by logging the model and last trained epoch number so as to have on-call inspection and save more time if continuous training may show some promising result.
- Try new feature planes. Prevalent patterns of Go Game have been broadly mastered and professional players seems very sensitive to these patterns and they would have counterplan for each pattern either.  Since our prediction process is pattern recognize process, using more pattern mask on board will help the outcome of a model have better performance.  
- The current program is limited with few corner cases. Special situations such as handicap is not implemented, yet it is logically easy to think of an approach such as initializing a new board with already assigned values for all 27 feature planes. We can certainly implement a parser or local ‘image pixel’ identifier specifically for some well-known strategies in each ranked game. 
- Of course, the other part of the very fundamental neural network as described in the original paper - the value network, which can help reduce the hundreds of possibility of moves down to a handful of more promising moves. While the policy network evaluate the breadth of the network, the value network can be devised as some representative depth level of the ‘possibility tree’. By leveraging MCTS; instead of brute-force, we can localize a specific depth of the game, then find the more-likely-to-win path and continue the training with our policy network. This will not only enable faster training but also the utter purpose of the Go Game - to win a game.


###Reference

- Training data set: GoGoD [URL: http://gogodonline.co.uk/]
- Yuandong Tian, Yan Zhu. Better Computer Go Player with Neural Network and Long-term Prediction. arXiv:1511.06410 [cs.LG] 2016.
- Christopher Clark, Amos Storkey. Teaching Deep Convolutional Neural Networks to Play Go. arXiv:1412.3409 [cs.AI] 2015.
- Move Evaluation in Go Using Deep Convolutional Neural Networks, Chris J Maddison University of Toronto cmaddis@cs.toronto.edu A. Huang, I. Sutskever, D. Silver.
- Rules of Go, Wikipedia [URL: https://en.wikipedia.org/wiki/Rules_of_go ]
- Facebook Research / Darkforest Go, Github [URL: https://github.com/facebookresearch/darkforestGo ]
