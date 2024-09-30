/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_EstimatesResponseWrapper
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Response Wrapper class for Estimates API
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel          2022-11-17             Initial version    
*********************************************************************************************************************/
public class SBR_3_0_API_EstimatesResponseWrapper {
    
    public String result;
	public Data data;
	public Error error;

    public class Data {
		public Estimate estimate;
	}

    public class Estimate {
		public ItemizedCharges itemizedCharges;
		public List<MiscCharges> miscCharges;
		public Totals totals;
		public OtherDetails otherDetails;
	}

	public class ItemizedCharges {
		public List<OrderLine> orderLines;
	}

	public class OrderLine {
		public List<Product> products;
		public List<SalesItem> salesItems;
	}

	public class Product {
		public String catId;
		public String classId;
		public String rentalCost;
		public String unitRentalCost;
		public String quantity;
		public String rentalTax;
		public String rentalTaxRate;
		public String rppCost;
		public String unitRPPCost;
		public String rppTax;
		public String rppTaxRate;
		public String isSerialized;
	}

	public class SalesItem {
		public String itemNumber;
		public String stockClass;
		public String unitPrice;
		public String totalPrice;
		public String salesTax;
		public String salesTaxRate;
		public String quantity;
		public String productSku;
	}

    public class MiscCharges {
		public String type;
		public Decimal charge;
		public Decimal tax;
		public Boolean taxExempt;
		public Boolean nonTaxable;
		public Decimal itemTaxRate;
		public String productSku;
	}    

    public class Totals {
		public Decimal rentalAmount;
		public Decimal rppCharges;
		public Decimal miscCharges;
		public Decimal finalTotal;
		public Decimal salesAmount;
		public Decimal salesTax;
	}

	public class OtherDetails {
		public Decimal distBetweenPCandSite;
		public String unitOfDistance;
	}
	
	public class Error {
		public String message;	//Active Cat/Class Not Found_115  /0001, please refer application logs for more details
		public String errorKey;	//INVALID_REQUEST_PAYLOAD
		public String errorCode;	//422-130
	}
}