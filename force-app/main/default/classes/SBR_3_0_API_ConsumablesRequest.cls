public class SBR_3_0_API_ConsumablesRequest {

	public String pc;
	public List<Products> products;

	public class Products {
		public String catId;
		public String classId;
	}

	
	public static SBR_3_0_API_ConsumablesRequest parse(String json) {
		return (SBR_3_0_API_ConsumablesRequest) System.JSON.deserialize(json, SBR_3_0_API_ConsumablesRequest.class);
	}
}