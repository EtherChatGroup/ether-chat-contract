pragma solidity ^0.8.0;

//  _______  _________  ___  ___  _______   ________          ________  ___  ___  ________  _________
// |\  ___ \|\___   ___\\  \|\  \|\  ___ \ |\   __  \        |\   ____\|\  \|\  \|\   __  \|\___   ___\
// \ \   __/\|___ \  \_\ \  \\\  \ \   __/|\ \  \|\  \       \ \  \___|\ \  \\\  \ \  \|\  \|___ \  \_|
//  \ \  \_|/__  \ \  \ \ \   __  \ \  \_|/_\ \   _  _\       \ \  \    \ \   __  \ \   __  \   \ \  \
//   \ \  \_|\ \  \ \  \ \ \  \ \  \ \  \_|\ \ \  \\  \|       \ \  \____\ \  \ \  \ \  \ \  \   \ \  \
//    \ \_______\  \ \__\ \ \__\ \__\ \_______\ \__\\ _\        \ \_______\ \__\ \__\ \__\ \__\   \ \__\
//     \|_______|   \|__|  \|__|\|__|\|_______|\|__|\|__|        \|_______|\|__|\|__|\|__|\|__|    \|__|

contract EtherChat {
    uint256 public id;

    event Write(
        address indexed _token,
        address indexed _owner,
        string _content,
        uint256 _id
    );

    function write(address _address, string memory _content) public {
        _write(_address, _content);
    }

    function _write(address _address, string memory _content) internal {
        emit Write(_address, msg.sender, _content, id++);
    }
}
