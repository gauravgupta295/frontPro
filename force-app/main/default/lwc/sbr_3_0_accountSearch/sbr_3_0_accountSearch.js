import { LightningElement, track, api } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import { NavigationMixin } from "lightning/navigation";
const SMALL_FORM_FACTOR = "Small";
const OBJECT_PAGE = "standard__objectPage";
const RECORD_PAGE = "standard__recordPage";
export default class Sbr_3_0_accountSearch extends NavigationMixin(
  LightningElement
) {
  @track isModalOpen;
  @track searchKey = "";
  isMobile = false;

  connectedCallback() {
    this.isMobile = FORM_FACTOR === SMALL_FORM_FACTOR;
    this.dispatchEvent(
      new CustomEvent("settabname", {
        detail: {
          tabName: "Account Search"
        }
      })
    );
  }

  hideResults(event) {
    if (event.detail && event.detail.acc && event.detail.acc.Id) {
      this.navigateToRecord(event.detail.acc.Id);
    } else {
      this.emitCloseCurrentTab(true);
    }
  }

  emitCloseCurrentTab(navigateToAccountPage = false) {
    this.dispatchEvent(
      new CustomEvent("closetab", { detail: { navigateToAccountPage } })
    );
  }
  closeModal() {
    this.isModalOpen = false;
  }

  closeMobileAccountSearch() {
    this.emitCloseCurrentTab(true);
  }

  showAccountCreationModal(event) {
    this.isModalOpen = true;
  }
  @api
  navigateToPreviousPage(props = {}) {
    let replace = props.replace === undefined ? true : props.replace;
    this[NavigationMixin.Navigate](
      {
        type: OBJECT_PAGE,
        attributes: {
          objectApiName: "Account",
          actionName: "list"
        },
        state: {
          filterName: "Recent"
        }
      },
      replace
    );
  }

  navigateToRecord(recordId) {
    if (recordId) {
      this[NavigationMixin.Navigate](
        {
          type: RECORD_PAGE,
          attributes: {
            recordId: recordId,
            objectApiName: "Account",
            actionName: "view"
          }
        },
        true
      );
    }
  }

  resultFromMobileCmp(event) {
    if (event.detail) {
      let account = JSON.parse(JSON.stringify(event.detail.selectedRecord));
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: account.Id,
          objectApiName: "Account",
          actionName: "view"
        }
      });
    }
  }
}