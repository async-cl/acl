package acl.nme;

/**
 * ...
 * @author ritchie
 */
 
import acl.nme.Defs;
import scuts.core.Option;
using scuts.core.Options;
using scuts.core.Strings;

class Spr {

	static var spriteNo = 0;

	public static function create(w:Float,h:Float,nameStem='Spr'):TSprite {
		var s = new TSprite();
		s.name = createName(nameStem);
		size(s,w,h);
		s.x = 0;
		s.y = 0;
		return s;
	}

	static function createName(stem:String) {	
		return getStem(stem) + "__" + spriteNo++;
	}
	
	public static function addChild(parent:TSprite,child:TSprite) {
		parent.addChild(child);
	}
	
	public static function bitMap(dir,name):Option<TBitmap> {
		var asset = TAssets.getBitmapData(dir + "/" + name);
      	if (asset == null) {
      	     trace("no bitmap for "+dir+"/"+name);
      		return None;
      	}
      	return Some(new TBitmap(asset));
	}
	
	public static function getStem(s:String):String {
		var r = ~/^(.*)__/;
		if (r.match(s)) 
			return r.matched(1);
		return s;
	}
	
	//public static var bitMap:String->String->Option<TBitmap> = Defs.memoize(memoBitMap);

	public static function bg(s:TSprite,col:Int) {
		var g = s.graphics;
    	g.beginFill(col);
    	g.drawRect(0,0,s.width,s.height);
    	g.endFill();
	}
	
	public static function size(s:TSprite,width:Float,height:Float,?bg:Int) {
		var g = s.graphics;
		
		if (bg != null) {
			g.beginFill(bg);
    	} else {
    		g.beginFill(1,0);
    	}
		
    	g.drawRect(0,0,width,height);
		s.width = width;
		s.height = height;
		
		if (bg != null)
    		g.endFill();
	}
	
	public static function fromUrl(url:String):TPromise<TSprite> {
		var p = new TPromise<TSprite>();
		var r =new nme.net.URLRequest(url);
		var l = new nme.display.Loader();
		l.load(r);
		
		l.contentLoaderInfo.addEventListener(TEvent.COMPLETE,function(r) {
			var s = new TSprite();
			s.addChild(l);
			p.complete(s);
		});
		
		return p;
	}
	
	public static function fromAsset(name,dir):TOption<TSprite> {
		var bm = bitMap(dir,name);
		if (bm.isNone())
			return None;
		
		var b = bm.extract();
		var s = Spr.create(b.width,b.height);
		
      	s.addChild(b);
    	return Some(s);
	}
	
	static dynamic function memSpr(assetDir:String,keys:Array<String>): Map<String,TSprite> {
		trace("memSpr:should only see this one time!");
		var m:Map<String,TSprite> = new Map();
		keys.map(function(k) {
			var o = Spr.fromAsset(k+'.png',assetDir);
			if (o.isSome())	 
				m.set(k,o.extract());
		});
		return m;
	}
	
	public static var mapFromDir:String->Array<String>->Map<String,TSprite> = U.memoize(memSpr);
	
	public static function children(s:TSprite):Iterable<TSprite> {		
		return {
			iterator: function() {
				var nc = s.numChildren,
				i = 0;
				return {
					next: function() {
						return cast s.getChildAt(i++);
					},
					hasNext:function() {
						return i < nc;
					}
				}
			}
		}
	}
	
	public static function childrenByRow(parent:TSprite,nCols=2) {
		var nChild = parent.numChildren;
		if (nChild == 0)
			return ;
			
		var cwidth = if (nChild == 1) parent.width else parent.width / nCols;
		var rheight = if (nChild == 1) parent.height else parent.height / ((nChild / nCols)+1);
		var c = 0;
		var r = 0;
		for (child in children(parent)) {
			child.x = c++ * cwidth;
			child.y = r * rheight;
			child.width = cwidth;
			child.height = rheight;
			if (c > nCols -1) {
				r++;
				c = 0;
			}
		}
	}
	
	public static function toBitmap(sprite:TSprite, smoothing:Bool = false):TBitmap {
		var bitmapData = new nme.display.BitmapData(Math.ceil(sprite.width), Math.ceil(sprite.height), true, 0);
		bitmapData.draw(sprite);
		return new TBitmap(bitmapData, null, smoothing);
	}
	
	
	public static function fromBitmap(bm:TBitmap):Option<TSprite> {
		var s = Spr.create(bm.width,bm.height);
      	s.addChild(bm);
    	return Some(s);
	}
	
	
}
