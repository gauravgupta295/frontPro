/**
 * @description       : Utility Data Access
 * @group             :
 * @last modified on  : 01-25-2024
 * @last modified by  : Shreenivas Adapur
 **/
public with sharing class SBR_3_0_UtilityDA implements SBR_3_0_UtilityDAInterface {
  private static final String STANDARD_PRICE_BOOK_NAME = 'Standard Price Book';

  private static Map<String, String> quoteChildObjects = new Map<String, String>{
    'Crew_Summary__c' => 'Crew_Summaries__r',
    'Crew__c' => 'Crews__r',
    'SBQQ__QuoteLineGroup__c' => 'SBQQ__LineItemGroups__r',
    'SBQQ__QuoteLine__c' => 'SBQQ__LineItems__r',
    'SBR_Expense__c' => 'Expenses__r',
    'Scope__c' => 'Scopes__r',
    'SBQQ__Account__c' => 'SBQQ__Account__r',
    'SBQQ__SalesRep__c' => 'SBQQ__SalesRep__r',
    'Jobsite__c' => 'Jobsite__r',
    'Secondary_Rep__c' => 'Secondary_Rep__r',
    'Office_Account__c' => 'Office_Account__r',
    'Branch__c' => 'Branch__r',
    'Ordered_by__c' => 'Ordered_by__r',
    'Sourcing_Branch__c' => 'Sourcing_Branch__r'
  };

  private static Map<String, String> cartChildObjects = new Map<String, String>{
    'Cart_Items__c' => 'Cart_Items__r',
    'Order_Form_Item__c' => 'Order_Form_Items__r',
    'User_Location__c' => 'User_Location__r',
    'Account__c' => 'Account__r',
    'Contact__c' => 'Contact__r',
    'Branch__c' => 'Branch__r',
    'Existing_Contract__c' => 'Existing_Contract__r',
    'Jobsite__c' => 'Jobsite__r'
  };

  //SF-6444,SAL-25600
  private static Map<String, String> scaffoldPlatformChildObjects = new Map<String, String>{
    'Scaffold_Platform__c' => 'Scaffold_Platforms__r',
    'OwningUser__c' => 'OwningUser__r',
    'Account__c' => 'Account__r',
    'sbr_JobSiteId__c' => 'sbr_JobSiteId__r',
    'sbr_OpportunityId__c' => 'sbr_OpportunityId__r',
    'sbr_ProfitCenterId__c' => 'sbr_ProfitCenterId__r',
    'sbr_QuoteId__c' => 'sbr_QuoteId__r',
    'Shared_Location__c' => 'Shared_Location__r',
    'sbr_SCSurveyOfficeContactId__c' => 'sbr_SCSurveyOfficeContactId__r',
    'sbr_scsurveyjobsitecontactid__c' => 'sbr_scsurveyjobsitecontactid__r'
  };

  public static Map<String, PricebookEntry> getPriceBookEntriesByProductSKUs(
    Set<String> skus
  ) {
    Map<String, PricebookEntry> priceBookEntries = new Map<String, PricebookEntry>();
    for (PricebookEntry pe : [
      SELECT Id, Product2.Product_SKU__c, UnitPrice
      FROM PricebookEntry
      WHERE Product2.Product_SKU__c IN :skus
    ]) {
      priceBookEntries.put(pe.Product2.Product_SKU__c, pe);
    }
    return priceBookEntries;
  }

  public static Pricebook2 getStandardPriceBookRec() {
    return ([
      SELECT Id, Name
      FROM Pricebook2
      WHERE Name = :STANDARD_PRICE_BOOK_NAME
      LIMIT 1
    ]);
  }

  public static Map<String, PricebookEntry> getPriceBookEntriesByProductSKUs(
    Set<String> skus,
    String companyCode
  ) {
    String cic = getCompanyCurrencies().get(companyCode);
    Map<String, PricebookEntry> priceBookEntries = new Map<String, PricebookEntry>();
    for (PricebookEntry pe : [
      SELECT Id, Product2.Product_SKU__c, UnitPrice
      FROM PricebookEntry
      WHERE
        Pricebook2.name = :STANDARD_PRICE_BOOK_NAME
        AND Product2.Product_SKU__c IN :skus
        AND CurrencyIsoCode = :cic
    ]) {
      priceBookEntries.put(pe.Product2.Product_SKU__c, pe);
    }
    return priceBookEntries;
  }

  public static Map<String, PricebookEntry> getPriceBookEntriesByProductIds(
    Set<String> ids,
    String companyCode
  ) {
    String cic = getCompanyCurrencies().get(companyCode);
    Map<String, PricebookEntry> priceBookEntries = new Map<String, PricebookEntry>();
    for (PricebookEntry pe : [
      SELECT Id, Product2Id, UnitPrice
      FROM PricebookEntry
      WHERE
        Pricebook2.name = :STANDARD_PRICE_BOOK_NAME
        AND Product2Id IN :ids
        AND CurrencyIsoCode = :cic
    ]) {
      priceBookEntries.put(pe.Product2Id, pe);
    }
    return priceBookEntries;
  }

  public static Map<String, String> getCompanyCurrencies() {
    Map<String, String> currencies = new Map<String, String>();
    for (Company_Currency__mdt cc : [
      SELECT CurrencyIsoCode__c, Company_Code__c
      FROM Company_Currency__mdt
    ]) {
      currencies.put(cc.Company_Code__c, cc.CurrencyIsoCode__c);
    }
    return currencies;
  }
  public static Adobe_Quote_template__c getAdobeTemplateById(
    String templateId
  ) {
    Adobe_Quote_template__c adobeTemplateQuote = [
      SELECT Id, Template__c, Template_Id__c, Analysis_Regions__c, Name
      FROM Adobe_Quote_Template__c
      WHERE Id = :templateId
    ];

    return adobeTemplateQuote;
  }

  public static List<ContentDocumentLink> getContentDocumentLinkById(
    String linkedEntityRecId
  ) {
    List<ContentDocumentLink> contentDocLinkList = [
      SELECT
        Id,
        ContentDocument.LatestPublishedVersion.VersionData,
        ContentDocument.title,
        LinkedEntityId,
        ContentDocumentId,
        ContentDocument.OwnerId,
        ContentDocument.LastModifiedDate,
        ContentDocument.CreatedDate
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :linkedEntityRecId
      ORDER BY ContentDocument.CreatedDate DESC
      LIMIT 1
    ];

    return contentDocLinkList;
  }

  /**
   * @description //SAL-25600, SADAPUR
   * @param String selectedObject
   * @param String recordId
   * @return List<SObject>
   **/
  public static List<SObject> getAllFieldsForSObject(
    String selectedObject,
    String recordId
  ) {
    List<String> selectedObjFieldNames = new List<String>();
    List<String> childObjFieldNames;
    List<String> parentObjFieldNames;
    String selectStr = 'SELECT  Owner.Name, Owner.Email, Owner.Phone,';
    String whereClause = ' WHERE ';
    String fromString = ' FROM ' + selectedObject;
    List<String> innerQuery = new List<String>();

    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Schema.SObjectType selectedObjSchema = schemaMap.get(selectedObject);
    List<Schema.ChildRelationship> childRelObj = selectedObjSchema.getDescribe()
      .getChildRelationships();

    for (Schema.ChildRelationship chilObj : childRelObj) {
      String innerQueryStr = 'SELECT ';
      childObjFieldNames = new List<String>();
      String childObject = String.valueOf(chilObj.getChildSObject());
      if (childObject.endsWith('__c')) {
        String relField = '';
        if (
          selectedObject == 'Cart__c' &&
          cartChildObjects.containsKey(childObject) &&
          cartChildObjects.get(childObject) != 'User_Location__r'
        ) {
          relField = cartChildObjects.get(childObject);
        }
        if (
          selectedObject == 'SBQQ__Quote__c' &&
          quoteChildObjects.containsKey(childObject)
        ) {
          relField = quoteChildObjects.get(childObject);
        }
        //SF-6444
        if (
          selectedObject == 'Jobsite_Survey__c' &&
          scaffoldPlatformChildObjects.containsKey(childObject)
        ) {
          relField = scaffoldPlatformChildObjects.get(childObject);
        }

        Map<String, Schema.SObjectField> childFieldMap = chilObj.getChildSObject()
          .getDescribe()
          .fields.getMap();

        for (Schema.SObjectField childField : childFieldMap.values()) {
          if (childField != null) {
            String childFieldStr = String.valueOf(childField);
            innerQueryStr = innerQueryStr + childFieldStr + ',';
            //childObjFieldNames.add(childFieldStr);
          }
        }
        innerQueryStr = innerQueryStr.removeEnd(',');
        if (String.isNotBlank(relField)) {
          innerQuery.add(innerQueryStr + ' FROM ' + relField);
        }
      }
    }
    Map<String, Schema.SObjectField> fieldMap = selectedObjSchema.getDescribe()
      .fields.getMap();

    for (Schema.SObjectField parentFieldfieldName : fieldMap.values()) {
      if (parentFieldfieldName != null) {
        if (
          parentFieldfieldName.getDescribe().getType() ==
          Schema.DisplayType.REFERENCE
        ) {
          Schema.SObjectType parentSchema = parentFieldfieldName.getDescribe()
            .getReferenceTo()
            .get(0);

          String parentObject = String.valueOf(parentFieldfieldName);
          if (parentObject.endsWith('__c')) {
            String relField = '';
            if (
              selectedObject == 'Cart__c' &&
              cartChildObjects.containsKey(parentObject)
            ) {
              relField = cartChildObjects.get(parentObject);
            }
            if (
              selectedObject == 'SBQQ__Quote__c' &&
              quoteChildObjects.containsKey(parentObject)
            ) {
              relField = quoteChildObjects.get(parentObject);
            }
            //SF-6444
            if (
              selectedObject == 'Jobsite_Survey__c' &&
              scaffoldPlatformChildObjects.containsKey(parentObject)
            ) {
              relField = scaffoldPlatformChildObjects.get(parentObject);
            }

            Map<String, Schema.SObjectField> parentFieldMap = parentSchema.getDescribe()
              .fields.getMap();

            for (Schema.SObjectField parentField : parentFieldMap.values()) {
              if (
                String.valueOf(parentField) != null &&
                String.isNotBlank(relField)
              ) {
                String parentFieldStr = String.valueOf(parentField);
                selectedObjFieldNames.add(relField + '.' + parentFieldStr);
              }
            }
          }
        } else {
          String parentFieldfieldNamestr = String.valueOf(parentFieldfieldName);
          selectedObjFieldNames.add(parentFieldfieldNamestr);
        }
      }
    }
    String queryStr = selectStr;

    for (String selectedObjField : selectedObjFieldNames) {
      queryStr = queryStr + ' ' + selectedObjField + ',';
    }
    for (String innerQ : innerQuery) {
      queryStr = queryStr + '(' + innerQ + ')' + ',';
    }
    String dbQuery = queryStr.removeEnd(',') + fromString + whereClause;
    List<SObject> sObjectList = Database.query(
      dbQuery + 'Id=:recordId LIMIT 1'
    );

    return sObjectList;
  }

  public static String getCurrentUserApplicationName() {
    String returnVal = '';
    UserAppInfo userAppInfo = [
      SELECT Id, AppDefinitionId
      FROM UserAppInfo
      WHERE UserId = :UserInfo.getUserId()
      LIMIT 1
    ];
    if (userAppInfo <> null) {
      AppDefinition appDefinition = [
        SELECT DurableId, Label, DeveloperName
        FROM AppDefinition
        WHERE DurableId = :userAppInfo.AppDefinitionId
        LIMIT 1
      ];
      if (appDefinition <> null) {
        returnVal = appDefinition.DeveloperName;
      }
    }

    return returnVal;
  }
}