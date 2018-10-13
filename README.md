# A Generic Model and a Distributed Algorithm for Optimization of Station Based Bike Sharing Systems
This repo is intended only for researchers that are working on the project. I am sorry that some are in British English but some in American English.
I might be a good researcher but I am no good programmer as my comments might be confusing and I am new to writing a ReadMe file. Do correct me if I got something wrong. I understand there are lots of codes and files but don't panic and do let me explain every file and what you probably want to do next. Do take my codes and comments with a grain of salt as I was in a hurry and some comments were added months after.

## Flow before Optimization
This is the flow of procedures before doing any optimization. Too lazy to draw a fancy one.
```bash
.
├── ValidateSystemModel.m
├── InitialiseModel.m
│   ├── GenerateJourneys.m
│   │   ├── DefineNeighbourhood.m
│   │   ├── SimulateStations.m
│   │   │   ├── DeleteDistantStations.m  
│   │   │   │   ├── Optimise?.m
```
* [ValidateSystemModel.m](./ValidateSystemModel.m) constructs and validates a model from historical data. It also generates some fancy graphs. *This procedure does not need to be executed for optimization algorithms.*
* [InitialiseModel.m](./InitialiseModel.m) constructs a model with historical data.
* [GenerateJourneys.m](./GenerateJourneys.m) generates sampled journeys *after InitialiseModel.m*.
* [DefineNeighbourhood.m](./DefineNeighbourhood.m) defines the concept of neighbourhood *after GenerateJourneys.m*. After getting a concept of how sparse/dence the system is, we use this info and calibrate SimulateStations.m, and thus *this procedure does not need to be executed for optimization algorithms.*
* [SimulateStations.m](./SimulateStations.m) simulates stations with their fill levels *after GenerateJourneys.m*.
* [DeleteDistantStations.m](./DeleteDistantStations.m) deletes distant stations *after SimulateStations.m*. Make sure this procedure runs *once* only.

We will then be ready to execute *Optimise?.m* procedures.

## Optimization Algorithm
### Greedy Heuristic
* [OptimiseGreedy.m](./OptimiseGreedy.m) is pretty self-ish explanatary.
* [OptimiseGreedyCandle.m](./OptimiseGreedyCandle.m) produces candle plots for greedy heuristic. Greedy heuristic generates different solutions when the station sequence changes. The plots can see how solutions vary.

### Centralized Paradigm
* [OptimiseCentralised.m](./OptimiseCentralised.m) solves a standard two-dimensional constrained optimization problem.
* [OptimiseCentralisedwithDiffPS.m.m](./OptimiseCentralisedwithDiffPS.m) tries to solve problems with different problem size (PS). It tests station size 50, 100, 150, ..., 700 to be precise.
* [CompareComputation.m](./CompareComputation.m) compares computation time of centralized paradigm when PS changes. It is found that time required increases exponentially as PS increases. Information extracted from this procedure can be leveraged to generate a plot.

### Distributed Algorithm
* [OptimiseDistributed2.m](./OptimiseDistributed2.m) is the standard distributed algorithm I developed. I used β=10.
* [CompareBeta.m](./CompareBeta.m) calls [OptimiseDistributed2Beta.m](./OptimiseDistributed2Beta.m) and tweaks the only parameter β in the distributed algorithm. It does not make a huge difference in our case.
* [OptimiseDistributed2CheckMiddle.m](./OptimiseDistributed2CheckMiddle.m) allows us to do optimization NOT starting at time 1. For instance, we already have solutions for time 1 to 27, the optimization solver can proceed at time 28. Simply change the parameter TPOINT for starting at different time slices.
* [OptimiseDistributed2withDiffPS.m](./OptimiseDistributed2withDiffPS.m) tries to solve problems with different problem size (PS). It tests station size 50, 100, 150, ..., 700 to be precise.

### Novel TDG Algorithm
TDG consists of a truncated distributed algorithm (when to interupt is a design choice), followed by a double-greedy approach.
* [OptimiseTDG.m](./OptimiseTDG.m) is the implementation of the TDG algorithm.
* [OptimiseTDGSimplerG.m](./OptimiseTDGSimplerG.m) tries to implement a simpler greedy component in TDG.
* [OptimiseTDGTightening.m](./OptimiseTDGTightening.m) tries to do temporary proportional (station fill level) tightening to see if there would be any improvement in performance. Did not seem to be the case.

### Obsolete Ones
These algorithms are no longer used. They are put in folder [obsolete](./obsolete/) to avoid confusion.
* [OptimiseDistributed3.m](./obsolete/OptimiseDistributed3.m) tried to decouple the two-dimensional setting in another dimension (direction). It should work but for some reasons I did not go for this. Probably because it made less sense in this particular BSS optimization setting.
* [OptimiseDistributed2ManualRoundoff.m](./obsolete/OptimiseDistributed2ManualRoundoff.m) tried to solve the roundoff problem faced in distributed algorithm. For instance, when the algorithm tried to relocate 0.33, 0.33, and 0.33 users to station A, B, and C respectively, if we round off all of these numbers naïvely, the total number of users does not conserve. Not sure why I did not use this code anymore, it probably did not work well.

## Other Functions
* [CapacityCount.m](./CapacityCount.m) checks if there is enough parking spaces in the whole system for all time. If not, optimization problem must be infeasible. It does not matter at all if you are sure that the system must have empty spaces somewhere.
* [HaversineDistance.m](./HaversineDistance.m) computes distance of two latitude-longitude points on Earth. It is called somewhere in the flow.
* [IsWeekend.m](./IsWeekend.m) determines if a day is weekday/weekend in year *2017*. It is called somewhere in the flow.
