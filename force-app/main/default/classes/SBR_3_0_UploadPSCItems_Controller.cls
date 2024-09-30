/*********************************************************************************************************************
* Apex Class: SBR_3_0_UploadPSCItems_Controller
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* SERV-2659 - Controller Class to insert Product Service Campaign Items for Assets uploaded via CSV Files
----------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME        DATE            MOD LOG
    1.0       Ritesh Mohapatra      2023-Nov-15     Initial version (SERV-2659)
	
**********************************************************************************************************************/
public without sharing  class SBR_3_0_UploadPSCItems_Controller 
{
    /**************************************************************************************
    * Method Name : getDeliveryMethodValues
    * Method Description : Returns picklist values of Delivery Method field in PSC Object.
    * Version:     
        DEVELOPER    NAME                  DATE            MOD LOG
        1.0          Ritesh Mohapatra      2023-Nov-15     Initial version (SERV-2659) 
    ***************************************************************************************/
    
    @AuraEnabled
    public static String[] getDeliveryMethodValues()
    {
        String[] pickListValues= new String[]{};
		Schema.DescribeFieldResult fieldResult = ProductServiceCampaign.SVMXA360__DeliveryMethod__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple)
        {
			pickListValues.add(pickListVal.getLabel());
		} 
		return pickListValues;
    }
    
    /**************************************************************************************
    * Method Name : preparePSCItems
    * Method Description : Prepares PSC Items to be created from the uploaded CSV
    * Version:     
        DEVELOPER    NAME                  DATE            MOD LOG
        1.0          Ritesh Mohapatra      2023-Nov-15     Initial version (SERV-2659) 
    ***************************************************************************************/
    @AuraEnabled
    public static String preparePSCItems(String fileName, String base64Data, String pscRecordId, String delmethodSelected)
    {
        List<String> deliveryTypesList = new List<String>();
        String COMPANY_CODE = 'COMPANY CODE';
        String EQUIPMENT_NUMBER = 'EQUIPMENT NUMBER';
        String ASSET_ID = 'ASSET ID';
        
        Blob csvFileBody;
        String csvAsString;
        String[] csvFileLines;
        List<String> compCodeValues = new List<String>(); 
        List<String> equipNumberValues = new List<String>();  
        List<String> assetIdValues = new List<String>(); 

        List<String> eachHeader;
        Integer headerPosition, companyCodeCol, equipNumberCol, assedtIdCol ;
        Map<String, Integer> eachHeaderMap = new Map<String, Integer>();
        
        //Conversion of CSV Data
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        csvFileBody = EncodingUtil.base64Decode(base64Data);
        csvAsString  = csvFileBody.toString();
        csvAsString = csvAsString.replace('\r','\n');
        csvAsString = csvAsString.replace('\n\n','\n');
        csvFileLines = csvAsString.split('\n');
        
        if(delmethodSelected.contains('Both'))
        {
            deliveryTypesList.add('WorkOrder');
            deliveryTypesList.add('SVMXA360__AssetNotification__c');
        }
        if(delmethodSelected == 'Asset Notification')
        {
            deliveryTypesList.add('SVMXA360__AssetNotification__c');
        }
        else
        {
            deliveryTypesList.add('WorkOrder');
        }
        
        if(csvFileLines.isEmpty() || csvFileLines.size() == 1){
            return 'The CSV file is empty or only contains headers';
        }
        
        //Idenfity column position of each header - create map of header value to header column position
        eachHeader = csvFileLines[0].split(',',-1);
        headerPosition = 0;
        for(String header : eachHeader)
        {
            if(!String.isBlank(header))
            {
                eachHeaderMap.put(header, headerPosition);         
            }
            
            headerPosition++;
        }
        
        if(eachHeaderMap.containsKey(COMPANY_CODE)){
            companyCodeCol = eachHeaderMap.get(COMPANY_CODE);
        }
        if(eachHeaderMap.containsKey(EQUIPMENT_NUMBER)){
            equipNumberCol = eachHeaderMap.get(EQUIPMENT_NUMBER);
        }
        if(eachHeaderMap.containsKey(ASSET_ID)){
            assedtIdCol = eachHeaderMap.get(ASSET_ID);
        }
        System.debug('companyCodeCol:'+companyCodeCol);
        System.debug('equipNumberCol:'+equipNumberCol);
        System.debug('assedtIdCol:'+assedtIdCol);
        
        if(companyCodeCol == null || equipNumberCol == null || assedtIdCol == null){
            return 'Cannot find one or more of the following headers on the CSV file - "COMPANY CODE", "EQUIPMENT NUMBER", "ASSET ID"';
        }
        System.debug('csvFileLines: '+csvFileLines);
        //Loop through CSV file to identify all items
        for (Integer i=1; i<csvFileLines.size(); i++)
        {
            List<String> columnValues = new List<String>();
            columnValues = csvFileLines[i].split(',');
            system.debug('->'+columnValues);
            system.debug('->columnValues[0]'+columnValues[0]);
            compCodeValues.add(String.valueOf(columnValues[0]));
            equipNumberValues.add(String.valueOf(columnValues[1]));
            assetIdValues.add(String.valueOf(columnValues[2]));
            
        }  
        System.debug('Line 109 - preparePSCItems');
        
        //Check to ensure current PSC isn't already processing
        ProductServiceCampaign existPsc = [SELECT Id, 
                                                  SVMXix__ExtraCriteriaRunning__c 
                                           FROM ProductServiceCampaign 
                                           WHERE Id = :pscRecordId];
        if(existPsc.SVMXix__ExtraCriteriaRunning__c)
        {
            return 'An existing process is already running. Wait for it to complete.';
        }
        
        if(!assetIdValues.isEmpty())
        {
            Set<Id> finalAssetIdSet = (new Map<Id, Asset>([SELECT Id FROM Asset WHERE SM_PS_Asset_Id__c IN : assetIdValues])).keySet();
            List<Id> finalAssetIdList = new List<Id>(finalAssetIdSet);
            
            if(!finalAssetIdSet.isEmpty())
            {
                System.enqueueJob(new SVMXix.PscAddResultLines(pscRecordId,finalAssetIdList,deliveryTypesList,false),1);
            }
        }
        
        return 'SUCCESS'; 	                                     
    }
    
    @AuraEnabled               
    public static String getExampleCsvContent(){
        String idValue;
        String prodName;

        String csvContent = '';
        //CSV Headers
        csvContent += 'COMPANY CODE,EQUIPMENT NUMBER,ASSET ID\n';
        
        //Example 1
        csvContent += '01' + ',';
        csvContent += '5797462' + ',';
        csvContent += '01-5797462' + ',';
        csvContent += '\n';
           		
		//Example 2
        csvContent += '02' + ',';
        csvContent += '5797463' + ',';
        csvContent += '02-5797463' + ',';
        csvContent += '\n';

		//Example 3
        csvContent += '03' + ',';
        csvContent += '5797464' + ',';
        csvContent += '03-5797464' + ',';
        csvContent += '\n';
        
        return csvContent;
    }
}