/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Web_ResourceAbsence_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class to cover test cases for SBR_3_0_API_Web_ResourceAbsence
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Shubham Tunkikar        2023-11-15          Initial version
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
*
*********************************************************************************************************************/
@isTest()
public class SBR_3_0_API_Web_ResourceAbsence_Test {
	@testSetup
    Public static void testSetupMethod()
    {
        //SOQL Dispatcher PSG
        List<PermissionSetGroup> dispatcherPSGList = [SELECT Id,Status,DeveloperName FROM PermissionSetGroup WHERE DeveloperName = 'Dispatcher'];
        //Update employeeId on loggedin user
        User loggedinUser = new User();
        loggedinUser.Id = UserInfo.getUserId();
        loggedinUser.EmployeeNumber = '222';
        Update loggedinUser;

        if(!dispatcherPSGList.isEmpty())
        {
            PermissionSetGroup psg = dispatcherPSGList[0];
            //SOQL PermissionSetAssignment to check if PermissionSetAssignment for Dispatcher PSG
            if (psg.Status != 'Updated') {
                Test.calculatePermissionSetGroup(psg.Id);
            }
            List<PermissionSetAssignment> psaList = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetGroupId =: psg.Id AND AssigneeId =: loggedinUser.Id];
            if(psaList.isEmpty())
            {
                System.Debug('psaList:Not Found:');
                //Assign PSG to user, Create Assignment.
                PermissionSetAssignment assignment = new PermissionSetAssignment(
                    PermissionSetGroupId = psg.Id,
                    AssigneeId = loggedinUser.Id
                );
                Insert assignment;
            }
        }
    }

    /**
     * Need to add it as we can not add a non-setup object if we are inserting a setup object in same Synchronous context.
     * So could not run it from testSetup, and had to run it from each method.
     */
    public static void insertServiceResource()
    {
        //Create Resource with loggedin user
        ServiceResource serviceResource = SBR_3_0_ServiceTestDataFactory.create_Service_Resource(False);
        serviceResource.RelatedRecordId = UserInfo.getUserId();
        insert serviceResource;
    }

    /**
     * @description| Get Absence Wrapper for upsert operation
     */
    Public static SBR_3_0_ResourceAbsenceRequestWrapper.AbsenceWrapper getAbsenceWrapper()
    {
        SBR_3_0_ResourceAbsenceRequestWrapper.AbsenceWrapper aw = new SBR_3_0_ResourceAbsenceRequestWrapper.AbsenceWrapper();
        aw.workdayId= '712';
        aw.objectName = 'absence';
        aw.employeeId = '222';
        aw.firstDayOfLeave = Date.Today();//DateTime.Now();
        aw.lastDayOfLeave = Date.Today();//DateTime.Now();
        aw.lastDayOfLeave.addDays(1);
        aw.status = 'Successfully completed';
        return aw;
    }

    /**
     * @description| Get Absence Wrapper for duplicate and fail case
     */
    Public static SBR_3_0_ResourceAbsenceRequestWrapper.AbsenceWrapper getAbsenceWrapperException()
    {
        SBR_3_0_ResourceAbsenceRequestWrapper.AbsenceWrapper aw = new SBR_3_0_ResourceAbsenceRequestWrapper.AbsenceWrapper();
        aw.workdayId= '712';
        aw.objectName = 'absence';
        aw.employeeId = '222';
        aw.firstDayOfLeave = Date.Today();//DateTime.Now();
        aw.lastDayOfLeave = Date.Today();//DateTime.Now();
        aw.lastDayOfLeave.addDays(1);
        aw.status = 'Successfully completed';
        return aw;
    }

    /**
     * @description| Get Absence Wrapper for delete operation
     */
    Public static SBR_3_0_ResourceAbsenceRequestWrapper.AbsenceWrapper getAbsenceWrapperDelete()
    {
        SBR_3_0_ResourceAbsenceRequestWrapper.AbsenceWrapper aw = new SBR_3_0_ResourceAbsenceRequestWrapper.AbsenceWrapper();
        aw.workdayId= '71266';
        aw.objectName = 'absence';
        aw.employeeId = '222';
        aw.firstDayOfLeave = Date.Today();
        aw.lastDayOfLeave = Date.Today();
        aw.lastDayOfLeave.addDays(1);
        aw.status = 'canceled';
        return aw;
    }

    /**
     * @description| Get TimeOff Wrapper for upsert operation
     */
    public static SBR_3_0_ResourceAbsenceRequestWrapper.TimeOffWrapper getTimeOffWrapper()
    {
        SBR_3_0_ResourceAbsenceRequestWrapper.TimeOffWrapper tw = new SBR_3_0_ResourceAbsenceRequestWrapper.TimeOffWrapper();
        tw.workdayId = '4712';
        tw.objectName = 'timeoff';
        tw.employeeId = '222';
        tw.timeOffDate = DateTime.Now();
        tw.status = 'Successfully completed';
        tw.lastDayOfLeave = Date.Today();
        tw.lastDayOfLeave.addDays(1);
        tw.timeOffTime = 6;
        return tw;
    }

    /**
     * @description| Get Absence Wrapper for delete operation
     */
    public static SBR_3_0_ResourceAbsenceRequestWrapper.TimeOffWrapper getTimeOffWrapperDelete()
    {
        SBR_3_0_ResourceAbsenceRequestWrapper.TimeOffWrapper tw = new SBR_3_0_ResourceAbsenceRequestWrapper.TimeOffWrapper();
        tw.workdayId = '47123';
        tw.objectName = 'timeoff';
        tw.employeeId = '222';
        tw.timeOffDate = DateTime.Now();
        tw.status = 'Successfully completed';
        tw.lastDayOfLeave = Date.Today();
        tw.lastDayOfLeave.addDays(1);
        tw.timeOffTime = -6;
        return tw;
    }

    public static void insertResourceAbsence()
    {
        //SOQL Service Resource
        List<ServiceResource> lstResource = [SELECT Id FROM ServiceResource];
        List<ResourceAbsence> lstAbsence = new List<ResourceAbsence>();
        ResourceAbsence absence = new ResourceAbsence();
        absence.ResourceId = lstResource[0].Id;
        absence.Type = SBR_3_0_Constants.ABSENCE_TYPE_VACATION;
        absence.Start = DateTime.Now();
        absence.End = DateTime.Now();
        absence.End = absence.End.addDays(2);
        absence.SF_PS_Resource_Absence_Key__c = '71266';
        absence.FSL__Approved__c = true;
        absence.SF_PS_TimeOffUnits__c = 3;
        absence.SF_PS_Resource_Absence_Status__c = 'Successfully completed';
        lstAbsence.add(absence);

        ResourceAbsence absence2 = new ResourceAbsence();
        absence2.ResourceId = lstResource[0].Id;
        absence2.Type = SBR_3_0_Constants.ABSENCE_TYPE_VACATION;
        absence2.Start = DateTime.Now();
        absence2.End = DateTime.Now();
        absence2.End = absence.End.addDays(2);
        absence2.SF_PS_Resource_Absence_Key__c = '47123';
        absence2.FSL__Approved__c = true;
        absence2.SF_PS_TimeOffUnits__c = 3;
        absence2.SF_PS_Resource_Absence_Status__c = 'Successfully completed';
        lstAbsence.add(absence2);
        insert lstAbsence;
    }
    /**
     * @description| Check API method for success case
     */
    @isTest()
    public static void upsertAbsence()
    {
		insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        insertServiceResource();
        //Create SBR_3_0_ResourceAbsenceRequestWrapper
		SBR_3_0_ResourceAbsenceRequestWrapper objAbsenceWrapper = new SBR_3_0_ResourceAbsenceRequestWrapper();
        List<SBR_3_0_ResourceAbsenceRequestWrapper.BaseResourceAbsenceWrapper> lstBaseWrapper = new List<SBR_3_0_ResourceAbsenceRequestWrapper.BaseResourceAbsenceWrapper>();
        lstBaseWrapper.add(getAbsenceWrapper());
        lstBaseWrapper.add(getTimeOffWrapper());
		String strBody = JSON.Serialize(lstBaseWrapper);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/ResourceAbsence/ApiCreate/v1';
        req.requestBody = Blob.valueof(strBody);
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        SBR_3_0_API_Web_ResourceAbsence.upsertAbsence();
        Test.stopTest();
    }

    /**
     * @description| Check API method for Failure case
     */
    @isTest()
    public static void upsertAbsenceException()
    {
		insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        insertServiceResource();
        //Create SBR_3_0_ResourceAbsenceRequestWrapper
		SBR_3_0_ResourceAbsenceRequestWrapper objAbsenceWrapper = new SBR_3_0_ResourceAbsenceRequestWrapper();
        List<SBR_3_0_ResourceAbsenceRequestWrapper.BaseResourceAbsenceWrapper> lstBaseWrapper = new List<SBR_3_0_ResourceAbsenceRequestWrapper.BaseResourceAbsenceWrapper>();
        lstBaseWrapper.add(getAbsenceWrapper());
        lstBaseWrapper.add(getAbsenceWrapperException());
        lstBaseWrapper.add(getTimeOffWrapper());
		String strBody = JSON.Serialize(lstBaseWrapper);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/ResourceAbsence/ApiCreate/v1';
        req.requestBody = Blob.valueof(strBody);
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        SBR_3_0_API_Web_ResourceAbsence.upsertAbsence();
        Test.stopTest();
    }

	@isTest()
    public static void deleteAbsence()
    {
		insert new Bypass_Settings__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Flow__c=true);
        //Insert Resource
        insertServiceResource();
        //Insert Absence
        insertResourceAbsence();
        //Create SBR_3_0_ResourceAbsenceRequestWrapper
		SBR_3_0_ResourceAbsenceRequestWrapper objAbsenceWrapper = new SBR_3_0_ResourceAbsenceRequestWrapper();
        List<SBR_3_0_ResourceAbsenceRequestWrapper.BaseResourceAbsenceWrapper> lstBaseWrapperDelete = new List<SBR_3_0_ResourceAbsenceRequestWrapper.BaseResourceAbsenceWrapper>();
        lstBaseWrapperDelete.add(getAbsenceWrapperDelete());
        lstBaseWrapperDelete.add(getTimeOffWrapperDelete());
        String strBodyDelete = JSON.Serialize(lstBaseWrapperDelete);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/ResourceAbsence/ApiCreate/v1';
        req.requestBody = Blob.valueof(strBodyDelete);
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
            SBR_3_0_API_Web_ResourceAbsence.upsertAbsence();
            // Trying to delete the record again should send a error response.
            SBR_3_0_API_Web_ResourceAbsence.upsertAbsence();
        Test.stopTest();
    }
}