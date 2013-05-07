
package acl.njs;

import scuts.core.Validation;

using acl.Core;
import acl.njs.sys.WriteStreamImpl;
import acl.njs.sys.ReadStreamImpl;
import acl.Event;

import js.Node;

typedef SysAssert = NodeAssert;

enum SysEnc {
	ASCII;
	UTF8;
	BINARY;
	BASE64;
}

enum SysEvents {
	ProcessExit;
	ProcessUncaughtException(ex:Dynamic);
	SigInt(s:Int);
}

enum SysWriteStreamEvents {
	Drain;
	Error(e:String);
	Close;
	Pipe(src:SysReadStream);
}

enum SysReadStreamEvents {
	Data(d:String);
	Error(e:String);
	End;
	Close;
	Fd;
}

enum SysChildProcessEvents {
	Exit(code:Int,signal:Int);
}

typedef SysChildExit = {code:Int,stderr:String};

interface SysChildProcess  {
	var stdin(get_stdin,null):SysWriteStream;
	var stdout(get_stdout,null):SysReadStream;
	var stderr(get_stderr,null):SysReadStream;
	var pid(get_pid,null):Int;
	function kill(signal:String):Void;
}

interface SysWriteStream {
	var writeable(get_writeable,null):Bool;
	function write(d:String,?enc:String,?fd:Int):Bool;
	function end(?s:String,?enc:String):Void;
	function getNodeWriteStream():NodeWriteStream;
}

interface SysReadStream {
	var readable(get_readable,null):Bool;
	function pause():Void;
	function resume():Void;
	function destroy():Void;
	function destroySoon():Void;
	function setEncoding(enc:String):Void;
	function pipe(dest:SysWriteStream,?opts:{end:Bool}):Void;
	function getNodeReadStream():NodeReadStream;
}

class Sys {

	static var _events:Event<SysEvents>;
	static var _proc:NodeProcess = Node.process;
	static var _os:NodeOs = Node.os;
	static var _child:NodeChildProcessCommands = Node.childProcess;

	public static var path(get,null):NodePath ;
	public static var dirname(get,null):String ;

	public static var Assert(get,null):NodeAssert;

	public static function captureSystemEvents(fn:SysEvents->Void) {
		if (_events == null) {
			_events = new acl.njs.sys.Events();
			
		    Node.process.addListener(NodeC.EVENT_PROCESS_EXIT,function() {
		        _events.emit(ProcessExit);
		      });

		    Node.process.addListener(NodeC.EVENT_PROCESS_UNCAUGHTEXCEPTION,function(ex) {
		        _events.emit(ProcessUncaughtException(ex));
		    });
		}
		
		_events.on(fn);
	}

	static function get_path() { return Node.path; }
	static function get_dirname():String { return Node.__dirname; }
	static function get_Assert() { return Node.assert; }
	
	public static inline function require(module:String) { return Node.require(module); }
	public static inline function events() { return _events; }
	public static inline function argv() { return _proc.argv; }
	public static inline function env() { return _proc.env; }
	public static inline function pid() { return _proc.pid; }
	public static inline function title() { return _proc.title; }
	public static inline function arch() { return _proc.arch; }
	public static inline function platform() { return _proc.platform; }
	public static inline function installPrefix() { return _proc.installPrefix; }
	public static inline function execPath() { return _proc.execPath; }
	public static inline function version() { return _proc.version; }
	public static inline function versions() { return _proc.versions; }
	public static inline function memoryUsage():{rss:Int,vsize:Int,heapUsed:Int,heapTotal:Int} { return _proc.memoryUsage(); }
	public static inline function nextTick(fn:Void->Void) { _proc.nextTick(fn); }
	public static inline function exit(code:Int) { _proc.exit(code); }
	public static inline function cwd() { return _proc.cwd(); }
	public static inline function getuid():Int { return _proc.getuid(); }
	public static inline function getgid():Int { return _proc.getgid(); }
	public static inline function setuid(u:Int) { _proc.setuid(u); }
	public static inline function setgid(g:Int) { _proc.setgid(g); }
	public static inline function umask(?m:Int):Int { return _proc.umask(m); }
	public static inline function chdir(d:String) { _proc.chdir(d); }
	public static inline function kill(pid:Int,?signal:String) { _proc.kill(pid,signal); }
	public static inline function uptime():Int { return _proc.uptime(); }
	public static inline function hostname():String { return _os.hostname(); }
	public static inline function type():String { return _os.type(); }
	public static inline function release():String { return _os.release(); }
	public static inline function osUptime():Int { return _os.uptime(); }
	public static inline function loadavg():Array<Float> { return _os.loadavg(); }
	public static inline function totalmem():Int { return _os.totalmem(); }
	public static inline function freemem():Int { return _os.freemem(); }
	public static inline function cpus():Int { return _os.cpus(); }
	public static inline function networkInterfaces():Dynamic { return _os.networkInterfaces(); }
	
