public with sharing class SBR_3_0_ResponseHandler {
        
        public String pc;
        public String currencyIsoCode ;
        public Date fromDate ;
        public String fromTime ;
        public Date toDate ;
        public String toTime ;
        public Decimal totalRoaChecksAmount ;
        public Decimal totalChecksAmount ;
        public Decimal nextDrawerAmount ;
        public Decimal startDrawerAmount ;
        public Date depositDate ;
        public Decimal cashSalesAmount;
        public String user ;
        public String postedToGL ;
        public DenominationDetails denominationDetails ;
        public List<ReasonDetail> reasonDetails ;
        public CreditCardDetails creditCardDetails ;

public class DenominationDetails {
    public Decimal hundredDollarBills;
    public Decimal fiftyDollarBills ;
    public Decimal twentyDollarBills ;
    public Decimal tenDollarBills ;
    public Decimal fiveDollarBills ;
    public Decimal twoDollarBills ;
    public Decimal oneDollarBills ;
    public Decimal oneDollarCoins ;
    public Decimal fiftyCents ;
    public Decimal quarters ;
    public Decimal dimes ;
    public Decimal nickels ;
    public Decimal pennies ;
}

public class ReasonDetail {
    public Decimal amount ;
    public String description ;
    public Decimal customerNumber ;
    public String note ;
    public String checkNumber ;
    public String reasonCode ;
}

public class CreditCardDetails {
    public Decimal amexAmount ;
    public Decimal amexRoaAmount ;
    public Decimal discoverAmount ;
    public Decimal discoverRoaAmount ;
    public Decimal masterCardAmount ;
    public Decimal masterCardRoaAmount ;
    public Decimal visaAmount ;
    public Decimal visaRoaAmount ;
    public Decimal dinersClubAmount ;
    public Decimal dinersClubRoaAmount ;
}
}