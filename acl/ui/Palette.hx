package acl.ui;

using scuts.core.Arrays;
using scuts.core.Iterables;
import scuts.core.Pair;
import scuts.core.Option;
using scuts.core.Options;
using scuts.core.Hashs;

using acl.Core;
using acl.Ui;
using acl.ui.Grid;
using acl.ui.Spr;
using acl.ui.Palette;


typedef TPaletteAttr = {
	parent:TSprite,
	cols:Int,
	rows:Int,
	size:TDim,
	keys:Array<String>,
	bg:Int,
	sounds:Map<String,TSound>
}

typedef TPalette = {
	_grid:TGrid,
	_keys:Array<String>,
	_notifier:Event<Dynamic>,
	_sprites:Option<Map<String,TSprite>>,
	_sounds:Option<Map<String,TSound>>
};

/*
 * ...
 * @author ritchie
 */
class Palette {

	public static function create(attrs:TPaletteAttr):TPalette {
		return positionSprites({
			 _grid:Grid.create(attrs.parent,{
					rows:attrs.rows,
					cols:attrs.cols,
					cellWidth:Math.floor(attrs.size.width / attrs.cols),
					cellHeight:Math.floor(attrs.size.height / attrs.rows),
					background:attrs.bg,
					})
				.draw(),
			_keys:attrs.keys,
			_notifier: new Event<Dynamic>(),
			_sprites:None,
			_sounds: if (attrs.sounds != null) Some(attrs.sounds) else None
		});
	}
	
	public static function setSprites(palette:TPalette,fn:TPalette->Map<String,TSprite>) {
		palette._sprites = Some(fn(palette));
		positionSprites(palette);
		return palette;
	}
	
	public static inline function container(palette:TPalette) {
		return palette._grid.sprite;
	}
	
	static function positionSprites(palette:TPalette):TPalette {
		var sprites = palette._sprites.orNull();
		if (sprites != null) {
			palette._grid.iterate(function(g,c,r,i) {
				var key = palette._keys[i];
				var sprite = sprites.get(key);
	   			sprite.name = key;
			   	palette._grid.setCellSprite(c,r,sprite);
			   	
			});
		}
		return palette;
	}
	
	public static function move(palette:TPalette,x:Int,y:Int):TPalette {
		palette._grid.move(x,y);
		return palette;
	}
	
	public static inline  function grid(palette:TPalette):TGrid {
		return palette._grid;
	}

	public static inline function dimensions(palette:TPalette):TDim {
		return grid(palette).dimensions();
	}
	
	public static inline function cellDimensions(palette:TPalette):TDim {
  		return grid(palette).cellDimensions();
  	}
	
	public static function observe(palette:TPalette,fn:TSprite->Void,?info:Dynamic):TPalette {
		palette._notifier.on(fn,info);
		return palette;
	}
	
	public static function notify(palette:TPalette,prm:TSprite):TPalette {
		palette._notifier.emit(prm);
		return palette;
	}
	
	public static inline function sprites(palette:TPalette):Option<Map<String,TSprite>> {
		return palette._sprites;
	}
	
	public static inline  function sounds(palette:TPalette):Option<Map<String,TSound>> {
		return palette._sounds;
	}
		
	public static function hitTest(palette:TPalette,s:TSprite):TOption<TSprite> {
		return Spr.children(palette._grid.sprite).filterToArray(function(c) {
			return c.getBounds(s.stage).containsRect(s.getBounds(s.stage));
		}).firstOption();
	}
	
	public static function eachSprite(palette:TPalette,fn:TPalette->String->TSprite->Void):TPalette {
		palette._sprites.each(function(spriteMap) {
			spriteMap.toArray().each(function(tup) {
				fn(palette,tup._1,tup._2);
			});
		});
		return palette;
	}
	
	public static function eachSound(palette:TPalette,fn:String->TSound->Void):TPalette {
		palette._sounds.each(function(soundMap) {
			soundMap.toArray().each(function(tup) {
				fn(tup._1,tup._2);
			});
		});
		return palette;
	}
	
	public static function sound(palette:TPalette,key:String):Option<TSound> {
		return switch(palette.sounds()) {
			case Some(sounds):
				sounds.getOption(key);
			case None:
				None;
		}
	}
	
	public static function sprite(palette:TPalette,key:String):Option<TSprite> {
		return switch(palette.sprites()) {
			case Some(sprites):
				sprites.getOption(key);
			case None:
				None;
		}
	}
}
