import { LightningElement, wire, api, track } from "lwc";
import { getFieldValue, getRecords } from "lightning/uiRecordApi";
import FORM_FACTOR from "@salesforce/client/formFactor";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import DESKTOP_SOFT_STOP_TEMPLATE from "./sbr_3_0_duplicateResolverDesktop/sbr_3_0_duplicateResolverDesktopSoftStop/sbr_3_0_duplicateResolverDesktop.html";
import DESKTOP_SOFT_STOP_TEMPLATE_ACTION from "./sbr_3_0_duplicateResolverDesktop/sbr_3_0_duplicateResolverDesktopSoftStop/sbr_3_0_duplicateResolverDesktopQuickAction.html";
import MOBILE_LANDING_PAGE_TEMPLATE from "./sbr_3_0_duplicateResolverMobile/sbr_3_0_duplicateResolverLandingPageSS/sbr_3_0_duplicateResolverLandingPage.html";
import MOBILE_LANDING_HARDSTOP_PAGE_TEMPLATE from "./sbr_3_0_duplicateResolverMobile/sbr_3_0_duplicateResolverLandingPageHS/sbr_3_0_duplicateResolverHardStopLandingPage.html";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import ACCOUNT_FIELDS from "./accountSchema";
import { isUndefinedOrNull } from "c/sbr_3_0_frontlineUtils";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import DESKTOP_HARD_STOP_TEMPLATE from "./sbr_3_0_duplicateResolverDesktop/sbr_3_0_duplicateResolverDesktopHardStop/sbr_3_0_duplicateResolverHardStopDesktop.html";
import MOBILE_SOFT_SOFT_ACTION from "./sbr_3_0_duplicateResolverMobile/sbr_3_0_duplicateResolverLandingPageSS/sbr_3_0_duplicateResolverLandingPageAction.html"; //FRONT-4481
import DESKTOP_SOFT_STOP_BG_ACTION from "./sbr_3_0_duplicateResolverDesktop/sbr_3_0_duplicateResolverDesktopSoftStop/sbr_3_0_duplicateResolverDesktopSSBackground.html"; //FRONT-44
import DESKTOP_HARD_STOP_BG_ACTION from "./sbr_3_0_duplicateResolverDesktop/sbr_3_0_duplicateResolverDesktopHardStop/sbr_3_0_duplicateResolverDesktopHSBackground.html"; //FRONT-4597
import { NavigationMixin } from "lightning/navigation";

const COLUMNS = [
  {
    label: "Account Name",
    fieldName: "Name",
    classes: "slds-cell-wrap"
  },
  {
    label: "Status",
    fieldName: "Status__c",
    classes: "slds-cell-wrap fixed-width-10"
  },
  {
    label: "Phone",
    fieldName: "Phone",
    classes: "slds-cell-wrap"
  },
  {
    label: "Billing Address",
    fieldName: "BillingAddress"
  },
  {
    label: "D/L State",
    fieldName: "Driver_s_License_State__c",
    classes: "slds-cell-wrap fixed-width-10"
  },
  {
    label: "D/L Number",
    fieldName: "Drivers_License__c",
    classes: "slds-cell-wrap fixed-width-15"
  },
  {
    label: "Email",
    fieldName: "E_mail_Address__c"
  }
];

const STATUS_TO_CSS_CLASS_MAP = {
  Active: "greenColor",
  Inactive: "greyColor",
  Closed: "greyColor",
  Deleted: "redColor",
  "On Hold": "orangeColor",
  "Bad Debt": "redColor",
  None: "greyColor",
  Suspended: "orangeColor",
  "Credit Denied": "redColor"
};

const DEFAULT_FIELDS_TO_QUERY = [
  ACCOUNT_FIELDS.ID_FIELD,
  ACCOUNT_FIELDS.NAME_FIELD,
  ACCOUNT_FIELDS.STATUS_FIELD,
  ACCOUNT_FIELDS.PHONE_FIELD,
  ACCOUNT_FIELDS.BILLING_STREET_FIELD,
  ACCOUNT_FIELDS.BILLING_CITY_FIELD,
  ACCOUNT_FIELDS.BILLING_STATE_FIELD,
  ACCOUNT_FIELDS.BILLING_POSTALCODE_FIELD,
  ACCOUNT_FIELDS.BILLING_COUNTRY_FIELD,
  ACCOUNT_FIELDS.DRIVERS_LICENSE_FIELD,
  ACCOUNT_FIELDS.DRIVERS_LICENSE_STATE_FIELD,
  ACCOUNT_FIELDS.EMAIL_FIELD,
  ACCOUNT_FIELDS.RECORD_TYPEID_FIELD,
  ACCOUNT_FIELDS.RECORD_TYPE_NAME_FIELD
];

