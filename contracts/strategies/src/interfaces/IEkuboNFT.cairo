#[starknet::interface]
pub trait IEkuboNFT<TContractState> {
  fn get_next_token_id(ref self: TContractState) -> u64;
}