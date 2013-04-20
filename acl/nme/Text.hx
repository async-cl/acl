package acl.nme;

import acl.nme.Defs;
import acl.nme.Fonts;
using scuts.core.Strings;
using scuts.core.Arrays;

/**
 * ...
 * @author ritchie
 */
class Text {

 public static function createFields(text:String,?format:TFormat):Array<TField> {
	var a = [];
	for (i in 0 ... text.length) {
		var c  = text.charAt(i);
		var tf = new TField();
		tf.defaultTextFormat = (format == null) ? Fonts.letters : format;
		tf.selectable = false;
		tf.embedFonts = true;
		tf.text = c;
		tf.height = tf.textHeight+2;
		tf.width = tf.textWidth+2;
	
		a.push(tf);
	}
 	return a;
  }
  
  public static function width(flds:Array<TField>) {
	  return flds.foldLeft(0.0,function(a,f) {
		  a += f.textWidth;
		  return a;
	  });
  }
  
  public static function position(tfs:Array<TField>,s:TSprite) {
	  var x = 0.0;
	  tfs.each(function(f) {
		  s.addChild(f);
		  f.x = x;
		  f.y = 0;
		  x += f.textWidth;
	  });
	  return x;
  }
	
	public static function simple(t:String):TText {
		var tfs = createFields(t,Fonts.bigLetters);
		var w = width(tfs);
		var s = Spr.create(w,20);
		var p = position(tfs,s);
		return s;
	}
	
	public static function create(text:String,?format:TFormat):TField {
		var tf = new TField();
		tf.defaultTextFormat = (format == null) ? Fonts.letters : format;
		tf.selectable = false;
		tf.embedFonts = true;
		tf.text = text;
	 	return tf;
	 }
  
	
}
