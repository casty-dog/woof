// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721A_SupplyLimitable is ERC721A, Ownable {
  event MaxSupplyChanged(address indexed sender, uint256 maxSupply);

  error MaxSupplyExceeded(address sender, uint256 amount, uint256 price);

  uint256 private _maxSupply;

  modifier onlyUnderMaxSupply(uint256 amount_) {
    if (totalSupply() + amount_ > _maxSupply) {
      revert MaxSupplyExceeded(msg.sender, amount_, _maxSupply);
    }
    _;
  }

  constructor(uint256 maxSupply_) {
    _maxSupply = maxSupply_;
  }

  function maxSupply() public view returns (uint256) {
    return _maxSupply;
  }

  function setMaxSupply(uint256 maxSupply_) public onlyOwner {
    _maxSupply = maxSupply_;
    emit MaxSupplyChanged(msg.sender, _maxSupply);
  }
}
