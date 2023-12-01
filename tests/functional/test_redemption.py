import ape
import pytest
from math import exp

SLIPPAGE_TOLERANCE = 3
SLIPPAGE_DENOMINATOR = 1000
AMOUNT = 10**18


def discount(s, x):
    return 1 / (1 + 10 * exp(4.7 * (s * x - 1)))


@pytest.mark.parametrize("percent_locked", [1, 5, 10, 40, 60])
@pytest.mark.parametrize("scaling_factor", [1, 2, 4, 8, 10])
def test_redeem(
    chain, d_yfi, yfi, ve_yfi, redemption, gov, panda, percent_locked, scaling_factor
):
    redemption.start_ramp(scaling_factor * AMOUNT, 0, sender=gov)
    # Lock tokens to reach the targeted percentage of locked tokens
    assert yfi.totalSupply() == 0
    total_to_mint = 10**22
    yfi.mint(gov, total_to_mint, sender=gov)
    to_lock = int(total_to_mint * percent_locked / 100)
    yfi.approve(ve_yfi, to_lock, sender=gov)
    ve_yfi.modify_lock(
        to_lock, chain.blocks.head.timestamp + 3600 * 24 * 2000, sender=gov
    )

    expected = discount(scaling_factor, percent_locked / 100)
    assert pytest.approx(expected) == redemption.discount() / AMOUNT

    yfi.transfer(redemption, AMOUNT, sender=gov)
    d_yfi.mint(panda, AMOUNT, sender=gov)
    expected = int(redemption.get_latest_price() * (1 - expected))
    assert pytest.approx(expected) == redemption.eth_required(AMOUNT)
    d_yfi.approve(redemption, AMOUNT, sender=panda)
    assert yfi.balanceOf(panda) == 0
    redemption.redeem(AMOUNT, sender=panda, value=expected)
    assert yfi.balanceOf(panda) == AMOUNT


def test_slippage_tollerance(d_yfi, yfi, redemption, gov, panda):
    yfi.mint(redemption, AMOUNT * 2, sender=gov)
    d_yfi.mint(panda, AMOUNT * 2, sender=gov)
    estimate = redemption.eth_required(AMOUNT)
    d_yfi.approve(redemption, AMOUNT * 2, sender=panda)
    assert yfi.balanceOf(panda) == 0
    with ape.reverts("price out of tolerance"):
        redemption.redeem(
            AMOUNT,
            sender=panda,
            value=estimate - estimate * SLIPPAGE_TOLERANCE // SLIPPAGE_DENOMINATOR - 1,
        )
    redemption.redeem(
        AMOUNT,
        sender=panda,
        value=estimate - estimate * SLIPPAGE_TOLERANCE // SLIPPAGE_DENOMINATOR,
    )
    assert yfi.balanceOf(panda) == AMOUNT
    with ape.reverts("price out of tolerance"):
        redemption.redeem(
            AMOUNT,
            sender=panda,
            value=estimate + estimate * SLIPPAGE_TOLERANCE // SLIPPAGE_DENOMINATOR + 1,
        )
    redemption.redeem(
        AMOUNT,
        sender=panda,
        value=estimate + estimate * SLIPPAGE_TOLERANCE // SLIPPAGE_DENOMINATOR,
    )
    assert yfi.balanceOf(panda) == 2 * AMOUNT


def test_ramp(chain, redemption, gov, panda):
    assert redemption.scaling_factor() == AMOUNT
    assert redemption.scaling_factor_ramp() == (0, 0, AMOUNT, AMOUNT)
    with ape.reverts():
        redemption.start_ramp(2 * AMOUNT, sender=panda)

    ts = chain.pending_timestamp + 10
    redemption.start_ramp(2 * AMOUNT, 1000, ts, sender=gov)
    assert redemption.scaling_factor_ramp() == (ts, ts + 1000, AMOUNT, 2 * AMOUNT)
    chain.pending_timestamp = ts + 200
    chain.mine()
    assert redemption.scaling_factor() == AMOUNT * 12 // 10

    with ape.reverts():
        redemption.start_ramp(3 * AMOUNT, sender=gov)

    with ape.reverts():
        redemption.stop_ramp(sender=panda)

    chain.pending_timestamp = ts + 500
    with chain.isolate():
        redemption.stop_ramp(sender=gov)
        assert redemption.scaling_factor() == AMOUNT * 15 // 10
        assert redemption.scaling_factor_ramp() == (
            0,
            0,
            AMOUNT * 15 // 10,
            AMOUNT * 15 // 10,
        )

    chain.mine()
    assert redemption.scaling_factor() == AMOUNT * 15 // 10
    chain.pending_timestamp = ts + 1000
    chain.mine()
    assert redemption.scaling_factor() == AMOUNT * 2
    chain.pending_timestamp = ts + 2000
    chain.mine()
    assert redemption.scaling_factor() == AMOUNT * 2


