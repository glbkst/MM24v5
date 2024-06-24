# MM24v5
A flexible ERC721 EVM NFT contract, based on the OpenZeppelin ERC721 contract ( v5 )

While it could use 1 tokenURI for each token id, this isn't the intention and it would be inefficient.
The intention is to have 1 or a few tokenURIs for all tokenIds.  Or update later tokens to use new metadata.

Example:

1) init with initial uri  or setUri

2) Token 1 - n are minted with the uri from 1)

3) setUri again, new uri

4) Token n+1 - m  use the new uri

5) (optional) update tokens from 1) or all



