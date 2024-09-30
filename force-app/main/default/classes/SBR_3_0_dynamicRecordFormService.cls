/*********************************************************************************************************************
* Apex Class: SBR_3_0_DynamicRecordFormController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Controller class for sbr_3_0_dynamicRecordFrom component. It returns the configuration needed to render the dynamic form
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Komal Dwivedi          25-Jan-2024          Initial version.
*********************************************************************************************************************/

public inherited sharing class SBR_3_0_dynamicRecordFormService {
  Map<Id, SBR_3_0_DynamicRecordFormPageDetail> detail = new Map<Id, SBR_3_0_DynamicRecordFormPageDetail>();
  Map<Id, SBR_3_0_DynamicRecordFormSectionDetail> idToRecordSectionDetails = new Map<Id, SBR_3_0_DynamicRecordFormSectionDetail>();
  Map<String, SBR_3_0_DynamicRecordFormPageDetail> configNameToDetail = new Map<String, SBR_3_0_DynamicRecordFormPageDetail>(); // FRONT-14725
  Map<String, String> recordPageDeveloperNameToId = new Map<String, String>();
  String mappingNames;
  Set<String> lstMappingName;
  public SBR_3_0_dynamicRecordFormService(String mappingNames) {
    this.mappingNames = mappingNames;
  }

  public Object getConfigurationsByMappingNames() {
    if (String.isBlank(mappingNames)) {
      return null;
    }
    if (String.isNotBlank(mappingNames)) {
      this.buildConfigNames(mappingNames)
        .buildRecordFormPageDetails()
        .buildRecordFormSectionDetails()
        .buildRecordFormElementDetails()
        .buildResponse();
    }
    return configNameToDetail.values();
  }

  private SBR_3_0_dynamicRecordFormService buildConfigNames(
    String mappingNames
  ) {
    this.lstMappingName = this.getPages(mappingNames);
    return this;
  }

  private Set<String> getPages(String mappingNames) {
    Set<String> lstMappingName = this.getParentPages(this.mappingNames);
    Set<String> childPages = getChildPages(lstMappingName);
    if (!childPages.isEmpty()) {
      lstMappingName.addAll(childPages);
    }

    return lstMappingName;
  }

  private Set<String> getParentPages(String mappingNames) {
    Set<String> configNames = new Set<String>();
    for (String configName : mappingNames.split(',')) {
      configNames.add(configName.trim());
    }

    return configNames;
  }

  private Set<String> getChildPages(Set<String> lstMappingName) {
    Set<String> childPages = new Set<String>();
    for (Record_Page__mdt recordPage : [
      SELECT Id, DeveloperName, Parent_Record_Page__c, Order__c
      FROM Record_Page__mdt
      WHERE Parent_Record_Page__c IN :lstMappingName
      ORDER BY Order__c ASC
    ]) {
      childPages.add(recordPage.DeveloperName);
    }

    return childPages;
  }

  private SBR_3_0_dynamicRecordFormService buildRecordFormPageDetails() {
    for (Record_Page__mdt recordPage : [
      SELECT
        Id,
        MasterLabel,
        DeveloperName,
        SObject_Name__c,
        Stylesheet_Name__c,
        Label__c,
        Parent_Record_Page__c,
        Order__c,
        Helptext__c
      FROM Record_Page__mdt
      WHERE DeveloperName IN :lstMappingName
      ORDER BY Order__c ASC
    ]) {
      system.debug('## recordPage--> ' + recordPage.DeveloperName);
      SBR_3_0_DynamicRecordFormPageDetail record = new SBR_3_0_DynamicRecordFormPageDetail(
        recordPage
      );

      if (
        String.isNotBlank(recordPage.Parent_Record_Page__c) &&
        lstMappingName.contains(recordPage.Parent_Record_Page__c)
      ) {
        record.parentPageName = recordPage.Parent_Record_Page__c;
      }

      detail.put(recordPage.Id, record);
      if (String.isNotBlank(recordPage.Stylesheet_Name__c)) {
        record.styleSheet = getStyleSheet(recordPage.Stylesheet_Name__c);
      }
      recordPageDeveloperNameToId.put(recordPage.DeveloperName, recordPage.Id);
    }
    return this;
  }

  public String getStyleSheet(String staticResourceStyleSheet) {
    String styleSheet;
    try {
      styleSheet = Pagereference.forResource(staticResourceStyleSheet)
        .getUrl()
        .split('\\?')[0];
    } catch (Exception e) {
      System.debug(LoggingLevel.WARN, 'Not a valid style sheet');
      styleSheet = '';
    }
    return styleSheet;
  }

  private SBR_3_0_dynamicRecordFormService buildRecordFormSectionDetails() {
    for (Record_Section__mdt section : [
      SELECT
        Id,
        DeveloperName,
        Display_Type__c,
        Label__c,
        Order__c,
        Record_Page__c,
        Is_Collapsible__c,
        Variant__c,
        Helptext__c
      FROM Record_Section__mdt
      WHERE Record_Page__c = :detail.keySet()
      ORDER BY Order__c ASC
    ]) {
      SBR_3_0_DynamicRecordFormSectionDetail sectionDetail = new SBR_3_0_DynamicRecordFormSectionDetail(
        section
      );
      idToRecordSectionDetails.put(section.Id, sectionDetail);
      detail.get(section.Record_Page__c).sections.add(sectionDetail);
    }
    return this;
  }

  private SBR_3_0_dynamicRecordFormService buildRecordFormElementDetails() {
    for (Record_Field__mdt field : [
      SELECT
        Id,
        Api_Name__c,
        Attributes__c,
        Label__c,
        Order__c,
        Record_Section__c,
        Required__c,
        Is_Read_Only__c,
        DeveloperName,
        Type__c,
        Show_Custom_Label__c,
        Custom_Component_Name__c,
        Allow_To_Dispatch_Event__c,
        Listen_To__c,
        Is_Inactive__c,
        Placeholder__c,
        HelpText__c //Added for Front-13084
      FROM Record_Field__mdt
      WHERE
        Record_Section__c IN :idToRecordSectionDetails.keySet()
        AND Is_Inactive__c = FALSE
      ORDER BY Order__c ASC
    ]) {
      SBR_3_0_DynamicRecordFormSectionDetail sectionDetail = idToRecordSectionDetails.get(
        field.Record_Section__c
      );
      SBR_3_0_DynamicRecordFormFieldDetail fieldDetail = new SBR_3_0_DynamicRecordFormFieldDetail(
        field
      );
      sectionDetail.fields.add(fieldDetail);
    }

    return this;
  }

  private void buildResponse() {
    for (String recordPageName : this.lstMappingName) {
      String recordPageId = recordPageDeveloperNameToId.get(recordPageName);
      SBR_3_0_DynamicRecordFormPageDetail dynamicForm = String.isNotBlank(
          recordPageId
        )
        ? detail.get(recordPageId)
        : null;

      SBR_3_0_DynamicRecordFormPageDetail parentDynamicForm = String.isNotBlank(
          dynamicForm.parentPageName
        )
        ? detail.get(
            recordPageDeveloperNameToId.get(dynamicForm.parentPageName)
          )
        : null;

      if (parentDynamicForm <> null) {
        if (!configNameToDetail.containsKey(dynamicForm.parentPageName)) {
          configNameToDetail.put(dynamicForm.parentPageName, parentDynamicForm);
        }
        parentDynamicForm.childrenPages.add(dynamicForm);
      } else {
        if (null <> dynamicForm) {
          if (!configNameToDetail.containsKey(dynamicForm.externalId)) {
            configNameToDetail.put(dynamicForm.externalId, dynamicForm);
          }
        }
      }
    }
  }
}