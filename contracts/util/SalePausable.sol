// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

abstract contract SalePausable {
  event PreSalePaused(address account);
  event PreSaleUnpaused(address account);
  event PublicSalePaused(address account);
  event PublicSaleUnpaused(address account);

  bool private _preSalePaused;
  bool private _publicSalePaused;

  constructor(bool preSalePaused_, bool publicSalePaused_) {
    _preSalePaused = preSalePaused_;
    _publicSalePaused = publicSalePaused_;
  }

  modifier whenNotPreSalePaused() {
    _requireNotPreSalePaused();
    _;
  }

  modifier whenPreSalePaused() {
    _requirePreSalePaused();
    _;
  }

  modifier whenNotPublicSalePaused() {
    _requireNotPublicSalePaused();
    _;
  }

  modifier whenPublicSalePaused() {
    _requirePublicSalePaused();
    _;
  }

  function preSalePaused() public view virtual returns (bool) {
    return _preSalePaused;
  }

  function publicSalePaused() public view virtual returns (bool) {
    return _publicSalePaused;
  }

  function _requireNotPreSalePaused() internal view virtual {
    require(!preSalePaused(), "Error: pre sale is paused");
  }

  function _requirePreSalePaused() internal view virtual {
    require(preSalePaused(), "Error: pre sale is not paused");
  }

  function _requireNotPublicSalePaused() internal view virtual {
    require(!publicSalePaused(), "Error: public sale is paused");
  }

  function _requirePublicSalePaused() internal view virtual {
    require(publicSalePaused(), "Error: public sale is not paused");
  }

  function _preSalePause() internal virtual whenNotPreSalePaused {
    _preSalePaused = true;
    emit PreSalePaused(msg.sender);
  }

  function _preSaleUnpause() internal virtual whenPreSalePaused {
    _preSalePaused = false;
    emit PreSalePaused(msg.sender);
  }

  function _publicSalePause() internal virtual whenNotPublicSalePaused {
    _publicSalePaused = true;
    emit PublicSalePaused(msg.sender);
  }

  function _publicSaleUnpause() internal virtual whenPublicSalePaused {
    _publicSalePaused = false;
    emit PublicSaleUnpaused(msg.sender);
  }
}
