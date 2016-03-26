package db
{
	import com.maclema.mysql.ResultSet;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;

	public class DBList
	{
		public static const FILE_EXT_NAME:String = "dgb";
		public static var plat:String="qq";
		
		protected var _service:MySqlService;
		
		protected var dist_dict:String;
		protected var dist_path:String;
		
		protected var bytes:ByteArray;
		
		protected var save_bytes:ByteArray;
		protected var save_file:File;
		protected var _file_add:String;
		
		protected var sql:String;
		protected var _proto:Object;
		
		public function DBList(dist_dict:String,service:MySqlService)
		{
			save_bytes = new ByteArray();
			_file_add = FILE_EXT_NAME;
			this.dist_dict = dist_dict;
			this._service = service;
			
			init();
			createBytes();
		}
		
		protected function init():void
		{
			
		}
		
		private function createBytes():void
		{
			if(_service)
			{
				_service.select(sql,resultHandler);
			}
		}

		protected function resultHandler(result:ResultSet):void
		{
			result.first();
			
			Compress(result);
		}
		
		protected function Compress(result:ResultSet):void
		{
			
		}
		
		protected function saveFile():void
		{
			save_file = new File(dist_path);
			var file_stream:FileStream = new FileStream();
			save_bytes.compress();
			file_stream.open(save_file,FileMode.WRITE);
			file_stream.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
			file_stream.writeBytes(save_bytes,0,save_bytes.length);
		}
		
		private function onIOError(evt:Event):void
		{
			Alert.show("The specified currentFile cannot be saved.", "Error", Alert.OK);
		}
		
		public function set proto(value:Object):void
		{
			_proto = value;	
		}
		
		public function get proto():Object
		{
			return _proto;
		}
	}
}