// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import "./interfaces/IVotingJCD.sol";
import "./interfaces/IGaugeFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/** @title Voter
    @notice veJCD holders will vote for gauge allocation to vault tokens.
 */

contract Registry is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    address public veToken; // the ve token that governs these contracts
    address public immutable jcd; // reward token
    address public immutable veJcdRewardPool;
    address public immutable gaugefactory;

    EnumerableSet.AddressSet private _vaults;
    mapping(address => address) public gauges; // vault => gauge
    mapping(address => address) public vaultForGauge; // gauge => vault
    mapping(address => bool) public isGauge;

    event VaultAdded(address indexed vault);
    event VaultRemoved(address indexed vault);
    event UpdatedVeToken(address indexed ve);

    constructor(
        address _ve,
        address _jcd,
        address _gaugefactory,
        address _veJcdRewardPool
    ) {
        require(_ve != address(0x0), "_ve 0x0 address");
        require(_jcd != address(0x0), "_jcd 0x0 address");
        require(_gaugefactory != address(0x0), "_gaugefactory 0x0 address");
        require(
            _veJcdRewardPool != address(0x0),
            "_veJcdRewardPool 0x0 address"
        );

        veToken = _ve;
        jcd = _jcd;
        gaugefactory = _gaugefactory;
        veJcdRewardPool = _veJcdRewardPool;
    }

    /**
    @notice Set the veJCD token address.
    @param _veToken the new address of the veJCD token
    */
    function setVe(address _veToken) external onlyOwner {
        veToken = _veToken;
        emit UpdatedVeToken(_veToken);
    }

    /** 
    @return address[] list of vaults with gauge that are possible to vote for.
    */
    function getVaults() external view returns (address[] memory) {
        return _vaults.values();
    }

    /** 
    @notice Add a vault to the list of vaults that receives rewards.
    @param _vault vault address
    @param _owner owner.
    */
    function addVaultToRewards(
        address _vault,
        address _owner
    ) external onlyOwner returns (address) {
        require(gauges[_vault] == address(0x0), "exist");

        address _gauge = IGaugeFactory(gaugefactory).createGauge(
            _vault,
            _owner
        );
        gauges[_vault] = _gauge;
        vaultForGauge[_gauge] = _vault;
        isGauge[_gauge] = true;
        _vaults.add(_vault);
        emit VaultAdded(_vault);
        return _gauge;
    }

    /** 
    @notice Remove a vault from the list of vaults receiving rewards.
    @param _vault vault address
    */
    function removeVaultFromRewards(address _vault) external onlyOwner {
        address gauge = gauges[_vault];
        require(gauge != address(0x0), "!exist");

        _vaults.remove(_vault);

        gauges[_vault] = address(0x0);
        vaultForGauge[gauge] = address(0x0);
        isGauge[gauge] = false;
        emit VaultRemoved(_vault);
    }
}
