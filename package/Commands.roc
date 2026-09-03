import /Commands/Strings as StringCommands
import /Commands/HyperLogLog as HyperLogLogCommands
import /Commands/Transactions as TransactionCommands
import /Commands/Connection as ConnectionCommands
import /Commands/Sets as SetCommands
import /Commands/Lists as ListCommands
import /Commands/Hashes as HashCommands
import /Commands/Bitmaps as BitmapCommands
import /Commands/Scripting as ScriptingCommands
import /Commands/PubSub as PubSubCommands
import /Commands/Keyspace as KeyspaceCommands
import /Commands/Geo as GeoCommands
import /Commands/SortedSets as SortedSetCommands
import /Commands/Arrays as ArrayCommands
import /Commands/VectorSets as VectorSetCommands
import /Commands/Streams as StreamCommands
import /Commands/Cluster as ClusterCommands
import /Commands/Server as ServerCommands
import Command

## Redis command families, grouped independently of transport ownership.
Commands :: [].{
	Strings : StringCommands
	HyperLogLog : HyperLogLogCommands
	Transactions : TransactionCommands
	Connection : ConnectionCommands
	Sets : SetCommands
	Lists : ListCommands
	Hashes : HashCommands
	Bitmaps : BitmapCommands
	Scripting : ScriptingCommands
	PubSub : PubSubCommands
	Keyspace : KeyspaceCommands
	Geo : GeoCommands
	SortedSets : SortedSetCommands
	Arrays : ArrayCommands
	VectorSets : VectorSetCommands
	Streams : StreamCommands
	Cluster : ClusterCommands
	Server : ServerCommands
}

expect Command.encode(Commands.Strings.get("key").command()) == "*2\r\n$3\r\nGET\r\n$3\r\nkey\r\n".to_utf8()
