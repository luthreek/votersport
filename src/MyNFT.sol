pragma solidity ^0.8.0;

contract MyNFT is ERC721, Ownable {
    constructor() ERC721("MyNFT", "MNFT") {}

    // Функция для множественного создания NFT
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }
}
