%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from contracts.AstralyScore.Scorer.library import scorer, Badge, StorageProof

//
// Constructor
//
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    badges_len: felt, badges: Badge*, handler: felt
) {
    scorer.initialize(badges_len, badges, handler);
    return ();
}

//
// Views
//
@view
func get_score{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, proofs_len: felt, proofs: felt*
) -> (score: felt) {
    let (score) = scorer.get_score(account, proofs_len, proofs);
    return (score=score);
}

//
// Externals
//
@external
func update_score{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proofs_len: felt, proofs: felt*
) {
    let (caller) = get_caller_address();
    scorer.update_score(caller, proofs_len, proofs);
    return ();
}
