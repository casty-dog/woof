// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./util/ERC721A_URIStorage.sol";
import "./util/ERC721A_SupplyLimitable.sol";
import "./util/AllowListable.sol";
import "./util/SalePausable.sol";

interface IWoofNFT {
  function preMint(uint256 amount_, bytes32[] memory proof_, uint256 allocated_) external payable;

  function mint(uint256 amount_) external payable;

  function preSalePurchase(
    address to_,
    uint256 amount_,
    bytes32[] memory proof_,
    uint256 allocated_
  ) external payable;

  function purchase(address to_, uint256 amount_) external payable;

  function preSalePrice() external view returns (uint256);

  function publicSalePrice() external view returns (uint256);

  function currentPrice() external view returns (uint256);

  function calculateCost(uint256 amount_) external view returns (uint256);

  function preSaleMintLimit() external view returns (uint256);

  function maxMintablePerAddress() external view returns (uint256);

  function preSaleMintedAmount() external view returns (uint256);

  function mintedAmount(address account_) external view returns (uint256);

  // functions for owner
  function setPreSaleMintLimit(uint256 preSaleMax_) external;

  function setMaxMintablePerAddress(uint256 max_) external;

  function setPreSalePrice(uint256 price_) external;

  function setPublicSalePrice(uint256 price_) external;

  function setPreSalePaused(bool paused_) external;

  function setPublicSalePaused(bool paused_) external;

  function mintForGiveaway(address to_, uint256 amount_) external;

  function withdrawValue() external;
}

