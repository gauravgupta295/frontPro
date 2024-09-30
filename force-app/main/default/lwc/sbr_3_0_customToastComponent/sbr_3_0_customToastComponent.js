import { LightningElement, api, track } from "lwc";
export default class Sbr_3_0_customToastComponent extends LightningElement {
  @track title;
  @track message;
  @track variant;
  @track showToastBar = false;
  @track icon;
  showIcon = true;
  classList = "";

  @api
  showToast({
    title,
    message,
    variant,
    icon = "",
    mode = "dismissible",
    dismissibleTime = 3000,
    showIcon = true,
    classList = ""
  }) {
    this.title = title;
    this.variant = variant;
    this.icon = icon || variant;
    this.showIcon = showIcon;
    console.log("Icon is :- " + this.icon);
    console.log("showIcon is :- " + this.showIcon);
    this.message = message;
    this.classList = classList;

    this.showToastBar = true;
    if (mode === "dismissible") {
      setTimeout(() => {
        this.hideToast();
      }, dismissibleTime);
    }
  }

  @api
  hideToast() {
    this.showToastBar = false;
    this.variant = "";
    this.message = "";
  }

  get getIconName() {
    return "utility:" + this.icon;
  }

  get innerClass() {
    return (
      "slds-icon_container slds-icon-utility-" +
      this.icon +
      " slds-icon-utility-success slds-m-right_small slds-no-flex slds-align-top"
    );
  }

  get outerClass() {
    return "slds-notify slds-notify_toast slds-theme_" + this.variant + " temp";
  }
}