	public static function genPasswd(val) { 
	    return Node.crypto.createHash('md5').update(val).digest("hex");
	}

	public static inline function stdout():SysWriteStream {
		return new WriteStreamImpl(_proc.stdout);
	}

	public static inline function stdin():SysReadStream {
		return new ReadStreamImpl(_proc.stdin);
	}

	public static inline function stderr():SysWriteStream {
		return new WriteStreamImpl(_proc.stderr);
	}

	public static inline function createWriteStream(path,?opt:WriteStreamOpt):SysWriteStream {
		return WriteStreamImpl.createWriteStream(path,opt);
	}

	public static inline function createReadStream(path,?opt:ReadStreamOpt):SysReadStream {
		return ReadStreamImpl.createReadStream(path,opt);
	}

	public static function spawn(command: String,?args: Array<String>,?options: Dynamic ) : TOutcome<String,SysChildProcess> {
		if (args == null)
	  		args =[];
		return acl.njs.sys.ChildProcessImpl.spawn(command,args,options);
	}

	public static function exec(command: String,?options:Dynamic,?cb:SysChildProcess->Void):TOutcome<SysChildExit,String>{
		return acl.njs.sys.ChildProcessImpl.exec(command,options,cb);
	}

	public static function execFile(command: String,?options:Dynamic,?cb:SysChildProcess->Void):TOutcome<SysChildExit,String> {
		return acl.njs.sys.ChildProcessImpl.execFile(command,options,cb);
	}

	public static function getEnc(enc:SysEnc):String {
		if (enc == null)
		  return NodeC.UTF8;

		return switch(enc) {
			case ASCII: NodeC.ASCII;
			case UTF8: NodeC.UTF8;
			case BINARY:NodeC.BINARY;
			case BASE64: NodeC.BASE64;
		}
	}

	// Async FS calls

	public static function exists(path:String):TOutcome<String,String> {
		var oc = Core.outcome();
		Node.path.exists(path,function(exists) {
		    oc.complete((exists) ? Success(path) : Failure(path));
		  });
		return oc;
	}

