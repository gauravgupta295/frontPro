public with sharing class SBR_3_0_WrapPayment {
    public class AdditionalDeposits {
        public String currencyIsoCode;
        public Decimal depositAmount;
        public String lane;
        public String pc;
        public String depositType;
        public String checkNumber;
        public Boolean usePreviousCard;
    }
    public class UCPDeposits {
        public String currencyIsoCode;
        public Decimal depositAmount;
        public String lane;
        public String pc;
        public String depositType;
        public String checkNumber;
        public Boolean usePreviousCard;
        public Decimal invSeqNumber;
    }
    public class ROADeposits {
        public String pc;
        public String paymentType;
        public String currencyIsoCode;
        public String laneNumber;
        public Decimal paymentAmount;
        public String checkNumber;
        public List<Payment> payments;
    }
  
    public class Payment {
        public Decimal paymentAmount;
        public String comment;
        public String sfReferenceNumber;
    }
}