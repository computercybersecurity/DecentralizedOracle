export default {
    "type": "price",
    "contractAddr": "0x198C317Ff58882456fFB40dD41A07AdEDA2346bb",
    "queries": [
        {
            "url": "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2",
            "method": "POST",
            "body": "{\"query\":\"{\n pair(id: \"0x856e90282961c0e7f6693fd2f62b35d5df9783cf\"){\n token1Price\n }\n}\"}",
            "attributes": [
                {
                    "type": "object",
                    "object": "data"
                },
                {
                    "type": "object",
                    "object": "pair"
                },
                {
                    "type": "object",
                    "object": "token1Price"
                }
            ]
        }
    ]
}
