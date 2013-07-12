package acl;

using scuts.core.Arrays;
/**
 * ...
 * @author ritchie
 */
class Event<T> {
	
	static var CLEANUP = 1;

	var _unsubscribes:Int;
	var _observers:Array<{handler:T->Void,info:Dynamic}>;

	public function new() {
		_observers = [];
		_unsubscribes = 0;
	}

	public function emit(v:T) {
		for (ob in _observers) {
			if (ob.handler != null) {
		    	ob.handler(v);
		    }
		}
	}

  	public function on(cb:T->Void,?info:Dynamic):Void->Void {
  		var  h = {handler:cb,info:info};
		_observers.push(h);

		return function() {
			if (h.handler != null) { // check we don't call this twice
			    h.handler = null;
			    _unsubscribes++;
			    if (_unsubscribes >= CLEANUP) {
			      cleanup();
			    }
			  }
			}
	}
	
    function cleanup() {
	    trace("cleaning up");
    	_unsubscribes = 0;
    	_observers = _observers.filter(function(s) {
          if (s.handler == null)
            trace("filtering "+s.info);
          return s.handler != null;
      	});
  	}
  
	public function peers():Array<Dynamic> {
		return _observers
		  .filter(function(el) return el.handler != null)
		  .map(function(el) return el.info);
	}

	public function removePeers() {
		_observers.each(function(s) {
		    s.handler = null;
		    s.info = null;
		  });
		_observers = [];
	}
  

}

