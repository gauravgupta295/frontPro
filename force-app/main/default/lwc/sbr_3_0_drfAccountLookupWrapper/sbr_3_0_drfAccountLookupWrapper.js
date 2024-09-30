import { LightningElement, track, wire } from "lwc";
import {
  DynamicRecordFormMixin,
  isMobile // FRONT-20757 & FRONT-20761
} from "c/sbr_3_0_dynamicRecordFormUtility";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import { getRecord } from "lightning/uiRecordApi"; // FRONT-20757 & FRONT-20761
import { Logger, isEmpty } from "c/sbr_3_0_frontlineUtils"; // FRONT-20757 & FRONT-20761
const logger = Logger.create(true); // FRONT-20757 & FRONT-20761

const OBJECT_API_NAME_TO_ACCOUNT_RELATIONSHIP = {
  Order: "Account",
  SBQQ__Quote__c: "SBQQ__Account__r"
};
const OBJECT_API_Label = {
  Order: "Reservation",
  ContractOrder: "Contract",
  SBQQ__Quote__c: "Quote"
};

const ACCOUNT_FIELDS_TO_BE_QUERIED = [
  // FRONT-20757 & FRONT-20761
  "Account.Name",
  "Account.RecordType.Name"
];

const DEFAULT_BTN_ICON_CLASS = "slds-m-top_medium"; // FRONT-20757 & FRONT-20761

