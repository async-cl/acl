package acl.ui;

using acl.Ui;
/**
 * ...
 * @author ritchie
 */
class Fonts {
	
    public static var letters:TFormat;
    public static var bigLetters:TFormat;
    public static var bigger:TFormat; 
    public static var larger:TFormat;
    public static var standard = TAssets.getFont ("fonts/VeraSe.ttf");
    
    public static function init() {
        letters = new TFormat(standard.fontName, 16, 0x000000);
        larger = new TFormat(standard.fontName, 22, 0x000000);
        bigLetters = new TFormat(standard.fontName, 48, 0x000000);
        bigger= new TFormat(standard.fontName, 58, 0x000000);
    }
  
 
}
