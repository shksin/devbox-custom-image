param location string = 'australiaeast'
var tags = {
  'Demo-Name': 'DevBoxCustomImage'
}
param imagePublisher string = 'ContosoCorporation'
param prefix string = 'devboxcustom'


// Scripts
var commonScript = split(loadTextContent('installScripts/vscode-developer.ps1'), ['\r','\n'])

module developerImage 'modules/main.bicep' = {
  name: 'vscode-devbox-custom-image'
  params: {
    prefix: prefix
    imageName: 'vscode-devbox-custom-image'
    location: location
    imagePublisher: imagePublisher
    tags: tags
    customize: [
      {
        type: 'PowerShell'
        name: 'Common Setup'
        inline: commonScript
      }
    ]
  }
}