	public static function rename(from:String,to:String):TOutcome<String,String> {
		var prm = Core.outcome();
		Node.fs.rename(from,to,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(to));
		  });
		return prm;
	}

	public static function stat(path:String):TOutcome<String,{path:String,stat:NodeStat}>{
		var prm = Core.outcome();
		Node.fs.stat(path,function(err,stat) {
		    prm.complete((err != null) ? Failure(err) : Success({path:path,stat:stat}));
		  });
		return prm;
	}

	public static function lstat(path:String):TOutcome<String,NodeStat>{
		var prm = Core.outcome();
		Node.fs.lstat(path,function(err,stat) {
		    prm.complete((err != null) ? Failure(err) : Success(stat));
		  });
		return prm;
	}

	public static function fstat(fd:Int):TOutcome<String,NodeStat>{
		var prm = Core.outcome();
		  Node.fs.fstat(fd,function(err,stat) {
		    prm.complete((err != null) ? Failure(err) : Success(stat));
		  });  
		return prm;
	}

	public static function link(srcPath:String,dstPath:String):TOutcome<String,String>{
		var prm = Core.outcome();
		Node.fs.link(srcPath,dstPath,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(dstPath));
		  });
		return prm;
	}

	public static function unlink(srcPath:String):TOutcome<String,String>{
		var prm = Core.outcome();
		Node.fs.unlink(srcPath,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(srcPath));
		  });
		return prm;
	}

	public static function symlink(linkData:Dynamic,path:String):TOutcome<String,Dynamic>{
		var prm = Core.outcome();
		Node.fs.symlink(linkData,path,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(true));
		  });
		return prm;
	}

	public static function readlink(path:String):TOutcome<String,String>{
		var prm = Core.outcome();
		Node.fs.readlink(path,function(err,s) {
		    prm.complete((err != null) ? Failure(err) : Success(s));
		  });
		return prm;
	}

	public static function realpath(path:String):TOutcome<String,String>{
		var prm = Core.outcome();
		Node.fs.realpath(path,function(err,s) {
		    prm.complete((err != null) ? Failure(err) : Success(s));
		  });
		return prm;
	}

	public static function chmod(path:String,mode:Int):TOutcome<String,String>{
		var prm = Core.outcome();
		Node.fs.chmod(path,mode,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(path));
		  });
		return prm;
	}

	public static function fchmod(fd:Int,mode:Int):TOutcome<String,Int>{
		var prm = Core.outcome();
		Node.fs.fchmod(fd,mode,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(fd));
		  });  
		return prm;
	}

	public static function chown(path:String,uid:Int,gid:Int):TOutcome<String,String>{
		var prm = Core.outcome();
		Node.fs.chown(path,uid,gid,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(path));
		  });  
		return prm;
	}

	public static function rmdir(path:String):TOutcome<String,String>{
		var prm = Core.outcome();
		Node.fs.rmdir(path,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(path));
		  });  
		return prm;
	}

	public static function mkdir(path:String,?mode:Int):TOutcome<String,String>{
		var prm = Core.outcome();
		Node.fs.mkdir(path,mode,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(path));
		  });  
		return prm;
	}

	public static function readdir(path:String):TOutcome<String,Array<String>>{
		var prm = Core.outcome();
		Node.fs.readdir(path,function(err,fileNames) {
		    prm.complete((err != null) ? Failure(err) : Success(fileNames));
		  });
		return prm;
	}

	public static function close(fd:Int):TOutcome<String,Int>{
		var prm = Core.outcome();
		Node.fs.close(fd,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(fd));
		  });
		return prm;
	}

	public static function open(path:String,flags:String,mode:Int):TOutcome<String,Int>{
		var prm = Core.outcome();
		Node.fs.open(path,flags,mode,function(err,i) {
		    prm.complete((err != null) ? Failure(err) : Success(i));
		  });
		return prm;
	}

	public static function write(fd:Int,bufOrStr:Dynamic,offset:Int,length:Int,position:Null<Int>):TOutcome<String,Int>{
		var prm = Core.outcome();
		Node.fs.write(fd,bufOrStr,offset,length,position,function(err,i) {
		    prm.complete((err != null) ? Failure(err) : Success(i));
		  });
		return prm;
	}

	public static function read(fd:Int,buffer:NodeBuffer,offset:Int,length:Int,position:Int):TOutcome<String,Int>{
		var prm = Core.outcome();
		Node.fs.read(fd,buffer,offset,length,position,function(err,i,nb) {
		    prm.complete((err != null) ? Failure(err) : Success(i));
		  });
		return prm;
	}

	public static function truncate(fd:Int,len:Int):TOutcome<String,Int>{
		var prm = Core.outcome();
		Node.fs.truncate(fd,len,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(len));
		  });
		return prm;
	}


	public static function readFile(path:String,?enc:SysEnc):TOutcome<String,Dynamic>{
		var oc = Core.outcome();
		trace("reading file "+path);
		Node.fs.readFile(path,Sys.getEnc(enc),function(err,s) {
		    oc.complete((err != null) ? Failure(err) : Success(s));
  	    });
		return oc;
	}

	public static function writeFile(fileName:String,contents:String,?enc:SysEnc):TOutcome<String,String>{
		var prm = Core.outcome();
		Node.fs.writeFile(fileName,contents,Sys.getEnc(enc),function(err) {
		      prm.complete((err != null) ? Failure(err) : Success(fileName));
		  });
		return prm;
	}

	public static function utimes(path:String,atime:Dynamic,mtime:Dynamic):TOutcome<String,String>{
		var prm = Core.outcome();
		Node.fs.utimes(path,atime,mtime,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(path));
		  });
		return prm;
	}

	public static function futimes(fd:Int,atime:Dynamic,mtime:Dynamic):TOutcome<String,Int>{
		var prm = Core.outcome();
		Node.fs.futimes(fd,atime,mtime,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(fd));
		  });
		return prm;
	}

	public static function fsync(fd:Int):TOutcome<String,Int>{
		var prm = Core.outcome();
		Node.fs.fsync(fd,function(err) {
		    prm.complete((err != null) ? Failure(err) : Success(fd));
		  });
		return prm;
	}

	public static function watchFile(fileName:String,?options:NodeWatchOpt,listener:NodeStat->NodeStat->Void){
		Node.fs.watchFile(fileName,options,listener);
	}

	public static function unwatchFile(fileName:String){
		Node.fs.unwatchFile(fileName);
	}

	public static function watch(fileName:String,?options:NodeWatchOpt,listener:String->String->Void):TOutcome<String,NodeFSWatcher>{
		var prm = Core.outcome();
		try {
		  var w = Node.fs.watch(fileName,options,listener);
		  prm.complete((w == null) ? Failure("can't create readStream") : Success(w));
		} catch(ex:Dynamic) {
		  prm.complete(Failure(ex));
		}
		return prm;
	}

	public static function nodeReadStream(path:String,?options:ReadStreamOpt):TOutcome<String,NodeReadStream>{
		var prm = Core.outcome();
		try {
		  var rs = Node.fs.createReadStream(path,options);
		  prm.complete((rs == null) ? Failure("can't create readStream") : Success(rs));
		} catch(ex:Dynamic) {
		  prm.complete(Failure(ex));
		}
		return prm;
	}

	public static function nodeWriteStream(path:String,?options:WriteStreamOpt):TOutcome<String,NodeWriteStream>{
		var prm = Core.outcome();
		try {
		  var ws = Node.fs.createWriteStream(path,options);
		  prm.complete((ws == null) ? Failure("can't create writeStream") : Success(ws));
		} catch(ex:Dynamic) {
		  prm.complete(Failure(ex));
		}
		return prm;
	}

}


