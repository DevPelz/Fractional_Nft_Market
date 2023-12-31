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

    function burn(address operator, uint256 amount) external virtual {
        _burn(operator, amount);
    }
}

contract Vault is IERC721Receiver {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(address => NftVault[]) public _vaults;
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
        uint256 Listprice
        // address FractionTokens
    );

    // create a fraction based on the nft

    function createFraction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _fractions,
        uint256 _Listprice
    ) external {
        IERC721(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        vaultPosition[_nftAddress][_tokenId] = _vaults[_nftAddress].length;
        Fractions _FractionTokens = new Fractions(
            "Fractional NFT",
            "FracNFT",
            _fractions
        );

        _vaults[_nftAddress].push(
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
        uint256 vaultI = vaultPosition[_nftAddress][_tokenId];
        NftVault storage vault = _vaults[_nftAddress][vaultI];

        //   check price of fraction
        Fractions _FractionTokens = Fractions(vault.FractionTokens);
        uint256 _frac = _FractionTokens.totalSupply();
        uint256 _price = vault.Listprice / vault.fractions;
        require(msg.value >= _price, "Not enough funds to buy");
        uint256 _amount = msg.value / _price;
        require(_frac >= _amount, "Not enough fractions to buy");

        // update the fraction tokens
        vault.fractions -= _amount;
        _FractionTokens.transfer(msg.sender, _amount);

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
            vault.Listprice
        );
    }

    // withdraw nft

    function deListNft(address _nftAddress, uint256 _tokenId) external {
        uint256 vaultI = vaultPosition[_nftAddress][_tokenId];
        NftVault storage vault = _vaults[_nftAddress][vaultI];

        // check that msg.sender has all the fraction tokens totalling to the total supply
        Fractions _FractionTokens = Fractions(vault.FractionTokens);
        uint256 _frac = _FractionTokens.balanceOf(msg.sender);
        uint256 _totalSupply = _FractionTokens.totalSupply();
        require(_frac == _totalSupply, "You do not own all the fractions");

        // burn all fractions
        _FractionTokens.burn(msg.sender, _frac);

        // delete vault
        delete _vaults[vault.seller];
        delete vaultPosition[_nftAddress][_tokenId];

        // transfer nft to msg.sender

        IERC721(_nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
