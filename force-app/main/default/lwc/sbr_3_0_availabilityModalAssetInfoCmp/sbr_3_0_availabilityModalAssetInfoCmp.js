import { LightningElement, track, api } from "lwc";
import fetchAssetInformation from "@salesforce/apex/SBR_3_0_AvailabilityModalInfoCmpCon.fetchAssetInformation";
import { NavigationMixin } from "lightning/navigation";

export default class Sbr_3_0_availabilityModalAssetInfoCmp extends NavigationMixin(
  LightningElement
) {
  @track assetWrapper = {};
  @track assetInformation = {};
  @track orderInformation = {};

  @api productCat;
  @api branchNum;
  @api selectedAssetId;
  @track isLoading = false;

  isMobile;
  itemSize;
  activeTab;
  orderRecordId;
  showContractNumber;
  formattedPhoneNumber;
  phoneValue;

  jobsite;

  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    this.itemSize = this.isMobile ? "12" : "6";
    this.isLoading = true;
    fetchAssetInformation({ assetId: this.selectedAssetId })
      .then((result) => {
        console.debug(JSON.parse(JSON.stringify(result)));

        this.assetWrapper = result;
        this.assetInformation = result.asset;
        if (result.order) {
          this.orderInformation = result.order;
          this.jobsite = result.order.Order.Jobsite__r;
          this.orderRecordId = "/" + result.order.OrderId;
          if (result.order.Order.Contract_Order_Number__c) {
            this.showContractNumber = true;
          }
          if (result.order?.Order?.Branch__r?.Phone__c) {
            let phoneNumber = result.order.Order.Branch__r.Phone__c;
            this.phoneValue = "tel:" + phoneNumber;
            this.formattedPhoneNumber =
              phoneNumber.length === 11
                ? phoneNumber.replace(
                    /(\d{1})(\d{3})(\d{3})(\d{3})/,
                    "+$1 ($2)-$3-$4"
                  )
                : phoneNumber.replace(/(\d{3})(\d{3})(\d{4})/, "($1)-$2-$3");
          }
        }

        if (this.isMobile) {
          this.dispatchEvent(
            new CustomEvent("newheadertext", {
              detail: "Asset #" + this.assetInformation.SM_PS_Asset_Id__c
            })
          );
        }

        this.isLoading = false;
      })
      .catch((error) => {
        console.log("error message on fetching Asset " + error.message);
        this.isLoading = false;
      });
  }

  toggleSection(event) {
    let buttonid = event.currentTarget.dataset.buttonid;
    let currentsection = this.template.querySelector(
      '[data-id="' + buttonid + '"]'
    );
    if (currentsection.className.search("slds-is-open") == -1) {
      currentsection.className = "slds-section slds-is-open";
    } else {
      currentsection.className = "slds-section slds-is-close";
    }
  }

  navigateToRecord(event) {
    event.stopPropagation();

    let recordId = event.target.dataset.id;
    let newTab = event.target.dataset.newtab;

    if (recordId) {
      if (!this.isMobile && newTab) {
        this[NavigationMixin.GenerateUrl]({
          type: "standard__recordPage",
          attributes: {
            recordId: recordId,
            actionName: "view"
          }
        }).then((url) => {
          window.open(url, "_blank");
        });
      } else {
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: recordId,
            actionName: "view"
          }
        });
      }
    }
  }
}