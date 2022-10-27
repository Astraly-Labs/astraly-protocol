import asyncio

from web3 import Web3
from web3.types import HexBytes, BlockData
from util_types import Data, BlockHeaderIndexes

from block_header import BlockHeader, build_block_header
from helpers import Encoding

BLOCK_NUMBER = 7837994


def get_block(block_number: int) -> BlockData:
    alchemy_url = "https://eth-goerli.g.alchemy.com/v2/uXpxHR8fJBH3fjLJpulhY__jXbTGNjN7"

    w3 = Web3(Web3.HTTPProvider(alchemy_url))

    block = BlockData(w3.eth.get_block(block_number))
    return block


async def process_block():
    block: BlockData = get_block(BLOCK_NUMBER)
    block_header: BlockHeader = build_block_header(block)
    block_rlp = Data.from_bytes(block_header.raw_rlp()).to_ints()

    print("option_set: ", 2**BlockHeaderIndexes.STATE_ROOT)
    print("block_number: ", block['number'])
    print("block_header_rlp_bytes_len: ", block_rlp.length)
    print("block_header_rlp_len: ", len(block_rlp.values))
    print("block_header_rlp: ", block_rlp.values)

asyncio.run(process_block())
