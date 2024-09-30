import { LightningElement, api, wire } from "lwc";
import getProductDetails from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductDetails";
import { NavigationMixin } from "lightning/navigation";

export default class Sbr_3_0_productDetailsCmp extends NavigationMixin(
  LightningElement
) {
  @api variant = "base";
  @api productId = "";
  @api productCat;
  @api isProductKit;
  hasDetailsLoaded = false;

  productName = "";
  productCatClass = "";
  productDescription = "";
  productWeight = "";
  imageNotFoundURL =
    "https://cdn1-originals.webdamdb.com/13348_133475191?cache=1651842673&response-content-disposition=inline;filename=SBR_no-image_320x240.png&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cCo6Ly9jZG4xLW9yaWdpbmFscy53ZWJkYW1kYi5jb20vMTMzNDhfMTMzNDc1MTkxP2NhY2hlPTE2NTE4NDI2NzMmcmVzcG9uc2UtY29udGVudC1kaXNwb3NpdGlvbj1pbmxpbmU7ZmlsZW5hbWU9U0JSX25vLWltYWdlXzMyMHgyNDAucG5nIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoyMTQ3NDE0NDAwfX19XX0_&Signature=J2cxa4dR~P3inOK1UDEmX1D60RjRk8LX7-wRvAwivgbULDLJigtc4fk1i0RGA50Mu4x-EcIaQCd1lBR6j8WQJmOMriQY~4PgAMw4t7-mrpiq0Zq6ursO5T5-ItK6ImbZXJAQRWLsjy0nKWJBBdN0qIpeFzb0iB3WRZI8SI35Ih1i1YAoHTIArq0dJjXYIX-Nrrl2URDPyo3qFJBNhl318~vhzunLwv5sPG6ml1Wkd3wkLaMWVqZbbzojLN7V2WS08Gq6bNYCnzTSpFlVn7aR3~pEgPy1U30ksPCRHHIkgg7Nu-HNV3SNtIQpI5rf5PBDZcIoQYMgEGjJc25w4zhheQ__&Key-Pair-Id=APKAI2ASI2IOLRFF2RHA";
  productImages = [];
  renderedImageCarousel = false;
  @api isContractSalesTab; //FRONT-15259, 28872
  productItemNumber; //FRONT-15259,28872
  productStockClass; //FRONT-15259,28872
  productUnitOfMeasure; //FRONT-15259,28872

  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
  }

  //check to see if this can be replaced with getrecord api based on fields that needs to be fetched
  @wire(getProductDetails, { productId: "$productId" })
  wiredProductDetails({ error, data }) {
    if (data) {
      console.log("Inside wired Product details --- ", JSON.stringify(data));
      let details = JSON.parse(data);
      this.productDescription = details.Description;
      this.productCatClass = "Cat-Class: " + details.CatClass;
      this.productName = details.Name;
      this.productWeight = details.Weight;
      this.productItemNumber = details.itemNumber; //FRONT-15259,28872
      this.productStockClass = details.stockClass; //FRONT-15259,28872
      this.productUnitOfMeasure = details.unitOfMeasure; //FRONT-15259,28872
      if (this.isMobile) {
        this.productImages = [];
        this.renderedImageCarousel = false;
        details.PrimaryImageURL
          ? this.productImages.push(details.PrimaryImageURL)
          : this.productImages.push(this.imageNotFoundURL);
      } else {
        details.PrimaryImageURL
          ? this.productImages.push(details.PrimaryImageURL)
          : this.productImages.push(this.imageNotFoundURL);
      }
      this.hasDetailsLoaded = true;
    } else if (error) {
      console.log("error in getProductDetails:");
      console.log(error);
      this.hasDetailsLoaded = false;
    }
  }

  get isBase() {
    return this.variant === "base";
  }
  get isCompact() {
    return this.variant === "compact";
  }
  get isMobileProductDescription() {
    return this.variant === "mobileProductDescription";
  }
  get isImageCarousel() {
    return this.variant === "mobileImageCarousel";
  }
  get productImageDescription() {
    let desc = this.productWeight
      ? `${this.productCatClass}, ${this.productWeight}`
      : `${this.productCatClass}`;
    return desc;
  }
  get isImageCarouselRendered() {
    return this.renderedImageCarousel;
  }

  get hasProductDescription() {
    return this.productDescription && this.productDescription !== "";
  }

  get isKit() {
    return this.isProductKit === "Yes" ? true : false;
  }

  //FRONT-11395
  get isMobileSalesTabDetailPanel() {
    return this.variant === "mobileSalesTabDetailPanel";
  }

  //FRONT-29178 (Issue 3)
  get isDesktopSalesTabDetailPanel() {
    return this.variant === "desktopSalesTabDetailPanel";
  }

  renderedCallback() {
    console.log("===== Details isProductKit: " + this.isProductKit);
    console.log("===== Details isKit: " + this.isKit);
    if (this.isMobile) {
      this.renderedImageCarousel = true;
    }

    const style = document.createElement("style");
    if (this.isMobile) {
      style.innerText = `c-sbr_3_0_spotlight-panel-cmp .mobile-container .slds-carousel__image{
                text-align: center;
                width: 100%;
            }
            .mobile-container .slds-carousel__stage{
                flex: auto;
            }
            .mobile-container .slds-carousel__image img{
                max-width: 100%;
                align-items: center;
            }
            .mobile-container .slds-carousel__autoplay{
                width: 1.75rem;
                height: 1.75rem;
            }
            .mobile-container .slds-carousel__autoplay button{
                width: 1.75rem;
                height: 1.75rem;
            }
            .mobile-container .slds-is-active{
                background-color: #24693E;
                border-color: #E5E5E5;
            }
            .mobile-container .slds-carousel__panels slot{
                flex: auto;
            }
            .mobile-container .slds-carousel__content{
                display: none;
            }`;
    } else {
      style.innerText = `c-sbr_3_0_spotlight-panel-cmp .details-container .slds-carousel__image{
                text-align: center;
            }
            .details-container .slds-carousel__image img{
                max-width: 75%;
            }`;
    }
    if (this.template.querySelector("lightning-carousel-image")) {
      this.template
        .querySelector("lightning-carousel-image")
        .appendChild(style);
    }
    console.log("===== Details isProductKit: " + this.isProductKit);
    console.log("===== Details isKit: " + this.isKit);
  }

  @api
  resetImageCarousel() {
    this.renderedImageCarousel = false;
  }

  /* Method to open the product record after clicking "More Information" */
  navigateToRecord(event) {
    event.stopPropagation();
    console.log("productId == " + this.productId);
    this.recordNavigateRef = {
      type: "standard__recordPage",
      attributes: {
        recordId: this.productId,
        actionName: "view"
      }
    };
    this[NavigationMixin.Navigate](this.recordNavigateRef).then((url) => {
      window.open(url, "_blank");
    });
  }
}