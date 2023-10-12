// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Vault, Fractions, NftVault} from "../src/Nftfraction.sol";
import {OurNFT} from "./MockNft.sol";
import {Test, console2} from "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract NftMarketplaceTest is Test {
    Vault public NftMarket;
    NftVault nftvault;
    Fractions frac;
    OurNFT public Nft;

    uint256 ownerPriv =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address public owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public user = vm.addr(123444);
    // address public nftAddr;
    uint256 public tokenId = 9351;
    uint256 public price = 3 ether;
    uint256 public deadline = 1 days;
    bytes public signature;

    function setUp() public {
        NftMarket = new Vault();
        Nft = new OurNFT();
    }

    function testCreateFraction() public {
        Nft.mint(address(this), 1);
        Nft.approve(address(NftMarket), 1);
        NftMarket.createFraction(address(Nft), 1, 100, 2 ether);

        assertEq(Nft.balanceOf(address(this)), 0);
        assertEq(Nft.balanceOf(address(NftMarket)), 1);
    }

    function testBuyFraction() public {
        vm.startPrank(owner);
        Nft.mint(owner, 1);
        Nft.approve(address(NftMarket), 1);
        NftMarket.createFraction(address(Nft), 1, 10, 2 ether);
        vm.stopPrank();

        vm.deal(address(this), 4 ether);
        NftMarket.buyFraction{value: 1 ether}(address(Nft), 1);
    }

    function testDelist() public {
        vm.startPrank(owner);
        Nft.mint(owner, 1);
        Nft.approve(address(NftMarket), 1);
        NftMarket.createFraction(address(Nft), 1, 10, 2 ether);

        vm.deal(owner, 5 ether);
        NftMarket.buyFraction{value: 2 ether}(address(Nft), 1);

        NftMarket.deListNft(address(Nft), 1);

        assertEq(Nft.balanceOf(address(NftMarket)), 0);
        assertEq(Nft.balanceOf(owner), 1);
    }

    function testDelistFail() public {
        Nft.mint(address(this), 1);
        Nft.approve(address(NftMarket), 1);
        NftMarket.createFraction(address(Nft), 1, 10, 2 ether);

        vm.expectRevert("You do not own all the fractions");
        NftMarket.deListNft(address(Nft), 1);
    }

    receive() external payable {}

    fallback() external payable {}
}
