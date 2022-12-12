import pytest
import pytest_asyncio

from typing import Tuple
from utils import *
from generate_proof_balance import pack_intarray

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.state import StarknetState

from signers import MockSigner


account_path = 'openzeppelin/account/presets/Account.cairo'
sbt_contract_factory_path = 'AstralyBadge/AstralyBalanceSBTContractFactory.cairo'
balance_proof_badge_path = 'AstralyBadge/AstralyBalanceProofBadge.cairo'
mock_L1_headers_store_path = 'mocks/mock_L1_Headers_Store.cairo'
mock_L1_facts_registry_path = "mocks/mock_L1_Facts_Registry.cairo"
prover = MockSigner(1234321)


@pytest.fixture(scope='module')
def contract_defs():
    account_def = get_contract_def(account_path, True )
    sbt_contract_factory_def = get_contract_def(sbt_contract_factory_path, True)
    balance_proof_badge_def = get_contract_def(balance_proof_badge_path, True)
    mock_L1_headers_store_def = get_contract_def(mock_L1_headers_store_path, True)
    mock_L1_facts_registry_def = get_contract_def(mock_L1_facts_registry_path, True)
    return account_def, sbt_contract_factory_def, balance_proof_badge_def, mock_L1_facts_registry_def, mock_L1_headers_store_def


@pytest_asyncio.fixture(scope='module')
async def contacts_init(contract_defs, get_starknet: Starknet) -> Tuple[
        StarknetContract, StarknetContract, StarknetContract]:
    starknet = get_starknet
    account_def, sbt_contract_factory_def, balance_proof_badge_def, mock_L1_facts_registry_def, mock_L1_headers_store_def = contract_defs
    await starknet.declare(contract_class=account_def)
    prover_account = await starknet.deploy(
        contract_class=account_def,
        constructor_calldata=[prover.public_key],
        disable_hint_validation=True,
        contract_address_salt=prover.public_key
    )

    await starknet.declare(contract_class=sbt_contract_factory_def)
    sbt_contract_factory = await starknet.deploy(
        contract_class=sbt_contract_factory_def,
        constructor_calldata=[],
        disable_hint_validation=True
    )

    await starknet.declare(contract_class=mock_L1_headers_store_def)
    mock_L1_headers_store = await starknet.deploy(
        contract_class=mock_L1_headers_store_def,
        constructor_calldata=[],
        disable_hint_validation=True
    )
    await starknet.declare(contract_class=mock_L1_facts_registry_def)
    mock_L1_facts_registry = await starknet.deploy(
        contract_class=mock_L1_facts_registry_def,
        constructor_calldata=[mock_L1_headers_store.contract_address],
        disable_hint_validation=True
    )
    
    balance_proof_class_hash = await starknet.declare(contract_class=balance_proof_badge_def)

    await prover.send_transaction(prover_account, sbt_contract_factory.contract_address, "initializer",
                                  [balance_proof_class_hash.class_hash, prover_account.contract_address,
                                  mock_L1_facts_registry.contract_address])

    return prover_account, sbt_contract_factory, mock_L1_facts_registry, mock_L1_headers_store



@pytest.fixture
def contracts_factory(contract_defs, contacts_init, get_starknet: Starknet) -> Tuple[
        StarknetContract, StarknetContract, StarknetContract, StarknetState]:
    account_def, sbt_contract_factory_def, _, mock_L1_facts_registry_def, mock_L1_headers_store_def = contract_defs
    prover_account, sbt_contract_factory, mock_L1_facts_registry, mock_L1_headers_store = contacts_init
    _state = get_starknet.state.copy()

    prover_cached = cached_contract(
        _state, account_def, prover_account)
    sbt_contract_factory_cached = cached_contract(
        _state, sbt_contract_factory_def, sbt_contract_factory)
    mock_L1_headers_store_cached = cached_contract(
        _state, mock_L1_headers_store_def, mock_L1_headers_store)
    mock_L1_facts_registry_cached = cached_contract(
        _state, mock_L1_facts_registry_def, mock_L1_facts_registry)

    return prover_cached, sbt_contract_factory_cached, mock_L1_facts_registry_cached,mock_L1_headers_store_cached, _state


@pytest.mark.asyncio
async def test_create_SBT(contracts_factory, contract_defs):
    prover_account, sbt_contract_factory, mock_L1_facts_registry_cached,mock_L1_headers_store_cached, starknet_state = contracts_factory

    _, _, balance_proof_badge_def, _ , _= contract_defs

    LINK_token_address = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB"
    block_number = 1
    min_balance = 1
    token_uri = []
    token_uri.append(str_to_felt('ipfs://QmYcWYk4SV4kfo2j5UCXkd9L'))
    token_uri.append( str_to_felt("5iQurfvKtAWGRqoEtx9DRC"))
    state_root = pack_intarray(
        '0x1dc1f3f9a5764b362d5c5fe2568807d5ff74c832e3319d7410e3f2309b4c2f2b')
    await prover.send_transaction(prover_account, mock_L1_headers_store_cached.contract_address, "set_state_root",
                                  [len(state_root), *state_root, block_number])

    create_sbt_transaction_receipt = await prover.send_transaction(prover_account,
                                                                   sbt_contract_factory.contract_address,
                                                                   "createSBTContract",
                                                                   [block_number, min_balance, int(LINK_token_address, 16),len(token_uri),*token_uri])

    balance_proof_badge_contract = StarknetContract(starknet_state, balance_proof_badge_def.abi,
                                                    create_sbt_transaction_receipt.call_info.internal_calls[0].retdata[0], None)

    assert min_balance == (await balance_proof_badge_contract.minBalance().call()).result.min
    assert int(LINK_token_address, 16) == (await balance_proof_badge_contract.tokenAddress().call()).result.address

    assert_event_exist(create_sbt_transaction_receipt, "SBTContractCreated")
