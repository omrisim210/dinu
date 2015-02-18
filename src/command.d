module dinu.command;

import
	core.sync.mutex,
	std.string,
	std.process,
	std.parallelism,
	std.stdio,
	std.file,
	dinu.xclient,
	draw;


__gshared:


enum Type {

	script,
	desktop,
	file,
	directory

}


class Command {
	abstract int draw(int[2] pos);
	abstract string text();
	abstract string filterText();
	//bool lessenScore();
	abstract int score();
	abstract void run(string params);
	Type type;
}


class CommandFile: Command {

	string name;
	FontColor color;

	this(string name){
		this.name = name;
		type = Type.file;
		color = colorFile;
	}

	override string text(){
		return name;
	}

	override string filterText(){
		return name;
	}

	override int score(){
		return 0;
	}

	override int draw(int[2] pos){
		dc.text(pos, name, color);
		return pos[0]+dc.textWidth(name);
	}

	override void run(string params){
		spawnCommand(`xdg-open %s`.format(name));
	}

}

class CommandDir: CommandFile {

	this(string name){
		super(name);
		type = Type.directory;
		color = colorDir;
	}

	override int score(){
		return 2;
	}


}

class CommandExec: CommandFile {

	this(string name){
		super(name);
		type = Type.script;
		color = colorExec;
	}

	override int score(){
		return 5;
	}

	override void run(string params){
		spawnCommand(name ~ " " ~ params);
	}

}


class CommandDesktop: CommandFile {

	string exec;
	FontColor colorHint;

	this(string name, string exec){
		super(name);
		type = Type.desktop;
		this.exec = exec;
		color = colorDesktop;
		colorHint = dinu.xclient.colorHint;
	}

	override int draw(int[2] pos){
		int r = super.draw(pos);
		dc.text([r+5, pos[1]], exec, colorHint);
		return pos[0];
	}


	override int score(){
		return 100;
	}

	override string filterText(){
		return exec ~ name;
	}

	override void run(string params){
		spawnCommand(exec);
	}

}


void spawnCommand(string command){
	auto dg = {
		writeln("Running \"%s\"".format(command));
		(options.configPath ~ ".history").append(command ~ '\n');
		auto mutex = new Mutex;
		auto pipes = pipeShell(command);
		task({
			foreach(line; pipes.stdout.byLine){
				synchronized(mutex){
					(options.configPath ~ ".log").append(line ~ '\n');
					writeln(line);
				}
			}
		}).executeInNewThread;
		foreach(line; pipes.stderr.byLine){
			synchronized(mutex){
				(options.configPath ~ ".log").append(line ~ '\n');
				writeln(line);
			}
		}
		pipes.pid.wait;
	};
	task(dg).executeInNewThread;
}