const SMALL_FORM_FACTOR = "Small";
const logger = Logger.create(true);
const DUPLICATE_SCREEN_HEADER = "Duplicate Account(s) Detected";
const TOTAL_DUPLICATE_ACCOUNTS_SUB_HEADING =
  "Total Number of Duplicate Accounts Found"; //FRONT-4002, 3880, 4001
const HARDSTOP_DUPLICATE_ACCOUNTS_SUB_HEADING =
  "D/L Number and D/L State is already being used."; //FRONT-4596
const METHOD_SECTION_HEADING = "How would you like to proceed?";
const ACTION_SECTION_HEADING = LABELS.ACTION_PROCEED_LABEL; //FRONT-4481
const RESERVATION_ORDER_ORIGIN = "orderrequireCustomLookup";
const EDIT_SCREEN_FROM_TRANSACTION = "EditScreen";
const CONVERT_SCREEN_FROM_TRANSACTION = "ConvertScreen";
const CONTRACT_ORDER_ORIGIN = "orderrequireCustomLookup";
const ACTIVE_STATUS = "Active";
const NEW_RESOLUTION = "new";
const EXISTING_RESOLUTION = "existing";
const DUPLICATE_LIST_HEADING = "Existing Accounts";
const DUPLICATE_SERIALIZED_MESSAGE_END =
  " is already being used in an existing account.";
const DUPLICATE_SERIALIZED_MESSAGE = " is already being used.";
const HARDSTOP_DUPLICATE_SERIALIZED_MESSAGE_END =
  "You cannot create multiple Non-Credit Accounts with the same driver's license information.  See existing account details below.";
const HARDSTOP_PROCEED_LABEL =
  "Please update the D/L Number and D/L State to continue making this change.";
const ACCOUNT_NAME_LABEL = "Account Name";
const EMAIL_LABEL = "Email";
const PHONE_LABEL = "Phone";
const BILLING_ADDRESS_LABEL = "Billing Address";
const USE_NEW_ACCOUNT_LABEL = "Use new account";
const USE_NEW_ACCOUNT_DESCRIPTION =
  "Continue with creating a new non-credit account.";
const USE_EXISTING_ACCOUNT_LABEL = "Use existing account";
const USE_EXISTING_ACCOUNT_DESCRIPTION =
  "Select one of the existing accounts below.";
const HARDSTOPDUPLICATERULE =
  "Account_Non_Credit_Driving_Information_Duplicate_Rule";
