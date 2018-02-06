pragma solidity ^0.4.19;

// @title  SwearJar
// @author Luke Hedger
contract SwearJar {
  /*
   * @notice Jar
   * @param {uint}    deposit Required Deposit to Vote in Jar
   * @param {uint}    fine    Fine fee for a Swear
   * @param {address} owner   Jar owner
   * @param {uint}    quorum  Number of Votes required to ratify a Swear
   */
  struct Jar {
    uint deposit;
    uint fine;
    address owner;
    uint quorum;
  }

  /*
   * @notice JarCreated event
   * @param {bytes32} _jar
   */
  event JarCreated(bytes32 _jar);

  /*
   * @notice A Shelf for all the Jars
   */
  mapping(bytes32 => Jar) shelf;

  /*
   * @notice Log of Jar Voters' Deposits
   * @todo This needs to also be keyed by Jar, to allow Voters to participate in multiple Jars
   */
  mapping(address => uint) deposits;

  /*
   * @notice SwearJar contract constructor function - called when creating the contract.
   */
  function SwearJar() public {

  }

  /*
   * @notice Method to create a new Jar
   * @param {bytes32} _jar     Hash of the Jar name
   * @param {uint}    _deposit Required Deposit to Vote in Jar
   * @param {uint}    _fine    Fine fee for a Swear
   * @param {uint}    _quorum  Number of Votes required to ratify a Swear
   */
  function createJar(bytes32 _jar, uint _deposit, uint _fine, uint _quorum) public {
    address owner = msg.sender;

    // Check Jar does not already exist on the Shelf
    if (shelf[_jar] == true) {
      revert();
    }

    // Create new Jar
    Jar jar = Jar(_deposit, _fine, owner, _quorum);

    // Add Jar to the Shelf
    shelf[_jar] = jar;

    // Fire JarCreated event
    JarCreated(_jar);
  }

  /**
   * @todo Register Voter to a Jar with required Deposit
   */
  function registerVoter() public payable {

  }

  /**
   * @todo Record Swear
   */
  function recordSwear() public {

  }

  /**
   * @todo Add Vote on a Swear (cost to vote? or deposit > required minimum?)
   * @todo If enough Votes are received, debit Fine from Deposit - distribute amongst Voters
   * @todo If Deposit is depleted, the account must 'top-up' to restore right to Vote
   */
  function upVoteSwear() public {

  }
}
