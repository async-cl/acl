
package acl.njs.sys;

import scuts.core.Validation;

using acl.Core;
import acl.njs.Sys;


import js.Node;

class WriteStreamImpl extends acl.Event<SysWriteStreamEvents> implements SysWriteStream {

  var _writeStream:NodeWriteStream;
  
  public function new(s:NodeWriteStream) {
    super();
    _writeStream = s;
    
    _writeStream.addListener(NodeC.EVENT_STREAM_DRAIN,function() {
        inform(Drain);
      });
    _writeStream.addListener(NodeC.EVENT_STREAM_ERROR,function(ex) {
        inform(SysWriteStreamEvents.Error(new String(ex)));
      });
    _writeStream.addListener(NodeC.EVENT_STREAM_CLOSE,function() {
        inform(SysWriteStreamEvents.Close);
      });
    _writeStream.addListener(NodeC.EVENT_STREAM_PIPE,function(src) {
        inform(Pipe(new ReadStreamImpl(src)));
      });
    
  }
  
  public var writeable(get_writeable,null):Bool;

  function get_writeable() {
    return _writeStream.writeable;
  }
  
  public function write(d:String,?enc:String,?fd:Int):Bool {
    return _writeStream.write(d,enc,fd);
  }
  
  public function end(?s:String,?enc:String):Void {
    _writeStream.end(s,enc);
  }

  public function getNodeWriteStream() {
    return _writeStream;
  }

  public static function createWriteStream(path:String,?options:WriteStreamOpt) {
    return new WriteStreamImpl(Node.fs.createWriteStream(path,options));
  }
}

