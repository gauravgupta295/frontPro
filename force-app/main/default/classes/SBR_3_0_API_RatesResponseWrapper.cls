public class SBR_3_0_API_RatesResponseWrapper {


	public class SuggestedRates {
		public String minimum;
		public String daily;
		public String weekly;
		public String monthly;
	}

	public class Rates {
		public SuggestedRates suggestedRates;
		public SuggestedRates bookRates;
	}

	public Data data;

	public class Items {
		public String productId;
		public String pc;
		public String rateFlag;
		public String rateFlagDescription;
		public String notToExceed;
		public String notToExceedDescription;
		public String rppPercentage;
		public String needPassword;
		public String showAllRates;
		public String suggestMinimalHours;
		public String isConsumerCatClass;
		public String isSerialized;
		public String customerDiscountPercentageDaily;
		public String customerDiscountPercentageWeekly;
		public String customerDiscountPercentageMonthly;
		public String showFloorRate;
		public Rates rates;
	}

	public class Data {
		public String errorCode;
		public String errorDesc;
		public String company;
		public String accountNumber;
		public String jobsiteName;
		public List<Items> items;
	}

}