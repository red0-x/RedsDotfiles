/**
 * @name RiceHomeLogo
 * @version 1.0.0
 * @description Centers the local R logo on Discord's Home button with the wallpaper accent.
 * @author Dotfiles Maintainer
 */
module.exports = class RiceHomeLogo {
  start() {
    const {readFileSync} = require('fs');
    const {join} = require('path');
    const image = readFileSync(join(BdApi.Plugins.folder, 'rice-home-logo.png')).toString('base64');
    BdApi.DOM.addStyle('RiceHomeLogo', `
      #app-mount [data-list-item-id="guildsnav___home"] { margin: 0 !important; }
      #app-mount [data-list-item-id="guildsnav___home"] [class*="childWrapper"] {
        background-image: url("data:image/png;base64,${image}") !important;
        background-color: transparent !important;
        background-repeat: no-repeat !important;
        background-size: 135% !important;
        background-position: 50% 63% !important;
        border-radius: 16px !important;
        filter: hue-rotate(calc(var(--accent-hue, 0) * 1deg));
      }
      #app-mount [data-list-item-id="guildsnav___home"] [class*="childWrapper"] > svg {
        display: none !important;
      }
    `);
  }
  stop() { BdApi.DOM.removeStyle('RiceHomeLogo'); }
};
