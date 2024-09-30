public class SBR_3_0_SyncAccountJsonParser{
	public cls_data data;
	public class cls_data {
		public String crossReferenceNumber;	//00000000000000820242
		public String rmAccountNumber;	//12146
	}
	public static SBR_3_0_SyncAccountJsonParser parse(String json){
		return (SBR_3_0_SyncAccountJsonParser) System.JSON.deserialize(json, SBR_3_0_SyncAccountJsonParser.class);
	}
 }