export default class Sbr_3_0_drfAccountLookupWrapper extends DynamicRecordFormMixin(
  LightningElement
) {
  labels = LABELS;
  whereClause =
    "((Status__c = 'Active') AND RecordType.DeveloperName IN ('ERP_Link', 'Non_Credit', 'Credit') AND (Company_Code__c = '' OR Company_Code__c = '01' OR Company_Code__c = '02'))";
  frontlineDefaultFilteringFields =
    "RM_Account_Number__c, Phone,E_mail_Address__c,Record_Type_Text__c"; //FRONT-4737
  mobileScreenProps = {
    zIndex: 9004
  };
  parentComp;
  disableEditInfo;
  accountId;
  @track showWarningMessage = false;
  objectAccountId;
  fieldLabel;
  objectLabel;
  showFrontlineComponents;
  isRequired = true;
  //Front-20803 start
  recordTypeName = "";
  //Front-20803 end

  // START - FRONT-20757 & FRONT-20761
  isNonCreditRecordTypeAccount = false;
  showEditButtons = false;
  lookupWrapperSize = 12;
  disableBtn = false;
  showEditBtnScreen = false;
  isMobile = isMobile;
  // END - FRONT-20757 & FRONT-20761

  connectedCallback() {
    this.recordTypeName = FORM_STORE.records[this.recordId].recordTypeInfo.name; //20803
    logger.log("inside account wrapper");
    this.getAppName();
    this.objectLabel = OBJECT_API_Label[this.objectApiName];
    if (
      this.objectApiName === "Order" &&
      this.recordTypeName === "Create Contract"
    ) {
      this.parentComp = "orderrequireCustomLookup";
      this.fieldLabel = "Account Name";
      this.objectLabel = OBJECT_API_Label["ContractOrder"];
    } else if (this.objectApiName === "Order") {
      this.parentComp = "orderrequireCustomLookup";
      this.fieldLabel = "Account Name";
    } else if (this.objectApiName === "SBQQ__Quote__c") {
      this.parentComp = "quoterequireCustomLookup";
      this.fieldLabel = "Account Name";
      this.whereClause =
        "((Status__c = 'Active') AND RecordType.DeveloperName IN ('Prospect', 'ERP_Link', 'Non_Credit', 'Credit') AND (Company_Code__c = '' OR Company_Code__c = '01' OR Company_Code__c = '02'))";
    }

    let accountRelationshipName =
      OBJECT_API_NAME_TO_ACCOUNT_RELATIONSHIP[this.objectApiName];
    let account =
      FORM_STORE.records[this.recordId]?.fields?.[accountRelationshipName]
        ?.value;
    this.accountId = account?.fields?.Id.value;
    this.objectAccountId = this.accountId;
    this.disableBtn = this.accountId ? false : true; // FRONT-20757 & FRONT-20761

    this.props = {
      recordId: this.objectAccountId,
      recordTypeName: this.recordTypeName,
      recordTypeId: FORM_STORE.records[this.recordId].recordTypeId
    };

    logger.log(
      " this.props on  connected callback : " + JSON.stringify(this.props)
    );
  }

  updateCustomer(event) {
    try {
      let selectedCustomer = event.detail;
      if (selectedCustomer.selectedRecord) {
        //FRONT-11424
        let message = this.labels.ORDER_CUSTOMER_INFO_CHANGE_TOAST;
        let showIcon = true;
        let classList = "";

        if (this.isCreateContractOrder) {
          message = this.labels.CONTRACT_ORDER_CUSTOMER_INFO_CHANGE_TOAST;
          classList = "messageFont";
        }
        if (this.isMobile) {
          showIcon = false;
        }
        const toastNotification = new CustomEvent("showtoast", {
          detail: {
            title: "",
            message: message,
            variant: "info",
            mode: "sticky",
            showIcon: showIcon,
            classList: classList
          },
          bubbles: true,
          composed: true
        });

        this.dispatchEvent(toastNotification);

        let selectedValue = [
          {
            apiName: this.field.apiName,
            value: selectedCustomer.selectedRecord
              ? selectedCustomer.selectedRecord.Id
              : undefined
          },
          {   //FRONT-20762
            apiName: 'RM_Account_Number_Display__c',
            value: selectedCustomer.selectedRecord
              ? selectedCustomer.selectedRecord.RM_Account_Number__c
              : undefined
          }
        ];
        this.publishChange(this.field.externalId, selectedValue[0], true);
        this.updateDRFFieldUpdate(selectedValue);
        this.objectAccountId = selectedCustomer.selectedRecord.Id;
        this.disableBtn = false; // FRONT-20757 & FRONT-20761

        this.props = {
          recordId: this.objectAccountId,
          recordTypeName: selectedCustomer.selectedRecord.RecordType.Name,
          recordTypeId: selectedCustomer.selectedRecord.RecordTypeId
        };
      } else {
        this.showWarningMessage = true;
        this.accountId = null;
        this.disableBtn = true; // FRONT-20757 & FRONT-20761
      }
    } catch (error) {
      console.log(error);
    }
  }
  //FRONT-10312
  getAppName() {
    console.log('FORMSTOREAPP',FORM_STORE.appName);
    if (FORM_STORE.appName === "RAE Frontline") {
      this.showFrontlineComponents = true;
    } else {
      this.showFrontlineComponents = false;
      this.whereClause =
        "(Status__c IN ('Active','On Hold','Suspended') AND RecordType.DeveloperName IN ('ERP_Link','Credit'))";
    }
  }

  closeWarningMessage(event) {
    this.showWarningMessage = false;
    if (event.detail === "close") {
      this.accountId = this.objectAccountId;
      this.disableBtn = false; // FRONT-20757 & FRONT-20761
    } else {
      // START - FRONT-20757 & FRONT-20761
      this.showEditButtons = true;
      this.lookupWrapperSize = 10;
      this.disableBtn = true;
      // END - FRONT-20757 & FRONT-20761
      let selectedValue = [
        {
          apiName: this.field.apiName,
          value: undefined
        }
      ];
      this.updateDRFFieldUpdate(selectedValue);
      this.objectAccountId = undefined;
    }
  }

  // START - FRONT-20757 & FRONT-20761
  get btnIconClass() {
    return this.disableBtn
      ? DEFAULT_BTN_ICON_CLASS + " btn-icon-disabled-class"
      : DEFAULT_BTN_ICON_CLASS + " btn-icon-enabled-class";
  }

  get isCreateContractOrder() {
    return this.recordTypeName === "Create Contract";
  }

  @wire(getRecord, {
    recordId: "$objectAccountId",
    fields: ACCOUNT_FIELDS_TO_BE_QUERIED
  })
  getAccountRecord({ error, data }) {
    if (!isEmpty(data)) {
      logger.log("@@@@ Data >> " + JSON.stringify(data));
      this.isNonCreditRecordTypeAccount =
        data?.recordTypeInfo?.name === "Non-Credit";

      this.showEditButtons =
        this.isNonCreditRecordTypeAccount && this.isCreateContractOrder;

      this.lookupWrapperSize = this.showEditButtons ? 10 : 12;
      if (data?.recordTypeInfo) {
        this.props = {
          recordId: this.objectAccountId,
          recordTypeName: data?.recordTypeInfo?.name,
          recordTypeId: data?.recordTypeId
        };
      }

      logger.log("[+] this.props :" + JSON.stringify(this.props));
    } else {
      logger.log("[-] EMPTY DATA");
    }

    if (error) {
      logger.log("🔥 ERROR >> " + error.stack);
    }
  }

  async handleEditBtnClick() {
    if (isMobile && this.disableBtn) return;
    logger.log("@@@@ this.props >> " + this.props);
    this.showEditBtnScreen = true;
  }

  @track props = {};

  closeModal = (evt) => {
    logger.log(evt);
    this.showEditBtnScreen = false;
  };

  async selectAccount(evt) {
    this.disableBtn = true;
    this.accountId = this.objectAccountId = evt.detail.id;
    logger.log("Selected Accounts >> " + JSON.stringify(evt.detail));
    logger.log("Accounts Id >> " + this.accountId);
    let requiredCustomLookupCmp = this.template.querySelector(
      "c-s-b-r_3_0_required-custom-lookup-cmp-frontline"
    );
    if (requiredCustomLookupCmp) {
      requiredCustomLookupCmp.defaultRecord = evt.detail.id;
      await requiredCustomLookupCmp.refreshApexMethod();
    }

    let editAccountCmp = this.template.querySelector(
      "c-sbr_3_0_edit-account-cmp"
    );
    if (editAccountCmp) {
      await editAccountCmp.refreshApexMethod();
    }
    this.disableBtn = false;

    this.props = {
      recordId: this.objectAccountId,
      recordTypeName: evt.detail.Record_Type_Text__c,
      recordTypeId: evt.detail.RecordTypeId
    };
  }
  // END - FRONT-20757 & FRONT-20761
}