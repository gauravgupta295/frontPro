/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateWOAsset
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Wrapper Class for Creating Work Order Quote with Customer Owned Asset
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0             Harry Rokad        2023-12-04             Initial version
*********************************************************************************************************************/
public with sharing class SBR_3_0_WrapWOQuoteAsset {

    public List<WorkOrderQuote> workOrderQuote;

    public class CustomerOwnedAsset {
        public String equipmentDescription;
        public String make;
        public String model;
        public String serialNumber;
        public String category;
        public String classId;
        public Double subClass;
        public String modelYear;
        public Boolean serviceMaintenanceContractFlag;
        public String milesHoursCode;
        public String ownedEquipmentStatus;
        public String updatedInSF;
        public String currentMilesHour;
    }

    public class workOrderQuote {
        public String driverLicenseState;
        public String driverLicenseNumber;
        public String jobNumber;
        public String poNumber;
        public String equipmentDescription;
        public Long phoneNumber;
        public Integer salesRepresentativeId;
        public String marketSegmentCode;
        public String equipmentNumber;
        public String estimatedCompletionDate;
        public String openedDateTime;
        public String majorRepair;
        public String workOrderDescription;
        public String complaint;
        public String cause;
        public String cure;
        public Integer laborCode;
        public String billTo;
        public String currencyCode;
        public String expenseToLocation;
        public String expenseCode;
        public String jobLocation;
        public String authorizedBy;
        public String serviceCall;
        public Long repairTicketNumber;
        public String warrantyCode;
        public String claimNumber;
        public String dateClaimFiled;
        public Double warrantyAmount;
        public String warrantyExpiryDate;
        public String warrantyPaid;
        public Double currentMiHr;
        public Double currentMiHr2;
        public String mechanicId;
        public Integer accountNumber;
        public String internalComments;
        public String externalComments;
        public String updateMeter;
        public String replaceMeter;
        public String miHrCode;
        public CustomerOwnedAsset customerOwnedAsset;
    }

    public class WrappedResponse{
        //System.debug('woToSend is '+ woToSend);
        public string workOrderQuoteNumber{get;set;}
        //public string mode{get;set;} 
       // public string message;
        public string body{get;set;}
       // public string status{get;set;} 
        public list<String> headers{get;set;}
       // public list<WorkOrderLineItem> workOrderLineItems{get;set;}
    }

}