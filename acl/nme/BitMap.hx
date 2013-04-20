package acl.nme;
import acl.nme.Defs;

import nme.net.URLRequest;
import nme.net.URLLoader;
import nme.net.URLLoaderDataFormat;


//import scuts.Scuts;

/**
 * ...
 * @author ritchie
 */
class BitMap {

		
	public static function loadFrom(url:String,cb:TBitmap->Void) {	
		// define image url	
		var url:URLRequest = new URLRequest(url);

		// create Loader and load url
		var img:URLLoader = new URLLoader();
		
		trace("loading "+url);
		img.dataFormat = URLLoaderDataFormat.BINARY;
		img.load(url);


		// listener for image load complete
		img.addEventListener(TEvent.COMPLETE, function(e:TEvent)	{
		    trace("seem to have got it "+img.bytesLoaded+" type "+img.dataFormat);
		   
		    // remove listener
		    //e.target.removeEventListener(TEvent.COMPLETE, loaded);

			//var bm = new TBitmap(img.data);
			
			//trace("haha got bm"+bm.height);		
			cb(img.data);
		});
	}
}
