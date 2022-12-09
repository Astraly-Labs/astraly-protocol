%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check

from openzeppelin.utils.constants.library import IERC721_METADATA_ID
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.math import assert_le_felt
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.hash import hash2
from openzeppelin.access.ownable.library import Ownable

from immutablex.starknet.token.erc721.library import ERC721
from immutablex.starknet.token.erc721_token_metadata.library import ERC721_Token_Metadata

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC721.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC721.symbol();
    return (symbol,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC721.balance_of(owner);
    return (balance,);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    let (owner: felt) = ERC721.owner_of(tokenId);
    return (owner,);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (tokenURI_len: felt, tokenURI: felt*) {
    let (tokenURI_len, tokenURI) = ERC721_Token_Metadata.token_uri(token_id);
    return (tokenURI_len, tokenURI);
}

struct SSSBTData {
    token_id: Uint256,
    public_key: felt,
}

@storage_var
func data(sbt_id) -> (data: SSSBTData) {
}

@storage_var
func blacklisted(salt) -> (blacklisted: felt) {
}

@event
func sssbt_transfer(source: Uint256, target: Uint256, sbt) {
}

@view
func get_public_key{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(sbt_id) -> (
    public_key: felt
) {
    let (token_data) = data.read(sbt_id);
    return (public_key=token_data.public_key);
}

@view
func get_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(sbt_id) -> (
    token_id: Uint256
) {
    let (token_data) = data.read(sbt_id);
    return (token_id=token_data.token_id);
}

@external
func transfer{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}(sbt_id, token_id: Uint256, salt, signature: (felt, felt)) {
    let (token_data) = data.read(sbt_id);
    with_attr error_message("Blacklisted salt") {
        let (is_blacklisted) = blacklisted.read(salt);
        assert is_blacklisted = FALSE;
    }

    with_attr error_message("Invalid signature") {
        let (message_hash) = hash2{hash_ptr=pedersen_ptr}(sbt_id, token_id.low);
        let (message_hash) = hash2{hash_ptr=pedersen_ptr}(message_hash, token_id.high);
        let (message_hash) = hash2{hash_ptr=pedersen_ptr}(message_hash, salt);
        verify_ecdsa_signature(message_hash, token_data.public_key, signature[0], signature[1]);
    }

    blacklisted.write(salt, TRUE);
    sssbt_transfer.emit(token_data.token_id, token_id, sbt_id);
    data.write(sbt_id, SSSBTData(token_id, token_data.public_key));

    return ();
}
