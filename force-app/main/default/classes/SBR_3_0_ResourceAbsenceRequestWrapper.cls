/*********************************************************************************************************************
* Apex Class: SBR_3_0_ResourceAbsenceRequestWrapper
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Wrapper Class for Resource Absence Workday API
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Shubham Tunkikar        2023-11-15          Initial version
    2.0         Shubham Tunkikar        2024-06-17          Added ABSENCE_CORRECTED status
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
*
*********************************************************************************************************************/
public with sharing class SBR_3_0_ResourceAbsenceRequestWrapper
{
    /** Wrapper Properties Declaration*/
    public List<BaseResourceAbsenceWrapper> lstBaseWrapper;
    private List<AbsenceWrapper> lstAbsence;
    private Map<String, AbsenceWrapper> mapAbsence = new Map<String, AbsenceWrapper>();
    private List<TimeOffWrapper> lstTimeOff;
    private Map<String, TimeOffWrapper> mapTimeOff = new Map<String, TimeOffWrapper>();
    private Map<String,Id> mapExternalToResourceId = new Map<String,Id>();
    private List<String> lstExternalIdToDelete = new List<String>();
    private static final Id ABSENCE_RECORD_TYPE_ID = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByDeveloperName().get('Non_Availability').getRecordTypeId();
    /** Wrapper Properties Declaration*/


    /**Non parameterised constructor */
    public SBR_3_0_ResourceAbsenceRequestWrapper(){}

    /**
     * @description| Constructod definition, Pass Request data as String/Serialised to convert it as List<BaseResourceAbsenceWrapper> format.
     */
    public SBR_3_0_ResourceAbsenceRequestWrapper(String data)
    {
        //Instentiate mapExternalToResourceId
        mapExternalToResourceId = new Map<String,Id>();
        //Instentiate lstBaseWrapper
        lstBaseWrapper = new List<BaseResourceAbsenceWrapper>();
        if(String.isNotBlank(data))
        {
            List<Object> lstWrappers = (List<Object>)JSON.deserializeUntyped(data);
            if(!lstWrappers.isEmpty())
            {
                // Convert data to Wrapper lists
                convertToWrapperList(lstWrappers);
            }
        }
    }

    /**
     * @description| Returns List<ServiceResource> for External Ids passed from Workday as Workday Id.
     */
    public void getServiceResources(List<String> lstResourceExternalIds)
    {
		List<ServiceResource> lstResource = new List<ServiceResource>();
		if(!lstResourceExternalIds.isEmpty())
		{
			lstResource = [SELECT Id, RelatedRecord.EmployeeNumber FROM ServiceResource Where RelatedRecord.EmployeeNumber IN: lstResourceExternalIds];
            // [SELECT Id, External_Id__c FROM ServiceResource WHERE External_Id__c IN: lstResourceExternalIds];
            for(ServiceResource resource: lstResource)
            {
                mapExternalToResourceId.put(resource.RelatedRecord.EmployeeNumber, resource.Id);
            }
		}
	}

    /**
     * @description| getter function for Absence list Wrapper
     */
    public List<AbsenceWrapper> getAbsenceList()
    {
        return lstAbsence.isEmpty() ? null : lstAbsence;
    }

    /**
     * @description| getter function for TimeOff list Wrapper
     */
    public List<TimeOffWrapper> gettimeOffList()
    {
        return lstTimeOff.isEmpty() ? null : lstTimeOff;
    }

    public List<String> getExternalIdsToDelete()
    {
        if(!lstExternalIdToDelete.isEmpty())
        {
            return lstExternalIdToDelete;
        }
        return null;
    }

    /**
     * @description| Converts lstAbsence and  lstTimeOff to single SObject List lstResourceAbsence.
     */
    public Map<String,List<ResourceAbsence>> convertToSobjectList()
    {
        List<ResourceAbsence> lstResourceAbsence = new List<ResourceAbsence>();
        List<ResourceAbsence> lstAbsenceToDelete = new List<ResourceAbsence>();
        Map<String,List<ResourceAbsence>> mapResourceAbsenceOperations = new Map<String,List<ResourceAbsence>>();
        //check if lstAbsence Empty
        if(!lstAbsence.isEmpty())
        {
            //Iterate over list to get single value.
            for(AbsenceWrapper absence : lstAbsence)
            {
                switch on absence.getStatusAction() {
                    when 'upsert' {
                        //Add record to upsert list
                        lstResourceAbsence.add(absence.getSObjectRecord(absence, mapExternalToResourceId));
                    }
                    when 'delete' {
                        //Add record to delete list
                        lstAbsenceToDelete.add(absence.getSObjectRecord(absence, mapExternalToResourceId));
                        lstExternalIdToDelete.add(absence.workdayId);
                    }
                    when else {
                        //Throw an exception if status value do not match
                        IllegalArgumentException error = new IllegalArgumentException();
                        error.setMessage('Invalid Value for Status: '+absence.status);
                        throw error;
                    }
                }
            }
        }
        //check if lstTimeOff Empty
        if(!lstTimeOff.isEmpty())
        {
            //Iterate over list to get single value.
            for(TimeOffWrapper timeOff : lstTimeOff)
            {
                switch on timeOff.getStatusAction() {
                    when 'upsert' {
                        //Add record to upsert list
                        lstResourceAbsence.add(timeOff.getSObjectRecord(timeOff, mapExternalToResourceId));
                    }
                    when 'delete' {
                        //Add record to delete list
                        lstAbsenceToDelete.add(timeOff.getSObjectRecord(timeOff, mapExternalToResourceId));
                        lstExternalIdToDelete.add(timeOff.workdayId);
                    }
                    when else {
                        //Throw an exception if status value do not match
                        IllegalArgumentException error = new IllegalArgumentException();
                        error.setMessage('Invalid Value for Status: '+timeOff.status);
                        throw error;
                    }
                }
            }
        }

        //If lstResourceAbsence has values then add list to mapResourceAbsenceOperations, and mark it as upsert.
        if(!lstResourceAbsence.isEmpty())
        {
            mapResourceAbsenceOperations.put('upsert',lstResourceAbsence);
        }
        //If lstAbsenceToDelete has values then add list to mapResourceAbsenceOperations, and mark it as delete.
        if(!lstAbsenceToDelete.isEmpty())
        {
            mapResourceAbsenceOperations.put('delete',lstAbsenceToDelete);
        }
        // return mapResourceAbsenceOperations.
        return mapResourceAbsenceOperations;
    }

    /**
     * @description| Converts Request data to list of child wrappers AbsenceWrapper/TimeOffWrapper
     */
    private void convertToWrapperList(List<Object> lstWrappers)
    {
        //Instenciate private lists
        lstAbsence = new List<AbsenceWrapper>();
        lstTimeOff = new List<TimeOffWrapper>();
        List<String> lstExternalId = new List<String>();
        //Loop through Wrappers list received in request.
        for(Object objWrapper : lstWrappers)
        {
            //Convert single record to Map
            Map<String, Object> record = (Map<String, Object>)objWrapper;
            //Get Name of the record object
            String objectName = (String)record.get('objectName');
            //Store employeeId in a list in order to retrieve service resource FROM SOQL.
            lstExternalId.add((String)record.get('employeeId'));
            //Add records to list based on objectName absence/timeoff
            switch on objectName.toLowerCase() {
                when 'absence' {
                    AbsenceWrapper objAbsence = (AbsenceWrapper)JSON.deserialize(JSON.serialize(record), AbsenceWrapper.class);
                    lstAbsence.add(objAbsence);
                    mapAbsence.put(objAbsence.workdayId, objAbsence);
                }
                when 'timeoff' {
                    //If lastDayOfLeave comes as '' empty string make it null so it wont throw an Exception while converting to DateTime.
                    if(record.get('lastDayOfLeave') != null && (String)record.get('lastDayOfLeave') == '')
                    {
                        record.put('lastDayOfLeave', null);
                    }
                    TimeOffWrapper objTimeOff = (TimeOffWrapper)JSON.deserialize(JSON.serialize(record), TimeOffWrapper.class);
                    lstTimeOff.add(objTimeOff);
                    mapTimeOff.put(objTimeOff.workdayId, objTimeOff);
                }
                when else {
                    //Throw an exception for mismatch object name
                    //Throw an exception if condition is true
                    IllegalArgumentException error = new IllegalArgumentException();
                    error.setMessage('Invalid value in field objectName: ' + objectName);
                    throw error;
                }
            }
        }

        //Call getServiceResources method to populate mapExternalToResourceId
        getServiceResources(lstExternalId);
    }

    /**
     * @description| Using List<ResourceAbsence> populate List<BaseResourceAbsenceWrapper> to return as API response.
     */
    public List<BaseResourceAbsenceWrapper> getWrapperRecordsToReturn(List<ResourceAbsence> lstResourceAbsenceObj)
    {
        //List<AbsenceWrapper> lstAbsenceWrapper = new List<AbsenceWrapper>();
        for(ResourceAbsence absence : lstResourceAbsenceObj)
        {
            //lstAbsenceWrapper.add(new AbsenceWrapper().getWrapperFromSObject(absence));
            //Add TimeOff Or Absence Wrapper records to lstBaseWrapper
            if(mapAbsence.containsKey(absence.SF_PS_Resource_Absence_Key__c))
            {
                lstBaseWrapper.add(getAbsenceRecordToReturn(absence, mapAbsence.get(absence.SF_PS_Resource_Absence_Key__c)));
            }
            if(mapTimeOff.containsKey(absence.SF_PS_Resource_Absence_Key__c))
            {
                lstBaseWrapper.add(getTimeOffRecordToReturn(absence, mapTimeOff.get(absence.SF_PS_Resource_Absence_Key__c)));
            }
        }
        return lstBaseWrapper;
    }

    private AbsenceWrapper getAbsenceRecordToReturn(ResourceAbsence absence, AbsenceWrapper oldAbsenceObj)
    {
        AbsenceWrapper objAbsence = new AbsenceWrapper().getWrapperFromSObject(absence);
        objAbsence.status = oldAbsenceObj.status;
        objAbsence.employeeId = oldAbsenceObj.employeeId;
        return objAbsence;
    }

    private TimeOffWrapper getTimeOffRecordToReturn(ResourceAbsence absence, TimeOffWrapper oldTimeOffObj)
    {
        TimeOffWrapper objTimeOff = new TimeOffWrapper().getWrapperFromSObject(absence);
        objTimeOff.timeOffTime = oldTimeOffObj.timeOffTime;
        objTimeOff.status = oldTimeOffObj.status;
        objTimeOff.employeeId = oldTimeOffObj.employeeId;
        return objTimeOff;
    }

    /** Supporting Wrapper Classes */
    public virtual class BaseResourceAbsenceWrapper
    {
        public String sfId;
        public String workdayId;
        public String objectName;
        public String employeeId;
        public String status;
        public String resourceSFId;
        public Datetime lastDayOfLeave; // Optional
        /**
         * @description| Placeholder to Populate common data for ResourceAbsence.
         */
        public ResourceAbsence populateCommonData(ResourceAbsence sfAbsence)
        {
            //If Start Hours are not populated, Populate it with default Value
            if(sfAbsence.Start.hourGmt() <= 0 && sfAbsence.Start.minuteGmt() <= 0 && sfAbsence.Start.secondGmt() <= 0)
            {
                //Time defaultStartTime = Time.newInstance(SBR_3_0_Constants.ABSENCE_START_TIME_HOURS, SBR_3_0_Constants.ABSENCE_START_TIME_MINUTES, 0, 0);
                sfAbsence.Start = sfAbsence.Start.addHours(SBR_3_0_Constants.ABSENCE_START_TIME_HOURS);
                sfAbsence.Start = sfAbsence.Start.addMinutes(SBR_3_0_Constants.ABSENCE_START_TIME_MINUTES);
            }
            //If End Hours are not populated, Populate it with default Value
            if(sfAbsence.End.hourGmt() <= 0 && sfAbsence.End.minuteGmt() <= 0 && sfAbsence.End.secondGmt() <= 0)
            {
                //Time defaultEndTime = Time.newInstance(SBR_3_0_Constants.ABSENCE_END_TIME_HOURS, SBR_3_0_Constants.ABSENCE_END_TIME_MINUTES, 0, 0);
                sfAbsence.End = sfAbsence.End.addHours(SBR_3_0_Constants.ABSENCE_END_TIME_HOURS);
                //As a correction of GMT to EST We need to add 4 hours more in order to make it correct upto EST TimeZone.
                sfAbsence.End = sfAbsence.End.addHours(4);
                sfAbsence.End = sfAbsence.End.addMinutes(SBR_3_0_Constants.ABSENCE_END_TIME_MINUTES);
            }
            return sfAbsence;
        }
    }

    public class AbsenceWrapper extends BaseResourceAbsenceWrapper
    {
        public Datetime firstDayOfLeave;
        /**
         * @description| Method to convert wrapper back to SObject record of ResourceAbsence.
         */
        public ResourceAbsence getSObjectRecord(AbsenceWrapper abs, Map<String,Id> mapExternalToResourceId)
        {
            if(abs != null)
            {
                //set AbsenceWrapper ResourceSFId, So we can use it while populating Master-detail on absence.
                abs.resourceSFId = mapExternalToResourceId.get(abs.employeeId);
                //Populate ResourceAbsence record.
                ResourceAbsence absence = new ResourceAbsence();
                absence.ResourceId = abs.resourceSFId;//abs.employeeId;//abs.resourceSFId;
                absence.Type = SBR_3_0_Constants.ABSENCE_TYPE_VACATION;
                absence.Start = abs?.firstDayOfLeave;
                absence.End = abs?.lastDayOfLeave;
                absence.SF_PS_Resource_Absence_Key__c = abs.workdayId;
                absence.FSL__Approved__c = true;
                absence.SF_PS_Resource_Absence_Status__c = abs.status;
                absence.RecordTypeId = SBR_3_0_ResourceAbsenceRequestWrapper.ABSENCE_RECORD_TYPE_ID;
                absence = abs.populateCommonData(absence);
                return absence;
            }
            return null;
        }

        /**
         * @description| Convert SObject ResourceAbsence to TimeOffWrapper type.
         */
        private AbsenceWrapper getWrapperFromSObject(ResourceAbsence absence)
        {
            //Instentiate the wrapper.
            AbsenceWrapper wrapperObj = new AbsenceWrapper();
            wrapperObj.objectName = 'absence';
            wrapperObj.workdayId = absence.SF_PS_Resource_Absence_Key__c;
            wrapperObj.resourceSFId = absence.ResourceId;
            wrapperObj.firstDayOfLeave = absence.Start;
            wrapperObj.lastDayOfLeave = absence.End;
            wrapperObj.sfId = absence.Id;
            return wrapperObj;
        }

        /**
         * @description| Returns action to be perform for a specific Status on Absence or on TimeOff.
         */
        public String getStatusAction()
        {
            //if status is null/blank/white space return exception action.
            if(String.isBlank(status))
            {
                return 'exception';
            }
            //For status == Correction/Complete/Approved return upsert action
            else if
            (
                status.toLowerCase() == SBR_3_0_Constants.ABSENCE_CORRECTION.toLowerCase()||
                status.toLowerCase() == SBR_3_0_Constants.ABSENCE_CORRECTED.toLowerCase()||
                status.toLowerCase() == SBR_3_0_Constants.ABSENCE_COMPLETED.toLowerCase() ||
                status.toLowerCase() == SBR_3_0_Constants.ABSENCE_APPROVED.toLowerCase()
            )
            {
                return 'upsert';
            }
            // for status == canceled return delete action
            else if
            (
                status.toLowerCase() == SBR_3_0_Constants.ABSENCE_CANCELED
            )
            {
                return 'delete';
            }
            //If status do not match above conditions, throw an exception.
            else
            {
                return 'exception';
            }
        }
    }

    public class TimeOffWrapper extends BaseResourceAbsenceWrapper
    {
        public Datetime timeOffDate;
        public Decimal timeOffTime; // Can be  -ve or +ve if -ve delete if +ve add time (Not mandatory)

        /**
         * @description| Method to convert wrapper back to SObject record of ResourceAbsence.
         */
        public ResourceAbsence getSObjectRecord(TimeOffWrapper timeOff, Map<String,Id> mapExternalToResourceId)
        {
            if(timeOff != null)
            {
                //set AbsenceWrapper ResourceSFId, So we can use it while populating Master-detail on absence.
                timeOff.resourceSFId = mapExternalToResourceId.get(timeOff.employeeId);
                //populate default values on timeoff object
                timeOff.populateDefaultValues();
                //Populate ResourceAbsence
                ResourceAbsence absence = new ResourceAbsence();

                //Populate data based on timeOff & mapExternalToResourceId
                absence.ResourceId = timeOff.resourceSFId;
                absence.Type = SBR_3_0_Constants.ABSENCE_TYPE_VACATION;
                absence.Start = timeOff?.timeOffDate;
                absence.End = timeOff?.lastDayOfLeave;
                absence.SF_PS_Resource_Absence_Key__c = timeOff.workdayId;
                absence.FSL__Approved__c = true;
                absence.SF_PS_TimeOffUnits__c = timeOff.timeOffTime;
                absence.SF_PS_Resource_Absence_Status__c = timeOff.status;
                absence.RecordTypeId = SBR_3_0_ResourceAbsenceRequestWrapper.ABSENCE_RECORD_TYPE_ID;

                return absence;
            }
            return null;
        }

        /**
         * @description| Populate default values on ResourceAbsence for TimeOffRecord
        */
        public void populateDefaultValues()
        {
            //Populate Default value for timeOffDate & lastDayOfLeave
            //If timeOffDate Hours are not populated, Populate it with default Value
            if(this.timeOffDate.hourGmt() <= 0 && this.timeOffDate.minuteGmt() <= 0 && this.timeOffDate.secondGmt() <= 0)
            {
                this.timeOffDate = this.timeOffDate.addHours(SBR_3_0_Constants.ABSENCE_START_TIME_HOURS);
                this.timeOffDate = this.timeOffDate.addMinutes(SBR_3_0_Constants.ABSENCE_START_TIME_MINUTES);
            }
            //Check if lastDayOfLeave in null
            if(this.lastDayOfLeave == null)
            {
                //In this case this.lastDayOfLeave = this.timeOffDate.addHours(this.timeOffTime)
                // We need to check If timeOffTime has a fractional value.
                Decimal timeOffFractionValue = this.timeOffTime - this.timeOffTime.round(System.RoundingMode.DOWN);
                // First Add Hours to last day of leave
                this.lastDayOfLeave = this.timeOffDate.addHours((Integer)this.timeOffTime.round(System.RoundingMode.DOWN));
                // Add Minutes to last day of leave If we have timeOffFractionValue as non zero value
                If(timeOffFractionValue != 0)
                {
                    //Since it is a fraction value we need to multiply it with 60 to get minutes value.
                    //Rounding it to a complete value since apex do not support fractional value in Date Time Object.
                    //upto .5 will get considered as 0 after that .6 will add as 1 minute.
                    this.lastDayOfLeave = this.lastDayOfLeave.addMinutes((Integer)(timeOffFractionValue*60).round(System.RoundingMode.HALF_UP));
                }
            }
            //If lastDayOfLeave Hours are not populated, Populate it with default Value
            //if lastDayOfLeave is not null and time is zero, then we will populate default time.
            if(this.lastDayOfLeave.hourGmt() <= 0 && this.lastDayOfLeave.minuteGmt() <= 0 && this.lastDayOfLeave.secondGmt() <= 0)
            {
                this.lastDayOfLeave = this.lastDayOfLeave.addHours(SBR_3_0_Constants.ABSENCE_END_TIME_HOURS);
                //As a correction of GMT to EST We need to add 4 hours more in order to make it correct upto EST TimeZone.
                this.lastDayOfLeave = this.lastDayOfLeave.addHours(4);
                this.lastDayOfLeave = this.lastDayOfLeave.addMinutes(SBR_3_0_Constants.ABSENCE_END_TIME_MINUTES);
            }
        }

        /**
         * @description| Convert SObject ResourceAbsence to TimeOffWrapper type.
         */
        private TimeOffWrapper getWrapperFromSObject(ResourceAbsence absence)
        {
            //Instentiate TimeOffWrapper
            TimeOffWrapper wrapperObj = new TimeOffWrapper();
            wrapperObj.workdayId = absence.SF_PS_Resource_Absence_Key__c;
            wrapperObj.objectName = 'timeoff';
            wrapperObj.resourceSFId = absence.ResourceId;
            wrapperObj.timeOffDate = absence.Start;
            wrapperObj.lastDayOfLeave = absence.End;
            wrapperObj.status = '';
            wrapperObj.timeOffTime = 6;
            wrapperObj.sfId = absence.Id;
            return wrapperObj;
        }

        /**
         * @description| Returns action to be perform for a specific Status on Absence or on TimeOff.
         */
        public String getStatusAction()
        {
            //if status is null/blank/white space return exception action.
            if(String.isBlank(status))
            {
                return 'exception';
            }
            // for status == canceled return delete action
            else if
            (
                status.toLowerCase() == SBR_3_0_Constants.ABSENCE_CANCELED || timeOffTime < 0
            )
            {
                return 'delete';
            }
            //For status == Correction/Complete/Approved return upsert action
            else if
            (
                status.toLowerCase() == SBR_3_0_Constants.ABSENCE_CORRECTION.toLowerCase()||
                status.toLowerCase() == SBR_3_0_Constants.ABSENCE_CORRECTED.toLowerCase()||
                status.toLowerCase() == SBR_3_0_Constants.ABSENCE_COMPLETED.toLowerCase() ||
                status.toLowerCase() == SBR_3_0_Constants.ABSENCE_APPROVED.toLowerCase()
            )
            {
                return 'upsert';
            }
            //If status do not match above conditions, throw an exception.
            else
            {
                return 'exception';
            }
        }
    }

    /**
     * @description| Used to send responce back to API Consumer
     */
    public class ResultWrapper
    {
        public Boolean isSuccess;
        public String message;
        public String data;

        /**
         * @description| Constructor definition, to instentiate Result
         * @Param| data: pass as your original format and not as string
         */
        public ResultWrapper(Boolean successParam, String description, Object dataObj)
        {
            isSuccess = successParam;
            message = description;
            data = JSON.serialize(dataObj);
        }

        public Map<String, String> getResponseMap()
        {
            return new Map<String,String>{'Status'=> isSuccess ? 'Success' : 'Error', 'Message'=> data};
        }
    }
    /** Supporting Wrapper Classes */
}