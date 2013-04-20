package acl.nme;

import acl.nme.Defs;
/**
 * ...
 * @author ritchie
 */
class Fonts {
	
  public static var letters:TFormat;
  public static var bigLetters:TFormat;
  
  public static function init() {
    var font = TAssets.getFont ("fonts/VeraSe.ttf");
    letters = new TFormat(font.fontName, 16, 0x000000);
    bigLetters = new TFormat(font.fontName, 48, 0x000000);
  }
  
 
}
