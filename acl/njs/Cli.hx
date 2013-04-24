package acl.njs;

using acl.njs.Sys;

/**
 * npm install commander
 * @author Ritchie Turner
 */
 
 typedef TCli = {
 	cli:Dynamic,
 	cmd:Dynamic
 }
 
 
class Cli {
	
	static var cli = Sys.require("commander");
	
	public static function create():TCli {
		return {
			cli:cli,
			cmd:null
		};
	}
	
	public static function option(cli:TCli,name:String,?desc:String,?type:Class<Dynamic>,?defaultValue:Dynamic) {
		cli.cli.option(name,desc,type,defaultValue);
	}
	
	public static function start(cli:TCli) {
		cli.cli.parse(Sys.argv());
	}
	
	public static function command(cli:TCli,cmd:String):TCli {
		cli.cmd = cli.cli.command(cmd);
		return cli;
	}
	
	public static function description(cli:TCli,desc:String) {
		cli.cmd.description(desc);
		return cli;
	}
	
	public static function action(cli:TCli,action:Dynamic) {
		Sys.Assert.ok(Reflect.isFunction(action));
		cli.cmd.action(action);
		return cli;
	}

	public static function action0(cli:TCli,action:Void->Void) {
		cli.cmd.action(action);
		return cli;
	}

	public static function action1(cli:TCli,action:Dynamic->Void) {
		cli.cmd.action(action);
		return cli;
	}

	public static function action2(cli:TCli,action:Dynamic->Dynamic->Void) {
		cli.cmd.action(action);
		return cli;
	}

}
