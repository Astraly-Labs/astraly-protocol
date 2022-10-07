%lang starknet

from contracts.lib.general_address import Address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from openzeppelin.access.accesscontrol.library import AccessControl
from starkware.cairo.common.math import assert_not_zero

//
// Enums
//
struct Role {
    // Keep ADMIN role first of this list as 0 is the default admin value to manage roles in AccessControl library
    ADMIN: felt,  // ADMIN role, can assign/revoke roles
}

//
// Structs
//

struct Badge {
    address: Address,
    weight: felt,
}

struct StorageProof {
    starknet_account: felt,
    token_balance: felt,
    token_contract_nonce: felt,
    account_proof_len: felt,
    storage_proof_len: felt,
    code_hash__len: felt,
    code_hash_: felt*,
    storage_slot__len: felt,
    storage_slot_: felt*,
    storage_hash__len: felt,
    storage_hash_: felt*,
    message__len: felt,
    message_: felt*,
    message_byte_len: felt,
    R_x__len: felt,
    R_x_: felt*,
    R_y__len: felt,
    R_y_: felt*,
    s__len: felt,
    s_: felt*,
    v: felt,
    storage_key__len: felt,
    storage_key_: felt*,
    storage_value__len: felt,
    storage_value_: felt*,
    account_proofs_concat_len: felt,
    account_proofs_concat: felt*,
    account_proof_sizes_words_len: felt,
    account_proof_sizes_words: felt*,
    account_proof_sizes_bytes_len: felt,
    account_proof_sizes_bytes: felt*,
    storage_proofs_concat_len: felt,
    storage_proofs_concat: felt*,
    storage_proof_sizes_words_len: felt,
    storage_proof_sizes_words: felt*,
    storage_proof_sizes_bytes_len: felt,
    storage_proof_sizes_bytes: felt*,
}

//
// Storage
//

// cache users' scores on update
@storage_var
func user_score_(user: felt) -> (res: felt) {
}

// badge address -> badge weight
@storage_var
func badges_(address: Address) -> (res: felt) {
}

// handler contract address
@storage_var
func handler_() -> (res: felt) {
}

namespace scorer {
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        badges_len: felt, badges: Badge*, handler: felt
    ) {
        handler_.write(handler);
        internal.write_rec(badges_len, badges);
        return ();
    }

    func get_score{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt, proofs_len: felt, proofs: felt*
    ) -> (score: felt) {
        let (_score) = user_score_.read(account);

        if (_score == 0) {
            return internal.get_score(proofs_len, proofs);
        } else {
            return (score=_score);
        }
    }

    func update_score{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt, proofs_len: felt, proofs: felt*
    ) {
        return ();
    }

    // Grant the ADMIN role to a given address
    func grant_admin_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        AccessControl.grant_role(Role.ADMIN, address);
        return ();
    }

    // Revoke the ADMIN role from a given address
    func revoke_admin_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        with_attr error_message("scorer: Cannot self renounce to ADMIN role") {
            internal.assert_not_caller(address);
        }
        AccessControl.revoke_role(Role.ADMIN, address);
        return ();
    }

    func update_handler{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        handler: felt
    ) {
        internal.assert_only_admin();
        handler_.write(handler);
        return ();
    }
}

namespace internal {
    func write_rec{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt, array: Badge*
    ) {
        badges_.write(array[index].address, array[index].weight);
        if (index == 0) {
            return ();
        }

        return write_rec(index - 1, array);
    }

    func get_score{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        proofs_len: felt, proofs: felt*
    ) -> (score: felt) {
        let score = 0;
        return (score,);
    }

    func assert_not_caller{syscall_ptr: felt*}(address: felt) {
        let (caller_address) = get_caller_address();
        assert_not_zero(caller_address - address);
        return ();
    }

    func assert_only_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        with_attr error_message("scorer: ADMIN role required") {
            AccessControl.assert_only_role(Role.ADMIN);
        }

        return ();
    }
}
