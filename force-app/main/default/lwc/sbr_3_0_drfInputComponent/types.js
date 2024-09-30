const PHONE_FORMATTER = function (contextArg) {
  //normalize string and remove all unnecessary characters
  const context = this || contextArg;
  let value = context.inputElement?.value || context.fieldValue;
  let phone = value?.replace(/[^\d]/g, "") || "";

  //check if number length equals to 10
  if (phone.length === 10) {
    //reformat and return phone number
    context.fieldValue = phone.replace(/(\d{3})(\d{3})(\d{4})/, "($1) $2-$3")
  }
};
const TEXT = {};

const PHONE = {
  executors: [PHONE_FORMATTER]
};

const TYPE = {
  text: "Text",
  tel: "Phone",
  email: "Email"
};

const FIELD_EXECUTOR = {
  [TYPE.tel]: PHONE,
  [TYPE.text]: TEXT
};

export { TYPE, FIELD_EXECUTOR };