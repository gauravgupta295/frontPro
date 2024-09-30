import { LightningElement, api, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import { isUndefinedOrNull, Logger } from "c/sbr_3_0_frontlineUtils";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import FORM_FACTOR from "@salesforce/client/formFactor";

const OBJECT_PAGE = "standard__objectPage";
const RECORD_PAGE = "standard__recordPage";
const NEW_ACTION = "new";
const LIST_ACTION = "list";
const HOME_ACTION = "home";
const VIEW_ACTION = "view";
const CANCEL_ACTION = "cancel";
const OVERRIDDEN_RECORDTYPES = ["Prospect", "Non-Credit"];
const SMALL_FORM_FACTOR = "Small";
const NAVIGATE_USING_HEADER_MOBILE_MESSAGE =
  "Please use the header to navigate to previous page.";
const NEW_ACTION_OVERRIDE = "NewActionOverride";
const RECORD_SELECTION_ORIGIN = "RecordTypeSelection";
const logger = Logger.create(false);
export default class Sbr_3_0_AccountNewActionOverrideDelegator extends NavigationMixin(
  LightningElement
) {
  @api
  objectApiName = ACCOUNT_OBJECT.objectApiName;
  _currentPageReference = null;
  _previousPageReference = null;
  recordTypeId;
  _interval;
  _previousPath;
  _recordTypesInfo;
  currentRecordType;
  currentCmpName = NEW_ACTION_OVERRIDE;
  message;

  @wire(getObjectInfo, {
    objectApiName: "$objectApiName"
  })
  objectInfo({ error, data }) {
    if (data) {
      this._recordTypesInfo = data.recordTypeInfos;
      this.setCurrentRecordTypeOnLoad();
    } else if (error) {
      console.log(error);
    }
  }

  @wire(CurrentPageReference)
  getPageReferenceParameters(currentPageReference) {
    if (currentPageReference) {
      this._currentPageReference = currentPageReference;
      this.getAttributesFromPg();
    }
  }

  getAttributesFromPg() {
    if (this._currentPageReference?.state?.recordTypeId) {
      this.setCurrentRecordTypeId(
        this._currentPageReference?.state?.recordTypeId
      );
      this.setCurrentRecordTypeOnLoad();
    }
    this.setPreviousPageReferenceOnLoad();
    this.setOriginStateOnLoad(this._currentPageReference?.state?.c__origin);
  }

  setPreviousPageReferenceOnLoad() {
    this._previousPageReference = this.getPreviousPageReference(
      this._currentPageReference
    );
  }

  setOriginStateOnLoad(origin) {
    this._origin = origin;
  }

  setCurrentRecordTypeId(recordTypeId) {
    this.recordTypeId = recordTypeId;
  }

  setCurrentRecordTypeOnLoad() {
    if (!this.isLoading) {
      let currentRecordTypeInfo = this._recordTypesInfo[this.recordTypeId];
      this.currentRecordType = {
        id: currentRecordTypeInfo.recordTypeId,
        label: currentRecordTypeInfo.name,
        value: currentRecordTypeInfo.name
      };
    }
  }

  connectedCallback() {
    this._previousPath = window.location.href;
  }

  get isLoading() {
    return !(this._recordTypesInfo && this.recordTypeId);
  }

  get showRecordSelectionScreen() {
    return isUndefinedOrNull(this.recordTypeId);
  }

  get isActionOverrideViewAvailable() {
    let isViewAvailable = false;
    if (!this.isLoading) {
      if (!this.isViewOverridden) {
        this.navigateToStdActionView();
      } else {
        isViewAvailable = true;
      }
    }

    return isViewAvailable;
  }

  get isViewOverridden() {
    return OVERRIDDEN_RECORDTYPES.includes(this.currentRecordType?.value);
  }
  navigateToStdActionView(action = NEW_ACTION) {
    this.setCancelClickBehavior();
    this.navigateAsynchronously(this.getNewActionPageReference(action));
  }

  setCancelClickBehavior() {
    if (this.isMobileView) {
      this.showMessageDialogForBackNavigation();
    } else {
      this.observeUrlChange(false);
    }
  }

  showMessageDialogForBackNavigation() {
    this.message = NAVIGATE_USING_HEADER_MOBILE_MESSAGE;
  }

  navigateAsynchronously(pageReference) {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    window.setTimeout(() => {
      this[NavigationMixin.Navigate](pageReference, !this.isMobileView);
    }, 1);
  }

  getNewActionPageReference(action = NEW_ACTION) {
    return {
      type: OBJECT_PAGE,
      attributes: {
        objectApiName: this.objectApiName,
        actionName: action
      },
      state: {
        nooverride: 1,
        recordTypeId: this.recordTypeId
      }
    };
  }

  handleCloseModal(event) {
    event.stopPropagation();
    this.navigate(event);
  }

  navigate(event) {
    if (event?.detail?.navigateTo) {
      this[NavigationMixin.Navigate](event.detail.navigateTo, true);
      return;
    }
    const actionType = event?.detail?.action;
    switch (actionType) {
      case VIEW_ACTION:
        this.navigateToRecord(event);
        break;
      case CANCEL_ACTION:
        this.handleCustomCancelNavigation();
        break;
      default:
        this.navigateToPreviousPage();
    }
  }

  @api
  navigateToPreviousPage(props = {}) {
    let { pageReference, replace } = props;
    pageReference = pageReference || this._currentPageReference;
    replace = replace === undefined ? true : replace;
    let previousPageReference =
      this._previousPageReference ||
      this.getPreviousPageReference(pageReference);
    this.clearUrlObserverInterval();
    this[NavigationMixin.Navigate](previousPageReference, replace);
  }

  getPreviousPageReference(currentPageReference) {
    let previousPageReference;
    let parentContextOf = currentPageReference?.state?.inContextOfRef;
    if (isUndefinedOrNull(parentContextOf)) {
      previousPageReference = this.getObjectHomeReference();
    } else {
      previousPageReference =
        this.getPreviousPageReferenceRecursively(parentContextOf);
    }

    return previousPageReference;
  }

  getObjectHomeReference() {
    return {
      type: OBJECT_PAGE,
      attributes: {
        objectApiName: this.objectApiName,
        actionName: HOME_ACTION
      }
    };
  }

  getPreviousPageReferenceRecursively(contextOf) {
    let pageReference = JSON.parse(atob(contextOf.substring(2)));
    if (pageReference?.state?.inContextOfRef) {
      pageReference = this.getPreviousPageReferenceRecursively(
        pageReference.state.inContextOfRef
      );
    } else if (pageReference?.attributes?.actionName === LIST_ACTION) {
      pageReference = this.getObjectHomeReference();
    }
    return pageReference;
  }

  get isMobileView() {
    return FORM_FACTOR === SMALL_FORM_FACTOR;
  }
  /**
   * This is a hack to track the URL changes in non-console applications.
   * In non-console applications, the record creation opens as a panel and our overridden component
   * stays in the background. If user clicks on "Cancel" button, the panel is closed, however our overridden component
   * remains and is not destroyed. This hack is to mitigate that. This is not applicable to mobile applications either because
   * the url doesn't change in mobile.
   *
   */
  observeUrlChange(isBackEvent = true) {
    if (this.isMobileView) {
      return;
    }

    if (!this._interval) {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this._interval = setInterval(() => {
        try {
          const currUrl = window.location.href;
          if (currUrl === this._previousPath && isBackEvent) {
            this.navigateToPreviousPage();
          } else {
            isBackEvent = true;
          }
        } catch (e) {
          logger.error(e);
        }
      }, 1000);
    }
  }

  clearUrlObserverInterval() {
    if (this._interval) {
      clearInterval(this._interval);
    }
  }

  disconnectedCallback() {
    this.clearUrlObserverInterval();
  }

  navigateToRecord(event) {
    const detail = event?.detail;

    if (detail.recordId) {
      this[NavigationMixin.Navigate](
        {
          type: RECORD_PAGE,
          attributes: {
            recordId: detail.recordId,
            objectApiName: ACCOUNT_OBJECT.objectApiName,
            actionName: VIEW_ACTION
          }
        },
        true
      );
    } else {
      this.navigateToPreviousPage();
    }
  }

  handleCustomCancelNavigation() {
    if (this._origin === RECORD_SELECTION_ORIGIN) {
      this.navigateToRecordTypeSelection();
    } else {
      this.emitCloseCurrentTab();
    }
  }

  emitCloseCurrentTab(navigateToAccountPage = false) {
    this.dispatchEvent(
      new CustomEvent("closetab", { detail: { navigateToAccountPage } })
    );
  }

  handleRecordTypeCancelClick() {
    this.emitCloseCurrentTab(true);
  }

  handleRecordTypeSelection(event) {
    event.stopPropagation();
    this.setCurrentRecordType(event.detail.recordType);
    this.setCurrentRecordTypeId(this.currentRecordType.id);
    this.setOriginStateOnLoad(event.detail.origin);
  }

  setCurrentRecordType(recordType) {
    this.currentRecordType = recordType;
  }

  navigateToRecordTypeSelection() {
    this.currentRecordType = null;
    this.recordTypeId = null;
  }
}