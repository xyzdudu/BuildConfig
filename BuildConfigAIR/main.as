import com.maclema.mysql.ResultSet;

import db.MySqlService;

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.ByteArray;

import mx.controls.Alert;

import utils.OutputASNameConfig;
import utils.OutputASTemplateInfoConfig;
import utils.OutputDGBConfig;

private var _mysqlService:MySqlService;

private var _textChange:Boolean = false;
private var _languageTextChange:Boolean = false;
private var _checkLanguage:Boolean = false;
private var _checkConfig:Boolean = false;

private var _arrConfigs:Array = [];
private var _isLanguageFinish:Boolean = false;
private var _isConfigFinish:Boolean = false;

private function onInit():void
{
	_mysqlService = new MySqlService(host.text,int(port.text),username.text,password.text,database.text);
	_mysqlService.startService(connectComplete);
	
	readConfig();
}

private function connectComplete():void
{
	connState.text = "数据库已连接";
}

private function connectClick(e:MouseEvent):void
{
	if(_mysqlService == null || isNewAddress())
	{
		onInit();
	}
	else
	{
		_mysqlService.stopService();
		_mysqlService.resetInfo(host.text,int(port.text),username.text,password.text,database.text);
		connState.text = "数据库未连接";
		_mysqlService.startService(connectComplete);
	}
}

private function isNewAddress():Boolean
{
	var data:Object = _mysqlService.getData();
	if(host.text != data.host || port.text != data.port || username.text != data.username)
	{
		return true;
	}
	return false;
}

private function onClose():void
{
	if(_mysqlService)_mysqlService.stopService();
	saveConfig();
}

private function text_change(e:Event):void
{
	_textChange = true;
}

/**保存程序配置*/
private function saveConfig(complete:Function=null):void
{
	if(!_textChange)return;
	trace("start save !");
	var cfgFile:File = File.applicationDirectory;
	var file_stream:FileStream = new FileStream();
	var configFile:File = new File(cfgFile.nativePath+ "\\config.ini");
	var config:String = host.text + "||" + port.text + "||" + username.text + "||" + password.text + "||" + database.text + "||" + target_path.text + "||" + language_path.text;
		
	file_stream.open(configFile,FileMode.WRITE);
	file_stream.writeUTFBytes(config);
	file_stream.close();
}

/**读取程序配置*/
private function readConfig():void
{
	var cfgFile:File = File.applicationDirectory;
	var configFile:File = new File(cfgFile.nativePath+ "\\config.ini");
	if(!configFile.exists)
	{
		saveConfig(read);
	}
	else
	{
		read();
	}
	
	function read():void
	{
		var loader:URLLoader = new URLLoader()
		var urlRequest:URLRequest = new URLRequest(cfgFile.nativePath+ "\\config.ini");	
		loader.load(urlRequest);
		loader.addEventListener(Event.COMPLETE,setDefaultConfig);
	}
}

private function setDefaultConfig(e:Event):void
{
	var configList:Array = ((e.currentTarget as URLLoader).data as String).split("||");
	if(configList && configList.length >= 7)
	{
		host.text = configList[0];
		port.text = configList[1];
		username.text = configList[2];
		password.text = configList[3];
		database.text = configList[4];
		target_path.text = configList[5];
		language_path.text = configList[6];
	}
}

private function selectLanguage(evt:Event):void
{
	_checkLanguage = !_checkLanguage
}

private function selectConfig(evt:Event):void
{
	_checkConfig = !_checkConfig;
}

private function btn_ok_clickHandler(evt:MouseEvent):void
{
	if(_mysqlService == null)
		return;
	
	_isLanguageFinish = false;
	_isConfigFinish = false;
	if(select_language.selected == true)
		buildLanguageAndDescript();
	if(select_config.selected == true)
		buildAllConfig();
}

private function buildAllConfig():void
{
	_mysqlService.select("select TABLE_NAME from information_schema.TABLES where TABLE_SCHEMA = 'zhtx_template'",allConfigResultHandler);
}

private function allConfigResultHandler(result:ResultSet):void
{
	result.first();
	
	_arrConfigs = [];
	var len:int = result.size();
	for(var i:int = 0; i < len; i ++)
	{
		_arrConfigs.push(result.getString("TABLE_NAME"));
		result.next();
	}
	
	_arrConfigs.forEach(buildConfig);
}

private function buildConfig(name:String,index:int,arrConfig:Array):void
{
	function dataTypesResultHandler(result:ResultSet):void
	{
		result.first();
		
		var len:int = result.size();
		var arrDataTypes:Array = [];
		var arrDatas:Array = [];
		for(var i:int = 0; i < len; i ++)
		{
			arrDataTypes.push(result.getString("DATA_TYPE"));
			arrDatas.push(result.getString("COLUMN_NAME"));
			result.next();
		}
		
		createBytes(name,arrDatas,arrDataTypes,index);
	}
	_mysqlService.select("select * from information_schema.COLUMNS where table_name = '" + name + "' and table_schema= 'zhtx_template'",dataTypesResultHandler);
}

