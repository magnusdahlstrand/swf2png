package
{
	import com.adobe.images.PNGEncoder;
	import com.bit101.components.ScrollPane;
	
	import flash.desktop.NativeApplication;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	public class swf2png extends Sprite
	{
		public var outputWidth:int;
		public var outputHeight:int;
		public var loadedSwf:MovieClip;
		public var loader:Loader;
		private var counter:int = 0;
		private var timer:Timer;
		private var totalFrames:int;
		private var inputFileName:String;
		private var inputFilePath:String;
		private var prefix:String;
		private var separator:String = "_";
		private var outfield:TextField;
		private var outputDirPath:String;
		private var offsetMatrix:Matrix = new Matrix();
		private var bBox:Rectangle;
		private var scaleFactor:Number;
		private var pane:ScrollPane;



		public function swf2png() {
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);

			stage.align = 'TL';
			stage.scaleMode = 'noScale';
			stage.frameRate = 12;
			outfield = new TextField();
			outfield.autoSize = TextFieldAutoSize.LEFT;
			pane = new ScrollPane(stage);

			pane.width = stage.stageWidth;
			pane.height = stage.stageHeight;
			pane.addChild(outfield);
			pane.update();

			stage.addEventListener(Event.RESIZE, onResize, false, 0, true);

		}

		//Loads in file
		private function loadSwf():void {

			loader = new Loader();
			log("Loading " + inputFilePath);
			loader.load(new URLRequest("file://" + inputFilePath));
			loader.contentLoaderInfo.addEventListener(Event.INIT, startLoop);

		}

		//Event handler called when the swf is loaded. Sets it up and starts the export loop
		private function startLoop(ev:Event):void {
			try {
				loadedSwf = MovieClip(ev.target.content);
			}
			catch(err:Error) {
				//AVM1 Movie not supported
				exit(5);
				return;
			}
			outputWidth = Math.ceil(ev.target.width);
			outputHeight = Math.ceil(ev.target.height);
			log("Loaded!");
			totalFrames = loadedSwf.totalFrames;
			log("Frame count: " + totalFrames);

			stopClip(loadedSwf);
			goToFrame(loadedSwf, 0);
			timer = new Timer(1);

			timer.addEventListener(TimerEvent.TIMER, step);
			timer.start();

		}

		private function padNumber(input:int, target:int):String {
			var out:String = input.toString();
			var targetCount:int = target.toString().length;
			while(out.length < targetCount) {
				out = '0' + out;
			}
			return out;
		}

		//Called for every frame
		private function step(ev:TimerEvent):void {
			counter++;
			if(counter <= totalFrames) {
				goToFrame(loadedSwf, counter);
				saveFrame();
			}
			else {
				timer.stop();
				log("Done!");
				exit(0);
				return;
			}
		}

		//Saves the current frame of the loader object to a png
		private function saveFrame():void {
			var bitmapData:BitmapData = new BitmapData(outputWidth, outputHeight, true, 0x0);
			offsetMatrix.scale(scaleFactor, scaleFactor);
			bitmapData.draw(loader.content, offsetMatrix);
			var bytearr:ByteArray = PNGEncoder.encode(bitmapData);
			var increment:String = '';
			if(totalFrames > 1) {
				increment = separator + padNumber(counter, totalFrames);
			}
			var outfileName:String = outputDirPath + File.separator + prefix + increment + ".png"
			var file:File = new File(outfileName);

			log("Writing: " + outfileName);
			var stream:FileStream = new FileStream();
			stream.open(file, "write");
			stream.writeBytes(bytearr);
			stream.close();
		}

		//Stops the movie clip and all its subclips.
		private function stopClip(inMc:MovieClip):void {
			var l:int = inMc.numChildren;
			for (var i:int = 0; i < l; i++) 
			{
				var mc:MovieClip = inMc.getChildAt(i) as MovieClip;
				if(mc) {
					mc.stop();
					if(mc.numChildren > 0) {
						stopClip(mc);
					}
				}
			}
			inMc.stop();
		}

		//Traverses the movie clip and sets the current frame for all subclips too, looping them where needed.		
		private function goToFrame(inMc:MovieClip, frameNo:int):void {
			var l:int = inMc.numChildren;
			for (var i:int = 0; i < l; i++) 
			{
				var mc:MovieClip = inMc.getChildAt(i) as MovieClip;
				if(mc) {
					mc.gotoAndStop(frameNo % (inMc.totalFrames + 1));
					if(mc.numChildren > 0) {
						goToFrame(mc, frameNo);
					}
				}
			}
			inMc.gotoAndStop(frameNo % inMc.totalFrames);
		}

		//Finds and checks for existance of input file
		private function getInputFile(ev:InvokeEvent):String {
			if(ev.arguments && ev.arguments.length) {
				inputFileName = ev.arguments[0];
				var matchNameRegExStr:String = '([^\\' + File.separator + ']+)$';
				var matchNameRegEx:RegExp = new RegExp(matchNameRegExStr);
				var matches:Array = inputFileName.match(matchNameRegEx);
				if(!matches) {
					// File inputFileName not valid
					exit(2);
					return "";
				}
				prefix = matches[1].split('.')[0];
				log("Prefix: " + prefix);
				var f:File = new File(ev.currentDirectory.nativePath);
				f = f.resolvePath(inputFileName);
				if(!f.exists) {
					log("Input file not found!");
					//Input file not found
					exit(3);
					return "";
				}
				return f.nativePath;
			}
			else {
				//App opened without input data
				exit(1);
				return "";
			}
		}

		//Finds and checks for existance of output directory
		private function getOutputDir(ev:InvokeEvent):String {
			var d:File;
			if(ev.arguments.length > 1) {
				outputDirPath = ev.arguments[1];
				d = new File(ev.currentDirectory.nativePath);
				d = d.resolvePath(outputDirPath);
				if(!d.isDirectory) {
					//outdir not a directory
					exit(4);
					return "";
				}
				return d.nativePath;
			}
			else if(inputFilePath) {
				d = new File(inputFilePath);
				if(!d.isDirectory) {
					d = d.resolvePath('..');
				}
				return d.nativePath;
			}
			else {
				if(ev.currentDirectory.nativePath === '/') {
					return File.desktopDirectory.nativePath;
				}
				else {
					return ev.currentDirectory.nativePath;
				}
			}
			return "";
		}
		private function getScaleFactor(ev:InvokeEvent):Number {
			if(ev.arguments.length > 2) {
				log("scale factor set to " + parseFloat(ev.arguments[2]));
				return parseFloat(ev.arguments[2]);
			}
			outputWidth *= scaleFactor;
			outputHeight *= scaleFactor;
			return 1;
		}

		private function log(message:String="", add_new_line:Boolean=true):void {
			outfield.appendText((add_new_line ? "\n" : "") + message);
			pane.update();
		}

		//Invoke handler called when started
		private function onInvoke(ev:InvokeEvent):void {

			inputFilePath = getInputFile(ev);
			outputDirPath = getOutputDir(ev);
			scaleFactor = getScaleFactor(ev);

			log("Input file: " + inputFilePath);
			log("Output directory: " + outputDirPath);
			loadSwf();
		}

		private function onResize(ev:Event):void {
			pane.width = stage.stageWidth;
			pane.height = stage.stageHeight;
			pane.update();
		}

		private function exit(code:int=0):void {
			log("Exit: " + code);
			NativeApplication.nativeApplication.exit(code);
		}
	}
}