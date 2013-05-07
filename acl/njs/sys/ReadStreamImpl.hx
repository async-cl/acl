
package acl.njs.sys;

using acl.Core;
import acl.njs.Sys;

import js.Node;

class ReadStreamImpl extends acl.Event<SysReadStreamEvents> implements SysReadStream {
  
  var _readStream:NodeReadStream;

  public var readable(get_readable,null):Bool;
  
  public function new(rs:NodeReadStream) {
    super();
    _readStream = rs;
    _readStream.addListener(NodeC.EVENT_STREAM_DATA,function(d) {
        emit(Data(new String(d)));
      });
    _readStream.addListener(NodeC.EVENT_STREAM_END,function() {
        emit(End);
      });
    _readStream.addListener(NodeC.EVENT_STREAM_ERROR,function(exception) {
        emit(SysReadStreamEvents.Error(new String(exception)));
      });
    _readStream.addListener(NodeC.EVENT_STREAM_CLOSE,function() {
        emit(SysReadStreamEvents.Close);
      });
  }

  function get_readable() {
    return _readStream.readable;
  }

  public function pause():Void {
    _readStream.pause();
  }
  public function resume():Void {
    _readStream.resume();
  }
  public function destroy():Void {
    _readStream.destroy();
  }
  public function destroySoon():Void {
    _readStream.destroySoon();
  }
  public function setEncoding(enc:String) {
    _readStream.setEncoding(enc);
  }
  public function pipe(dest:SysWriteStream,?opts:{end:Bool}) {
    _readStream.pipe(dest.getNodeWriteStream(),opts);
  }

  public function getNodeReadStream() {
    return _readStream;
  }

  public static function createReadStream(path:String,?options:ReadStreamOpt) {
    return new ReadStreamImpl(Node.fs.createReadStream(path,options));
  }
  
}