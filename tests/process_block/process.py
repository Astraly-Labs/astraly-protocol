import asyncio

from web3 import Web3
from web3.types import BlockData
from util_types import Data, BlockHeaderIndexes

from block_header import BlockHeader, build_block_header
from helpers import Encoding

BLOCK_NUMBER = 7837994
PARRENT_HASH = "0x3f54c705dd673ab1415a42fa47a6b4f57ee77e96f6f507c560e67605addb414d"


def get_block(block_number: int) -> BlockData:
    alchemy_url = "https://eth-goerli.g.alchemy.com/v2/uXpxHR8fJBH3fjLJpulhY__jXbTGNjN7"

    w3 = Web3(Web3.HTTPProvider(alchemy_url))

    block = BlockData(w3.eth.get_block(block_number))
    return block


async def process_block():
    block: BlockData = get_block(BLOCK_NUMBER)
    block_header: BlockHeader = build_block_header(block)
    block_rlp = Data.from_bytes(block_header.raw_rlp()).to_ints()

    block_parent_hash = Data.from_hex(PARRENT_HASH)
    assert block_parent_hash.to_hex() == block_header.hash().hex()

    result = [[2**BlockHeaderIndexes.STATE_ROOT] + [block['number']] +
              [block_rlp.length] + [len(block_rlp.values)] + block_rlp.values]

    print(result)

asyncio.run(process_block())
