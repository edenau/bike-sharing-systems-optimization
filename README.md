# A Generic Model and a Distributed Algorithm for Optimization of Station Based Bike Sharing Systems
This repo is intended only for researchers that are working on the project. I might be a good researcher but I am no good programmer as my comments might be confusing and I am new to writing a ReadMe file. Do correct me if I got something wrong. I understand there are lots of codes and files but don't panic and do let me explain every file and what you probably want to do next.

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
* [OptimiseGreedyCandle.m](./OptimiseGreedyCandle.m) produces candle plots for greedy heuristic.
### Centralized Paradigm
* [OptimiseCentralised.m](./OptimiseCentralised.m) solves a standard two-dimensional constrained optimization problem.
* [OptimiseCentralisedwithDiffPS.m.m](./OptimiseCentralisedwithDiffPS.m) tries to solve problems with different problem size (PS). It tests station size 50, 100, 150, ..., 700 to be precise.
* [CompareComputation.m](./CompareComputation.m) compares computation time of centralized paradigm when PS changes. It is found that time required increases exponentially as PS increases. Information extracted from this procedure can be leveraged to generate a plot.

### Distributed Algorithm


## Other Functions
* [CapacityCount.m](./CapacityCount.m) checks if there is enough parking spaces in the whole system for all time. If not, optimization problem must be infeasible. It does not matter at all if you are sure that the system must have empty spaces somewhere.
* [HaversineDistance.m](./HaversineDistance.m) computes distance of two points on Earth. It is called somewhere in the flow.
* [IsWeekend.m](./IsWeekend.m) determines if a day is weekday/weekend in year *2017*. It is called somewhere in the flow.
