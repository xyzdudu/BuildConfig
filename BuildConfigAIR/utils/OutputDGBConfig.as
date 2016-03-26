package utils
{	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	/**
	 * @author cl
	 * 2014-3-5 上午11:32:32
	 */
	public class OutputDGBConfig
	{
		[Embed(source="DefaultDGBConfigText.txt",mimeType="application/octet-stream")]
		private var clz:Class;
				
		private static var _instance:OutputDGBConfig;
		
		private var defaultTxt:String;
		private var outputTxt:String;
		
		public static function getInstance():OutputDGBConfig
		{
			return _instance ||= new OutputDGBConfig();
		}
		
		public function OutputDGBConfig()
		{
			defaultTxt = new clz().toString();
		}
		
		private function addItem(index:int,fileName:String,extendName:String):void
		{
			var name:String = fileName + extendName;
			if(index == 0)
			{
				outputTxt += "[Embed(source='../config/"+name+"',mimeType='application/octet-stream')]";
			}
			else
			{
				outputTxt += "\n\t\t[Embed(source='../config/"+name+"',mimeType='application/octet-stream')]";
			}
			
			var clzName:String = fileName + "Clz";
			
			outputTxt += "\n\t\t";
			outputTxt += "private var "+clzName+":Class;";
			outputTxt += "\n\t\t";
			outputTxt += "public var "+fileName.toLocaleLowerCase()+":ByteArray = new "+clzName+"() as ByteArray;\n";
		}
		
		public function outputFile(dirPath:String):void
		{
			outputTxt = "";
			
			/*var dataList:Dictionary = ConfigDataBase.getInstance().configs;
			var index:int = 0;
			for each(var item:Object in dataList)
			{
				addItem(index,item.fileName,item.extName);
				
				index++;
			}*/
			var cfgFile:File = new File(dirPath + "\\dgb/")
			var list:Array = cfgFile.getDirectoryListing();
			for(var i:int = 0; i < list.length; i ++)
			{
				var dgbFile:File = list[i];
				if(dgbFile)
				{
					if(dgbFile.type == ".dgb")
						addItem(i,dgbFile.name.split(".")[0],dgbFile.type);
						
				}
			}
			
			outputTxt = defaultTxt.replace("[info]",outputTxt);
			
			try
			{
				var file:File = new File(dirPath + "/CONFIG_ZHTX.as");
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