// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {
    ShardsNFTMarketplace,
    IShardsNFTMarketplace,
    ShardsFeeVault,
    DamnValuableToken,
    DamnValuableNFT
} from "../../src/shards/ShardsNFTMarketplace.sol";
import {DamnValuableStaking} from "../../src/DamnValuableStaking.sol";

contract Handler is Test {
    address user = makeAddr("user");
    ShardsNFTMarketplace marketplace;
    DamnValuableToken token;
    uint64 offerId;
    uint256 purchasesLen;

    uint256 constant USER_INIT_BALANCE = 10000e20;

    // purchaseIndex => paid
    mapping(uint256 => uint256) public paid;

    constructor(ShardsNFTMarketplace _marketplace, DamnValuableToken _token, uint64 _offerId) {
        marketplace = _marketplace;
        token = _token;
        offerId = _offerId;
        deal(address(token), user, USER_INIT_BALANCE);
    }

    modifier useUser() {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }

    function actFill(uint256 _want) public useUser {
        IShardsNFTMarketplace.Offer memory offer = marketplace.getOffer(offerId);
        uint256 stock = offer.stock;
        if (stock == 0) return;
        uint256 want = bound(_want, 1, stock / 100);
        uint256 balanceBefore = token.balanceOf(user);
        token.approve(address(marketplace), UINT256_MAX);
        purchasesLen = marketplace.fill(offerId, want) + 1;
        uint256 balanceAfter = token.balanceOf(user);
        paid[purchasesLen - 1] = balanceBefore - balanceAfter;
    }

    function actCancel(uint256 _index) public useUser {
        if (purchasesLen == 0) return;
        uint256 index = bound(_index, 0, purchasesLen - 1);
        IShardsNFTMarketplace.Purchase memory purchase;
        (,,,, purchase.cancelled) = marketplace.purchases(offerId, index);
        if (purchase.cancelled) return;
        uint256 balanceBefore = token.balanceOf(user);
        marketplace.cancel(offerId, index);
        uint256 balanceAfter = token.balanceOf(user);
        assertEq(balanceAfter - balanceBefore, paid[index]);
    }
}
