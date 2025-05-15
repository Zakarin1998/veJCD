from pathlib import Path
from readline import append_history_file

import click
from ape import accounts, project, chain
from ape.cli import NetworkBoundCommand, network_option, account_option
from eth._utils.address import generate_contract_address
from eth_utils import to_checksum_address, to_canonical_address
from datetime import datetime


@click.group(short_help="Deploy the project")
def cli():
    pass


@cli.command(cls=NetworkBoundCommand)
@network_option()
@account_option()
def deploy_ve_jcd(network, account):
    now = datetime.now()
    jcd = "0x0Ed024d39d55e486573EE32e583bC37Eb5A6271f"  # Mainnet
    # deploy veJCD
    reward_pool_address = to_checksum_address(
        generate_contract_address(to_canonical_address(str(account)), account.nonce + 1)
    )
    ve_jcd = account.deploy(
        project.VotingJCD, jcd, reward_pool_address, required_confirmations=0
    )
    start_time = (
        int(datetime.timestamp(now)) + 7 * 3600 * 24
    )  # MUST offset by a week otherwise token distributed are lost since no lock has been made yet.
    reward_pool = account.deploy(
        project.RewardPool, ve_jcd, start_time, required_confirmations=0
    )
    print(reward_pool)
    print(reward_pool_address)
    assert str(reward_pool) == reward_pool_address, "broken setup"
