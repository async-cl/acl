

package acl.njs.sys;

import scuts.core.Validation;

using acl.Core;
import acl.njs.Sys;

import acl.Event;

import js.Node;

class ChildProcessImpl extends Event<SysChildProcessEvents> implements SysChildProcess  {
  
  public var stdin(get_stdin,null):SysWriteStream;
  public var stdout(get_stdout,null):SysReadStream;
  public var stderr(get_stderr,null):SysReadStream;
  public var pid(get_pid,null):Int;
  
  var _childProc:NodeChildProcess;
  var _stdin:SysWriteStream;
  var _stdout:SysReadStream;
  var _stderr:SysReadStream;
  
  
  public function new(cp:NodeChildProcess) {
    super();
    _childProc = cp;
    _stdin = new WriteStreamImpl(cp.stdin);
    _stdout = new ReadStreamImpl(cp.stdout);
    _stderr = new ReadStreamImpl(cp.stderr);

    _childProc.addListener(NodeC.EVENT_PROCESS_EXIT,function(code,sig) {
        emit(Exit(code,sig));
      });

  }
  
  function get_stdin() {
    return _stdin;
  }

  function get_stdout() {
    return _stdout;
  }

  function get_stderr() {
    return _stderr;
  }

  function get_pid() {
    return _childProc.pid;
  }
   
  public function kill(signal:String) {
    // _childProc.kill(signal);
  }

  public static function spawn(command: String,args: Array<String>,?options: Dynamic ) : TOutcome<String,SysChildProcess> {
    var oc = Core.outcome();
    var forTyper:SysChildProcess = new ChildProcessImpl(Node.childProcess.spawn(command,args,options));
    oc.complete(Success(forTyper));
    return oc;
  }

  public static function exec(command: String,?options:Dynamic,?cb: SysChildProcess->Void):TOutcome<SysChildExit,String> {
    var
      oc = Core.outcome(),
      child = Node.childProcess.exec(command,options,function(err,so,se) {
        if (err != null) {
              oc.complete((Failure({code:err.code,stderr:new String(se)})));
          } else {
              oc.complete(Success(new String(so)));
          }
      });

    if (cb != null)
      cb(new ChildProcessImpl(child));
    
    return oc;
  }


  public static function execFile(command: String,?options:Dynamic,?cb: SysChildProcess->Void):TOutcome<SysChildExit,String> {
    var
      oc = Core.outcome(),
      child = Node.childProcess.execFile(command,options,function(err,so,se) {
          if (err != null) {
              oc.complete(Failure({code:err.code,stderr:new String(se)}));
          } else {
              oc.complete(Success(new String(so)));
          }
      });
    
    if (cb != null)
      cb(new ChildProcessImpl(child));
    
    return oc;
  }

}