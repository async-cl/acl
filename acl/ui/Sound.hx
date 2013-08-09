package acl.ui;

import scuts.core.Option;
using scuts.core.Options;
using scuts.core.Arrays;
import scuts.core.Pair;
import haxe.io.Path;
using acl.Core;
using acl.Ui;
import acl.Event;

/**
 * ...
 * @author ritchie
 */
class Sound {

    public static var mute:Bool = true;

	public static function
    getMp3(name:String,dir:String):TSound {
		return get(name+".mp3",dir);
	}

	public static function
    get(name:String,dir:String):TSound {
	 	return TAssets.getSound(dir +"/"+name);
	}
	
	public static var
    mapFromDir:String->Array<String>->Map<String,TSound> = Ui.memoize(memSounds);
	
	static dynamic function
    memSounds(assetDir:String,keys:Array<String>) {
		var sounds = new Map();
		keys.map(function(k) {
			sounds.set(k,getMp3(k,assetDir));
		});
		return sounds;
	}

    public static function play_(sound:TSound):TPromise<Bool> {
        var prm = Core.promise();
        if (sound == null) {
            trace("play: Sound was null!!");
            prm.complete(true);
        }
        if (!mute) {
            sound.play().addEventListener(TFEvent.SOUND_COMPLETE,function(e) {
                prm.complete(true);
            });

        } else
            prm.complete(true);
        return prm;
    }
    
    public static function soundPairs(snds:Array<String>):Array<Pair<String,Option<TSound>>> {
        return snds.map(function(snd) {
            var dir = Path.directory(snd);
            var file = Path.withoutDirectory(snd);
            var key = Path.withoutExtension(file);
            return Pair.create(key,Some(get(file,dir)));
        });
    }
    
	public static function
    chain(sounds:Array<Pair<String,Option<TSound>>>,?ev:Event<String>):TPromise<Bool> {
		var prm = new TPromise<Bool>();
        if (sounds == null) {
            trace("chain: sounds was null!!");
            prm.complete(true);
        }
        if (mute)
            prm.complete(true);
        else {
		    function playFirst() {
			    if (sounds.length > 0) {
				    var sndPair = sounds.shift();
				    switch(sndPair._2) {
					case Some(snd):
						snd.play().addEventListener(TFEvent.SOUND_COMPLETE,function(e) {
							if (ev != null) ev.emit(sndPair._1);
							playFirst();
						});
					case None:
						trace("don't have a sound for "+sndPair._1);
				    
			        }
                } else
				    prm.complete(true);
		    }
		    playFirst();
        }
		return prm;
	}

}
