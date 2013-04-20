package acl.nme;

import acl.nme.Defs;
import acl.nme.U;
import acl.Event;
import scuts.core.Option;
using scuts.core.Options;
using scuts.core.Arrays;
import scuts.core.Pair;

/**
 * ...
 * @author ritchie
 */
class Sound {

	public static function getMp3(name:String,dir:String):TSound {
		return get(name+".mp3",dir);
	}

	public static function get(name:String,dir:String):TSound {
		var name = name.toLowerCase();
	 	return TAssets.getSound(dir +"/"+name);
	}
	
	public static var mapFromDir:String->Array<String>->Map<String,TSound> = U.memoize(memSounds);
	
	static dynamic function memSounds(assetDir:String,keys:Array<String>) {
		var sounds = new Map();
		keys.map(function(k) {
			sounds.set(k,getMp3(k,assetDir));
		});
		return sounds;
	}
	
	public static function chain(sounds:Array<Pair<String,Option<TSound>>>,?ev:Event<String>):TPromise<Bool> {
		var prm = new TPromise<Bool>();
		function playFirst() {
			if (sounds.length > 0) {
				var sndPair = sounds.shift();
				switch(sndPair._2) {
					case Some(snd):
						snd.play().addEventListener(TEvent.SOUND_COMPLETE,function(e) {
							if (ev != null) ev.inform(sndPair._1);
							playFirst();
						});
					case None:
						trace("don't have a sound for "+sndPair._1);
				}
			} else
				prm.complete(true);
		}
		playFirst();
		return prm;
	}

}
