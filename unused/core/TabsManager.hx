package core;
import haxe.Timer;
import js.Browser;
import jQuery.*;
import js.html.Element;
import js.html.LIElement;
import js.html.SpanElement;

//Code from Tern bin\includes\js\tern\doc\demo\demo.js
//Ported to Haxe

typedef Doc = {
	var name:String;
	var doc:Dynamic;
	var path:String;
}

/**
 * ...
 * @author AS3Boyan
 */
class TabsManager
{

	public static var useWorker:Bool = false;
	public static var server:Dynamic;
	public static var editor:Dynamic;
	public static var docs:Array<Doc> = [];
	public static var curDoc:Doc;
	private static var themes:Array<String>;
	
	public function new() 
	{
		
	}
	
	public static function init()
	{
		themes = 
		[
		"3024-day",
		"3024-night",
		"ambiance",
		"base16-dark",
		"base16-light",
		"blackboard",
		"cobalt",
		"eclipse",
		"elegant",
		"erlang-dark",
		"lesser-dark",
		"midnight",
		"monokai",
		"neat",
		"night",
		"paraiso-dark",
		"paraiso-light",
		"rubyblue",
		"solarized dark",
		"solarized light",
		"the-matrix",
		"tomorrow-night-eighties",
		"twilight",
		"vibrant-ink",
		"xq-dark",
		"xq-light"
		];
		
	  new JQuery(Browser.document).on("closeTab",function(event, path)
		{
			for (i in 0...docs.length)
			{				
				if (docs[i] != null && docs[i].path == path)
				{
					unregisterDoc(docs[i]);
				}
			}
	  	});


		CodeMirror.on(Browser.window, "load", function() {
		  //Those defs(ecma5.json, browser.json, jquery.json) contain default completion for JavaScript, 
		  //probably we can supply here Haxe keywords, like so:
		  //this, typedef, class, interface, package, private, public, static, var, function, trace, switch, case and etc.
		  //http://haxe.org/ref/keywords
		  //We can create file similar to ecma5.json and provide description for each keyword
		  
		  //We can even provide completion for classes here, like String.
			
		  //var files = ["./includes/js/tern/defs/ecma5.json"];
		  //var files = ["./includes/js/tern/defs/ecma5.json", "./includes/js/tern/defs/browser.json", "./includes/js/tern/defs/jquery.json"];
		  //var loaded = 0;
		  //for (var i = 0; i < files.length; ++i) (function(i) {
			//load(files[i], function(json) {
			  //defs[i] = JSON.parse(json);
			  //if (++loaded == files.length) initEditor();
			//});
		  //})(i);
		  
		  initEditor();

		  //var cmds = document.getElementById("commands");
		  //CodeMirror.on(cmds, "change", function() {
			//if (!editor || cmds.selectedIndex == 0) return;
			//var found = commands[cmds.value];
			//cmds.selectedIndex = 0;
			//editor.focus();
			//if (found) found(editor);
		  //});
		  
		  Main.resize();
		
		  TabsManager.editor.refresh();
		});
	}
	
	public static function applyRandomTheme():Void
	{
		var theme:String = themes[Std.random(themes.length)];
		editor.setOption("theme", theme);
		new JQuery("body").css("background", new JQuery(".CodeMirror").css("background"));
	}
	
	private static function load(file, c:Dynamic):Void 
	{
		c(Utils.system_openFile(file), 200);
	}
	
	public static function createFileInNewTab():Void
	{
		var name = Browser.window.prompt("Name of the new file", "");
		if (name == null) return;
		registerDoc(name, new CodeMirror.Doc("", "haxe"), "");
		selectDoc(docs.length - 1);
	}
	
	public static function openFileInNewTab(path:String):Void
	{
		if (Utils.getOS() == Utils.WINDOWS)
		{
			var ereg = ~/[\\]/g;
			
			path = ereg.replace(path, "/");
		}
		
		for (i in 0...docs.length)
		{
			if (docs[i].path == path)
			{
				selectDoc(i);
				return;
			}
		}
		
		var pos:Int = null;
		
		if (Utils.getOS() == Utils.WINDOWS)
		{
			pos = path.lastIndexOf("\\");
			
			if (pos == -1)
			{
				pos = path.lastIndexOf("/");
			}
		}
		else
		{
			pos = path.lastIndexOf("/");
		}
		
		var filename:String = null;
		
		if (pos != -1)
		{
			filename = path.substr(pos + 1);
		}
		else
		{
			filename = path;
		}
		
		load(path, function(body) 
		{
			registerDoc(filename, new CodeMirror.Doc(body, "haxe"), path);
			selectDoc(docs.length - 1);
		});
		
		if (new JQuery("#panel").css("display") == "none" && docs.length > 0)
		{
			new JQuery("#panel").css("display", "block");
			TabsManager.editor.refresh();
			Main.updateMenu();
		}
		
		Main.resize();
	}
	
	public static function closeActiveTab():Void
	{
		unregisterDoc(curDoc);
	}
	
	public static function showNextTab():Void
	{
		var n = Lambda.indexOf(docs, curDoc);
		
		n++;
		
		if (n > docs.length - 1)
		{
			n = 0;
		}
		
		selectDoc(n);
	}
	
	public static function showPreviousTab():Void
	{
		var n = Lambda.indexOf(docs, curDoc);
		
		n--;
		
		if (n < 0)
		{
			n = docs.length - 1;
		}
		
		selectDoc(n);
	}
	
