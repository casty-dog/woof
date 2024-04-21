// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @dev The update of the allowlist is performed via the script (updateAllowlist).
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract AllowListable is Ownable {
  using MerkleProof for bytes32[];

  error AllowListableDisallowedAccount(address account);
  error AllowListableNotAllocated(address account, uint256 amount);

  event AllowListUpdated(address indexed sender, bytes32 merkleRoot);

  bytes32 internal _merkleRoot;

  function setAllowlist(bytes32 merkleRoot_) public onlyOwner {
    _merkleRoot = merkleRoot_;
    emit AllowListUpdated(msg.sender, merkleRoot_);
  }

  /*
   * @dev Restricted to only users registered in the allowlist. Amount will not be managed
   * @param account_ address to check
   * @param merkleRoot_ merkle tree root node
   * @param proof_ proof of allow list
   */
  modifier onlyInAllowList(
    address account_,
    bytes32 merkleRoot_,
    bytes32[] memory proof_
  ) {
    if (!_verifyAllowlist(account_, proof_)) {
      revert AllowListableDisallowedAccount(account_);
    }
    _;
  }

  /*
   * @dev NOTE: Only check merkle tree verification. NOT check allocated amount
   * @param account_ address to check
   * @param merkleRoot_ merkle tree root node
   * @param proof_ proof of allow list
   * @param allocated_ allocated amount in allowlist
   */
  modifier onlyAllowListAllocated(
    address account_,
    bytes32 merkleRoot_,
    bytes32[] memory proof_,
    uint256 allocated_
  ) {
    if (!_verifyAllowlistAllocated(account_, proof_, allocated_)) {
      revert AllowListableNotAllocated(account_, allocated_);
    }
    _;
  }

  function merkleRoot() public view returns (bytes32) {
    return _merkleRoot;
  }

  // TODO: consider visibility carefully here to prevent fraud
  function verifyAllowlist(bytes32[] memory proof_) public view returns (bool) {
    return _verifyAllowlist(msg.sender, proof_);
  }

  function _verifyAllowlist(
    address account_,
    bytes32[] memory proof_
  ) internal view returns (bool) {
    return proof_.verify(_merkleRoot, keccak256(abi.encodePacked(account_)));
  }

  function verifyAllowlistAllocated(
    bytes32[] memory proof_,
    uint256 allocated_
  ) public view returns (bool) {
    return _verifyAllowlistAllocated(msg.sender, proof_, allocated_);
  }

  // NOTE: This is intended solely for verifying the integrity of the Merkle tree.
  // -> The verification of the allocated amount is expected to be done by the caller.
  function _verifyAllowlistAllocated(
    address account_,
    bytes32[] memory proof_,
    uint256 allocated_
  ) internal view returns (bool) {
    /*
      isAllocated = allocated_ >= balanceOf(msg.sender) + quantity;
     */

    return proof_.verify(_merkleRoot, keccak256(abi.encodePacked(account_, allocated_)));
  }
}
