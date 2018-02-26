pragma solidity ^0.4.19;

// @title  SwearJar
// @author Luke Hedger
contract SwearJar {
  /*
   * @notice Jar struct
   * @param {uint}    deposit Required Deposit to Vote in Jar
   * @param {address} owner   Jar owner, probably a multisig
   * @param {uint}    quorum  Number of Votes required to ratify a Swear
   */
  struct Jar {
    uint deposit;
    address owner;
    uint quorum;
  }

  /**
   * @notice Swear struct
   * @param {bool}         exists      Flag to verify existence of record
   * @param {bool}         open        Flag to permit votes
   * @param {address}      swearer     Who swore!?
   * @param {uint}         timestamp   Time of Swear
   * @param {uint}         votes       Number of votes that Swear is genuine
   * @param {address[]}    voters      List of voters who confirmed Swear
   */
  struct Swear {
    bool exists;
    bool open;
    address swearer;
    uint timestamp;
    uint votes;
    address[] voters;
  }

  /**
   * @notice Voter struct
   * @param {uint}    balance Current balance
   * @param {bool}    exists  Flag to verify existence of record
   * @param {address} owner   Voter address
   * @param {bool}    right   Flag to verify right to vote
   */
  struct Voter {
    uint balance;
    bool exists;
    address owner;
    bool right;
  }

  /*
   * @notice BalanceRestored event
   * @param {address} _voter
   */
  event BalanceRestored(address _voter);

  /*
   * @notice JarCreated event
   */
  event JarCreated();

  /*
   * @notice JarEmptied event
   * @param {address} _recipient
   */
  event JarEmptied(address _recipient);

  /*
   * @notice SwearConfirmed event
   * @param {bytes32} _swear
   * @param {address} _swearer
   */
  event SwearConfirmed(bytes32 _swear, address _swearer);

  /*
   * @notice SwearRecorded event
   * @param {bytes32} _swear
   * @param {address} _swearer
   */
  event SwearRecorded(bytes32 _swear, address _swearer);

  /*
   * @notice SwearUpVoted event
   * @param {bytes32} _swear
   * @param {address} _voter
   */
  event SwearUpVoted(bytes32 _swear, address _voter);

  /*
   * @notice VoterDepositDebited event
   * @param {address} _voter
   */
  event VoterDepositDebited(address _voter);

  /*
   * @notice VoterRegistered event
   * @param {address} _voter
   */
  event VoterRegistered(address _voter);

  /*
   * @notice Store of Jar Swears
   */
  mapping(bytes32 => Swear) public swearStore;

  /*
   * @notice Store of Jar Voters
   */
  mapping(address => Voter) public voterStore;

  /*
   * @notice The Swear Jar
   */
  Jar internal jar;

  /*
   * @notice SwearJar contract constructor function - called when creating the
             contract. Will create a new Jar with the given parameters.
   * @param {uint} _deposit Required Deposit to Vote in Jar
   * @param {uint} _quorum  Number of Votes required to ratify a Swear
   */
  function SwearJar(uint _deposit, uint _quorum) public {
    // Set Jar owner to message sender
    address owner = msg.sender;

    // Create new Jar
    jar = Jar(_deposit, owner, _quorum);

    // Fire JarCreated event
    JarCreated();
  }

  /**
   * @notice Method to allow a Jar owner to withdraw all funds
   */
  function emptySwearJar() public {
    // Set the receiving address to message sender
    address recipient = msg.sender;

    // Check Jar is owned by sender
    if (jar.owner != recipient) {
      revert();
    }

    // Get the current Jar balance
    uint balance = this.balance;

    // Send the entire Jar balance to the owner
    recipient.transfer(balance);

    // Fire JarEmptied event
    JarEmptied(recipient);
  }

  /**
   * @notice Method to record a Swear
   * @param {bytes32} _swear     Hash of the Swear word, timestamp and swearer address
   * @param {address} _swearer   Offending account
   * @param {uint}    _timestamp Time the Swear took place - could use `block.timestamp` instead?
   */
  function recordSwear(bytes32 _swear, address _swearer, uint _timestamp) public {
    // Set the initial Swear Voter to the message sender
    address voter = msg.sender;

    // Check Swearer is a Voter on the Jar
    if (voterStore[_swearer].exists != true) {
      revert();
    }

    // Check Swearer has required balance to be able to pay fine
    if (voterStore[_swearer].balance < jar.deposit) {
      revert();
    }

    // Initialise number of votes to one (recorder counts as the first vote)
    uint votes = 1;

    // Initialise voters array
    address[] voters;

    // Add initial voter to voters array
    voters.push(voter);

    // Create new Swear
    Swear swear = Swear(true, true, _swearer, _timestamp, votes, voters);

    // Add Swear to store
    swearStore[_swear] = swear;

    // Fire SwearRecorded event
    SwearRecorded(_swear, _swearer);
  }

  /**
   * @notice Method to register a Voter to a Jar
   */
  function registerVoter() public payable {
    address voterAddress = msg.sender;
    uint voterDeposit = msg.value;

    // Check that Voter is not already registerd to Jar
    if (voterStore[voterAddress].exists == true) {
      revert();
    }

    // Check that Deposit is above minimum required to Vote in Jar
    if (voterDeposit < jar.deposit) {
      revert();
    }

    // Create new Voter
    Voter voter = Voter(voterDeposit, true, voterAddress, true);

    // Add Voter to store
    voterStore[voterAddress] = voter;

    // Fire VoterRegistered event
    VoterRegistered(voter);
  }

  /**
   * @notice Method to restore the balance of a Voter
   */
  function restoreVoterBalance() public payable {
    address voterAddress = msg.sender;
    uint voterDeposit = msg.value;

    // Check that Voter is already registerd to Jar
    if (voterStore[voterAddress].exists != true) {
      revert();
    }

    // Check that Deposit is above minimum required to Vote in Jar
    if (voterDeposit < jar.deposit) {
      revert();
    }

    // Restore Voter's balance
    voterStore[voterAddress].balance = voterDeposit;

    // Restore Voter's right to vote
    voterStore[voterAddress].right = true;

    // Fire BalanceRestored event
    BalanceRestored(voterAddress);
  }

  /**
   * @notice Method to vote that a Swear is genuine
   * @param {bytes32} _swear
   */
  function upVoteSwear(bytes32 _swear) public {
    // Set voter to message sender
    address voter = msg.sender;

    // Get voter's right to vote
    bool right = voterStore[voter].right;

    // Check that the Swear has been recorded
    if (swearStore[_swear].exists != true) {
      revert();
    }

    // Check that Voter has right to vote
    if (right != true) {
      revert();
    }

    // Check that Swear is open to voting
    if (swearStore[_swear].open != true) {
      revert();
    }

    // Add Voter address to Swear.voters array
    swearStore[_swear].voters.push(voter);

    // Add Vote to votes count
    swearStore[_swear].votes += 1;

    // Fire SwearUpVoted event
    SwearUpVoted(_swear, voter);

    // Check if Jar quorum has now been reached
    if (swearStore[_swear].votes >= jar.quorum) {
      // Close Swear voting
      swearStore[_swear].open = false;

      // Debit the deposit from the swearing Voter
      debitVoterDeposit(swearStore[_swear].swearer);

      // Fire SwearConfirmed event
      SwearConfirmed(_swear, swearStore[_swear].swearer);
    }
  }

  /**
   * @notice Method to debit a Deposit from a Voter for a Swear
   * @param {address} _voter
   */
  function debitVoterDeposit(address _voter) internal {
    // Set the deposit value to the required Jar deposit
    uint deposit = jar.deposit;

    // Debit Deposit from swearing Voter
    voterStore[_voter].balance -= deposit;

    // Revoke Voter's right to vote
    voterStore[_voter].right = false;

    // Fire VoterDepositDebited event
    VoterDepositDebited(_voter);
  }
}
