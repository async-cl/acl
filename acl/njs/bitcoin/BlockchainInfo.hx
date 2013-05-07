package acl.njs.bitcoin;


using acl.Core;
import acl.Http;


/**
 * ...
 * @author Ritchie Turner
 */
 
 typedef TBtcValues = {
	last:Float,
	buy:Float,
	sell:Float,
	symbol:String
 }
 
 typedef TBtcTicker = {
 	USD : TBtcValues,
 	CNY : TBtcValues,
  	JPY : TBtcValues,
    SGD : TBtcValues,
    HKD : TBtcValues,
    CAD : TBtcValues,
    AUD : TBtcValues,
    NZD : TBtcValues,
    GBP : TBtcValues,
    DKK : TBtcValues,
    SEK : TBtcValues,
    BRL : TBtcValues,
    CHF : TBtcValues,
    EUR : TBtcValues,
    RUB : TBtcValues,
    SLL : TBtcValues
 };
 
 enum ECurrency {
 	USD ;
 	CNY ;
  	JPY ;
    SGD ;
    HKD ;
    CAD ;
    AUD ;
    NZD ;
    GBP ;
    DKK ;
    SEK ;
    BRL ;
    CHF ;
    EUR ;
    RUB ;
    SLL ;
 }
 
 
class BlockchainInfo {
	
	public static function toBtc(currencyCode:ECurrency,value:Float):TOutcome<String,Float> {
		return Http.get("http://blockchain.info/tobtc",{currency:Type.enumConstructor(currencyCode),value:value}).fmap(function(value) {
			return Core.success(Std.parseFloat(value));
		});
	}
	
	public static function ticker():TOutcome<String,TBtcTicker> {
		return Http.get("http://blockchain.info/ticker").fmap(function(raw) {
			return Core.success(haxe.Json.parse(raw));
		});
	}

}
