%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

@storage_var
func l1_headers_store_addr() -> (address: felt) {
}


@view
func get_l1_headers_store_addr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (address : felt) {
    return l1_headers_store_addr.read();
}

@external
func set_l1_headers_store_addr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
   address : felt
) {
    return l1_headers_store_addr.write(address);
}