contract WoofNFT is
  IWoofNFT,
  ERC721A_URIStorage,
  ERC721A_SupplyLimitable,
  AllowListable,
  ReentrancyGuard,
  SalePausable
{
  event PriceChanged(address indexed sender, uint256 price, bool publicSale);
  event MaxMintablePerAddressChanged(address indexed sender, uint256 maxMintablePerAddress);
  event PreSaleMintLimitChanged(address indexed sender, uint256 preSaleMintLimit);
  event Minted(address indexed sender, uint256 value, uint256 amount, bool publicSale);
  event Purchased(address indexed sender, uint256 value, uint256 amount, bool publicSale);
  event WithdrawnETH(address indexed recipient, uint256 amount);

  error NotEnoughEtherSent(address sender, uint256 value, uint256 amount, uint256 price);
  error PreSaleMintLimitExceeded(address sender, uint256 demand, uint256 preSaleMintLimit);
  error MaxMintableAmountExceeded(address sender, uint256 demand);

  modifier onlyUnderPreSaleMintLimit(uint256 demand_) {
    if (demand_ + _preSaleMintedAmount > _preSaleMintLimit) {
      revert PreSaleMintLimitExceeded(msg.sender, demand_, _preSaleMintLimit);
    }
    _;
  }

  modifier onlyUnderMintableAmount(address to_, uint256 demand_) {
    if (_maxMintablePerAddress < mintedAmount(to_) + demand_) {
      revert MaxMintableAmountExceeded(to_, demand_);
    }
    _;
  }

  modifier enoughValueForMint(uint256 demand_, address payer_) {
    uint256 cost = calculateCost(demand_);
    if (msg.value < cost) {
      revert NotEnoughEtherSent(payer_, msg.value, demand_, cost);
    }
    _;
  }

  // public constants
  string public constant NAME = "Casty Woof NFT is a collection of OG NFT";
  string public constant SYMBOL = "CastyWoof";
  uint256 public constant MAX_SUPPLY = 1000;

  // private members
  uint256 private _preSalePrice = 500 ether;
  uint256 private _publicSalePrice = 1000 ether;
  uint256 private _preSaleMintLimit = 200;
  uint256 private _maxMintablePerAddress = 1;
  uint256 private _preSaleMintedAmount;
  mapping(address => uint256) private _mintedQuantityPerAccount;

  constructor(
    string memory tokenBaseURI_
  ) ERC721A(NAME, SYMBOL) ERC721A_SupplyLimitable(MAX_SUPPLY) SalePausable(false, true) {
    setBaseURI(tokenBaseURI_);
  }

  function preMint(
    uint256 amount_,
    bytes32[] memory proof_,
    uint256 allocated_
  )
    external
    payable
    onlyAllowListAllocated(msg.sender, _merkleRoot, proof_, allocated_)
    whenNotPreSalePaused
    enoughValueForMint(amount_, msg.sender)
    onlyUnderMaxSupply(amount_)
    onlyUnderPreSaleMintLimit(amount_)
    onlyUnderMintableAmount(msg.sender, amount_)
  {
    // zero address check
    require(msg.sender != address(0), "Error: Zero address");
    // quantity check
    require(amount_ > 0, "Error: Amount must be greater than 0");
    // batch preMint limit check
    require(
      amount_ <= 1,
      "Error: The maximum limit that can be obtained in a batch preMint has been reached"
    );
    // allowlist allocated quantity check
    require(
      allocated_ >= balanceOf(msg.sender) + amount_,
      "Error: The maximum limit that can be allocated allowlist has been reached"
    );

    _preMint(msg.sender, amount_);
    emit Minted(msg.sender, msg.value, amount_, false);
  }

  function mint(
    uint256 amount_
  )
    external
    payable
    whenNotPublicSalePaused
    enoughValueForMint(amount_, msg.sender)
    onlyUnderMaxSupply(amount_)
    onlyUnderMintableAmount(msg.sender, amount_)
  {
    // zero address check
    require(msg.sender != address(0), "Error: Zero address");
    // quantity check
    require(amount_ > 0, "Error: Amount must be greater than 0");
    // batch preMint limit check
    require(
      amount_ <= 1,
      "Error: The maximum limit that can be obtained in a batch mint has been reached"
    );

    _mint(msg.sender, amount_);
    emit Minted(msg.sender, msg.value, amount_, true);
  }

  function preSalePurchase(
    address to_,
    uint256 amount_,
    bytes32[] memory proof_,
    uint256 allocated_
  )
    external
    payable
    onlyAllowListAllocated(to_, _merkleRoot, proof_, allocated_)
    whenNotPreSalePaused
    enoughValueForMint(amount_, to_)
    onlyUnderMaxSupply(amount_)
    onlyUnderPreSaleMintLimit(amount_)
    onlyUnderMintableAmount(to_, amount_)
  {
    // zero address check
    require(to_ != address(0), "Error: Zero address");
    // quantity check
    require(amount_ > 0, "Error: Amount must be greater than 0");
    // batch preMint limit check
    require(
      amount_ <= 1,
      "Error: The maximum limit that can be obtained in a batch mint has been reached"
    );
    // allowlist allocated quantity check
    require(
      allocated_ >= balanceOf(to_) + amount_,
      "Error: The maximum limit that can be allocated allowlist has been reached"
    );

    _preMint(to_, amount_);
    emit Purchased(to_, msg.value, amount_, false);
  }

  function purchase(
    address to_,
    uint256 amount_
  )
    external
    payable
    whenNotPublicSalePaused
    enoughValueForMint(amount_, to_)
    onlyUnderMaxSupply(amount_)
    onlyUnderMintableAmount(to_, amount_)
  {
    // zero address check
    require(to_ != address(0), "Error: Zero address");
    // quantity check
    require(amount_ > 0, "Error: Amount must be greater than 0");
    // batch preMint limit check
    require(
      amount_ <= 1,
      "Error: The maximum limit that can be obtained in a batch mint has been reached"
    );

    _mint(to_, amount_);
    emit Purchased(to_, msg.value, amount_, true);
  }

  function preSalePrice() public view returns (uint256) {
    return _preSalePrice;
  }

  function publicSalePrice() public view returns (uint256) {
    return _publicSalePrice;
  }

  function currentPrice() public view returns (uint256) {
    // NOTE: If both public sale and pre-sale are open, prioritize the price of the pre-sale.
    return preSalePaused() ? _publicSalePrice : _preSalePrice;
  }

  function calculateCost(uint256 amount_) public view returns (uint256) {
    return amount_ * currentPrice();
  }

  function preSaleMintLimit() public view returns (uint256) {
    return _preSaleMintLimit;
  }

  function maxMintablePerAddress() public view returns (uint256) {
    return _maxMintablePerAddress;
  }

  // Total number minted from each wallet in the pre-sale.
  function preSaleMintedAmount() public view returns (uint256) {
    return _preSaleMintedAmount;
  }

  function mintedAmount(address account_) public view returns (uint256) {
    return _mintedQuantityPerAccount[account_];
  }

  function _preMint(address to_, uint256 amount_) internal {
    _mint(to_, amount_);
    _preSaleMintedAmount += amount_;
  }

  function _mint(address to_, uint256 amount_) internal override(ERC721A) {
    super._mint(to_, amount_);
    _mintedQuantityPerAccount[to_] += amount_;
  }

  function _baseURI()
    internal
    view
    virtual
    override(ERC721A_URIStorage, ERC721A)
    returns (string memory)
  {
    return super._baseURI();
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function tokenURI(
    uint256 _tokenId
  ) public view virtual override(ERC721A_URIStorage, ERC721A) returns (string memory) {
    return super.tokenURI(_tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId_
  ) public view virtual override(ERC721A) returns (bool) {
    return super.supportsInterface(interfaceId_);
  }

  function setPreSaleMintLimit(uint256 preSaleMax_) public onlyOwner {
    require(preSaleMax_ > 0, "Error: preSaleMintLimit must be greater than 0");
    require(
      preSaleMax_ <= MAX_SUPPLY,
      "Error: preSaleMintLimit must be less than or equal to MAX_SUPPLY"
    );
    _preSaleMintLimit = preSaleMax_;
    emit PreSaleMintLimitChanged(msg.sender, _preSaleMintLimit);
  }

  function setMaxMintablePerAddress(uint256 max_) public onlyOwner {
    require(max_ > 0, "Error: maxMintablePerAddress must be greater than 0");
    _maxMintablePerAddress = max_;
    emit MaxMintablePerAddressChanged(msg.sender, _maxMintablePerAddress);
  }

  function setPreSalePrice(uint256 price_) public onlyOwner {
    require(price_ > 0, "Error: Price must be greater than 0");
    _preSalePrice = price_;
    emit PriceChanged(msg.sender, _preSalePrice, false);
  }

  function setPublicSalePrice(uint256 price_) public onlyOwner {
    require(price_ > 0, "Error: Price must be greater than 0");
    _publicSalePrice = price_;
    emit PriceChanged(msg.sender, _publicSalePrice, true);
  }

  function setPreSalePaused(bool paused_) public onlyOwner {
    if (paused_) {
      _preSalePause();
    } else {
      _preSaleUnpause();
    }
  }

  function setPublicSalePaused(bool paused_) public onlyOwner {
    if (paused_) {
      _publicSalePause();
    } else {
      _publicSaleUnpause();
    }
  }

  function mintForGiveaway(
    address to_,
    uint256 amount_
  ) external onlyOwner onlyUnderMaxSupply(amount_) {
    // zero address check
    require(to_ != address(0), "Error: Zero address");
    // quantity check
    require(amount_ > 0, "Error: Amount must be greater than 0");
    // batch preMint limit check
    require(
      amount_ <= 1,
      "Error: The maximum limit that can be obtained in a batch mint has been reached"
    );

    _mint(to_, amount_);
  }

  function withdrawValue() external onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
    emit WithdrawnETH(msg.sender, address(this).balance);
  }
}
