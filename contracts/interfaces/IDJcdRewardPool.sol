// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IDJcdRewardPool {
    function burn(uint256 _amount) external returns (bool);
}
