package acl.njs;

/**
 * ...
 * @author Ritchie Turner
 */
 
using acl.Core;
import js.Node;

class Bitcoin {
	
	static var qr:Dynamic;

	public static function connect(url:String,user:String,password:String) {
		return new acl.njs.bitcoin.BitcoinApi(url,user,password);
	}


	public static function qrCode(address:String):TOutcome<String,Dynamic> {
		var oc = Core.outcome();
		
		if (qr == null) {
			var Encoder = Sys.require("qr").Encoder;
            qr = untyped __js__("new Encoder()");
        }
			
		qr.on('end',function(png) {
			oc.complete(Success(png));	
		});
		qr.on('error',function(err) {
			oc.complete(Failure(err));
		});
		qr.encode(address);
		return oc;
	}
}
