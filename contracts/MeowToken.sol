// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// Slight modifiations from base Open Zeppelin Contracts
// Consult /oz/README.md for more information
import "./oz-meow/ERC20Upgradeable.sol";
import "./oz-meow/ERC20SnapshotUpgradeable.sol";
import "./oz-meow/ERC20PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MeowToken is
  OwnableUpgradeable,
  ERC20Upgradeable,
  ERC20PausableUpgradeable,
  ERC20SnapshotUpgradeable
{
  event AuthorizedSnapshotter(address account);
  event DeauthorizedSnapshotter(address account);

  // Mapping which stores all addresses allowed to snapshot
  mapping(address => bool) authorizedToSnapshot;

  function initialize(string memory name, string memory symbol, uint amount)
    public
    initializer
  {
    __Ownable_init();
    __ERC20_init(name, symbol);
    __ERC20Snapshot_init();
    __ERC20Pausable_init();
    _mint(msg.sender, amount*10**decimals());
  }

  // Call this on the implementation contract (not the proxy)
  function initializeImplementation() public initializer {
    __Ownable_init();
    _pause();
  }


  /**
   * Utility function to transfer tokens to many addresses at once.
   * @param recipients The addresses to send tokens to
   * @param amount The amount of tokens to send
   * @return Boolean if the transfer was a success
   */
  function transferBulk(address[] calldata recipients, uint256 amount)
    external
    returns (bool)
  {
    address sender = _msgSender();

    uint256 total = amount * recipients.length;
    require(
      _balances[sender] >= total,
      "ERC20: transfer amount exceeds balance"
    );

    _balances[sender] -= total;

    for (uint256 i = 0; i < recipients.length; ++i) {
      address recipient = recipients[i];
      require(recipient != address(0), "ERC20: transfer to the zero address");

      _balances[recipient] += amount;

      emit Transfer(sender, recipient, amount);
    }

    return true;
  }

  /**
   * Utility function to transfer tokens to many addresses at once.
   * @param sender The address to send the tokens from
   * @param recipients The addresses to send tokens to
   * @param amount The amount of tokens to send
   * @return Boolean if the transfer was a success
   */
  function transferFromBulk(
    address sender,
    address[] calldata recipients,
    uint256 amount
  ) external returns (bool) {
    uint256 total = amount * recipients.length;
    require(
      _balances[sender] >= total,
      "ERC20: transfer amount exceeds balance"
    );

    // Ensure enough allowance
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= total,
      "ERC20: transfer total exceeds allowance"
    );
    _approve(sender, _msgSender(), currentAllowance - total);

    _balances[sender] -= total;

    for (uint256 i = 0; i < recipients.length; ++i) {
      address recipient = recipients[i];
      require(recipient != address(0), "ERC20: transfer to the zero address");

      _balances[recipient] += amount;

      emit Transfer(sender, recipient, amount);
    }

    return true;
  }


  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  )
    internal
    virtual
    override(
      ERC20PausableUpgradeable,
      ERC20SnapshotUpgradeable,
      ERC20Upgradeable
    )
  {
    if (to == address(this)) {
      _burn(from, amount);
    }
    super._beforeTokenTransfer(from, to, amount);
  }
}