// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title: ERC721 Framework.
/// @author: Zume

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

import './@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol';
import './@rarible/royalties/contracts/LibRoyaltiesV2.sol';
import './@rarible/royalties/contracts/LibPart.sol';

import 'base64-sol/base64.sol';
import 'hardhat/console.sol';

contract frameERC721 is ERC721URIStorage, Ownable, RoyaltiesV2Impl {
  bool private paused;
  uint256 private mintPrice;
  uint256 private maxSupply;
  uint256 public tokenCount;
  uint256 public _completionTimestamp;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor() ERC721('frameERC721', 'FRAME.') {
    maxSupply = 10;
    mintPrice = 0.1 ether;
    _completionTimestamp = block.timestamp + 3 weeks;
  }

  function mint() public payable {
    require(!paused, 'Minting paused.');
    require(msg.value == mintPrice, 'Incorrect price.');
    require(tokenCount + 1 <= maxSupply, 'Sold out.');
    tokenCount = tokenCount + 1;
    _safeMint(msg.sender, tokenCount);
  }

  function setRoyalties(
    uint256 _tokenId,
    address payable _royaltiesRecipientAddress,
    uint96 _percentageBasisPoints
  ) public onlyOwner {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _royaltiesRecipientAddress;
    _saveRoyalties(_tokenId, _royalties);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    LibPart.Part[] memory _royalties = royalties[_tokenId];
    if (_royalties.length > 0) {
      return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
    }
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  function generateSVG() public pure returns (string memory) {
    string memory svgURL = string(
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="-.5 -.5 1 1"><defs><linearGradient id="prefix__b" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="hsl(202.8397,53.9769%,52.7838%)"/><stop offset="100%" stop-color="hsl(0,0%,95%)"/></linearGradient><filter id="prefix__a"><feColorMatrix values="-0.639 -1.920 0.000 0.934 -0.852 -0.604 0.328 0.000 0.934 0.876 -3.300 1.290 0.000 0.934 0.000 0.000 0.000 1.000 0.000"/><feColorMatrix type="hueRotate" values="0"><animate attributeName="values" values="140; 200; 260;" calcMode="spline" keySplines="0.4 0 0.2 1; 0.4 0 0.2 1" dur="10s" repeatCount="indefinite"/></feColorMatrix></filter></defs><g filter="url(#prefix__a)"><path fill="hsl(0,0%,100%)" d="M-.5-.5h1v1h-1z"/><path fill="url(#prefix__b)" d="M-.25-.25h.5v.5h-.5z"/><circle r=".4" fill="transparent"><animateTransform attributeName="transform" repeatCount="indefinite"/></circle></g></svg>'
      )
    );
    return svgURL;
  }

  function tokenURI(uint256) public pure override returns (string memory) {
    string memory svg = generateSVG();
    string memory imageURI = svgToImageURI(svg);
    return formatTokenURI(imageURI);
  }

  function svgToImageURI(string memory svg) public pure returns (string memory) {
    string memory baseURL = 'data:image/svg+xml;base64,';
    string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
    string memory imageURI = string(abi.encodePacked(baseURL, svgBase64Encoded));
    return imageURI;
  }

  function formatTokenURI(string memory imageURI) public pure returns (string memory) {
    string memory baseURL = 'data:application/json;base64,';

    return string(abi.encodePacked(baseURL, Base64.encode(bytes(abi.encodePacked('{"name": "name",', ' "description": "TEST-V1",', ' "attributes": "",', ' "image": "', imageURI, '"}')))));
  }

  function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return '0';
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }
}
