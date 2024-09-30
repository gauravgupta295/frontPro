export function parseError(err) {
  let message = "",
    output = {},
    detail = "";

  if (err) {
    if (err.body && err.body.output) {
      message = err.body.message;

      if (err.body.output.errors.length > 0) {
        detail = err.body.output.errors[0].message;
      }

      output = JSON.parse(JSON.stringify(err.body.output));
    } else if (Array.isArray(err.body) && err.body.length > 0) {
      message = err.body[0].message;
      detail = err.body[0].errorCode;
    } else if (err.body && err.body.message) {
      message = err.body.message;
    } else if (err.body && err.body.error) {
      message = err.body.error;
    } else if (err.body) {
      message = err.body;
    } else if (err.statusText) {
      message.err = err.statusText;
    } else if (err.message) {
      message = err.message;
    } else {
      message = err;
    }
  }

  return { message, detail, output };
}