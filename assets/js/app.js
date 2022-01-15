// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html';
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from 'phoenix';
import {LiveSocket} from 'phoenix_live_view';
import topbar from '../vendor/topbar';

const NoContextMenu = el => {
  el.addEventListener('contextmenu', e => {
    e.preventDefault();
    e.stopImmediatePropagation();
    e.cancelBubble = true;
    return false;
  });
};

const hooks = {};

hooks.CellButton = {
  mounted() {
    NoContextMenu(this.el);

    this.el.addEventListener('mouseup', e => {
      if (e.button == 0) {
        this.pushEventTo(e.target.attributes.getNamedItem('phx-target').value, 'reveal');
      }
    });
    this.el.addEventListener('mousedown', e => {
      if (e.buttons == 2) {
        this.pushEventTo(e.target.attributes.getNamedItem('phx-target').value, 'mark');
      }
      if (e.buttons == 3) {
        this.pushEventTo(e.target.attributes.getNamedItem('phx-target').value, 'detect');
      }
    });

    this.row = parseInt(this.el.dataset['row']);
    this.col = parseInt(this.el.dataset['col']);

    const isNeighbour = e =>
      [-1, 0, 1].map(d => d + this.row).includes(e.row) &&
      [-1, 0, 1].map(d => d + this.col).includes(e.col) &&
      (e.row != this.row || e.col != this.col);

    this.handleEvent('detect', e => {
      if (isNeighbour(e)) {
        this.el.classList.add('shake');
        setTimeout(() => {
          this.el.classList.remove('shake');
        }, 200);
      }
    });
  },
};

hooks.MineField = {
  mounted() {
    NoContextMenu(this.el);
  },
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content');
let liveSocket = new LiveSocket('/live', Socket, {hooks, params: {_csrf_token: csrfToken}});

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: '#29d'}, shadowColor: 'rgba(0, 0, 0, .3)'});
window.addEventListener('phx:page-loading-start', () => topbar.show());
window.addEventListener('phx:page-loading-stop', () => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
