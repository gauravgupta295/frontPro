const script = document.createElement('script');

script.setAttribute(
  'src',
  'https://documentcloud.adobe.com/view-sdk/main.js',
);

script.setAttribute('async', '');

script.onload = function handleScriptLoaded() {
  console.log('Adobe view-sdk script has loaded');
};

script.onerror = function handleScriptError() {
  console.log('error loading script');
};

document.body.appendChild(script);

const adobeDcViewDiv = document.createElement('div');
adobeDcViewDiv.setAttribute(
  'id',
  'adobe-dc-view',
);

adobeDcViewDiv.onload = function handleDivLoaded() {
  console.log('Adobe adobeDcViewDiv has loaded');
};

adobeDcViewDiv.onerror = function handleDivError() {
  console.log('error loading adobeDcViewDiv');
};
document.body.appendChild(adobeDcViewDiv);
