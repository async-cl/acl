package acl.ui;

/**
 * ...
 * @author ritchie
 */

using acl.Ui;
import acl.ui.Fonts;
using acl.ui.Grid;
using acl.ui.Spr;
using acl.ui.Palette;
using acl.ui.Text;

typedef TWordPanelAttr = {
	width:Float,
	height:Float,
	bg:Int,
	parent:TSprite
};
     
enum TWordPanelEvent {
	Append(s:TText);
}

typedef TWordPanel = { > TWordPanelAttr,
	sprite:TSprite,
	curX:Float,
	curY:Float,
	line:Int, 
	event:Event<TWordPanelEvent>
};

class WordPanel {
	
	public static function create(attrs:TWordPanelAttr):TWordPanel {
		var s = Spr.create(attrs.width,attrs.height);
		attrs.parent.addChild(s);
		
		Spr.bg(s,attrs.bg);
		
		s.width = attrs.width;
		s.height = attrs.height;
		
		return {
			parent:attrs.parent,
			sprite:s,
			curX:0,
			curY:0,
			line:0,
			width:attrs.width,
			height:attrs.height,
			bg:attrs.bg,
			event:new Event()
		};
	}
	
	public static function move(wp:TWordPanel,x:Float,y:Float):TWordPanel {
		wp.sprite.x = x;
		wp.sprite.y = y;
		return wp;
	}
	
	public static function clear(wp:TWordPanel) {
		Ui.removeChildren(wp.sprite);
		wp.curX = 0;
		wp.curY = 0;
		wp.line = 0;
	}
	
	public static function append(wp:TWordPanel,t:String):TWordPanel {
		var text = Text.simple(t);
	//	text.bg(0xff0000);
		if (wp.curX + text.width > wp.width) {
			wp.line++;
			wp.curX = 0;
			wp.curY = wp.line*text.height + 3;
		}
		
		wp.sprite.addChild(text);
		wp.event.emit(Append(text));
		text.x = wp.curX;
		text.y = wp.curY;
		wp.curX += text.width +12;
		return wp;
	}

}
