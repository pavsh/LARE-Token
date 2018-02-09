
pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    uint256 public uintsOneEthCanBuy;     // How many uints of your coin can be bought by 1 ETH?
    uint256 public totalEthInWei;         // WEI is the smallest uint of ETH (the equivalent of cent in USD or satoshi in BTC). We'll store the total ETH raised via our ICO here.  
    address public fundsWallet;           // Where should the raised ETH go?
    uint256 public minContributionPreSale;
     uint256 public minContributionMainSale;
     uint256 public maxContributionEther;
     uint256 public Softcap;
     uint256 public Hardcap;
     uint ICOStart=1520121600 ; // 04.03.18 in unixtime
     uint public stage1End = 1528070400;  // 04.06.18 unixtime
     uint public stage2End = 1536019200; // 04.09.18 unixtime
     uint stage3End = 1546560000; // 04.01.19 unixtime
     uint ICOEnd = 1546560000; //  04.01.19 unixtime
     uint oneFifth=20; // 20/100=1/5- need it for getting 0.2
     struct Tier {

        uint amount;
        uint bonus; // in percent
     }
     Tier public Tier1 = Tier(2500000000,70);
     Tier public Tier2 = Tier(2500000000,60);
     Tier public Tier3 = Tier(2500000000,50);
     Tier public Tier4 = Tier(2500000000,40);
     Tier public Tier5 = Tier(3000000000,30);
     Tier public Tier6 = Tier(3000000000,10);
     Tier public Tier7 = Tier(3000000000,8);
     Tier public Tier8 = Tier(3000000000,6);
     Tier public Tier9 = Tier(3000000000,4);
     Tier public Tier10 = Tier(3000000000,2);
     Tier[] Tiers;
     uint public currentTier=0;  //holds the bonus of the curren tier. the Bonus function moving to next tier.

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) {
        uintsOneEthCanBuy = 1500;  

        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}