	private static function initEditor():Void
	{
		  var keyMap = {
			"Ctrl-I": function(cm) { server.showType(cm); },
			"Ctrl-Space": function(cm) { server.complete(cm); },
			"Alt-.": function(cm) { server.jumpToDef(cm); },
			"Alt-,": function(cm) { server.jumpBack(cm); },
			"Ctrl-Q": function(cm) { server.rename(cm); }
		  };

		  editor = CodeMirror.fromTextArea(Browser.document.getElementById("code"), {
			lineNumbers: true,
			extraKeys: keyMap,
			matchBrackets: true,
			dragDrop: false,
			autoCloseBrackets: true,
			foldGutter: {
				rangeFinder: untyped __js__("new CodeMirror.fold.combine(CodeMirror.fold.brace, CodeMirror.fold.comment)")
			},
			gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
		  });
		  
		  server = new TernServer({
			defs: [],
			plugins: {doc_comment: true},
			switchToDoc: function(name) { selectDoc(docID(name)); },
			workerDeps: ["./includes/js/acorn/acorn.js", "./includes/js/acorn/acorn_loose.js",
						 "./includes/js/acorn/util/walk.js", "./includes/js/tern/lib/signal.js", "./includes/js/tern/lib/tern.js",
						 "./includes/js/tern/lib/def.js", "./includes/js/tern/lib/infer.js", "./includes/js/tern/lib/comment.js",
						 "./includes/js/tern/plugin/doc_comment.js"],
			workerScript: "./includes/js/codemirror-3.18/addon/tern/worker.js",
			useWorker: useWorker

		  });

		  editor.on("cursorActivity", function(cm) { server.updateArgHints(cm); });

		  openFileInNewTab("../src/Main.hx");
		  openFileInNewTab("../src/Utils.hx");	
		  openFileInNewTab("../src/Session.hx");
		  openFileInNewTab("../src/core/FileAccess.hx");
		  openFileInNewTab("../src/core/ProjectAccess.hx");
		  openFileInNewTab("../src/core/TabsManager.hx");
										
		  //registerDoc("Main.hx", editor.getDoc(),'');
		  
		  //registerDoc("test_dep.js", new CodeMirror.Doc(document.getElementById("requirejs_test_dep").firstChild.nodeValue, "javascript"));
		  
		  //We can load files like this:
		  
		  //load("./includes/js/tern/doc/demo/underscore.js", function(body) {
			//registerDoc("underscore.js", new CodeMirror.Doc(body, "javascript"));
		  //});

		  CodeMirror.on(Browser.document.getElementById("docs"), "click", function(e) {
			var target:Dynamic = e.target || e.srcElement;
			if (target.nodeName.toLowerCase() != "li") return;
			
			var i = 0;
			var c:Dynamic = target.parentNode.firstChild;
			
			if (c == target)
			{
				return selectDoc(0);
			}
			else
			{
				while (true)
				{
					i++;
					c = c.nextSibling;
					if (c == target) return selectDoc(i);
				}
			}			
			//for (var i = 0, c = target.parentNode.firstChild; ; ++i, (c = c.nextSibling))
			  //if (c == target) return selectDoc(i);
		  });
	}

	private static function findDoc(name) { return docs[docID(name)]; }
	private static function docID(name) { for (i in 0...docs.length) if (docs[i].name == name) return i; return null; }

private static function registerDoc(name:String, doc:CodeMirror.Doc, path:String):Void
{	
  server.addDoc(name, doc);
  var data = {name: name, doc: doc, path: path};
  docs.push(data);

  var docTabs = Browser.document.getElementById("docs");
  var li:LIElement = Browser.document.createLIElement();
  li.title = path;
  li.innerText = name + "\t";
  
  var span:SpanElement = Browser.document.createSpanElement();
  span.style.position = "relative";
  span.style.top = "2px";
  
  span.setAttribute("onclick", "$(document).triggerHandler(\"closeTab\", \"" + path + "\");");
  
  var span2:SpanElement = Browser.document.createSpanElement();
  span2.className = "glyphicon glyphicon-remove-circle";
  span.appendChild(span2);
  
  li.appendChild(span);
  
  docTabs.appendChild(li);
  
  if (editor.getDoc() == doc) 
  {
    setSelectedDoc(docs.length - 1);
    curDoc = data;
  }
}

private static function unregisterDoc(doc):Void
{
	var b = curDoc == doc;
	
  server.delDoc(doc.name);
  var j:Int = null;
  for (i in 0...docs.length) 
  {
	  j = i;
	  if (doc == docs[i]) break;
  }
  
  docs.splice(j, 1);
  var docList = Browser.document.getElementById("docs");
  docList.removeChild(docList.childNodes[j]);
  
  if (b && docList.childNodes.length > 0)
  {
	selectDoc(Std.int(Math.max(0, j - 1)));
  }
  
  if (docList.childNodes.length == 0)
  {
	  new JQuery("#panel").css("display", "none");
	  Main.updateMenu();
  }
  
  Main.resize();
}

private static function setSelectedDoc(pos):Void
{
	var docTabs = Browser.document.getElementById("docs");
	for (i in 0...docTabs.childNodes.length)
	{
		var child:Element = cast(docTabs.childNodes[i], Element);
	  
		if (pos == i)
		{
			child.className = "selected";
		}
		else
		{
			child.className = "";
		}
	}
}
	
public static function selectDoc(pos):Void
{
	if (curDoc != null)
	{
		server.hideDoc(curDoc.name);
	}
	setSelectedDoc(pos);
	curDoc = docs[pos];
	editor.swapDoc(curDoc.doc);
}
	
}