public with sharing class SBR_3_0_WrapWorkOrder {
    public String timestamp; // WO.LastModifiedDate
    public String user; // First and Last Name of the User
    public String systemName; //Salesforce
    public String rentalmanUser; // User.Wynn_Name__c
    public String salesforceWorkOrderNumber; //SF_PS_RM_WO_Number__c
    public String salesforceWorkOrderLineNumber;
    public List<WorkOrder> workOrder;

    public class WorkOrder{
        public String companyCode; // SF_PS_Company_Code__c
        public String jobNumber; // SF_PS_Job_Site__r.Job_Number__c 
        public String accountNumber; //Account.RM_Account_Number__c
        public String locationCode; // ServiceTerritory.Branch_Location_Number__c
        public String equipmentNumber;  // Asset.SM_PS_Asset_Id__c
        public String expenseToLocation; // SF_PS_Expense_To_Location__r.Branch_Location_Number__c
        public String salesRep; // SF_PS_Sales_Rep__r.RepID__c
        public String mechanic; // SF_PS_Service_Resource__r.SF_PS_Mechanic_Id__c
        public String estimatedCompletionDate; // SF_PS_Due_Date__c
        public String majorRepair; // SF_PS_Major_Repair__c
        public String workOrderDescription;// SF_PS_Work_Order_Des__c
        public String descriptionOfProblem; // SF_PS_Complaint__c
        public String laborCode; // SF_PS_LaborCode__c
        public String currencyCode; // CurrencyIsoCode
        

        public String expenseCode; // SF_PS_ExpenseCode__c
        public String jobLocation; // SF_PS_Job_Location__c
        

        public String pONumber; // SF_PS_PONumber__c
        public String dlNumber; // SF_PS_Drivers_License_Number__c
        public String serialNumber; //SF_PS_Serial_Number__c
        public String phoneNumber; // SVMXA360__ContactPhone__c
        public String openedDate; // SF_PS_Date_Opened__c

        public String authorizedBy; // SF_PS_Authorized_By__c
        public String servicecall; // SF_PS_Service_Call__c
        public Double repairTicketNumber; // SF_PS_Repair_Ticket__c
        public String creationTimestamp; // CreatedDate
        public Double currentMiHr; // SF_PS_Current_MiHr__c
        public Double currentMiHr2; // SF_PS_Current_MiHr2__c
        public String marketSegment; //	SF_SP_Market_Segment__c
    }
    //Added for FRONT-30844
    public static SBR_3_0_WrapWorkOrder parse(String json){
        return (SBR_3_0_WrapWorkOrder) System.JSON.deserialize(json, SBR_3_0_WrapWorkOrder.class);
    }
}