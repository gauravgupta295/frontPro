/*********************************************************************************************************************
* Apex Class: SBR_3_0_DynamicRecordFormSectionDetail
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to store the details of the dynamic record section driven by Record_Section__mdt
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Komal Dwivedi          12-Oct-2023          Initial version
*********************************************************************************************************************/

public with sharing class SBR_3_0_DynamicRecordFormSectionDetail {
  private static final String COL2_LAYOUT = '2 Col';
  private static final String ACCORDION_VARIANT = 'Accordion';
  private static final String FULL_VIEW_VARIANT = 'Full';
  @AuraEnabled
  public String externalId;
  @AuraEnabled
  public String label;
  @AuraEnabled
  public String displayType;
  @AuraEnabled
  public Decimal order;
  @AuraEnabled
  public Boolean isMultiColLayout;
  @AuraEnabled
  public Boolean IsCollapsible;
  @AuraEnabled
  public List<SBR_3_0_DynamicRecordFormFieldDetail> fields;
  @AuraEnabled
  public String variant;
  /* Added helptext as part of FRONT-15703*/
  @AuraEnabled
  public String helpText;
  public SBR_3_0_DynamicRecordFormSectionDetail(Record_Section__mdt section) {
    this.externalId = section.DeveloperName;
    this.label = section.Label__c;
    this.displayType = section.Display_Type__c;
    this.order = section.Order__c;
    this.isMultiColLayout = this.displayType == COL2_LAYOUT;
    this.fields = new List<SBR_3_0_DynamicRecordFormFieldDetail>();
    this.IsCollapsible = section.Is_Collapsible__c;
    this.variant = String.isBlank(section.Variant__c)
      ? ACCORDION_VARIANT
      : section.Variant__c;
    this.helpText = section.Helptext__c;
  }
}