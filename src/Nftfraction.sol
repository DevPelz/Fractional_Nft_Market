// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

// create vault for fractional nft

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

struct NftVault {
    address seller;
    address nftAddress;
    uint256 tokenId;
    uint256 fractions;
    uint256 timestamp;
    uint256 Listprice;
    address FractionTokens;
}

contract Fractions is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint _frac
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, _frac);
    }
}

contract Vault is IERC721Receiver {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // vault array
    NftVault[] public vaults;

    mapping(address => NftVault) public _vaults;
    mapping(address => mapping(uint256 => uint256)) public vaultPosition;

    // events
    event NftCreated(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 fractions,
        uint256 timestamp,
        uint256 Listprice,
        address FractionTokens
    );

    event NftBought(
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 fractions,
        uint256 timestamp,
        uint256 Listprice,
        address FractionTokens
    );

    // create a fraction based on the nft

    function createFraction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _fractions,
        uint256 _Listprice
    ) external {
        ERC721(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        vaultPosition[_nftAddress][_tokenId] = vaults[msg.sender];
        Fractions _FractionTokens = new Fractions(
            "Fractional NFT",
            "FracNFT",
            _fractions
        );

        vaults.push(
            NftVault({
                seller: msg.sender,
                nftAddress: _nftAddress,
                tokenId: _tokenId,
                fractions: _fractions,
                timestamp: block.timestamp,
                Listprice: _Listprice,
                FractionTokens: address(_FractionTokens)
            })
        );

        emit NftCreated(
            msg.sender,
            _nftAddress,
            _tokenId,
            _fractions,
            block.timestamp,
            _Listprice,
            address(_FractionTokens)
        );
    }

    // buy fraction of nft and give the tokens to the buyer

    function buyFraction(
        address _nftAddress,
        uint256 _tokenId
    ) external payable {
        NftVault storage vault = vaultPosition[_nftAddress][_tokenId];

        //   check price of fraction
        Fractions _FractionTokens = Fractions(vault.FractionTokens);
        uint256 _frac = _FractionTokens.totalSupply();
        uint256 _price = vault.Listprice / vault.fractions;
        require(msg.value >= _price, "Not enough funds to buy");
        uint256 _amount = msg.value / _price;
        require(_frac >= _amount, "Not enough fractions to buy");

        // update the fraction tokens
        vault.fractions -= _amount;
        _FractionTokens.transferFrom(vault.seller, msg.sender, _amount);

        // calculate 0.1% from the price of each fraction
        uint256 fee = _price / 1000;
        uint256 _fee = fee * _amount;

        //transfer ether to seller
        (bool success, ) = payable(vault.seller).call{value: msg.value - _fee}(
            ""
        );

        require(success, "Transfer failed.");

        // transfer fee to owner
        (bool success2, ) = payable(owner).call{value: _fee}("");
        require(success2, "Transfer failed.");

        emit NftBought(
            vault.seller,
            msg.sender,
            _nftAddress,
            _tokenId,
            _amount,
            block.timestamp,
            vault.Listprice,
            vault.FractionTokens
        );
    }
}
