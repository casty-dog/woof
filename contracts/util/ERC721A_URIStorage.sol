// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @dev using ERC721A and creating a custom solution since ERC721URIStorage is not available
 */

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

abstract contract ERC721A_URIStorage is ERC721A, Ownable {
  event BaseURIChanged(address indexed sender, string baseURI);

  string private _tokenBaseURI;

  function setBaseURI(string memory uri_) public onlyOwner {
    _tokenBaseURI = uri_;
    emit BaseURIChanged(msg.sender, _tokenBaseURI);
  }

  function baseURI() external view returns (string memory) {
    return _tokenBaseURI;
  }

  function tokenURI(uint tokenId_) public view virtual override returns (string memory) {
    return string(abi.encodePacked(ERC721A.tokenURI(tokenId_), ".json"));
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _tokenBaseURI;
  }
}
