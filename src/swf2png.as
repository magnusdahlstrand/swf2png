package
{
	import com.adobe.images.PNGEncoder;
	
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
		private var offsetMatrix:Matrix;
		private var bBox:Rectangle;



		public function swf2png() {
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
			outfield = new TextField();
			outfield.autoSize = TextFieldAutoSize.LEFT;
			stage.addChild(outfield);
			stage.frameRate = 12;
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
			loadedSwf = MovieClip(ev.target.content);
			outputWidth = Math.ceil(ev.target.width);
			outputHeight = Math.ceil(ev.target.height);
			log("Loaded!");
			totalFrames = loadedSwf.totalFrames;
			log("Frame count: " + totalFrames);

			calculateBBox();

			stopClip(loadedSwf);
			goToFrame(loadedSwf, 0);
			timer = new Timer(1);

			timer.addEventListener(TimerEvent.TIMER, step);
			timer.start();

		}

		private function calculateBBox():void {
			stopClip(loadedSwf);
			goToFrame(loadedSwf, 0);

			var boundsArray:Object = {
				"x" : new Array(),
				"y" : new Array(),
				"w" : new Array(),
				"h" : new Array()
			}
			var r:Rectangle;
			for(var currentFrame:int = 0; currentFrame < totalFrames; currentFrame++) {
				goToFrame(loadedSwf, currentFrame);
				r = loader.content.getRect(stage);
				boundsArray.x.push(r.x);
				boundsArray.y.push(r.y);
				boundsArray.w.push(r.width);
				boundsArray.h.push(r.height);
			}

			boundsArray.x.sort(Array.NUMERIC);
			boundsArray.y.sort(Array.NUMERIC);
			boundsArray.w.sort(Array.NUMERIC | Array.DESCENDING);
			boundsArray.h.sort(Array.NUMERIC | Array.DESCENDING);

			bBox = new Rectangle(
				Math.floor(boundsArray.x[0]),
				Math.floor(boundsArray.y[0]),
				Math.ceil(boundsArray.w[0]),
				Math.ceil(boundsArray.h[0])
			);

			log("Bounding box: " + bBox)

			outputWidth = bBox.width;
			outputHeight = bBox.height;
			offsetMatrix = new Matrix();
			offsetMatrix.translate(bBox.x * -1, bBox.y * -1);

			return;
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
			bitmapData.draw(loader.content, offsetMatrix);
			var bytearr:ByteArray = PNGEncoder.encode(bitmapData);
			var increment:String = '';
			if(totalFrames > 1) {
				increment = separator + counter;
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
					mc.gotoAndStop(frameNo % inMc.totalFrames);
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
				var matches:Array = inputFileName.match(/([a-zA-Z0-9_\-\+\.]*?)\.swf$/);
				if(!matches) {
					// File inputFileName not valid
					exit(2);
					return "";
				}
				prefix = matches[1];
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
				log("inpt: " + d.nativePath);
				return d.nativePath;
			}
			else {
				if(ev.currentDirectory.nativePath === '/') {
					if(ev.arguments.length) {
						d = new File(ev.arguments[0]);
						d = d.resolvePath('..');
						return d.nativePath;
					}
					else {
						return File.desktopDirectory.nativePath;
					}
				}
				else {
					log("cwd: " + ev.currentDirectory.nativePath);
					return ev.currentDirectory.nativePath;
				}
				return "";
			}
		}

		private function log(message:String="", add_new_line:Boolean=true):void {
			outfield.appendText((add_new_line ? "\n" : "") + message);
		}

		//Invoke handler called when started
		private function onInvoke(ev:InvokeEvent):void {

			inputFilePath = getInputFile(ev);
			outputDirPath = getOutputDir(ev);

			log("Input file: " + inputFilePath);
			log("Output directory: " + outputDirPath);
			loadSwf();
		}

		private function exit(code:int=0):void {
			NativeApplication.nativeApplication.exit(code);
		}
	}
}