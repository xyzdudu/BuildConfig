package utils
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;

	public class OutputASTemplateInfoConfig
	{
		[Embed(source="DefaultASTemplateInfoConfigText.txt",mimeType="application/octet-stream")]
		private var templateInfoClz:Class;
		
		[Embed(source="DefaultASTemplateListConfigText.txt",mimeType="application/octet-stream")]
		private var templateListClz:Class;
		
		private static var _instance:OutputASTemplateInfoConfig;
		
		private var defaultTemplateInfoTxt:String;
		private var defaultTemplateListTxt:String;
		private var infoOutputTxt:String;
		private var listOutputTxt:String;
		
		public function OutputASTemplateInfoConfig()
		{
			defaultTemplateInfoTxt = new templateInfoClz().toString();
			defaultTemplateListTxt = new templateListClz().toString();
		}
		
		public static function getInstance():OutputASTemplateInfoConfig
		{
			return _instance ||= new OutputASTemplateInfoConfig();
		}
		
		private function addItem(fileName:String,bytesConfig:ByteArray):void
		{
			//TemplateInfo
			bytesConfig.readUTF();
			infoOutputTxt = defaultTemplateInfoTxt.replace(/nameClass/g,fileName + "TemplateInfo");
			
			var strVar:String = "";
			var strInfo:String = "";
			var len:int = bytesConfig.readInt();
			for(var i:int = 0; i < len; i ++)
			{
				var varName:String = bytesConfig.readUTF();
				var varType:String = bytesConfig.readUTF(); 
				
				var strGetType:String = "";
				switch(varType)
				{
					case "int":
					case "tinyint":
					case "smallint":
					case "float":
						strGetType = ".readInt()";
						strVar += "public var " + varName + ":int;";
						break;
					case "bigint":
						strGetType = ".readDouble()";
						strVar += "public var " + varName + ":Number;";
						break;
					case "char":
					case "varchar":
					case "text":
						strGetType = ".readUTF()";
						strVar += "public var " + varName + ":String;";
						break;
				}
				
				strVar += "\n\t\t";
				
				strInfo += varName + " = data" + strGetType + ";";
				strInfo += "\n\t\t\t";
			}
			
			infoOutputTxt = infoOutputTxt.replace("[variable]",strVar);
			infoOutputTxt = infoOutputTxt.replace("[info]",strInfo);
			
			//TemplateList
			listOutputTxt = defaultTemplateListTxt.replace(/nameClass/g,fileName + "TemplateList");
			listOutputTxt = listOutputTxt.replace(/nameList/,fileName + "list");
			listOutputTxt = listOutputTxt.replace(/templateInfo/g,fileName + "TemplateInfo");
		}
		
		public function outputFile(fileName:String,bytesConfig:ByteArray,dirPath:String):void
		{
			var name:String = fileName.slice(0,fileName.length - 8);
			bytesConfig.uncompress();
			addItem(name,bytesConfig);
			
			try
			{
				var infoFile:File = new File(dirPath + "\\config/" + name + "TemplateInfo.as");
				var infoFs:FileStream = new FileStream();
				infoFs.open(infoFile,FileMode.WRITE);
				infoFs.writeUTFBytes(infoOutputTxt);
				infoFs.close();
				
				var listFile:File = new File(dirPath + "\\config/" + name + "TemplateList.as");
				var listFs:FileStream = new FileStream();
				listFs.open(listFile,FileMode.WRITE);
				listFs.writeUTFBytes(listOutputTxt);
				listFs.close();
			}
			catch(e:Error)
			{
				Alert.show(e.message,"错误");
			}
			/*var cfgFile:File = new File(dirPath)
			var list:Array = cfgFile.getDirectoryListing();
			for(var i:int = 0; i < list.length; i ++)
			{
				var dgbFile:File = list[i];
				if(dgbFile)
				{
					if(dgbFile.type == ".dgb")
					{
						var name:String = dgbFile.name.slice(0,dgbFile.name.length - 8);
						bytesConfig.uncompress();
						addItem(name,bytesConfig);
						
						try
						{
							var file:File = new File(dirPath + "/config/" + name + "TemplateInfo.as");
							var fs:FileStream = new FileStream();
							fs.open(file,FileMode.WRITE);
							fs.writeUTFBytes(infoOutputTxt);
							fs.close();
						}
						catch(e:Error)
						{
							Alert.show(e.message,"错误");
						}
					}
					
				}
			}*/
		}
	}
}