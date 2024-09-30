/*********************************************************************************************************************
* Apex Class: SBR_3_0_VDOS_UpdateWorkOrderWrapper
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Wrapper to send WorkOrder to VDOS (via Mulesoft) when it is Updated in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Shubham Tunkikar        2023-10-31          Initial version
    2.0         Piyush Jindal           2023-12-01          Updated startTimeUTC field to startTime
                                                            Added rmContractId and removed companyId from UpdateWorkOrderWrapperRequest
    3.0         Piyush Jindal           2023-12-05          Added pcNumber and removed rmContractId from UpdateWorkOrderWrapperRequest
    4.0         Piyush Jindal           2023-12-08          Added slClockId to capture Service Leader's Employee Id
    5.0         Piyush Jindal           2023-12-14          Removed pcNumber from UpdateWorkOrderWrapperRequest changed type of startTime from DateTime to String
    6.0         Piyush Jindal           2024-01-25          Added a new attribute "sfGUID" in the Wrapper.
*********************************************************************************************************************/
public with sharing class SBR_3_0_VDOS_UpdateWorkOrderWrapper {

    /*********************************************************************************************************************
    * Purpose/Methods:
    * This is used to create Resquest Wrapper
    *********************************************************************************************************************/
    public class UpdateWorkOrderWrapperRequest {
        public String rmWorkOrderId; //workOrderNumber; //SF_PS_RM_WO_Number__c // or WorkOrderNumber
        public String technicianName; //assignedServiceResource; // SF_PS_Service_Resource__r.Name
        public String locationOffset; // Time Zone offset
        public String startTime; //Service Appointment Scheduled Start Time or Actual Start Time depending upon the status
        public String clockId; // Technician Employee Id 
        public String slClockId; // Service Leader Employee Id 
        public String sfWorkOrderId;
        public String workOrderStatus;
        public String sfGUID;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * This is used to create Parent Response Wrapper
    *********************************************************************************************************************/
    public class ResponseWrapper {
        public UpdateWorkOrderWrapperResponse data;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * This is used to create Response Wrapper
    *********************************************************************************************************************/
    public class UpdateWorkOrderWrapperResponse {
        public String vdosId;
        public String companyId;
        public String rmWorkOrderId;
        public String sfWorkOrderId;
        public String resultSetMsg;
    }
    //Added below method as part of tech story FRONT-30843
    public static SBR_3_0_VDOS_UpdateWorkOrderWrapper parse(String json){
        return (SBR_3_0_VDOS_UpdateWorkOrderWrapper) System.JSON.deserialize(json, SBR_3_0_VDOS_UpdateWorkOrderWrapper.class);
    }
}