package utils
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.controls.Alert;

	public class OutputASNameConfig
	{
		[Embed(source="DefaultASNameConfigText.txt",mimeType="application/octet-stream")]
		private var clz:Class;
		private static var _instance:OutputASNameConfig;
		
		private var defaultTxt:String;
		private var outputTxt:String;
		private var listTxt:String;
		private var len:int;
		
		public function OutputASNameConfig()
		{
			defaultTxt = new clz().toString();
		}
		
		public static function getInstance():OutputASNameConfig
		{
			return _instance ||= new OutputASNameConfig();
		}
		
		private function addItem(index:int,fileName:String):void
		{
			outputTxt += "public static const " + fileName.toLocaleUpperCase() + ":String = \"" + fileName.toLocaleLowerCase() + "\";";
			outputTxt += "\n\t\t";
			
			if(index + 1 == len)
				listTxt += "\"" + fileName.toLocaleLowerCase() + "\"";
			else
				listTxt += "\"" + fileName.toLocaleLowerCase() + "\",";
			if((index + 1) % 7 == 0)
				listTxt += "\n\t\t\t";
		}
		
		public function outputFile(dirPath:String):void
		{
			outputTxt = "";
			listTxt = "";
			
			var cfgFile:File = new File(dirPath + "\\dgb/")
			var list:Array = cfgFile.getDirectoryListing();
			len = list.length;
			var index:int = 0;
			for(var i:int = 0; i < len; i ++)
			{
				var dgbFile:File = list[i];
				if(dgbFile)
				{
					if(dgbFile.type == ".dgb")
					{
						var name:String = dgbFile.name.split(".")[0];
						addItem(index,name);
						index ++;
					}
					
				}
			}
			
			outputTxt = defaultTxt.replace("[info]",outputTxt);
			outputTxt = outputTxt.replace("[list]",listTxt);
			
			try
			{
				var file:File = new File(dirPath + "/ConfigName.as");
				var fs:FileStream = new FileStream();
				fs.open(file,FileMode.WRITE);
				fs.writeUTFBytes(outputTxt);
				fs.close();
				
				Alert.show("导出成功！！","提示");
			}
			catch(e:Error)
			{
				Alert.show(e.message,"错误");
			}
		}
	}
}