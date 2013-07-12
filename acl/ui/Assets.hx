package acl.ui;

usingQ acl.Ui



/**
 * ...
 * @author ritchie
 */
class Assets {
  public static function imageSprite(res:TResource):TSprite {
    var
      s = new TSprite(),
      b = new TBitmap (TAssets.getBitmapData("images/"+res.header.im));

    s.addChild(b);
    s.x = res.header.x;
    s.y = res.header.y;
    return s;
  }
	
}
