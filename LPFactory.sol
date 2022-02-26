pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

interface WETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);
}

contract Token is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }
}

interface ISwapV2 {
    /// @return Returns the address of the Uniswap V2 factory
    function factoryV2() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

contract LPFactory is Ownable, ReentrancyGuard {
    event Deposit(
        address indexed chatroom,
        address indexed owner,
        uint256 amount
    );

    event CreateLP(address indexed chatroom, address indexed owner);

    event Claim(
        address indexed chatroom,
        address indexed owner,
        uint256 amount
    );

    struct DepositOrder {
        address owner;
        uint256 amount;
    }

    struct Chatroom {
        Token token;
        address pair;
        uint256 status;
        uint256 totalFund;
    }

    ISwapV2 public router = ISwapV2(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    uint256 public baseFund = 10**17;

    uint256 public createLPTimes = 1;

    mapping(address => Chatroom) public chatroomStatus;

    mapping(address => DepositOrder[]) public chatroomFund;

    mapping(address => mapping(address => bool)) claimed;

    function setBaseFund(uint256 _baseFund) external onlyOwner {
        baseFund = _baseFund;
    }

    function setCreateLPTimes(uint256 _createLPTimes) external onlyOwner {
        createLPTimes = _createLPTimes;
    }

    function setRouter(ISwapV2 _router) external onlyOwner {
        router = _router;
    }

    function getChatroomFundLength(address _chatroom)
        external
        view
        returns (uint256)
    {
        return chatroomFund[_chatroom].length;
    }

    function deposit(address _chatroom) external payable {
        require(
            chatroomStatus[_chatroom].status == 0,
            "Ether Chat : you can't deposit , LP has been created"
        );
        require(
            msg.value % baseFund == 0 && msg.value > 0,
            "Ether Chat : amount must geater than zero and eliminate baseFund"
        );
        chatroomFund[_chatroom].push(
            DepositOrder({owner: msg.sender, amount: msg.value})
        );
        chatroomStatus[_chatroom].totalFund += msg.value;
        emit Deposit(_chatroom, msg.sender, msg.value);
    }

    function createLP(address _chatroom) external nonReentrant {
        require(
            chatroomStatus[_chatroom].status == 0,
            "Ether Chat : LP has been created"
        );
        require(
            chatroomStatus[_chatroom].totalFund >= baseFund * createLPTimes,
            "Ether Chat : Below the minimum"
        );
        uint256 totalSupply = 10**10 * 10**18;
        Token token = new Token("", "", totalSupply);
        WETH weth = WETH(router.WETH9());
        address pair = IUniswapV2Factory(router.factoryV2()).createPair(
            address(weth),
            address(token)
        );

        uint256 fee = (chatroomStatus[_chatroom].totalFund * 3) / 100;

        token.transfer(pair, (totalSupply * 15) / 100);
        token.transfer(msg.sender, (totalSupply * 7) / 100);
        token.transfer(owner(), (totalSupply * 3) / 100);

        payable(owner()).transfer(fee);
        uint256 pairAmount = chatroomStatus[_chatroom].totalFund - fee;
        weth.deposit{value: pairAmount}();
        weth.transfer(pair, pairAmount);
        IUniswapV2Pair(pair).mint(address(this));
        chatroomStatus[_chatroom].pair = pair;
        chatroomStatus[_chatroom].token = token;
        chatroomStatus[_chatroom].status = 1;
        emit CreateLP(_chatroom, msg.sender);
    }

    function claim(address _chatroom) external nonReentrant {
        require(
            chatroomStatus[_chatroom].status == 1,
            "Ether Chat : LP must be created"
        );
        require(
            !claimed[_chatroom][msg.sender],
            "Ether Chat : The account has been claimed"
        );
        uint256 amount;
        for (uint256 i = 0; i < chatroomFund[_chatroom].length; i++) {
            if (chatroomFund[_chatroom][i].owner == msg.sender) {
                amount += chatroomFund[_chatroom][i].amount;
            }
        }
        uint256 claimAmount = (((chatroomStatus[_chatroom].token.totalSupply() *
            amount) / chatroomStatus[_chatroom].totalFund) * 70) / 100;
        uint256 contractLeftAmount = chatroomStatus[_chatroom].token.balanceOf(
            address(this)
        );
        if (contractLeftAmount < claimAmount) {
            claimAmount = contractLeftAmount;
        }
        chatroomStatus[_chatroom].token.transfer(msg.sender, claimAmount);
        claimed[_chatroom][msg.sender] = true;
        emit Claim(_chatroom, msg.sender, claimAmount);
    }
}
