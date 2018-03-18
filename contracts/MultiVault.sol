pragma solidity ^0.4.18;

contract MultiVault {
    // ----------------------------------------------
    // ---------------- Globals ---------------------
    // ----------------------------------------------

    address public owner;

    struct Rank {
        bytes32 name;               // What is the common name of this rank
        uint level;                 // What permission level does this rank hold
        uint256 withdrawalLimit;    // How many daily withdrawals
        uint resetTime;             // How long until their withdrawal limit resets
    }

    struct Withdraw {
        address asset;
        uint at;
        bool pending;
    }

    bytes32[] rankNames;

    mapping(bytes32 => Rank) ranks;
    mapping(address => bytes32) members;
    mapping(address => Withdraw[]) withdraws;

    // Permissions levels
    // Any rank with a level lower than permission level will be restricted
    uint[] permissions = [
        2, // addMember
        2 // Requires approval
    ];

    function MultiVault () public {
        owner = msg.sender;
    }

    // ----------------------------------------------
    // ---------------- Modifiers -------------------
    // ----------------------------------------------
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyApprovers {
        require(_canApproveMember(msg.sender));
        _;
    }

    // ----------------------------------------------
    // ----------- Internal Functions ---------------
    // ----------------------------------------------

    // Check if a member is allowed to approve another member
    function _canApproveMember (address member) internal view returns (bool allowed) {
        bytes32 memberRank = members[member];
        return (
            ranks[memberRank].level >= permissions[0] || 
            member == owner
        );
    }

    function _withdrawalLimitSurpassed (address member) internal view returns (bool allowed) {
        uint256 twentyfourhours;

        Withdraw[] memory memberWithdrawals = withdraws[member];

        for (uint i = 0; i < memberWithdrawals.length; i++) {
            if (now - memberWithdrawals[i].at < 86400) {
                twentyfourhours++;
            }
        }

        return twentyfourhours > ranks[members[member]].withdrawalLimit;
    }

    // ----------------------------------------------   
    // ------------ Getter Functions ----------------
    // ----------------------------------------------

    // Get available ranks in the system
    function getRanks () public view returns (bytes32[] _ranks) {
        return rankNames;
    }

    // Get the rank of a member
    function getMemberRank (address member) public view returns (bytes32 rank) {
        return members[member];
    }

    // Get a rank
    function getRank (bytes32 rank) public view returns (bytes32 name, uint level, uint256 withdrawalLimit, uint resetTime) {
        return (
            ranks[rank].name,
            ranks[rank].level,
            ranks[rank].withdrawalLimit,
            ranks[rank].resetTime
        );
    }

    // ----------------------------------------------   
    // ------------ Public Functions ----------------
    // ----------------------------------------------

    function createRank (bytes32 name, uint level, uint withdrawalLimit, uint resetTime) external onlyOwner {
        require(ranks[name].name == 0x0);
        ranks[name] = Rank({
            name: name,
            level: level,
            withdrawalLimit: withdrawalLimit,
            resetTime: resetTime
        });
        rankNames.push(name);
    }

    // ------------ Member Managment -----------------

    // Add a member to the vault
    function addMember (address member, bytes32 rank) external onlyApprovers {
        require(members[member] == 0x0);
        members[member] = rank;
    }

    // Change the rank of a member in the system
    function changeMemberRank (address member, bytes32 rank) external onlyOwner {
        require(members[member] != 0x0);
        members[member] = rank;
    }

    // -------------- Permissions -------------------
    // Change permission levels of different core tasks

    // Change the level required to add a member to the vault
    function changeAddMemberLevel (uint level) external onlyOwner {
        permissions[0] = level;
    }

    // Change the level required to add withdrawal without approval from the vault
    function changeRequiresApprovalLevel (uint level) external onlyOwner {
        permissions[1] = level;
    }

    // Change a ranks permission level
    function changeRankLevel (bytes32 rank, uint level) external onlyOwner {
        ranks[rank].level = level;
    }
}