private function createBytes(name:String,datas:Array,types:Array,index:int):void
{
	function resultHandler(result:ResultSet):void
	{
		result.first();
		
		var len:int = result.size();
		var arrTemplateName:Array = name.split("_");
		arrTemplateName.pop();
		arrTemplateName.shift();
		var templateName:String = "";
		for(var k:int = 0; k < arrTemplateName.length; k ++)
		{
			if(k == 0)
				templateName = templateName + arrTemplateName[k];
			else
				templateName = templateName + arrTemplateName[k].toString().charAt(0).toUpperCase() + arrTemplateName[k].toString().slice(1);
		}
		templateName = templateName + "List";
		
		var save_bytes:ByteArray = new ByteArray();
		save_bytes.writeUTF(templateName);
		
		save_bytes.writeInt(datas.length);
		for(var m:int = 0; m < datas.length; m ++)
		{
			save_bytes.writeUTF(datas[m]);
			save_bytes.writeUTF(types[m]);
		}
		
		save_bytes.writeInt(len);
		for(var i:int = 0; i < len ; i ++)
		{
			for(var j:int = 0; j < types.length; j ++)
			{
				var strType:String = types[j];
				switch(strType)
				{
					case "int":
					case "tinyint":
					case "smallint":
					case "float":
						save_bytes.writeInt(result.getInt(datas[j]));
						break;
					case "bigint":
						save_bytes.writeDouble(result.getNumber(datas[j]));
						break;
					case "char":
					case "varchar":
					case "text":
						save_bytes.writeUTF(result.getString(datas[j]));
						break;
				}
			}
			result.next();
		}
		
		saveFile(target_path.text+"\\dgb/"+templateName+".dgb",save_bytes);
		
		if(index == _arrConfigs.length - 1)
		{
			_isConfigFinish = true;
			if(select_language.selected == true && _isLanguageFinish == true)
				Alert.show("Finish & Sucessed","Sucessed");
			else if(select_language.selected == false)
				Alert.show("Finish & Sucessed","Sucessed");
		}
	}
	_mysqlService.select("select * from " + name,resultHandler);
}

private function buildLanguageAndDescript():void
{
	var languageLoader:URLLoader = new URLLoader();
	languageLoader.addEventListener(Event.COMPLETE,onLanguageComplate);
	languageLoader.load(new URLRequest(language_path.text + platTxt.text + "/language.txt"));
	
	var descriptLoader:URLLoader = new URLLoader();
	descriptLoader.addEventListener(Event.COMPLETE,onDescriptComplate);
	descriptLoader.load(new URLRequest(language_path.text + platTxt.text + "/descript.txt"));
}

private function onLanguageComplate(evt:Event):void
{
	var save_bytes:ByteArray = new ByteArray();
	save_bytes.writeUTF("language");
	save_bytes.writeUTFBytes(evt.currentTarget.data.toString());
	
	saveFile(target_path.text + platTxt.text +"/languageC.txt",save_bytes);
	
	_isLanguageFinish = true;
	if(select_config.selected == true && _isConfigFinish == true)
		Alert.show("Finish & Sucessed","Sucessed");
	else if(select_config.selected == false)
		Alert.show("Finish & Sucessed","Sucessed");
}

private function onDescriptComplate(evt:Event):void
{
	var save_bytes:ByteArray = new ByteArray();
	save_bytes.writeUTF("descriptList");
	save_bytes.writeUTFBytes(evt.currentTarget.data.toString());
	
	saveFile(target_path.text + platTxt.text +"/descriptC.txt",save_bytes);
}

private function saveFile(dist_path:String,save_bytes:ByteArray):void
{
	var save_file:File = new File(dist_path);
	var file_stream:FileStream = new FileStream();
	save_bytes.compress();
	file_stream.open(save_file,FileMode.WRITE);
	file_stream.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
	file_stream.writeBytes(save_bytes,0,save_bytes.length);
	
	if(save_file.type == ".dgb")
		OutputASTemplateInfoConfig.getInstance().outputFile(save_file.name,save_bytes,target_path.text);
}

private function onIOError(evt:Event):void
{
	Alert.show("The specified currentFile cannot be saved.", "Error", Alert.OK);
}

private function onOutputDGBConfig(evt:MouseEvent):void
{
	OutputDGBConfig.getInstance().outputFile(target_path.text);
}

private function onOutputASConfig(evt:MouseEvent):void
{
	OutputASNameConfig.getInstance().outputFile(target_path.text);
}