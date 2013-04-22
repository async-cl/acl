
package tests;

using acl.Core;
using acl.njs.RHash;
import acl.njs.Mocha;
using scuts.core.Option;
using scuts.core.Options;

typedef Person = {
	first:String,
	last:String
}

class TestRedis {

	public static function main() {
		RHash.init();
		
		var h:TRHash<Person> = RHash.create("peeps");
		
		Core.chain()
		.link(function(d) {
			return h.set("blah",{first:"ritchie",last:"turner"});
		}).link(function(reply) {
			return h.get("blah");
		}).tap(function(person:Option<Person>,d) {
			trace(d);
			trace('finally first name is ${person.orNull().first}');
		}).link(function(person) {
			return h.exists("blah");
		}).link(function(exists) {
			if (exists) {
				trace("exists removing");
				return h.remove("blah");
			} else
				return Core.success(0);
		}).value(function(nremoved) {
			trace("removed "+nremoved);
			
		});
	}
}