const GO_BACK_BTN_LABEL = "Go Back";
const CANCEL_BTN_LABEL = "Cancel";
//FRONT-4080
const ORIGIN_NEW_ACCOUNT_OVERRIDE_ACTION = "NewActionOverride";
const ORIGIN_ACTION_BUTTON = "ActionButton";
const NEW_SCREEN = "NewScreen";
// FRONT-808 Starts
const HARDSTOPDUPLICATERULE_LEGACY = "Account_DL_Duplicate_Rule";
// FRONT-808 Ends
export default class Sbr_3_0_duplicateRecordResolver extends NavigationMixin(
  LightningElement
) {
  @api screenname; //4001
  _duplicateRecordIds;
  _duplicateRule;
  _fields;
  _record;
  _getRecordsPayload;
  showViewButton = false;

  _props;
  _origin;
  _resolutionMethod;
  _selectedRecord;
  _resolutionPayload;
  @api iconName = "standard:account";
  duplicateRecords;
  hardStopDuplicateRecord;
  header = LABELS.DUPLICATEACCOUNTSHEADER || DUPLICATE_SCREEN_HEADER;
  proceedLabel = LABELS.DUPLICATEACCOUNTSECTIONHEADER || METHOD_SECTION_HEADING;
  columns = COLUMNS;
  @track methodOptions;
  _isHardstop; //Added as part of FRONT-4851
  hideUseExistingAccCheckBox = false; //Added as part of FRONT-4851
  isUseExistingAccountButtonDisabled = true; //Added as part of FRONT-4851
  viewExistingAccountButton = LABELS.VIEW_EXISTING_ACCOUNT_BUTTON;
  isViewButtonClicked = false;
  label = LABELS;
  isActiveRecordSelected = true; //FRONT-6263 Used in disabled attribute of Existing Accounts checkbox
  @api
  get props() {
    return this._props;
  }

  set props(value) {
    this._props = value;
    this.init();
  }
  //FRONT-4466 start
  get ProceedLabelAction() {
    let dynamicVar = "";
    if (this.screenname === EDIT_SCREEN_FROM_TRANSACTION) {
      dynamicVar = "editing";
    } else if (this.screenname === CONVERT_SCREEN_FROM_TRANSACTION) {
      dynamicVar = "converting to";
    } else {
      dynamicVar = "creating";
    }
    return ACTION_SECTION_HEADING.replace("placeholder", dynamicVar);
  }

  get isMobileView() {
    return FORM_FACTOR === SMALL_FORM_FACTOR;
  }

  get isLoading() {
    return !(this._duplicateRecordIds && this.duplicateRecords);
  }

  get isContinueButtonDisabled() {
    return !(
      this._resolutionMethod &&
      ((this._resolutionMethod === EXISTING_RESOLUTION &&
        this._selectedRecord) ||
        this._resolutionMethod === NEW_RESOLUTION)
    );
  }

  get totalDuplicateSubHeading() {
    return this.isLoading
      ? ""
      : `${
          LABELS.TOTALDUPLICATEACCOUNTS || TOTAL_DUPLICATE_ACCOUNTS_SUB_HEADING
        } : {${this._duplicateRecordIds.length}}`;
  }

  get hardStopDuplicateSubHeading() {
    return this.isLoading
      ? ""
      : `${
          LABELS.HARD_STOP_ACCOUNT_SUB_HEADING ||
          HARDSTOP_DUPLICATE_ACCOUNTS_SUB_HEADING
        }`;
  }

  get hardStopContinueLabel() {
    return this.isLoading
      ? ""
      : `${LABELS.HARD_STOP_ACCOUNT_PROCEED_MESSAGE || HARDSTOP_PROCEED_LABEL}`;
  }

  get duplicateRecordMessage() {
    return `${this._serializedCurrentRecord}${
      DUPLICATE_SERIALIZED_MESSAGE_END || DUPLICATEACCOUNTSALREADYINUSE
    }`;
  }

  get duplicateRecordMessageEdit() {
    return `${this._serializedCurrentRecord}${DUPLICATE_SERIALIZED_MESSAGE}`;
  }

  get duplicateHardStopRecordMessage() {
    let message;
    if (this.isLoading) {
      message = "";
    } else if (this.isMobileView) {
      message = `${
        LABELS.HARD_STOP_MESSAGE || HARDSTOP_DUPLICATE_SERIALIZED_MESSAGE_END
      }`;
    } else {
      message = `${
        LABELS.HARD_STOP_MESSAGE || HARDSTOP_DUPLICATE_SERIALIZED_MESSAGE_END
      }`;
    }
    return message;
  }

  init() {
    console.log("this:::", this._props?.duplicateRecords);
    this.setDuplicateRecordIds();
    this.setFields();
    this.setCurrentRecord();
    this.setOrigin();
    this.setDuplicateRuleName();
    this.setMethodOptions();
    this.buildDuplicateData(this._props?.duplicateRecords);
    this.setHideUseExistingForNonTransactionFlows();
  }

  setDuplicateRecordIds() {
    this._duplicateRecordIds = this.props.duplicateRecordIds;
  }

  setDuplicateRuleName() {
    this._duplicateRule = this.props.duplicateRuleName;
    // FRONT-808 Starts
    this._isHardstop =
      this._duplicateRule === HARDSTOPDUPLICATERULE ||
      this._duplicateRule === HARDSTOPDUPLICATERULE_LEGACY;
    // FRONT-808 Ends
  }

  setFields() {
    this._fields = this.props.fields || DEFAULT_FIELDS_TO_QUERY;
  }

  setCurrentRecord() {
    this._record = this.props.currentRecord;
    this.setSerializedCurrentRecord();
  }

  setSerializedCurrentRecord() {
    let address = {};
    address.BillingStreet = this._record.BillingStreet;
    address.BillingCity = this._record.BillingCity;
    address.BillingStateCode = this._record.BillingStateCode;
    address.BillingCountryCode = this._record.BillingCountryCode;
    address.BillingPostalCode = this._record.BillingPostalCode;
    this.setAccountAddress(address);
    this._serializedCurrentRecord = `{${
      LABELS.ACCOUNTNAME || ACCOUNT_NAME_LABEL
    }: ${this._record.Name}, ${LABELS.ACC_EMAIL || EMAIL_LABEL}: ${
      this._record.E_mail_Address__c
    }, ${LABELS.PHONE || PHONE_LABEL}: ${this.formatPhone(
      this._record.Phone
    )}, ${LABELS.BILL_ADDRESS || BILLING_ADDRESS_LABEL}: ${
      address.BillingAddress
    }}`;
  }

  setOrigin() {
    this._origin = this.props.origin;
  }

  //Modified as part of FRONT-4851
  buildMethodOptions() {
    if (this._isHardstop) {
      return this.buildHardStopMethodOptions();
    } else {
      return this.buildSoftStopMethodOptions();
    }
  }

  render() {
    return this.getTemplate();
  }

  getTemplate() {
    //start FRONT-4481, FRONT-4081, FRONT-808
    if (
      (this._origin === ORIGIN_ACTION_BUTTON ||
        this._origin === ORIGIN_NEW_ACCOUNT_OVERRIDE_ACTION) &&
      this.isMobileView &&
      !this._isHardstop
    ) {
      this._currentTemplate = MOBILE_SOFT_SOFT_ACTION;
    }
    //end FORNT-4481
    //FRONT-4597, FRONT-4480, FRONT-4466, FRONT-808
    else if (
      this._origin === ORIGIN_ACTION_BUTTON &&
      !this.isMobileView &&
      !this._isHardstop &&
      (this.screenname === CONVERT_SCREEN_FROM_TRANSACTION ||
        this.screenname === EDIT_SCREEN_FROM_TRANSACTION)
    ) {
      this._currentTemplate = DESKTOP_SOFT_STOP_BG_ACTION;
    } //start - For opening the soft stop template from the new Account screen in Desktop
    // FRONT-808
    else if (
      (this._origin === ORIGIN_ACTION_BUTTON ||
        this._origin === ORIGIN_NEW_ACCOUNT_OVERRIDE_ACTION) &&
      !this.isMobileView &&
      !this._isHardstop &&
      this.screenname !== CONVERT_SCREEN_FROM_TRANSACTION
    ) {
      this._currentTemplate = DESKTOP_SOFT_STOP_TEMPLATE_ACTION;
    } else if (
      // FRONT-808
      this._origin === ORIGIN_ACTION_BUTTON &&
      !this.isMobileView &&
      this._isHardstop &&
      (this.screenname === EDIT_SCREEN_FROM_TRANSACTION ||
        this.screenname === CONVERT_SCREEN_FROM_TRANSACTION)
    ) {
      this._currentTemplate = DESKTOP_HARD_STOP_BG_ACTION;
    }

    //FRONT-4597, FRONT-4480, FRONT-808
    else {
      this._currentTemplate = this.isMobileView
        ? this._isHardstop
          ? MOBILE_LANDING_HARDSTOP_PAGE_TEMPLATE
          : MOBILE_LANDING_PAGE_TEMPLATE
        : this._isHardstop
          ? DESKTOP_HARD_STOP_TEMPLATE
          : DESKTOP_SOFT_STOP_TEMPLATE;
    }
    return this._currentTemplate;
  }

  renderedCallback() {
    if (
      this._origin === RESERVATION_ORDER_ORIGIN ||
      this._origin === CONTRACT_ORDER_ORIGIN
    ) {
      var ite = this.template.querySelectorAll('[data-id="divItem"]');
      ite.forEach((ele) => ele.classList.add("itemVal"));
    }
  }

  showToast(title, message, variant = "error") {
    const event = new ShowToastEvent({
      title,
      message,
      variant
    });
    this.dispatchEvent(event);
  }

  buildDuplicateData(data) {
    const duplicateRecords = [];
    for (let account of data) {
      let acc = JSON.parse(JSON.stringify(account));
      this.setAccountAddress(acc);
      this.setRadioBoxSelectionState(acc);
      this.setStatusClass(acc);
      this.setFormattedPhone(acc);
      this.checkReservationActiveAccounts(acc); //FRONT-6263 Added this method here from below so that it can be run on loop for all the account records
      duplicateRecords.push(acc);
    }

    this.duplicateRecords = duplicateRecords;
    this.setHideCheckboxReservationInactiveAccounts(this.duplicateRecords); // FRONT-6263 Added to check if all are inactive accounts then hide checkbox in reservation order
  }

  setAccountAddress(acc) {
    acc.BillingAddress = [
      acc.BillingStreet,
      acc.BillingCity,
      acc.BillingStateCode,
      acc.BillingCountryCode,
      acc.BillingPostalCode
    ]
      .filter(Boolean)
      .join(", ");
  }

  setRadioBoxSelectionState(acc) {
    acc.isSelected = this.setSelectedState(acc);
    acc.isDisabled = this.setDisabledState(acc);
  }

  setSelectedState(acc) {
    return (
      !isUndefinedOrNull(this._selectedRecord) &&
      this._selectedRecord.Id === acc.Id
    );
  }

  setDisabledState(acc) {
    return (
      this._resolutionMethod !== EXISTING_RESOLUTION ||
      (acc.Status__c !== ACTIVE_STATUS &&
        (this._origin === RESERVATION_ORDER_ORIGIN ||
          this._origin === CONTRACT_ORDER_ORIGIN))
    );
  }

  setStatusClass(acc) {
    let defaultClass = "color-boxes";
    let colorClass = STATUS_TO_CSS_CLASS_MAP[acc.Status__c] || "";
    acc.computedStatusClasses = `${defaultClass} ${colorClass}`;
  }

  setFormattedPhone(acc) {
    acc.Phone = this.formatPhone(acc.Phone);
  }

  formatPhone(phone) {
    return phone?.replace(/^(\d{3})(\d{3})(\d{4})/, "$1-$2-$3");
  }

  handleResolveChange(event) {
    event.stopPropagation();
    const resolutionSelected = event.target.value;
    switch (resolutionSelected) {
      case NEW_RESOLUTION:
        this.resolveDuplicateWithNew();
        break;
      case EXISTING_RESOLUTION:
        this.resolveDuplicateWithExisting();
        break;
      default:
        break;
    }
    this.methodOptions = this.buildMethodOptions();
  }

  resolveDuplicateWithNew() {
    this._resolutionMethod = NEW_RESOLUTION;
    this._selectedRecord = undefined;
    this.duplicateRecords = this.getFreshDuplicateRecords();
    this.setResolutionPayload();
  }

  resolveDuplicateWithExisting() {
    this._resolutionMethod = EXISTING_RESOLUTION;
    this.duplicateRecords = this.getFreshDuplicateRecords();
    this.setResolutionPayload();
  }

  /*FRONT-6263 Changed the payload selectedRecord var to be sent in custom event 'resolveselection'
   * First it was sent for only the first duplicate record
   * Now it is sent for the record that is selected by selecting the radio group.
   */
  setResolutionPayload() {
    this._resolutionPayload = {
      resolveBy: this._resolutionMethod
    };
    if (this._isHardstop) {
      //this._resolutionPayload.selectedRecord = this.duplicateRecords?.[0];
      this._resolutionPayload.selectedRecord = this._selectedRecord;
    }
  }

  /* FRONT-6263 Used this method in onchange event of radio group
   * Changes in the method - Setting isActiveRecordSelected variable according to status
   * isActiveRecordSelected variable is used to disable/enable the Existing Account checkbox
   */
  handleRecordSelectionChange(event) {
    const selectedRecordId = event.target.value;

    this._selectedRecord = this.duplicateRecords.find(
      (record) => record.Id === selectedRecordId
    );
    console.log(
      "selected Record",
      selectedRecordId,
      JSON.stringify(this._selectedRecord)
    );
    if (this._isHardstop) {
      if (this._selectedRecord) {
        this.isActiveRecordSelected = false;
      }
    }
    this.duplicateRecords = this.getFreshDuplicateRecords();
    if (!this._resolutionPayload) {
      this._resolutionPayload = {};
    }
    this._resolutionPayload.selectedRecord = this._selectedRecord;
  }

  getFreshDuplicateRecords() {
    return this.duplicateRecords.map((record) => {
      let clonedRecord = { ...record };
      clonedRecord.isSelected = this.setSelectedState(clonedRecord);
      clonedRecord.isDisabled = this.setDisabledState(clonedRecord);
      return clonedRecord;
    });
  }

  handleCloseModal() {
    this.dispatchEvent(new CustomEvent("resolvecancel"));
  }

  handleCancelModal() {
    if (this._origin === ORIGIN_NEW_ACCOUNT_OVERRIDE_ACTION) {
      this.dispatchEvent(
        new CustomEvent("hardstopcancel", { detail: this._origin })
      ); // Added as part of FRONT-4929
    } else {
      this.dispatchEvent(new CustomEvent("hardstopcancel"));
    }
  }

  handleContinueClick() {
    this.dispatchEvent(
      new CustomEvent("resolveselection", {
        detail: this._resolutionPayload
      })
    );
  }
  /** Kishore Meesala
   * FRONT-4080*/
  handleYesClick() {
    this.resolveDuplicateWithNew();
    this.dispatchEvent(
      new CustomEvent("resolveselection", {
        detail: this._resolutionPayload
      })
    );
  }

  get cancelButtonLabel() {
    return LABELS.CANCEL || CANCEL_BTN_LABEL;
  }
  get goBackButtonLabel() {
    return LABELS.GO_BACK || GO_BACK_BTN_LABEL;
  }
  get existingButtonLabel() {
    return (
      LABELS.DUPLICATECONTINUEWITHEXISTING || LABELS.USE_EXISTING_ACCOUNT_LABEL
    );
  }
  // FRONT-808
  get duplicateDivEditAction() {
    if (
      this._origin === ORIGIN_ACTION_BUTTON &&
      !this.isMobileView &&
      !this._isHardstop &&
      this.screenname === EDIT_SCREEN_FROM_TRANSACTION
    ) {
      return "duplicate-div-edit-action";
    } else {
      return "";
    }
  }

  // FRONT-808
  get closeButtonStyling() {
    logger.log(this._origin + "" + this.screenname);
    if (
      this._origin === ORIGIN_ACTION_BUTTON &&
      !this.isMobileView &&
      !this._isHardstop &&
      this.screenname === EDIT_SCREEN_FROM_TRANSACTION
    ) {
      return "close-button-edit-action";
    } else {
      return "posClass";
    }
  }
  setMethodOptions() {
    this.methodOptions = this.buildMethodOptions();
  }
  //Added as part of FRONT-4851
  buildHardStopMethodOptions() {
    const self = this;
    return [
      {
        label:
          LABELS.DUPLICATECONTINUEWITHEXISTING || USE_EXISTING_ACCOUNT_LABEL,
        value: EXISTING_RESOLUTION,
        get checked() {
          return this.value === self._resolutionMethod;
        },
        info: LABELS.DUPLICATESELECTEXISTING || USE_EXISTING_ACCOUNT_DESCRIPTION
      }
    ];
  }
  //Added as part of FRONT-4851
  buildSoftStopMethodOptions() {
    const self = this;
    return [
      {
        label: LABELS.DUPLICATENEWACCOUNT || USE_NEW_ACCOUNT_LABEL,
        value: NEW_RESOLUTION,
        get checked() {
          return this.value === self._resolutionMethod;
        },
        // Started for FRONT - 3878, 3880, 4001, 3883
        get info() {
          if (self.screenname === CONVERT_SCREEN_FROM_TRANSACTION) {
            return LABELS.ConvertLabel;
          } else {
            return self.screenname === EDIT_SCREEN_FROM_TRANSACTION
              ? LABELS.EditingLabel
              : LABELS.DUPLICATECONTINUEWITHNEWACCOUNT ||
                  USE_NEW_ACCOUNT_DESCRIPTION;
          }
        }
        // ENDED for FRONT - 3878, 3880, 4001, 3883
      },
      {
        label:
          LABELS.DUPLICATECONTINUEWITHEXISTING || USE_EXISTING_ACCOUNT_LABEL,
        value: EXISTING_RESOLUTION,
        get checked() {
          return this.value === self._resolutionMethod;
        },
        info: LABELS.DUPLICATESELECTEXISTING || USE_EXISTING_ACCOUNT_DESCRIPTION
      }
    ];
  }
  //Added as part of FRONT-4851
  handleHardStopResolveChange(event) {
    event.stopPropagation();
    const existingDupAccountChecked = event.target.checked;
    this.isUseExistingAccountButtonDisabled = !existingDupAccountChecked;
    if (existingDupAccountChecked) {
      this.resolveDuplicateWithExisting();
    }
  }
  //Added as part of FRONT-4851
  /*FRONT-6263 Changes - added a parameter as now it is called from a loop of records
   * For each record setting the variable disableRadioButton as per origin
   * If the origin is from order flow then disable the radio group for inactive accounts
   * For all other, it will be enabled.
   */
  checkReservationActiveAccounts(acc) {
    if (
      this._isHardstop &&
      acc.Status__c !== ACTIVE_STATUS &&
      (this._origin === RESERVATION_ORDER_ORIGIN ||
        this._origin === CONTRACT_ORDER_ORIGIN)
    ) {
      acc.disableRadioButton = true;
    } else {
      acc.disableRadioButton = false;
    }
  }
  //Added as part of FRONT-4931
  /*FRONT-6263 This method is used to navigate to the account that is selected
   * When the user will click on the Account Name link, it will be directed to this method
   * Changes done are instead of the first duplicate record Id, we are now setting the selected Record Id.
   */
  handleNavigateToExistingAccount(event) {
    console.log(JSON.stringify(this._selectedRecord));
    if (this._isHardstop) {
      let selectedRecordId = event.target.dataset.id || this._selectedRecord.Id;

      this[NavigationMixin.GenerateUrl]({
        type: "standard__recordPage",
        attributes: {
          recordId: selectedRecordId,
          objectApiName: "Account",
          actionName: "view"
        }
      }).then((generatedUrl) => {
        window.open(generatedUrl);
      });
    }
  }

  //---FRONT-4932,5528 start---//
  get cancelButton() {
    return LABELS.CANCEL;
  }

  get confirmButton() {
    return LABELS.CONFIRM;
  }

  get duplicateAccountInputLostModalHeader() {
    let header = "";
    if (this.screenname === NEW_SCREEN) {
      header = LABELS.VIEW_DUPLICATE_INPUT_LOST_HEADER;
    } else if (this.screenname === EDIT_SCREEN_FROM_TRANSACTION) {
      header = LABELS.VIEW_DUPLICATE_INPUT_LOST_HEADER_EDIT;
    } else if (this.screenname === CONVERT_SCREEN_FROM_TRANSACTION) {
      header = LABELS.VIEW_DUPLICATE_INPUT_LOST_HEADER_CONVERT;
    }
    return header;
  }

  get duplicateAccountInputLostModalDescription() {
    let description = "";
    if (this.screenname === NEW_SCREEN) {
      description = LABELS.VIEW_DUPLICATE_INPUT_LOST_DESCRIPTION;
    } else if (this.screenname === EDIT_SCREEN_FROM_TRANSACTION) {
      description = LABELS.VIEW_DUPLICATE_INPUT_LOST_DESCRIPTION_EDIT;
    } else if (this.screenname === CONVERT_SCREEN_FROM_TRANSACTION) {
      description = LABELS.VIEW_DUPLICATE_INPUT_LOST_DESCRIPTION_CONVERT;
    }
    return description;
  }

  //FRONT-6263 Thsi method is called when clicked on Account Name clickable link.
  handleAccountNameClickMobile(event) {
    this.isViewButtonClicked = true;
    if (event.target.dataset.id) {
      this._selectedRecord = this.duplicateRecords.find(
        (record) => record.Id === event.target.dataset.id
      );
    }
  }

  handleDialogCancel() {
    this.isViewButtonClicked = false;
  }
  //---FRONT-4932,5528 end---//

  get duplicateRecordListHeader() {
    return this._isHardstop
      ? LABELS.DUPLICATEEXISTINGACCOUNTS_HS
      : LABELS.DUPLICATEEXISTINGACCOUNTS;
  }

  // FRONT-808
  setHideUseExistingForNonTransactionFlows() {
    if (
      (this._origin === ORIGIN_ACTION_BUTTON ||
        this._origin === ORIGIN_NEW_ACCOUNT_OVERRIDE_ACTION) &&
      this._isHardstop
    ) {
      this.hideUseExistingAccCheckBox = true;
      this.showViewButton = true;
    }
  }

  get isViewExistingDisabled() {
    return !this._selectedRecord;
  }

  //FRONT-6263 Method called to check if in Order flow if any of duplicate account is Active then don't hide existing checkbox oterwise hide it
  setHideCheckboxReservationInactiveAccounts(duplicateRecords) {
    if (
      this._isHardstop &&
      (this._origin === RESERVATION_ORDER_ORIGIN ||
        this._origin === CONTRACT_ORDER_ORIGIN)
    )
      this.hideUseExistingAccCheckBox = !duplicateRecords.some(
        (record) => record.Status__c === ACTIVE_STATUS
      );
  }
}