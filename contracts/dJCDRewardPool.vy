# @version 0.3.7
"""
@title dJCD Reward Pool
@author Curve Finance, Yearn Finance
@license MIT
"""
from vyper.interfaces import ERC20

interface VotingJCD:
    def epoch(add: address) -> uint256: view
    def point_history(addr: address, loc: uint256) -> Point: view
    def checkpoint(): nonpayable
    def token() -> ERC20: view
    def balanceOf(addr: address, epoch: uint256) -> uint256: view
    def find_epoch_by_timestamp(user: address, ts: uint256) -> uint256: view 

event Initialized:
    vejcd: VotingJCD
    start_time: uint256

event CheckpointToken:
    time: uint256
    tokens: uint256

event Claimed:
    recipient: indexed(address)
    amount: uint256
    week_cursor: uint256
    max_epoch: uint256

event RewardReceived:
    sender: indexed(address)
    amount: uint256

struct Point:
    bias: int128
    slope: int128  # - dweight / dt
    ts: uint256
    blk: uint256  # block

struct LockedBalance:
    amount: uint256
    end: uint256


WEEK: constant(uint256) = 7 * 86400
TOKEN_CHECKPOINT_DEADLINE: constant(uint256) = 86400

DJCD: immutable(ERC20)
VEJCD: immutable(VotingJCD)

start_time: public(uint256)
time_cursor: public(uint256)
time_cursor_of: public(HashMap[address, uint256])

last_token_time: public(uint256)
tokens_per_week: public(HashMap[uint256, uint256])

token_last_balance: public(uint256)
ve_supply: public(HashMap[uint256, uint256])


@external
def __init__(vejcd: VotingJCD, djcd: address, start_time: uint256):
    """
    @notice Contract constructor
    @param vejcd VotingJCD contract address
    @param start_time Epoch time for fee distribution to start
    """
    t: uint256 = start_time / WEEK * WEEK
    self.start_time = t
    self.last_token_time = t
    self.time_cursor = t
    VEJCD = vejcd
    DJCD = ERC20(djcd)

    log Initialized(vejcd, start_time)


@internal
def _checkpoint_token():
    token_balance: uint256 = DJCD.balanceOf(self)
    to_distribute: uint256 = token_balance - self.token_last_balance
    # @dev gas optimization
    if to_distribute == 0:
        self.last_token_time = block.timestamp
        log CheckpointToken(block.timestamp, 0)
        return
    
    self.token_last_balance = token_balance
    t: uint256 = self.last_token_time
    since_last: uint256 = block.timestamp - t
    self.last_token_time = block.timestamp
    this_week: uint256 = t / WEEK * WEEK
    next_week: uint256 = 0

    for i in range(40):
        next_week = this_week + WEEK
        if block.timestamp < next_week:
            if since_last == 0 and block.timestamp == t:
                self.tokens_per_week[this_week] += to_distribute
            else:
                self.tokens_per_week[this_week] += to_distribute * (block.timestamp - t) / since_last
            break
        else:
            if since_last == 0 and next_week == t:
                self.tokens_per_week[this_week] += to_distribute
            else:
                self.tokens_per_week[this_week] += to_distribute * (next_week - t) / since_last
        t = next_week
        this_week = next_week

    log CheckpointToken(block.timestamp, to_distribute)


@external
def checkpoint_token():
    """
    @notice Update the token checkpoint
    @dev Calculates the total number of tokens to be distributed in a given week.
    """
    assert block.timestamp > self.last_token_time + TOKEN_CHECKPOINT_DEADLINE
    self._checkpoint_token()


@internal
def _checkpoint_total_supply():
    t: uint256 = self.time_cursor
    rounded_timestamp: uint256 = block.timestamp / WEEK * WEEK
    VEJCD.checkpoint()

    for i in range(40):
        if t > rounded_timestamp:
            break
        else:
            epoch: uint256 = VEJCD.find_epoch_by_timestamp(VEJCD.address, t)
            pt: Point = VEJCD.point_history(VEJCD.address, epoch)
            dt: int128 = 0
            if t > pt.ts:
                # If the point is at 0 epoch, it can actually be earlier than the first deposit
                # Then make dt 0
                dt = convert(t - pt.ts, int128)
            self.ve_supply[t] = convert(max(pt.bias - pt.slope * dt, 0), uint256)
        t += WEEK

    self.time_cursor = t


@external
def checkpoint_total_supply():
    """
    @notice Update the veJCD total supply checkpoint
    @dev The checkpoint is also updated by the first claimant each
         new epoch week. This function may be called independently
         of a claim, to reduce claiming gas costs.
    """
    self._checkpoint_total_supply()


@internal
def _claim(addr: address, last_token_time: uint256) -> uint256:
    to_distribute: uint256 = 0

    max_user_epoch: uint256 = VEJCD.epoch(addr)
    _start_time: uint256 = self.start_time

    if max_user_epoch == 0:
        # No lock = no fees
        return 0

    week_cursor: uint256 = self.time_cursor_of[addr]

    if week_cursor == 0:
        user_point: Point = VEJCD.point_history(addr, 1)
        week_cursor = (user_point.ts + WEEK - 1) / WEEK * WEEK

    if week_cursor >= last_token_time:
        return 0

    if week_cursor < _start_time:
        week_cursor = _start_time

    # Iterate over weeks
    for i in range(50):
        if week_cursor >= last_token_time:
            break
        balance_of: uint256 = VEJCD.balanceOf(addr, week_cursor)
        if balance_of == 0:
            break
        to_distribute += balance_of * self.tokens_per_week[week_cursor] / self.ve_supply[week_cursor]
        week_cursor += WEEK

    self.time_cursor_of[addr] = week_cursor

    log Claimed(addr, to_distribute, week_cursor, max_user_epoch)

    return to_distribute


@external
@nonreentrant('lock')
def claim(user: address = msg.sender) -> uint256:
    """
    @notice Claim fees for a user
    @dev 
        Each call to claim looks at a maximum of 50 user veJCD points.
        For accounts with many veJCD related actions, this function
        may need to be called more than once to claim all available
        fees. In the `Claimed` event that fires, if `claim_epoch` is
        less than `max_epoch`, the account may claim again.
    @param user account to claim the fees for
    @return uint256 amount of the claimed fees
    """
    if block.timestamp >= self.time_cursor:
        self._checkpoint_total_supply()

    last_token_time: uint256 = self.last_token_time

    if block.timestamp > last_token_time + TOKEN_CHECKPOINT_DEADLINE:
        self._checkpoint_token()
        last_token_time = block.timestamp

    last_token_time = last_token_time / WEEK * WEEK

    amount: uint256 = self._claim(user, last_token_time)
    if amount != 0:
        assert DJCD.transfer(user, amount)
        self.token_last_balance -= amount

    return amount


@external
def burn(amount: uint256 = max_value(uint256)) -> bool:
    """
    @notice Receive dJCD into the contract and trigger a token checkpoint
    @param amount Amount of tokens to pull [default: allowance]
    @return bool success
    """
    _amount: uint256 = amount
    if _amount == max_value(uint256):
        _amount = DJCD.allowance(msg.sender, self)
    if _amount > 0:
        DJCD.transferFrom(msg.sender, self, _amount)
        log RewardReceived(msg.sender, _amount)
        if block.timestamp > self.last_token_time + TOKEN_CHECKPOINT_DEADLINE:
            self._checkpoint_token()

    return True


@view
@external
def token() -> ERC20:
    return DJCD


@view
@external
def vejcd() -> VotingJCD:
    return VEJCD
