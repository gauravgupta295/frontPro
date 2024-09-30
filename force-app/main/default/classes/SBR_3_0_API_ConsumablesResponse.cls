public class SBR_3_0_API_ConsumablesResponse {

	public class Consumables {
		public String inventoryClass;
		public String invClassDescription;
		public List<SpecGroups> specGroups;
	}

	public class SuggestedItems {
		public String catId;
		public String classId;
		public List<Rentables> rentables;
		public List<Consumables> consumables;
	}

	public class Products {
		public String productNumber;
		public String stockClass;
		public String oemStockNumber;
		public String productDescription;
		public String priceSchedule;
		public String sequence;
		public String forceItem;
		public Integer minQuantity;
		public Double sellingPrice;
		public Integer availQuantity;
		public String binNumber1;
		public String binNumber2;
		public String binNumber3;
		public String rentalCat;
		public String rentalClass;
		public Boolean isSerialized;
	}

	public Data data;

	public class Rentables {
		public String rentalCat;
		public String rentalClass;
		public String equipmentNumber;
		public String sequence;
		public String description;
		public String forceItem;
		public Integer minQuantity;
		public Double minRate;
		public Double dayRate;
		public Double wkRate;
		public Double moRate;
		public Integer availQuantity;
		public Boolean isSerialized;
	}

	public class Data {
		public List<SuggestedItems> suggestedItems;
	}

	public class SpecGroups {
		public String specNumber;
		public String title;
		public String specDescription;
		public Double minPrice;
		public Double maxPrice;
		public List<Products> products;
	}

	
	public static SBR_3_0_API_ConsumablesResponse parse(String json) {
		return (SBR_3_0_API_ConsumablesResponse) System.JSON.deserialize(json, SBR_3_0_API_ConsumablesResponse.class);
	}
}