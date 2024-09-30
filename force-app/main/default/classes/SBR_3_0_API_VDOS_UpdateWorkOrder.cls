/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_VDOS_UpdateWorkOrder
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send WorkOrder to VDOS (via Mulesoft) when it is Updated in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Shubham Tunkikar        2023-10-31          Initial version
    2.0         Piyush Jindal           2023-12-01          Code cleanup and added comments and description
    3.0         Piyush Jindal           2023-12-02          Modified the endpoint API to accommodate WO insertion, updating, and deletion.
    4.0         Piyush Jindal           2023-12-05          Removed companyId from Request Payload and added pcNumber.
                                                            Renamed the request wrapper variable from startTimeUTC to startTime
    5.0         Piyush Jindal           2023-12-11          Added logic to assign value of SchedStartTime or ActualStartTime to startTime (attribute in Request payload).
    6.0         Piyush Jindal           2023-12-14          Added header param (pc) and removed request attribute (pcNumber)
    7.0         Piyush Jindal           2023-12-16          Assigned the value of OperatingHours.TimeZone to locationOffset attribute of Request Wrapper.
    8.0         Piyush Jindal           2024-01-25          Added a new attribute "sfGUID" in the request. This attribute stores the SF work order Id.
    9.0         Piyush Jindal           2024-05-17          Extracted RM WO Number from SF_PS_RM_WO_Number__c as this field stores the concatenation of Company Code and RM Work Order Number
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_VDOS_UpdateWorkOrder {
    private static final String VDOS_API_INSERT_WO = 'VDOS_API_Insert_Work_Order';
    private static final String VDOS_API_UPDATE_WO = 'VDOS_API_Update_Work_Order';
    private static final String VDOS_API_DELETE_WO = 'VDOS_API_Delete_Work_Order';
    private String vdosId = '';
    private String pcNumber = '';
    private String companyId = '';
    private Map<String, String> picklistValueToLabelMap = new Map<String, String>();
    private SBR_3_0_VDOS_UpdateWorkOrderWrapper.UpdateWorkOrderWrapperRequest workOrderWrapperRequest = new SBR_3_0_VDOS_UpdateWorkOrderWrapper.UpdateWorkOrderWrapperRequest();
    private SBR_3_0_VDOS_UpdateWorkOrderWrapper.UpdateWorkOrderWrapperResponse workOrderWrapperResponse = new SBR_3_0_VDOS_UpdateWorkOrderWrapper.UpdateWorkOrderWrapperResponse();
    private List<User> userDetails = new List<User> ();
    private WorkOrder objWorkOrder = new WorkOrder();
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static final String SEPARATOR_DASH = '-';

    /*********************************************************************************************************************
    * Purpose/Methods:
    * This is used to create Map of request header attributes.
    *********************************************************************************************************************/
    public Map<String, String> getHeadersMap {
        get {
            if(getHeadersMap == null) {
                getHeadersMap = new Map<String, String> {
                    'companyId'         => objWorkOrder.SF_PS_Company_Code__c,
                    'Content-Type'      => 'application/json',
                    'thresholdWaitTime' => '1',
                    'X-Correlation-ID'  => X_CORRELATION_ID,
                    'source'            => 'Salesforce'
                };
            }
            return getHeadersMap;
        }
        set;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Parameterised Constructor to assign values of Work Order to the Request Wrapper.
    *********************************************************************************************************************/
    public SBR_3_0_API_VDOS_UpdateWorkOrder(String workOrderId) {
        if(String.isNotBlank(workOrderId)) {
            //Fetch latest WO values from DB and populate objWorkOrder class attribute
            getLatestWO(workOrderId);

            //Check if objWorkOrder is not null
            if(this.objWorkOrder != null ) {
                System.debug('this.objWorkOrder.Status::'+this.objWorkOrder?.Status?.toLowerCase());
                // We dont want to send Request to VDOS for Scheduled WO status
                if(this.objWorkOrder?.Status?.toLowerCase() != 'scheduled'){
                    System.debug('Processing non scheduled status::'+this.objWorkOrder?.Status);
                    //This is invoked to create Request Wrapper (workOrderWrapperRequest)
                    populateRequestWrapper();
                }
            } else {
                //Throw an exception if status value do not match
                IllegalArgumentException error = new IllegalArgumentException();
                error.setMessage('WorkOrder not found for workOrderId:' + workOrderId);
                throw error;
            }
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Method is exposed to the Service Appointment Record Triggered Flow (SBR 3.0 ServiceAppointment After Create/Update Handler).
    * Params: input (List of Work Order Ids)
    *********************************************************************************************************************/
    @InvocableMethod(Label = 'WorkOrderUpdateVDOSCallout')
    public static void workOrderVDOSCallout(List<String> input) {
        if (!input.isEmpty() && !System.isFuture() && !System.isBatch()) {
            sendWorkOrderToVDOS(input);
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Prepare API Request using workOrderWrapperRequest Wrapper object and send to VDOS.
    * Params: lstWOId (List of Work Order Ids)
    *********************************************************************************************************************/
    @future(Callout = true)
    public static void sendWorkOrderToVDOS(List<Id> lstWOId) {
        if(!lstWOId.isEmpty()) {
            SBR_3_0_API_VDOS_UpdateWorkOrder objUpdateWO = new SBR_3_0_API_VDOS_UpdateWorkOrder(lstWOId[0]);

            if(objUpdateWO.pcNumber != null && objUpdateWO.companyId != null) {
                Boolean isThrowCustomException = false;
                String strCustomExceptionData  = '';

                try {
                    String endpointAPI = '';

                    // Modified the endpoint API to accommodate WO insertion, updation, and deletion.
                    if(String.isBlank(objUpdateWO.vdosId)) {
                        // Assigning endpoint for Insertion
                        endpointAPI = VDOS_API_INSERT_WO;
                    } else {
                        // Assigning endpoint for Updation or Deletion
                        endpointAPI = String.isNotBlank(objUpdateWO.workOrderWrapperRequest.workOrderStatus) && (
                            objUpdateWO.workOrderWrapperRequest.workOrderStatus.toLowerCase() == 'open' || 
                            objUpdateWO.workOrderWrapperRequest.workOrderStatus.toLowerCase() == 'cancelled' || 
                            objUpdateWO.workOrderWrapperRequest.workOrderStatus.toLowerCase() == 'canceled'
                        ) ? VDOS_API_DELETE_WO : VDOS_API_UPDATE_WO;
                    }

                    //Initialise callout class and pass APINAME class Attribute.
                    SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(endpointAPI);

                    //Set Header Params
                    objUpdateWO.getHeadersMap.put('pc', objUpdateWO.pcNumber); // additional header paramerter added
                    httpCallout.setHeadersMap(objUpdateWO.getHeadersMap);

                    //Get payload value to be send as a String Body.
                    String payload = JSON.serialize(objUpdateWO.workOrderWrapperRequest).replace('null', '""');

                    if( objUpdateWO.workOrderWrapperRequest.workOrderStatus.toLowerCase().contains('cancel') ||
                        (
                            objUpdateWO.workOrderWrapperRequest.workOrderStatus.toLowerCase() == 'open' && 
                            (String.isBlank(objUpdateWO.workOrderWrapperRequest.startTime) || objUpdateWO.workOrderWrapperRequest.startTime == '""')
                        )
                    ){
                        List<String> removableAttributes = new List<String>{'startTime', 'locationOffset'};
                        payload = SBR_3_0_API_VDOS_UpdateWorkOrder.removeAttributeFromSerializedData(payload, removableAttributes);
                    }

                    if(endpointAPI == VDOS_API_DELETE_WO){
                        List<String> removableAttributes = new List<String>{'sfGUID'};
                        payload = SBR_3_0_API_VDOS_UpdateWorkOrder.removeAttributeFromSerializedData(payload, removableAttributes);
                    }

                    //Set Request Body
                    httpCallout.setRequestBody(payload);
                    System.debug('payload:Request:'+ payload);
                    // Set objUpdateWO.vdosId in case of Updation or Deletion
                    if(objUpdateWO.vdosId != null && objUpdateWO.vdosId != '') {
                        httpCallout.setPathParams(new List<String>{objUpdateWO.vdosId});
                    }

                    //Initialize Request
                    HttpResponse res = httpCallout.sendRequest();

                    String returnPayload = res.getBody();
                    System.debug('returnPayload:Response::'+returnPayload);
                    if ((res.getStatusCode() == 200 || res.getStatus().toLowerCase() == 'ok') && String.isNotBlank(returnPayload)) {
                        //Check if returnPayload is not empty or null
                        SBR_3_0_VDOS_UpdateWorkOrderWrapper.ResponseWrapper responseDataWrapper = (SBR_3_0_VDOS_UpdateWorkOrderWrapper.ResponseWrapper)JSON.deserialize(returnPayload, SBR_3_0_VDOS_UpdateWorkOrderWrapper.ResponseWrapper.class);
                        SBR_3_0_VDOS_UpdateWorkOrderWrapper.UpdateWorkOrderWrapperResponse responseWrapper = objUpdateWO.populateReturnWrapper(JSON.serialize(responseDataWrapper.data));

                        if(String.isNotBlank(responseWrapper.vdosId) && String.isNotBlank(responseWrapper.rmWorkOrderId) && String.isBlank(responseWrapper.resultSetMsg)) {
                            // Sync VDOS Id with SF Workorder Order Line ID field
                            WorkOrder workOrder = objUpdateWO.syncToSF();
                        } else {
                            isThrowCustomException = true;
                            strCustomExceptionData = 'Request: ' + payload + ', Response: '+ JSON.serialize(responseWrapper);
                        }
                    } else {
                        isThrowCustomException = true;
                        strCustomExceptionData = 'Request: ' + payload + ', Response: ' + returnPayload + ', Server Error: '+ '{' + 'statusCode: ' + res.getStatusCode() + '}';
                    }

                    // Set error message and throw exception
                    if(isThrowCustomException == true) {
                        IllegalArgumentException error = new IllegalArgumentException();
                        error.setMessage(strCustomExceptionData);
                        throw error;
                    }
                } catch(Exception ex) {
                    // Log Exception
                    objUpdateWO.logException(ex);
                }
            } else {
                IllegalArgumentException error = new IllegalArgumentException();
                error.setMessage('SBR_3_0_API_VDOS_UpdateWorkOrder: callout unsuccessful. Error : PC Number or Company Id is missing on Work Order : '+objUpdateWO.objWorkOrder.WorkOrderNumber);
                objUpdateWO.logException(error);
            }
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Removes attribute from String and returns the updated String.
    *********************************************************************************************************************/
    public static String removeAttributeFromSerializedData (String serializedData, List<String> attributeList) {
        Map<String, Object> dataMap = (Map<String, Object>)JSON.deserializeUntyped(serializedData);

        for(String attribute : attributeList) {
            dataMap.remove(attribute);
        }

        return JSON.serialize(dataMap);
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Sync Response data received from VDOS.
    *********************************************************************************************************************/
    private WorkOrder syncToSF() {
        // This method is only invoked when vdosId in the returned Response has some value
        //Fetch WorkOrder record from SFDB
        Boolean updateWO = false;

        // SF_PS_RM_WO_Number__c field stores the value which is concatenation of company code and RM Work Order Number.
        String rmWorkOrderNumberStr = this.companyId + '-' + this.workOrderWrapperResponse.rmWorkOrderId;

        List<WorkOrder> lstWorkOrder = [SELECT Id, SF_PS_VDOS_OrderLine_External_Id__c, SF_PS_RM_WO_Number__c, SF_PS_Company_Code__c, Status,
                                        (SELECT Id, ActualStartTime, SchedStartTime, ActualEndTime, SchedEndTime, Status FROM ServiceAppointments)
                                        FROM WorkOrder
                                        WHERE SF_PS_RM_WO_Number__c = :rmWorkOrderNumberStr
                                        ORDER BY CreatedDate DESC];

        if(lstWorkOrder != null && !lstWorkOrder.isEmpty()) {
            if(lstWorkOrder[0].Status.toLowercase() == 'o' && String.isNotBlank(lstWorkOrder[0].SF_PS_VDOS_OrderLine_External_Id__c)) {
                updateWO = true;
                lstWorkOrder[0].SF_PS_VDOS_OrderLine_External_Id__c = null;
            } else if (lstWorkOrder[0].Status.toLowercase() != 'o' && lstWorkOrder[0].Status.toLowercase() != 'd' && (String.isBlank(lstWorkOrder[0].SF_PS_VDOS_OrderLine_External_Id__c) || (String.isNotBlank(lstWorkOrder[0].SF_PS_VDOS_OrderLine_External_Id__c) && lstWorkOrder[0].SF_PS_VDOS_OrderLine_External_Id__c != this.workOrderWrapperResponse.vdosId))){
                updateWO = true;
                lstWorkOrder[0].SF_PS_VDOS_OrderLine_External_Id__c = this.workOrderWrapperResponse.vdosId;
            }

            if(updateWO) {
                update lstWorkOrder[0];
            }

            return lstWorkOrder[0];
        } else {
            //Throw an exception if lstWorkOrder is empty.
            IllegalArgumentException error = new IllegalArgumentException();
            error.setMessage('Work Order does not exist for RM WO #:' + this.workOrderWrapperResponse.rmWorkOrderId);
            throw error;
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Fetch latest values and fields for WorkOrder object which are needed to be sent to VDOS.
    *********************************************************************************************************************/
    private void getLatestWO(String workOrderId) {
        List<WorkOrder> lstWorkOrder = new List<WorkOrder>();

        if(String.isNotBlank(workOrderId)) {
            lstWorkOrder = [SELECT Id, 
                                WorkOrderNumber, 
                                Status, 
                                SF_PS_RM_WO_Number__c, 
                                SF_PS_Company_Code__c, 
                                SF_PS_User_Company_Code__c, 
                                LastModifiedDate, 
                                CreatedBy.alias, 
                                SF_PS_VDOS_OrderLine_External_Id__c,
                                SF_PS_Service_Resource__r.Name, 
                                SF_PS_Service_Resource__r.SF_PS_Resource_Employee_Id__c,
                                ServiceTerritory.OperatingHours.Name, 
                                ServiceTerritory.OperatingHours.TimeZone, 
                                ServiceTerritory.Branch_Location_Number__c,
                                (SELECT Id, ActualStartTime, SchedStartTime, ActualEndTime, SchedEndTime, Status FROM ServiceAppointments)
                FROM WorkOrder
                WHERE Id =: workOrderId
            ];
        }

        if(lstWorkOrder != null && !lstWorkOrder.isEmpty()) {
            this.objWorkOrder = lstWorkOrder[0];
        } else {
            this.objWorkOrder = null;
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Create RequestWrapper from Work Order details.
    *********************************************************************************************************************/
    private void populateRequestWrapper() {
        this.picklistValueToLabelMap = new Map<String, String>(getPicklistFieldDetails('WorkOrder', 'Status'));
        this.userDetails = [SELECT Id, EmployeeNumber, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        //Calculate GMT Time for start time
        DateTime startTime = getCorrectStartEndTimeForStatus(this.objWorkOrder);

        this.vdosId    = this.objWorkOrder?.SF_PS_VDOS_OrderLine_External_Id__c;
        this.pcNumber  = this.objWorkOrder.ServiceTerritory?.Branch_Location_Number__c;
        this.companyId = this.objWorkOrder.SF_PS_Company_Code__c;

        this.workOrderWrapperRequest.rmWorkOrderId = String.isBlank(this.objWorkOrder.SF_PS_RM_WO_Number__c) ? this.objWorkOrder.SF_PS_RM_WO_Number__c : (
            this.objWorkOrder.SF_PS_RM_WO_Number__c.contains(SEPARATOR_DASH) ? this.objWorkOrder.SF_PS_RM_WO_Number__c.substringAfter(SEPARATOR_DASH) : this.objWorkOrder.SF_PS_RM_WO_Number__c
        );
        this.workOrderWrapperRequest.sfWorkOrderId  = this.objWorkOrder.WorkOrderNumber;
        this.workOrderWrapperRequest.technicianName = this.objWorkOrder.SF_PS_Service_Resource__r?.Name;
        this.workOrderWrapperRequest.locationOffset = this.objWorkOrder.ServiceTerritory?.OperatingHours.TimeZone;
        this.workOrderWrapperRequest.startTime      = (startTime != null ? (JSON.serialize(startTime)).replace('"', '') : null);
        this.workOrderWrapperRequest.clockId        = this.objWorkOrder.SF_PS_Service_Resource__r?.SF_PS_Resource_Employee_Id__c;
        this.workOrderWrapperRequest.slClockId      = this.userDetails[0]?.EmployeeNumber;
        this.workOrderWrapperRequest.sfGUID         = this.objWorkOrder.Id;
        // The label of Status field is being assigned to this.workOrderWrapperRequest.workOrderStatus with the exception of 'Canceled' being substituted with 'Cancelled' due to its mapping in VDOS.
        this.workOrderWrapperRequest.workOrderStatus = this.picklistValueToLabelMap.get(this.objWorkOrder.Status).toLowerCase() == 'canceled' ? 'Cancelled' : this.picklistValueToLabelMap.get(this.objWorkOrder.Status);
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Create Response Wrapper from returnPayload (Response received).
    * Params: returnPayload (Response received)
    *********************************************************************************************************************/
    private SBR_3_0_VDOS_UpdateWorkOrderWrapper.UpdateWorkOrderWrapperResponse populateReturnWrapper(String returnPayload) {
        this.workOrderWrapperResponse = (SBR_3_0_VDOS_UpdateWorkOrderWrapper.UpdateWorkOrderWrapperResponse)JSON.deserialize(returnPayload, SBR_3_0_VDOS_UpdateWorkOrderWrapper.UpdateWorkOrderWrapperResponse.class);

        return this.workOrderWrapperResponse;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Get startTime (for Request Payload) according to the Work Order Status.
    *********************************************************************************************************************/
    private DateTime getCorrectStartEndTimeForStatus(WorkOrder workOrder) {
        //Check Status value of Work Order
        switch on  workOrder.Status.toLowerCase() {
            when  'scheduled', 'dispatched', 'in route' {
                return workOrder?.ServiceAppointments[0]?.SchedStartTime;
            }
            when else {
                return workOrder?.ServiceAppointments[0]?.ActualStartTime != null ?
                        workOrder?.ServiceAppointments[0]?.ActualStartTime :
                        (
                            workOrder?.ServiceAppointments[0]?.SchedStartTime != null ?
                            workOrder?.ServiceAppointments[0]?.SchedStartTime : datetime.now()
                        );
            }
        }
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Log Exception - Create picklistValueToLabelMap
    * Params : objectAPIName and fieldAPIName
    *********************************************************************************************************************/
    private static Map<String, String> getPicklistFieldDetails(String objectAPIName, String fieldAPIName) {
        String objectName = objectAPIName;
        String fieldName = fieldAPIName;
        Map<String, String> valueToLabelMap = new Map<String, String>();

        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult sObjectResult = sObjectType.getDescribe() ;
        Map<String, Schema.SObjectField> fieldsMap = sObjectResult.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fieldsMap.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> picklistValuesList = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry pickListValue : picklistValuesList) {
            valueToLabelMap.put(pickListValue.getValue(), pickListValue.getLabel());
        }

        return valueToLabelMap;
    }

    /*********************************************************************************************************************
    * Purpose/Methods:
    * Log Exception - Create a record of Exception Log Object.
    *********************************************************************************************************************/
    private void logException(Exception ex) {
        // Handle any exceptions that occur during the update process.
        Map<String,String> exceptionParams = new Map<String,String>();
        exceptionParams.put('ClassName', 'SBR_3_0_API_VDOS_UpdateWorkOrder');
        exceptionParams.put('MethodName', 'sendWorkOrderToVDOS');
        exceptionParams.put('Type', ex.getTypeName());
        exceptionParams.put('LineNumber', String.valueOf(ex.getLineNumber()));
        exceptionParams.put('StackTrace', ex.getStackTraceString());
        exceptionParams.put('Message', ex.getMessage());
        PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);
    }
}