def test_kill(d_yfi, yfi, redemption, gov, panda):
    assert yfi.balanceOf(gov) == 0
    d_yfi.mint(panda, AMOUNT * 2, sender=gov)
    yfi.mint(redemption, AMOUNT, sender=gov)
    redemption.kill(sender=gov)
    assert yfi.balanceOf(gov) == AMOUNT
    estimate = redemption.eth_required(AMOUNT)
    d_yfi.approve(redemption, AMOUNT, sender=panda)
    with ape.reverts("killed"):
        redemption.redeem(AMOUNT, sender=panda, value=estimate)


def test_sweep(d_yfi, yfi, redemption, gov):
    d_yfi.mint(redemption, AMOUNT, sender=gov)
    yfi.mint(redemption, AMOUNT, sender=gov)
    redemption.sweep(d_yfi, sender=gov)
    assert d_yfi.balanceOf(gov) == AMOUNT
    with ape.reverts("protected token"):
        redemption.sweep(yfi, sender=gov)


def test_oracle(project, yfi, d_yfi, ve_yfi, gov):
    mock = project.MockOracle.deploy(sender=gov)
    redemption = project.Redemption.deploy(
        yfi, d_yfi, ve_yfi, gov, mock, 10 * AMOUNT, sender=gov
    )

    mock.set_price(2 * AMOUNT, AMOUNT, sender=gov)
    assert redemption.get_latest_price() == 2 * AMOUNT

    mock.set_price(3 * AMOUNT, 2 * AMOUNT, sender=gov)
    assert redemption.get_latest_price() == 3 * AMOUNT

    mock.set_updated(1, sender=gov)
    with ape.reverts():
        redemption.get_latest_price()


def test_chainlink_oracle(project, yfi, d_yfi, ve_yfi, gov):
    yfiusd = ape.project.AggregatorV3Interface.at(
        "0xA027702dbb89fbd58938e4324ac03B58d812b0E1"
    )
    ethusd = ape.project.AggregatorV3Interface.at(
        "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"
    )
    yfieth = ape.project.AggregatorV3Interface.at(
        "0x7c5d4F8345e66f68099581Db340cd65B078C41f4"
    )
    combined = project.CombinedChainlinkOracle.deploy(sender=gov)
    actual = combined.latestRoundData()[1]
    expected = yfiusd.latestRoundData()[1] * 10**18 // ethusd.latestRoundData()[1]
    assert actual == expected
    assert abs(yfieth.latestRoundData()[1] - actual) / actual <= 0.01

    redemption = project.Redemption.deploy(
        yfi, d_yfi, ve_yfi, gov, combined, 10 * AMOUNT, sender=gov
    )
    assert redemption.get_latest_price() == actual


def test_redeployment_oracle(chain, accounts, project, d_yfi, ve_yfi, gov):
    ychad = accounts["0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52"]
    pool = ape.Contract("0xC26b89A667578ec7b3f11b2F98d6Fd15C07C54ba")
    yfi = ape.Contract("0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e")
    yfi.approve(pool, 1000 * AMOUNT, sender=ychad)
    pool.exchange(1, 0, 100 * AMOUNT, 0, sender=ychad)
    chain.pending_timestamp += 60
    pool.exchange(1, 0, 100 * AMOUNT, 0, sender=ychad)
    chain.pending_timestamp += 60
    pool.exchange(1, 0, 100 * AMOUNT, 0, sender=ychad)

    old = ape.Contract("0x2fBa208E1B2106d40DaA472Cb7AE0c6C7EFc0224")
    new = project.Redemption.deploy(
        yfi,
        d_yfi,
        ve_yfi,
        gov,
        "0x3EbEACa272Ce4f60E800f6C5EE678f50D2882fd4",
        10 * AMOUNT,
        sender=gov,
    )
    assert old.get_latest_price() == new.get_latest_price()
