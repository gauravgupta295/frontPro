/*********************************************************************************************************************
* Apex Class: SBR_3_0_ResourceAbsenceHandler
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Handler class for operations related to Resource Absence Object API calls
* This is getting called from SBR_3_0_API_Web_ResourceAbsence
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Shubham Tunkikar        2023-11-15          Initial version
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
*
*********************************************************************************************************************/
public with sharing class SBR_3_0_ResourceAbsenceHandler {
	//Class Variables
	private SBR_3_0_ResourceAbsenceRequestWrapper absenceWrapperObj;
	private String absenceDataWrapperString;

	/**
	 * @description| Constructor to instenciate the class, Getting API data converted into wrapper class.
	 */
    public SBR_3_0_ResourceAbsenceHandler(String data) {
		//Get String data converted to Absence Wrapper
		if(!String.isEmpty(data))
        {
			absenceDataWrapperString = data;
			System.debug('Input Request:'+ absenceDataWrapperString);
		}
    }

	/**
	 * @description| Handles Request and response flow.
	 */
	public SBR_3_0_ResourceAbsenceRequestWrapper.ResultWrapper processRequest()
	{

		List<ResourceAbsence> lstResourceAb = new List<ResourceAbsence>();
		List<ResourceAbsence> lstResourceAbToDelete = new List<ResourceAbsence>();

		//Instentiate SBR_3_0_ResourceAbsenceRequestWrapper class
		absenceWrapperObj = new SBR_3_0_ResourceAbsenceRequestWrapper(absenceDataWrapperString);
		//Convert Wrapper data to List of ResourceAbsence SObject.
		Map<String,List<ResourceAbsence>> mapResourceAb = absenceWrapperObj.convertToSobjectList();

		//Add data to be upserted in lstResourceAb
		lstResourceAb = mapResourceAb.get('upsert');
		//Add data to be deleted in lstResourceAbToDelete
		lstResourceAbToDelete = mapResourceAb.get('delete');

		//Upsert SObject data within lstResourceAb to Salesforce Database.
		lstResourceAb = syncAbsenceToSF(lstResourceAb);

		//Delete SObject data within lstResourceAbToDelete from Salesforce Database.
		//Directly get External Id from absenceWrapperObj, It will save extra for loop.
		handleDeleteAbsenceFromSF(absenceWrapperObj.getExternalIdsToDelete());

		System.debug('lstResourceAb::'+lstResourceAb);
		System.debug('lstResourceAbToDelete::'+lstResourceAbToDelete);

		if(lstResourceAb == null)
		{
			lstResourceAb = new List<ResourceAbsence>();
		}

		//Append lstResourceAbToDelete in lstResourceAb in order to return the data back to the source.
		if(lstResourceAbToDelete!=null && !lstResourceAbToDelete.isEmpty())
		{
			lstResourceAb.addAll(lstResourceAbToDelete);
		}

		//Prepare Wrapper data from lstResourceAb, to be sent as a response.
		List<SBR_3_0_ResourceAbsenceRequestWrapper.BaseResourceAbsenceWrapper> lstFinalAbsenceResponse = absenceWrapperObj.getWrapperRecordsToReturn(lstResourceAb);
		//Populate Results
		SBR_3_0_ResourceAbsenceRequestWrapper.ResultWrapper result = new SBR_3_0_ResourceAbsenceRequestWrapper.ResultWrapper(true, '',lstFinalAbsenceResponse);
		System.debug('Response::'+ result);
		return result;
	}

	/**
	 * @Upsert Absence or TimeOff records on Salesforce ResourceAbsence based on External Id.
	 */
	public List<ResourceAbsence> syncAbsenceToSF(List<ResourceAbsence> lstResourceAb)
	{
		//upsert lstResourceAb;
		System.debug('lstResourceAb::'+lstResourceAb);
		if(lstResourceAb != null && !lstResourceAb.isEmpty())
		{
			upsert lstResourceAb SF_PS_Resource_Absence_Key__c;
		}
		return lstResourceAb;
	}

	/**
	 * @description| Deletes ResourceAbsence from salesforce
	 */
	private void handleDeleteAbsenceFromSF(List<String> lstExternalIdsToDelete)
	{
		if(lstExternalIdsToDelete != null && !lstExternalIdsToDelete.isEmpty())
		{
			// SOQL ResourceAbsence records based on SF_PS_Resource_Absence_Key__cfield value present in lstExternalIdsToDelete
			List<ResourceAbsence> lstAbsenceToDelete = [SELECT Id, SF_PS_Resource_Absence_Key__c FROM ResourceAbsence WHERE SF_PS_Resource_Absence_Key__c IN: lstExternalIdsToDelete WITH SECURITY_ENFORCED];

			//Validate lstAbsenceToDelete before deleting.
			if(validateAbsenceDeletion(lstAbsenceToDelete, lstExternalIdsToDelete))
			{
				//If validation success, delete records in lstAbsenceToDelete.
				delete lstAbsenceToDelete;
			}
			else
			{
				System.debug('NoDataFoundException');
				//If validation fails, Throw an exception.
				DmlException error = new DmlException();
				error.setMessage('Fail to delete the records. One or more records dose not exist:'+lstExternalIdsToDelete);
				throw error;
			}
		}
	}

	/**
	 * @description| Validates ResourceAbsence records before deletions,
	 * and if validations are correct and returns true, then only it should delete target records.
	 */
	private Boolean validateAbsenceDeletion(List<ResourceAbsence> lstAbsenceToDelete, List<String> lstExternalIdsToDelete)
	{
		System.debug('lstExternalIdsToDelete:1:'+lstExternalIdsToDelete);
		System.debug('lstAbsenceToDelete:1:'+lstAbsenceToDelete);
		Boolean isValidData = true;
		//if lstAbsenceToDelete is empty, set isValidData = false.
		if(lstAbsenceToDelete != null && !lstAbsenceToDelete.isEmpty())
		{
			//if lstAbsenceToDelete is not empty, loop through it for more validations.
			for(ResourceAbsence absence : lstAbsenceToDelete)
			{
				//It checks if External Id is correct and record for same external Id present in Org.
				if(!lstExternalIdsToDelete.contains(absence.SF_PS_Resource_Absence_Key__c))
				{
					System.debug('isValidData::'+isValidData);
					//If not present, set isValidData = false.
					isValidData = false;
					break;
				}
			}
		}
		else
		{
			isValidData = false;
		}

		System.debug('isValidData:Return:'+isValidData);
		return isValidData;
	}
}