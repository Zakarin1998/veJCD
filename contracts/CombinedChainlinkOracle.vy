struct LatestRoundData:
    round_id: uint80
    answer: int256
    started: uint256
    updated: uint256
    answered_round: uint80

interface ChainlinkOracle:
    def latestRoundData() -> LatestRoundData: view
    def decimals() -> uint256: view

SCALE: constant(int256) = 10**18
JCD_ORACLE: constant(address) = missing # JCD/USD
ETH_ORACLE: constant(address) = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 # ETH/USD

decimals: public(constant(uint256)) = 18

@external
def __init__():
    assert ChainlinkOracle(JCD_ORACLE).decimals() == 8
    assert ChainlinkOracle(ETH_ORACLE).decimals() == 8

@external
@view
def latestRoundData() -> LatestRoundData:
    jcd: LatestRoundData = ChainlinkOracle(JCD_ORACLE).latestRoundData()
    eth: LatestRoundData = ChainlinkOracle(ETH_ORACLE).latestRoundData()
    if eth.updated < jcd.updated:
        jcd.updated = eth.updated
    jcd.answer = jcd.answer * SCALE / eth.answer
    return jcd
