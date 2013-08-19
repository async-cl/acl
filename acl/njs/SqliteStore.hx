
package acl.njs;

import acl.externs.Sqlite3;
import js.Node;

using acl.Core;

typedef Indexer<T> = T->Dynamic;

typedef TSqliteStore = {
    var _db:Sqlite3Db;
}

typedef TSqliteBucket = {
    var _store:TSqliteStore;
    var _table:String;
    var _indexers:haxe.ds.StringMap<Indexer<Dynamic>>;
    var _serializer:Serializer;
}


@:expose
class SqliteStore {

    static var uuid:Dynamic = Node.require("uuid");

    public static function create(path:String):TOutcome<String,TSqliteStore> {
        Sqlite3.init();
        
        var store = {
            _db:null
        };
        
        return Core.success({_db:new Sqlite3Db(path)});
    }

    public static function
    bucket(store:TSqliteStore,bucket:String,?serializer:Serializer):TOutcome<String,TSqliteBucket> {
        var p = Core.outcome();
        store._db.run('create table if not exists $bucket (_id text,_rev text primary key desc, text,__obj text)',function(err) {
            if (err != null) {
                p.complete(Failure("can't create bucket:"+bucket+"->"+err));
                return;
            }
                
            p.complete(Success({
                _store:store,
                _table:bucket,
                _indexers:new haxe.ds.StringMap(),
                _serializer: if (serializer == null) Core.jsonSerializer() else serializer
            }));
        });
        return p;
    }

    public static function
    indexer(b:TSqliteBucket,name:String,indexer:Indexer<Dynamic>,typeHint="text",unique=false):TOutcome<String,Bool> {
        var prm = Core.outcome();
        b._indexers.set(name,indexer);
        addField(b,name,typeHint).onComplete(function(fieldAdded) {
            switch(fieldAdded) {
            case Failure(msg):
                if (msg.indexOf("duplicate column") == -1) {
                    throw msg;
                }
                prm.complete(Success(true));
            case Success(_):
                addPhysicalIndex(b,name,unique).onComplete(function(added) {
                    switch(added) {
                    case Failure(msg):
                        prm.complete(Failure(msg));
                    case Success(_):
                        prm.complete(Success(true));
                    }
                    return true;
                });
            }
            return true;
        });
        return prm;
    }

    static function
    addField(b:TSqliteBucket,name:String,typeHint:String):TOutcome<String,Bool> {
        var prm = Core.outcome();
        b._store._db.exec("alter table "+b._table+" add "+name+" "+typeHint,function(err) {
            prm.complete((err != null) ? Failure(new String(err)) : Success(true));
        });
        return prm;
    }
    
    
    static function
    addPhysicalIndex(b:TSqliteBucket,name:String,unique:Bool):TOutcome<String,Bool> {
        var
        prm = Core.outcome(),
        createIndex = "create "+ ((unique) ? "unique" : "") + " index if not exists ",
        indexName = "i_"+b._table+"_"+name;
        
        b._store._db.run(createIndex+indexName +" on "+b._table+" ("+name+")",function(err) {
            prm.complete((err != null) ? Failure(new String(err)) : Success(true));
        });
        return prm;
  }

    static function handleRev(o:Dynamic) {
        var rev = Reflect.field(o,"_rev");
        if (rev == null) {
            Reflect.setField(o,"_rev","1-"+uuid.v1());
        } else {
            var spl = rev.split("-");
            Reflect.setField(o,"_rev",Std.string((Std.parseInt(spl[0]) + 1)) +"-"+ uuid.v1());
        }
    }
    
    //var rowId = untyped __js__("this.lastID");
    public static function insert<T>(b:TSqliteBucket,o:T,?id:String):TOutcome<String,T> {
        var
        p = Core.outcome();

        if (!Reflect.hasField(o,"_id"))
            Reflect.setField(o,"_id",uuid.v4());
        
        handleRev(o);
        
        var indexVals = indexInsert(b,o);
        trace("inserting "+indexVals);
        
        b._store._db.run('insert into '+b._table+indexVals,b._serializer.serialize(o),function(err) {
            if (err != null) {
                p.complete(Failure(err));
                return;
            }
            
            p.complete(Success(o));
            
        });
        return p;
    }

    public static function
    get<T>(b:TSqliteBucket,id:String):TOutcome<String,T> {
        var p = Core.outcome();
        var sql = 'select __obj from '+b._table+' where _id="${id}" order by _rev desc limit 1'; 
        b._store._db.get(sql,function(err,row) {

            if (err != null) {
                p.complete(Failure(new String(err)));
                return;
            }

            var o:T = b._serializer.deSerialize(new String(row.__obj));
            p.complete(Success(o));
        });
        
        return p;
    }

