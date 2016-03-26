package db
{
	import com.maclema.mysql.Connection;
	import com.maclema.mysql.MySqlToken;
	import com.maclema.mysql.ResultSet;
	import com.maclema.mysql.Statement;
	import com.maclema.mysql.events.MySqlEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class MySqlService extends EventDispatcher
	{
		private var _host:String;
		private var _port:int;
		private var _username:String;
		private var _password:String;
		private var _database:String;
		private var _callBack:Function;
		
		private var _connection:Connection;
		private var _isConnected:Boolean;
		
		public function MySqlService(host:String, port:int, username:String, password:String, database:String)
		{
			super();
			this._host = host;
			this._port = port;
			this._username = username;
			this._password = password;
			this._database = database;
		}
		/**
		 * 重置数据
		 * @param host
		 * @param port
		 * @param username
		 * @param password
		 * @param database
		 * @return 
		 */		
		public function resetInfo(host:String, port:int, username:String, password:String, database:String):void
		{
			this._host = host;
			this._port = port;
			this._username = username;
			this._password = password;
			this._database = database;
		}
		
		/**建立一个新连接*/
		public function startService(callBack:Function):void
		{
			this._callBack = callBack;
			_connection = new Connection(_host,_port,_username,_password,_database);
			_connection.addEventListener(Event.CONNECT,connectCompleteHandler);
			_connection.connect();
		}
		
		private function connectCompleteHandler(e:Event):void
		{
			_isConnected =true;
			if(_callBack != null)_callBack();
		}
		
		/**断开连接*/
		public function stopService():void
		{
			if(!_isConnected)return;
			_connection.disconnect();
			_isConnected =false;
		}
		
		public function getData():Object
		{
			return {host:_host,port:_port,username:_username,password:_password,database:_database};
		}
		
		/**查询数据*/
		public function select(sql:String,callBack:Function):void
		{
			if(sql == null)return;
			var statement:Statement = _connection.createStatement();
			var token:MySqlToken = statement.executeQuery(sql);
			token.addEventListener(MySqlEvent.RESULT,resultHandler);

			function resultHandler(e:MySqlEvent):void
			{
				var result:ResultSet = e.resultSet;
				if(result != null && callBack != null)
				{
					callBack(result);
				}
			}
		}
		
	}
}