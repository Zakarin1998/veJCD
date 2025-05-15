## veJCD

veJCD is locking similar to the ve-style program of Curve and Yearn. 

### Max lock

JCD can be locked up to 4 years into veJCD, which is non-transferable. They are at least locked for a week.

### veJCD balance

The duration of the lock gives the amount of veJCD relative to the amount locked, locking for four years gives you a veJCD balance equal to the amount of JCD locked. Locking for 2 years gives you a veJCD balance of 50% of the JCD locked.
The balance decay overtime and can be pushed back to max value by increasing the lock back to the max lock duration.


### veJCD early exit
It’s possible to exit the lock early, in exchange for paying a penalty that gets distributed to the account that have veJCD locked. The penalty for exiting early is the following: 
```
    min(75%, lock_duration_left / 4 years * 100%)
```
So at most you are paying a 75% penalty that starts decreasing when your lock duration goes beyond 3 years.

## Gauges

Gauges allow vault depositors to stake their vault tokens and earn dJCD rewards according to the amount of dJCD to be distributed and their veJCD weight.

### Gauges boosting

Gauge rewards are boosted with a max boost of 10x. The max boost is a variable that can be adjusted by the team.

The boost mechanism will calculate your earning weight by taking the smaller amount of two values:
- The first value is the amount of liquidity you are providing. This amount is your maximum earning weight.
- The second value is 10% of first value + 90% the amount deposited in gauge multiplied by the ratio of your `veJCD Balance/veJCD Total Supply`.
```
min(AmountDeposited, (AmountDeposited /10) + (TotalDepositedInTheGauge * VeJCDBalance / VeJCDTotalSupply * 0.9))
```
When a user interacts with the gauge, the boosted amount is snapshotted until the next interaction.
The rewards that are not distributed because the balance isn't fully boosted are distributed back to veJCD holders.

### Gauge JCD distribution

Every two weeks veJCD holders can vote on dJCD distribution to gauges.

## veJCDRewardPool

Users who lock veJCD can claim JCD from the veJCD exited early and the non-distributed gauge rewards due to the lack of boost.
You will be able to start claiming from the veJCD reward pool two or three weeks from the Thursday after which you lock before you can claim.


## dJCDRewardPool

Users who lock veJCD can claim dJCD from the dJCD that aren't distributed due to the lack of boost.

## Redemption

Redemption is the contract used to redeem dJCD for JCD using ETH. JCD/ETH price is fetched from curve and chainlink oracles. JCD is sold at a discounted rate based on the ratio between the total JCD supply and the veJCD supply.

## Setup

Install ape framework. See [ape quickstart guide](https://docs.apeworx.io/ape/stable/userguides/quickstart.html)

Install dependencies
```bash
npm install
```

Install [Foundry](https://github.com/foundry-rs/foundry) for running tests
```bash
curl -L https://foundry.paradigm.xyz | bash
```

```bash
foundryup
```

## Compile

Install ape plugins
```bash
ape plugins install .
```

```bash
ape compile
```

## Test

```bash
ape test
```
