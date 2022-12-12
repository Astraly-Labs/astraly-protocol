%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

//
// Storage Var
//
@storage_var
func l1_header_store_addr() -> (address: felt) {
}

//
// Constructor
//
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    l1_header_store_address: felt
) {
    l1_header_store_addr.write(l1_header_store_address);
    return ();
}

//
// View
//
@view
func get_L1_headers_store_addr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (address: felt) {
    let (address: felt) = l1_header_store_addr.read();
    return (address,);
}
