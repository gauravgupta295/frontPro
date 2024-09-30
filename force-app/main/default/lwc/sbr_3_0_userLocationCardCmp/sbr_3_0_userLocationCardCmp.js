import { LightningElement, api } from "lwc";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";
import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName"; //Front-1644
import FrontlineTemplate from "./sbr_3_0_userLocationCardCmpFrontline.html"; //Front-1644
import defaultTemplate from "./sbr_3_0_userLocationCardCmp.html"; //Front-1644
import Sbr_3_0_address_Css from "@salesforce/resourceUrl/Sbr_3_0_AddressCss"; //1644
import { loadStyle } from "lightning/platformResourceLoader"; //1644
export default class sbr_3_0_userLocationCardCmp extends LightningElement {
  @api salesRepsList;
  @api userId;
  @api repId;
  @api source;

  isDisabled = false;
  searchKey;
  filteredSalesRepsList;
  showFrontlineComponents = false;
  connectedCallback() {
    //1644 start
    getAppName()
      .then((results) => {
        this.appName = results;
        if (this.appName === "RAE Frontline") {
          this.showFrontlineComponents = true;
        }
      })
      .catch((error) => {
        console.log("error");
      });
    //1644 end
    if (this.salesRepsList.length === 0) {
      this.isDisabled = true;
    }
    this.salesRepsList = JSON.parse(JSON.stringify(this.salesRepsList));
    this.filteredSalesRepsList = this.salesRepsList;
  }

  //Front-1644 start
  render() {
    if (this.showFrontlineComponents) {
      return FrontlineTemplate;
    } else {
      return defaultTemplate;
    }
  }
  renderedCallback() {
    Promise.all([loadStyle(this, Sbr_3_0_address_Css)])
      .then(() => {})
      .catch((error) => {});
    //added for front-20271
    if (this.source != "Order") {
      this.template.querySelector('.parent-container').classList.add('par');
      this.template.querySelector('hr').classList.add('hrr');
    } else {
      this.template.querySelector('.parent-container').classList.add('par2');
      this.template.querySelector('hr').classList.add('hrr2');
    }
  }
  //Front-1644 end
  handleChange(event) {
    // SF-5340
    this.userId = event.currentTarget.dataset.user;
    console.log("*** this.userId : ", this.userId);
    this.repId = event.currentTarget.dataset.rep;
    console.log("*** this.repId : ", this.repId);
    this.dispatchEvent(
      new FlowAttributeChangeEvent("userId", event.currentTarget.dataset.user)
    );
    this.dispatchEvent(
      new FlowAttributeChangeEvent("repId", event.currentTarget.dataset.rep)
    );
  }

  handleKeyChange(event) {
    this.searchKey = event.target.value;
    this.filterList();
  }

  filterList() {
    if (this.searchKey) {
      this.filteredSalesRepsList = this.salesRepsList.filter((item) =>
        Object.values(item).some((value) =>
          value
            ?.toString()
            .toLowerCase()
            .includes(this.searchKey?.toLowerCase())
        )
      );
    } else {
      this.filteredSalesRepsList = this.salesRepsList;
    }
  }
}