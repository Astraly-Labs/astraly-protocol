import pytest
import pytest_asyncio

from typing import Tuple
from signers import MockSigner
from utils import *
from starkware.starknet.services.api.contract_class import ContractClass

account_path = 'openzeppelin/account/presets/Account.cairo'
scorer_path = 'AstralyScore/Scorer/Scorer.cairo'

deployer = MockSigner(1234321)


@pytest.fixture(scope='module')
def contract_defs() -> Tuple[ContractClass, ...]:
    account_def = get_contract_def(account_path)
    scorer_def = get_contract_def(scorer_path)

    return account_def, scorer_def


@pytest_asyncio.fixture(scope='module')
async def contacts_init(contract_defs: Tuple[ContractClass, ...], get_starknet: Starknet) -> Tuple[StarknetContract, ...]:
    starknet = get_starknet
    account_def, scorer_def = contract_defs

    await starknet.declare(contract_class=account_def)
    deployer_account = await starknet.deploy(
        contract_class=account_def,
        constructor_calldata=[deployer.public_key]
    )

    await starknet.declare(contract_class=scorer_def)
    scorer_contract = await starknet.deploy(
        contract_class=scorer_def,
        constructor_calldata=[0, 0]
    )

    return deployer_account, scorer_contract


@pytest.fixture
def contracts_factory(contract_defs: Tuple[ContractClass, ...], contacts_init: Tuple[StarknetContract, ...], get_starknet: Starknet):
    account_def, scorer_def = contract_defs
    deployer_account, scorer_contract = contacts_init
    _state = get_starknet.state.copy()

    deployer_cached = cached_contract(
        _state, account_def, deployer_account)

    scorer_cached = cached_contract(
        _state, scorer_def, scorer_contract)

    return deployer_cached, scorer_cached, _state


@pytest.mark.asyncio
async def test_scorer(contracts_factory):
    deployer_account, scorer_contract, _ = contracts_factory

    t = 0
