# Chainlink Hackathon OptWiz

## To do
### SmartContract 
- ERC20, ERC721, ERC1155, ERC777 compatible
- There exist 2-party in option contracts buyer and seller
- Option seller should provide %100 of the colleteral and set interval for the offer, set the maturity date for the option and size of the option(ex. 1.5 eth, 200 Algo). Option seller will be denoted as initiator.
- Participant can participate to initiators option contract if only if offer is still available and by paying the premium participator participates.
- Option contract are not obligatory for participant but obligatory for the option seller. Because option seller commits to perform the actions it promises and to ensure that control of the underlying asset must be given to our smart contract
- Initiator can withdraw the asset he locked during offer period if no participator participates during the interval. In case of any participator participates initiators option will be locked until expiry or when option get exercised
- If options expires out of money, initiator can withdraw the asset
- If option get exercised by the participant, participant must provide enough asset to exercise the option. For example if participant buys a call option contract with size of 3 eth and strike price of $3000 with maturity of 1 month. If option get exercised participant must provide $9000 in order to exercise the option in this case participant receives 3 eth and initiator receives $9000 and premium paid for the option
- If option expires worthless, initiator receives the premium and 3 eth it locked before

## Front-end
- Create option page with params(underyling asset, counter asset, maturity,  premium price, strike price)
- Participate in option screen, where users see the unfilled options and participates it
- Secondary market for options, only option buyer can sell its position
- My Options screen with status filter
- Option details page (profitability chart might be provided)

## Further details will be discussed
