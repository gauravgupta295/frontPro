public with sharing class SBR_3_0_WrapEstimates {
   
    public List<WorkOrder> workOrder;

    public class WorkOrder {
            public String majorRepair;
            public String workOrderDescription;
            public Integer laborCode;
            public String billTo;
            public String currencyCode;
            public String expenseToLocation;
            public String expenseCode;
            public String jobLocation;
            public String mechanicId;
            public Integer accountNumber;
            public String driverLicenseState;
            public String driverLicenseNumber;
            public String jobNumber;
            public String pONumber;
            public Decimal quotedLaborAmount;
            public List<InsideLabor> insideLabor;
            public List<OutsideLabor> outsideLabor;
            public Mileage mileage;
            public List<Parts> parts;
    }

    public class InsideLabor {
        public Decimal insideLaborHours;
        public Decimal insideLaborRate;
        public Integer laborCode;
        public String mechanicId;
        public String sourceReferenceLineNumber;
    }

    public class OutsideLabor {
        public Integer laborCode;
        public Decimal outsideLaborCost;
        public Decimal outsideLaborPrice;
        public String outsideLaborPoNumber;
        public String sourceReferenceLineNumber;
    }

    public class Mileage {
        public Integer laborCode;
        public Decimal mileageMiles;
        public Decimal mileageRate;
        public String sourceReferenceLineNumber;
    }

    public class Parts {
        public Decimal cost;
        public Decimal discountPercent;
        public String itemNumber;
        public Integer laborCode;
        public Decimal quantity;
        public Decimal sellingPrice;
        public String sourceReferenceLineNumber;
        public String stockClass;
        public String unitOfMeasure;
    }
}