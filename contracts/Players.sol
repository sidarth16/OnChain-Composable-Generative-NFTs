// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract Players is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    uint256 constant TOTAL_SUPPLY = 100;

    Counters.Counter private _tokenIdCounter;
    mapping (uint256 => uint256) public combId2Ind;
    uint256[TOTAL_SUPPLY] public combId;

    uint256 public totalMinted;

    string public baseURI ;
    string public imgType ;
    string[] public layerOrder;
    mapping (uint256 => string[]) public layerInfo;


    event Minted(uint256 indexed tokenId, uint256 indexed CombinationId, address indexed MintedTo);

    constructor( ) ERC721("TestPlayers", "PLY"){ //string memory _baseURI
        totalMinted = 0;
        baseURI = "https://ipfs.io/ipfs/QmWpt47XRV9gCHyQsSehcMCnNrNhirYbiT1bJqXFXcMYMq"; //_baseURI;
        layerOrder   = ["Pendant", "EyeWear", "HeadGear", "Jersey", "Background"];
        
        layerInfo[4] = ["Floodlights", "Mars", "Neon", "Stands"];
        layerInfo[3] = ["Bullish", "Ethereum", "Test", "ODI"];
        layerInfo[2] = ["Blue", "Camo", "Mask", "NavyBlue"];
        layerInfo[1] = ["Neon", "Vue", "VR", "ThugLife"];
        layerInfo[0] = ["Emerald", "Pearl", "Bitcoin", "Key"];
        imgType = ".png";
    }

    function updateBaseURI(string memory _baseURI) onlyOwner external{
        baseURI = _baseURI;
    }

    function updateImgType(string memory _imgType) onlyOwner external{
        imgType = _imgType;
    }

    function nftMint(uint256 _combId) public returns (uint){
        require( bytes(_combId.toString()).length >= 2, "CombId error");    
        require(combId2Ind[_combId]==0, "Already Used");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= TOTAL_SUPPLY, "Player's Sold Out !!!" );

        combId2Ind[ _combId ] = tokenId;
        combId[ tokenId ] = _combId;

        string memory attr = getAttributes(tokenId);

        _safeMint(msg.sender, tokenId);
        emit Minted(tokenId, _combId, msg.sender);

        totalMinted+=1;
        return tokenId;
    }



    function generateSVG( uint256 tokenId ) public virtual view returns (string memory finalSvg) {

        uint256 _combId = combId[tokenId] ;
        
        finalSvg = "<svg xmlns='http://www.w3.org/2000/svg' width='750' height='750' > ";
        for (uint256 i=layerOrder.length; i>0; i--){
            string memory layername = layerOrder[i-1];
            if (_combId%10 > 0) {
                uint256 combInd = _combId%10  - 1 ;
                require(combInd < layerInfo[i-1].length, "Error in given combId");
                string memory attrName = layerInfo[i-1][ combInd ];
                
                finalSvg = string(abi.encodePacked(
                    finalSvg,
                    '<image href="', baseURI, "/", layername, "/", attrName, imgType, '" />' ));

            }
            _combId = _combId / 10;
        }    
        finalSvg = string(abi.encodePacked( finalSvg, "</svg>" ));
    }

    function getAttributes(uint256 tokenId) public virtual view returns(string memory attr){
        
        uint256 _combId = combId[tokenId] ;
        attr = "[" ;
        for (uint256 i=layerOrder.length; i>0; i--){
            if (_combId%10 > 0) {
                uint256 combInd = _combId%10  - 1 ;
                require(combInd < layerInfo[i-1].length, "Error in given combId");
                attr = string(abi.encodePacked( 
                            attr,
                            '{"trait_type":"',layerOrder[i-1],'" , "value":"',layerInfo[i-1][ combInd ],'"},'
                        ));
            }
            _combId = _combId / 10;
        }  

        attr =  string(abi.encodePacked(attr,
            '{"trait_type": "level", "value":',Strings.toString((tokenId/10)+1),'}, ',
            '{"display_type": "number","trait_type":"Generation" , "value":1} ],'
        ));
    }

    function generateFinalMetaJson(uint256 tokenId) internal view returns (string memory){
        string memory finalSvg = generateSVG(tokenId);
        string memory nftName = string(abi.encodePacked("Demo Player #", tokenId.toString())) ;

        string memory json = Base64.encode(
            bytes(string(
                    abi.encodePacked(
                        '{"name": "',nftName, '",',
                        ' "description": "Demo Players Collection",',
                        ' "attributes":', getAttributes(tokenId), 
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        // prepend data:application/json;base64, to our data.
        string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", json));
        return finalTokenUri;
    }    
    
    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function burn(uint256 tokenId) external{
        _burn(tokenId) ;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory)
    {
        return generateFinalMetaJson(tokenId);
    }
   

}