    static function indexInsert<T>(b:TSqliteBucket,o:T):String {
        var values = [], keys = [];
        var id = Reflect.field(o,"_id");
        var rev = Reflect.field(o,"_rev");
        
        for (k in b._indexers.keys()) {
            var indexVal = b._indexers.get(k)(o);
            if (indexVal != null)  {
                if (Std.is(indexVal,"Float"))
                    values.push(indexVal);
                else
                    values.push("'"+indexVal+"'");
                keys.push(k);
            }
        }

        return if (keys.length == 0) '(_id,_rev,__obj) values ("${id}","${rev}",?)'
            else '(_id,_rev, __obj,' + keys.join(",") + ') values ("${id}","${rev}",?,'+values.join(",") + ")";
    }

}

/*
class SqliteBucket {  
    var _table:String;
    var _indexers:Hash<Indexer<T>>;
    var _serialize:Dynamic->String;
    var _deserialize:String->Dynamic;
  
    public function (file:String) {
        _table = table;
        _indexers = new Hash() ;
        
        if (serialize == null) 
            serialize = Core.jsonSerializer();
        
        _serialize = serialize.serialize;
        _deserialize= serialize.deSerialize;
    }

  
  
  public function index():TOutcome<String,Bool> {
    var prm = Core.outcome();
    _db.serialize(function() {
        var sql = 'select rowid,__obj from '+_table;
        
        _db.each(sql,[],function(err,row) {
            if (err != null) {
              prm.complete(Failure(new String(err)));
              return;
            }

            var o:T = _deserialize(new String(row.__obj));

            reindexObj(o,row.rowid,function(b) {
                trace("indexed:"+row.rowid);
              });
          },function() {
            prm.complete(Success(true));
          });
      });

    return prm;
  }
                 
  function indexSingle(name:String,p:TOutcome<String,String>) {
    _db.serialize(function() {
        var
          sql = 'select rowid,__obj from '+_table +' where '+name+' is null',
          indexer = _indexers.get(name);
        
        _db.each(sql,[],function(err,row) {
            if (err != null) {
              trace("error creatig index:"+err);
              p.complete(Failure(new String(err)));
              return;
            }
            
            var
              o:T = _deserialize(new String(row.__obj)),
              indexVal = indexer(o),
              update = "update "+_table+" set "+name+" = '"+ indexVal+"' where rowid="+row.rowid;
            
            if (indexVal != null) {
              _db.exec(update,function(err) {
                  if (err != null) {
                    trace("update err:"+err);
                    p.complete(Failure(new String(err)));
                  }
                });
            }                    
          },function() {
            p.complete(Success(name));
          });
      });
  }
  
  public function update(o:T):TOutcome<String,T> {
    var
      rowId = Data.oid(o);

    if (rowId == null)
      throw "can't update an object with no oid";

    var
      p = Core.outcome(),
      indexVals = indexUpdate(o),
      obj = _serialize(o),
      sql = "update "+_table+" set __obj = '" + obj + "'"+indexVals+" where rowID="+rowId;

    _db.run(sql,function(err) {
        if (err != null) {
          p.complete(Failure(new String(err)));
          return;
        }
        p.complete(Success(o));
      });
    return p;
  }
  
  function indexUpdate(o:T):String {
    var clause = [];
    for (k in _indexers.keys()) {
      var indexVal = _indexers.get(k)(o);
      if (indexVal != null)
        clause.push(k + "=" +"'"+indexVal+"'");
    }
    return if (clause.length  == 0) ""  else  "," + clause.join(",");
  }

  public function insert(o:T):TOutcome<String,T> {
    var
      p = Core.outcome(),
      indexVals = indexInsert(o);

    _db.run('insert into '+_table+indexVals,_serialize(o),function(err) {
        if (err != null) {
          p.complete(Failure(err));
          return;
        }

        var rowId = untyped __js__("this.lastID");
        Reflect.setField(o,"__oid",rowId);
        p.complete(Success(o));
        
      });
    return p;
  }

  function indexInsert(o:T):String {
    var values = [], keys = [];
    for (k in _indexers.keys()) {
      var indexVal = _indexers.get(k)(o);
      if (indexVal != null)  {
        if (Std.is(indexVal,"Float"))
          values.push(indexVal);
        else
            values.push("'"+indexVal+"'");
        keys.push(k);
      }
    }

    return if (keys.length == 0) "(__obj) values (?)"
      else "( __obj," + keys.join(",") + ") values (?,"+values.join(",") + ")";
  }

  public function delete(o:T):TOutcome<String,T> {
    var prm:TOutcome<String,T> = Core.outcome();
    deleteByOid(Data.oid(o)).deliver(function(e:Either<String,Int>) {
        switch(e) {
        case Success(i):
          prm.complete(Success(o));
        case Failure(err):
          prm.complete(Failure(err));
        }
      });
    return prm;
  }
  
  public function getByOid(id:Int):TOutcome<String,T> {
    var p = Core.outcome();
 select * from people where _id = "b6f63c9e-b037-4dbf-8ebe-a9365a1998c4" order by _rev desc limit 1;

    _db.get('select __obj from '+_table+' where rowid='+id,function(err,row) {

        if (err != null) {
          p.complete(Failure(new String(err)));
          return;
        }

        var o:T = _deserialize(new String(row.__obj));
        Reflect.setField(o,"__oid",id);
        p.complete(Success(o));
      });
    
    return p;
  }

  
  public function deleteByOid(oid:Int):TOutcome<String,Int> {
    var p = Core.outcome();
     if (oid != null) {
      _db.run("delete from "+_table+' where rowid='+oid,function(err) {
          p.complete((err != null) ? Failure(new String(err)) : Success(oid));
        });
    }
    return p;
  }

  function reindexObj(o:T,rowId:Int,cb:Bool->Void) {
    var clause = [];
    for (k in _indexers.keys()) {
      var indexVal = _indexers.get(k)(o);
      if (indexVal != null)
        clause.push(k + "=" +"'"+indexVal+"'");
    }

    if (clause.length > 0) {
      var sql = "update "+_table+" set "+clause.join(",")+" where rowid="+rowId; 
      _db.exec(sql,function(err) {
          if (err != null) {
            trace("update err:"+err);
          trace(sql);
          cb(false);
          return;
          }
          cb(true);
        });
    } else
      cb(false);
  } 

  public function where(where:String):TOutcome<String,Array<T>> {
    var
      p = Core.outcome(),
      results = [],
      sql = 'select rowid,__obj from '+_table +' where '+where;
    
    _db.each(sql,[],function(err,row) {
        if (err != null) {
          p.complete(Failure(new String(err)));
          return;
        }

        var o = _deserialize(new String(row.__obj));
        Reflect.setField(o,"__oid",row.rowid);
        results.push(o);
      },function() {
        p.complete(Success(results));
      });
    return p;
  }

  public function find(query:Dynamic):TOutcome<String,Array<T>> {
    var clause = [];
    for (f in Reflect.fields(query)) {
      var val = Reflect.field(query,f);
      clause.push(f+"='"+val+"'");
    }
    trace("clause = "+clause.join(" and "));
    return where(clause.join(" and "));
  }

  public function link(child:BucketValue,parent:T):TOutcome<String,Bool> {
    var
      p = Core.outcome(),
      parentOid = Data.oid(parent),
      linkFld = "__link_"+_table,
      vals = "'"+child.bucket+"'"+","+child.oid+",'"+_table+"',"+parentOid,
      sql = "insert into __links(ch_bkt,ch_oid,p_bkt,p_oid) values("+vals+")";

    if (parentOid == null) throw "parentOid can't be null when linking";
    
    //trace(sql);
    
    _db.run(sql,function(err) {
        if (err != null) {
          p.complete(Failure(new String(err)));
          return;
        }
        p.complete(Success(true));
      });
    return p;
  }

  public function linked<Q>(bucket:Bucket<Q>,val:T):TOutcome<String,Option<Array<Q>>> {
    var
      p = Core.outcome(),
      parentOid = Data.oid(val),
      results = [],
      sql = Std.format("select __obj from ${bucket.name()} where rowid in (select ch_oid from __links where p_oid=$parentOid and p_bkt='$_table');");

    //if (parentOid == null) throw "parentOid can't be null when getting linked";

    trace(sql);
    
    _db.each(sql,[],function(err,row) {
        if (err != null) {
          p.complete(Failure(new String(err)));
          return;
        }
        
        results.push(_deserialize(row.__obj));
      },function() {
          p.complete((results.length > 0) ? Success(Some(results)) : Success(None));
      });
    return p;
  }

  public function unlink(child:BucketValue,parent:T):TOutcome<String,Bool> {
    var
      p = Core.outcome(),
      parentOid = Data.oid(parent),
      sql = "delete from __links where p_oid="+parentOid+" and ch_oid="+child.oid+" and p_pkt='"+_table+"' and ch_bkt='"+child.bucket+"'";

    if (parentOid == null) throw "parentOid can't be null when getting linked";

    _db.run(sql,function(err) {
        if (err != null) {
          p.complete(Failure(new String(err)));
          return;
        }
        
        p.complete(Success(true));
      });

    return p;
  }
                         
  public function name():String {
    return _table;
  }

  public function child(child:Dynamic):BucketValue {
    return {bucket:name(),oid:Data.oid(child)};
  }
  
}

*/