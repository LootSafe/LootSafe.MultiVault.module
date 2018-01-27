pragma solidity ^0.4.18;

contract MultiVault {
    // ----------------------------------------------
    // ---------------- Globals ---------------------
    // ----------------------------------------------

    address public owner;

    struct Rank {
        bytes32 name;               // What is the common name of this rank
        uint level;                 // What permission level does this rank hold
        uint256 withdrawalLimit;    // How many assets can they withdrawal
        uint resetTime;             // How long until their withdrawal limit resets
        bool requiresApproval;      // Should withdrawals require approval from higher rank
    }

    struct Withdraw {
        address asset;
        uint at;
        bool pending;
    }

    bytes32[] rankNames;

    mapping(bytes32 => Rank) ranks;
    mapping(address => bytes32) members;
    mapping(address => Withdraw) withdraws;

    // Permissions levels
    uint[] permissions = [
        0 // addMember
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

    function _withdrawalLimitSurpassed () internal view returns (bool allowed) {

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
    function getRank (bytes32 rank) public view returns (bytes32 name, uint level, uint256 withdrawalLimit, uint resetTime, bool requiresApproval) {
        return (
            ranks[rank].name,
            ranks[rank].level,
            ranks[rank].withdrawalLimit,
            ranks[rank].resetTime,
            ranks[rank].requiresApproval
        );
    }

    // ----------------------------------------------   
    // ------------ Public Functions ----------------
    // ----------------------------------------------

    function createRank (bytes32 name, uint level, uint withdrawalLimit, uint resetTime, bool requiresApproval) external onlyOwner {
        require(ranks[name].name == 0x0);
        ranks[name] = Rank({
            name: name,
            level: level,
            withdrawalLimit: withdrawalLimit,
            resetTime: resetTime,
            requiresApproval: requiresApproval
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

    // Change a ranks permission level
    function changeRankLevel (bytes32 rank, uint level) external onlyOwner {
        ranks[rank].level = level;
    }
}