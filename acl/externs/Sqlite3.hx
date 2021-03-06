package acl.externs;

typedef Sqlite3Err= String;

class Sqlite3 {

  static var sqlite3:Dynamic;
  
  public static function init() {
      if (sqlite3 == null) {
          trace("initing sqlite extern");
          sqlite3 = js.Node.require('sqlite3');
      }
  }
}

@:native("acl.externs.Sqlite3.sqlite3.Database")
extern class Sqlite3Db  {
  public function new(fileName:String,?mode:Int,?cb:Sqlite3Err->Void):Void;
  public function run(sql:String,?param:Dynamic,?cb:Sqlite3Err->Void):Void;
  public function each(sql:String,?param:Dynamic,?cb:Sqlite3Err->Dynamic->Void,?complete:Void->Void):Void;
  public function get(sql:String,?param:Dynamic,?cb:Sqlite3Err->Void):Void;
  public function exec(sql:String,?param:Dynamic,?cb:Sqlite3Err->Void):Void;
  public function serialize(?cb:Void->Void):Void;
}