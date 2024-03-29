// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).

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
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
});

window.addEventListener("phx:share", () => {
  const element = document.getElementById("share-button");

  if (navigator.share) {
    navigator
      .share({
        title: "Todoish!",
        text: "Add some things!",
        url: window.location.href,
      })
      .then(() => {
        if (element) {
          element.innerText = "Shared!";

          setTimeout(() => {
            element.innerText = "Share this list!";
          }, 1000);
        }
      })
      .catch((error) => console.log("Error sharing", error));
  } else {
    navigator.clipboard.writeText(window.location.href);

    if (element) {
      element.innerText = "Copied to clipboard!";

      setTimeout(() => {
        element.innerText = "Share this list!";
      }, 1000);
    }
  }
});

window.addEventListener("phx:save-list", () => {
  const element = document.getElementById("save-list-button");

  if (element) {
    element.innerText = "List saved!";

    setTimeout(() => {
      element.innerText = "Save list";
    }, 1000);
  }
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) => topbar.show());
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
