package acl;

/**
 * Top level ui definitions for OpenFlash
 * @author ritchie
 */

typedef TMouseEvent = flash.events.MouseEvent;
typedef TAssets = openfl.Assets;
typedef TFont =  flash.text.Font;
typedef TFormat = flash.text.TextFormat;
typedef TFEvent = flash.events.Event;
typedef TField = flash.text.TextField;
typedef TDisplayObj = flash.display.DisplayObject;
typedef TSprite = flash.display.Sprite;
typedef TBitmap = flash.display.Bitmap;
typedef TBitmapData = flash.display.BitmapData;
typedef TSound = flash.media.Sound;
typedef TGraphics = flash.display.Graphics;
typedef TDim = {width:Int,height:Int};
typedef TText = TSprite;


class Ui {
	public static function inf(s:TSprite) {
		trace('${s.name} -> dims (${s.x},${s.y},${s.width},${s.height}) - scale (${s.scaleX},${s.scaleY})');
	}	
	
	public static function removeChildren(s:TSprite) {
		while (s.numChildren > 0) {
			s.removeChildAt(0);
		}
	}
	
	public static function memoize(func:Dynamic , hash_size:Int = 100) : Dynamic {
    	var arg_hash = new Map<String,Dynamic>();
    	var f =  function(args:Array<Dynamic>){
	        var arg_string = args.join('|');
	        if (arg_hash.exists(arg_string)) return arg_hash.get(arg_string);
	        else{
	            var ret = Reflect.callMethod({},func,args);
	            if(Lambda.count(arg_hash) < hash_size) arg_hash.set(arg_string, ret);
	            return ret;
	        }
	    }
	    f = Reflect.makeVarArgs(f);
    	return f;
	}
	

}
